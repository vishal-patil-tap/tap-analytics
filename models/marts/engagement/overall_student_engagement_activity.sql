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

with joined as (
  select
    sd.batch,
    sd.glific_id,
    sd.student_id,
    sd.language,
    sd.student_name as name,
    sd.grade,
    sd.gender,
    sd.course,
    sd.level,
    sch.school_join_key as school_id,
    sch.school_name,
    sch.state,
    sch.district,
    sch.city,
    sch.model,
    sch.type,
    ef.contact_phone,
    ef.flow_name,
    ef.flow_label,
    ef.bsp_status,
    ef.unit_num,
    ef.activity_num,
    ef.activity_sent,
    ef.sent_at,
    case when aa.activity_access is null then 0 else 1 end as access_flag,
    case when aa.bsp_status is null then 'not sent' else aa.bsp_status end as access_msg_status,
    case when sub.activity_submission is null then 0 else 1 end as submission_flag,
    case when sub.bsp_status is null then 'not sent' else sub.bsp_status end as submission_msg_status,
    sub.artefact,
    case when fc.activity_complete is null then 0 else 1 end as completion_flag,
    case when fc.bsp_status is null then 'not sent' else fc.bsp_status end as completion_msg_status,
    case when qz.quiz_sent = 1 then 1 else 0 end as quiz_sent_flag,
    case when qz.quiz_attempted = 1 then 1 else 0 end as quiz_attempted_flag,
    case when qz.quiz_completed = 1 then 1 else 0 end as quiz_completed_flag,
    sv.submission_validity
  from {{ ref('int_engagement_flow_start') }} as ef
  left join {{ ref('int_engagement_access') }} as aa
    on ef.contact_phone = aa.contact_phone
    and ef.unit_num = aa.unit_num
    and ef.activity_num = aa.activity_num
  left join {{ ref('int_engagement_submission') }} as sub
    on ef.contact_phone = sub.contact_phone
    and ef.unit_num = sub.unit_num
    and ef.activity_num = sub.activity_num
  left join {{ ref('int_engagement_flow_complete') }} as fc
    on ef.contact_phone = fc.contact_phone
  left join {{ ref('int_engagement_quiz_flags') }} as qz
    on right(ef.contact_phone, 10) = qz.phone_last10
  left join {{ ref('int_student_details') }} as sd
    on ef.contact_phone = sd.phone
  left join {{ ref('stg_schools') }} as sch
    on sd.school_id = sch.school_join_key
  left join {{ ref('int_submission_validity') }} as sv
    on sd.student_id = sv.student_id
  where ef.sent_at is not null
    {% if is_incremental() %}
    and {{ ist_date('ef.sent_at') }} >= {{ incremental_lookback_week_start() }}
    {% endif %}
)

-- Collapse flow_complete fan-out to one row per phone x unit x activity.
-- contact_phone is the phone key (duplicate phone column dropped).
-- submission_validity is student-level (latest judged); does not change rates.
select
  any_value(batch) as batch,
  any_value(glific_id) as glific_id,
  any_value(student_id) as student_id,
  any_value(language) as language,
  any_value(name) as name,
  any_value(grade) as grade,
  any_value(gender) as gender,
  any_value(course) as course,
  any_value(level) as level,
  any_value(school_id) as school_id,
  any_value(school_name) as school_name,
  any_value(state) as state,
  any_value(district) as district,
  any_value(city) as city,
  any_value(model) as model,
  any_value(type) as type,
  contact_phone,
  any_value(flow_name) as flow_name,
  any_value(flow_label) as flow_label,
  any_value(bsp_status) as bsp_status,
  unit_num,
  activity_num,
  max(activity_sent) as activity_sent,
  any_value(sent_at) as sent_at,
  {{ ist_date('any_value(sent_at)') }} as sent_date,
  max(access_flag) as access_flag,
  any_value(access_msg_status) as access_msg_status,
  max(submission_flag) as submission_flag,
  any_value(submission_msg_status) as submission_msg_status,
  any_value(artefact) as artefact,
  max(completion_flag) as completion_flag,
  any_value(completion_msg_status) as completion_msg_status,
  max(quiz_sent_flag) as quiz_sent_flag,
  max(quiz_attempted_flag) as quiz_attempted_flag,
  max(quiz_completed_flag) as quiz_completed_flag,
  any_value(submission_validity) as submission_validity
from joined
group by contact_phone, unit_num, activity_num
