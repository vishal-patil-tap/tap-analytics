select
  id as plio_id,
  name as video_title,
  uuid as plio_uuid,
  video_id
from {{ source('plio_video', 'plio') }}
