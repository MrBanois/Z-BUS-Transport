# =============================================================================
# Stored column widths
# =============================================================================
# These mirror the DDL in SQL-Docs/SQL-Create-FULL-V2.txt. They live here rather
# than in one router because two routers write to the same columns (Auth.py
# creates accounts, CRUD/User.py updates them) and a limit that drifts between
# them produces a 500 from Oracle instead of a 400 with a usable message.

# USER.F_NAME / USER.L_NAME are VARCHAR2(20)
MAX_NAME_LENGTH = 20

# USER.EMAIL is VARCHAR2(100)
MAX_EMAIL_LENGTH = 100

# DEPARTMENT.ID and POSITION.ID are CHAR(5), padded with spaces
MAX_DEPARTMENT_LENGTH = 5
MAX_POSITION_LENGTH = 5

# DEPARTMENT.NAME and POSITION.NAME are both VARCHAR2(20) in the DDL. One
# constant because they are one number today; if either column ever changes,
# split it here rather than loosening the check to fit the wider one.
MAX_REFERENCE_NAME_LENGTH = 20

# USER.SALARY is number(8,2). The upper bound is 999999.99; the lower bound is
# left to the caller, since a zero salary is legitimate for a volunteer and a
# negative one is a data-entry mistake rather than a representation.
MAX_SALARY = 999999.99

# Enforced by Auth.py at registration. Stored length is not checked here: a
# password the server did not create is a different problem from a short one.
MIN_PASSWORD_LENGTH = 6
