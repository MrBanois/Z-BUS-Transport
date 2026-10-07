# =============================================================================
# Statistic reports
# =============================================================================
# Six read-only aggregates: /report1, /report2, /report3, /report4, /report6 and
# /report7. There has never been a report5, and the numbering is kept because it
# is how these are referred to everywhere else.
#
# Each one is a single SELECT with no side effect, so calling any of them cannot
# change the database.
#
# Two rules they now all share. The original versions disagreed about both, and
# the disagreement was invisible until a screen tried to use them:
#
#   Parameters arrive as a JSON body, like every other endpoint in this API.
#   Reports 1 and 2 take a year and lay out its twelve months; the other four
#   take a date range. They were query parameters before, which made the two
#   shapes easy to overlook when reading a request.
#
#   The end of a range is INCLUSIVE. Somebody choosing 1 January to 30 January
#   means all thirty days. Report 3 used `BETWEEN start AND end`, which against
#   an Oracle DATE only matches midnight on the last day, and the other three
#   used `< end`, which drops that day entirely. So every report here compares
#   against `end + 1 day`, and that conversion happens once in `_range`.

from datetime import date, timedelta
import logging

from fastapi import APIRouter, HTTPException

from Connect_DB import get_db_connection
from errors import field_error
from schemas import DateRangeReportBody, Report, YearReportBody

router = APIRouter()
log = logging.getLogger("zbus.reports")

MONTHS = (
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December",
)

DAYS = (
    "Monday", "Tuesday", "Wednesday", "Thursday",
    "Friday", "Saturday", "Sunday",
)

# Oracle's abbreviated day name, upper-cased, to the Monday-first position the
# charts use. The abbreviation arrives in English because the format string asks
# for English, which is what stops a report from collapsing if the database ever
# runs in another language -- a database-set language would otherwise turn
# 'Monday' into its translation and this lookup into a 500.
DAY_NUMBER = {
    "MON": 0, "TUE": 1, "WED": 2, "THU": 3, "FRI": 4, "SAT": 5, "SUN": 6,
}


def _run(cursor, sql: str, binds: dict) -> list[tuple]:
    """Run one SELECT and hand back all of its rows.

    Named binds are passed as a dict rather than as keyword arguments: that is
    the documented form, and the original used keywords, which the driver does
    not describe as a bind map.

    The two bound names are `range_start` and `range_end`, not `start` and
    `end`. Oracle rejects the latter with ORA-01745 "invalid host/bind variable
    name" because both are reserved words, and it rejects the whole statement
    at parse time, so a perfectly sensible-looking date range would have failed
    on every report that has one.
    """
    cursor.execute(sql, binds)
    return cursor.fetchall()


def _count(value) -> int:
    """A whole number for the JSON.

    Oracle returns COUNT as an integer but SUM over an INTEGER column as a
    float, and `12.0` is not what anybody wants in a spreadsheet cell.
    """
    return int(value or 0)


def _range(body: DateRangeReportBody) -> tuple[date, date]:
    """Validated bounds, with the end pushed one day past its inclusive date."""
    if body.end_date < body.start_date:
        raise field_error(
            400,
            "The end of the range cannot be before its start",
            "end_date",
        )
    return body.start_date, body.end_date + timedelta(days=1)


def _covers(body: DateRangeReportBody) -> str:
    """What to show a user as the range the report covered."""
    return f"{body.start_date} to {body.end_date}"


def _generate(title: str, date_range: str, query) -> Report:
    """Open a connection, run `query`, and wrap what it returns as a Report.

    This is the whole shape of all six reports, which is why it lives here
    rather than being typed out six times: the original repeated the connection
    setup, the `except HTTPException` re-raise and the `finally` block in every
    single one, which is precisely how the date rules ended up disagreeing with
    each other. A failure is logged with its traceback and reported as an
    opaque 500, because the raw Oracle message would name tables and columns to
    a caller who has no use for them.
    """
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="Database connection failed")
    try:
        cursor = conn.cursor()
        try:
            data = query(cursor)
        finally:
            cursor.close()
    except HTTPException as http_error:
        raise http_error
    except Exception:
        log.exception("report %r failed", title)
        raise HTTPException(status_code=500, detail="Could not generate the report")
    finally:
        conn.close()
    return Report(report_title=title, date_range=date_range, data=data)


# =============================================================================
# Report 1 - passengers picked up and dropped off at every station, by month
# =============================================================================

