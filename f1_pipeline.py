import dlt

from rest_api import rest_api_source

f1_config = {
    "client": {
        "base_url": "https://ergast.com/api/f1/",
    },
    "resource_defaults": {
        "write_disposition": "replace",
        "endpoint": {
            "params": {
                "limit": 1000,
            },
        },
    },
    "resources": [
        {
            "name": "drivers",
            "endpoint": {
                "path": "drivers.json"
            }
        },
        "seasons.json",
        {
                "name": "season_details",
                "endpoint": {
                    "path": "{season_year}.json",
                    "params": {
                        "season_year": {
                            "type": "resolve",
                            "resource": "seasons.json",
                            "field": "season",
                        }
                    },
                }
        }
    ],
}
    
f1_source = rest_api_source(f1_config)
pipeline = dlt.pipeline(
    pipeline_name = "f1_pipeline",
    destination="duckdb",
    dataset_name='ergast',
    progress="log",
)

load_info = pipeline.run(f1_source)
print(load_info)
