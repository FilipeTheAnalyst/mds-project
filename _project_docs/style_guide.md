# dbt Style Guide

## Model Naming
Our models (typically) fit into three main categories: staging, marts, intermediate. For more detail about why we use this structure, check out [the dbt best practices](https://docs.getdbt.com/guides/best-practices/how-we-structure/1-guide-overview). The file and naming structures are as follows:
```
dbt
├── _project_docs
│   └── style_guide.md
├── analyses
├── seeds
│   └── some_data.csv
├── snapshots
├── tests
│   └── assert_some_test_scenario.sql
├── macros
│   ├── _macros__definitions.yml
│   ├── _macros__docs.md
│   └── generate_schema_name.sql
├── models
│   ├── intermediate
│   │   ├── _intermediate__docs.md
│   │   ├── _intermediate__models.yml
│   │   └── int_customer_sources_unioned.sql
│   ├── marts
│   │   ├── _marts__docs.md
│   │   ├── _marts__models.yml
│   │   ├── customers.sql
│   │   └── orders.sql
│   ├── staging
│   │   ├── google_ads
│   │   │   ├── _google_ads__docs.md
│   │   │   ├── _google_ads__models.yml
│   │   │   ├── _google_ads__sources.yml
│   │   │   ├── stg_google_ads__campaigns.sql
│   │   │   └── stg_google_ads__keywords.sql
│   │   └── quickbooks
│   │       ├── _quickbooks__models.yml
│   │       ├── _quickbooks__sources.yml
│   │       └── stg_quickbooks__invoices.sql
├── dbt_project.yml
├── packages.yml
├── profiles.yml
└── README.md
```
- All objects should be plural, such as: `stg_quickbooks__invoices`
- Base tables (if needed) are prefixed with `base__`, such as: `base__<source>_<object>`
- Staging models are 1:1 with each source table and named with the following convention: `stg_<source>__<table_name>.sql`
  - [Additional context on Staging models](https://docs.getdbt.com/guides/best-practices/how-we-structure/2-staging)
- Intermediate tables should help break apart complex or lengthy logic and follow the following convention: `int_[entity]s_[verb]s.sql`
  - [Additional context on Intermediate models](https://docs.getdbt.com/guides/best-practices/how-we-structure/3-intermediate)
- Marts contain all of the useful data about a _particular entity_ at a granular level and should lean towards being wide and denormalized.
  - [Additional context on Marts models](https://docs.getdbt.com/guides/best-practices/how-we-structure/4-marts)


## Model configuration

- Model-specific attributes (like sort/dist keys) should be specified in the model.
- If a particular configuration applies to all models in a directory, it should be specified in the `dbt_project.yml` file.
- In-model configurations should be specified like this:

```python
{{
  config(
    materialized = 'table',
    sort = 'id',
    dist = 'id'
  )
}}
```
- Marts should always be configured as tables

## dbt conventions
* Only `stg_` models (or `base_` models if your project requires them) should select from `source`s.
* All other models should only select from other models.

## Testing

- Every subdirectory should contain a `.yml` file, in which each model in the subdirectory is tested. For staging folders, there will be both `_sourcename__sources.yml` as well as `_sourcename__models.yml`. For other folders, the structure should be `_foldername__models.yml` (example `_finance__models.yml`).
- At a minimum, unique and not_null tests should be applied to the primary key of each model.

## Naming and field conventions

* Schema, table and column names should be in `snake_case`.
* Use names based on the _business_ terminology, rather than the source terminology.
* Each model should have a primary key.
* The primary key of a model should be named `<object>_id`, e.g. `account_id` – this makes it easier to know what `id` is being referenced in downstream joined models.
* For base/staging models, fields should be ordered in categories, where identifiers are first and timestamps are at the end.
* Timestamp columns should be named `<event>_at`, e.g. `created_at`, and should be in UTC. If a different timezone is being used, this should be indicated with a suffix, e.g `created_at_pt`.
* Booleans should be prefixed with `is_` or `has_`.
* Price/revenue fields should be in decimal currency (e.g. `19.99` for $19.99; many app databases store prices as integers in cents). If non-decimal currency is used, indicate this with suffix, e.g. `price_in_cents`.
* Avoid reserved words as column names
* Consistency is key! Use the same field names across models where possible, e.g. a key to the `customers` table should be named `customer_id` rather than `user_id`.

## CTEs

For more information about why we use so many CTEs, check out [this discourse post](https://discourse.getdbt.com/t/why-the-fishtown-sql-style-guide-uses-so-many-ctes/1091).

- All `{{ ref('...') }}` statements should be placed in CTEs at the top of the file
- Where performance permits, CTEs should perform a single, logical unit of work.
- CTE names should be as verbose as needed to convey what they do
- CTEs with confusing or noteable logic should be commented
- CTEs that are duplicated across models should be pulled out into their own models
- create a `final` or similar CTE that you select from as your last line of code. This makes it easier to debug code within a model (without having to comment out code!)
- CTEs should be formatted like this:

``` sql
with

events as (

    ...

),

-- CTE comments go here
filtered_events as (

    ...

)

select * from filtered_events
```

## SQL style guide

- Use trailing commas
- Indents should be four spaces (except for predicates, which should line up with the `where` keyword)
- Lines of SQL should be no longer than [80 characters](https://stackoverflow.com/questions/29968499/vertical-rulers-in-visual-studio-code)
- Field names and function names should all be lowercase
- The `as` keyword should be used when aliasing a field or table
- Fields should be stated before aggregates / window functions
- Aggregations should be executed as early as possible before joining to another table.
- Ordering and grouping by a number (eg. group by 1, 2) is preferred over listing the column names (see [this rant](https://blog.getdbt.com/write-better-sql-a-defense-of-group-by-1/) for why). Note that if you are grouping by more than a few columns, it may be worth revisiting your model design.
- Prefer `union all` to `union` [*](http://docs.aws.amazon.com/redshift/latest/dg/c_example_unionall_query.html)
- Avoid table aliases in join conditions (especially initialisms) – it's harder to understand what the table called "c" is compared to "customers".
- If joining two or more tables, _always_ prefix your column names with the table alias. If only selecting from one table, prefixes are not needed.
- Be explicit about your join (i.e. write `inner join` instead of `join`). `left joins` are normally the most useful, `right joins` often indicate that you should change which table you select `from` and which one you `join` to.

- *DO NOT OPTIMIZE FOR A SMALLER NUMBER OF LINES OF CODE. NEWLINES ARE CHEAP, BRAIN TIME IS EXPENSIVE*

### Example SQL
```sql
with

my_data as (

    select * from {{ ref('my_data') }}

),

some_cte as (

    select * from {{ ref('some_cte') }}

),

some_cte_agg as (

    select
        id,
        sum(field_4) as total_field_4,
        max(field_5) as max_field_5

    from some_cte
    group by 1

),

final as (

    select [distinct]
        my_data.field_1,
        my_data.field_2,
        my_data.field_3,

        -- use line breaks to visually separate calculations into blocks
        case
            when my_data.cancellation_date is null
                and my_data.expiration_date is not null
                then expiration_date
            when my_data.cancellation_date is null
                then my_data.start_date + 7
            else my_data.cancellation_date
        end as cancellation_date,

        some_cte_agg.total_field_4,
        some_cte_agg.max_field_5

    from my_data
    left join some_cte_agg  
        on my_data.id = some_cte_agg.id
    where my_data.field_1 = 'abc'
        and (
            my_data.field_2 = 'def' or
            my_data.field_2 = 'ghi'
        )
    having count(*) > 1

)

select * from final

```

- Your join should list the "left" table first (i.e. the table you are selecting `from`):
```sql
select
    trips.*,
    drivers.rating as driver_rating,
    riders.rating as rider_rating

from trips
left join users as drivers
    on trips.driver_id = drivers.user_id
left join users as riders
    on trips.rider_id = riders.user_id

```

## YAML style guide

* Indents should be two spaces
* List items should be indented
* Use a new line to separate list items that are dictionaries where appropriate
* Lines of YAML should be no longer than 80 characters.

### Example YAML
```yaml
version: 2

models:
  - name: events
    columns:
      - name: event_id
        description: This is a unique identifier for the event
        tests:
          - unique
          - not_null

      - name: event_time
        description: "When the event occurred in UTC (eg. 2018-01-01 12:00:00)"
        tests:
          - not_null

      - name: user_id
        description: The ID of the user who recorded the event
        tests:
          - not_null
          - relationships:
              to: ref('users')
              field: id
```


## Jinja style guide

* When using Jinja delimiters, use spaces on the inside of your delimiter, like `{{ this }}` instead of `{{this}}`
* Use newlines to visually indicate logical blocks of Jinja


## Helpful Reference Links
* https://docs.getdbt.com/guides/best-practices/how-we-structure/1-guide-overview
* https://discourse.getdbt.com/t/why-the-fishtown-sql-style-guide-uses-so-many-ctes/1091
* https://blog.getdbt.com/write-better-sql-a-defense-of-group-by-1/
* https://docs.getdbt.com/docs/about/viewpoint
* https://github.com/dbt-labs/corp/blob/main/dbt_style_guide.md