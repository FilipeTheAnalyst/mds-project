-- macro that formats a timestamp to a date key that references the DIM_DATE dimension table
{% macro to_date_key(timestamp_column) %}
    {% set _result = "strftime(" ~ timestamp_column ~ ", '%Y%m%d')" %}

    {{ return(_result) }}
{% endmacro %}

-- macro that formats a timestamp to a time key that references the DIM_TIME dimension table
{% macro to_time_key(timestamp_column) %}
    {% set _result = "strftime(" ~ timestamp_column ~ ", '%H%M')" %}

    {{ return(_result) }}
{% endmacro %}

-- macro that formats a timestamp to the ISO8601 date format
{% macro to_iso_date(timestamp_column) %}
    {% set _result = "strftime(" ~ timestamp_column ~ ", '%Y-%m-%d')" %}

    {{ return(_result) }}
{% endmacro %}

-- macro that formats a timestamp to the ISO8601 date format but with dots delimiters instead of dashes
{% macro to_iso_date_us(timestamp_column) %}
    {% set _result = "strftime(" ~ timestamp_column ~ ", '%Y.%m.%d')" %}

    {{ return(_result) }}
{% endmacro %}

-- macro that formats a timestamp to British date
{% macro to_date_gb(timestamp_column) %}
    {% set _result = "strftime(" ~ timestamp_column ~ ", '%d/%m/%Y')" %}

    {{ return(_result) }}
{% endmacro %}

-- macro that formats a timestamp to US date
{% macro to_date_us(timestamp_column) %}
    {% set _result = "strftime(" ~ timestamp_column ~ ", '%m/%d/%Y')" %}

    {{ return(_result) }}
{% endmacro %}

-- macro that returns the current age from a time
{% macro to_age(timestamp_column) %}
    {% set _result = "(year(current_date) - year(" ~ timestamp_column ~ "))" %}

    {{ return(_result) }}
{% endmacro %}

-- macro to convert date in integer data type to date
{% macro convert_yyyymmdd_int_to_date(yyyymmdd_int) %}
    {{ 
        return(
            "MAKE_DATE("
            ~ "CAST(SUBSTR(CAST(" ~ yyyymmdd_int ~ " AS VARCHAR), 1, 4) AS INT), "
            ~ "CAST(SUBSTR(CAST(" ~ yyyymmdd_int ~ " AS VARCHAR), 5, 2) AS INT), "
            ~ "CAST(SUBSTR(CAST(" ~ yyyymmdd_int ~ " AS VARCHAR), 7, 2) AS INT)"
            ~ ")"
        ) 
    }}
{% endmacro %}