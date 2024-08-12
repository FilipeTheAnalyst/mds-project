################ ENVIRONMENT SETUP ###################
# create a virtual env
create-venv:
    rm -rf .dbt-venv && virtualenv .dbt-venv --python=python3.11

################ DBT COMMANDS ###################

# Download dependencies
deps:
    dbt deps

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

check-orphan-tests:
    python3 check_orphans.py

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

dev-run:
    just test-raw
    just snapshot
    just run-sde
    just check-orphan-tests
    just test-warehouse

prod-run:
    dbt test --target prod --select "source:*"
    dbt snapshot --target prod
    dbt run --select sde_dbt_tutorial --target prod
    just check-orphan-tests
    dbt test --target prod --exclude "source:*"

ci:
    just lint-format
    just dbt-check