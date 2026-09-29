from fastapi import APIRouter, HTTPException
from Connect_DB import get_db_connection
from datetime import datetime
from schemas import Report

import pandas as pd

router = APIRouter()

@router.post("/report1", response_model=Report)
def generate_report_1(year : int, range : int) -> Report : # 2024, 2
    conn = None
    cursor = None
    try :
        conn = get_db_connection()
        if not conn :
            raise HTTPException(status_code=500, detail="Database connection failed")
        
        cursor = conn.cursor()
        report = pd.DataFrame(columns=["station_id", "Station", "month_no", "Date_Month", "Pickup", "Dropoff"])
        sql = '''
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
                    b."DATE" >= :start_date
                    AND b."DATE" < :end_date

                GROUP BY
                    rds.station,
                    EXTRACT(MONTH FROM b."DATE")
            ) x
                ON x.station_id = s.id
               AND x.month_no = m.month_no

            ORDER BY
                s.id,
                m.month_no
        '''

        start_date = datetime(year, 1, 1)
        end_date = datetime(year + range, 1, 1)

        query = cursor.execute(
            sql,
            start_date=start_date,
            end_date=end_date
        )
        for _ in query : 
            report.loc[len(report)] = _

        df = report.sort_values('month_no')

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

        # Convert DataFrame to dictionary for JSON output
        return Report(
            report_title = "Station Statistics",
            date_range = f"{year} to {int(year) + int(range) - 1}",
            data =  df_wide.to_dict(orient='records')
        )
    
    except HTTPException as he :
        raise he
    except Exception as e :
        print(f"Error : {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error")
    finally :
        if cursor :
            cursor.close()
        if conn :
            conn.close()

@router.post("/report2", response_model=Report)
def generate_report_2(year : int, range : int) -> Report : # 2024, 2
    conn = None
    cursor = None
    try :
        conn = get_db_connection()
        if not conn :
            raise HTTPException(status_code=500, detail="Database connection failed")
        
        cursor = conn.cursor()
        report = pd.DataFrame(columns=["Month", "Bookings", "Seats", "Cancelled", "Checked-In", "No-Show"])
        sql = '''
            SELECT
                TO_CHAR(M.MONTH_DATE, 'FMMonth') AS "Month",
                COUNT(BD."BID") AS "Booking Count",
                NVL(SUM(BD."SEAT"), 0) AS "Seat Booked",
                NVL(SUM(CASE
                    WHEN BD."CURRENT_STATUS" = '3' THEN BD."SEAT"
                    ELSE 0
                END), 0) AS "Cancelled",
                NVL(SUM(CASE
                    WHEN BD."CURRENT_STATUS" = '2' THEN BD."SEAT"
                    ELSE 0
                END), 0) AS "Checked-In",
                NVL(SUM(CASE
                    WHEN BD."CURRENT_STATUS" = '4' THEN BD."SEAT"
                    ELSE 0
                END), 0) AS "No-Show"
            FROM (
                SELECT LEVEL AS MONTH_NO,
                       ADD_MONTHS(DATE '2025-01-01', LEVEL - 1) AS MONTH_DATE
                FROM DUAL
                CONNECT BY LEVEL <= 12
            ) M
            LEFT JOIN "BOOKING" B
                ON EXTRACT(MONTH FROM B."DATE") = M.MONTH_NO
               AND B."DATE" >= :start_date
               AND B."DATE" < :end_date
            LEFT JOIN "BOOKING_DETAIL" BD
                ON B."BOOKING_ID" = BD."BID"
            GROUP BY
                M.MONTH_NO,
                M.MONTH_DATE
            ORDER BY
                M.MONTH_NO
        '''

        start_date = datetime(year, 1, 1)
        end_date = datetime(year + range, 1, 1)

        query = cursor.execute(
            sql,
            start_date=start_date,
            end_date=end_date
        )
        for _ in query : 
            report.loc[len(report)] = _

        # Convert DataFrame to dictionary for JSON output
        return Report(
            report_title = "Booking Statistics",
            date_range = f"{year} to {int(year) + int(range) - 1}",
            data =  report.to_dict(orient='records')
        )
    
    except HTTPException as he :
        raise he
    except Exception as e :
        print(f"Error : {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error")
    finally :
        if cursor :
            cursor.close()
        if conn :
            conn.close()

