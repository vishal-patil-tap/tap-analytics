select
  id as session_id,
  user_id,
  retention,
  plio_id,
  watch_time,
  created_at
from {{ source('plio_video', 'session') }}
