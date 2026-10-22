-- test_get_sales_data.sql
-- Automated regression and unit tests for GET_SALES_DATA PL/SQL Process

SET DEFINE OFF;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE;

SET SERVEROUTPUT ON SIZE UNLIMITED;
SET FEEDBACK OFF;

-- Bind variables for host environment
VARIABLE P10_YEAR VARCHAR2(20);
VARIABLE P10_REGION VARCHAR2(20);
VARIABLE TEST_YEAR VARCHAR2(20);
VARIABLE TEST_REGION VARCHAR2(20);

-- Temporary helper package for suite lifecycle and assertions
CREATE OR REPLACE PACKAGE test_sales_runner_pkg IS
    g_total   NUMBER := 0;
    g_failed  NUMBER := 0;
    PROCEDURE init(p_year VARCHAR2, p_region VARCHAR2);
    PROCEDURE record_result(p_name VARCHAR2, p_condition BOOLEAN, p_detail VARCHAR2 DEFAULT NULL);
    PROCEDURE summary;
END test_sales_runner_pkg;
/

CREATE OR REPLACE PACKAGE BODY test_sales_runner_pkg IS
    PROCEDURE init(p_year VARCHAR2, p_region VARCHAR2) IS
    BEGIN
        g_total  := 0;
        g_failed := 0;
        DBMS_OUTPUT.PUT_LINE('====================================================');
        DBMS_OUTPUT.PUT_LINE('SUITE: GET_SALES_DATA Production Process Tests');
        DBMS_OUTPUT.PUT_LINE('====================================================');
        DBMS_OUTPUT.PUT_LINE('Target Fixture -> Year: ' || p_year || ' | Region: ' || p_region);
    END init;

    PROCEDURE record_result(p_name VARCHAR2, p_condition BOOLEAN, p_detail VARCHAR2 DEFAULT NULL) IS
    BEGIN
        g_total := g_total + 1;
        IF p_condition THEN
            DBMS_OUTPUT.PUT_LINE('  [PASS] ' || p_name);
        ELSE
            g_failed := g_failed + 1;
            DBMS_OUTPUT.PUT_LINE('  [FAIL] ' || p_name || ' - Detail: ' || p_detail);
        END IF;
    END record_result;

    PROCEDURE summary IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('----------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('RESULTS: Total: ' || g_total ||
                             ' | Passed: ' || (g_total - g_failed) ||
                             ' | Failed: ' || g_failed);
        DBMS_OUTPUT.PUT_LINE('====================================================');
        IF g_failed > 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Test suite failed with ' || g_failed || ' failed assertions.');
        END IF;
    END summary;
END test_sales_runner_pkg;
/

-- Initialize suite state and APEX session dynamically
DECLARE
    l_ws_id   NUMBER;
    l_app_id  NUMBER;
    l_cgiv    owa.vc_arr;
    l_cgin    owa.vc_arr;
BEGIN
    -- Dynamically discover workspace and application without hardcoded IDs
    SELECT workspace_id
    INTO l_ws_id
    FROM apex_workspaces
    WHERE ROWNUM = 1;

    SELECT application_id
    INTO l_app_id
    FROM apex_applications
    WHERE workspace_id = l_ws_id
      AND ROWNUM = 1;

    APEX_UTIL.SET_SECURITY_GROUP_ID(l_ws_id);
    APEX_SESSION.CREATE_SESSION(
        p_app_id   => l_app_id,
        p_page_id  => 1,
        p_username => 'TEST_RUNNER'
    );

    owa.init_cgi_env(0, l_cgin, l_cgiv);

    -- Select existing year and region from the same order for deterministic fixture
    SELECT TO_CHAR(EXTRACT(YEAR FROM order_date)), TO_CHAR(region_id)
    INTO :TEST_YEAR, :TEST_REGION
    FROM orders
    WHERE region_id IS NOT NULL
      AND ROWNUM = 1;

    test_sales_runner_pkg.init(:TEST_YEAR, :TEST_REGION);
END;
/

--------------------------------------------------------------------------------
-- TEST 1: AJAX Call via APEX_APPLICATION.G_X01 / G_X02 (all regions)
--------------------------------------------------------------------------------
DECLARE
    l_cgiv owa.vc_arr;
    l_cgin owa.vc_arr;
BEGIN
    owa.init_cgi_env(0, l_cgin, l_cgiv);
    APEX_APPLICATION.G_X01 := :TEST_YEAR;
    APEX_APPLICATION.G_X02 := NULL;
    :P10_YEAR   := NULL;
    :P10_REGION := NULL;
END;
/
@@03_packages.sql
DECLARE
    l_page  HTP.HTBUF_ARR;
    l_lines NUMBER := 9999;
    l_buf   CLOB;
BEGIN
    OWA.GET_PAGE(l_page, l_lines);
    FOR i IN 1..l_lines LOOP
        l_buf := l_buf || l_page(i);
    END LOOP;
    test_sales_runner_pkg.record_result(
        p_name      => 'Test 1: AJAX scalar parameters (G_X01=' || :TEST_YEAR || ', G_X02=NULL) returns valid JSON array with "data"',
        p_condition => (l_buf IS NOT NULL
                        AND INSTR(l_buf, '"data":[') > 0
                        AND INSTR(l_buf, '"period":') > 0
                        AND INSTR(l_buf, '"total_sales":') > 0),
        p_detail    => SUBSTR(l_buf, 1, 150)
    );
END;
/

--------------------------------------------------------------------------------
-- TEST 2: AJAX Call with specific Region filter (G_X02 = TEST_REGION)
--------------------------------------------------------------------------------
DECLARE
    l_cgiv owa.vc_arr;
    l_cgin owa.vc_arr;
