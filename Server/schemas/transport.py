from pydantic import BaseModel
from datetime import datetime

class Route(BaseModel):
    id: str
    name: str
    is_active: bool

class RouteDetail(BaseModel):
    station_no: str
    rid: str
    station: str
    time: datetime

class Station(BaseModel):
    id: str
    name: str
    is_active: bool

class Schedule(BaseModel):
    rid: str
    trip_no: str
    driver: str
    vehicle: str
    time_start: datetime
    is_active: bool

class Vehicle(BaseModel):
    id: str
    plate_no: str
    seat: int
    type: str
    is_active: bool

class VehicleType(BaseModel):
    id: str
    name: str
