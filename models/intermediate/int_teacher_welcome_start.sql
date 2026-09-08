-- Latest TeacherWelcome FlowStart per phone.
select
  contact_phone as phone,
  flow_label,
  flow_name,
  inserted_at,
  case
    when bsp_status like 'error' then 'Sending_failed'
    else bsp_status
  end as consent_msg_status
from {{ ref('stg_tlm26_messages') }}
where flow_label like '%TLM26_FlowStart%'
  and flow_name like '%TLM26_TeacherWelcome_Flow%'
qualify row_number() over (
  partition by contact_phone
  order by inserted_at desc
) = 1
