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
where group_labels like '{{ var("tlm_student_group_like") }}'
  and group_labels not like '{{ var("tlm_exclude_group_like") }}'
