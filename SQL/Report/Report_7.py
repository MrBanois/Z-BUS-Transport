import oracledb
import getpass
import pandas as pd
import json

username = input("Enter Username : ")
userpwd = getpass.getpass(f"Enter password : ")
host = input("Enter Host : ") # "localhost"
port = 1521 #Assume Default port
service_name = input("Enter Service Name : ") # "freepdb1","database1"

rep7 = pd.DataFrame(columns=["Type", "PLATE_NO", "Seat", "Trips"])

with oracledb.connect(f'{username}/{userpwd}@{host}:{port}/{service_name}') as connection :
    with connection.cursor() as cursor :
        start_date = input("Start date (YYYY-MM-DD) : ") # 2025-04-12
        end_date = input("End date (YYYY-MM-DD) : ") # 2025-04-16
        query = cursor.execute(f'''
            SELECT
                VT."NAME" AS "VEHICLE_TYPE",
                V."PLATE_NO",
                V."SEAT",
                COUNT(TL."LOG_ID") AS "TRIPS"
            FROM 
                "VEHICLE_TYPE" VT
                JOIN "VEHICLE" V
                    ON V."TYPE" = VT."ID"
                LEFT JOIN "TRIP_LOG" TL
                    ON TL."VEHICLE" = V."ID"
                        AND TL."DATE" >= DATE '{start_date}'
                        AND TL."DATE" < DATE '{end_date}'
            GROUP BY
                VT."ID",
                VT."NAME",
                V."ID",
                V."SEAT",
                V."PLATE_NO"
            ORDER BY
                VT."ID",
                V."ID"
        ''')
        for _ in query : 
            rep7.loc[len(rep7)] = _

        # Convert DataFrame to dictionary for JSON output
        data = {
            "report_title": "Trips Statistics",
            "date_range": f"{start_date} to {end_date}",
            "data": rep7.to_dict(orient='records')
        }
        print(json.dumps(data, indent=2, default=str))