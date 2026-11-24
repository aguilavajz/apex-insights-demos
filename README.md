# apex-insights-demos Blueprint

Official code repository for the **APEX Insights** blog series ([insigthsapex.vinnyum.tech](https://insigthsapex.vinnyum.tech)), with editorial and product documentation anchored in the Vinnyum Obsidian SOT (`01_vinnyum/contenido` / `01_vinnyum/productos/vinnyum-tools`).

![License](https://img.shields.io/badge/License-MIT-blue.svg)
![Oracle APEX](https://img.shields.io/badge/Oracle%20APEX-24.2-orange)
![Contributions](https://img.shields.io/badge/Contributions-Welcome-brightgreen)

## System Overview
`apex-insights-demos` hosts standalone Oracle Database, PL/SQL, ORDS, and Oracle APEX proof-of-concept demos accompanying APEX Insights technical articles. Database scripts and PL/SQL packages live in dated topic directories (`2025-*`, `2026-*`), while the shared Oracle APEX Application `231200` (`APEX Insights Demos`) import script is maintained in [`./apex/`](./apex/README.md).

## Subdirectories & System Boundaries
- `2025-12-02-dynamic-charts`: [./2025-12-02-dynamic-charts/README.md](./2025-12-02-dynamic-charts/README.md) — Oracle schema (`regions`, `orders`), 1,000-row sample generator, `GET_SALES_DATA` `APEX_EXEC`/`APEX_JSON` AJAX callback (`03_packages.sql`), and Dynamic Action caller (`chart_refresh.js`).
- `2026-01-27-automated-testing-utplsql`: [./2026-01-27-automated-testing-utplsql/README.md](./2026-01-27-automated-testing-utplsql/README.md) — PL/SQL package `pkg_orders` (`calculate_total`, `c_standard_discount`), SQL*Plus/SQLcl install & run scripts (`install.sql`, `run_tests.sql`), and the 4-test `ut_pkg_orders` utPLSQL suite.
- `2026-03-24-enterprise-ux-patterns`: [./2026-03-24-enterprise-ux-patterns/README.md](./2026-03-24-enterprise-ux-patterns/README.md) — `demo_invoices` table and sample rows backing Master-Detail-Drawer, Adaptive Action Bars (Page `5`), and Guided Steppers (Pages `7`–`9`) in App `231200`.
- `2026-05-11-dashboard-design`: [./2026-05-11-dashboard-design/README.md](./2026-05-11-dashboard-design/README.md) — `demo_opportunities` and `demo_kpi_thresholds` DDL plus 240 deterministic rows backing Sales Operation Dashboard (Pages `6`/`10`) and Dashboard Demo (Pages `11`/`12`) in App `231200`.
- `2026-06-09-ords-professional-patterns`: [./2026-06-09-ords-professional-patterns/README.md](./2026-06-09-ords-professional-patterns/README.md) — ORDS REST handler template (`ords_handler_template.sql`) with `api_error_log`, `api_rate_log`, `check_rate_limit`, `pkg_ords_handler_template`, and commented `'resources.v1'` module registration.
- `apex`: [./apex/README.md](./apex/README.md) — Shared Oracle APEX export (`f231200.sql`, App `231200` `APEX Insights Demos`, Pages `0`–`12` and `9999`, plus `apex-insights-demos.zip`).

## Global Invariants
- **Schema & Parsing Scope**: Each demo assumes its DDL/PL/SQL scripts (`regions`/`orders`, `pkg_orders`, `demo_invoices`, `demo_opportunities`/`demo_kpi_thresholds`, `api_error_log`/`api_rate_log`) are installed in the Oracle parsing schema used by APEX or ORDS before importing or running the corresponding UI/REST demo.
- **Explicit Protection & Validation**: Pages `1`–`12` and `9999` in `apex/f231200.sql` enforce checksum page protection (`p_protection_level='C'`) and session state protection; `pkg_orders.calculate_total` enforces non-negative `p_amount` (`-20001`); `pkg_ords_handler_template` sanitizes/validates inputs and masks internal `SQLERRM` behind `SYS_GUID()` references.
- **Documentation & Branch Conventions**: Default development branch is `develop` (PRs target `develop`); PL/SQL parameters/variables/constants follow `p_`, `l_`, `c_` prefixes (see [Copilot Instructions](.github/copilot-instructions.md)).

## Global Side Effects
- **DDL / Seed Mutations**: Demo setup scripts create tables, indexes, constraints, PL/SQL packages/procedures, and seed sample rows (with `2026-05-11-dashboard-design/scripts/01_tables.sql` dropping/purging prior `demo_opportunities` and `demo_kpi_thresholds` tables, and `apex/f231200.sql` calling `wwv_flow_imp.remove_flow` before re-importing App `231200`).
- **Runtime DML & Session State**: APEX App `231200` and ORDS handlers mutate `demo_invoices`, `demo_job_log`, `api_rate_log`, `api_error_log`, and APEX session/cookie state on user actions.

## System Verification
- **utPLSQL Demo (`2026-01-27-automated-testing-utplsql`)**: From `2026-01-27-automated-testing-utplsql/scripts/`, run `@install.sql` then `@run_tests.sql` in SQLcl or SQL*Plus against a schema with utPLSQL v3.1.13+.
- **SQL / ORDS / APEX Demos**: Execute each demo's `scripts/` or `database/` SQL files via SQLcl or Oracle APEX SQL Workshop, then import [`./apex/f231200.sql`](./apex/f231200.sql) via **Application Builder -> Import** to verify interactive pages.

## 🤝 Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for instructions on how to add new demos, and please follow our standards:

- **Issues**: Use our [Issue Templates](.github/ISSUE_TEMPLATE/) for Bugs, Features, and Chores.
- **AI Coding**: If using GitHub Copilot, please respect the [Copilot Instructions](.github/copilot-instructions.md) in this repo.
- **Labels**: We use a standardized label system (e.g., `type: bug`, `priority: high`).
- **Branching**: Default branch is `develop`. Please branch off `develop` and submit PRs to it.
