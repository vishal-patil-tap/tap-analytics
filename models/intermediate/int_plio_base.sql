-- 2026 plios with user/video attributes.
select
  s.session_id,
  s.user_id,
  u.glific_id,
  u.contact_phone,
  s.plio_id,
  p.video_title,
  v.url,
  v.video_length,
  s.watch_time,
  s.retention,
  s.created_at
from {{ ref('stg_plio_session') }} as s
left join {{ ref('stg_plio_user') }} as u
  on s.user_id = u.user_id
left join {{ ref('stg_plio_plio') }} as p
  on s.plio_id = p.plio_id
left join (
  select
    video_id,
    url,
    video_length
  from {{ ref('stg_plio_video') }}
  where video_length > 0
) as v
  on p.video_id = v.video_id
where p.video_title like '{{ var("plio_title_like") }}'
