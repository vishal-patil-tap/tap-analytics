{{
  config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by={
      "field": "inserted_date",
      "data_type": "date",
      "granularity": "day"
    },
    cluster_by=["contact_phone", "status_tag"],
    unique_key="message_id"
  )
}}

with labelled as (
  select
    message_id,
    body,
    contact_name,
    contact_phone,
    inserted_at,
    flow_label,
    flow_name,
    media_url,
    trim((split(flow_label, 'TLM26 -'))[safe_ordinal(2)]) as activity_tag,
    case
      when flow_label like "%Activity_QuizAttempted%"
        or {{ is_quiz_attempted_body('body') }}
        then "QuizAttempted"
      else trim((split(flow_label, 'Activity_'))[safe_ordinal(2)])
    end as status_tag1,
    trim((split(flow_label, '-'))[safe_ordinal(2)]) as unit_tag
  from {{ ref('stg_tlm26_messages') }}
  -- TLM26 required for activity tags. QuizCompleted/Attempted labels often omit TLM26.
  where (
      (
        flow_label like "%TLM26%"
        and (
          flow_label like "%Activity_Sent%"
          or flow_label like "%Activity_Access%"
          or flow_label like "%Activity_Submission%"
          or flow_label like "%Activity_FlowAccessed%"
        )
      )
      or flow_label like "%Activity_QuizSent%"
      or flow_label like "%Activity_QuizAccess%"
      or flow_label like "%Activity_QuizAttempted%"
      or flow_label like "%Activity_QuizCompleted%"
      or flow_label like "%Activity_QuizScore%"
      or {{ is_quiz_attempted_body('body') }}
    )
    {% if is_incremental() %}
    and {{ ist_date('inserted_at') }} >= {{ incremental_lookback_week_start() }}
    {% endif %}
),

numbered as (
  select
    *,
    trim((split(activity_tag, 'Activity '))[safe_ordinal(2)]) as activity_number_tag1
  from labelled
)

select
  message_id,
  {{ ist_date('inserted_at') }} as inserted_date,
  body,
  contact_name,
  contact_phone,
  inserted_at,
  flow_label,
  flow_name,
  media_url,
  activity_tag,
  status_tag1,
  unit_tag,
  activity_number_tag1,
  concat("Activity ", trim((split(activity_number_tag1, ','))[safe_ordinal(1)])) as activity_number_tag,
  concat("Activity_", trim((split(status_tag1, ','))[safe_ordinal(1)])) as status_tag
from numbered
