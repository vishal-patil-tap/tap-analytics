-- Earliest parent-consent message per phone.
select
  contact_phone,
  flow_label,
  flow_name,
  inserted_at as consent_at
from {{ ref('stg_tlm26_messages') }}
where flow_label like '%TLM26_ParentConsent_Received%'
qualify row_number() over (
  partition by contact_phone
  order by inserted_at asc
) = 1
