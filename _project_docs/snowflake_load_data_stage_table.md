# Stored Procedure on Snowflake to load data from internal stage to table Rankings

```sql
CREATE OR REPLACE PROCEDURE load_data_from_stage(
    database_dest STRING, 
    schema_dest STRING,
    stage_name STRING
)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python', 'pandas')
HANDLER = 'load_data'
EXECUTE AS CALLER
AS
$$


import snowflake.snowpark as snowpark
# from snowflake.snowpark.dataframe import *
from datetime import timedelta, date, datetime
import pandas as pd


def load_data(session: snowpark.Session, database_dest, schema_dest, stage_name):

    # Set the destination database and schema
    session.sql(f"USE DATABASE {database_dest};").collect()
    session.sql(f"USE SCHEMA {schema_dest};").collect()

    csv_file_format = 'csv_file_format'

    json_file_format = 'json_file_format'

    # Check if CSV file format exists
    csv_file_format_check = session.sql(f"""
        SELECT FILE_FORMAT_NAME
        FROM INFORMATION_SCHEMA.FILE_FORMATS
        WHERE FILE_FORMAT_NAME = UPPER('{csv_file_format}');
    """).collect()

    if not csv_file_format_check:
        session.sql(f"""
                CREATE FILE FORMAT {csv_file_format}
                  TYPE = 'CSV'
                  FIELD_DELIMITER = ',' 
                  PARSE_HEADER = TRUE
                  ;
            """).collect()

    # Check if JSON file format exists
    json_file_format_check = session.sql(f"""
        SELECT FILE_FORMAT_NAME
        FROM INFORMATION_SCHEMA.FILE_FORMATS
        WHERE FILE_FORMAT_NAME = UPPER('{json_file_format}');
    """).collect()

    if not json_file_format_check:
        session.sql(f"""
                CREATE FILE FORMAT {json_file_format}
                  TYPE = 'JSON'
                  STRIP_OUTER_ARRAY = TRUE
                  ;
            """).collect()

    
    # Check for files in the stage
    files_on_stage = session.sql(f"""
        SELECT distinct(METADATA$FILENAME) FILE
        FROM @{database_dest}.{schema_dest}.{stage_name};
    """).collect()

    if not files_on_stage:
        return "No files found in the stage."

    # Create a DataFrame to store file and the table name 
    df_files_information = pd.DataFrame(columns=['FILE_NAME', 'TABLE_NAME'])
    
    # Split the information to get file name and table name 
    for file in files_on_stage:
        file_name, table_name, file_extension = file['FILE'], file['FILE'].split('.')[0], file['FILE'].split('.')[1]

        new_df = pd.DataFrame({
            'FILE_NAME': [file_name], 
            'TABLE_NAME': [table_name],
            'FILE_EXTENSION': [file_extension]
        })

        df_files_information = pd.concat([df_files_information, new_df], ignore_index=True)

        # Check if the table exists
        table_exists = session.sql(f"""
            SELECT COUNT(*)
            FROM INFORMATION_SCHEMA.TABLES
            WHERE TABLE_NAME = UPPER('{table_name}')
        """).collect()[0][0] > 0

        if not table_exists:
            if file_extension == 'csv':

                session.sql(f"""
                    CREATE TABLE {table_name}
                        USING TEMPLATE (
                            SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
                            FROM TABLE(
                                INFER_SCHEMA(
                                    LOCATION=>'@{stage_name}/{file_name}',
                                    FILE_FORMAT=>'{csv_file_format}'
                                )
                            )
                        );
                """).collect()

        if file_extension == 'csv':
            # Execute COPY INTO command for each table
            session.sql(f"""
                COPY INTO {table_name}
                FROM '@{stage_name}/{file_name}'
                FILE_FORMAT = (FORMAT_NAME = '{csv_file_format}')
                ON_ERROR = SKIP_FILE
                PURGE = TRUE
                MATCH_BY_COLUMN_NAME = CASE_SENSITIVE;
            """).collect()

        else:

            session.sql(f"""
                    CREATE OR REPLACE TABLE {table_name}
                        USING TEMPLATE (
                            SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
                            FROM TABLE(
                                INFER_SCHEMA(
                                    LOCATION=>'@{stage_name}/{file_name}',
                                    FILE_FORMAT=>'{json_file_format}'
                                )
                            )
                        );
                """).collect()

            # Execute COPY INTO command for each table
            session.sql(f"""
                COPY INTO {table_name}
                FROM '@{stage_name}/{file_name}'
                FILE_FORMAT = (FORMAT_NAME = '{json_file_format}')
                ON_ERROR = SKIP_FILE
                PURGE = TRUE
                MATCH_BY_COLUMN_NAME = CASE_SENSITIVE;
            """).collect()
    
    return f"Data loaded to '{database_dest}.{schema_dest}'"

$$
```