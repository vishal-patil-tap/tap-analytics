select
  week_start,
  week_end
from {{ ref('plio_avg_video_watch_pct') }}
where week_end != date_add(week_start, interval 6 day)
