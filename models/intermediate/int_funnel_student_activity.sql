-- One row per phone x curriculum activity_id. Flags and latest step attributes.
select
  contact_phone,
  activity_id,
  any_value(activity_type) as activity_type,
  regexp_extract(activity_id, r'(U\d+)') as unit_num,
  regexp_extract(activity_id, r'Activity\s+([CR]A\d+)') as activity_num,
  max(case when flow_label like '%Activity_Sent%' then 1 else 0 end) as sent_flag,
  max(
    case
      when flow_label like '%Activity_Access%'
        and flow_label not like '%Activity_QuizAccess%'
      then 1
      else 0
    end
  ) as access_flag,
  max(case when flow_label like '%Activity_Submission%' then 1 else 0 end) as submission_flag,
  max(case when flow_label like '%Activity_QuizSent%' then 1 else 0 end) as quiz_sent_flag,
  max(case when flow_label like '%Activity_QuizAccess%' then 1 else 0 end) as quiz_access_flag,
  max(
    case
      when flow_label like '%Activity_QuizAttempted%'
        or {{ is_quiz_attempted_body('body') }}
      then 1
      else 0
    end
  ) as quiz_attempted_flag,
  max(case when flow_label like '%Activity_QuizCompleted%' then 1 else 0 end) as quiz_completed_flag,
  min(case when flow_label like '%Activity_Sent%' then inserted_at end) as sent_at,
  min(
    case
      when flow_label like '%Activity_Access%'
        and flow_label not like '%Activity_QuizAccess%'
      then inserted_at
    end
  ) as access_at,
  min(case when flow_label like '%Activity_Submission%' then inserted_at end) as submission_at,
  min(inserted_at) as first_at,
  coalesce(
    array_agg(
      if(flow_label like '%Activity_Sent%', flow_name, null)
      ignore nulls
      order by inserted_at desc
      limit 1
    )[safe_offset(0)],
    array_agg(flow_name ignore nulls order by inserted_at desc limit 1)[safe_offset(0)]
  ) as flow_name,
  coalesce(
    array_agg(
      if(flow_label like '%Activity_Sent%', flow_label, null)
      ignore nulls
      order by inserted_at desc
      limit 1
    )[safe_offset(0)],
    array_agg(flow_label ignore nulls order by inserted_at desc limit 1)[safe_offset(0)]
  ) as flow_label,
  coalesce(
    array_agg(
      if(flow_label like '%Activity_Sent%', bsp_status, null)
      ignore nulls
      order by inserted_at desc
      limit 1
    )[safe_offset(0)],
    array_agg(bsp_status ignore nulls order by inserted_at desc limit 1)[safe_offset(0)]
  ) as bsp_status,
  coalesce(
    array_agg(
      if(
        flow_label like '%Activity_Sent%' and ifnull(trim(body), '') != '',
        body,
        null
      )
      ignore nulls
      order by inserted_at desc
      limit 1
    )[safe_offset(0)],
    array_agg(
      if(ifnull(trim(body), '') != '', body, null)
      ignore nulls
      order by inserted_at desc
      limit 1
    )[safe_offset(0)]
  ) as body,
  array_agg(
    if(
      flow_label like '%Activity_Access%'
        and flow_label not like '%Activity_QuizAccess%',
      bsp_status,
      null
    )
    ignore nulls
    order by inserted_at desc
    limit 1
  )[safe_offset(0)] as access_msg_status,
  array_agg(
    if(flow_label like '%Activity_Submission%', bsp_status, null)
    ignore nulls
    order by inserted_at desc
    limit 1
  )[safe_offset(0)] as submission_msg_status,
  array_agg(
    if(flow_label like '%Activity_Submission%', gcs_url, null)
    ignore nulls
    order by inserted_at desc
    limit 1
  )[safe_offset(0)] as artefact,
  array_agg(
    if(
      flow_label like '%Activity_Access%'
        and flow_label not like '%Activity_QuizAccess%',
      case
        when regexp_contains(ifnull(body, ''), r'plio\.in/tap/play/') then 'plio'
        when regexp_contains(ifnull(body, ''), r'(?i)youtu(\.be|be\.com)') then 'youtube'
      end,
      null
    )
    ignore nulls
    order by inserted_at desc
    limit 1
  )[safe_offset(0)] as sent_video_link
from {{ ref('int_funnel_activity_messages') }}
where contact_phone is not null
  and activity_id is not null
group by contact_phone, activity_id
