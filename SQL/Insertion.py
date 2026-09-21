import oracledb
import getpass
import hashlib #For generating user Passwd MD5(Userid+Passwrod)

TABLES = [
    'VEHICLE_TYPE',
    'POSITION',
    'STATUS',
    'DEPARTMENT',
    'STATION',
    'VEHICLE',
    'USER',
    'ROUTE',
    'ROUTE_DETAIL',
    'SCHEDULE',
    'BOOKING',
    'BOOKING_DETAIL',
    'TRIP_LOG',
    'TRIP_LOG_DETAIL']

def main() :
    username = input("Enter Username : ")
    userpwd = getpass.getpass(f"Enter password : ")
    host = input("Enter Host : ") # "localhost"
    port = 1521 #Assume Default port
    service_name = input("Enter Service Name : ") # "freepdb1","database1"

    try :
        print('Connecting To Database')

        with oracledb.connect(f'{username}/{userpwd}@{host}:{port}/{service_name}') as connection :
            with connection.cursor() as cursor :

                print("Select Table to insert")
                for i,table in enumerate(TABLES) :
                    print(f'{i} : {table}')

    except Exception as e :
        print(e)

if __name__ == "__main__" :
    main()