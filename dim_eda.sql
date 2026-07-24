--Dimensions Exporation 

--countries we oprate in 
select distinct country from airports

--Models in the aircraft fleet 
select distinct model from aircraft

--capacity of aircraft
select distinct capacity  from aircraft

--unique aircraft year-model
select distinct manufacture_year from aircraft

--number of customers
select distinct customer_id from bookings  

--unique days of operations
select distinct booking_date from bookings 
order by booking_date desc

--booking platforms 
select distinct booking_channel from bookings

--country the airline oprates in 
select distinct country from customers

--unique loyal tier 
select distinct loyalty_tier from customers

--unique signup date 
select distinct signup_date from customers
order by signup_date desc

--different department 
select distinct department from employees

--different job title
select distinct job_title from employees

-- 180 aircrafts 
select distinct aircraft_id from maintenance 

--maintenance type 
select distinct maintenance_type from maintenance

--number of routes
select distinct route_id from routes

