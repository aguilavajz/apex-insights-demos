# EGM Drift Report — 2026-11-24

Drift check across all 13 generated/updated EGM `README.md` contract files against the local source tree.

## README.md

- **Non-Code Asset Excluded from Index**: `src/css/main.css` exists in the repository tree and is intentionally excluded per EGM non-code pruning rules (not referenced under `Subdirectories & System Boundaries`).

## 2025-12-02-dynamic-charts/README.md

- **Incomplete Client UI Update (`apex/chart_refresh.js`)**: Documentation instructs using `apex/chart_refresh.js` for the Dynamic Action to update the JET Chart, while `chart_refresh.js` (lines 12–20) maps `pData.data` into `mapped` and leaves the UI update (`// Use the mapped data to update the UI (e.g., apex.region("ID").setData(mapped))`) commented out as a stub.

## 2025-12-02-dynamic-charts/apex/README.md

- **Stubbed `success` Callback (`chart_refresh.js`)**: `chart_refresh.js` computes `mapped` inside `success` (lines 14–17) without invoking any DOM/chart update API (line 19 is a comment stub).

## 2025-12-02-dynamic-charts/database/README.md

No drift detected.

## 2026-01-27-automated-testing-utplsql/README.md

No drift detected.

## 2026-01-27-automated-testing-utplsql/scripts/README.md

No drift detected.

## 2026-01-27-automated-testing-utplsql/src/README.md

No drift detected.

## 2026-03-24-enterprise-ux-patterns/README.md

No drift detected.

## 2026-03-24-enterprise-ux-patterns/scripts/README.md

No drift detected.

## 2026-05-11-dashboard-design/README.md

- **Unbound `P6_PERIOD` on Page 6 KPI Cards (`apex/f231200.sql`)**: Docs state Page 6's Filter Bar includes Period (`P6_PERIOD`), Region (`P6_REGION`), and Owner (`P6_OWNER`), and `'At-Risk Deals'` (line 2869) and `'Open Pipeline Value'` (line 2954) declare `p_ajax_items_to_submit => 'P6_PERIOD,P6_REGION,P6_OWNER'`, but both SQL queries (lines 2864–2866 and 2948–2950) filter only by `:P6_REGION` and `:P6_OWNER` and ignore `:P6_PERIOD`.
- **Stale Page 1 Bind Variables in Page 6 `'Won This Period'` (`apex/f231200.sql`)**: `'Won This Period'` declares `p_ajax_items_to_submit => 'P6_PERIOD,P6_REGION,P6_OWNER'` (line 3230), but its SQL `WHERE` clause (lines 3225–3226) references `:P1_PERIOD` and `:P1_REGION` instead of `:P6_PERIOD`, `:P6_REGION`, and `:P6_OWNER`.
- **Bind Typo in Page 11 `'Pipeline by Stage'` (`apex/f231200.sql`)**: Series SQL on line 4556 references `:P11PERIOD` (missing underscore) while `p_ajax_items_to_submit` on line 4559 submits `P11_REGION, P11_OWNER, P11_PERIOD`.
- **Unseeded `demo_kpi_thresholds` Table (`scripts/02_data.sql` vs. Page 11 KPI)**: Page 11's `KPI` region cross-joins `demo_kpi_thresholds WHERE kpi_name = 'AT_RISK_COUNT'` (`apex/f231200.sql`, lines 4455–4456), while `scripts/02_data.sql` only seeds `demo_opportunities` (leaving `demo_kpi_thresholds` empty after `01_tables.sql` drops and recreates it).
- **Drilldown Endpoint Scope (`Key Patterns Demonstrated`)**: The pattern table summarizes drilldown as `Bar chart -> IR -> Detail page`, whereas Page 10 (`Deal Details`) and Page 12 (`Oportunity Details`) in `apex/f231200.sql` terminate at filtered Interactive Reports without a separate detail modal/form page.

## 2026-05-11-dashboard-design/scripts/README.md

No drift detected.

## 2026-06-09-ords-professional-patterns/README.md

- **Unused Constant & Simulated Data Sources (`ords_handler_template.sql`)**: `pkg_ords_handler_template.c_err_not_found` (line 80) is declared in the package specification without any reference in the package body; `get_collection`, `get_resource`, and `post_resource` select from `DUAL` or return a hardcoded `'id' VALUE 1001` (template placeholder behavior); and the ORDS module/handler registration block (lines 296–491) is commented out (`/* ... */`).

## apex/README.md

- **Uncovered Shared Metadata (`f231200.sql`)**: `f231200.sql` also declares 4 Page Groups (`Administration`, `Automation Demo`, `Enterprise UX Patterns Demo`, `Performance Demo`, lines 1095–1117), 1 excluded Build Option (`'Commented Out'`, lines 1326–1339), and 14 `NATIVE_*` plugin settings (lines 137–313) not individually enumerated in `apex/README.md`.
- **Citation Identifier Style (`page_0`..`page_5`)**: `apex/README.md` cites Pages 0–5 using `[f231200.sql:page_0]`..`[f231200.sql:page_5]`, whereas the file section prompt comments use `page_00000`..`page_00005` (`p_id=>0`..`p_id=>5`).
