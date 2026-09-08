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
    glific_id,
    created_at,
    {{ ist_week_start('created_at') }} as week_start,
    video_watch_count
  from {{ ref('plio_video_info') }}
  where created_at is not null
    {% if is_incremental() %}
    and created_date >= {{ incremental_lookback_week_start() }}
    {% endif %}
),

weekly_students as (
  select
    week_start,
    count(distinct glific_id) as total_students_in_week
  from base
  group by week_start
),

weekly_watched as (
  select
    week_start,
    count(distinct glific_id) as students_who_watched
  from base
  where video_watch_count > 0
  group by week_start
)

select
  ws.week_start,
  date_add(ws.week_start, interval 6 day) as week_end,
  ws.total_students_in_week,
  ifnull(ww.students_who_watched, 0) as students_who_watched,
  round(
    safe_divide(ifnull(ww.students_who_watched, 0), ws.total_students_in_week) * 100,
    2
  ) as video_watch_rate_pct
from weekly_students as ws
left join weekly_watched as ww
  on ws.week_start = ww.week_start
