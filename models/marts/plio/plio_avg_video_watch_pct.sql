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
    user_id as student_id,
    plio_id,
    duration,
    created_at,
    created_date,
    video_watch_count
  from {{ ref('plio_video_info') }}
  where duration > 0
    {% if is_incremental() %}
    and created_date >= {{ incremental_lookback_week_start() }}
    {% endif %}
),

student_video_week as (
  select
    {{ ist_week_start('created_at') }} as week_start,
    student_id,
    plio_id,
    max(safe_divide(video_watch_count, duration) * 100) as watch_pct
  from base
  where created_at is not null
  group by week_start, student_id, plio_id
),

student_week as (
  select
    week_start,
    student_id,
    avg(watch_pct) as avg_watch_pct_student
  from student_video_week
  where watch_pct > 0
  group by week_start, student_id
)

select
  week_start,
  date_add(week_start, interval 6 day) as week_end,
  count(distinct student_id) as student_count,
  round(avg(avg_watch_pct_student), 2) as avg_video_watch_pct
from student_week
group by week_start
