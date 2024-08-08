# What this project is about

This is a MDS (Modern Data Stack) project which uses the [ATP Tennis Rankings, Results, and Stats](https://github.com/JeffSackmann/tennis_atp) dataset that is publicly available on Github, to demonstrate how to build and structure a data architecture from scratch suitable for analytics.

## Architecture

![Architecture](/_project_docs/Modern_Data_Stack_Project_Architecture.png)

## Pre-requisites

For this project make sure you have following installed:

-   [Git](https://git-scm.com/downloads)
-   [Python](https://www.python.org/downloads/)
-   [DuckDB CLI](https://duckdb.org/docs/installation/index)

## Getting started with this project

Clone the [ATP Tour project](https://github.com/achilala/dbt-atp-tour) to somewhere on your local directory
```bash
git clone https://github.com/achilala/dbt-atp-tour.git
cd dbt-atp-tour
```

Create a virtual environment for your python dependencies and activate it. Your python dependencies will be installed here.
```bash
python3 -m venv .venv/dbt-atp-tour
source .venv/dbt-atp-tour/bin/activate
```

Install the python dependencies
```bash
pip install -r requirements.txt
```

Some of the installed modules require reactivating your virtual environment to take effect
```bash
deactivate
source .venv/dbt-atp-tour/bin/activate
```

Running this python script will read the ATP tour data into a duckdb database called `atp_tour.duckdb`
```python 
python3 el_sources_data.py
```

A new file called `atp_tour.duckdb` should appear in the folder, and this is the `DuckDB` database file. The reason why `DuckDB` is my-go-to database is because it's very light, simple to setup and built for analytical processing.

Before running `dbt` makes sure the `profiles.yml` file is setup corrently. The `path` in the file should point to your duckdb database and on mine it looks something like this `atp_tour.duckdb`.

Test your connection and adjust your `profiles.yml` settings accordingly until you get a successful test.
```bash
dbt debug
```

Run the dbt project to build your models for analysis
```bash
dbt clean && dbt deps && dbt build
```

To generate and view the project documentation run the following.
```bash
dbt docs generate && dbt docs serve
```

A browser should open with the docs site or [click here](http://127.0.0.1:8080/#!/overview). To cancel press the following on the keyboard
```bash
^c
```

Use the `DuckDB CLI` to query the `DuckDB` database. If you don't already have DuckDB v0.8.1 or higher installed then proceed to do the following:

Download and unzip the CLI
```bash
curl -OL https://github.com/duckdb/duckdb/releases/download/v0.9.1/duckdb_cli-osx-universal.zip
unzip duckdb_cli-osx-universal.zip
```

Open the database using the downloaded DuckDB CLI like this
```bash
./duckdb --readonly atp_tour.duckdb
```

And if you already have DuckDB install then open the database like this
```bash
duckdb --readonly atp_tour.duckdb
```

To sample the players data try the following
```sql
summarize mart.dim_player;

select *
  from mart.dim_player
 order by dim_player_key;
```