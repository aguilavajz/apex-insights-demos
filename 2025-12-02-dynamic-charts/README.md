# Dynamic Charts and Data Visualization in Oracle APEX

This folder contains the source code and examples for the **APEX Insights** article:
*   🇺🇸 [Dynamic Charts and Data Visualization in Oracle APEX](https://insightsapex.hashnode.dev/dynamic-charts-data-visualization-oracle-apex)
*   🇪🇸 [Gráficos Dinámicos y Visualización de Datos en Oracle APEX](https://insightsapex.hashnode.dev/graficos-dinamicos-visualizacion-datos-oracle-apex)

## Contents

*   **`database/`**: SQL scripts to create the schema, sample data, and PL/SQL packages.
    *   `01_schema.sql`: Creates `orders` and `regions` tables.
    *   `02_sample_data.sql`: Inserts sample data for testing.
    *   `03_packages.sql`: Contains the `GET_SALES_DATA` logic for the advanced demo.
*   **`apex/`**: JavaScript code used in the APEX page.
    *   `chart_refresh.js`: The AJAX call using `apex.server.process`.

## How to Use

1.  Run the scripts in `database/` in your Oracle APEX SQL Workshop or via SQLcl.
2.  Create a new APEX Page.
3.  Follow the instructions in the blog post to configure the JET Chart region.
4.  Use the JavaScript code in `apex/chart_refresh.js` for the Dynamic Action.
