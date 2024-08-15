import snowflake.connector
import os

def read_from_snowflake_stage(stage_name, user, password, account, warehouse, database, schema, role, local_path):
    conn = snowflake.connector.connect(
        user=user,
        password=password,
        account=account,
        warehouse=warehouse,
        database=database,
        schema=schema,
        role=role
    )

    try:
        cursor = conn.cursor()

        cursor.execute(f'USE ROLE {role};')
        cursor.execute(f'USE DATABASE {database};')
        cursor.execute(f'USE SCHEMA {schema};')

        # List the files in the stage
        cursor.execute(f"LIST @{stage_name};")
        files = cursor.fetchall()

        # Download each file from the stage to the local directory
        for file_info in files:
            file_name = file_info[0].split('/')[-1]
            get_statement = f"GET @{stage_name}/{file_name} file://{local_path};"
            cursor.execute(get_statement)
            print(f"Downloaded file: {file_name} to {local_path}")

    except snowflake.connector.errors.ProgrammingError as e:
        print(f"Snowflake ProgrammingError: {e}")
    finally:
        if cursor:
            cursor.close()
        conn.close()

if __name__ == "__main__":
    # Snowflake credentials
    user=os.getenv("SNOWFLAKE_USER")
    password=os.getenv("SNOWFLAKE_PASSWORD")
    account=os.getenv("SNOWFLAKE_ACCOUNT")
    warehouse=os.getenv("SNOWFLAKE_WAREHOUSE")
    database=os.getenv("SNOWFLAKE_DATABASE")
    schema=os.getenv("SNOWFLAKE_SCHEMA")
    role=os.getenv("SNOWFLAKE_ROLE")
    stage_name=os.getenv("SNOWFLAKE_STAGE")
    local_path = './'

read_from_snowflake_stage(stage_name, user, password, account, warehouse, database, schema, role, local_path)