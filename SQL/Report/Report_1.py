```python
import oracledb
import getpass
import pandas as pd
import json

username = input("Enter Username : ")
userpwd = getpass.getpass("Enter password : ")
host = input("Enter Host : ")  # "localhost"
port = 1521
service_name = input("Enter Service Name : ")  # "freepdb1"

rep1 = pd.DataFrame(
    columns=[
        "station_id",
        "Station",
        "month_no",
        "Date_Month",
        "Pickup",
        "Dropoff"
    ]
)

with oracledb.connect(
    f'{username}/{userpwd}@{host}:{port}/{service_name}'
) as connection:

    with connection.cursor() as cursor:

        year_s = input("Enter year : ")
        Year_Range = input("Enter range : ")

        start_year = int(year_s)
        end_year = start_year + int(Year_Range)

        query = cursor.execute(f'''
            SELECT
                s.id AS station_id,
                s.name AS "Station",
                m.month_no,
                TO_CHAR(
                    TO_DATE(m.month_no, 'MM'),
                    'Month'
                ) AS "Date_Month",

                NVL(x.pickup_count, 0) AS "Pickup",
                NVL(x.dropoff_count, 0) AS "Dropoff"

            FROM station s

            CROSS JOIN (
                SELECT LEVEL AS month_no
                FROM dual
                CONNECT BY LEVEL <= 12
            ) m

            LEFT JOIN (
                SELECT
                    station_id,
                    month_no,
                    SUM(pickup) AS pickup_count,
                    SUM(dropoff) AS dropoff_count

                FROM (
                    /* =========================
                       PICKUP
                       ========================= */
                    SELECT
                        rds.station AS station_id,
                        EXTRACT(MONTH FROM b."DATE") AS month_no,
                        tld.passenger AS pickup,
                        0 AS dropoff

                    FROM booking b

                    JOIN booking_detail bd
                        ON b.booking_id = bd.bid

                    JOIN route_detail rds
                        ON bd.srid = rds.rid
                       AND bd.startno = rds.station_no

                    JOIN trip_log_detail tld
                        ON bd.bid = tld.bid
                       AND bd.no = tld.no

                    WHERE
                        b."DATE" >= DATE '{start_year}-01-01'
                        AND b."DATE" < DATE '{end_year}-01-01'


                    UNION ALL


                    /* =========================
                       DROPOFF
                       ========================= */
                    SELECT
                        rde.station AS station_id,
                        EXTRACT(MONTH FROM b."DATE") AS month_no,
                        0 AS pickup,
                        tld.passenger AS dropoff

                    FROM booking b

                    JOIN booking_detail bd
                        ON b.booking_id = bd.bid

                    JOIN route_detail rde
                        ON bd.erid = rde.rid
                       AND bd.endno = rde.station_no

                    JOIN trip_log_detail tld
                        ON bd.bid = tld.bid
                       AND bd.no = tld.no

                    WHERE
                        b."DATE" >= DATE '{start_year}-01-01'
                        AND b."DATE" < DATE '{end_year}-01-01'
                )

                GROUP BY
                    station_id,
                    month_no
            ) x
                ON x.station_id = s.id
               AND x.month_no = m.month_no

            ORDER BY
                s.id,
                m.month_no
        ''')

        for row in query:
            rep1.loc[len(rep1)] = row


# ============================================================
# PANDAS PROCESSING
# ============================================================

# Explicit month order
month_order = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December"
]

# Remove Oracle's trailing spaces from MONTH
rep1["Date_Month"] = rep1["Date_Month"].str.strip()

# Make sure month names are consistent
rep1["Date_Month"] = rep1["Date_Month"].str.capitalize()

# Sort by station and month number
df = rep1.sort_values(
    ["station_id", "month_no"]
)

df_wide = df.pivot_table(
    index=["station_id", "Station"],
    columns="Date_Month",
    values=["Pickup", "Dropoff"],
    aggfunc="sum",
    fill_value=0
)

df_wide = df_wide.swaplevel(0, 1, axis=1)

existing_months = [
    month
    for month in month_order
    if month in df_wide.columns.get_level_values(0)
]

df_wide = df_wide.reindex(
    columns=existing_months,
    level=0
)


df_wide = df_wide.reindex(
    columns=["Pickup", "Dropoff"],
    level=1
)

df_wide.columns = [
    f"{metric}_{month}"
    for month, metric in df_wide.columns
]

df_wide = df_wide.reset_index()

data = {
    "report_title": "Station Statistics",
    "year_range": f"{start_year} to {end_year - 1}",
    "data": df_wide.to_dict(orient="records")
}

print(json.dumps(data, indent=2, default=str))
```
