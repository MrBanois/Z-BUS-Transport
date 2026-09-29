import oracledb
import getpass
import pandas as pd
import json

username = input("Enter Username : ")
userpwd = getpass.getpass(f"Enter password : ")
host = input("Enter Host : ") # "localhost"
port = 1521 #Assume Default port
service_name = input("Enter Service Name : ") # "freepdb1","database1"

rep4_Q = pd.DataFrame(columns=["DAY", "ROUTE_ID", "ROUTE_NAME", "PASSENGERS"])

with oracledb.connect(f'{username}/{userpwd}@{host}:{port}/{service_name}') as connection :
    with connection.cursor() as cursor :
        start_date = input("Start date (YYYY-MM-DD) : ") # 2025-04-12
        end_date = input("End date (YYYY-MM-DD) : ") # 2025-04-16 
        query = cursor.execute(f'''
            SELECT
                TO_CHAR(TL."DATE", 'DAY') AS "DAY",
                R."ID" AS "ROUTE_ID",
                R."NAME" AS "ROUTE_NAME",
                SUM(TLD."PASSENGER") AS "PASSENGERS"
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
                TL."DATE" >= DATE '{start_date}'
                AND TL."DATE" < DATE '{end_date}'
            GROUP BY
                TO_CHAR(TL."DATE", 'DAY'),
                R."ID",
                R."NAME"
            ''')
        for _ in query : 
            rep4_Q.loc[len(rep4_Q)] = _

rep4 : pd.DataFrame
routes : list[str] = []
days = [ "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

with oracledb.connect(f'{username}/{userpwd}@{host}:{port}/{service_name}') as connection :
    with connection.cursor() as cursor :
        query = cursor.execute(f'''
        SELECT "ID"
        FROM "ROUTE"
        WHERE "IS_ACTIVE" = 'T'
        ORDER BY "ID"
        ''')
        for _ in query :
            routes.append(_[0])

# Start with all weekdays and all active routes = 0
rep4 = pd.DataFrame(0, index=days, columns=routes)
rep4.index.name = "Day"

for _, row in rep4_Q.iterrows():
    day = row["DAY"].strip().title()
    rep4.loc[day, row["ROUTE_ID"]] = row["PASSENGERS"]

rep4.reset_index(inplace=True)

# Convert DataFrame to dictionary for JSON output
data = {
    "report_title": "Route Statistics",
    "date_range": f"{start_date} to {end_date}",
    "data": rep4.to_dict(orient='records')
}
print(json.dumps(data, indent=2, default=str))