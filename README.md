# What this project is about

This is a MDS (Modern Data Stack) project which uses the [ATP Tennis Rankings, Results, and Stats](https://github.com/JeffSackmann/tennis_atp) dataset that is publicly available on Github, to demonstrate how to build and structure a data architecture from scratch suitable for analytics.

## Architecture

![Architecture](/_project_docs/Modern_Data_Stack_Project_Architecture.png)

A brief explanation of all the building blocks used on this architecture:

### Sources

- .csv files from a GitHub repository with [ATP Tennis Rankings, Results, and Stats](https://github.com/JeffSackmann/tennis_atp) dataset.
- .json file from a [REST API](https://restcountries.com/v3.1/all) with a countries dataset.

### Extract & Load

- **Snowflake Connector for Python**: The Snowflake Connector for Python provides an interface for developing Python applications that can connect to Snowflake and perform all standard operations. This approach is used to extract and load data into `Snowflake`.

**Note**: Both scenarios will be triggered by a `GitHub Actions` workflow to perform batch jobs.

### Transform

- **dbt Core**: dbt (Data build tool) takes care of the transformation layer to modularize and centralize your analytics code, while also providing best practices from software engineering workflows with version control and data quality features combined with documentation in one single tool.
dbt compiles and runs your analytics code against your data plaform (in this scenario `Snowflake`), enabling you and your team to collaborate on a single source of truth for metrics, insights and business definitions.

### BI

- **Rill**: Rill is a data analytics platform designed to create fast and interactive operational dashboards. Unlike many traditional business intelligence (BI) tools, Rill comes with an embedded in-memory database that allows for near-instantaneous querying and data exploration. This feature enables users to quickly pivot, slice, and drill down into their data without the typical delays associated with other BI solutions.

Rill is particularly useful for operational and exploratory analytics, offering tools to transform datasets using SQL, and it integrates smoothly with other data sources and analytics platforms like Tableau and Looker. Additionally, Rill supports real-time analytics by working with both batch and streaming data from various sources such as Apache Kafka and Google BigQuery​

## Pre-requisites

For this project make sure you have following installed:

-   [Git](https://git-scm.com/downloads)
-   [Python 3.11](https://www.python.org/downloads/)
-   [Homebrew](https://brew.sh/) - Package manager for macOS or Linux
-   [Snowflake](https://www.snowflake.com/) - Data Warehouse (Create a 30-days free trial account)

## Project Setup

There are 2 possible scenarios to setup this project:

- **Cloning**: By performing a clone of the repository you can pull changes from the repository to your local repository, but you can't push changes (I restrict access).

![Cloning diagram](/_project_docs/cloning_repository.jpg)

- **Forking**: With forking a one-off copy is performed and you can push/pull to your own copy of the repository.

![Forking diagram](/_project_docs/forking_repository.jpg)

My recommendation is to use the **Forking** approach that will give you more autonomy to reproduce the project and make your changes.

### Option 1: Clone Repository
Clone the [ATP Tour project](https://github.com/achilala/dbt-atp-tour) to somewhere on your local directory
```bash
git clone https://github.com/FilipeTheAnalyst/mds-project.git
cd mds-project
```

### Option 2: Fork Repository
To fork the repository please follow these instructions from [GitHub documentation](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo#forking-a-repository).

After performing these steps, you can then clone your forked repository to your local development workstation. You can follow the same steps mentioned on the topic above. If you have any doubts, you also have [instructions here](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo#cloning-your-forked-repository) on how to do it.

---

### Setup Your Environment

Execute the following command to install the required packages using [Homebrew](https://brew.sh/):

``` shell
brew install python@3.11 virtualenv just rilldata/tap/rill
```

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
- Add the missing credentials that apply to your Snowflake account (ex: the account value corresponds to your account url text before snowflake.computing.com)
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

**Note:** You have to run `source .venv/dbt-atp-tour/bin/activate` each time you boot your development workstation.

#### Snowflake Setup

Perform the following [commands](./_project_docs/snowflake_setup.md) in a Snowflake SQL worksheet to create the required objects to successfully deploy the project.

## Extract & Load

### Snowflake Python Connector

Running this python script will read the ATP tour and countries data and upload the files into a Snowflake stage called `dbt_artifacts`.
```python 
python3 .github/scripts/upload_to_snowflake.py
```

To load data from the stage into tables you should create a Stored Procedure with the [following script](/_project_docs/snowflake_load_data_stage_table.md) on a Snowflake SQL worksheet.

To call the stored procedure you can run the following command on a Snowfake SQL worksheet:

```sql 
CALL load_data_from_stage('ATP_TOUR', 'RAW', 'DBT_ARTIFACTS');
```

To automate this step to be performed in a daily basis you should create the following ***task*** in Snowflake:

```sql 
CREATE OR REPLACE task RAW_DATA_LOAD_TASK
	warehouse=COMPUTE_WH
	schedule='USING CRON 15 10 * * * UTC'
	AS CALL load_data_from_stage('ATP_TOUR', 'RAW', 'DBT_ARTIFACTS');
```

To activate the task run this command:

```sql 
ALTER TASK RAW_DATA_LOAD_TASK RESUME;
```

### Automate Extract & Load to Snowflake stage with GitHub Actions
To make this process fully automated, I've created a GitHub Actions [workflow](./.github/workflows/upload_to_snowflake.yml) that runs daily at 10:00AM UTC.

#### GitHub Actions (Workfllows)

GitHub Actions is a feature that enables to build, test and deploy your code right from GitHub, following CI/CD best practices.

To define a workflow you need to create a `.yml` file under `.github/workflows/` folder.

[Here](https://docs.github.com/en/actions) is the documentation for more details.

#### Github Secrets
In order to make the environment variables loaded on your local development workstations available to GitHub Actions workflows, GitHub uses ***secrets*** to store that sensitive information.
[Here](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions#creating-secrets-for-a-repository) is the documentation with the steps to follow to achieve that.

**Note**: If you chose the Forking approach, you'll need to perform this step to make your workflow run successfully. 

At the end of your setup, your GitHub secrets definition should look like this:

![GitHub E&L secrets](/_project_docs/github_el_secrets.png)

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
