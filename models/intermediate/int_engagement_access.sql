-- Latest Activity_Access per phone x unit x activity.
-- Unit/Activity parse is intentionally different from flow_start (source SQL).
select
  contact_phone,
  flow_name,
  flow_label,
  bsp_status,
  split(split(flow_label, 'TLM26_')[safe_ordinal(2)], '_')[safe_ordinal(1)] as unit_num,
  split(split(flow_label, 'TLM26_')[safe_ordinal(2)], '_')[safe_ordinal(2)] as activity_num,
  1 as activity_access
from {{ ref('stg_tlm26_messages') }}
where {{ tlm26_engagement_flow_name('flow_name') }}
  and flow_label like '%Activity_Access%'
qualify row_number() over (
  partition by contact_phone, unit_num, activity_num
  order by inserted_at desc
) = 1
