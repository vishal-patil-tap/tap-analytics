select
  id as user_id,
  unique_id as glific_id,
  mobile as contact_phone
from {{ source('plio_video', 'user') }}
