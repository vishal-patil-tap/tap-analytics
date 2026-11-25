-- Funnel base: labelled TLM26 U/RA/CA activity messages (user starter SQL, TLM26).
select
  msg.message_id,
  msg.inserted_at,
  msg.contact_phone,
  msg.body,
  msg.flow_name,
  msg.flow_label,
  msg.bsp_status,
  msg.gcs_url,
  regexp_extract(msg.flow_label, {{ tlm26_funnel_activity_regex() }}) as activity_id,
  case
    when regexp_contains(msg.flow_label, r'Activity\s+CA\d+') then 'CA'
    when regexp_contains(msg.flow_label, r'Activity\s+RA\d+') then 'RA'
  end as activity_type
from {{ ref('stg_tlm26_messages') }} as msg
where regexp_contains(ifnull(msg.flow_label, ''), {{ tlm26_funnel_activity_regex() }})
