-- week_end is always Monday + 6 days (Sunday)
select
  week_start,
  week_end
from {{ ref('plio_video_watch_rate') }}
where week_end != date_add(week_start, interval 6 day)
