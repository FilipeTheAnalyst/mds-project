# Introduction and Environment Setup

## Snowflake user creation
Copy these SQL statements into a Snowflake Worksheet, select all and execute them (i.e. pressing the play button).

```sql
-- Use the ACCOUNTADMIN role
USE ROLE ACCOUNTADMIN;

-- Create the `transform` role
CREATE ROLE IF NOT EXISTS TRANSFORM;

-- Create the `dbt` user and assign to role
CREATE USER IF NOT EXISTS dbt
  PASSWORD='dbtPassword123'
  LOGIN_NAME='dbt'
  MUST_CHANGE_PASSWORD=FALSE
  DEFAULT_WAREHOUSE='COMPUTE_WH'
  DEFAULT_ROLE='transform'
  DEFAULT_NAMESPACE='ATP_TOUR.RAW'
  COMMENT='DBT user used for data transformation';
GRANT ROLE transform to USER dbt;

-- Create our database and schema
CREATE DATABASE IF NOT EXISTS ATP_TOUR;
CREATE SCHEMA IF NOT EXISTS ATP_TOUR.RAW;

-- Set up permissions to role `transform`
GRANT ALL ON WAREHOUSE COMPUTE_WH TO ROLE transform; 
GRANT ALL ON DATABASE ATP_TOUR to ROLE transform;
GRANT ALL ON ALL SCHEMAS IN DATABASE ATP_TOUR to ROLE transform;
GRANT ALL ON FUTURE SCHEMAS IN DATABASE ATP_TOUR to ROLE transform;
GRANT ALL ON ALL TABLES IN SCHEMA ATP_TOUR.RAW to ROLE transform;
GRANT ALL ON FUTURE TABLES IN SCHEMA ATP_TOUR.RAW to ROLE transform;

```