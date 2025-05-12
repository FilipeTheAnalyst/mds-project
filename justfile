################ ENVIRONMENT SETUP ###################
# create a virtual env
create-venv:
    rm -rf .venv && virtualenv .venv --python=python3.11

################ DBT COMMANDS ###################

# Download dependencies
deps:
    dbt clean && dbt deps

# Run Snapshot
snapshot:
    dbt snapshot

# Run sde_dbt_tutorial models
run-dbt:
    dbt run

# Test
test-raw:
    dbt test --select "source:*"

test-warehouse:
    dbt test --exclude "source:*"

test:
    just test-raw
    just test-warehouse

# generate dbt docs
docs-gen:
    dbt docs generate

# Serve docs
serve:
    dbt docs serve

# Generate and serve dbt docs
docs:
    just docs-gen
    just serve

# Debug connections
debug:
    dbt debug

################## LINT & FORMATTING ###########

lint-sql:
    sqlfluff lint ./models

format-sql:
    sqlfluff fix ./models --show-lint-violations

lint-yml:
    yamllint ./models ./snapshots ./dbt_project.yml ./packages.yml ./profiles.yml

format-yml:
    yamlfix ./models

################## WORKFLOW COMMANDS ###########

lint-format:
    just format-sql
    just lint-sql

dbt-check:
    pre-commit run
    dbt build --select package:dbt_project_evaluator

dev-run:
    just test-raw
    just snapshot
    just test-warehouse

prod-run:
    dbt test --target prod --select "source:*"
    dbt snapshot --target prod
    dbt build --select package:dbt_project_evaluator --target prod --exclude package:dbt_artifacts
    dbt run --select mds_pipeline --target prod
    dbt test --target prod --exclude "source:*"

ci:
    just lint-format
    just dbt-check