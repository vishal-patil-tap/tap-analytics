-- One contact per phone. Prefer a numbered AllStudents batch over NoBatch over other labels.
select
  glific_id,
  phone,
  group_labels,
  language,
  case
    when initcap(JSON_EXTRACT_SCALAR(raw_fields, '$.buddy_name.value')) is null
      then "Not entered"
    else initcap(JSON_EXTRACT_SCALAR(raw_fields, '$.buddy_name.value'))
  end as name,
  case
    when JSON_EXTRACT_SCALAR(raw_fields, '$.grade.value') is null then "Not entered"
    else JSON_EXTRACT_SCALAR(raw_fields, '$.grade.value')
  end as grade,
  case
    when JSON_EXTRACT_SCALAR(raw_fields, '$.gender.value') is null then "Not enetered"
    else JSON_EXTRACT_SCALAR(raw_fields, '$.gender.value')
  end as gender,
  case
    when JSON_EXTRACT_SCALAR(raw_fields, '$.course.value') is null then "Not enetered"
    else JSON_EXTRACT_SCALAR(raw_fields, '$.course.value')
  end as course,
  case
    when JSON_EXTRACT_SCALAR(raw_fields, '$.level.value') is null then "Not enetered"
    else JSON_EXTRACT_SCALAR(raw_fields, '$.level.value')
  end as level,
  JSON_EXTRACT_SCALAR(raw_fields, '$.school.value') as school,
  JSON_EXTRACT_SCALAR(raw_fields, '$.school_id.value') as school_id
from {{ ref('stg_contacts') }}
where group_labels like '%TLM26_AllStudent%'
  and group_labels not like '{{ var("tlm_exclude_group_like") }}'
qualify row_number() over (
  partition by phone
  order by
    case
      when regexp_contains(group_labels, r'TLM26_AllStudents_Batch[0-9]+') then 1
      when group_labels like '%TLM26_AllStudents_NoBatch%' then 99
      else 100
    end
) = 1
