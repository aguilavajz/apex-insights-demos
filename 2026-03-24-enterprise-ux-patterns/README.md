# Enterprise UX Patterns Demo

This demo accompanies the APEX Insights article: **"Enterprise UX Patterns: Designing Internal Apps for High Productivity"**.

## Overview

This directory and its corresponding pages in Application `231200` (`../apex/f231200.sql`) provide the database objects and architectural patterns required to implement a high-productivity internal application in Oracle APEX 24.2+.

### Patterns Included

1. **Master-Detail-Drawer** (Page 5): Using an Interactive Grid (`INVOICE_GRID` on `demo_invoices`) paired with an Inline Dialog (`DETAIL_DRAWER` / `INVOICE_DETAIL`) to preserve context.
2. **Adaptive Action Bars** (Page 5): Context-aware buttons (`#BTN_SUBMIT`, `#BTN_APPROVE`, `#BTN_REJECT`) that toggle visibility based on the selected record's `status` (`DRAFT`, `PENDING`, `APPROVED`).
3. **Guided Steppers** (Pages 7–9): A 3-step Wizard flow (`Client Info` -> `Amount` -> `Confirm`) for multi-step invoice creation (`Insert New Invoice`).

## Subdirectories & Boundaries
- `scripts`: [scripts/README.md](./scripts/README.md) — DDL (`01_tables.sql`) creating `demo_invoices` (identity PK, `status` check constraint `'DRAFT'`/`'PENDING'`/`'APPROVED'`) and seed data (`02_data.sql`) inserting 3 sample invoices.
- Root APEX Export: [../apex/README.md](../apex/README.md) — Houses `f231200.sql` containing Page `5` (`Invoice Management`) and Pages `7`–`9` (`New Invoice` wizard).

## Installation

### 1. Database Objects

Run the scripts in the `scripts/` folder via SQL Workshop or SQLcl:

- `01_tables.sql`: Creates the `demo_invoices` table.
- `02_data.sql`: Populates the table with 3 test records (`Acme Corp`, `Global Tech`, `Innova S.A.`).

### 2. APEX Application

Import the latest application export found in the root-level [`../apex/`](../apex/README.md) folder of this repository (`../apex/f231200.sql`).

## Feedback

If you have any questions or find an issue with the implementation, please open an issue in this repository.

---
*Brought to you by **APEX Insights** — Architecture over Page Building.*