BEGIN
    owa.init_cgi_env(0, l_cgin, l_cgiv);
    APEX_APPLICATION.G_X01 := :TEST_YEAR;
    APEX_APPLICATION.G_X02 := :TEST_REGION;
    :P10_YEAR   := NULL;
    :P10_REGION := NULL;
END;
/
@@03_packages.sql
DECLARE
    l_page  HTP.HTBUF_ARR;
    l_lines NUMBER := 9999;
    l_buf   CLOB;
BEGIN
    OWA.GET_PAGE(l_page, l_lines);
    FOR i IN 1..l_lines LOOP
        l_buf := l_buf || l_page(i);
    END LOOP;
    test_sales_runner_pkg.record_result(
        p_name      => 'Test 2: AJAX with specific region (G_X02=' || :TEST_REGION || ') returns non-empty filtered array',
        p_condition => (l_buf IS NOT NULL
                        AND INSTR(l_buf, '"data":[') > 0
                        AND INSTR(l_buf, '"total_sales":') > 0),
        p_detail    => SUBSTR(l_buf, 1, 150)
    );
END;
/

--------------------------------------------------------------------------------
-- TEST 3: Bind variable fallback (when G_X01 / G_X02 are NULL)
--------------------------------------------------------------------------------
DECLARE
    l_cgiv owa.vc_arr;
    l_cgin owa.vc_arr;
BEGIN
    owa.init_cgi_env(0, l_cgin, l_cgiv);
    APEX_APPLICATION.G_X01 := NULL;
    APEX_APPLICATION.G_X02 := NULL;
    :P10_YEAR   := :TEST_YEAR;
    :P10_REGION := :TEST_REGION;
END;
/
@@03_packages.sql
DECLARE
    l_page  HTP.HTBUF_ARR;
    l_lines NUMBER := 9999;
    l_buf   CLOB;
BEGIN
    OWA.GET_PAGE(l_page, l_lines);
    FOR i IN 1..l_lines LOOP
        l_buf := l_buf || l_page(i);
    END LOOP;
    test_sales_runner_pkg.record_result(
        p_name      => 'Test 3: Bind variable fallback (YEAR=' || :TEST_YEAR || ', REGION=' || :TEST_REGION || ') works when G_X01/G_X02 are NULL',
        p_condition => (l_buf IS NOT NULL
                        AND INSTR(l_buf, '"data":[') > 0
                        AND INSTR(l_buf, '"period":') > 0),
        p_detail    => SUBSTR(l_buf, 1, 150)
    );
END;
/

--------------------------------------------------------------------------------
-- TEST 4: Query with no matching records returns valid empty array
--------------------------------------------------------------------------------
DECLARE
    l_cgiv owa.vc_arr;
    l_cgin owa.vc_arr;
BEGIN
    owa.init_cgi_env(0, l_cgin, l_cgiv);
    APEX_APPLICATION.G_X01 := '1900';
    APEX_APPLICATION.G_X02 := '9999';
    :P10_YEAR   := NULL;
    :P10_REGION := NULL;
END;
/
@@03_packages.sql
DECLARE
    l_page  HTP.HTBUF_ARR;
    l_lines NUMBER := 9999;
    l_buf   CLOB;
BEGIN
    OWA.GET_PAGE(l_page, l_lines);
    FOR i IN 1..l_lines LOOP
        l_buf := l_buf || l_page(i);
    END LOOP;
    test_sales_runner_pkg.record_result(
        p_name      => 'Test 4: Non-matching year/region returns valid empty JSON array {"data":[]}',
        p_condition => (l_buf IS NOT NULL
                        AND REGEXP_LIKE(l_buf, '"data"\s*:\s*\[\s*\]')),
        p_detail    => SUBSTR(l_buf, 1, 100)
    );
END;
/

--------------------------------------------------------------------------------
-- TEST 5: Verify lowercase JSON property keys for frontend chart compatibility
--------------------------------------------------------------------------------
DECLARE
    l_cgiv owa.vc_arr;
    l_cgin owa.vc_arr;
BEGIN
    owa.init_cgi_env(0, l_cgin, l_cgiv);
    APEX_APPLICATION.G_X01 := :TEST_YEAR;
    APEX_APPLICATION.G_X02 := NULL;
    :P10_YEAR   := NULL;
    :P10_REGION := NULL;
END;
/
@@03_packages.sql
DECLARE
    l_page  HTP.HTBUF_ARR;
    l_lines NUMBER := 9999;
    l_buf   CLOB;
BEGIN
    OWA.GET_PAGE(l_page, l_lines);
    FOR i IN 1..l_lines LOOP
        l_buf := l_buf || l_page(i);
    END LOOP;
    test_sales_runner_pkg.record_result(
        p_name      => 'Test 5: Verify lowercase property keys ("period", "total_sales")',
        p_condition => (INSTR(l_buf, '"period":') > 0
                        AND INSTR(l_buf, '"PERIOD":') = 0
                        AND INSTR(l_buf, '"total_sales":') > 0
                        AND INSTR(l_buf, '"TOTAL_SALES":') = 0),
        p_detail    => 'Keys check: period and total_sales must be lowercase'
    );
END;
/

--------------------------------------------------------------------------------
-- Suite Cleanup & Evaluation
--------------------------------------------------------------------------------
BEGIN
    BEGIN
        APEX_SESSION.DELETE_SESSION;
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;

    test_sales_runner_pkg.summary;
END;
/

DROP PACKAGE test_sales_runner_pkg;
