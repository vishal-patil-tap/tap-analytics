select
  week_start,
  total_students_in_week,
  students_who_submitted
from {{ ref('weekly_submission_rate') }}
where students_who_submitted > total_students_in_week
