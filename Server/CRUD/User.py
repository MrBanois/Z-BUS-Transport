from fastapi import APIRouter, HTTPException
from columns import (
    MAX_DEPARTMENT_LENGTH,
    MAX_EMAIL_LENGTH,
    MAX_NAME_LENGTH,
    MAX_POSITION_LENGTH,
    MAX_SALARY,
)
from credentials import hash_password, validate_password
from Connect_DB import get_db_connection
from errors import field_error
from ids import generate_user_id
from schemas import (
    Profile,
    ProfileUpdate,
    StandardResponse,
    UserCreate,
    UserUpdate,
    Userdata,
)

from typing import List
import re

router = APIRouter()

# Same rule registration uses, so an administrator is not held to a stricter
# standard than the public form. One @, no spaces, a dotted domain.
_EMAIL_PATTERN = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


def _clean_names(f_name: str, l_name: str) -> tuple[str, str]:
    """Validate both names, raising against whichever one is wrong."""
    first = (f_name or "").strip()
    last = (l_name or "").strip()
    if not first:
        raise field_error(400, "First name is required", "firstName")
    if not last:
        raise field_error(400, "Last name is required", "lastName")
    if len(first) > MAX_NAME_LENGTH:
        raise field_error(
            400, f"First name cannot exceed {MAX_NAME_LENGTH} characters", "firstName"
        )
    if len(last) > MAX_NAME_LENGTH:
        raise field_error(
            400, f"Last name cannot exceed {MAX_NAME_LENGTH} characters", "lastName"
        )
    return first, last


def _clean_email(email: str) -> str:
    cleaned = (email or "").strip().lower()
    if not cleaned:
        raise field_error(400, "Email is required", "email")
    if len(cleaned) > MAX_EMAIL_LENGTH:
        raise field_error(
            400, f"Email cannot exceed {MAX_EMAIL_LENGTH} characters", "email"
        )
    if not _EMAIL_PATTERN.match(cleaned):
        raise field_error(400, "Email address is not valid", "email")
    return cleaned


def _check_assignment(cursor, dep: str, pos: str, is_employee: bool) -> None:
    """Confirm the department and position exist and suit the account type.

    A passenger account must be given passenger-facing rows. This is the rule
    registration enforces, and without it an administrator could hand a passenger
    a staff position and, with it, every screen that position's mask unlocks.

    The reverse is not restricted: giving an employee a passenger-facing position
    only ever removes screens, so there is no equivalent reason to refuse it.
    """
    department = (dep or "").strip()
    position = (pos or "").strip()

    if len(department) > MAX_DEPARTMENT_LENGTH or len(position) > MAX_POSITION_LENGTH:
        raise field_error(
            400, "Department or position id is not valid", "department"
        )

    cursor.execute('''
    SELECT
        (SELECT COUNT(*) FROM "DEPARTMENT" WHERE "ID" = :dep),
        (SELECT COUNT(*) FROM "POSITION"   WHERE "ID" = :pos)
    FROM DUAL''', [department, position])
    dep_exists, pos_exists = cursor.fetchone()

    if not dep_exists:
        raise field_error(400, "That department does not exist", "department")
    if not pos_exists:
        raise field_error(400, "That position does not exist", "position")

    if is_employee:
        return

    cursor.execute('''
    SELECT
        (SELECT COUNT(*) FROM "DEPARTMENT" WHERE "ID" = :dep AND "ISEMP" = 'F'),
        (SELECT COUNT(*) FROM "POSITION"   WHERE "ID" = :pos AND "ISEMP" = 'F')
    FROM DUAL''', [department, position])
    dep_passenger, pos_passenger = cursor.fetchone()

    if not dep_passenger:
        raise field_error(
            400,
            "A passenger cannot be assigned a staff department",
            "department",
        )
    if not pos_passenger:
        raise field_error(
            400,
            "A passenger cannot be assigned a staff position",
            "position",
        )


#Pull user with no FK following
@router.get("/user", response_model=List[Userdata])
def get_user() -> List[Userdata]:
    """Every account, for the Manage users screen.

    PASSWORD is deliberately not selected. It used to be, which meant this route
    published every account's credential digest to whoever asked.
    """
    conn = None
    cursor = None
    try :
        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=500, detail="Database connection failed")
        
        cursor = conn.cursor()

        cursor.execute('''
        SELECT
            U."ID", U."F_NAME", U."L_NAME", U."EMAIL",
            U."POS", U."DEP", U."ISEMP", U."SALARY"
        FROM
            "USER" U
        ORDER BY U."ID"
        ''')
        rows = cursor.fetchall()

        # Convert rows to a list of dictionaries
        results : List[Userdata] = []
        for row in rows:
            results.append({
                "id": row[0],
                "f_name": row[1],
                "l_name": row[2],
                "email": row[3],
                "pos": row[4],
                "dep": row[5],
                "isemp": True if row[6] == 'T' else False,
                "salary": 0 if row[7] is None else float(row[7])
            })
        return results

    except HTTPException as he :
        raise he
    except Exception as e:
        print(f"Error : {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error")
    finally :
        if cursor:
            cursor.close()
        if conn:
            conn.close()

