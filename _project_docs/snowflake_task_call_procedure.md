# Task to automate Stored Procedure to load data from stage

```sql
CREATE OR REPLACE task RAW_DATA_LOAD_TASK
	warehouse=COMPUTE_WH
	schedule='USING CRON 15 10 * * * UTC'
	AS CALL load_data_from_stage('ATP_TOUR', 'RAW', 'DBT_ARTIFACTS');
```

## Resume Task
```sql
ALTER TASK RAW_DATA_LOAD_TASK RESUME;
```