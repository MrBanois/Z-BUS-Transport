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
from Connect_DB import get_db_connection
from schemas import Position, StandardResponse

from oracledb import Connection
from typing import List

router = APIRouter()

# =============================================================================
# Helper Functions
# =============================================================================

def _generatePosID(connection: Connection) -> str:
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
def get_position():
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

        cursor.execute('''SELECT P."ID", P."NAME", P."PERMISSION" FROM "POSITION" P''')
        rows = cursor.fetchall()

        # Convert rows to a list of dictionaries
        results : List[Position] = []
        for row in rows:
            results.append({
                "id": row[0],
                "name": row[1],
                "permission": row[2]
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
def create_position(name: str, perms: str) -> StandardResponse:
    """
    POST Create a new position record.
    
    Creates a new position in the database with an auto-generated ID.
    Validates that both name and permissions are provided.
    
    Args:
        name (str): The name of the position (e.g., "Admin", "Manager")
        perms (str): Permission string associated with the position
        
    Returns:
        StandardResponse: Response containing success message and created position info
        
    Example Request:
        POST /position
        Body: {"name": "Admin", "perms": "ADMIN"}
        
    Example Response:
        {"msg": "Position Created Successfully", "info": "P0006 (Admin)"}
    """
    conn = None
    cursor = None
    autogen_id = None
    try:
        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=500, detail="Database connection failed")
        
        # Generate position ID
        autogen_id = _generatePosID(conn)
        cursor = conn.cursor()

        # Validate input data
        if not name or not name.strip():
            raise HTTPException(status_code=400, detail="Position name cannot be empty")

        if not perms or not perms.strip():
            raise HTTPException(status_code=400, detail="Permission string cannot be empty")

        # Insert the position
        sql = f'''INSERT INTO "POSITION" ("ID", "NAME", "PERMISSION")
                   VALUES (:autogen, :name, :perms)'''
        cursor.execute(sql, [autogen_id, name.strip(), perms.strip()])
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
def update_position(id: str, name: str, perms: str) -> StandardResponse :
    """
    PUT Update an existing position record.
    
    Updates the name and permissions of an existing position by its ID.
    The position ID must exist in the database for this operation to succeed.
    
    Args:
        id (str): The ID of the position to update (e.g., "P0001")
        name (str): The new name for the position
        perms (str): The new permission string for the position
        
    Returns:
        StandardResponse: Response containing success message and updated position info
        
    Example Request:
        PUT /position/P0001
        Body: {"name": "Administrator", "perms": "SUPER_ADMIN"}
        
    Example Response:
        {"msg": "Position Updated Successfully", "info": "P0001 (Administrator)"}
    """
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=500, detail="Database connection failed")

        cursor = conn.cursor()

        # Validate input data
        if not name or not name.strip():
            raise HTTPException(status_code=400, detail="Position name cannot be empty")

        if not perms or not perms.strip():
            raise HTTPException(status_code=400, detail="Permission string cannot be empty")

        # Update the position
        sql = f'''UPDATE "POSITION" SET "NAME" = :name, "PERMISSION" = :perm WHERE "ID" = :id'''
        cursor.execute(sql, [name.strip(), perms.strip(), id.strip()])
        conn.commit()

        return StandardResponse(
            msg="Position Updated Successfully",
            info= f"{id} ({name})"
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

@router.delete("/position/{id}")
def delete_position(id: str) :
    """
    DELETE Remove a position record from the database.
    
    Deletes a position record from the POSITION table by its ID.
    The position ID must exist in the database for this operation to succeed.
    
    Args:
        id (str): The ID of the position to delete (e.g., "P0001")
        
    Returns:
        StandardResponse: Response containing success message and deleted position ID
        
    Example Request:
        DELETE /position/P0001
        
    Example Response:
        {"msg": "Position Deleted Successfully", "info": "P0001"}
    """
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=500, detail="Database connection failed")

        cursor = conn.cursor()

        # Delete the position
        sql = f'''DELETE FROM "POSITION" WHERE ID = :id'''
        cursor.execute(sql, [id.strip()])
        conn.commit()

        return StandardResponse(
            msg="Position Deleted Successfully",
            info=id
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
