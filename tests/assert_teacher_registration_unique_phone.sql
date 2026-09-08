{{ config(severity='warn') }}

-- School name1 join can fan out; source SQL keeps those rows.
select
  phone,
  count(*) as n
from {{ ref('tlm26_teacher_registration') }}
group by phone
having n > 1
