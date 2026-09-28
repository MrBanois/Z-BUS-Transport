from fastapi import FastAPI, HTTPException
from typing import List
import hashlib
import os

from Connect_DB import get_db_connection
from schemas import Userdata

app = FastAPI()

def verify_password(passwd : str, db_pass : str) :
    return hashlib.md5(passwd.encode()).hexdigest() == db_pass

@app.get("/api")
def Root() :
    return {"message" : "API is running "}

@app.post("/apt/login")
def Login(user : str, passwd : str) :
    conn = None
    cursor = None
    try : 
        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=500, detail="Database connection failed")

        cursor = conn.cursor()

        query = '''
        SELECT 
            U."ID", 
            U."EMAIL", 
            U."PASSWORD", 
            U."F_NAME", 
            U."L_NAME",
            P."PERMISSION"
        FROM 
            "USER" U JOIN "POSITION" P ON U."POS" = P."ID"
        WHERE 
            U."EMAIL" = :1'''
        cursor.execute(query, [user])
        user_row = cursor.fetchone()

        if not user_row:
            raise HTTPException(status_code=401, detail="Invalid credentials")

        id, db_email, db_password, f_name, l_name, perms = user_row

        #Password logic : MD5(f"{ID}{PASSWORD}")
        if not verify_password(id + passwd, db_password):
            raise HTTPException(status_code=401, detail="Invalid credentials")

        return {
            "message": "Login successful",
            "user": {
                "id": id,
                "name": f"{f_name} {l_name}",
                "email": db_email,
                "permission": perms
      }
        }

    except HTTPException as he:
        raise he
    except Exception as e :
        print(f"Error : {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error")
    finally :
        if cursor:
            cursor.close()
        if conn:
            conn.close()


if __name__ == "__main__" :
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)