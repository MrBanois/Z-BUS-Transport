from fastapi import FastAPI, HTTPException
from typing import List

from Connect_DB import get_db_connection

app = FastAPI()

@app.get("/api")
def Root() :
    return {"message" : "API is running "}



if __name__ == "__main__" :
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)