select
  contact_phone,
  unit_num,
  activity_num,
  count(*) as n
from {{ ref('overall_student_engagement_activity') }}
group by 1, 2, 3
having n > 1
