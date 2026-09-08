select
  name1 as school_name,
  name as school_join_key,
  city,
  district,
  state,
  model,
  type
from {{ source('dalgo_staging', 'tabSchool') }}
