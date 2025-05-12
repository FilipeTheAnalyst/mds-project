WITH source AS (
    SELECT *
    FROM {{ source('atp_tour_raw', 'countries') }}
),

renamed AS (
    SELECT
        name__common AS country_name,
        cca2 AS country_iso_code_2,
        cca3 AS country_iso_code_3,
        cioc AS country_ioc_code,
        flag AS country_flag,
        population AS country_population,
        area AS country_area,
        region AS country_region,
        car__side AS country_car_side
    FROM source
)

SELECT *
FROM renamed
