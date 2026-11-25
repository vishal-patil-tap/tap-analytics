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

-- Funnel quiz_completed is almost empty; attempt rate uses quiz_attempted ÷ quiz_sent.
with base as (
  select
    contact_phone,
    sent_at,
    {{ ist_week_start('sent_at') }} as week_start,
    quiz_sent_flag,
    quiz_attempted_flag
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

weekly_sent as (
  select
    week_start,
    count(distinct contact_phone) as students_who_were_sent_quiz
  from base
  where quiz_sent_flag = 1
  group by week_start
),

weekly_attempted as (
  select
    week_start,
    count(distinct contact_phone) as students_who_attempted_quiz
  from base
  where quiz_attempted_flag = 1
  group by week_start
)

select
  ws.week_start,
  date_add(ws.week_start, interval 6 day) as week_end,
  ws.total_students_in_week,
  ifnull(wsent.students_who_were_sent_quiz, 0) as students_who_were_sent_quiz,
  ifnull(wa.students_who_attempted_quiz, 0) as students_who_attempted_quiz,
  ifnull(
    round(
      safe_divide(
        ifnull(wa.students_who_attempted_quiz, 0),
        ifnull(wsent.students_who_were_sent_quiz, 0)
      ) * 100,
      2
    ),
    0
  ) as weekly_quiz_attempt_rate_pct
from weekly_students as ws
left join weekly_sent as wsent
  on ws.week_start = wsent.week_start
left join weekly_attempted as wa
  on ws.week_start = wa.week_start
