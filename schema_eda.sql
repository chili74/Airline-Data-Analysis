
--Explore all objects in the database 
select * from information_schema.tables 

--Explore all columns in the Database 
select * from information_schema.columns 

select * from information_schema.columns
where table_name = 'airports'

select * from information_schema.columns
where table_name = 'aircrafts'

select * from information_schema.columns
where table_name = 'routes'

select * from information_schema.columns
where table_name = 'bookings'

select * from information_schema.columns
where table_name = 'employees'

select * from information_schema.columns
where table_name = 'customers'

select * from information_schema.columns
where table_name = 'flights'

select * from information_schema.columns
where table_name = 'tickets'

select * from information_schema.columns
where table_name = 'maintenance'


