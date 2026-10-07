from datetime import date

from pydantic import BaseModel


class Report(BaseModel):
    """One generated statistic report.

    `data` is a list of flat records, and every report decides its own keys. That
    is the point: the client describes a report by its name, its x-axis, its
    y-axis and how it groups, then reads whatever columns the payload carries,
    rather than having a fixed response shape that six different shapes have to
    be squeezed into.

    `date_range` is display text covering whatever the report actually queried,
    so a caller can show the coverage without reconstructing it from parameters
    it may not have.
    """
    report_title: str
    date_range: str
    data: list[dict]


class YearReportBody(BaseModel):
    """Parameters of the two year-based reports: `/report1` and `/report2`.

    `year` is the whole input. Both reports lay out that year's twelve months,
    so there is no range to pick: the endpoint used to accept a `range` as well,
    and a range wider than one year silently merged the years together, because
    both queries group by month number alone and never look at the year.

    `end_date` does not exist here. The boundary is 1 January of the following
    year, which keeps 31 December inside the report.
    """
    year: int


class DateRangeReportBody(BaseModel):
    """Parameters of the four date-range reports: `/report3`, `/report4`,
    `/report6` and `/report7`.

    Both are calendar dates and `end_date` is INCLUSIVE -- 1 January to 30
    January means all thirty days. The route converts that to an exclusive
    bound internally, so no caller has to remember to add a day itself.
    """
    start_date: date
    end_date: date
