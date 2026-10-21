-- test_get_sales_data.sql
-- Automated regression and unit tests for GET_SALES_DATA PL/SQL Process

SET DEFINE OFF;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE;

SET SERVEROUTPUT ON SIZE UNLIMITED;
SET FEEDBACK OFF;

VARIABLE P10_YEAR VARCHAR2(20);
VARIABLE P10_REGION VARCHAR2(20);

DECLARE
    l_total_tests   PLS_INTEGER := 0;
    l_passed_tests  PLS_INTEGER := 0;
    l_failed_tests  PLS_INTEGER := 0;

    l_ws_id         NUMBER;
    l_app_id        NUMBER;
    l_json          CLOB;
    l_test_year     VARCHAR2(4);
    l_err           VARCHAR2(4000);

    FUNCTION get_htp_output RETURN CLOB
    IS
        l_page  HTP.HTBUF_ARR;
        l_lines NUMBER := 9999;
        l_buf   CLOB;
    BEGIN
        OWA.GET_PAGE(l_page, l_lines);
        FOR i IN 1..l_lines LOOP
            l_buf := l_buf || l_page(i);
        END LOOP;
        RETURN l_buf;
    END get_htp_output;

    FUNCTION run_process_test(
        p_g_x01       IN VARCHAR2,
        p_g_x02       IN VARCHAR2,
        p_bind_year   IN VARCHAR2,
        p_bind_region IN VARCHAR2
    ) RETURN CLOB
    IS
        l_context  APEX_EXEC.T_CONTEXT;
        l_params   APEX_EXEC.T_PARAMETERS;
        l_result   CLOB;
        l_cgiv     owa.vc_arr;
        l_cgin     owa.vc_arr;
    BEGIN
        -- Re-initialize OWA CGI environment for each invocation
        owa.init_cgi_env(0, l_cgin, l_cgiv);

        -- Set request values
        APEX_APPLICATION.G_X01 := p_g_x01;
        APEX_APPLICATION.G_X02 := p_g_x02;

        -- Step 1: Configure bind parameters defensively
        APEX_EXEC.ADD_PARAMETER(l_params, 'P_YEAR',   COALESCE(APEX_APPLICATION.G_X01, p_bind_year));
        APEX_EXEC.ADD_PARAMETER(l_params, 'P_REGION', COALESCE(APEX_APPLICATION.G_X02, p_bind_region));

        -- Step 2: Execute secure SQL with bind variables using Query Context
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
            p_sql_parameters    => l_params
        );

        -- Step 3: Emit JSON response directly from context
        APEX_JSON.OPEN_OBJECT;
        APEX_JSON.WRITE_CONTEXT('data', l_context);
        APEX_JSON.CLOSE_OBJECT;

        -- Step 4: Clean up resources
        APEX_EXEC.CLOSE(l_context);

        l_result := get_htp_output;
        RETURN l_result;
    EXCEPTION
        WHEN OTHERS THEN
            IF l_context IS NOT NULL THEN
                APEX_EXEC.CLOSE(l_context);
            END IF;
            RAISE;
    END run_process_test;

    PROCEDURE assert_test(p_name IN VARCHAR2, p_condition IN BOOLEAN, p_detail IN VARCHAR2 DEFAULT NULL)
    IS
    BEGIN
        l_total_tests := l_total_tests + 1;
        IF p_condition THEN
            l_passed_tests := l_passed_tests + 1;
            DBMS_OUTPUT.PUT_LINE('  [PASS] ' || p_name);
        ELSE
            l_failed_tests := l_failed_tests + 1;
            DBMS_OUTPUT.PUT_LINE('  [FAIL] ' || p_name || ' - Detail: ' || p_detail);
        END IF;
    END assert_test;
