
--DATA QUALITY AUDIT 

--Flights with booking dates after their departure dates ( Multiple cases)
select b.booking_id, f.flight_id, b.booking_date, f.departure_date 
from bookings b
full join flights f 
on b.flight_id = f.flight_id 
where booking_date > departure_date

--Checking for flights that have sold more tickets than the aircraft's capacity (We have 0 cases)

select f.flight_id, a.capacity, count(t.ticket_id) as tickets_sold, count(t.ticket_id) - a.capacity as seats_oversold 
from flights f 
join aircraft a on f.aircraft_id = a.aircraft_id 
join bookings b on b.flight_id = f.flight_id 
join tickets t on t.booking_id = b.booking_id 
group by f.flight_id, a.capacity 
having count(t.ticket_id) > a.capacity
order by seats_oversold desc

--Check for routes where the origin and destination airports are the same (We have 3 cases)

select * from routes 
where origin_airport_id = destination_airport_id

--Checking flights cancelled with revenue ( Multiple cases )

select t.ticket_id, b.booking_id , f.flight_id, f.status, t.ticket_price 
from tickets t 
join bookings b on t.booking_id = b.booking_id 
join flights f on b.flight_id = f.flight_id 
where f.status = 'Cancelled'

--Checking for implausable speed for flights (distance / duration): Multiple cases 

select f.flight_id, r.distance_km, f.duration_minutes, 
cast (round(r.distance_km/ (f.duration_minutes / 60.0), 2) as decimal(10,2)) as implied_speed_km 
from flights f 
join routes r on f.route_id = r.route_id 


--Fare class pricing hierarchy check: Difference in the three fare classes is 57,54,and 158 rand. This doesnt making any business sense

with Fare_class_difference as (
select fare_class, avg(ticket_price) as avg_price 
from tickets 
group by fare_class
)

select fare_class,round(avg_price, 2) as avg_price, round(avg_price - lag(avg_price) over (order by avg_price),2) as difference
from Fare_class_difference
order by avg_price;

--Checking for duplicate seats identified

select f.flight_id,t.seat_number,count(*) as tickets_on_this_seat, count(distinct t.booking_id) as distinct_bookings_involved
from tickets t
join bookings b on t.booking_id = b.booking_id
join flights f on b.flight_id = f.flight_id
group by f.flight_id, t.seat_number
having count(*) > 1
order by distinct_bookings_involved desc;

--job_titles are not correctly assigned to the depatments 
select department, job_title from employees

--created the functional area of employees based on their job title
alter employees
add functional_area varchar(50);

update employees
set functional_area =
    case
        when job_title = 'Pilot' then 'Flight Operations'
        when job_title = 'Attendant' then 'Cabin Services'
        when job_title = 'Technician' then 'Maintenance and Engineering'
        when job_title = 'Officer' then 'Corporate / Administration'
        when job_title = 'Manager' then 'Management (Cross Functional)'
        else 'Other'
    end;

select functional_area, 