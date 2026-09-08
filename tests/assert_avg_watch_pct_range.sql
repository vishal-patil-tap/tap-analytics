{{ config(severity='warn') }}

-- Retention chunk count can exceed duration; SQL does not cap at 100.
select
  week_start,
  avg_video_watch_pct
from {{ ref('plio_avg_video_watch_pct') }}
where avg_video_watch_pct > 100
   or avg_video_watch_pct < 0
