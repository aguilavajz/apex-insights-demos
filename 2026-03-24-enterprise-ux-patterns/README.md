# Enterprise UX Patterns Demo

This demo accompanies the APEX Insights article: **"Enterprise UX Patterns: Designing Internal Apps for High Productivity"**.

## Overview

This repository contains the database objects and architectural patterns required to implement a high-productivity internal application in Oracle APEX 24.2.

### Patterns Included

1. **Master-Detail-Drawer**: Using an Interactive Grid (Master) paired with an Inline Dialog (Right Drawer) to preserve context.
2. **Adaptive Action Bars**: Context-aware buttons that change visibility based on the record's state (`DRAFT`, `PENDING`, `APPROVED`).
3. **Guided Steppers**: A 3-step Wizard flow for complex data entry.

## Installation

### 1. Database Objects

Run the scripts in the `scripts/` folder via SQL Workshop or SQLcl:

- `01_tables.sql`: Creates the `demo_invoices` table.
- `02_data.sql`: Populates the table with test records.

### 2. APEX Application

Import the latest application export found in the root-level `apex/` folder of this repository.

## Feedback

If you have any questions or find an issue with the implementation, please open an issue in this repository.

---
*Brought to you by **APEX Insights** — Architecture over Page Building.*
