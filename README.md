
# Airline Operations: SQL Data Quality & Business Intelligence Project

A full SQL Server project that audits synthetic airline operations data, rebuilds it into a star schema, and surfaces business insights through flight- and ticket-level analysis.

## Overview

This repository shows how poor data quality can distort airline analytics and how a rebuilt dimensional model can expose the real business story.

Using about 47,000 rows across 10 source tables, I:
- audited the raw data for nulls, duplicates, referential integrity, and domain plausibility,
- rebuilt the dataset into a star schema,
- modeled flight operating cost and profit using sourced assumptions,
- and wrote insight queries for route profitability, load factor, fare structure, and customer value.

## Why this project matters

The headline finding is that every route is unprofitable under sourced industry cost assumptions, but not because the airline is badly run. The core issue is volume: average ticket sales are far below what a 150–350 seat aircraft needs to break even.

This only became visible after a full data-quality audit and a dimensional rebuild.

## Repository contents

- `sql/01_data_quality_audit.sql` — 15-point audit covering nulls, duplicates, foreign keys, and airline-domain checks.
- `sql/02_star_schema_build.sql` — star schema build for `dim_date`, `dim_aircraft`, `dim_route`, `dim_customer`, `dim_flight`, and `fact_tickets`.
- `sql/03_fact_flight_operations.sql` — flight-grain fact table with modeled operating cost, maintenance allocation, and profit.
- `sql/04_flagship_insights.sql` — six business insight queries.
- `docs/schema_diagram.png` — star schema ERD.
- `docs/data_quality_findings.md` — full audit notes, examples, and corrections.

## Source data

The raw dataset contains 10 tables and roughly 47,000 rows:
- aircraft
- airports
- bookings
- customers
- employees
- flights
- maintenance
- routes
- tickets

## Data quality audit

### Clean checks
- Nulls, duplicate primary keys, and all nine foreign key relationships passed validation.

### Key issues found
- 4,565 of 9,000 bookings were dated after departure.
- 24 duplicate seat assignments appeared on the same flight.
- Implied flight speed ranged from 15 to 15,247 km/h, which shows distance and duration were generated independently.
- First-class fares averaged only 2.1% above business class fares, far below real-world pricing patterns.
- Aircraft model did not predict capacity.
- Cancelled flights still held ticket revenue in 274 bookings and 358 tickets.
- Employee department and job title were statistically independent.

## Modeling assumptions

Because the source tables do not include cost or profit fields, I derived them using documented assumptions:
- Block time = distance_km / 780 + 0.5 hours.
- Narrow-body operating cost = $4,733 per block hour.
- Wide-body operating cost = $10,351 per block hour.
- Maintenance is allocated by aircraft usage, not evenly per flight.
- Cancelled-flight revenue is treated as fully refunded.
- Aircraft size classification uses capacity, not model.

## Star schema

The model uses a ticket-grain fact table and a separate flight-grain fact table.

- `fact_tickets` stores one row per ticket.
- `fact_flight_operations` stores one row per flight.
- Dimensions support date, aircraft, route, customer, and flight analysis.

This split keeps flight-level cost logic from being repeated across every ticket on the same flight.

## Flagship insights

The six main insights are:
1. Route profitability.
2. Load factor by aircraft class.
3. On-time performance by aircraft age.
4. Fare-class price compression.
5. Customer value by loyalty tier.
6. Department cost structure.

Insight 3 acts as a control: it behaves like a real-world airline metric and shows the methodology is not simply detecting problems everywhere. 
The other insights point to the same root cause: the synthetic data was generated with weak correlation between operational and financial fields.

## Two corrections I kept

I left two mistakes in the documentation because they show how the analysis was validated:
- A false oversold-flight finding caused by comparing INTEGER values to TEXT values lexicographically.
- A `DECIMAL(5,4)` overflow during load factor calculation because the precision was too small for ticket counts.

Both were corrected by rerunning the analysis with explicit types and safer casts.

## How to run

1. Run `sql/01_data_quality_audit.sql` against the raw tables.
2. Run `sql/02_star_schema_build.sql` to build the dimensional model.
3. Run `sql/03_fact_flight_operations.sql` to build the flight-grain fact table.
4. Run `sql/04_flagship_insights.sql` for the six summary queries.

## Lessons learned

This project shows the value of validating assumptions before trusting results. It also shows why dimensional modeling matters:
a good schema makes business patterns easier to see, and a bad schema can hide them.

## Notes

- Written and tested in T-SQL for SQL Server.
- Dialect notes for SQLite, PostgreSQL, and MySQL are included in comments where syntax differs.
