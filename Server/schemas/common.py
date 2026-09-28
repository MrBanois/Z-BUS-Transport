from pydantic import BaseModel

class Status(BaseModel):
    id: str
    name: str

class StandardResponse(BaseModel):
    msg: str
    info: str