#Pull user with FK following
@router.get("/user-linked", response_model=List[Userdata])
def get_user_linked() -> List[Userdata] :
    """Every account whose department and position both resolve.

    The INNER JOINs mean an account pointing at a deleted row is absent rather
    than rendered blank, which is what makes this the safer list for the
    employee screen.

    Unlike the plain listing this also returns `dep_name` and `pos_name`. `pos`
    and `dep` stay ids in both routes, so a caller can use them as dropdown
    values without having to tell the two shapes apart.
    """
    conn = None
    cursor = None
    try :
        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=500, detail="Database connection failed")
        
        cursor = conn.cursor()

        cursor.execute('''
        SELECT
            U."ID", U."F_NAME", U."L_NAME", U."EMAIL",
            U."POS", U."DEP", U."ISEMP", U."SALARY",
            P."NAME", D."NAME"
        FROM
            "USER" U
            JOIN "POSITION" P ON P."ID" = U."POS"
            JOIN "DEPARTMENT" D ON D."ID" = U."DEP"
        ORDER BY U."ID"
        ''')
        rows = cursor.fetchall()

        # Convert rows to a list of dictionaries
        results : List[Userdata] = []
        for row in rows:
            results.append({
                "id": row[0],
                "f_name": row[1],
                "l_name": row[2],
                "email": row[3],
                "pos": row[4],
                "dep": row[5],
                "isemp": True if row[6] == 'T' else False,
                "salary": 0 if row[7] is None else float(row[7]),
                "pos_name": row[8],
                "dep_name": row[9],
            })
        return results

    except HTTPException as he :
        raise he
    except Exception as e:
        print(f"Error : {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error")
    finally :
        if cursor:
            cursor.close()
        if conn:
            conn.close()

# =============================================================================
# Self-service profile
# =============================================================================
# Powers GET/PUT /api/user/profile/{id} for the My account screen.
#
# These are separate from the management routes above, and deliberately so:
#
#   * GET /api/user and GET /api/user-linked return every account including its
#     PASSWORD hash, and PUT /api/user/{id} replaces the whole row from query
#     parameters, which means the caller has to send the password in the URL to
#     avoid rehashing over it. Neither is acceptable for a signed-in member
#     editing their own name, so this path exists instead.
#   * The response carries no PASSWORD, and the update never writes PASSWORD,
#     ISEMP or SALARY. A member cannot escalate themselves to an employee by
#     editing their profile.
#
# The `id` is caller-asserted: this API has no token to check it against yet, so
# any caller can read and rename any account. Closing that requires issuing a
# token at /api/login and matching it here; it is not a job this endpoint can do
# on its own.

@router.get("/user/profile/{id}", response_model=Profile)
def get_profile(id : str) -> Profile:
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=500, detail="Database connection failed")

        cursor = conn.cursor()

        # INNER JOINs: an account whose POS or DEP row was deleted is broken data
        # and should report as not found rather than render as blank fields.
        sql = '''
        SELECT
            U."ID", U."F_NAME", U."L_NAME", U."EMAIL", U."ISEMP",
            U."DEP", TRIM(D."NAME"), U."POS", TRIM(P."NAME")
        FROM
            "USER" U
            JOIN "DEPARTMENT" D ON D."ID" = U."DEP"
            JOIN "POSITION" P ON P."ID" = U."POS"
        WHERE
            U."ID" = :id
        '''
        cursor.execute(sql, {"id": id.strip()})
        row = cursor.fetchone()

        if not row:
            raise HTTPException(status_code=404, detail="Account not found")

        return Profile(
            id=row[0],
            f_name=(row[1] or "").strip(),
            l_name=(row[2] or "").strip(),
            email=(row[3] or "").strip(),
            isemp=row[4] == 'T',
            dep=(row[5] or "").strip(),
            dep_name=row[6] or "",
            pos=(row[7] or "").strip(),
            pos_name=row[8] or "",
        )

    except HTTPException:
        raise
    except Exception as e:
        print(f"Error : {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error")
    finally :
        if cursor:
            cursor.close()
        if conn:
            conn.close()

