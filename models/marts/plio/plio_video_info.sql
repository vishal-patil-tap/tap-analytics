{{
  config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by={
      "field": "created_date",
      "data_type": "date",
      "granularity": "day"
    },
    cluster_by=["school_id", "plio_id"],
    unique_key="session_id"
  )
}}

with watched_sessions as (
  select distinct
    b.created_at,
    cast(b.glific_id as string) as glific_id,
    s.student_id,
    es.student_name,
    es.school_id,
    es.school_name,
    s.course,
    s.grade,
    s.level,
    s.gender,
    es.city,
    es.state,
    b.session_id,
    b.user_id,
    b.plio_id,
    b.video_title,
    b.url,
    b.watch_time,
    b.retention,
    b.video_length,
    {{ retention_total_watch_time('b.retention') }} as total_watch_time,
    {{ retention_positive_chunk_count('b.retention') }} as video_watch_count
  from {{ ref('int_plio_base') }} as b
  inner join {{ ref('int_eligible_students') }} as es
    on cast(b.glific_id as string) = es.glific_id
  left join {{ ref('int_student_details') }} as s
    on cast(b.glific_id as string) = cast(s.glific_id as string)
  where b.created_at is not null
    and {{ ist_date('b.created_at') }} >= date '{{ var("plio_session_start_date") }}'
    and ifnull(b.watch_time, 0) > 0
    {% if is_incremental() %}
    and {{ ist_date('b.created_at') }} >= {{ incremental_lookback_week_start() }}
    {% endif %}
)

select
  created_at,
  {{ ist_date('created_at') }} as created_date,
  glific_id,
  student_id,
  session_id,
  user_id,
  plio_id,
  video_title,
  url,
  retention,
  watch_time,
  video_length,
  video_length as duration,
  round(total_watch_time, 1) as total_watch_time,
  video_watch_count,
  student_name,
  course,
  grade,
  level,
  gender,
  school_id,
  school_name,
  city,
  state
from watched_sessions
