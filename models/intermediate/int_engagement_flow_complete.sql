-- Flow complete is phone-level in the source SQL (no unit/activity).
select
  contact_phone,
  flow_name,
  flow_label,
  bsp_status,
  1 as activity_complete
from {{ ref('stg_tlm26_messages') }}
where {{ tlm26_engagement_flow_name('flow_name') }}
  and flow_label like '%Flow_end%'
  and flow_label like '%tlm26_flow_end%'
group by 1, 2, 3, 4, 5
