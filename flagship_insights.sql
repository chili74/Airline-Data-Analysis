
--BUSINESS INSIGHTS AFTER DATA AUDIT  

--Route profitability
select dr.origin_city + ' -> ' + dr.destination_city as route,
       sum(ffo.profit) as total_profit, count(*) as flights
from fact_flight_operations ffo
join dim_flight df on ffo.flight_id = df.flight_id
join dim_route dr on df.route_id = dr.route_id
group by dr.origin_city, dr.destination_city
order by total_profit asc;

--Load factor by aircraft size class
select aircraft_size_class, avg(load_factor)*100 as avg_load_factor_pct
from fact_flight_operations
group by aircraft_size_class;

--On-time performance by aircraft age
select case
         when (2026 - da.manufacture_year) <= 5 then '0-5 yrs'
         when (2026 - da.manufacture_year) <= 10 then '6-10 yrs'
         else '10+ yrs'
       end as age_band,
       df.status, count(*) as n
from dim_flight df
join dim_aircraft da on df.aircraft_id = da.aircraft_id
group by case when (2026 - da.manufacture_year) <= 5 then '0-5 yrs'
              when (2026 - da.manufacture_year) <= 10 then '6-10 yrs'
              else '10+ yrs' end, df.status;


--Fare-class price compression (quantified)
select fare_class, avg(ticket_price) as avg_price
from fact_tickets
group by fare_class
order by avg_price desc;

--Customer value segmentation by loyalty tier
select dc.loyalty_tier, count(distinct dc.customer_id) as customers,
       sum(ft.ticket_price) as total_revenue,
       sum(ft.ticket_price) * 100.0 / sum(sum(ft.ticket_price)) over () as percent_of_revenue
from dim_customer dc
join fact_tickets ft on ft.customer_id = dc.customer_id
group by dc.loyalty_tier
order by total_revenue desc;

--Department cost structure
select department, count(*) as headcount, sum(salary) as total_salary, avg(salary) as avg_salary
from employees
group by department
order by total_salary desc;
