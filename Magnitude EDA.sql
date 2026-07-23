-- Magnitude 

--Total customers by countries 

select country, 
count(customer_id)  as "Total customers"
from customers
group by country

-- Total cyustomer by gender 
select gender,
count(customer_id) as total_customers
from customers 
group by gender 
order by total_customers desc 

-- Total tickets by fare class 
select fare_class, 
count(ticket_id) as "Total ticket"
from tickets
group by fare_class
order by "Total ticket" desc

-- Tickets sales by fare class 
select fare_class, 
sum(ticket_price) as "Total ticket sales"
from tickets
group by fare_class
order by "Total ticket sales" desc

