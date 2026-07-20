
-- STAR SCHEMA BUILD SCRIPT

-- Drop in reverse dependency order 
/*(fact_tickets references the dims, so it must go first;
  dim_flight references dim_route/dim_aircraft, so it goes before them)*/
IF OBJECT_ID('dbo.fact_tickets', 'U') IS NOT NULL DROP TABLE dbo.fact_tickets;
IF OBJECT_ID('dbo.dim_flight', 'U')   IS NOT NULL DROP TABLE dbo.dim_flight;
IF OBJECT_ID('dbo.dim_route', 'U')    IS NOT NULL DROP TABLE dbo.dim_route;
IF OBJECT_ID('dbo.dim_aircraft', 'U') IS NOT NULL DROP TABLE dbo.dim_aircraft;
IF OBJECT_ID('dbo.dim_customer', 'U') IS NOT NULL DROP TABLE dbo.dim_customer;
IF OBJECT_ID('dbo.dim_date', 'U')     IS NOT NULL DROP TABLE dbo.dim_date;
GO

-- DIM_DATE 
CREATE TABLE dim_date (
    date_key     INT PRIMARY KEY,        -- YYYYMMDD surrogate key
    full_date    DATE NOT NULL,
    [year]       INT NOT NULL,
    [month]      INT NOT NULL,
    [day]        INT NOT NULL,
    day_of_week  VARCHAR(10) NOT NULL,
    quarter      INT NOT NULL
);
GO

WITH calendar (d) AS (
    SELECT CAST('2010-01-01' AS DATE) AS d
    UNION ALL
    SELECT DATEADD(DAY, 1, d) FROM calendar WHERE d < '2025-12-31'
)
INSERT INTO dim_date (date_key, full_date, [year], [month], [day], day_of_week, quarter)
SELECT
    YEAR(d) * 10000 + MONTH(d) * 100 + DAY(d),
    d,
    YEAR(d),
    MONTH(d),
    DAY(d),
    DATENAME(WEEKDAY, d),
    DATEPART(QUARTER, d)
FROM calendar
OPTION (MAXRECURSION 0);   -- default cap is 100 recursions; we need ~5,844
GO

-- DIM_AIRCRAFT
CREATE TABLE dim_aircraft (
    aircraft_id       INT PRIMARY KEY,
    model             VARCHAR(50) NOT NULL,
    capacity          INT NOT NULL,
    manufacture_year  INT NOT NULL
);
GO

INSERT INTO dim_aircraft (aircraft_id, model, capacity, manufacture_year)
SELECT aircraft_id, model, capacity, manufacture_year
FROM aircraft;
GO

-- DIM_ROUTE 
CREATE TABLE dim_route (
    route_id             INT PRIMARY KEY,
    origin_code          VARCHAR(10) NOT NULL,
    origin_city          VARCHAR(100) NOT NULL,
    origin_country       VARCHAR(100) NOT NULL,
    destination_code     VARCHAR(10) NOT NULL,
    destination_city     VARCHAR(100) NOT NULL,
    destination_country  VARCHAR(100) NOT NULL,
    distance_km          FLOAT NOT NULL,
    is_self_loop_route   BIT NOT NULL DEFAULT 0
);
GO

INSERT INTO dim_route (route_id, origin_code, origin_city, origin_country,
                        destination_code, destination_city, destination_country,
                        distance_km, is_self_loop_route)
SELECT
    r.route_id,
    o.airport_code, o.city, o.country,
    d.airport_code, d.city, d.country,
    r.distance_km,
    CASE WHEN r.origin_airport_id = r.destination_airport_id THEN 1 ELSE 0 END
FROM routes r
JOIN airports o ON r.origin_airport_id = o.airport_id
JOIN airports d ON r.destination_airport_id = d.airport_id;
GO

-- DIM_CUSTOMER 
CREATE TABLE dim_customer (
    customer_id   INT PRIMARY KEY,
    gender        VARCHAR(20),
    country       VARCHAR(100) NOT NULL,
    loyalty_tier  VARCHAR(20) NOT NULL,
    signup_date   DATE NOT NULL
);
GO

