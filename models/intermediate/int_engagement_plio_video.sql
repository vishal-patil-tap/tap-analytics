-- Latest Plio play-link per phone x unit x activity from Activity_Access bodies.
-- Unit/activity parse matches int_engagement_access. Attribute only; not used in rates.
select
  msg.contact_phone,
  split(split(msg.flow_label, 'TLM26_')[safe_ordinal(2)], '_')[safe_ordinal(1)] as unit_num,
  split(split(msg.flow_label, 'TLM26_')[safe_ordinal(2)], '_')[safe_ordinal(2)] as activity_num,
  regexp_extract(msg.body, r'play/([A-Za-z0-9]+)') as plio_uuid,
  p.plio_id,
  p.video_title
from {{ ref('stg_tlm26_messages') }} as msg
left join {{ ref('stg_plio_plio') }} as p
  on lower(regexp_extract(msg.body, r'play/([A-Za-z0-9]+)')) = lower(p.plio_uuid)
where {{ tlm26_engagement_flow_name('msg.flow_name') }}
  and msg.flow_label like '%Activity_Access%'
  and regexp_contains(ifnull(msg.body, ''), r'plio\.in/tap/play/')
qualify row_number() over (
  partition by msg.contact_phone, unit_num, activity_num
  order by msg.inserted_at desc
) = 1
