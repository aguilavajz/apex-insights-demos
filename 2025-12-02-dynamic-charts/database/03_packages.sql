-- 03_packages.sql
-- PL/SQL Process logic for the Advanced Demo (AJAX Callback)
-- Name: GET_SALES_DATA

DECLARE
    l_cursor   APEX_EXEC.T_CURSOR;
BEGIN
    -- Step 1: Execute secure SQL with bind variables
    l_cursor := APEX_EXEC.OPEN_CURSOR(
        p_sql_statement =>
            'SELECT
               TO_CHAR(order_date, ''YYYY-MM'') AS "period",
               SUM(order_total)                 AS "total_sales"
             FROM orders
             WHERE EXTRACT(YEAR FROM order_date) = :P_YEAR
               AND (:P_REGION IS NULL OR region_id = :P_REGION)
             GROUP BY TO_CHAR(order_date, ''YYYY-MM'')
             ORDER BY 1',
        p_bind_vars     => APEX_EXEC.T_BIND_VAR(
            APEX_EXEC.T_BIND_VAR_ROW('P_YEAR',   :P10_YEAR),
            APEX_EXEC.T_BIND_VAR_ROW('P_REGION', :P10_REGION)
        )
    );

    -- Step 2: Emit JSON response
    APEX_JSON.OPEN_OBJECT;
    APEX_JSON.WRITE('data', l_cursor);
    APEX_JSON.CLOSE_OBJECT;

    APEX_EXEC.CLOSE_CURSOR(l_cursor);
END;
/