INSERT INTO dim_customer (customer_id, gender, country, loyalty_tier, signup_date)
SELECT customer_id, gender, country, loyalty_tier, signup_date
FROM customers;
GO

-- DIM_FLIGHT (carries the speed-plausibility flag) 
CREATE TABLE dim_flight (
    flight_id             INT PRIMARY KEY,
    route_id              INT NOT NULL REFERENCES dim_route(route_id),
    aircraft_id           INT NOT NULL REFERENCES dim_aircraft(aircraft_id),
    departure_date        DATE NOT NULL,
    duration_minutes      INT NOT NULL,
    status                VARCHAR(20) NOT NULL,
    implied_speed_kmh     FLOAT,
    is_speed_implausible  BIT NOT NULL DEFAULT 0
);
GO

INSERT INTO dim_flight (flight_id, route_id, aircraft_id, departure_date,
                         duration_minutes, status, implied_speed_kmh, is_speed_implausible)
SELECT
    f.flight_id, f.route_id, f.aircraft_id, f.departure_date,
    f.duration_minutes, f.status,
    ROUND(r.distance_km / (f.duration_minutes / 60.0), 1),
    CASE WHEN (r.distance_km / (f.duration_minutes / 60.0)) NOT BETWEEN 400 AND 950 THEN 1 ELSE 0 END
FROM flights f
JOIN routes r ON f.route_id = r.route_id;
GO

-- FACT_TICKETS (grain: one row per ticket) 
CREATE TABLE fact_tickets (
    ticket_id                  INT PRIMARY KEY,
    booking_id                 INT NOT NULL,
    customer_id                INT NOT NULL REFERENCES dim_customer(customer_id),
    flight_id                  INT NOT NULL REFERENCES dim_flight(flight_id),
    booking_date_key           INT NOT NULL REFERENCES dim_date(date_key),
    booking_channel            VARCHAR(50),
    fare_class                 VARCHAR(20) NOT NULL,
    seat_number                VARCHAR(10),
    ticket_price                DECIMAL(10,2) NOT NULL,
    realized_revenue           DECIMAL(10,2) NOT NULL,
    is_cancelled_with_revenue  BIT NOT NULL DEFAULT 0,
    is_late_booking             BIT NOT NULL DEFAULT 0,
    is_duplicate_seat           BIT NOT NULL DEFAULT 0
);
GO

INSERT INTO fact_tickets (
    ticket_id, booking_id, customer_id, flight_id, booking_date_key,
    booking_channel, fare_class, seat_number, ticket_price, realized_revenue,
    is_cancelled_with_revenue, is_late_booking, is_duplicate_seat
)
SELECT
    t.ticket_id,
    t.booking_id,
    b.customer_id,
    b.flight_id,
    YEAR(b.booking_date) * 10000 + MONTH(b.booking_date) * 100 + DAY(b.booking_date),
    b.booking_channel,
    t.fare_class,
    t.seat_number,
    t.ticket_price,
    CASE WHEN f.status = 'Cancelled' THEN 0 ELSE t.ticket_price END,
    CASE WHEN f.status = 'Cancelled' THEN 1 ELSE 0 END,
    CASE WHEN b.booking_date > f.departure_date THEN 1 ELSE 0 END,
    CASE WHEN dup.n > 1 THEN 1 ELSE 0 END
FROM tickets t
JOIN bookings b ON t.booking_id = b.booking_id
JOIN flights f ON b.flight_id = f.flight_id
LEFT JOIN (
    SELECT b2.flight_id, t2.seat_number, COUNT(*) AS n
    FROM tickets t2
    JOIN bookings b2 ON t2.booking_id = b2.booking_id
    GROUP BY b2.flight_id, t2.seat_number
) dup ON dup.flight_id = f.flight_id AND dup.seat_number = t.seat_number;
GO