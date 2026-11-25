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
),

with_engagement as (
  select
    w.*,
    e.activity_id
  from watched_sessions as w
  left join {{ ref('overall_student_engagement_activity') }} as e
    on w.glific_id = cast(e.glific_id as string)
    and w.plio_id = e.plio_id
  qualify row_number() over (
    partition by w.session_id
    order by
      case
        when timestamp(e.sent_at) <= w.created_at then 0
        else 1
      end,
      abs(timestamp_diff(w.created_at, timestamp(e.sent_at), second))
  ) = 1
),

with_funnel as (
  select
    w.session_id,
    f.activity_id as funnel_activity_id
  from watched_sessions as w
  left join {{ ref('overall_student_funnel_activity') }} as f
    on w.glific_id = cast(f.glific_id as string)
    and w.plio_id = f.plio_id
  qualify row_number() over (
    partition by w.session_id
    order by
      case
        when timestamp(coalesce(f.sent_at, f.access_at)) <= w.created_at then 0
        else 1
      end,
      abs(
        timestamp_diff(
          w.created_at,
          timestamp(coalesce(f.sent_at, f.access_at)),
          second
        )
      )
  ) = 1
)

select
  we.created_at,
  {{ ist_date('we.created_at') }} as created_date,
  we.glific_id,
  we.student_id,
  we.session_id,
  we.user_id,
  we.plio_id,
  we.video_title,
  we.url,
  we.retention,
  we.watch_time,
  we.video_length,
  we.video_length as duration,
  round(we.total_watch_time, 1) as total_watch_time,
  we.video_watch_count,
  we.student_name,
  we.course,
  we.grade,
  we.level,
  we.gender,
  we.school_id,
  we.school_name,
  we.city,
  we.state,
  we.activity_id,
  fn.funnel_activity_id
from with_engagement as we
left join with_funnel as fn
  on we.session_id = fn.session_id
