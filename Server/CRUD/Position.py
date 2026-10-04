# =============================================================================
# Position CRUD Operations Module
# =============================================================================
# This module provides API endpoints for managing position records in the database.
# It includes Create, Read, Update, and Delete operations for the POSITION table.
#
# Dependencies:
#   - fastapi: Web framework for API endpoints
#   - Connect_DB: Database connection utilities
#   - schemas: Data models for Position and StandardResponse
#   - oracledb: Oracle database driver

from fastapi import APIRouter, HTTPException
from columns import MAX_REFERENCE_NAME_LENGTH
from Connect_DB import get_db_connection
from errors import field_error
from permissions import PERMISSION_LENGTH, is_valid_mask
from schemas import Position, PositionCreate, PositionUpdate, StandardResponse

from oracledb import Connection
from typing import List

router = APIRouter()


def _clean_name(name: str) -> str:
    """Validate a position name, or raise the error the client renders inline."""
    trimmed = (name or "").strip()
    if not trimmed:
        raise field_error(400, "Position name cannot be empty", "name")
    if len(trimmed) > MAX_REFERENCE_NAME_LENGTH:
        raise field_error(
            400,
            f"Position name cannot exceed {MAX_REFERENCE_NAME_LENGTH} characters",
            "name",
        )
    return trimmed


def _clean_mask(perms: str) -> str:
    """Validate the 16 bit mask, or raise an error the editor can render.

    PERMISSION is a 16 character '0'/'1' mask. Rejecting a malformed value here
    stops a wrong length or a stray character from being stored and later read as
    a screen nobody intended to grant.
    """
    trimmed = (perms or "").strip()
    if not trimmed:
        raise field_error(400, "Permission string cannot be empty", "permissions")
    if not is_valid_mask(trimmed):
        raise field_error(
            400,
            f"Permission must be exactly {PERMISSION_LENGTH} '0'/'1' characters",
            "permissions",
        )
    return trimmed

# =============================================================================
# Helper Functions
# =============================================================================

def _generatePosID(connection: Connection) -> str :
    """
    Generate a new unique position ID for a position record.
    
    The ID format is 'P' followed by 4 digits (e.g., P0001, P0002, etc.).
    The function finds the maximum existing ID and increments it.
    
    Args:
        connection: Oracle database connection object
        
    Returns:
        str: A new position ID in the format P####
        
    Example:
        If MAX(ID) returns 'P0005', this function returns 'P0006'
    """
    with connection.cursor() as cur:
        result = cur.execute("SELECT MAX(ID) FROM POSITION").fetchone()
        max_id = result[0] if result else None
        
        # Case 1: Table is empty or has no valid IDs
        if max_id is None:
            return "P0001"
            
        # Case 2: Increment and format the existing max ID
        # Assumes format is always 'P' followed by 4 digits
        numeric_part = int(max_id[1:])
        next_num = numeric_part + 1
        return f"P{next_num:04d}"

