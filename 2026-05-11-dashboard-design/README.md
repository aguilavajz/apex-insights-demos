# Dashboard Design Demo

This demo accompanies the APEX Insights article:
**"Dashboard Design in Oracle APEX: Best Practices for Data Viz"**.

## Overview

A single-page Oracle APEX application that demonstrates the 10 dashboard design
principles from the article using a realistic sales operations scenario.

### What the Demo Includes

1. **Filter Bar** — Period, Region, and Owner. Each filter drives only the
   regions that depend on it (no full-page refresh).
2. **KPI Row (3 cards)** — At-Risk Deals, Won This Period, Open Pipeline Value.
   Each KPI is color-coded via SQL using Universal Theme semantic classes
   (`u-success`, `u-warning`, `u-danger`).
3. **Revenue Trend (Line Chart)** — Monthly won revenue for the last 12 months.
   Region Caching is enabled with a 300-second timeout per user.
4. **Pipeline by Stage (Bar Chart)** — Horizontal bar for open deals, sorted by
   value descending. Click any bar to drilldown into a filtered Interactive Report.
5. **Detail Report (Page 2)** — Filtered Interactive Report with semantic row
   highlighting based on stage.

## Installation

### Prerequisites

- Oracle APEX 24.2 or later.
- A schema with `CREATE TABLE`, `CREATE INDEX`, and `INSERT` privileges.
- Access to Oracle APEX Application Builder.

### 1. Database Objects

Run the scripts in order via SQL Workshop → SQL Commands, or via SQLcl:

```bash
# Option A: SQL Workshop (paste each file)

# Option B: SQLcl
sql username/password@connection_string @scripts/01_tables.sql
sql username/password@connection_string @scripts/02_data.sql
```

| Script | Purpose |
|---|---|
| `01_tables.sql` | Creates `demo_opportunities` and `demo_kpi_thresholds` tables with indexes |
| `02_data.sql` | Inserts 240 realistic opportunity records across 12 months + KPI thresholds |

### 2. APEX Application

Import the application export from the `apex/` folder:

1. Navigate to **Application Builder → Import**.
2. Select the file `apex/f_dashboard_demo.sql`.
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
| Controlled Filters | 3 items max; each chart declares its own Page Items to Submit |
| Drilldown Pattern | Bar chart → IR → Detail page |
| Performance | Region Cache on trend chart; set-based SQL only |

## Feedback

If you find an issue or want to suggest an improvement, open an issue in this
repository.

---

*Brought to you by **APEX Insights** — Architecture over Page Building.*
