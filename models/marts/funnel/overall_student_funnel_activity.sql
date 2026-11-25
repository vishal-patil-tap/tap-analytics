{{
  config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by={
      "field": "sent_date",
      "data_type": "date",
      "granularity": "day"
    },
    cluster_by=["contact_phone", "activity_id"],
    unique_key=["contact_phone", "activity_id"]
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
    f.contact_phone,
    f.flow_name,
    f.flow_label,
    f.body,
    f.bsp_status,
    f.unit_num,
    f.activity_num,
    f.activity_id,
    f.activity_type,
    f.sent_flag as activity_sent,
    f.sent_at,
    f.access_at,
    f.submission_at,
    f.access_flag,
    ifnull(f.access_msg_status, 'not sent') as access_msg_status,
    f.submission_flag,
    ifnull(f.submission_msg_status, 'not sent') as submission_msg_status,
    f.artefact,
    f.quiz_sent_flag,
    f.quiz_access_flag,
    f.quiz_attempted_flag,
    f.quiz_completed_flag,
    sv.submission_validity,
    pv.plio_id,
    pv.video_title,
    f.sent_video_link,
    f.first_at
  from {{ ref('int_funnel_student_activity') }} as f
  left join {{ ref('int_funnel_contact_details') }} as sd
    on f.contact_phone = sd.phone
  left join {{ ref('stg_schools') }} as sch
    on sd.school_id = sch.school_join_key
  left join {{ ref('int_submission_validity') }} as sv
    on sd.student_id = sv.student_id
  left join {{ ref('int_funnel_plio_video') }} as pv
    on f.contact_phone = pv.contact_phone
    and f.activity_id = pv.activity_id
  where coalesce(f.sent_at, f.first_at) is not null
    {% if is_incremental() %}
    and {{ ist_date('coalesce(f.sent_at, f.first_at)') }} >= {{ incremental_lookback_week_start() }}
    {% endif %}
)

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
  any_value(body) as body,
  any_value(bsp_status) as bsp_status,
  any_value(unit_num) as unit_num,
  any_value(activity_num) as activity_num,
  activity_id,
  any_value(activity_type) as activity_type,
  max(activity_sent) as activity_sent,
  any_value(sent_at) as sent_at,
  {{ ist_date('any_value(coalesce(sent_at, first_at))') }} as sent_date,
  max(access_flag) as access_flag,
  any_value(access_at) as access_at,
  any_value(access_msg_status) as access_msg_status,
  max(submission_flag) as submission_flag,
  any_value(submission_at) as submission_at,
  any_value(submission_msg_status) as submission_msg_status,
  any_value(artefact) as artefact,
  max(quiz_sent_flag) as quiz_sent_flag,
  max(quiz_access_flag) as quiz_access_flag,
  max(quiz_attempted_flag) as quiz_attempted_flag,
  max(quiz_completed_flag) as quiz_completed_flag,
  any_value(submission_validity) as submission_validity,
  any_value(plio_id) as plio_id,
  any_value(video_title) as video_title,
  any_value(sent_video_link) as sent_video_link
from joined
group by contact_phone, activity_id
