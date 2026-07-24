--Measure

--Total customers 
select count(customer_id) as total_customers 
from customers 

--average ticket price for fare classes
select avg(ticket_price) as average_price
from tickets
where fare_class = 'economy' 

select avg(ticket_price) as average_price
from tickets
where fare_class = 'premium economy' 

select avg(ticket_price) as average_price
from tickets
where fare_class = 'business' 

select avg(ticket_price) as average_price
from tickets
where fare_class = 'first class' 

--optimal capacity 
select sum(capacity) as Total_capacity
from aircraft

--Total aircrafts 
select count(aircraft_id) as number_of_aircrafts
from aircraft

--Total maintenance costs
select sum(cost) as Total_maintenance_costs
from maintenance

--average maintenance costs
select avg(cost) as Total_maintenance_costs
from maintenance

--Total amount hours flown 
select sum(duration_minutes/60) || 'h' as Total_hours_flown 
from flights 


