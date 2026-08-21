-- 03_packages.sql
-- PL/SQL Process logic for the Advanced Demo (AJAX Callback)
-- Name: GET_SALES_DATA

DECLARE
    l_context  APEX_EXEC.T_CONTEXT;
BEGIN
    -- Step 1: Execute secure SQL with bind variables
    l_context := APEX_EXEC.OPEN_QUERY_CONTEXT(
        p_sql_statement =>
            'SELECT
               TO_CHAR(order_date, ''YYYY-MM'') AS "period",
               SUM(order_total)                 AS "total_sales"
             FROM orders
             WHERE order_date >= TO_DATE(:P_YEAR || ''-01-01'', ''YYYY-MM-DD'')
               AND order_date <  TO_DATE(TO_NUMBER(:P_YEAR) + 1 || ''-01-01'', ''YYYY-MM-DD'')
               AND (:P_REGION IS NULL OR region_id = :P_REGION)
             GROUP BY TO_CHAR(order_date, ''YYYY-MM'')
             ORDER BY "period"',
        p_external_parameters => APEX_EXEC.T_BIND_VAR(
            APEX_EXEC.T_BIND_VAR_ROW('P_YEAR',   :P10_YEAR),
            APEX_EXEC.T_BIND_VAR_ROW('P_REGION', :P10_REGION)
        )
    );

    -- Step 2: Emit JSON response
    APEX_JSON.OPEN_OBJECT;
    APEX_JSON.WRITE('data', l_context);
    APEX_JSON.CLOSE_OBJECT;

    APEX_EXEC.CLOSE_CONTEXT(l_context);
END;
/
