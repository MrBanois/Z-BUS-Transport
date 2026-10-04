# =============================================================================
# Authentication: login and public registration
# =============================================================================
# Both endpoints live here so the password rules sit in one file instead of
# being split between Main.py and the user CRUD module.
#
# Password storage: USER.PASSWORD stores MD5(ID + plaintext), so the hash is
# bound to the row ID. That stops the same password producing the same digest
# for every account, but MD5 is fast and unsalted enough to be cracked offline.
# Treat it as a placeholder for bcrypt/argon2 and replace hash_password when
# that is available; keep the ID prefix so the migration is a single function.
#
# Registration is deliberately narrow: it creates passengers only, and only into
# department/position rows flagged ISEMP = 'F'. Staff accounts are provisioned
# through /api/user, which an admin calls, so a public endpoint can never mint
# an employee.

import hashlib
import re

from fastapi import APIRouter, HTTPException
from columns import (
    MAX_DEPARTMENT_LENGTH,
    MAX_EMAIL_LENGTH,
    MAX_NAME_LENGTH,
    MAX_POSITION_LENGTH,
    MIN_PASSWORD_LENGTH,
)
from Connect_DB import get_db_connection
from ids import generate_user_id
from schemas import Credentials, LoginResponse, RegisterRequest, StandardResponse

router = APIRouter()

# Deliberately permissive: one @, no spaces, a dotted domain. Anything stricter
# rejects legitimate institutional addresses.
_EMAIL_PATTERN = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


# =============================================================================
# Password helpers
# =============================================================================

def hash_password(user_id: str, password: str) -> str:
    """Return the stored form of a password: MD5(ID + password)."""
    return hashlib.md5(f"{user_id}{password}".encode()).hexdigest()


def verify_password(user_id: str, password: str, stored_hash: str) -> bool:
    """Check a login attempt against the stored hash."""
    return hashlib.md5(
        f"{user_id}{password}".encode()
    ).hexdigest() == stored_hash


# =============================================================================
# POST /api/login
# =============================================================================

@router.post("/login", response_model=LoginResponse)
def login(credentials: Credentials) -> LoginResponse:
    """
    Authenticate an account by email and password.

    Returns the user id, display name, email and the raw 16 bit permission mask
    from their position. The client decodes the mask; see permissions.py.

    Every failure returns the same 401 so the endpoint does not reveal whether
    an email is registered.
    """
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=500, detail="Database connection failed")

        cursor = conn.cursor()

        # LEFT JOINs rather than INNER: an account must still be able to sign in
        # if its position or department row was removed, otherwise the row
        # vanishes from the result set and the login looks like a bad password.
        query = '''
        SELECT
            U."ID",
            U."F_NAME",
            U."L_NAME",
            U."PASSWORD",
            P."PERMISSION"
        FROM
            "USER" U
            LEFT JOIN "POSITION" P ON U."POS" = P."ID"
        WHERE
            U."EMAIL" = :email'''

        cursor.execute(query, [credentials.email.strip().lower()])
        user_row = cursor.fetchone()

        if not user_row:
            raise HTTPException(status_code=401, detail="Invalid credentials")

        user_id, f_name, l_name, db_password, permission = user_row

        if not verify_password(user_id, credentials.password, db_password or ""):
            raise HTTPException(status_code=401, detail="Invalid credentials")

        # A user with no readable permission mask gets nothing rather than
        # everything. Empty mask = no screen unlocked.
        return LoginResponse(
            message="Login successful",
            user={
                "id": user_id.strip(),
                "name": f"{(f_name or '').strip()} {(l_name or '').strip()}".strip(),
                "email": credentials.email.strip().lower(),
                "permission": (permission or "").strip(),
            },
        )

    except HTTPException:
        raise
    except Exception as e:
        print(f"Error : {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error")
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()


# =============================================================================
# POST /api/register
# =============================================================================

