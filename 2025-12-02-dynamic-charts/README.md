# Dynamic Charts and Data Visualization in Oracle APEX

## Overview
This folder contains the source code and examples for the **APEX Insights** article:
*   🇺🇸 [Dynamic Charts and Data Visualization in Oracle APEX](https://insightsapex.hashnode.dev/dynamic-charts-data-visualization-oracle-apex)
*   🇪🇸 [Gráficos Dinámicos y Visualización de Datos en Oracle APEX](https://insightsapex.hashnode.dev/graficos-dinamicos-visualizacion-datos-oracle-apex)

The demo pairs Oracle schema DDL and an `APEX_EXEC` / `APEX_JSON` AJAX callback (`GET_SALES_DATA`) in `database/` with a Dynamic Action JavaScript caller in `apex/`.

## Subdirectories & Boundaries
- `apex`: [apex/README.md](./apex/README.md) — Client-side Dynamic Action JavaScript (`chart_refresh.js`) calling `apex.server.process("GET_SALES_DATA", ...)` with `P10_YEAR` and `P10_REGION`.
- `database`: [database/README.md](./database/README.md) — Schema DDL (`regions`, `orders`), sample-data generator (`02_sample_data.sql`), and the `GET_SALES_DATA` AJAX Callback anonymous PL/SQL block (`03_packages.sql`); `test_get_sales_data.sql` is an excluded test/diagnostic script.

## Contents

*   **`database/`**: SQL scripts to create the schema, sample data, and PL/SQL AJAX callback logic.
    *   `01_schema.sql`: Creates `regions` and `orders` tables with indexes `idx_orders_date` and `idx_orders_region`.
    *   `02_sample_data.sql`: Inserts 4 sample regions and 1,000 generated `orders` rows for testing.
    *   `03_packages.sql`: Contains the anonymous PL/SQL `GET_SALES_DATA` AJAX Callback logic for the advanced demo.
*   **`apex/`**: JavaScript code used in the APEX page.
    *   `chart_refresh.js`: The AJAX call using `apex.server.process`.

## How to Use

1.  Run `01_schema.sql` and `02_sample_data.sql` in `database/` in your Oracle APEX SQL Workshop or via SQLcl.
2.  Create a new APEX Page with `P10_YEAR` and `P10_REGION` items and an AJAX Callback process (`GET_SALES_DATA`) using `database/03_packages.sql`.
3.  Follow the instructions in the blog post to configure the JET Chart region.
4.  Use the JavaScript code in `apex/chart_refresh.js` for the Dynamic Action.
