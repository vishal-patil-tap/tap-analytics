-- Latest Engagement Flow Start per phone x unit x activity (overall_student_engagement_activity).
select
  msg.contact_phone,
  msg.flow_name,
  msg.flow_label,
  msg.bsp_status,
  msg.inserted_at as sent_at,
  split(split(msg.flow_label, ',')[safe_ordinal(3)], '_')[safe_ordinal(2)] as unit_num,
  split(split(msg.flow_label, ',')[safe_ordinal(3)], '_')[safe_ordinal(3)] as activity_num,
  1 as activity_sent
from {{ ref('stg_tlm26_messages') }} as msg
left join {{ ref('stg_contacts') }} as con
  on msg.contact_phone = con.phone
where {{ tlm26_engagement_flow_name('msg.flow_name') }}
  and msg.flow_label like '%TLM26_Engagement_Flow_Start%'
  and con.group_labels not like '%TLM26_TapTeam%'
  and {{ tlm_excluded_phone_filter('msg.contact_phone') }}
qualify row_number() over (
  partition by msg.contact_phone, unit_num, activity_num
  order by msg.inserted_at desc
) = 1
