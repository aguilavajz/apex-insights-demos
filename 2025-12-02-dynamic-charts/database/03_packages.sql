-- 03_packages.sql
-- PL/SQL Process logic for the Advanced Demo (AJAX Callback)
-- Name: GET_SALES_DATA

DECLARE
    l_context  APEX_EXEC.T_CONTEXT;
    l_params   APEX_EXEC.T_PARAMETERS;
BEGIN
    -- Step 1: Configure bind parameters defensively (supports AJAX x01/x02 and session state)
    APEX_EXEC.ADD_PARAMETER(l_params, 'P_YEAR',   COALESCE(APEX_APPLICATION.G_X01, :P10_YEAR));
    APEX_EXEC.ADD_PARAMETER(l_params, 'P_REGION', COALESCE(APEX_APPLICATION.G_X02, :P10_REGION));

    -- Step 2: Execute secure SQL with bind variables using optimized Query Context
    l_context := APEX_EXEC.OPEN_QUERY_CONTEXT(
        p_location          => APEX_EXEC.C_LOCATION_LOCAL_DB,
        p_sql_query         =>
            'SELECT
               TO_CHAR(order_date, ''YYYY-MM'') AS "period",
               SUM(order_total)                 AS "total_sales"
             FROM orders
             WHERE order_date >= TO_DATE(:P_YEAR || ''-01-01'', ''YYYY-MM-DD'')
               AND order_date <  TO_DATE(TO_NUMBER(:P_YEAR) + 1 || ''-01-01'', ''YYYY-MM-DD'')
               AND (:P_REGION IS NULL OR region_id = :P_REGION)
             GROUP BY TO_CHAR(order_date, ''YYYY-MM'')
             ORDER BY "period"',
        p_sql_parameters    => l_params
    );

    -- Step 3: Emit JSON response directly from context (High-Performance Serialization)
    APEX_JSON.OPEN_OBJECT;
    APEX_JSON.WRITE_CONTEXT('data', l_context);
    APEX_JSON.CLOSE_OBJECT;

    -- Step 4: Clean up resources
    APEX_EXEC.CLOSE(l_context);
EXCEPTION
    WHEN OTHERS THEN
        IF l_context IS NOT NULL THEN
            APEX_EXEC.CLOSE(l_context);
        END IF;
        RAISE;
END;
/
