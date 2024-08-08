{% macro fail_on_row_count_zero (source) %}
  {%- set query -%}
    select count(*) as row_count
    from {{ source }}
  {%- endset %}

  {%- set results = run_query(query) -%}
  
  {%- if results is none -%}
    {{ exceptions.raise_compiler_error("Query execution failed for source: " ~ source) }}
  {%- endif %}

  {%- set row_count = results.columns[0].values()[0] -%}

  {%- if row_count == 0 -%}
    {{ source }}
  {%- else -%}
    {# Output nothing if row count is not zero #}
  {%- endif %}
{% endmacro %}

{# Macro to find the sources used by a specific model and check if any of them have empty records #}
{% macro find_sources_for_model(model_name) %}
  {%- if execute -%}
    {% set sources_used = [] %}
    {%- set sources = [] -%}
    {%- set zero_row_count_sources = [] -%}
  
    {# Iterate through all nodes and find the sources used by the specified model #}
    {%- for name, node in graph.nodes.items() -%}

      {%- if node.name == model_name -%}
        
        {# Check if the model specifies sources #}
        {%- if node.sources | length > 0 -%}

          {%- for source_used in node.sources -%}
            {% set source_database = source_used[0] %}
            {% set source_table_name = source_used[1] %}
            {# Use source function to return a relation for the source #}
            {% set source_name = source(source_database, source_table_name) %} 

            {%- set result = fail_on_row_count_zero(source_name) | trim -%}
            {%- if result != '' -%}
              {%- do zero_row_count_sources.append(result) -%}
            {%- endif %}

          {%- endfor %}
            
        {%- else -%}
          {%- do log("Model '" ~ model_name ~ "' does not specify any sources.", info=true) -%}

        {%- endif -%}

        {%- if zero_row_count_sources | length > 0 -%}
          {%- set zero_sources_list = zero_row_count_sources | join(', ') -%}
          {{ exceptions.raise_compiler_error("Row count is zero for the following sources: " ~ zero_sources_list) }}
  
        {%- endif %}

      {%- endif -%}
    {%- endfor -%}

  {%- endif %}
{% endmacro %}