from pydantic import BaseModel
from datetime import datetime

class TripLog(BaseModel):
    log_id: str
    driver: str
    vehicle: str
    date: datetime
    time_start: datetime
    time_end: datetime

class TripLogDetail(BaseModel):
    lid: str
    bid: str
    no: str
    time_getin: datetime
    time_getout: datetime
    passenger: int
