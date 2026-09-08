{# TIMESTAMP: convert to IST date. DATETIME: TIMESTAMP() then IST (BQ DATE(dt, tz) is invalid). #}
{% macro ist_date(ts_column) %}
DATE(TIMESTAMP({{ ts_column }}), 'Asia/Kolkata')
{% endmacro %}


{% macro ist_week_start(ts_column) %}
DATE_TRUNC({{ ist_date(ts_column) }}, WEEK(MONDAY))
{% endmacro %}


{# Full weeks covering the lookback window, so weekly marts re-aggregate complete weeks. #}
{% macro incremental_lookback_week_start() %}
DATE_TRUNC(
  DATE_SUB(
    CURRENT_DATE('Asia/Kolkata'),
    INTERVAL {{ var('plio_incremental_lookback_days') }} DAY
  ),
  WEEK(MONDAY)
)
{% endmacro %}