@router.post("/report1", response_model=Report)
def generate_report_1(body: YearReportBody) -> Report:
    """One year. One row per station, with a pickup/dropoff pair per month.

    The pivot is built here rather than by the client because both the columns
    the table shows and the twelve month categories the chart plots come from
    the same place: the cross join guarantees every station has all twelve
    months, so a month with no traffic reports 0 instead of being absent.
    """
    return _generate(
        "Station Statistics",
        str(body.year),
        lambda cursor: _station_pickups(
            cursor,
            date(body.year, 1, 1),
            # 1 January of the next year, which is exclusive and therefore puts
            # 31 December inside the report instead of after it.
            date(body.year + 1, 1, 1),
        ),
    )


def _station_pickups(cursor, start: date, end: date) -> list[dict]:
    rows = _run(
        cursor,
        '''
            SELECT
                s.id AS station_id,
                s.name AS station_name,
                m.month_no,
                NVL(x.pickup_count, 0),
                NVL(x.dropoff_count, 0)

            FROM station s

            CROSS JOIN (
                SELECT LEVEL AS month_no
                FROM dual
                CONNECT BY LEVEL <= 12
            ) m

            LEFT JOIN (
                SELECT
                    rds.station AS station_id,
                    EXTRACT(MONTH FROM b."DATE") AS month_no,
                    COUNT(rds.station) AS pickup_count,
                    COUNT(rde.station) AS dropoff_count

                FROM booking b

                JOIN booking_detail bd
                    ON b.booking_id = bd.bid

                JOIN schedule sch
                    ON bd.route = sch.rid
                   AND bd.schedule = sch.trip_no

                JOIN route r
                    ON r.id = sch.rid

                JOIN route_detail rds
                    ON bd.srid = rds.rid
                   AND bd.startno = rds.station_no

                JOIN route_detail rde
                    ON bd.erid = rde.rid
                   AND bd.endno = rde.station_no

                WHERE
                    b."DATE" >= :range_start
                    AND b."DATE" < :range_end

                GROUP BY
                    rds.station,
                    EXTRACT(MONTH FROM b."DATE")
            ) x
                ON x.station_id = s.id
               AND x.month_no = m.month_no

            ORDER BY
                s.id,
                m.month_no
        ''',
        {"range_start": start, "range_end": end},
    )

    # Rows arrive station-major and month-minor, so one insertion per station
    # followed by one key per month produces exactly the column order the table
    # asks for: January pickup, January dropoff, February pickup, and so on.
    data: list[dict] = []
    where: dict[str, int] = {}
    for station_id, station_name, month_no, pickup, dropoff in rows:
        at = where.get(station_id)
        if at is None:
            at = len(data)
            where[station_id] = at
            data.append({"station_id": station_id, "Station": station_name})
        month = MONTHS[int(month_no) - 1]
        data[at][f"Pickup_{month}"] = _count(pickup)
        data[at][f"Dropoff_{month}"] = _count(dropoff)
    return data


# =============================================================================
# Report 2 - bookings by month, split by status
# =============================================================================

@router.post("/report2", response_model=Report)
def generate_report_2(body: YearReportBody) -> Report:
    """One year. One row per month, five metrics.

    Only three of those five are drawn (checked-in, cancelled, no-show); the
    other two -- bookings and seats -- are table-only, because they are totals
    rather than statuses and putting them on the same axis as the parts they
    contain would double-count.
    """
    return _generate(
        "Booking Statistics",
        str(body.year),
        lambda cursor: _bookings_by_month(
            cursor,
            date(body.year, 1, 1),
            date(body.year + 1, 1, 1),
        ),
    )


def _bookings_by_month(cursor, start: date, end: date) -> list[dict]:
    rows = _run(
        cursor,
        '''
            SELECT
                M.MONTH_NO,
                COUNT(BD."BID"),
                NVL(SUM(BD."SEAT"), 0),
                NVL(SUM(CASE
                    WHEN BD."CURRENT_STATUS" = '3' THEN BD."SEAT"
                    ELSE 0
                END), 0),
                NVL(SUM(CASE
                    WHEN BD."CURRENT_STATUS" = '2' THEN BD."SEAT"
                    ELSE 0
                END), 0),
                NVL(SUM(CASE
                    WHEN BD."CURRENT_STATUS" = '4' THEN BD."SEAT"
                    ELSE 0
                END), 0)

            FROM (
                SELECT LEVEL AS MONTH_NO
                FROM DUAL
                CONNECT BY LEVEL <= 12
            ) M

            LEFT JOIN "BOOKING" B
                ON EXTRACT(MONTH FROM B."DATE") = M.MONTH_NO
               AND B."DATE" >= :range_start
               AND B."DATE" < :range_end

            LEFT JOIN "BOOKING_DETAIL" BD
                ON B."BOOKING_ID" = BD."BID"

            GROUP BY
                M.MONTH_NO

            ORDER BY
                M.MONTH_NO
        ''',
        {"range_start": start, "range_end": end},
    )

    return [
        {
            "Month": MONTHS[int(month_no) - 1],
            "Bookings": _count(bookings),
            "Seats": _count(seats),
            "Cancelled": _count(cancelled),
            "Checked-In": _count(checked_in),
            "No-Show": _count(no_show),
        }
        for month_no, bookings, seats, cancelled, checked_in, no_show in rows
    ]


