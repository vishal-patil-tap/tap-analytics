-- Latest judged submission validity per student_id (ST…).
-- Used only as an attribute on overall_student_engagement_activity;
-- does not change access / submission / quiz flags or weekly rates.
select
  student_id,
  submission_validity
from {{ ref('stg_submissions') }}
where student_id is not null
  and submission_validity in ('Valid', 'Invalid')
qualify row_number() over (
  partition by student_id
  order by coalesce(completed_at, created_at, creation) desc
) = 1
