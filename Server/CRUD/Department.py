from fastapi import APIRouter, HTTPException
from Connect_DB import get_db_connection
from schemas import Department, StandardResponse

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

@router.get("/department", response_model=List[Department])
def get_department() -> List[Department] :
    conn = None
    cursor = None
    try :
        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=500, detail="Database connection failed")
        
        cursor = conn.cursor()

        cursor.execute('''SELECT D."ID", D."NAME" FROM "DEPARTMENT" D''')
        rows = cursor.fetchall()

        # Convert rows to a list of dictionaries
        results : List[Department] = []
        for row in rows:
            results.append({
                "id": row[0],
                "name": row[1]
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
def create_department(name: str) -> StandardResponse :
    conn = None
    cursor = None
    autogen_id = None
    try:
        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=500, detail="Database connection failed")
        
        # Generate position ID
        autogen_id = _generateDepID(conn)
        cursor = conn.cursor()

        # Insert the position
        sql = '''INSERT INTO "DEPARTMENT" ("ID", "NAME")
                   VALUES (:autogen, :name)'''
        cursor.execute(sql, [autogen_id, name.strip()])
        conn.commit()

        return StandardResponse(
            msg="Department Created Successfully",
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

@router.put("/department/{id}", response_model=StandardResponse)
def update_department(id: str, name: str) -> StandardResponse :
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=500, detail="Database connection failed")

        cursor = conn.cursor()

        # Update the position
        sql = '''UPDATE "DEPARTMENT" SET "NAME" = :name WHERE "ID" = :id'''
        cursor.execute(sql, [name.strip(), id.strip()])
        conn.commit()

        return StandardResponse(
            msg="Department Updated Successfully",
            info= f"{id} ({name})"
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
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=500, detail="Database connection failed")

        cursor = conn.cursor()

        # Delete the department
        sql = '''DELETE FROM "DEPARTMENT" WHERE ID = :id'''
        cursor.execute(sql, [id.strip()])
        conn.commit()

        return StandardResponse(
            msg="Department Deleted Successfully",
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
