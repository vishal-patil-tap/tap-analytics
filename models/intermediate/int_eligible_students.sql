-- Eligible = TLM students with a school match and a Plio user row.
-- Join key is tabSchool.name (school_join_key), display name is tabSchool.name1.
select distinct
  s.student_name,
  cast(s.glific_id as string) as glific_id,
  s.phone as contact_phone,
  s.school_id,
  sch.school_name,
  sch.city,
  sch.state
from {{ ref('int_student_details') }} as s
inner join {{ ref('stg_schools') }} as sch
  on s.school_id = sch.school_join_key
inner join {{ ref('stg_plio_user') }} as u
  on cast(s.glific_id as string) = cast(u.glific_id as string)
where s.glific_id is not null
