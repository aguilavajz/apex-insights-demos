# Dashboard Design Demo

This demo accompanies the APEX Insights article:
**"Dashboard Design in Oracle APEX: Best Practices for Data Viz"**.

## Overview

An Oracle APEX dashboard flow (Page 6 with Page 10 drilldown, plus Dashboard Demo on Page 11 with Page 12 drilldown in `../apex/f231200.sql`) that demonstrates dashboard design principles using a sales operations scenario backed by `demo_opportunities` and `demo_kpi_thresholds`.

### What the Demo Includes

1. **Filter Bar** — Period (`P6_PERIOD`), Region (`P6_REGION`), and Owner (`P6_OWNER`), refreshed via the `Apply` button's Dynamic Actions on Page 6 (and item-change Dynamic Action on Page 11 for `P11_REGION`, `P11_OWNER`, `P11_PERIOD`).
2. **KPI Row (3 cards)** — At-Risk Deals, Won This Period, Open Pipeline Value (`u-success`, `u-warning`, `u-danger`, `u-info` Universal Theme semantic classes; Page 11 cross-joins `demo_kpi_thresholds` for `'AT_RISK_COUNT'`).
3. **Revenue Trend (Line Chart)** — Monthly won revenue for the last 12 months.
4. **Pipeline by Stage (Bar Chart)** — Vertical bar on Page 6 (horizontal bar on Page 11) for pipeline stages, clicking a bar to drill down into a filtered Interactive Report.
5. **Detail Report (Page 10 / Page 12)** — Filtered Interactive Report (`demo_opportunities`) with semantic row highlighting on Page 10 (`semantic_class`).

## Subdirectories & Boundaries
- `scripts`: [scripts/README.md](./scripts/README.md) — Idempotent DDL (`01_tables.sql`) creating `demo_opportunities` and `demo_kpi_thresholds` with 4 indexes, plus deterministic PL/SQL seed script (`02_data.sql`) inserting 240 `demo_opportunities` rows across 12 months.
- Root APEX Export: [../apex/README.md](../apex/README.md) — Houses `f231200.sql` containing Pages `6`, `10`, `11`, and `12`.

## Installation

### Prerequisites

- Oracle APEX 24.2 or later.
- A schema with `CREATE TABLE`, `CREATE INDEX`, and `INSERT` privileges.
- Access to Oracle APEX Application Builder.

### 1. Database Objects

Run the scripts in order via SQL Workshop -> SQL Commands, or via SQLcl:

```bash
# Option A: SQL Workshop (paste each file)

# Option B: SQLcl
sql username/password@connection_string @scripts/01_tables.sql
sql username/password@connection_string @scripts/02_data.sql
```

| Script | Purpose |
|---|---|
| `01_tables.sql` | Drops/recreates `demo_opportunities` and `demo_kpi_thresholds` tables with `chk_opp_stage` and 4 indexes |
| `02_data.sql` | Deterministically inserts 240 opportunity records across 12 months (`demo_kpi_thresholds` is not seeded by this script) |

### 2. APEX Application

Import the application export from the root-level [`../apex/`](../apex/README.md) folder:

1. Navigate to **Application Builder -> Import**.
2. Select the file `../apex/f231200.sql`.
3. Accept the defaults and click **Install Application**.
4. Run the app and verify data appears in the KPI row.

> **Note:** The app uses `demo_opportunities` and `demo_kpi_thresholds`. Both
> tables must exist in the same schema as the APEX workspace parsing schema.

## Key Patterns Demonstrated

| Principle | Implementation |
|---|---|
| Dashboard Contract | Single audience, single question: "What needs attention?" |
| KPI Semantic Color | SQL CASE returns UT class; APEX applies it as CSS |
| Chart by Question | Line for trend, Bar for comparison, IR for exceptions |
| SQL for Visualization | Aggregated queries, no raw rows sent to charts |
| Controlled Filters | 3 items max; each chart/card declares its own Page Items to Submit |
| Drilldown Pattern | Bar chart -> IR -> Detail page |
| Performance | Set-based SQL with targeted page item submission |

## Feedback

If you find an issue or want to suggest an improvement, open an issue in this repository.

---

*Brought to you by **APEX Insights** — Architecture over Page Building.*
