-- Phone-level quiz flags for the engagement fact. Not joined on unit/activity
-- because quiz labels usually have no matching unit_num/activity_num.
select
  right(contact_phone, 10) as phone_last10,
  max(
    if(
      status_tag = 'Activity_QuizSent'
      or flow_label like '%Activity_QuizSent%',
      1,
      0
    )
  ) as quiz_sent,
  max(
    if(
      status_tag = 'Activity_QuizAttempted'
      or flow_label like '%Activity_QuizAttempted%'
      or {{ is_quiz_attempted_body('body') }},
      1,
      0
    )
  ) as quiz_attempted,
  max(
    if(
      status_tag = 'Activity_QuizCompleted'
      or flow_label like '%Activity_QuizCompleted%',
      1,
      0
    )
  ) as quiz_completed
from {{ ref('int_tlm26_activity_message_events') }}
where contact_phone is not null
group by 1