@router.post("/report3", response_model=Report) # 2025-04-12, 2025-04-16
def generate_report_3(start_date : datetime, end_date : datetime) -> Report :
    conn = None
    cursor = None
    try :
        conn = get_db_connection()
        if not conn :
            raise HTTPException(status_code=500, detail="Database connection failed")
        
        cursor = conn.cursor()
        report = pd.DataFrame(columns=["User", "Bookings", "Checked-In", "Cancelled", "No-Show"])

        sql = '''
            SELECT 
                US."F_NAME" || ' ' || US."L_NAME" AS "User",
                COUNT(BD."BID") AS "Bookings",
                COUNT(CASE WHEN BD."CURRENT_STATUS" = '2' THEN 1 END) AS "Checked_In",
                COUNT(CASE WHEN BD."CURRENT_STATUS" = '3' THEN 1 END) AS "Cancelled",
                COUNT(CASE WHEN BD."CURRENT_STATUS" = '4' THEN 1 END) AS "No-Show"
            FROM
                "BOOKING" B
                JOIN "BOOKING_DETAIL" BD ON B."BOOKING_ID" = BD.BID
                JOIN "USER" US ON B."USER" = US."ID"
            WHERE
                B."DATE" BETWEEN :start_date AND :end_date
            GROUP BY US."F_NAME", US."L_NAME"
        '''
        query = cursor.execute(
            sql,
            start_date=start_date,
            end_date=end_date
        )
        
        for _ in query : 
            report.loc[len(report)] = _

        return Report(
            report_title = "User activity",
            date_range = f"{start_date.date()} to {end_date.date()}",
            data = report.to_dict(orient = "records")
        )
    
    except HTTPException as he :
        raise he
    except Exception as e :
        print(f"Error : {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error")
    finally :
        if cursor :
            cursor.close()
        if conn :
            conn.close()

@router.post("/report4", response_model=Report)
def generate_report_4(start_date : datetime, end_date : datetime) -> Report : # 2025-04-12, 2025-04-16
    conn = None
    cursor = None
    try :
        conn = get_db_connection()
        if not conn :
            raise HTTPException(status_code=500, detail="Database connection failed")
        
        cursor = conn.cursor()
        report = pd.DataFrame(columns=["DAY", "ROUTE_ID", "ROUTE_NAME", "PASSENGERS"])
        sql = '''
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
                TL."DATE" >= :start_date
                AND TL."DATE" < :end_date
            GROUP BY
                TO_CHAR(TL."DATE", 'DAY'),
                R."ID",
                R."NAME"
        '''

        query = cursor.execute(
            sql,
            start_date=start_date,
            end_date=end_date
        )
        for _ in query : 
            report.loc[len(report)] = _

        rep4 : pd.DataFrame
        routes : list[str] = []
        days = [ "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

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

        for _, row in report.iterrows():
            day = row["DAY"].strip().title()
            rep4.loc[day, row["ROUTE_ID"]] = row["PASSENGERS"]

        rep4.reset_index(inplace=True)


        # Convert DataFrame to dictionary for JSON output
        return Report(
            report_title = "Route Statistics",
            date_range = f"{start_date.date()} to {end_date.date()}",
            data =  rep4.to_dict(orient='records')
        )
    
    except HTTPException as he :
        raise he
    except Exception as e :
        print(f"Error : {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error")
    finally :
        if cursor :
            cursor.close()
        if conn :
            conn.close()

@router.post("/report6", response_model=Report)
def generate_report_6(start_date : datetime, end_date : datetime) -> Report : # 2025-04-12, 2025-04-16
    conn = None
    cursor = None
    try :
        conn = get_db_connection()
        if not conn :
            raise HTTPException(status_code=500, detail="Database connection failed")
        
        cursor = conn.cursor()
        report = pd.DataFrame(columns=["Driver_ID", "Name", "Total", "Before_17", "After_17"])
        sql = '''
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
                TL."DATE" >= :start_date
                AND TL."DATE" < :end_date
            GROUP BY
                TL."DRIVER",
                U."F_NAME",
                U."L_NAME"
            ORDER BY
                TL."DRIVER"
        '''

        query = cursor.execute(
            sql,
            start_date=start_date,
            end_date=end_date
        )
        for _ in query : 
            report.loc[len(report)] = _

        # Convert DataFrame to dictionary for JSON output
        return Report(
            report_title = "Late Trip Statistics",
            date_range = f"{start_date.date()} to {end_date.date()}",
            data =  report.to_dict(orient='records')
        )
    
    except HTTPException as he :
        raise he
    except Exception as e :
        print(f"Error : {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error")
    finally :
        if cursor :
            cursor.close()
        if conn :
            conn.close()

@router.post("/report7", response_model=Report)
def generate_report_7(start_date : datetime, end_date : datetime) -> Report : # 2025-04-12, 2025-04-16
    conn = None
    cursor = None
    try :
        conn = get_db_connection()
        if not conn :
            raise HTTPException(status_code=500, detail="Database connection failed")
        
        cursor = conn.cursor()
        report = pd.DataFrame(columns=["Type", "PLATE_NO", "Seat", "Trips"])
        sql = '''
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
                        AND TL."DATE" >= :start_date
                        AND TL."DATE" < :end_date
            GROUP BY
                VT."ID",
                VT."NAME",
                V."ID",
                V."SEAT",
                V."PLATE_NO"
            ORDER BY
                VT."ID",
                V."ID"
        '''

        query = cursor.execute(
            sql,
            start_date=start_date,
            end_date=end_date
        )
        for _ in query : 
            report.loc[len(report)] = _

        # Convert DataFrame to dictionary for JSON output
        return Report(
            report_title = "Trips Statistics",
            date_range = f"{start_date.date()} to {end_date.date()}",
            data =  report.to_dict(orient='records')
        )
    
    except HTTPException as he :
        raise he
    except Exception as e :
        print(f"Error : {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error")
    finally :
        if cursor :
            cursor.close()
        if conn :
            conn.close()
