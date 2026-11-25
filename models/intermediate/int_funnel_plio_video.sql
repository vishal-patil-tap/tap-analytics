-- Latest Plio play-link per phone x funnel activity_id from Activity_Access bodies.
select
  msg.contact_phone,
  msg.activity_id,
  regexp_extract(msg.body, r'play/([A-Za-z0-9]+)') as plio_uuid,
  p.plio_id,
  p.video_title
from {{ ref('int_funnel_activity_messages') }} as msg
left join {{ ref('stg_plio_plio') }} as p
  on lower(regexp_extract(msg.body, r'play/([A-Za-z0-9]+)')) = lower(p.plio_uuid)
where msg.flow_label like '%Activity_Access%'
  and msg.flow_label not like '%Activity_QuizAccess%'
  and regexp_contains(ifnull(msg.body, ''), r'plio\.in/tap/play/')
qualify row_number() over (
  partition by msg.contact_phone, msg.activity_id
  order by msg.inserted_at desc
) = 1
