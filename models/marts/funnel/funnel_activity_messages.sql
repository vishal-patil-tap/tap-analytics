{{
  config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by={
      "field": "inserted_date",
      "data_type": "date",
      "granularity": "day"
    },
    cluster_by=["contact_phone", "activity_id"],
    unique_key="message_id"
  )
}}

select
  message_id,
  inserted_at,
  {{ ist_date('inserted_at') }} as inserted_date,
  contact_phone,
  body,
  flow_name,
  flow_label,
  activity_id,
  activity_type
from {{ ref('int_funnel_activity_messages') }}
where inserted_at is not null
  {% if is_incremental() %}
  and {{ ist_date('inserted_at') }} >= {{ incremental_lookback_week_start() }}
  {% endif %}
