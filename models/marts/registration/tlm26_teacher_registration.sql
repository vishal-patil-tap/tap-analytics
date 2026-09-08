{{
  config(
    materialized='table',
    cluster_by=['state', 'district']
  )
}}

-- Snapshot. Spine is latest TeacherWelcome FlowStart, then inner-filtered to TLM26_AllTeacher.
with joined as (
  select
    con.glific_id,
    JSON_EXTRACT_SCALAR(con.raw_fields, '$.buddy_name.value') as name,
    JSON_EXTRACT_SCALAR(con.raw_fields, '$.school.value') as school,
    JSON_EXTRACT_SCALAR(con.raw_fields, '$.gender.value') as gender,
    JSON_EXTRACT_SCALAR(con.raw_fields, '$.role.value') as role,
    schl.school_name,
    schl.state,
    schl.district,
    schl.city,
    pi.pi_assigned,
    cs.phone,
    cs.flow_label,
    cs.flow_name,
    cs.inserted_at,
    cs.consent_msg_status,
    case
      when sl.student_link is null then "No"
      else "Yes"
    end as student_link,
    case
      when sl.link_msg_status is null then "not sent"
      else sl.link_msg_status
    end as link_msg_status,
    case
      when con.group_labels like '%TLM26 - All Batch1 Teachers%' then 'Batch 1'
      when con.group_labels like '%TLM26 - All Batch2 Teachers%' then 'Batch 2'
      when con.group_labels like '%TLM26 - All Batch3 Teachers%' then 'Batch 3'
    end as teacher_batch_backup
  from {{ ref('int_teacher_welcome_start') }} as cs
  left join {{ ref('stg_contacts') }} as con
    on cs.phone = con.phone
  left join {{ ref('stg_schools') }} as schl
    on (
      regexp_contains(JSON_EXTRACT_SCALAR(con.raw_fields, '$.school.value'), r'^SC\d+$')
      and JSON_EXTRACT_SCALAR(con.raw_fields, '$.school.value') = schl.school_join_key
    )
    or (
      not regexp_contains(JSON_EXTRACT_SCALAR(con.raw_fields, '$.school.value'), r'^SC\d+$')
      and lower(trim(JSON_EXTRACT_SCALAR(con.raw_fields, '$.school.value')))
        = lower(trim(schl.school_name))
    )
  left join {{ ref('int_schools_pi') }} as pi
    on schl.school_join_key = pi.school_id
  left join {{ ref('int_teacher_student_link') }} as sl
    on con.phone = sl.contact_phone
  where con.group_labels like '%TLM26_AllTeacher%'
    and con.group_labels not like '{{ var("tlm_exclude_group_like") }}'
)

select
  glific_id,
  name,
  school,
  gender,
  role,
  school_name,
  state,
  district,
  city,
  pi_assigned,
  phone,
  flow_label,
  flow_name,
  inserted_at,
  consent_msg_status,
  {# student_link,
  link_msg_status, #}
  teacher_batch_backup
from joined
group by
  glific_id,
  name,
  school,
  gender,
  role,
  school_name,
  state,
  district,
  city,
  pi_assigned,
  phone,
  flow_label,
  flow_name,
  inserted_at,
  consent_msg_status,
  {# student_link,
  link_msg_status, #}
  teacher_batch_backup