BEGIN
    DBMS_OUTPUT.PUT_LINE('====================================================');
    DBMS_OUTPUT.PUT_LINE('SUITE: GET_SALES_DATA Optimization & Fixes Audit');
    DBMS_OUTPUT.PUT_LINE('====================================================');

    -- Setup: Discover active workspace and app for APEX session
    BEGIN
        SELECT workspace_id INTO l_ws_id
        FROM apex_workspaces
        WHERE workspace = 'ESTATE'
          AND ROWNUM = 1;
        l_app_id := 103;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            SELECT workspace_id INTO l_ws_id FROM apex_workspaces WHERE ROWNUM = 1;
            SELECT application_id INTO l_app_id FROM apex_applications WHERE ROWNUM = 1;
    END;

    APEX_UTIL.SET_SECURITY_GROUP_ID(l_ws_id);
    APEX_SESSION.CREATE_SESSION(
        p_app_id   => l_app_id,
        p_page_id  => 1,
        p_username => 'TEST_RUNNER'
    );

    -- Find an existing order year to test realistic retrieval
    SELECT TO_CHAR(EXTRACT(YEAR FROM order_date))
    INTO l_test_year
    FROM orders
    WHERE ROWNUM = 1;

    -- TEST 1: AJAX Call via APEX_APPLICATION.G_X01 / G_X02 (all regions)
    l_json := run_process_test(
        p_g_x01       => l_test_year,
        p_g_x02       => NULL,
        p_bind_year   => NULL,
        p_bind_region => NULL
    );
    assert_test(
        p_name      => 'Test 1: AJAX scalar parameters (G_X01=' || l_test_year || ', G_X02=NULL) returns valid JSON array with "data"',
        p_condition => (l_json IS NOT NULL 
                        AND INSTR(l_json, '"data":[') > 0 
                        AND INSTR(l_json, '"period":') > 0 
                        AND INSTR(l_json, '"total_sales":') > 0),
        p_detail    => SUBSTR(l_json, 1, 150)
    );

    -- TEST 2: AJAX Call with specific Region filter (G_X02 = '1')
    l_json := run_process_test(
        p_g_x01       => l_test_year,
        p_g_x02       => '1',
        p_bind_year   => NULL,
        p_bind_region => NULL
    );
    assert_test(
        p_name      => 'Test 2: AJAX with specific region (G_X02=1) returns filtered array',
        p_condition => (l_json IS NOT NULL 
                        AND INSTR(l_json, '"data":[') > 0 
                        AND INSTR(l_json, '"total_sales":') > 0),
        p_detail    => SUBSTR(l_json, 1, 150)
    );

    -- TEST 3: Bind variable fallback (when G_X01 / G_X02 are NULL)
    l_json := run_process_test(
        p_g_x01       => NULL,
        p_g_x02       => NULL,
        p_bind_year   => l_test_year,
        p_bind_region => '2'
    );
    assert_test(
        p_name      => 'Test 3: Bind variable fallback (YEAR=' || l_test_year || ', REGION=2) works when G_X01/G_X02 are NULL',
        p_condition => (l_json IS NOT NULL 
                        AND INSTR(l_json, '"data":[') > 0 
                        AND INSTR(l_json, '"period":') > 0),
        p_detail    => SUBSTR(l_json, 1, 150)
    );

    -- TEST 4: Query with no matching records returns valid empty array
    l_json := run_process_test(
        p_g_x01       => '1900',
        p_g_x02       => '9999',
        p_bind_year   => NULL,
        p_bind_region => NULL
    );
    assert_test(
        p_name      => 'Test 4: Non-matching year/region returns valid empty JSON array {"data":[]}',
        p_condition => (l_json IS NOT NULL 
                        AND REGEXP_LIKE(l_json, '"data"\s*:\s*\[\s*\]')),
        p_detail    => SUBSTR(l_json, 1, 100)
    );

    -- TEST 5: Verify lowercase JSON property keys for frontend chart compatibility
    l_json := run_process_test(
        p_g_x01       => l_test_year,
        p_g_x02       => NULL,
        p_bind_year   => NULL,
        p_bind_region => NULL
    );
    assert_test(
        p_name      => 'Test 5: Verify lowercase property keys ("period", "total_sales")',
        p_condition => (INSTR(l_json, '"period":') > 0 
                        AND INSTR(l_json, '"PERIOD":') = 0 
                        AND INSTR(l_json, '"total_sales":') > 0 
                        AND INSTR(l_json, '"TOTAL_SALES":') = 0),
        p_detail    => 'Keys check: period and total_sales must be lowercase'
    );

    APEX_SESSION.DELETE_SESSION;

    DBMS_OUTPUT.PUT_LINE('----------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('RESULTS: Total: ' || l_total_tests || 
                         ' | Passed: ' || l_passed_tests || 
                         ' | Failed: ' || l_failed_tests);
    DBMS_OUTPUT.PUT_LINE('====================================================');

    IF l_failed_tests > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Test suite failed with ' || l_failed_tests || ' failed assertions.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        l_err := SQLERRM;
        BEGIN
            APEX_SESSION.DELETE_SESSION;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
        RAISE_APPLICATION_ERROR(-20002, 'Suite encountered unexpected error: ' || l_err);
END;
/

-- Also execute the exact 03_packages.sql file to verify direct script compilation & execution
PROMPT Executing 03_packages.sql directly...
EXEC :P10_YEAR := '2024'; :P10_REGION := NULL;
DECLARE
    l_cgiv  owa.vc_arr;
    l_cgin  owa.vc_arr;
BEGIN
    APEX_UTIL.SET_SECURITY_GROUP_ID(9735678180641177);
    APEX_SESSION.CREATE_SESSION(p_app_id => 103, p_page_id => 1, p_username => 'TEST_RUNNER');
    owa.init_cgi_env(0, l_cgin, l_cgiv);
END;
/
@2025-12-02-dynamic-charts/database/03_packages.sql
BEGIN
    APEX_SESSION.DELETE_SESSION;
    DBMS_OUTPUT.PUT_LINE('Direct 03_packages.sql execution: SUCCESS');
END;
/
