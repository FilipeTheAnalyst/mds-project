import os
import snowflake.connector

def upload_to_snowflake(json_files, stage_name, user, password, account, warehouse, database, schema, role):
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

        cursor.execute(f'CREATE STAGE IF NOT EXISTS {stage_name};')

        for file in json_files:
            cursor.execute(f'PUT file://{file} @{stage_name} AUTO_COMPRESS=FALSE;')

            print(f"Succesfully uploaded {file} file into stage: {database}.{schema}.{stage_name}")

    except snowflake.connector.errors.ProgrammingError as e:
        print(f"Snowflake ProgrammingError: {e}")
    finally:
        if cursor:
            cursor.close()
        conn.close()

def get_json_files(directory):
    json_files = []
    for filename in os.listdir(directory):
        if filename.endswith('.json'):
            json_files.append(os.path.join(directory, filename))
    return json_files

if __name__ == "__main__":
    # Snowflake credentials
    user=os.getenv("DBT_USER")
    password=os.getenv("DBT_PASSWORD")
    account=os.getenv("SNOWFLAKE_ACCOUNT")
    warehouse=os.getenv("SNOWFLAKE_WAREHOUSE")
    database=os.getenv("SNOWFLAKE_DATABASE")
    schema=os.getenv("SNOWFLAKE_PROD_SCHEMA")
    role=os.getenv("SNOWFLAKE_ROLE")
    stage_name=os.getenv("SNOWFLAKE_STAGE")

    file_path = os.getcwd() + '/target'
    json_files = get_json_files(file_path)

    # Upload the processed json files to Snowflake
    upload_to_snowflake(json_files, stage_name, user, password, account, warehouse, database, schema, role)