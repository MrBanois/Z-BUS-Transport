import oracledb
import getpass
import pandas as pd
import json

username = input("Enter Username : ")
userpwd = getpass.getpass(f"Enter password : ")
host = input("Enter Host : ") # "localhost"
port = 1521 #Assume Default port
service_name = input("Enter Service Name : ") # "freepdb1","database1"

rep1 = pd.DataFrame(columns=["station_id", "Station", "month_no", "Date_Month", "Pickup", "Dropoff"])

with oracledb.connect(f'{username}/{userpwd}@{host}:{port}/{service_name}') as connection :
    with connection.cursor() as cursor :
        year_s = input("Enter year : ")
        Year_Range = input("Enter range : ")
        query = cursor.execute(f'''
            SELECT
                s.id AS station_id,
                s.name AS "Station",
                m.month_no,
                TO_CHAR(TO_DATE(m.month_no, 'MM'), 'Month') AS "Date_Month",
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

                JOIN station ss
                    ON rds.station = ss.id

                JOIN station es
                    ON rde.station = es.id

                JOIN status st
                    ON bd.current_status = st.id

                WHERE
                    b."DATE" >= DATE '{year_s}-01-01'
                    AND b."DATE" < DATE '{int(year_s) + int(Year_Range)}-01-01'

                GROUP BY
                    rds.station,
                    EXTRACT(MONTH FROM b."DATE")
            ) x
                ON x.station_id = s.id
               AND x.month_no = m.month_no

            ORDER BY
                s.id,
                m.month_no;
        ''')
        for _ in query : 
            rep1.loc[len(rep1)] = _
data = {
    "report_title": "Booking Statistics",
    "year_range": f"{year_s} to {int(year_s) + int(Year_Range) - 1}",
    "data": rep1.to_dict(orient='records')
}
print(json.dumps(data, indent=2, default=str))