@router.get("/position", response_model=List[Position])
def get_position() -> List[Position] :
    """
    GET all positions from the database.
    
    This endpoint retrieves all position records and returns them as a list
    of dictionaries containing ID, NAME, and PERMISSION fields.
    
    Returns:
        List[Position]: List of all position records
        
    Example Response:
        [
            {"id": "P0001", "name": "Admin", "permission": "ADMIN"},
            {"id": "P0002", "name": "Manager", "permission": "MANAGER"}
        ]
    """
    conn = None
    cursor = None
    try :
        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=500, detail="Database connection failed")
        
        cursor = conn.cursor()

        # Ordered by id, not left to the optimiser: this list drives both the
        # management table and the account form's position dropdown, and an
        # unordered result can reshuffle between calls or after a restart.
        cursor.execute('''
        SELECT P."ID", P."NAME", P."PERMISSION", P."ISEMP"
        FROM "POSITION" P
        ORDER BY P."ID"
        ''')
        rows = cursor.fetchall()

        # Convert rows to a list of dictionaries
        results : List[Position] = []
        for row in rows:
            results.append({
                "id": row[0],
                "name": row[1],
                "permission": row[2],
                "isemp": row[3] == 'T'
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

@router.get("/position/passenger", response_model=List[Position])
def get_passenger_position() -> List[Position] :
    """
    GET only the passenger facing positions (ISEMP = 'F').

    This is the list the registration form's position dropdown reads, so a public
    sign-up can never be issued an employee position and the screens it unlocks.
    """
    conn = None
    cursor = None
    try :
        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=500, detail="Database connection failed")
        
        cursor = conn.cursor()

        cursor.execute('''
        SELECT P."ID", P."NAME", P."PERMISSION", P."ISEMP"
        FROM "POSITION" P
        WHERE P."ISEMP" = 'F'
        ORDER BY P."ID"
        ''')
        rows = cursor.fetchall()

        results : List[Position] = []
        for row in rows:
            results.append({
                "id": row[0],
                "name": row[1],
                "permission": row[2],
                "isemp": row[3] == 'T'
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

#From Z-Bus mockup there should be 16 permissions
@router.post("/position", response_model=StandardResponse)
def create_position(body: PositionCreate) -> StandardResponse :
    """Create a position with an auto-generated id.

    The id is generated here, and the mask is validated before the insert, so a
    position can never be stored with a permission string that means something
    other than what the editor showed.
    """
    conn = None
    cursor = None
    autogen_id = None
    try:
        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=500, detail="Database connection failed")

        name = _clean_name(body.name)
        perms = _clean_mask(body.perms)

        cursor = conn.cursor()

        cursor.execute('''
        SELECT COUNT(*) FROM "POSITION" WHERE UPPER("NAME") = UPPER(:name)
        ''', [name])
        if cursor.fetchone()[0]:
            raise HTTPException(
                status_code=409,
                detail=f"A position called {name} already exists",
            )

        autogen_id = _generatePosID(conn)

        sql = '''INSERT INTO "POSITION" ("ID", "NAME", "PERMISSION", "ISEMP")
                   VALUES (:autogen, :name, :perms, :isemp)'''
        cursor.execute(sql, [autogen_id, name, perms, 'T' if body.isemp else 'F'])
        conn.commit()

        return StandardResponse(
            msg="Position Created Successfully",
            info=f"{autogen_id} ({name})"
        )

    except HTTPException:
        # Re-raise HTTP exceptions without rolling back (already handled)
        raise
    except Exception as e:
        print(f"Error creating position: {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error")
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

@router.put("/position/{id}", response_model=StandardResponse)
def update_position(id: str, body: PositionUpdate) -> StandardResponse :
    """Replace a position's name, mask and account type.

    Always sends all three fields: this is not a partial update, so a caller
    editing only the name must resend the mask it already had.
    """
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=500, detail="Database connection failed")

        name = _clean_name(body.name)
        perms = _clean_mask(body.perms)
        position_id = id.strip()

        cursor = conn.cursor()

        cursor.execute('''
        SELECT COUNT(*) FROM "POSITION"
        WHERE UPPER("NAME") = UPPER(:name) AND "ID" <> :id
        ''', [name, position_id])
        if cursor.fetchone()[0]:
            raise HTTPException(
                status_code=409,
                detail=f"A position called {name} already exists",
            )

        sql = '''UPDATE "POSITION"
                 SET "NAME" = :name, "PERMISSION" = :perm, "ISEMP" = :isemp
                 WHERE "ID" = :id'''
        cursor.execute(sql, [name, perms, 'T' if body.isemp else 'F', position_id])
        conn.commit()

        return StandardResponse(
            msg="Position Updated Successfully",
            info= f"{position_id} ({name})"
        )

    except HTTPException:
        # Re-raise HTTP exceptions without rolling back (already handled)
        raise
    except Exception as e:
        print(f"Error updating position: {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error")
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

@router.delete("/position/{id}", response_model=StandardResponse)
def delete_position(id: str) -> StandardResponse :
    """Delete a position, refusing while any account still points at it.

    The guard exists because POSITION.ID is referenced by USER.POS. Without it
    Oracle raises ORA-02273, which reaches the client as an unexplained 500.
    """
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=500, detail="Database connection failed")

        position_id = id.strip()
        cursor = conn.cursor()

        cursor.execute('''
        SELECT
            (SELECT COUNT(*) FROM "USER"     WHERE "POS" = :id),
            (SELECT COUNT(*) FROM "POSITION" WHERE "ID" = :id)
        FROM DUAL''', [position_id])
        in_use, exists = cursor.fetchone()

        if not exists:
            raise HTTPException(status_code=404, detail="Position not found")
        if in_use:
            raise HTTPException(
                status_code=409,
                detail=(
                    "This position is still assigned to "
                    f"{in_use} account(s). Move them first."
                ),
            )

        cursor.execute('DELETE FROM "POSITION" WHERE "ID" = :id', [position_id])
        conn.commit()

        return StandardResponse(
            msg="Position Deleted Successfully",
            info=position_id
        )

    except HTTPException:
        # Re-raise HTTP exceptions without rolling back (already handled)
        raise
    except Exception as e:
        print(f"Error deleting position: {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error")
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
