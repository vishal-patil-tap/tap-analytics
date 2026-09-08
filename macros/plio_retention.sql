{# Query 1: sum of retention tokens. Do not apply nan-cleaning here. #}
{% macro retention_total_watch_time(retention_column) %}
(
  SELECT SUM(IFNULL(SAFE_CAST(TRIM(x) AS INT64), 0))
  FROM UNNEST(SPLIT(IFNULL({{ retention_column }}, ''), ',')) AS x
)
{% endmacro %}


{# Queries 2–3: count of retention chunks > 0, with nan -> 0. #}
{% macro retention_positive_chunk_count(retention_column) %}
CASE
  WHEN TRIM(IFNULL({{ retention_column }}, '')) = '' THEN 0
  ELSE (
    SELECT COUNTIF(
      COALESCE(
        SAFE_CAST(REGEXP_REPLACE(TRIM(x), r'(?i)^nan$', '0') AS INT64),
        0
      ) > 0
    )
    FROM UNNEST(SPLIT({{ retention_column }}, ',')) AS x
  )
END
{% endmacro %}
