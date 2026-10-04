from fastapi import APIRouter, HTTPException
from columns import MAX_DEPARTMENT_LENGTH, MAX_NAME_LENGTH, MAX_POSITION_LENGTH
from Connect_DB import get_db_connection
from ids import generate_user_id
from schemas import Profile, ProfileUpdate, Userdata, StandardResponse

from typing import List
import hashlib

router = APIRouter()

#Pull user with no FK following
@router.get("/user", response_model=List[Userdata])
def get_user() -> List[Userdata]:
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
            U."PASSWORD", U."POS", U."DEP", U."ISEMP", U."SALARY"
        FROM
            "USER" U
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
                "passwd": row[4],
                "pos": row[5],
                "dep": row[6],
                "isemp": True if row[7] == 'T' else False,
                "salary": 0 if row[8] is None else float(row[8])
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
            U."PASSWORD", P."NAME", D."NAME", U."ISEMP", U."SALARY"
        FROM
            "USER" U
            JOIN "POSITION" P ON P."ID" = U."POS"
            JOIN "DEPARTMENT" D ON D."ID" = U."DEP"
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
                "passwd": row[4],
                "pos": row[5],
                "dep": row[6],
                "isemp": True if row[7] == 'T' else False,
                "salary": 0 if row[8] is None else float(row[8])
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

def _field_error(status : int, message : str, field : str) -> HTTPException:
    """An error that names the control to put it under.

    The client's forms key their fields by these names, so a rejection lands
    beside the input that caused it instead of in a banner above the page. The
    `message` key keeps it a string for anything that only displays the detail.
    """
    return HTTPException(
        status_code=status,
        detail={"message": message, "field": field},
    )

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
        f_name = (profile.f_name or "").strip()
        l_name = (profile.l_name or "").strip()
        # None means "unchanged". The screen sends both or neither, but a member
        # whose assignment is read-only should be able to rename themselves
        # without resending ids they were never shown.
        dep = None if profile.dep is None else profile.dep.strip()
        pos = None if profile.pos is None else profile.pos.strip()

        # These name the control they belong to, so the client renders them
        # under the input rather than as a banner. See _field_error.
        if not f_name:
            raise _field_error(400, "First name is required", "firstName")
        if not l_name:
            raise _field_error(400, "Last name is required", "lastName")
        if len(f_name) > MAX_NAME_LENGTH:
            raise _field_error(
                400, f"First name cannot exceed {MAX_NAME_LENGTH} characters", "firstName"
            )
        if len(l_name) > MAX_NAME_LENGTH:
            raise _field_error(
                400, f"Last name cannot exceed {MAX_NAME_LENGTH} characters", "lastName"
            )

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
                raise _field_error(
                    400,
                    "Selected department is not available to a passenger account",
                    "department",
                )
            if not pos_ok:
                raise _field_error(
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
def add_user(f_name : str, l_name : str, email : str,
             password : str, pos : str, dep : str, 
             isemp : bool, sal : float) :
    conn = None
    cursor = None
    autogen_id = None
    try :
        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=500, detail="Database connection failed")
        
        # Generate user ID
        autogen_id = generate_user_id(conn)
        cursor = conn.cursor()

        sql = '''
        INSERT INTO "USER" ("ID", "F_NAME", "L_NAME", "EMAIL", "PASSWORD", "POS", "DEP", "ISEMP", "SALARY")
        VALUES (:autogen, :fname, :lname, :mail, :passwd, :pos, :dep, :isemp, :sal)
        '''
        cursor.execute(sql, [autogen_id, f_name.strip(), l_name.strip(),
                             email.strip(), hashlib.md5((autogen_id + password).encode()).hexdigest(),
                             pos.strip(), dep.strip(), 'T' if isemp else 'F', sal])
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
def update_user(id : str, f_name : str, l_name : str, email : str,
                password : str, pos : str, dep : str, 
                isemp : bool, sal : float) :
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=500, detail="Database connection failed")

        cursor = conn.cursor()

        # Update the data
        sql = '''
        UPDATE "USER" SET 
            "F_NAME" = :fname, "L_NAME" = :lname,
            "EMAIL" = :mail, "PASSWORD" = :pass,
            "POS" = :pos, "DEP" = :dep,
            "ISEMP" = :isemp, "SALARY" = :sal
        WHERE "ID" = :id'''
        cursor.execute(sql, [f_name.strip(), l_name.strip(), email.strip(),
                             hashlib.md5((id + password).encode()).hexdigest(), 
                             pos.strip(), dep.strip(),
                             'T' if isemp else 'F', sal, id.strip()])
        conn.commit()

        return StandardResponse(
            msg="User Updated Successfully",
            info= f"{id}"
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
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=500, detail="Database connection failed")

        cursor = conn.cursor()

        # Delete the position
        sql = '''DELETE FROM "USER" WHERE ID = :id'''
        cursor.execute(sql, [id.strip()])
        conn.commit()

        return StandardResponse(
            msg="User Deleted Successfully",
            info=id
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