# scripts

## Overview
Database DDL and deterministic seed scripts for the Dashboard Design Oracle APEX demo (`2026-05-11-dashboard-design`), creating `demo_opportunities` and `demo_kpi_thresholds` and populating 240 sales opportunity records across 12 months.

## Interface
- `[01_tables.sql:demo_opportunities]` — Table (`opportunity_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY`, `owner_name VARCHAR2(100) NOT NULL`, `region VARCHAR2(50) NOT NULL`, `stage VARCHAR2(30) NOT NULL`, `amount NUMBER(12,2) NOT NULL`, `close_date DATE NOT NULL`, `created_at DATE DEFAULT SYSDATE NOT NULL`).
- `[01_tables.sql:chk_opp_stage]` — Check constraint restricting `demo_opportunities.stage` to `('Prospecting','Qualification','Proposal','Negotiation','Won','Lost','At Risk')`.
- `[01_tables.sql:idx_opp_region]` / `[01_tables.sql:idx_opp_owner]` / `[01_tables.sql:idx_opp_close_date]` / `[01_tables.sql:idx_opp_stage]` — Indexes on `demo_opportunities` (`region`, `owner_name`, `close_date`, `stage`).
- `[01_tables.sql:demo_kpi_thresholds]` — Table (`kpi_name VARCHAR2(50) NOT NULL PRIMARY KEY`, `warn_threshold NUMBER NOT NULL`, `danger_threshold NUMBER NOT NULL`, `description VARCHAR2(200)`).
- `[02_data.sql:SELECT]` — Verification query returning `stage`, `record_count`, `total_value`, `earliest`, and `latest` grouped by `stage` from `demo_opportunities`.

## Invariants
- `[01_tables.sql:WHEN OTHERS THEN NULL]` — Pre-create `DROP TABLE ... PURGE` blocks swallow all exceptions via `WHEN OTHERS THEN NULL` so re-runs stay idempotent.
- `[01_tables.sql:demo_opportunities]` — `opportunity_id` is `GENERATED ALWAYS AS IDENTITY PRIMARY KEY`; `created_at` defaults to `SYSDATE`; `amount` has precision `NUMBER(12,2)`.
- `[02_data.sql:month_offset]` / `[02_data.sql:day_offset]` — Nested loops (`0..11` × `0..19`) deterministically seed 240 rows without `DBMS_RANDOM` across 5 owners (`l_owners`), 5 regions (`l_regions`: `'NORTH'`, `'SOUTH'`, `'EAST'`, `'WEST'`, `'CENTRAL'`), and 8 weighted stage entries (`3x 'Won'`, `'Lost'`, `'At Risk'`, `'Negotiation'`, `'Proposal'`, `'Qualification'`).
- `[02_data.sql:l_amount]` / `[02_data.sql:l_close_date]` — Amounts are deterministic multiples of 100 in `[5000, 250000]` and `close_date` spans 12 months back from `TRUNC(SYSDATE, 'MM')`.
- `[02_data.sql:INSERT INTO demo_opportunities]` — Populates `demo_opportunities` only; `demo_kpi_thresholds` receives no seed rows in `02_data.sql`.

## Side Effects
- `[01_tables.sql:DROP TABLE demo_opportunities PURGE]` / `[01_tables.sql:DROP TABLE demo_kpi_thresholds PURGE]` — Destructively drops and purges existing `demo_opportunities` and `demo_kpi_thresholds` tables if present, then recreates both tables, constraints, and four indexes.
- `[02_data.sql:INSERT INTO demo_opportunities]` / `[02_data.sql:COMMIT]` — Inserts 240 rows into `demo_opportunities`, commits, emits `'Inserted 240 opportunity records.'` to `DBMS_OUTPUT`, and runs a summary `SELECT` query.

## Verification
- Run: `sql <username>/<password>@<connection_string> @01_tables.sql` and `@02_data.sql` in SQLcl (or run sequentially in Oracle APEX SQL Workshop).
