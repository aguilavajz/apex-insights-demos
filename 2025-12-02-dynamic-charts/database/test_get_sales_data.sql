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
        DBMS_OUTPUT.PUT_LINE('Controlled Fixture -> Year: ' || p_year || ' | Target Region: ' || p_region);
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

-- Initialize suite state, APEX session, and deterministic test fixtures
DECLARE
    l_ws_id    NUMBER;
    l_app_id   NUMBER;
    l_page_id  NUMBER;
    l_cgiv     owa.vc_arr;
    l_cgin     owa.vc_arr;
BEGIN
    -- Dynamically discover workspace, application, and a valid page
    BEGIN
        SELECT a.workspace_id, a.application_id, NVL(MIN(p.page_id), 1)
        INTO l_ws_id, l_app_id, l_page_id
        FROM apex_applications a
        LEFT JOIN apex_application_pages p
          ON p.application_id = a.application_id
         AND p.page_id > 0
        WHERE a.workspace NOT IN ('INTERNAL', 'COM.ORACLE.APEX.RESTRICTED')
        GROUP BY a.workspace_id, a.application_id
        ORDER BY a.application_id
        FETCH FIRST 1 ROWS ONLY;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            SELECT workspace_id INTO l_ws_id FROM apex_workspaces WHERE ROWNUM = 1;
            l_app_id  := 100;
            l_page_id := 1;
    END;

    APEX_UTIL.SET_SECURITY_GROUP_ID(l_ws_id);
    APEX_SESSION.CREATE_SESSION(
        p_app_id   => l_app_id,
        p_page_id  => l_page_id,
        p_username => 'TEST_RUNNER'
    );

    owa.init_cgi_env(0, l_cgin, l_cgiv);

    -- Transactional sandbox: Establish savepoint strictly after CREATE_SESSION
    SAVEPOINT sp_dynamic_charts_test;

    -- Insert controlled, deterministic fixture rows for Year 2099
    -- Region 1: 100 + 250 = 350.00
    -- Region 2: 500.00
    -- Total across all regions for 2099-01: 850.00
    INSERT INTO orders (customer_name, order_total, order_date, region_id)
    VALUES ('Deterministic Cust 1', 100.00, TO_DATE('2099-01-10', 'YYYY-MM-DD'), 1);

    INSERT INTO orders (customer_name, order_total, order_date, region_id)
    VALUES ('Deterministic Cust 2', 250.00, TO_DATE('2099-01-20', 'YYYY-MM-DD'), 1);

    INSERT INTO orders (customer_name, order_total, order_date, region_id)
    VALUES ('Deterministic Cust 3', 500.00, TO_DATE('2099-01-25', 'YYYY-MM-DD'), 2);

    :TEST_YEAR   := '2099';
    :TEST_REGION := '1';

    test_sales_runner_pkg.init(:TEST_YEAR, :TEST_REGION);
END;
/

--------------------------------------------------------------------------------
-- TEST 1: AJAX Call via APEX_APPLICATION.G_X01 / G_X02 (all regions)
-- Expected aggregate total for 2099-01 across all regions: 850
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
        p_name      => 'Test 1: AJAX all regions (G_X01=' || :TEST_YEAR || ', G_X02=NULL) returns total 850',
        p_condition => (l_buf IS NOT NULL
                        AND INSTR(l_buf, '"period":"2099-01"') > 0
                        AND INSTR(l_buf, '"total_sales":850') > 0),
        p_detail    => SUBSTR(l_buf, 1, 150)
    );
END;
/

--------------------------------------------------------------------------------
-- TEST 2: AJAX Call with specific Region filter (G_X02 = 1)
-- Expected aggregate total for 2099-01 for region 1: 350 (excludes region 2: 500)
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
        p_name      => 'Test 2: AJAX region filter (G_X02=' || :TEST_REGION || ') returns exact regional total 350 (excluding region 2)',
        p_condition => (l_buf IS NOT NULL
                        AND INSTR(l_buf, '"period":"2099-01"') > 0
                        AND INSTR(l_buf, '"total_sales":350') > 0
                        AND INSTR(l_buf, '"total_sales":850') = 0
                        AND INSTR(l_buf, '"total_sales":500') = 0),
        p_detail    => SUBSTR(l_buf, 1, 150)
    );
END;
/

--------------------------------------------------------------------------------
-- TEST 3: Bind variable fallback (when G_X01 / G_X02 are NULL)
-- Region 2 expected aggregate total for 2099-01: 500
--------------------------------------------------------------------------------
DECLARE
    l_cgiv owa.vc_arr;
    l_cgin owa.vc_arr;
BEGIN
    owa.init_cgi_env(0, l_cgin, l_cgiv);
    APEX_APPLICATION.G_X01 := NULL;
    APEX_APPLICATION.G_X02 := NULL;
    :P10_YEAR   := :TEST_YEAR;
    :P10_REGION := '2';
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
        p_name      => 'Test 3: Bind variable fallback (YEAR=' || :TEST_YEAR || ', REGION=2) returns region 2 total 500',
        p_condition => (l_buf IS NOT NULL
                        AND INSTR(l_buf, '"period":"2099-01"') > 0
                        AND INSTR(l_buf, '"total_sales":500') > 0
                        AND INSTR(l_buf, '"total_sales":350') = 0),
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
    -- Rollback transactional fixture changes
    ROLLBACK TO sp_dynamic_charts_test;

    BEGIN
        APEX_SESSION.DELETE_SESSION;
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;

    test_sales_runner_pkg.summary;
EXCEPTION
    WHEN OTHERS THEN
        BEGIN
            ROLLBACK TO sp_dynamic_charts_test;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
        BEGIN
            APEX_SESSION.DELETE_SESSION;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
        RAISE;
END;
/

DROP PACKAGE test_sales_runner_pkg;
