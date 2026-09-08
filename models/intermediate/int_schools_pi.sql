select
  school_join_key as school_id,
  school_name,
  type,
  model,
  state,
  district,
  city,
  case
    when district in ('Central', 'East', 'North', 'North West', 'South', 'South East', 'South West')
      then "Neelam Vashishth"
    when district in ('Thane') then "Abhijit Surgude"
    when district in ('Mumbai') then "Dhanesh Kamble"
    when district in ('Moga') then "Durgesh Rai"
    when district in ('Pune', 'Pune ZP') then "Juhi Jiten Shah"
     {# when district in ('Pune ZP') then "Shivprsad Kumbhar" #}
    when (district in ('Delhi MCD', 'New Delhi') or city in ('Delhi')) then "Parth Azad"
  end as pi_assigned
from {{ ref('stg_schools') }}
