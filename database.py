import pyodbc

def get_sql_connection():
    server = r'DEFNE\MSSQLSERVER02'
    database = 'SinavPlanlamaDB'

    conn_str = (
        f'DRIVER={{SQL Server}};'
        f'SERVER={server};'
        f'DATABASE={database};'
        f'Trusted_Connection=yes;'
        f'TrustServerCertificate=yes;'
    )

    try:
        return pyodbc.connect(conn_str)
    except Exception as e:
        print(f"\n❌ [CRITICAL DATABASE ERROR]: {e}\n")
        return None


def get_connection_info():
    return {
        "server": r"DEFNE\MSSQLSERVER02",
        "database": "SinavPlanlamaDB"
    }


def is_mock_mode():
    return False