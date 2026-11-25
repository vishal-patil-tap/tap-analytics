-- Engagement and funnel both use MEL TLM26_Messages only (not live Glific).
select
  id as message_id,
  body,
  contact_name,
  contact_phone,
  inserted_at,
  flow_label,
  flow_name,
  media_url,
  flow,
  bsp_status,
  gcs_url
from {{ source('messages', 'TLM26_Messages') }}
