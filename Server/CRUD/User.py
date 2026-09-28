from fastapi import APIRouter, HTTPException
from Connect_DB import get_db_connection
from schemas import Userdata, StandardResponse

from oracledb import Connection
from typing import List
import hashlib

router = APIRouter()

def _generateUsrID(connection: Connection) -> str :
    with connection.cursor() as cur:
        result = cur.execute('SELECT MAX(ID) FROM "USER"').fetchone()
        max_id = result[0] if result else None
        
        # Case 1: Table is empty or has no valid IDs
        if max_id is None:
            return "U000000001"
            
        # Case 2: Increment and format the existing max ID
        # Assumes format is always 'U' followed by 9 digits
        numeric_part = int(max_id[1:])
        next_num = numeric_part + 1
        return f"U{next_num:09d}"

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
        
        # Generate position ID
        autogen_id = _generateUsrID(conn)
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
        sql = f'''
        UPDATE "USER" SET 
            "F_NAME" = :fname, "L_NAME" = :lname,
            "EMAIL" = :mail, "PASSWORD" = :pass,
            "POS" = :pos, "DEP" = :dep,
            "ISEMP" = :isemp, "SALARY" = : sal
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
        sql = f'''DELETE FROM "USER" WHERE ID = :id'''
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