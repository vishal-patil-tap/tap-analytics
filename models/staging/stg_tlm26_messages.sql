-- MEL snapshot plus newer live Glific engagement rows.
-- MEL_2025_26.TLM26_Messages currently ends ~2026-07-29 and has no Batch 2
-- engagement; Batch 2 (and later Batch 1 activities) are in live Glific.
with mel as (
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
),

mel_max as (
  select max(inserted_at) as max_inserted_at
  from mel
),

glific_new_engagement as (
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
  from {{ source('glific_messages', 'messages') }}
  where {{ tlm26_engagement_flow_name('flow_name') }}
    and inserted_at > (select max_inserted_at from mel_max)
)

select * from mel
union all
select * from glific_new_engagement
