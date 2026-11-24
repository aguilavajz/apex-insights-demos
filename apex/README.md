# apex

## Overview
Oracle APEX Application `231200` (`APEX Insights Demos`, alias `APEX-INSIGHTS-DEMOS`) SQL export (`f231200.sql`) plus the binary export archive `apex-insights-demos.zip` (and `.gitkeep`). Consolidates the UI pages, shared components, LOVs, and server-side processes for multiple APEX Insights demos in Universal Theme (`42`).

## Interface
- `[f231200.sql:wwv_flow_imp.import_begin]` / `[f231200.sql:wwv_imp_workspace.create_flow]` — Application `231200` (`APEX Insights Demos`), owner `WKSP_APEXINSIGHTSDEMO`, APEX release `26.1.0`, compatibility mode `24.2`, Theme `42` (`UNIVERSAL_THEME`), PWA enabled (`p_is_pwa='Y'`), authentication `'Oracle APEX Accounts'` (`134022680870755176129`), authorization `'Administration Rights'` (`134022686408238176139`).
- `[f231200.sql:134022681656550176130]` / `[f231200.sql:154818321780246098986]` — Navigation lists `'Navigation Menu'` and `'New Invoice'` (3-step wizard list) plus `'Navigation Bar'` (`134022682846304176133`) and `'Breadcrumb'` (`134022681164086176129`).
- `[f231200.sql:163547517684780769151]` / `[f231200.sql:163547188164738759536]` / `[f231200.sql:163547318867860129122]` — SQL LOVs `OWNER`, `PERIOD`, and `REGION` querying `demo_opportunities`.
- `[f231200.sql:137138629497584266701]` — On-demand API automation `'Demo_Heavy_Process'` (`static_id='demo-async'`, `trigger_type='API'`, `polling_status='DISABLED'`).
- Pages:
  - `[f231200.sql:page_0]` / `[f231200.sql:page_1]` — Page `0` (`Global Page`) and Page `1` (`Home`, `HOME`).
  - `[f231200.sql:page_2]` / `[f231200.sql:page_4]` — `IR Performance - Naive` (`NAIVE`) and `IR Performance - Optimized` (`IR-PERFORMANCE-OPTIMIZED`), querying `IR_PERF_TEST` (`WHERE get_slow_value(id) > -1`).
  - `[f231200.sql:page_3]` — `Automation Control` (`AUTOMATION-CONTROL`), displaying `DEMO_JOB_LOG` (`LOG_REGION`) with a 3000 ms refresh loop and `Trigger Automation` button (`START_PROCESS`).
  - `[f231200.sql:page_5]` / `[f231200.sql:page_00007]` / `[f231200.sql:page_00008]` / `[f231200.sql:page_00009]` — Enterprise UX Patterns pages: Page `5` (`Invoice Management`: `INVOICE_GRID` IG + `DETAIL_DRAWER` + `INVOICE_ACTIONS` on `demo_invoices`) and Pages `7`–`9` (`New Invoice` 3-step wizard: Client Info -> Amount -> Confirm & `Insert New Invoice`). See [../2026-03-24-enterprise-ux-patterns/scripts/README.md](../2026-03-24-enterprise-ux-patterns/scripts/README.md).
  - `[f231200.sql:page_00006]` / `[f231200.sql:page_00010]` — `Sales Operation Dashboard` (`SALES-OPERATION-DASHBOARD`) and `Deal Details` (`DEAL-DETAILS`), rendering 3 KPI cards, 2 JET charts (`Pipeline by Stage`, `Revenue Trend`), and drilldown IR on `demo_opportunities`. See [../2026-05-11-dashboard-design/scripts/README.md](../2026-05-11-dashboard-design/scripts/README.md).
  - `[f231200.sql:p_id=>11]` / `[f231200.sql:p_id=>12]` — `Dashboard Demo` (`DASHBOARD-DEMO`) and `Oportunity Details` (`OPORTUNITY-DETAILS`), querying `demo_opportunities` and `demo_kpi_thresholds` (`kpi_name = 'AT_RISK_COUNT'`), with automatic item-change DA `Update Dashboard when Filtering`.
  - `[f231200.sql:p_id=>9999]` — Public `Login Page` (`LOGIN`) using `APEX_AUTHENTICATION`.