@router.put("/user/profile/{id}", response_model=StandardResponse)
def update_profile(id : str, profile: ProfileUpdate) -> StandardResponse:
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=500, detail="Database connection failed")

        user_id = id.strip()
        # Same name rules the administration routes apply, so a member cannot
        # save a name the administrator would have been refused.
        f_name, l_name = _clean_names(profile.f_name, profile.l_name)
        # None means "unchanged". The screen sends both or neither, but a member
        # whose assignment is read-only should be able to rename themselves
        # without resending ids they were never shown.
        dep = None if profile.dep is None else profile.dep.strip()
        pos = None if profile.pos is None else profile.pos.strip()

        cursor = conn.cursor()

        cursor.execute('SELECT "DEP", "POS", "ISEMP" FROM "USER" WHERE "ID" = :id', {"id": user_id})
        stored = cursor.fetchone()
        if not stored:
            raise HTTPException(status_code=404, detail="Account not found")

        current_dep, current_pos, is_employee = stored
        if dep is None:
            dep = (current_dep or "").strip()
        if pos is None:
            pos = (current_pos or "").strip()

        if len(dep) > MAX_DEPARTMENT_LENGTH or len(pos) > MAX_POSITION_LENGTH:
            raise HTTPException(status_code=400, detail="Department or position id is not valid")

        assignment_changed = (
            dep != (current_dep or "").strip() or pos != (current_pos or "").strip()
        )
        if assignment_changed:
            if is_employee == 'T':
                # The screen shows these as read-only for an employee. Reject it
                # here too rather than trusting that the client hid the control.
                raise HTTPException(
                    status_code=403,
                    detail="Employee department and position are assigned by administration",
                )

            # A passenger may re-pick their assignment, but only among the
            # passenger-facing rows: this is the same rule registration enforces,
            # and it is what stops the profile form from becoming a route to an
            # employee position and the screens its mask unlocks.
            lookup = '''
            SELECT
                (SELECT COUNT(*) FROM "DEPARTMENT" WHERE "ID" = :dep AND "ISEMP" = 'F'),
                (SELECT COUNT(*) FROM "POSITION"   WHERE "ID" = :pos AND "ISEMP" = 'F')
            FROM DUAL'''
            cursor.execute(lookup, {"dep": dep, "pos": pos})
            dep_ok, pos_ok = cursor.fetchone()

            if not dep_ok:
                raise field_error(
                    400,
                    "Selected department is not available to a passenger account",
                    "department",
                )
            if not pos_ok:
                raise field_error(
                    400,
                    "Selected position is not available to a passenger account",
                    "position",
                )

        # PASSWORD, ISEMP and SALARY are not in this statement, so they cannot be
        # changed here even if the client sends them.
        cursor.execute('''
        UPDATE "USER"
        SET "F_NAME" = :fname, "L_NAME" = :lname, "DEP" = :dep, "POS" = :pos
        WHERE "ID" = :id''', {"fname": f_name, "lname": l_name, "dep": dep, "pos": pos, "id": user_id})

        conn.commit()

        return StandardResponse(
            msg="Profile Updated Successfully",
            info=user_id
        )

    except HTTPException:
        raise
    except Exception as e:
        print(f"Error updating Profile: {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error")
    finally :
        if cursor:
            cursor.close()
        if conn:
            conn.close()

@router.post("/user", response_model=StandardResponse)
def add_user(body: UserCreate) -> StandardResponse :
    """Create an account on someone's behalf.

    `password` is required by the body schema, because this is the moment somebody
    decides what an account's credential is. There is no server-invented starting
    password: the previous default was derived from the public, sequential
    USER.ID, so every account created that way was guessable by anyone who could
    list accounts. Nothing in any response reveals the credential afterwards.
    """
    conn = None
    cursor = None
    autogen_id = None
    try :
        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=500, detail="Database connection failed")

        f_name, l_name = _clean_names(body.f_name, body.l_name)
        email = _clean_email(body.email)

        if body.sal is None or body.sal > MAX_SALARY:
            raise field_error(
                400, f"Salary cannot be above {MAX_SALARY:,.2f}", "salary"
            )

        # Checked before the id is generated so an obviously bad request costs
        # nothing, and before any INSERT so a rejection never leaves a row behind.
        problem = validate_password(body.password)
        if problem:
            raise field_error(400, problem, "password")

        cursor = conn.cursor()

        _check_assignment(cursor, body.dep, body.pos, body.isemp)

        cursor.execute(
            'SELECT COUNT(*) FROM "USER" WHERE "EMAIL" = :email', [email]
        )
        if cursor.fetchone()[0]:
            raise field_error(409, "That email address is already registered", "email")

        autogen_id = generate_user_id(conn)

        sql = '''
        INSERT INTO "USER" ("ID", "F_NAME", "L_NAME", "EMAIL", "PASSWORD", "POS", "DEP", "ISEMP", "SALARY")
        VALUES (:autogen, :fname, :lname, :mail, :passwd, :pos, :dep, :isemp, :sal)
        '''
        cursor.execute(sql, [autogen_id, f_name, l_name, email,
                             hash_password(autogen_id, body.password),
                             body.pos.strip(), body.dep.strip(),
                             'T' if body.isemp else 'F', body.sal])
        conn.commit()

        return StandardResponse(
            msg="User Created Successfully",
            info=autogen_id
        )

    except HTTPException as he :
        raise he
    except Exception as e:
        print(f"Error : {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error")
    finally :
        if cursor:
            cursor.close()
        if conn:
            conn.close()

