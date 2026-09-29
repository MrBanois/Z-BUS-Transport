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

# print(json.dumps(data, indent=2, default=str))
# print(rep1)

df = rep1.sort_values('month_no')

# 2. Create the Pivot Table
df_wide = df.pivot_table(
    index=['station_id', 'Station'], 
    columns='Date_Month', 
    values=['Pickup', 'Dropoff']
)

# 3. SWAP LEVELS: Move Month to Level 0 and Metric to Level 1
df_wide = df_wide.swaplevel(0, 1, axis=1)

# 4. FIX THE ORDER: 
# Sort Level 1 (Metric) in DESCENDING order so 'Pickup' (P) comes before 'Dropoff' (D)
df_wide = df_wide.sort_index(axis=1, level=1, ascending=False)

# 5. REINDEX MONTHS: Ensure months follow the chronological order (Jan, Feb, Mar...)
month_order = df['Date_Month'].unique()
df_wide = df_wide.reindex(columns=month_order, level=0)

# 6. FLATTEN COLUMNS: Combine them into 'Pickup_January', 'Dropoff_January', etc.
# Note: Since we swapped levels, 'col[0]' is Month and 'col[1]' is Metric
df_wide.columns = [f'{col[1]}_{col[0]}' for col in df_wide.columns]

# 7. CLEANUP
df_wide = df_wide.reset_index()

data = {
    "report_title": "Booking Statistics",
    "year_range": f"{year_s} to {int(year_s) + int(Year_Range) - 1}",
    "data": df_wide.to_dict(orient='records')
}
# Display result
# print(df_wide.head())
print(json.dumps(data, indent=2, default=str))
