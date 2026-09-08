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

-- Same pattern as weekly access/submission: week = engagement sent week (IST Monday).
-- Numerator = quiz_completed_flag (phone-level QuizCompleted), not Flow_end.
with base as (
  select
    contact_phone,
    sent_at,
    {{ ist_week_start('sent_at') }} as week_start,
    quiz_completed_flag,
    quiz_sent_flag
  from {{ ref('overall_student_engagement_activity') }}
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

weekly_sent as (
  select
    week_start,
    count(distinct contact_phone) as students_who_were_sent_quiz
  from base
  where quiz_sent_flag = 1
  group by week_start
),

weekly_completed as (
  select
    week_start,
    count(distinct contact_phone) as students_who_completed_quiz
  from base
  where quiz_completed_flag = 1
  group by week_start
)

select
  ws.week_start,
  date_add(ws.week_start, interval 6 day) as week_end,
  ws.total_students_in_week,
  ifnull(wsent.students_who_were_sent_quiz, 0) as students_who_were_sent_quiz,
  ifnull(wc.students_who_completed_quiz, 0) as students_who_completed_quiz,
  ifnull(
    round(
      safe_divide(
        ifnull(wc.students_who_completed_quiz, 0),
        ifnull(wsent.students_who_were_sent_quiz, 0)
      ) * 100,
      2
    ),
    0
  ) as weekly_quiz_completion_rate_pct
from weekly_students as ws
left join weekly_sent as wsent
  on ws.week_start = wsent.week_start
left join weekly_completed as wc
  on ws.week_start = wc.week_start
