from pydantic import BaseModel

class Report(BaseModel):
    report_title: str
    date_range: str
    data: list[dict]