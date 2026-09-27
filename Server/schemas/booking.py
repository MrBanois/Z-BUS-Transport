from pydantic import BaseModel
from datetime import datetime

class Booking(BaseModel):
    booking_id: str
    user: str
    date: datetime

class BookingDetail(BaseModel):
    bid: str
    no: str
    route: str
    schedule: str
    startno: str
    srid: str
    endno: str
    erid: str
    seat: int
    qr_string: str
    current_status: str
