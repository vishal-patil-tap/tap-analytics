{{
  config(
    materialized='table',
    cluster_by=['state', 'district', 'school_id']
  )
}}

-- Snapshot roster. contacts has no updated_at, so this is a full refresh (not incremental).
select
  r.glific_id,
  r.phone,
  r.group_labels,
  r.language,
  r.name,
  r.grade,
  r.gender,
  r.course,
  r.level,
  r.school,
  r.school_id,
  case
    when (
      r.group_labels like '%TLM22%'
      or r.group_labels like '%TLM23%'
      or r.group_labels like '%TLM24%'
      or r.group_labels like '%TLM25%'
    ) then 'Old'
    else 'New'
  end as student_type,
  case
    when r.group_labels like '%TLM26_AllStudents_Batch1%' then 'Batch 1'
    when r.group_labels like '%TLM26_AllStudents_Batch2%' then 'Batch 2'
    when r.group_labels like '%TLM26_AllStudents_Batch3%' then 'Batch 3'
    when r.group_labels like '%TLM26_AllStudents_Batch4%' then 'Batch 4'
    when r.group_labels like '%TLM26_AllStudents_Batch MCD%' then 'Batch MCD'
    when r.group_labels like '%TLM26_AllStudents_Batch Moga_P%' then 'Batch Moga Primary'
    when r.group_labels like '%TLM26_AllStudents_NoBatch%' then 'Batch not assigned'
  end as batch,
  pi.school_name,
  pi.type,
  pi.model,
  pi.state,
  pi.district,
  pi.city,
  pi.pi_assigned,
  case
    when pc.flow_name like 'TLM26_StudentWelcome_Flow' then 'Scratch'
    when pc.flow_name like 'Backend_StudentConsent_Flow' then 'Backend'
    else 'Not Applicable'
  end as registration_type,
  pc.consent_at
from {{ ref('int_registered_students') }} as r
left join {{ ref('int_schools_pi') }} as pi
  on r.school_id = pi.school_id
left join {{ ref('int_parent_consent') }} as pc
  on r.phone = pc.contact_phone
