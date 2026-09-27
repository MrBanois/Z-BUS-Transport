from pydantic import BaseModel

class Status(BaseModel):
    id: str
    name: str
