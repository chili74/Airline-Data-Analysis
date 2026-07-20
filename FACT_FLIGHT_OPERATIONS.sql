
-- Fact_flight_operations 
-- Derived fields: block hours, operating cost, allocated maintenance cost, profit, load factor.


if object_id('dbo.fact_flight_operations', 'U') IS NOT NULL
    drop table  dbo.fact_flight_operations;
go

create table fact_flight_operations (
    flight_id                  int primary key references dim_flight(flight_id),
    tickets_sold                int NOT NULL,
    gross_revenue               decimal(12,2) NOT NULL,
    realized_revenue            decimal(12,2) NOT NULL,
    estimated_block_hours       decimal(6,2) NOT NULL,
    aircraft_size_class         varchar(20) NOT NULL,
    cost_per_block_hour         decimal(10,2) NOT NULL,
    estimated_operating_cost    decimal(12,2) NOT NULL,
    allocated_maintenance_cost  decimal(12,2) NOT NULL,
    profit                      decimal(12,2) NOT NULL,
    load_factor                 decimal(5,4) NOT NULL
);
go

with flight_hours as (
    select df.flight_id, df.aircraft_id, dr.distance_km,
           dr.distance_km / 780.0 + 0.5 as est_block_hours
    from dim_flight df
    join dim_route dr on df.route_id = dr.route_id
),
aircraft_rate as (
    select fh.aircraft_id,
           sum(m.cost) * 1.0 / nullif(sum(fh.est_block_hours), 0) as maint_rate_per_hour
    from flight_hours fh
    left joinmaintenance m on m.aircraft_id = fh.aircraft_id
    group by fh.aircraft_id
),
ticket_agg as (
    select flight_id,
           count(*) as tickets_sold,
           sum(ticket_price) as gross_revenue,
           sum(realized_revenue) as realized_revenue
    from fact_tickets
    group by flight_id
)
insert into fact_flight_operations
select
    fh.flight_id,
    ta.tickets_sold,
    ta.gross_revenue,
    ta.realized_revenue,
    fh.est_block_hours,
    case when da.capacity <= 220 then 'Narrow-body' else 'Wide-body' end,
    case when da.capacity <= 220 then 4733.00 else 10351.00 end,
    fh.est_block_hours * case when da.capacity <= 220 then 4733.00 else 10351.00 end,
    fh.est_block_hours * ar.maint_rate_per_hour,
    ta.realized_revenue
        - (fh.est_block_hours * case when da.capacity <= 220 then 4733.00 else 10351.00 end)
        - (fh.est_block_hours * ar.maint_rate_per_hour),
    cast(ta.tickets_sold as decimal(10,4)) / da.capacity   -- FIX: was DECIMAL(5,4), overflowed at tickets_sold >= 10
from flight_hours fh
join dim_aircraft da on fh.aircraft_id = da.aircraft_id
join aircraft_rate ar on ar.aircraft_id = fh.aircraft_id
join ticket_agg ta on ta.flight_id = fh.flight_id;
go

create view dbo.vw_fact_flight_operations AS
select * from fact_flight_operations;