# =============================================================================
# Report 3 - what each user did
# =============================================================================

@router.post("/report3", response_model=Report)
def generate_report_3(body: DateRangeReportBody) -> Report:
    """One date range. One row per user.

    Grouped by `USER.ID` rather than by name. It grouped by the two name
    columns, so two accounts belonging to the same person -- or to two people
    who happen to share a name -- were folded into a single row whose counts
    added together, which is a wrong answer rather than a confusing one.

    Ordered by name because both the table and the chart read it as a list of
    people.
    """
    start, end = _range(body)
    return _generate(
        "User activity",
        _covers(body),
        lambda cursor: _user_behaviour(cursor, start, end),
    )


def _user_behaviour(cursor, start: date, end: date) -> list[dict]:
    rows = _run(
        cursor,
        '''
            SELECT
                US."F_NAME" || ' ' || US."L_NAME",
                COUNT(BD."BID"),
                COUNT(CASE WHEN BD."CURRENT_STATUS" = '2' THEN 1 END),
                COUNT(CASE WHEN BD."CURRENT_STATUS" = '3' THEN 1 END),
                COUNT(CASE WHEN BD."CURRENT_STATUS" = '4' THEN 1 END)
            FROM
                "BOOKING" B
                JOIN "BOOKING_DETAIL" BD ON B."BOOKING_ID" = BD."BID"
                JOIN "USER" US ON B."USER" = US."ID"
            WHERE
                B."DATE" >= :range_start
                AND B."DATE" < :range_end
            GROUP BY US."ID", US."F_NAME", US."L_NAME"
            ORDER BY US."F_NAME", US."L_NAME", US."ID"
        ''',
        {"range_start": start, "range_end": end},
    )

    return [
        {
            "User": name,
            "Bookings": _count(bookings),
            "Checked-In": _count(checked_in),
            "Cancelled": _count(cancelled),
            "No-Show": _count(no_show),
        }
        for name, bookings, checked_in, cancelled, no_show in rows
    ]


# =============================================================================
# Report 4 - passengers per route, by day of week
# =============================================================================

@router.post("/report4", response_model=Report)
def generate_report_4(body: DateRangeReportBody) -> Report:
    """One date range. One row per weekday, one column per route.

    The shape is wide because the x-axis is the days and the routes are what
    differentiates the bars, so each route is its own series. Columns are the
    active routes with any route that actually carried a trip added in, sorted
    by id: a route can be deactivated while its trips are still in the range,
    and a column that vanished would silently drop those passengers.

    Column keys are route ids. The screen turns them into names using
    `/api/route`, which already lists them; carrying the name here too would
    mean two sources for one label.
    """
    start, end = _range(body)
    return _generate(
        "Route Statistics",
        _covers(body),
        lambda cursor: _route_by_weekday(cursor, start, end),
    )


def _route_by_weekday(cursor, start: date, end: date) -> list[dict]:
    trips = _run(
        cursor,
        '''
            SELECT
                TO_CHAR(
                    TL."DATE", 'DY', 'NLS_DATE_LANGUAGE = American'
                ),
                R."ID",
                NVL(SUM(TLD."PASSENGER"), 0)
            FROM
                "TRIP_LOG" TL
                JOIN "TRIP_LOG_DETAIL" TLD
                    ON TL."LOG_ID" = TLD."LID"
                JOIN "BOOKING_DETAIL" BD
                    ON TLD."BID" = BD."BID"
                   AND TLD."NO" = BD."NO"
                JOIN "ROUTE" R
                    ON BD."ROUTE" = R."ID"
            WHERE
                TL."DATE" >= :range_start
                AND TL."DATE" < :range_end
            GROUP BY
                TO_CHAR(TL."DATE", 'DY', 'NLS_DATE_LANGUAGE = American'),
                R."ID"
        ''',
        {"range_start": start, "range_end": end},
    )

    active = [
        row[0]
        for row in _run(
            cursor,
            '''SELECT "ID" FROM "ROUTE" WHERE "IS_ACTIVE" = 'T' ORDER BY "ID"''',
            {},
        )
    ]

    routes = sorted({*(route_id for route_id in active), *(r[1] for r in trips)})
    counts = {route_id: [0] * len(DAYS) for route_id in routes}

    for day_name, route_id, passengers in trips:
        day = DAY_NUMBER.get(str(day_name).strip().upper())
        if day is None:
            # Not one of the seven, which would mean the English override did
            # not take. Dropping the row is deliberate: raising here would turn
            # one unrecognised day into no report at all.
            log.warning("ignoring unrecognised weekday %r", day_name)
            continue
        counts[route_id][day] = _count(passengers)

    return [
        {"Day": day, **{route_id: counts[route_id][day_index] for route_id in routes}}
        for day_index, day in enumerate(DAYS)
    ]