- Binary artifact: `apex-insights-demos.zip` (packaged APEX export archive; binary contents not unpacked).

## Invariants
- `[f231200.sql:wwv_imp_workspace.create_flow]` — Enforces `p_page_protection_enabled_y_n='Y'`, `p_bookmark_checksum_function='SH512'`, `p_exact_substitutions_only='Y'`, `p_rejoin_existing_sessions='N'`, and checksum `p_protection_level='C'` across Pages `1`–`12` and `9999` (`page_0` uses `'D'`; only `9999` is public).
- `[f231200.sql:whenever_sqlerror]` — Sets `whenever sqlerror exit sql.sqlcode rollback` and `set define off verify off feedback off` during import.
- `[f231200.sql:154801463780073427112]` — Page `5` `Selection Change` DA requires a non-empty selected row `id` and enforces status-gated action bar visibility: `DRAFT` -> `#BTN_SUBMIT`; `PENDING` -> `#BTN_APPROVE`, `#BTN_REJECT`; otherwise all three stay hidden (`u-hidden`).
- `[f231200.sql:154801466198953427136]` — Page `9` `Insert New Invoice` strips non-numeric characters via `REGEXP_REPLACE` before `TO_NUMBER(:P9_CONFIRM_AMOUNT)` and parses `:P9_CONFIRM_DUE_DATE` with `'DD/MM/YYYY'`; `PREVIOUS` buttons on Pages `8`/`9` skip validation (`execute_validations='N'`) and branch at `BEFORE_VALIDATION`.
- `[f231200.sql:163547782918979140608]` — Page `6` `'Won This Period'` card submits `P6_PERIOD,P6_REGION,P6_OWNER` via AJAX while its SQL query references `:P1_PERIOD` and `:P1_REGION`.
- `[f231200.sql:2771385829448343203]` — Page `11` `'Pipeline by Stage'` JET chart filters `stage != 'Lost'`, declares `ajax_items_to_submit='P11_REGION, P11_OWNER, P11_PERIOD'`, and references `:P11PERIOD` in SQL; Page `11` `KPI` card cross-joins `demo_kpi_thresholds` (`kpi_name = 'AT_RISK_COUNT'`).
- `[f231200.sql:134022686408238176139]` — Demo authorization `'Administration Rights'` unconditionally evaluates `return true;` (`BY_USER_BY_PAGE_VIEW`), and `'Oracle APEX Accounts'` uses `use_secure_cookie_yn='N'`.

## Side Effects
- `[f231200.sql:wwv_flow_imp.remove_flow]` / `[f231200.sql:wwv_flow_imp.import_end]` — Removes any existing application matching `wwv_flow.g_flow_id` (`231200`), recreates the application, loads 5 PNG static files as DB BLOBs, and commits (`commit;`).
- `[f231200.sql:137138629733656266704]` — Page `3` `Trigger Automation` invokes `apex_automation.execute(p_static_id => 'demo-async')`, which sleeps (`dbms_session.sleep(10)`) and inserts `('Async Task Triggered', 'SUCCESS', localtimestamp)` into `demo_job_log`.
- `[f231200.sql:154801466822607427143]` / `[f231200.sql:154801466198953427136]` — Page `5` processes (`Submit`, `Approve`, `Reject`) `UPDATE demo_invoices` (`PENDING`/`APPROVED`/`DRAFT`), and Page `9` `Insert New Invoice` inserts new rows into `demo_invoices`.
- `[f231200.sql:163547784609952140625]` / `[f231200.sql:2771385829448343203]` — Page `6` and Page `11` bar charts redirect to drilldown Pages `10` (`P10_STAGE`, `P10_REGION`) and `12` (`P12_STAGE`), and both IRs enable CSV/HTML/XLSX/PDF and email downloads.
- `[f231200.sql:134022689314313176145]` — Page `9999` reads/sets the login username cookie and creates an authenticated APEX session via `APEX_AUTHENTICATION.LOGIN`.

## Verification
- Run: Create prerequisite demo database objects first (e.g., `demo_invoices`, `demo_opportunities`, `demo_kpi_thresholds`, plus `IR_PERF_TEST`/`get_slow_value` and `DEMO_JOB_LOG` if using Pages 2–4), then import `f231200.sql` via Oracle APEX **Application Builder -> Import** or SQLcl (`@f231200.sql`) into a parsing schema containing those objects.
