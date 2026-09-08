-- numerator must not exceed denominator
select
  week_start,
  total_students_in_week,
  students_who_watched
from {{ ref('plio_video_watch_rate') }}
where students_who_watched > total_students_in_week
