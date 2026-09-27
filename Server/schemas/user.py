from pydantic import BaseModel

class Userdata(BaseModel):
    id: str
    f_name: str
    l_name: str
    email: str
    passwd: str
    pos: str
    dep: str
    isemp: bool
    salary: float

class Department(BaseModel):
    id: str
    name: str

class Position(BaseModel):
    id: str
    name: str
    permission: str
