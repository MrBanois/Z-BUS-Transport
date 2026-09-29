# Z-Bus Transport Report Generation Summary

This document summarizes all report generation code in the Report directory.

---

## Report Overview

| Report | Title | Purpose | Time Range | Output Format |
|--------|-------|---------|------------|---------------|
| Report 1 | Booking Statistics | Station-wise pickup and dropoff by month | Year Range | Pivot Table (JSON) |
| Report 2 | Booking Statistics | Monthly booking metrics with seat tracking | Year Range | Bar Chart + JSON |
| Report 3 | User Activity | Per-user booking activity breakdown | Date Range | Bar Chart + Pie Chart |
| Report 4 | Route Statistics | Passenger counts per route per day | Date Range | Pivot Table (JSON) |
| Report 6 | Driver Statistics | Driver trip counts with time breakdown | Date Range | Table (JSON) |
| Report 7 | Trips Statistics | Vehicle trips by type and plate number | Date Range | Table (JSON) |

---

## Detailed Report Descriptions

### **Report 1: Booking Statistics (Station-Level)**

**Purpose:** Analyze pickup and dropoff statistics at each bus station for a given year range.

**Inputs:**
- Username, Password, Host, Service Name
- Year (e.g., "2025")
- Year Range (e.g., "1" for single year, "2" for 2 years)

**Query Logic:**
- Joins: `station`, `booking`, `booking_detail`, `schedule`, `route`, `route_detail`, `status`
- Groups by station and month
- Uses `NVL` to handle NULL values

**Output Format:** Pivot table with:
- **Rows:** Station ID and Station Name
- **Columns:** Month (Jan, Feb, Mar, etc.) with separate columns for Pickup and Dropoff
- **Format:** JSON with `report_title`, `year_range`, and `data`

**Example Output Structure:**
```json
{
  "report_title": "Booking Statistics",
  "year_range": "2025 to 2025",
  "data": [
    {
      "station_id": 1,
      "Station": "Central Station",
      "Pickup_January": 150,
      "Dropoff_January": 120,
      ...
    }
  ]
}
```

---

### **Report 2: Booking Statistics (Monthly Metrics)**

**Purpose:** Track monthly booking performance with seat-level metrics.

**Inputs:**
- Username, Password, Host, Service Name
- Year
- Year Range

**Query Logic:**
- Joins: `BOOKING`, `BOOKING_DETAIL`
- Groups by month
- Uses `CASE` statements to categorize by `CURRENT_STATUS`:
  - Status '3': Cancelled
  - Status '2': Checked-In
  - Status '4': No-Show

**Output Format:** 
- **Bar Chart:** Clustered bar chart showing Check-in, Cancelled, and No-Show seats
- **JSON:** Monthly breakdown with `Month`, `Bookings`, `Seats`, `Cancelled`, `Checked-In`, `No-Show`

**Example Output Structure:**
```json
{
  "report_title": "Booking Statistics",
  "year_range": "2025 to 2025",
  "data": [
    {
      "Month": "Jan",
      "Bookings": 500,
      "Seats": 1200,
      "Cancelled": 50,
      "Checked-In": 800,
      "No-Show": 350
    }
  ]
}
```

---

### **Report 3: User Activity**

**Purpose:** Analyze individual user booking behavior over a date range.

**Inputs:**
- Username, Password, Host, Service Name
- Start Date (YYYY-MM-DD)
- End Date (YYYY-MM-DD)

**Query Logic:**
- Joins: `BOOKING`, `BOOKING_DETAIL`, `USER`
- Groups by user name (First + Last)
- Counts bookings and status-based breakdown

**Output Format:**
- **Bar Chart:** Per-user breakdown of Bookings, Check-in, Cancelled, No-Show
- **Pie Chart:** Overall proportion of status categories across all users
- **JSON:** User-level metrics

**Example Output Structure:**
```json
{
  "report_title": "User Activity",
  "date_range": "2025-04-12 to 2025-04-16",
  "data": [
    {
      "User": "John Doe",
      "Bookings": 5,
      "Checked-In": 3,
      "Cancelled": 1,
      "No-Show": 1
    }
  ]
}
```

---

### **Report 4: Route Statistics**

**Purpose:** Track passenger counts per route per day.

