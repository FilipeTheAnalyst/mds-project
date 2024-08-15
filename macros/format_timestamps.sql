-- macro that formats a timestamp to a date key that references the DIM_DATE dimension table
{% macro to_date_key(timestamp_column) %}
    {% set _result = "TO_CHAR(" ~ timestamp_column ~ ", 'YYYYMMDD')" %}

    {{ return(_result) }}
{% endmacro %}

-- macro that formats a timestamp to a time key that references the DIM_TIME dimension table
{% macro to_time_key(timestamp_column) %}
    {% set _result = "TO_CHAR(" ~ timestamp_column ~ ", '%H%M')" %}

    {{ return(_result) }}
{% endmacro %}

-- macro that formats a timestamp to the ISO8601 date format
{% macro to_iso_date(timestamp_column) %}
    {% set _result = "TO_CHAR(" ~ timestamp_column ~ ", '%Y-%m-%d')" %}

    {{ return(_result) }}
{% endmacro %}

-- macro that formats a timestamp to the ISO8601 date format but with dots delimiters instead of dashes
{% macro to_iso_date_us(timestamp_column) %}
    {% set _result = "TO_CHAR(" ~ timestamp_column ~ ", '%Y.%m.%d')" %}

    {{ return(_result) }}
{% endmacro %}

-- macro that formats a timestamp to British date
{% macro to_date_gb(timestamp_column) %}
    {% set _result = "TO_CHAR(" ~ timestamp_column ~ ", '%d/%m/%Y')" %}

    {{ return(_result) }}
{% endmacro %}

-- macro that formats a timestamp to US date
{% macro to_date_us(timestamp_column) %}
    {% set _result = "TO_CHAR(" ~ timestamp_column ~ ", '%m/%d/%Y')" %}

    {{ return(_result) }}
{% endmacro %}

-- macro that returns the current age from a time
{% macro to_age(timestamp_column) %}
    {% set _result = "(year(current_date) - year(" ~ timestamp_column ~ "))" %}

    {{ return(_result) }}
{% endmacro %}