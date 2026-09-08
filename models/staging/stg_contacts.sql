select
  id as glific_id,
  phone,
  group_labels,
  language,
  raw_fields
from {{ source('contact', 'contacts') }}
