from fastapi import APIRouter, HTTPException
from Connect_DB import get_db_connection
from datetime import datetime
from schemas import Report

import pandas as pd

router = APIRouter()

@router.post("/report1", response_model=Report)
def generate_report_1() -> Report :
    return

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
            date_range = f"{start_date} to {end_date}",
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
def generate_report_4() -> Report :
    return

@router.post("/report7", response_model=Report)
def generate_report_7() -> Report :
    return
