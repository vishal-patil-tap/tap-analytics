-- Funnel contact attributes. Same fields as int_student_details, but any
-- Glific contact on phone (not only TLM26_AllStudent). TapTeam still out.
-- One row per phone so the funnel fact does not fan out.
select
  glific_id,
  phone,
  JSON_EXTRACT_SCALAR(raw_fields, '$.student_id.value') as student_id,
  language,
  case
    when regexp_contains(group_labels, r'TLM26_AllStudents_Batch\d+') then
      concat('Batch ', regexp_extract(group_labels, r'TLM26_AllStudents_Batch(\d+)'))
    when regexp_contains(group_labels, r'TLM26_AllStudents_NoBatch') then
      'No Batch Assigned'
    else null
  end as batch,
  JSON_EXTRACT_SCALAR(raw_fields, '$.buddy_name.value') as student_name,
  JSON_EXTRACT_SCALAR(raw_fields, '$.grade.value') as grade,
  JSON_EXTRACT_SCALAR(raw_fields, '$.gender.value') as gender,
  JSON_EXTRACT_SCALAR(raw_fields, '$.course.value') as course,
  JSON_EXTRACT_SCALAR(raw_fields, '$.level.value') as level,
  JSON_EXTRACT_SCALAR(raw_fields, '$.school_id.value') as school_id
from {{ ref('stg_contacts') }}
where group_labels not like '{{ var("tlm_exclude_group_like") }}'
qualify row_number() over (
  partition by phone
  order by glific_id
) = 1
