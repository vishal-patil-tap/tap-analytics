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
    submission_flag,
    submission_validity
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

weekly_submitted as (
  select
    week_start,
    count(distinct contact_phone) as students_who_submitted
  from base
  where submission_flag = 1
  group by week_start
),

weekly_valid as (
  select
    week_start,
    count(distinct contact_phone) as valid_submission
  from base
  where submission_flag = 1
    and submission_validity = 'Valid'
  group by week_start
),

weekly_invalid as (
  select
    week_start,
    count(distinct contact_phone) as invalid_submission
  from base
  where submission_flag = 1
    and submission_validity = 'Invalid'
  group by week_start
)

select
  ws.week_start,
  date_add(ws.week_start, interval 6 day) as week_end,
  ws.total_students_in_week,
  ifnull(wsub.students_who_submitted, 0) as students_who_submitted,
  round(
    safe_divide(ifnull(wsub.students_who_submitted, 0), ws.total_students_in_week) * 100,
    2
  ) as weekly_submission_rate_pct,
  ifnull(wv.valid_submission, 0) as valid_submission,
  ifnull(wi.invalid_submission, 0) as invalid_submission,
  ifnull(
    round(
      safe_divide(
        ifnull(wv.valid_submission, 0),
        ifnull(wsub.students_who_submitted, 0)
      ) * 100,
      2
    ),
    0
  ) as weekly_valid_submission_rate_pct,
  ifnull(
    round(
      safe_divide(
        ifnull(wi.invalid_submission, 0),
        ifnull(wsub.students_who_submitted, 0)
      ) * 100,
      2
    ),
    0
  ) as weekly_invalid_submission_rate_pct
from weekly_students as ws
left join weekly_submitted as wsub
  on ws.week_start = wsub.week_start
left join weekly_valid as wv
  on ws.week_start = wv.week_start
left join weekly_invalid as wi
  on ws.week_start = wi.week_start
