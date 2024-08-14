import os
import snowflake.connector
import pandas as pd
from datetime import datetime
import requests
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
log = logging.getLogger(__name__)

BASE_URL = "https://raw.githubusercontent.com/JeffSackmann/tennis_atp/master"

def upload_to_snowflake(file_path, stage_name, user, password, account, warehouse, database, schema, role):
    try:
        with snowflake.connector.connect(
            user=user,
            password=password,
            account=account,
            warehouse=warehouse,
            database=database,
            schema=schema,
            role=role
        ) as conn:
            with conn.cursor() as cursor:
                cursor.execute(f'USE ROLE {role};')
                cursor.execute(f'USE DATABASE {database};')
                cursor.execute(f'USE SCHEMA {schema};')

                # Create the stage if it doesn't exist
                cursor.execute(f'CREATE STAGE IF NOT EXISTS {stage_name};')

                # Put the files into the Snowflake stage
                cursor.execute(f'PUT file://{file_path} @{stage_name} AUTO_COMPRESS=FALSE;')

                log.info(f"Successfully uploaded and loaded data from {file_path} into {database}.{schema}.{stage_name}")
    except snowflake.connector.errors.ProgrammingError as e:
        log.error(f"Snowflake ProgrammingError: {e}")
    except Exception as e:
        log.error(f"Unexpected error: {e}")

def table_exists(cursor, table_name):
    cursor.execute(f"""
        SELECT COUNT(*)
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_NAME = UPPER('{table_name}')
    """)
    return cursor.fetchone()[0] > 0

def atp_matches_source(cursor, table_name, year_from: int, year_to: int) -> pd.DataFrame:
    if table_exists(cursor, table_name):
        cursor.execute(f'SELECT MAX("tourney_date") FROM {table_name}')
        result = cursor.fetchone()[0]
        result = result if result else '19680101'
        log.info(f"Max tourney date: {result}")
    else:
        result = '19680101'

    all_matches = []
    for year in range(year_from, year_to + 1):
        matches_url = f"{BASE_URL}/{table_name}_{year}.csv"
        log.info(f"Downloading ATP matches data from: {matches_url}")

        matches_df = pd.read_csv(matches_url)
        matches_df = matches_df[matches_df['tourney_date'] > result]
        if not matches_df.empty:
            all_matches.append(matches_df)

    return pd.concat(all_matches, ignore_index=True) if all_matches else pd.DataFrame()

def atp_players_source(cursor, table_name) -> pd.DataFrame:
    if table_exists(cursor, table_name):
        cursor.execute(f'SELECT MAX("player_id") FROM {table_name}')
        result = cursor.fetchone()[0]
        result = result if result else 0
    else:
        result = 0

    players_url = f"{BASE_URL}/{table_name}.csv"
    log.info(f"Downloading ATP players data from: {players_url}")

    players_df = pd.read_csv(players_url)
    players_df = players_df[players_df['player_id'] > result]

    return players_df if not players_df.empty else pd.DataFrame()

def atp_rankings_source(cursor, table_name) -> pd.DataFrame:
    if table_exists(cursor, table_name):
        cursor.execute(f'SELECT MAX("ranking_date") FROM {table_name}')
        result = cursor.fetchone()[0]
        result = result if result else '19680101'
        log.info(f"Max ranking date: {result}")
    else:
        result = '19680101'

    decades = ['70', '80', '90', '00', '10', '20']
    files = [f"{table_name}_{decade}s.csv" for decade in decades]
    files.append(f"{table_name}_current.csv")

    all_rankings = []
    for file_name in files:
        rankings_url = f"{BASE_URL}/{file_name}"
        log.info(f"Downloading ATP rankings data from: {rankings_url}")

        rankings_df = pd.read_csv(rankings_url)
        rankings_df = rankings_df[rankings_df['ranking_date'] > result]
        if not rankings_df.empty:
            all_rankings.append(rankings_df)

    return pd.concat(all_rankings, ignore_index=True) if all_rankings else pd.DataFrame()

def countries_data_source() -> pd.DataFrame:
    url = 'https://restcountries.com/v3.1/all'
    log.info(f"Downloading countries JSON data from: {url}")

    response = requests.get(url)
    response.raise_for_status()
    json_data = response.json()

    countries_df = pd.json_normalize(json_data)
    return countries_df

if __name__ == "__main__":
    # Snowflake credentials and configurations
    user = os.getenv("SNOWFLAKE_USER")
    password = os.getenv("SNOWFLAKE_PASSWORD")
    account = os.getenv("SNOWFLAKE_ACCOUNT")
    warehouse = os.getenv("SNOWFLAKE_WAREHOUSE")
    database = os.getenv("SNOWFLAKE_DATABASE")
    schema = os.getenv("SNOWFLAKE_SCHEMA")
    role = os.getenv("SNOWFLAKE_ROLE")
    stage_name = os.getenv("SNOWFLAKE_STAGE")

    # Get the current year
    current_year = datetime.now().year

    # Define table names
    matches_table = "atp_matches"
    players_table = "atp_players"
    rankings_table = "atp_rankings"
    countries_table = "countries"

    try:
        with snowflake.connector.connect(
            user=user,
            password=password,
            account=account,
            warehouse=warehouse,
            database=database,
            schema=schema,
            role=role
        ) as conn:
            with conn.cursor() as cursor:
                # 1. Process ATP matches data
                matches_df = atp_matches_source(cursor, matches_table, year_from=1968, year_to=current_year)
                if not matches_df.empty:
                    local_file_path = f"{matches_table}.csv"
                    matches_df.to_csv(local_file_path, index=False)
                    upload_to_snowflake(local_file_path, stage_name, user, password, account, warehouse, database, schema, role)
                    os.remove(local_file_path)
                else:
                    log.info(f"No new data to upload for table {matches_table}")

                # 2. Process ATP players data
                players_df = atp_players_source(cursor, players_table)
                if not players_df.empty:
                    local_file_path = f"{players_table}.csv"
                    players_df.to_csv(local_file_path, index=False)
                    upload_to_snowflake(local_file_path, stage_name, user, password, account, warehouse, database, schema, role)
                    os.remove(local_file_path)
                else:
                    log.info(f"No new data to upload for table {players_table}")

                # 3. Process ATP rankings data
                rankings_df = atp_rankings_source(cursor, rankings_table)
                if not rankings_df.empty:
                    local_file_path = f"{rankings_table}.csv"
                    rankings_df.to_csv(local_file_path, index=False)
                    upload_to_snowflake(local_file_path, stage_name, user, password, account, warehouse, database, schema, role)
                    os.remove(local_file_path)
                else:
                    log.info(f"No new data to upload for table {rankings_table}")

                # 4. Process countries data
                countries_df = countries_data_source()
                if not countries_df.empty:
                    local_file_path = f"{countries_table}.json"
                    countries_df.to_json(local_file_path, orient='records', lines=True)
                    upload_to_snowflake(local_file_path, stage_name, user, password, account, warehouse, database, schema, role)
                    os.remove(local_file_path)
                else:
                    log.info(f"No new data to upload for table {countries_table}")

    except snowflake.connector.errors.ProgrammingError as e:
        log.error(f"Snowflake ProgrammingError: {e}")
    except Exception as e:
        log.error(f"Unexpected error: {e}")
