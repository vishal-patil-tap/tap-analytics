select
  week_start,
  total_students_in_week,
  students_who_accessed
from {{ ref('weekly_access_rate') }}
where students_who_accessed > total_students_in_week
