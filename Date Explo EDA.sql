--Date exploration 

-- Months in operation

 select 
 min(departure_date) as first_departure, 
 max(departure_date) as last_departure, 
 datediff(month, min(departure_date), max(departure_date)) as "months of operation"
 from flights

-- Maintenance timeframe 

select 
min(maintenance_date) as first_maintenance, 
max(maintenance_date) as last_maintenance
from maintenance 

-- Customer sign up timeframe 

select 
min(signup_date) as first_signup, 
max(signup_date) as last_signup, 
datediff(month, min(signup_date), max(signup_date)) as "sign up timeframe"
from customers

-- First and last hire 

select 
min(hire_date) as first_hire,
max(hire_date) as last_hire
from employees

-- First and last timeframe 

select 
min(booking_date) as first_booking_date,
max(booking_date) as last_booking_date
from bookings

--Oldest and youngest aircraft 

select 
min(manufacture_year) as oldest_aircraft,
max(manufacture_year) as newest_aircraft
from aircraft
