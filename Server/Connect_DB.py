from dotenv import load_dotenv
import oracledb
import os

load_dotenv()

def get_db_connection():
    try:
        # 'thin' mode doesn't require Oracle Instant Client installed
        conn = oracledb.connect(
            f'{os.getenv("DB_USER")}/{os.getenv("DB_PASSWORD")}@{os.getenv("DB_HOST")}:{os.getenv("DB_PORT")}/{os.getenv("DB_SERVICE_NAME")}')
        #USER / PASSWORD @ HOST : PORT / SERVICE
        return conn
    except Exception as e:
        print(f"Error connecting to Oracle: {e}")
        return None