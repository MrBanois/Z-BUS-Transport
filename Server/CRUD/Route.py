from fastapi import APIRouter, HTTPException
from Connect_DB import get_db_connection
from schemas import Route

from typing import List

router = APIRouter()

@router.get("/route", response_model=List[Route])
def get_route() -> List[Route] :
    conn = None
    cursor = None
    try :
        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=500, detail="Database connection failed")
        
        cursor = conn.cursor()

        cursor.execute('''SELECT R."ID", R."NAME", R."IS_ACTIVE" FROM "ROUTE" R''')
        rows = cursor.fetchall()

        # Convert rows to a list of dictionaries
        results : List[Route] = []
        for row in rows:
            results.append({
                "id": row[0],
                "name": row[1],
                "is_active": row[2]
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
