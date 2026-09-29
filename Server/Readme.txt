The server only implement what matters
Password Generation method
    MD5(ID + Password) - Not secure
    
What matters
    CRUD
        USER (User.py)
        ROUTE (Route.py) #Just get function
        PERMISSIONS (Positions.py)
        DEPARTMENT (Department.py)
    REPORT (Reports.py)
        REPORT-1
        REPORT-2
        REPORT-3
        REPORT-4
        REPORT-7
    LOGIN (main.py)

.ENV structure
DB_USER=
DB_PASSWORD=
DB_HOST=
DB_PORT=
DB_SERVICE_NAME=

Note
    Report4 returns column ID, UI must pull Route List by itself.