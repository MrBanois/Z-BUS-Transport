import oracledb
import getpass
import pandas as pd
import json

username = input("Enter Username : ")
userpwd = getpass.getpass(f"Enter password : ")
host = input("Enter Host : ") # "localhost"
port = 1521 #Assume Default port
service_name = input("Enter Service Name : ") # "freepdb1","database1"
rep6 = pd.DataFrame(columns=["Driver_ID", "Name", "Total", "Before_17", "After_17"])

with oracledb.connect(f'{username}/{userpwd}@{host}:{port}/{service_name}') as connection :
    with connection.cursor() as cursor :
        start_date = input("Start date (YYYY-MM-DD) : ") # 2025-04-12
        end_date = input("End date (YYYY-MM-DD) : ") # 2025-04-16
        query = cursor.execute(f'''
            SELECT
                TL."DRIVER" AS "DRIVER_ID",
                U."F_NAME" || ' ' || U."L_NAME" AS "DRIVER",
                COUNT(*) AS "TOTAL",
                SUM(
                    CASE
                        WHEN TO_CHAR(TL."TIME_START", 'HH24:MI:SS') < '17:00:00'
                        THEN 1 ELSE 0
                    END
                ) AS "BEFORE_17",
                SUM(
                    CASE
                        WHEN TO_CHAR(TL."TIME_START", 'HH24:MI:SS') >= '17:00:00'
                        THEN 1 ELSE 0
                    END
                ) AS "AFTER_17"
            FROM
                "TRIP_LOG" TL
                JOIN "USER" U
                    ON TL."DRIVER" = U."ID"
            WHERE
                TL."DATE" >= DATE '{start_date}'
                AND TL."DATE" < DATE '{end_date}'
            GROUP BY
                TL."DRIVER",
                U."F_NAME",
                U."L_NAME"
            ORDER BY
                TL."DRIVER";
        ''')
        for _ in query : 
            rep6.loc[len(rep6)] = _

        data = {
            "report_title": "Late Trip Statistics",
            "year_range": f"{start_date} to {end_date}",
            "data": rep6.to_dict(orient='records')
        }
        print(json.dumps(data, indent=2, default=str))