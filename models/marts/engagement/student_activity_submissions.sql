{{
  config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by={
      "field": "sent_date",
      "data_type": "date",
      "granularity": "day"
    },
    cluster_by=["contact_phone", "unit_num"],
    unique_key=["contact_phone", "unit_num", "activity_num"]
  )
}}

-- Submission-only slice of overall_student_engagement_activity.
-- Does not change access / submission / quiz weekly rates.
select
  contact_phone,
  student_id,
  glific_id,
  name,
  batch,
  school_id,
  school_name,
  state,
  district,
  city,
  unit_num,
  activity_num,
  sent_at,
  sent_date,
  submission_flag,
  submission_msg_status,
  artefact,
  submission_validity
from {{ ref('overall_student_engagement_activity') }}
where submission_flag = 1
  and sent_at is not null
  {% if is_incremental() %}
  and sent_date >= {{ incremental_lookback_week_start() }}
  {% endif %}
