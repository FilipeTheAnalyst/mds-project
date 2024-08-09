# What this project is about

This is a MDS (Modern Data Stack) project which uses the [ATP Tennis Rankings, Results, and Stats](https://github.com/JeffSackmann/tennis_atp) dataset that is publicly available on Github, to demonstrate how to build and structure a data architecture from scratch suitable for analytics.

## Architecture

![Architecture](/_project_docs/Modern_Data_Stack_Project_Architecture.png)

## Pre-requisites

For this project make sure you have following installed:

-   [Git](https://git-scm.com/downloads)
-   [Python](https://www.python.org/downloads/)
-   [DuckDB CLI](https://duckdb.org/docs/installation/index)
-   [Just](https://github.com/casey/just) - Command shortcuts manager

## Project Setup

### Clone Repository
Clone the [ATP Tour project](https://github.com/achilala/dbt-atp-tour) to somewhere on your local directory
```bash
git clone https://github.com/FilipeTheAnalyst/mds-project.git
cd mds-project
```

### Create a virtual environment
Create a virtual environment for your python dependencies and activate it. Your python dependencies will be installed here.
```bash
python3 -m venv .venv/dbt-atp-tour
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
## Extract & Load
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