@router.post("/register", response_model=StandardResponse)
def register(request: RegisterRequest) -> StandardResponse:
    """
    Create a passenger account through public sign-up.

    Validation, in order of the checks below:
      1. Names present and within the VARCHAR2(20) column.
      2. Email present, well formed and not already in use.
      3. Password at least MIN_PASSWORD_LENGTH characters.
      4. Department exists and ISEMP = 'F'.
      5. Position exists and ISEMP = 'F'.

    The account is created with ISEMP = 'F' and SALARY = NULL: a passenger has no
    salary, and an employee flag here would let a public signup grant staff
    access to every screen their position unlocks.

    Returns the generated user id so the client can show it or log the new user
    straight in.
    """
    conn = None
    cursor = None
    try:
        f_name = (request.f_name or "").strip()
        l_name = (request.l_name or "").strip()
        email = (request.email or "").strip().lower()
        password = request.password or ""
        dep = (request.dep or "").strip().upper()
        pos = (request.pos or "").strip().upper()

        # --- 1. Names -------------------------------------------------------
        if not f_name or not l_name:
            raise HTTPException(status_code=400, detail="First and last name are required")
        if len(f_name) > MAX_NAME_LENGTH or len(l_name) > MAX_NAME_LENGTH:
            raise HTTPException(
                status_code=400,
                detail=f"Names cannot exceed {MAX_NAME_LENGTH} characters",
            )

        # --- 2. Email -------------------------------------------------------
        if not email:
            raise HTTPException(status_code=400, detail="Email is required")
        if len(email) > MAX_EMAIL_LENGTH:
            raise HTTPException(
                status_code=400,
                detail=f"Email cannot exceed {MAX_EMAIL_LENGTH} characters",
            )
        if not _EMAIL_PATTERN.match(email):
            raise HTTPException(status_code=400, detail="Email address is not valid")

        # --- 3. Password ----------------------------------------------------
        # Length is checked before any DB work so a weak password never reaches
        # the database.
        if len(password) < MIN_PASSWORD_LENGTH:
            raise HTTPException(
                status_code=400,
                detail=f"Password must be at least {MIN_PASSWORD_LENGTH} characters",
            )

        # --- Column widths for the CHAR(5) references ------------------------
        if len(dep) > MAX_DEPARTMENT_LENGTH or len(pos) > MAX_POSITION_LENGTH:
            raise HTTPException(status_code=400, detail="Department or position id is not valid")

        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=500, detail="Database connection failed")

        cursor = conn.cursor()

        # --- 4 & 5. Email uniqueness and passenger-facing department/position -
        # One round trip: a second query here would leave a window where two
        # signups both pass the check before either commits.
        lookup = '''
        SELECT
            (SELECT COUNT(*) FROM "USER"       WHERE "EMAIL" = :email),
            (SELECT COUNT(*) FROM "DEPARTMENT" WHERE "ID" = :dep  AND "ISEMP" = 'F'),
            (SELECT COUNT(*) FROM "POSITION"   WHERE "ID" = :pos  AND "ISEMP" = 'F')
        FROM DUAL'''

        cursor.execute(lookup, {"email": email, "dep": dep, "pos": pos})
        email_taken, dep_ok, pos_ok = cursor.fetchone()

        if email_taken:
            # 409 rather than 400: the request was well formed, the resource
            # already exists. The client can show "email already registered".
            raise HTTPException(status_code=409, detail="Email is already registered")
        if not dep_ok:
            raise HTTPException(
                status_code=400,
                detail="Selected department is not available for registration",
            )
        if not pos_ok:
            raise HTTPException(
                status_code=400,
                detail="Selected position is not available for registration",
            )

        # --- Insert ---------------------------------------------------------
        new_id = generate_user_id(conn)

        # ISEMP 'F' = passenger. SALARY stays NULL.
        insert = '''
        INSERT INTO "USER"
            ("ID", "F_NAME", "L_NAME", "EMAIL", "PASSWORD", "POS", "DEP", "ISEMP", "SALARY")
        VALUES
            (:id, :f_name, :l_name, :email, :password, :pos, :dep, 'F', NULL)'''

        cursor.execute(insert, {
            "id": new_id,
            "f_name": f_name,
            "l_name": l_name,
            "email": email,
            "password": hash_password(new_id, password),
            "pos": pos,
            "dep": dep,
        })
        conn.commit()

        return StandardResponse(
            msg="Account Created Successfully",
            info=new_id,
        )

    except HTTPException:
        # Nothing was committed, but an explicit rollback keeps a failed insert
        # from holding locks if a statement failed partway.
        if conn:
            conn.rollback()
        raise
    except Exception as e:
        print(f"Error : {e}")
        if conn:
            conn.rollback()
        raise HTTPException(status_code=500, detail="Internal Server Error")
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
