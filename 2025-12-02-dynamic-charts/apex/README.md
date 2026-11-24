# apex

## Overview
Client-side Oracle APEX Dynamic Action JavaScript script for the Dynamic Charts and Data Visualization demo (`2025-12-02-dynamic-charts`), fetching aggregated sales series asynchronously and mapping the response payload for chart rendering.

## Interface
- `[chart_refresh.js:apex.server.process]` — Top-level AJAX invocation targeting the `"GET_SALES_DATA"` APEX server process with parameters `x01` (`$v('P10_YEAR')`), `x02` (`$v('P10_REGION')`), and `pageItems: ["P10_YEAR", "P10_REGION"]`.
- `[chart_refresh.js:success]` — Callback transforming `pData.data` array items into `{ period: r.period, total: r.total_sales }` objects (`mapped`) for downstream UI/chart update.
- `[chart_refresh.js:error]` — Callback handling failed AJAX calls via APEX client-side messaging.

## Invariants
- `[chart_refresh.js:apex.server.process]` — Expects an APEX AJAX Callback process named `"GET_SALES_DATA"`, page items `P10_YEAR` and `P10_REGION` in the DOM, and a JSON response containing a `data` array whose objects expose `period` and `total_sales` properties.

## Side Effects
- `[chart_refresh.js:apex.server.process]` — Reads DOM values `$v('P10_YEAR')` and `$v('P10_REGION')` and issues an asynchronous HTTP request to the APEX `"GET_SALES_DATA"` callback.
- `[chart_refresh.js:apex.message.clearErrors]` / `[chart_refresh.js:apex.message.showErrors]` — On AJAX failure, clears existing page errors and displays `{ type: "error", message: "An error occurred while retrieving sales data.", location: ["page"] }`.

## Verification
- Run: Configure the script inside an Oracle APEX Dynamic Action (`Execute JavaScript Code`) on a page containing `P10_YEAR`, `P10_REGION`, and a `"GET_SALES_DATA"` AJAX Callback (`../database/03_packages.sql`), then trigger the action in the browser.
