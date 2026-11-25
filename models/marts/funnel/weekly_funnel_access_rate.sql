{{
  config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by={
      "field": "week_start",
      "data_type": "date",
      "granularity": "day"
    },
    unique_key="week_start"
  )
}}

with base as (
  select
    contact_phone,
    sent_at,
    {{ ist_week_start('sent_at') }} as week_start,
    access_flag
  from {{ ref('overall_student_funnel_activity') }}
  where sent_at is not null
    {% if is_incremental() %}
    and sent_date >= {{ incremental_lookback_week_start() }}
    {% endif %}
),

weekly_students as (
  select
    week_start,
    count(distinct contact_phone) as total_students_in_week
  from base
  group by week_start
),

weekly_accessed as (
  select
    week_start,
    count(distinct contact_phone) as students_who_accessed
  from base
  where access_flag = 1
  group by week_start
)

select
  ws.week_start,
  date_add(ws.week_start, interval 6 day) as week_end,
  ws.total_students_in_week,
  ifnull(wa.students_who_accessed, 0) as students_who_accessed,
  round(
    safe_divide(ifnull(wa.students_who_accessed, 0), ws.total_students_in_week) * 100,
    2
  ) as weekly_access_rate_pct
from weekly_students as ws
left join weekly_accessed as wa
  on ws.week_start = wa.week_start
