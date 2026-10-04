from fastapi import APIRouter, HTTPException
from columns import MAX_REFERENCE_NAME_LENGTH
from Connect_DB import get_db_connection
from errors import field_error
from schemas import Department, DepartmentCreate, DepartmentUpdate, StandardResponse

from oracledb import Connection
from typing import List

router = APIRouter()

def _generateDepID(connection: Connection) -> str :
    with connection.cursor() as cur:
        result = cur.execute('SELECT MAX(ID) FROM "DEPARTMENT"').fetchone()
        max_id = result[0] if result else None
        
        # Case 1: Table is empty or has no valid IDs
        if max_id is None:
            return "D0001"
            
        # Case 2: Increment and format the existing max ID
        # Assumes format is always 'D' followed by 4 digits
        numeric_part = int(max_id[1:])
        next_num = numeric_part + 1
        return f"D{next_num:04d}"


def _clean_name(name: str) -> str:
    """Validate a department name, or raise the error the client renders inline."""
    trimmed = (name or "").strip()
    if not trimmed:
        raise field_error(400, "Department name cannot be empty", "name")
    if len(trimmed) > MAX_REFERENCE_NAME_LENGTH:
        raise field_error(
            400,
            f"Department name cannot exceed {MAX_REFERENCE_NAME_LENGTH} characters",
            "name",
        )
    return trimmed

@router.get("/department", response_model=List[Department])
def get_department() -> List[Department] :
    conn = None
    cursor = None
    try :
        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=500, detail="Database connection failed")
        
        cursor = conn.cursor()

        # Ordered by id, not left to the optimiser: this list drives both the
        # management table and the account form's department dropdown, and an
        # unordered result can reshuffle between calls or after a restart.
        cursor.execute('''
        SELECT D."ID", D."NAME", D."ISEMP"
        FROM "DEPARTMENT" D
        ORDER BY D."ID"
        ''')
        rows = cursor.fetchall()

        # Convert rows to a list of dictionaries
        results : List[Department] = []
        for row in rows:
            results.append({
                "id": row[0],
                "name": row[1],
                "isemp": row[2] == 'T'
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

@router.get("/department/passenger", response_model=List[Department])
def get_passenger_department() -> List[Department] :
    """
    GET only the passenger facing departments (ISEMP = 'F').

    This is the list the registration form's department dropdown reads, so a
    public sign-up cannot offer staff departments. Declared as a fixed path
    rather than a query flag so the intent stays visible at the call site.
    """
    conn = None
    cursor = None
    try :
        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=500, detail="Database connection failed")
        
        cursor = conn.cursor()

        cursor.execute('''
        SELECT D."ID", D."NAME", D."ISEMP"
        FROM "DEPARTMENT" D
        WHERE D."ISEMP" = 'F'
        ORDER BY D."ID"
        ''')
        rows = cursor.fetchall()

        results : List[Department] = []
        for row in rows:
            results.append({
                "id": row[0],
                "name": row[1],
                "isemp": row[2] == 'T'
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

@router.post("/department", response_model=StandardResponse)
def create_department(body: DepartmentCreate) -> StandardResponse :
    """Create a department.

    The id is generated here rather than accepted from the caller, so two
    administrators cannot pick the same one.
    """
    conn = None
    cursor = None
    autogen_id = None
    try:
        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=500, detail="Database connection failed")

        name = _clean_name(body.name)

        cursor = conn.cursor()

        # A duplicate name would make the dropdowns ambiguous and the screen
        # would show two identical entries, so it is refused before the insert
        # rather than surfacing later as ORA-00001 on the unique index.
        cursor.execute('''
        SELECT COUNT(*) FROM "DEPARTMENT" WHERE UPPER("NAME") = UPPER(:name)
        ''', [name])
        if cursor.fetchone()[0]:
            raise HTTPException(
                status_code=409,
                detail=f"A department called {name} already exists",
            )

        autogen_id = _generateDepID(conn)

        sql = '''INSERT INTO "DEPARTMENT" ("ID", "NAME", "ISEMP")
                   VALUES (:autogen, :name, :isemp)'''
        cursor.execute(sql, [autogen_id, name, 'T' if body.isemp else 'F'])
        conn.commit()

        return StandardResponse(
            msg="Department Created Successfully",
            info=f"{autogen_id} ({name})"
        )

    except HTTPException:
        # Re-raise HTTP exceptions without rolling back (already handled)
        raise
    except Exception as e:
        print(f"Error creating department: {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error")
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

@router.put("/department/{id}", response_model=StandardResponse)
def update_department(id: str, body: DepartmentUpdate) -> StandardResponse :
    """Replace a department's name and account type.

    This endpoint always sends both fields. There is no partial update, so a
    caller that wants to rename a passenger-facing department without publishing
    it to the registration form has to resend `isemp: false` explicitly.
    """
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=500, detail="Database connection failed")

        name = _clean_name(body.name)
        department_id = id.strip()

        cursor = conn.cursor()

        # Same rule as create, excluding this row so saving without changing the
        # name is not treated as a duplicate of itself.
        cursor.execute('''
        SELECT COUNT(*) FROM "DEPARTMENT"
        WHERE UPPER("NAME") = UPPER(:name) AND "ID" <> :id
        ''', [name, department_id])
        if cursor.fetchone()[0]:
            raise HTTPException(
                status_code=409,
                detail=f"A department called {name} already exists",
            )

        sql = '''UPDATE "DEPARTMENT"
                 SET "NAME" = :name, "ISEMP" = :isemp
                 WHERE "ID" = :id'''
        cursor.execute(sql, [name, 'T' if body.isemp else 'F', department_id])
        conn.commit()

        return StandardResponse(
            msg="Department Updated Successfully",
            info= f"{department_id} ({name})"
        )

    except HTTPException:
        # Re-raise HTTP exceptions without rolling back (already handled)
        raise
    except Exception as e:
        print(f"Error updating Department: {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error")
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

@router.delete("/department/{id}", response_model=StandardResponse)
def delete_department(id: str) -> StandardResponse :
    """Delete a department, refusing while any account still points at it.

    Without the guard Oracle raises ORA-02273, which surfaces as an opaque 500.
    The client renders this 409 as a banner explaining what to do instead.
    """
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=500, detail="Database connection failed")

        department_id = id.strip()
        cursor = conn.cursor()

        cursor.execute('''
        SELECT
            (SELECT COUNT(*) FROM "USER"      WHERE "DEP" = :id),
            (SELECT COUNT(*) FROM "DEPARTMENT" WHERE "ID" = :id)
        FROM DUAL''', [department_id])
        in_use, exists = cursor.fetchone()

        if not exists:
            raise HTTPException(status_code=404, detail="Department not found")
        if in_use:
            raise HTTPException(
                status_code=409,
                detail=(
                    "This department is still assigned to "
                    f"{in_use} account(s). Move them first."
                ),
            )

        cursor.execute('DELETE FROM "DEPARTMENT" WHERE "ID" = :id', [department_id])
        conn.commit()

        return StandardResponse(
            msg="Department Deleted Successfully",
            info=department_id
        )

    except HTTPException:
        # Re-raise HTTP exceptions without rolling back (already handled)
        raise
    except Exception as e:
        print(f"Error deleting department: {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error")
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
