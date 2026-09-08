-- Latest Submission_Received per phone x unit x activity.
select
  contact_phone,
  gcs_url as artefact,
  flow_name,
  flow_label,
  bsp_status,
  concat('B', split(split(flow_label, 'TLM26_B')[safe_ordinal(2)], '_')[safe_ordinal(1)]) as unit_num,
  split(split(flow_label, 'TLM26_B')[safe_ordinal(2)], '_')[safe_ordinal(2)] as activity_num,
  1 as activity_submission
from {{ ref('stg_tlm26_messages') }}
where {{ tlm26_engagement_flow_name('flow_name') }}
  and flow_label like '%Submission_Received%'
qualify row_number() over (
  partition by contact_phone, unit_num, activity_num
  order by inserted_at desc
) = 1
