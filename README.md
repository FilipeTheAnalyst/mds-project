# What this project is about

This is a MDS (Modern Data Stack) project which uses the [ATP Tennis Rankings, Results, and Stats](https://github.com/JeffSackmann/tennis_atp) dataset that is publicly available on Github, to demonstrate how to build and structure a data architecture from scratch suitable for analytics.

## Architecture

![Architecture](/_project_docs/Modern_Data_Stack_Project_Architecture.png)

A brief explanation of all the building blocks used on this architecture:

### Sources

- .csv files from a GitHub repository with [ATP Tennis Rankings, Results, and Stats](https://github.com/JeffSackmann/tennis_atp) dataset.
- .json file from a [REST API](https://restcountries.com/v3.1/all) with a countries dataset.

### Extract & Load

- **dltHub**: Python library for extract & load. You can dlt to your Python scripts to load data from various and oftn messy data sources into well-structured, live datasets. This approach is used to extract and load data into `Duckdb`.
- **Snowflake Connector for Python**: The Snowflake Connector for Python provides an interface for developing Python applications that can connect to Snowflake and perform all standard operations. This approach is used to extract and load data into `Snowflake`.

**Note**: Both scenarios will be triggered by a `GitHub Actions` workflow to perform batch jobs.

### Transform

- **dbt Core**: dbt (Data build tool) takes care of the transformation layer to modularize and centralize your analytics code, while also providing best practices from software engineering workflows with version control and data quality features combined with documentation in one single tool.
dbt compiles and runs your analytics code against your data plaform (in this scenario `Duckdb` and `Snowflake`), enabling you and your team to collaborate on a single source of truth for metrics, insights and business definitions.

### BI

- **Rill**: Rill is a data analytics platform designed to create fast and interactive operational dashboards. Unlike many traditional business intelligence (BI) tools, Rill comes with an embedded in-memory database that allows for near-instantaneous querying and data exploration. This feature enables users to quickly pivot, slice, and drill down into their data without the typical delays associated with other BI solutions.

Rill is particularly useful for operational and exploratory analytics, offering tools to transform datasets using SQL, and it integrates smoothly with other data sources and analytics platforms like Tableau and Looker. Additionally, Rill supports real-time analytics by working with both batch and streaming data from various sources such as Apache Kafka and Google BigQuery​

## Pre-requisites

For this project make sure you have following installed:

-   [Git](https://git-scm.com/downloads)
-   [Python 3.11](https://www.python.org/downloads/)
-   [DuckDB CLI](https://duckdb.org/docs/installation/index)
-   [Homebrew](https://brew.sh/) - Package manager for macOS or Linux
-   [Snowflake](https://www.snowflake.com/) - Data Warehouse (Create a 30-days free trial account)

## Project Setup

### Clone Repository
Clone the [ATP Tour project](https://github.com/achilala/dbt-atp-tour) to somewhere on your local directory
```bash
git clone https://github.com/FilipeTheAnalyst/mds-project.git
cd mds-project
```

---

### Setup Your Environment

Execute the following command to install the required packages using [Homebrew](https://brew.sh/):

``` shell
brew install python@3.11 virtualenv just rilldata/tap/rill
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
---

**Note:** An alternative way to query the `DuckDB` database is to install [DBeaver](https://dbeaver.io/) client (also works with Snowflake if preferred).

#### Create a virtual environment
Create a virtual environment for your python dependencies and activate it. Your python dependencies will be installed here.
```bash
virtualenv .venv/dbt-atp-tour --python=python3.11
source .venv/dbt-atp-tour/bin/activate
```

Install the python dependencies
```bash
pip install --upgrade pip

pip install -r requirements.txt
```

Some of the installed modules require reactivating your virtual environment to take effect
```bash
deactivate
source .venv/dbt-atp-tour/bin/activate
```

#### Create a `.env` file to store credentials

- Rename the [`env.sample`](env.sample) file to `.env` on the repository main directory
- Add `.env` file contents to virtual environment activate script
 ```bash
cat .env >> .venv/dbt-atp-tour/bin/activate
```
- Check how the activate script looks now
 ```bash
cat .venv/dbt-atp-tour/bin/activate | tail -10
```
- Now let's deactivate and activate the virtual environment again
 ```bash
deactivate
source .venv/dbt-atp-tour/bin/activate
```
- Let's checkout some of the environment variables
 ```bash
echo $DBT_USER
echo $DBT_PASSWORD
```

## Extract & Load

### DltHub

Running this python script will read the ATP tour data into a duckdb database called `atp_tour.duckdb`
```python 
python3 el_sources_data.py
```

A new file called `atp_tour.duckdb` should appear in the folder, and this is the `DuckDB` database file. The reason why `DuckDB` is my-go-to database is because it's very light, simple to setup and built for analytical processing.

## Transformation
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

### Use Formatter & Linter tools to define standards and avoid PR nits
It is beneficial to have a standard style guide to ensure the code has a consistent feel.
Having style standards automated ensures that it is easy to follow, and any dev new to the team is empowered to focus on the core feature delivery and not spend time fixing formatting issues.

There are two main concepts to understand

1. **Linter** tells us what’s wrong with our code regarding style and code correctness.
1. **Formatter** formats the code to conform to the standard style.

#### Lint and format sql with sqlfluff
sqlfluff is an SQL linter and a formatter. While there are multiple sql linters and formatters, we chose sqlfluff since it has good support for dbt (macros, jinja2, etc). We use the [.sqlfluff](./.sqlfluff) to provide dbt specific settings (like where the dbt project file is, how to format macros, etc) and the [.sqlfluffignore](./.sqlfluffignore) to ignore the folders to format.

To check all the possible rules that can be applied check out the [documentation](https://docs.sqlfluff.com/en/stable/configuration.html).

I've followed the rules mentioned on this [article](https://dbtips.substack.com/p/get-the-ultimate-developer-experience) to start simple.

 ``` bash
sqlfluff lint ./models # just lint-sql
```

 ``` bash
sqlfluff fix ./models --show-lint-violations # just format-sql
```

#### Lint and format yaml with yamllint
Similar to the process above for SQL we use yamllint to lint and format our yaml files.
The file [.yamllint](./.yamllint) contains the settings applied.

 ``` bash
yamllint ./models ./snapshots ./dbt_project.yml ./packages.yml ./profiles.yml # just lint-yml
```

 ``` bash
yamlfix ./models # just format-yml
```

To check all the possible rules that can be applied check out the [documentation](https://yamllint.readthedocs.io/en/stable/rules.html).

I've followed the rules mentioned on this [article](https://blog.montrealanalytics.com/automating-dbt-development-workflows-with-pre-commit-b6c7ca708f7) with a couple modifications changing the severity level from error to warning.

#### Autorun linting & checks locally before opening a PR to save on CI costs
Usually, your CI pipeline will run checks and tests to ensure the PR is up to standard. You can reduce the time taken at CI runs by preventing issues by adding the checks as a pre-commit git hook. The pre-commit git hook ensures that checks and tests run before a developer puts up a PR, saving potential CI time (if there are issues with the code).

As shown below, you can add a pre-commit hook to your .git/hooks folder.

 ``` bash
echo -e '
#!/bin/sh
just ci
' > .git/hooks/pre-commit
chmod ug+x .git/hooks/*
```

Now, the `just ci` command will run each time you try to add a commit (just ci will run before the code commit automatically).



To sample the players data try the following
```sql
summarize mart.dim_player;

select *
  from mart.dim_player
 order by dim_player_key;
```