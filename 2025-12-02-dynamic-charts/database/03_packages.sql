-- 03_packages.sql
-- PL/SQL Process logic for the Advanced Demo (AJAX Callback)
-- Name: GET_SALES_DATA

DECLARE
    l_context  APEX_EXEC.T_CONTEXT;
BEGIN
    -- Step 1: Execute secure SQL with bind variables using optimized Query Context
    l_context := APEX_EXEC.OPEN_QUERY_CONTEXT(
        p_location          => APEX_EXEC.C_LOCATION_LOCAL_DB,
        p_sql_query         =>
            'SELECT
               TO_CHAR(order_date, ''YYYY-MM'') AS "period",
               SUM(order_total)                 AS "total_sales"
             FROM orders
             WHERE EXTRACT(YEAR FROM order_date) = :P_YEAR
               AND (:P_REGION IS NULL OR region_id = :P_REGION)
             GROUP BY TO_CHAR(order_date, ''YYYY-MM'')
             ORDER BY "period"',
        p_external_parameters => APEX_EXEC.T_PARAMETERS(
            APEX_EXEC.T_PARAMETER(p_name => 'P_YEAR',   p_value => :P10_YEAR),
            APEX_EXEC.T_PARAMETER(p_name => 'P_REGION', p_value => :P10_REGION)
        )
    );

    -- Step 2: Emit JSON response directly from context (High-Performance Serialization)
    APEX_JSON.OPEN_OBJECT;
    APEX_JSON.WRITE('data', l_context);
    APEX_JSON.CLOSE_OBJECT;

    -- Step 3: Clean up
    APEX_EXEC.CLOSE_CONTEXT(l_context);
EXCEPTION
    WHEN OTHERS THEN
        APEX_EXEC.CLOSE_CONTEXT(l_context);
        RAISE;
END;
/
