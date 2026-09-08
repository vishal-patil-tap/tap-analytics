select
  id as video_id,
  url,
  duration as video_length
from {{ source('plio_video', 'video') }}
