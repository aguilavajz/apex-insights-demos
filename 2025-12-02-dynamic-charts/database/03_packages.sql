-- 03_packages.sql
-- PL/SQL Process logic for the Advanced Demo (AJAX Callback)
-- Name: GET_SALES_DATA

DECLARE
    l_context APEX_EXEC.T_CONTEXT;
    l_params  APEX_EXEC.T_PARAMETERS;
BEGIN
    -- Step 1: Pass bind parameters for APEX_EXEC.OPEN_QUERY_CONTEXT
    APEX_EXEC.ADD_PARAMETER(l_params, 'P_YEAR',   :P10_YEAR);
    APEX_EXEC.ADD_PARAMETER(l_params, 'P_REGION', :P10_REGION);

    -- Step 2: Execute query using OPEN_QUERY_CONTEXT with sargable date range filter.
    -- Replacing non-sargable EXTRACT(YEAR FROM order_date) with range comparisons
    -- allows Oracle to perform an Index Range Scan on idx_orders_date.
    l_context := APEX_EXEC.OPEN_QUERY_CONTEXT(
        p_location            => APEX_EXEC.C_LOCATION_LOCAL_DB,
        p_sql_query           =>
            'SELECT
               TO_CHAR(order_date, ''YYYY-MM'') AS "period",
               SUM(order_total)                 AS "total_sales"
             FROM orders
             WHERE order_date >= TO_DATE(:P_YEAR || ''-01-01'', ''YYYY-MM-DD'')
               AND order_date <  TO_DATE(TO_NUMBER(:P_YEAR) + 1 || ''-01-01'', ''YYYY-MM-DD'')
               AND (:P_REGION IS NULL OR region_id = :P_REGION)
             GROUP BY TO_CHAR(order_date, ''YYYY-MM'')
             ORDER BY "period"',
        p_external_parameters => l_params
    );

    -- Step 3: Stream query context directly into JSON response using APEX_JSON.WRITE.
    -- Replaces procedural PL/SQL row-by-row looping and eliminates context switching.
    APEX_JSON.OPEN_OBJECT;
    APEX_JSON.WRITE('data', l_context);
    APEX_JSON.CLOSE_OBJECT;

    -- Clean up context to release database resources
    APEX_EXEC.CLOSE_CONTEXT(l_context);
EXCEPTION
    WHEN OTHERS THEN
        APEX_EXEC.CLOSE_CONTEXT(l_context);
        RAISE;
END;
/
