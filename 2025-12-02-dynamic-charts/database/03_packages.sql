-- 03_packages.sql
-- PL/SQL Process logic for the Advanced Demo (AJAX Callback)
-- Name: GET_SALES_DATA

DECLARE
    l_context APEX_EXEC.T_CONTEXT;
    l_params  APEX_EXEC.T_PARAMETERS;
BEGIN
    -- Performance Optimization 1: Pass bind parameters via APEX_EXEC.T_PARAMETERS
    APEX_EXEC.ADD_PARAMETER(l_params, 'P_YEAR',   :P10_YEAR);
    APEX_EXEC.ADD_PARAMETER(l_params, 'P_REGION', :P10_REGION);

    -- Performance Optimization 2: Use sargable date filtering to enable index usage (idx_orders_date)
    -- instead of non-sargable EXTRACT(YEAR FROM order_date) which forces a full table scan.
    l_context := APEX_EXEC.OPEN_QUERY_CONTEXT(
        p_location            => APEX_EXEC.C_LOCATION_LOCAL_DB,
        p_sql_query           =>
            'SELECT
               TO_CHAR(order_date, ''YYYY-MM'') AS "period",
               SUM(order_total)                 AS "total_sales"
             FROM orders
             WHERE order_date >= TO_DATE(:P_YEAR || ''-01-01'', ''YYYY-MM-DD'')
               AND order_date < ADD_MONTHS(TO_DATE(:P_YEAR || ''-01-01'', ''YYYY-MM-DD''), 12)
               AND (:P_REGION IS NULL OR region_id = :P_REGION)
             GROUP BY TO_CHAR(order_date, ''YYYY-MM'')
             ORDER BY "period"',
        p_external_parameters => l_params
    );

    -- Performance Optimization 3: High-performance C-level JSON serialization streaming
    -- directly from query context, replacing slow row-by-row procedural PL/SQL loops.
    APEX_JSON.OPEN_OBJECT;
    APEX_JSON.WRITE('data', l_context);
    APEX_JSON.CLOSE_OBJECT;

    -- Clean up query context resource
    APEX_EXEC.CLOSE_CONTEXT(l_context);
EXCEPTION
    WHEN OTHERS THEN
        APEX_EXEC.CLOSE_CONTEXT(l_context);
        RAISE;
END;
/