**Inputs:**
- Username, Password, Host, Service Name
- Start Date (YYYY-MM-DD)
- End Date (YYYY-MM-DD)

**Query Logic:**
- Joins: `TRIP_LOG`, `TRIP_LOG_DETAIL`, `BOOKING_DETAIL`, `ROUTE`
- Groups by day of week (Monday, Tuesday, etc.) and route ID
- Sums passenger count from `TRIP_LOG_DETAIL`

**Output Format:**
- Pivot table with days as rows and active routes as columns
- **JSON:** Structured route-day passenger data

**Example Output Structure:**
```json
{
  "report_title": "Route Statistics",
  "date_range": "2025-04-12 to 2025-04-16",
  "data": [
    {
      "Day": "Monday",
      "Route_1": 25,
      "Route_2": 30,
      "Route_3": 0
    }
  ]
}
```

---

### **Report 6: Driver Statistics**

**Purpose:** Analyze driver activity with time-based trip classification.

**Inputs:**
- Username, Password, Host, Service Name
- Start Date (YYYY-MM-DD)
- End Date (YYYY-MM-DD)

**Query Logic:**
- Joins: `TRIP_LOG`, `USER`
- Groups by driver ID and name
- Counts total trips and splits by time threshold (before/after 17:00)

**Output Format:**
- Table with driver statistics
- **JSON:** Driver trip counts

**Example Output Structure:**
```json
{
  "report_title": "Booking Statistics",
  "year_range": "2025-04-12 to 2025-04-16",
  "data": [
    {
      "Driver_ID": 5,
      "Name": "Jane Smith",
      "Total": 10,
      "Before_17": 7,
      "After_17": 3
    }
  ]
}
```

---

### **Report 7: Trips Statistics**

**Purpose:** Track vehicle trips by vehicle type and plate number.

**Inputs:**
- Username, Password, Host, Service Name
- Start Date (YYYY-MM-DD)
- End Date (YYYY-MM-DD)

**Query Logic:**
- Joins: `VEHICLE_TYPE`, `VEHICLE`, `TRIP_LOG` (LEFT JOIN)
- Groups by vehicle type and vehicle ID
- Counts trip log entries within date range

**Output Format:**
- Table with vehicle type, plate number, seat capacity, and trip count
- **JSON:** Vehicle trip statistics

**Example Output Structure:**
```json
{
  "report_title": "Trips Statistics",
  "date_range": "2025-04-12 to 2025-04-16",
  "data": [
    {
      "Type": "Small Bus",
      "PLATE_NO": "ABC-123",
      "Seat": 20,
      "Trips": 15
    }
  ]
}
```

---

## Common Technical Details

### Database Connection
All reports use **Oracle Database** via the `oracledb` Python package:
```python
connection = oracledb.connect(f'{username}/{userpwd}@{host}:{port}/{service_name}')
```

### Date Handling
- Oracle DATE type with `DATE 'YYYY-MM-DD'` syntax
- Date comparisons using `>= DATE '...'` and `< DATE '...'`
- Month extraction using `EXTRACT(MONTH FROM date_column)`

### Output Consistency
All reports output:
1. **JSON Data:** Printed via `json.dumps(data, indent=2, default=str)`
2. **Visualizations:** Generated using `matplotlib` (bar charts, pie charts)
3. **DataFrame Processing:** Using `pandas` for data manipulation

### Libraries Used
- `oracledb` - Database connectivity
- `getpass` - Secure password input
- `pandas` - Data manipulation and output formatting
- `matplotlib` - Chart generation
- `numpy` - Numerical operations for charting

---

## Report Summary Table

| Report | Primary Metric | Visualization | JSON Keys |
|--------|---------------|---------------|-----------|
| 1 | Pickup/Dropoff by Station | Pivot Table | report_title, year_range, data |
| 2 | Monthly Seat Metrics | Clustered Bar Chart | report_title, year_range, data |
| 3 | User-Level Activity | Bar + Pie Charts | date_range, data |
| 4 | Daily Route Passengers | Pivot Table | date_range, data |
| 6 | Driver Trip Counts | Table | year_range, data |
| 7 | Vehicle Trip Counts | Table | date_range, data |

---

*Generated: Report Analysis Summary for Z-Bus Transport SQL Reports*
