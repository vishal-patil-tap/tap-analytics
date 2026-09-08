select
  week_start,
  students_who_were_sent_quiz,
  students_who_completed_quiz
from {{ ref('weekly_quiz_completion_rate') }}
where students_who_completed_quiz > students_who_were_sent_quiz