@router.put("/user/{id}", response_model=StandardResponse)
def update_user(id : str, body: UserUpdate) -> StandardResponse :
    """Update an account.

    `password` is optional and defaults to None, meaning the stored hash is left
    exactly as it was. This is the correction that makes the screen possible at
    all: the previous signature required a password and re-hashed it as
    MD5(ID + password), so an administrator renaming an account had to know that
    account's current password or silently destroy the credential. Supplying a
    password here resets it instead.

    PASSWORD is therefore absent from the statement unless a reset was asked for,
    rather than being written on every save.
    """
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=500, detail="Database connection failed")

        user_id = id.strip()
        f_name, l_name = _clean_names(body.f_name, body.l_name)
        email = _clean_email(body.email)

        if body.sal is None or body.sal > MAX_SALARY:
            raise field_error(
                400, f"Salary cannot be above {MAX_SALARY:,.2f}", "salary"
            )

        reset_to = None
        if body.password is not None:
            problem = validate_password(body.password)
            if problem:
                raise field_error(400, problem, "password")
            reset_to = body.password

        cursor = conn.cursor()

        cursor.execute('SELECT 1 FROM "USER" WHERE "ID" = :id', [user_id])
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail="Account not found")

        _check_assignment(cursor, body.dep, body.pos, body.isemp)

        cursor.execute('''
        SELECT COUNT(*) FROM "USER" WHERE "EMAIL" = :email AND "ID" <> :id
        ''', [email, user_id])
        if cursor.fetchone()[0]:
            raise field_error(409, "That email address is already registered", "email")

        if reset_to is None:
            sql = '''
            UPDATE "USER" SET
                "F_NAME" = :fname, "L_NAME" = :lname,
                "EMAIL" = :mail, "POS" = :pos, "DEP" = :dep,
                "ISEMP" = :isemp, "SALARY" = :sal
            WHERE "ID" = :id'''
            params = [f_name, l_name, email, body.pos.strip(), body.dep.strip(),
                      'T' if body.isemp else 'F', body.sal, user_id]
        else:
            sql = '''
            UPDATE "USER" SET
                "F_NAME" = :fname, "L_NAME" = :lname,
                "EMAIL" = :mail, "PASSWORD" = :passwd,
                "POS" = :pos, "DEP" = :dep,
                "ISEMP" = :isemp, "SALARY" = :sal
            WHERE "ID" = :id'''
            params = [f_name, l_name, email, hash_password(user_id, reset_to),
                      body.pos.strip(), body.dep.strip(),
                      'T' if body.isemp else 'F', body.sal, user_id]

        cursor.execute(sql, params)
        conn.commit()

        return StandardResponse(
            msg="User Updated Successfully",
            info= user_id
        )

    except HTTPException:
        # Re-raise HTTP exceptions without rolling back (already handled)
        raise
    except Exception as e:
        print(f"Error updating User: {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error")
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

@router.delete("/user/{id}", response_model=StandardResponse)
def delete_user(id : str) :
    """Delete an account.

    Unlike department and position there is nothing pointing at USER, so this
    needs no guard beyond reporting a row that is not there. Deleting the account
    you are signed in as is the caller's problem, not this endpoint's: there is no
    token here to compare the path id against.
    """
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=500, detail="Database connection failed")

        user_id = id.strip()
        cursor = conn.cursor()

        cursor.execute('DELETE FROM "USER" WHERE "ID" = :id', [user_id])
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="Account not found")
        conn.commit()

        return StandardResponse(
            msg="User Deleted Successfully",
            info=user_id
        )

    except HTTPException:
        # Re-raise HTTP exceptions without rolling back (already handled)
        raise
    except Exception as e:
        print(f"Error deleting User: {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error")
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()