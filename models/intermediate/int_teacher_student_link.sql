-- Latest student-link-shared message on TeacherWelcome flow, per phone.
select
  contact_phone,
  flow_label,
  flow_name,
  inserted_at,
  case when flow_label like '%student%' then 1 else 0 end as student_link,
  case
    when bsp_status like 'error' then 'Sending_failed'
    else bsp_status
  end as link_msg_status
from {{ ref('stg_tlm26_messages') }}
where flow_label like '%student%link%shared%'
  and flow_name like '%TLM26_TeacherWelcome_Flow%'
qualify row_number() over (
  partition by contact_phone
  order by inserted_at desc
) = 1