# =============================================================================
# Report 6 - each driver's trips, before and after 17:00
# =============================================================================

@router.post("/report6", response_model=Report)
def generate_report_6(body: DateRangeReportBody) -> Report:
    """One date range. One row per driver, total and split at 17:00.

    `Total` is returned as well as the two halves so the table can show all
    three, but only the halves are charted: they add up to the total, and
    plotting all three would draw every driver's total as a bar twice as tall
    as its own parts.
    """
    start, end = _range(body)
    return _generate(
        "Late Trip Statistics",
        _covers(body),
        lambda cursor: _driver_trips(cursor, start, end),
    )


def _driver_trips(cursor, start: date, end: date) -> list[dict]:
    rows = _run(
        cursor,
        '''
            SELECT
                TL."DRIVER",
                U."F_NAME" || ' ' || U."L_NAME",
                COUNT(*),
                SUM(
                    CASE
                        WHEN TO_CHAR(TL."TIME_START", 'HH24:MI:SS') < '17:00:00'
                        THEN 1 ELSE 0
                    END
                ),
                SUM(
                    CASE
                        WHEN TO_CHAR(TL."TIME_START", 'HH24:MI:SS') >= '17:00:00'
                        THEN 1 ELSE 0
                    END
                )
            FROM
                "TRIP_LOG" TL
                JOIN "USER" U
                    ON TL."DRIVER" = U."ID"
            WHERE
                TL."DATE" >= :range_start
                AND TL."DATE" < :range_end
            GROUP BY
                TL."DRIVER",
                U."F_NAME",
                U."L_NAME"
            ORDER BY
                U."F_NAME",
                U."L_NAME",
                TL."DRIVER"
        ''',
        {"range_start": start, "range_end": end},
    )

    return [
        {
            "Driver_ID": driver_id,
            "Name": name,
            "Total": _count(total),
            "Before_17": _count(before),
            "After_17": _count(after),
        }
        for driver_id, name, total, before, after in rows
    ]


# =============================================================================
# Report 7 - trips per vehicle
# =============================================================================

@router.post("/report7", response_model=Report)
def generate_report_7(body: DateRangeReportBody) -> Report:
    """One date range. One row per vehicle.

    The LEFT JOIN from the vehicle side is what keeps vehicles that made no
    trips in the range in the report. Filtering on the trip log in the WHERE
    clause instead would drop them, which would read as "this vehicle does not
    exist" rather than the truth, "this vehicle was not used".
    """
    start, end = _range(body)
    return _generate(
        "Trips Statistics",
        _covers(body),
        lambda cursor: _vehicle_trips(cursor, start, end),
    )


def _vehicle_trips(cursor, start: date, end: date) -> list[dict]:
    rows = _run(
        cursor,
        '''
            SELECT
                VT."NAME",
                V."PLATE_NO",
                V."SEAT",
                COUNT(TL."LOG_ID")
            FROM
                "VEHICLE_TYPE" VT
                JOIN "VEHICLE" V
                    ON V."TYPE" = VT."ID"
                LEFT JOIN "TRIP_LOG" TL
                    ON TL."VEHICLE" = V."ID"
                        AND TL."DATE" >= :range_start
                        AND TL."DATE" < :range_end
            GROUP BY
                VT."ID",
                VT."NAME",
                V."ID",
                V."SEAT",
                V."PLATE_NO"
            ORDER BY
                VT."ID",
                V."ID"
        ''',
        {"range_start": start, "range_end": end},
    )

    return [
        {
            "Type": vehicle_type,
            "PLATE_NO": plate,
            "Seat": _count(seat),
            "Trips": _count(trips),
        }
        for vehicle_type, plate, seat, trips in rows
    ]
