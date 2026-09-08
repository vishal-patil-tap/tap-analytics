select
  id as plio_id,
  name as video_title,
  video_id
from {{ source('plio_video', 'plio') }}
