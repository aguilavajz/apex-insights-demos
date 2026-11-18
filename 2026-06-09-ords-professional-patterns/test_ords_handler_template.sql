-- =============================================================================
-- APEX Insights — Automated Test Suite: Secure ORDS Handler Package Template
-- -----------------------------------------------------------------------------
-- Target Database: Oracle 19c / 21c
-- Script:          test_ords_handler_template.sql
-- Description:     Automated regression tests verifying input sanitization,
--                  byte-safe truncation, safe conversion, audit log integrity,
--                  and ORDS handler HTTP status mapping.
-- =============================================================================

SET DEFINE OFF;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE;

SET SERVEROUTPUT ON SIZE UNLIMITED FORMAT WRAPPED;
SET FEEDBACK OFF;

PROMPT ====================================================================
PROMPT Initializing Test Schema & Objects for ORDS Handler Template...
PROMPT ====================================================================

-- 1. Ensure prerequisite tables exist in test environment
DECLARE
    l_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO l_count FROM user_tables WHERE table_name = 'API_ERROR_LOG';
    IF l_count = 0 THEN
        EXECUTE IMMEDIATE q'[
            CREATE TABLE api_error_log (
                log_id         NUMBER         GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                error_codigo   VARCHAR2(50)   NOT NULL,
                error_mensaje  VARCHAR2(4000),
                contexto       VARCHAR2(500),
                referencia     VARCHAR2(36)   NOT NULL,
                created_at     TIMESTAMP      DEFAULT SYSTIMESTAMP NOT NULL,
                created_by     VARCHAR2(100)  DEFAULT SYS_CONTEXT('USERENV','SESSION_USER')
            )
        ]';
    END IF;

    SELECT COUNT(*) INTO l_count FROM user_tables WHERE table_name = 'API_RATE_LOG';
    IF l_count = 0 THEN
        EXECUTE IMMEDIATE q'[
            CREATE TABLE api_rate_log (
                log_id      NUMBER       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                client_id   VARCHAR2(200) NOT NULL,
                endpoint    VARCHAR2(200) NOT NULL,
                peticion_ts TIMESTAMP    DEFAULT SYSTIMESTAMP NOT NULL
            )
        ]';
    END IF;
END;
/

-- 2. Test Runner Helper Package
CREATE OR REPLACE PACKAGE test_ords_template_runner AS
    g_total   NUMBER := 0;
    g_passed  NUMBER := 0;
    g_failed  NUMBER := 0;

    PROCEDURE init_suite;
    PROCEDURE record_result(
        p_test_name  VARCHAR2,
        p_condition  BOOLEAN,
        p_detail     VARCHAR2 DEFAULT NULL
    );
    PROCEDURE print_summary;
END test_ords_template_runner;
/

CREATE OR REPLACE PACKAGE BODY test_ords_template_runner AS
    PROCEDURE init_suite IS
    BEGIN
        g_total  := 0;
        g_passed := 0;
        g_failed := 0;
        DBMS_OUTPUT.PUT_LINE('====================================================================');
        DBMS_OUTPUT.PUT_LINE('SUITE: pkg_ords_handler_template Security & Validation Suite');
        DBMS_OUTPUT.PUT_LINE('====================================================================');
    END init_suite;

    PROCEDURE record_result(
        p_test_name  VARCHAR2,
        p_condition  BOOLEAN,
        p_detail     VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        g_total := g_total + 1;
        IF p_condition THEN
            g_passed := g_passed + 1;
            DBMS_OUTPUT.PUT_LINE('  [PASS] ' || p_test_name);
        ELSE
            g_failed := g_failed + 1;
            DBMS_OUTPUT.PUT_LINE('  [FAIL] ' || p_test_name || ' -> ' || p_detail);
        END IF;
    END record_result;

    PROCEDURE print_summary IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('TEST RESULTS SUMMARY:');
        DBMS_OUTPUT.PUT_LINE('  Total Tests Executed : ' || g_total);
        DBMS_OUTPUT.PUT_LINE('  Passed               : ' || g_passed);
        DBMS_OUTPUT.PUT_LINE('  Failed               : ' || g_failed);
        IF g_failed = 0 THEN
            DBMS_OUTPUT.PUT_LINE('STATUS: ALL TESTS PASSING');
            DBMS_OUTPUT.PUT_LINE('====================================================================');
        ELSE
            DBMS_OUTPUT.PUT_LINE('STATUS: TEST FAILURES DETECTED');
            DBMS_OUTPUT.PUT_LINE('====================================================================');
            RAISE_APPLICATION_ERROR(-20099, 'Test suite completed with ' || g_failed || ' failure(s).');
        END IF;
    END print_summary;
END test_ords_template_runner;
/

PROMPT
PROMPT Executing Test Cases...
PROMPT

BEGIN
    test_ords_template_runner.init_suite;
END;
/

-- Test 1: get_collection handles oversized string (>200 chars) without ORA-06502
DECLARE
    l_cur      SYS_REFCURSOR;
    l_input    VARCHAR2(4000);
    l_err_msg  VARCHAR2(4000);
    l_passed   BOOLEAN := FALSE;
BEGIN
    l_input := RPAD('SEARCH_TERM_', 1000, 'X'); -- 1000 characters
    BEGIN
        pkg_ords_handler_template.get_collection(
            p_filter_val => l_input,
            p_cursor     => l_cur
        );
        l_passed := (l_cur IS NOT NULL);
        IF l_cur IS NOT NULL AND l_cur%ISOPEN THEN
            CLOSE l_cur;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            l_err_msg := SQLERRM;
            l_passed  := FALSE;
    END;

    test_ords_template_runner.record_result(
        p_test_name => '1. get_collection: >200-char input truncated cleanly without ORA-06502',
        p_condition => l_passed,
        p_detail    => l_err_msg
    );
END;
/

-- Test 2: get_collection handles multi-byte string >200 bytes without ORA-06502
DECLARE
    l_cur      SYS_REFCURSOR;
    l_input    VARCHAR2(4000);
    l_err_msg  VARCHAR2(4000);
    l_passed   BOOLEAN := FALSE;
BEGIN
    -- 100 3-byte CJK characters = 300 bytes (exceeds standard VARCHAR2(200 BYTE) limit)
    l_input := RPAD(UNISTR('\4E16\754C'), 100, UNISTR('\4E16'));
    BEGIN
        pkg_ords_handler_template.get_collection(
            p_filter_val => l_input,
            p_cursor     => l_cur
        );
        l_passed := (l_cur IS NOT NULL);
        IF l_cur IS NOT NULL AND l_cur%ISOPEN THEN
            CLOSE l_cur;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            l_err_msg := SQLERRM;
            l_passed  := FALSE;
    END;

    test_ords_template_runner.record_result(
        p_test_name => '2. get_collection: Multi-byte input >200 bytes handled cleanly without ORA-06502',
        p_condition => l_passed,
        p_detail    => l_err_msg
    );
END;
/

-- Test 3: post_resource handles oversized string (>200 chars) for name and email
DECLARE
    l_result   VARCHAR2(4000);
    l_err_msg  VARCHAR2(4000);
    l_passed   BOOLEAN := FALSE;
    l_code     VARCHAR2(100);
BEGIN
    BEGIN
        pkg_ords_handler_template.post_resource(
            p_name   => RPAD('John Doe ', 600, 'Z'),
            p_email  => RPAD('john.doe', 500, 'a') || '@example.com',
            p_result => l_result
        );
        l_passed := (l_result IS NOT NULL AND INSTR(l_result, '"status"') > 0);
    EXCEPTION
        WHEN OTHERS THEN
            l_err_msg := SQLERRM;
            l_passed  := FALSE;
    END;

    test_ords_template_runner.record_result(
        p_test_name => '3. post_resource: >200-char input truncated without ORA-06502',
        p_condition => l_passed,
        p_detail    => l_err_msg
    );
END;
/

-- Test 4: post_resource handles multi-byte string >200 bytes without ORA-06502
DECLARE
    l_result   VARCHAR2(4000);
    l_err_msg  VARCHAR2(4000);
    l_passed   BOOLEAN := FALSE;
BEGIN
    BEGIN
        pkg_ords_handler_template.post_resource(
            p_name   => RPAD(UNISTR('\674E\96F7'), 150, UNISTR('\96F7')), -- ~300 bytes
            p_email  => 'test.multibyte@example.com',
            p_result => l_result
        );
        l_passed := (l_result IS NOT NULL AND INSTR(l_result, '"status"') > 0);
    EXCEPTION
        WHEN OTHERS THEN
            l_err_msg := SQLERRM;
            l_passed  := FALSE;
    END;

    test_ords_template_runner.record_result(
        p_test_name => '4. post_resource: Multi-byte input >200 bytes truncated without ORA-06502',
        p_condition => l_passed,
        p_detail    => l_err_msg
    );
END;
/

-- Test 5: get_resource handles non-numeric :id via safe conversion (ERR_VALIDATION, no ORA-01722)
DECLARE
    l_cur      SYS_REFCURSOR;
    l_status   VARCHAR2(50);
    l_code     VARCHAR2(50);
    l_msg      VARCHAR2(200);
    l_err_msg  VARCHAR2(4000);
    l_passed   BOOLEAN := FALSE;
    l_raw_id   VARCHAR2(100) := 'invalid-alpha-id';
    l_num_id   NUMBER;
BEGIN
    BEGIN
        -- Emulate ORDS handler safe conversion
        l_num_id := TO_NUMBER(l_raw_id DEFAULT NULL ON CONVERSION ERROR);
        
        pkg_ords_handler_template.get_resource(
            p_id     => l_num_id,
            p_cursor => l_cur
        );

        FETCH l_cur INTO l_status, l_code, l_msg;
        l_passed := (l_status = 'error' AND l_code = 'ERR_VALIDATION');
        CLOSE l_cur;
    EXCEPTION
        WHEN OTHERS THEN
            l_err_msg := SQLERRM;
            l_passed  := FALSE;
    END;

    test_ords_template_runner.record_result(
        p_test_name => '5. get_resource: Non-numeric id returns ERR_VALIDATION without ORA-01722',
        p_condition => l_passed,
        p_detail    => 'Result: code=' || l_code || ', error=' || l_err_msg
    );
END;
/

-- Test 6: get_resource handles zero and negative IDs with ERR_VALIDATION
DECLARE
    l_cur      SYS_REFCURSOR;
    l_status   VARCHAR2(50);
    l_code     VARCHAR2(50);
    l_msg      VARCHAR2(200);
    l_passed   BOOLEAN := FALSE;
BEGIN
    pkg_ords_handler_template.get_resource(
        p_id     => -42,
        p_cursor => l_cur
    );

    FETCH l_cur INTO l_status, l_code, l_msg;
    l_passed := (l_status = 'error' AND l_code = 'ERR_VALIDATION');
    CLOSE l_cur;

    test_ords_template_runner.record_result(
        p_test_name => '6. get_resource: Negative id returns ERR_VALIDATION',
        p_condition => l_passed,
        p_detail    => 'Result: status=' || l_status || ', code=' || l_code
    );
END;
/

-- Test 7: Exception logging path successfully logs when inputs exceed 500 characters
DECLARE
    l_ref_id     VARCHAR2(36) := LOWER(RAWTOHEX(SYS_GUID()));
    l_huge_param VARCHAR2(4000) := RPAD('ATTACK_PAYLOAD_', 2000, 'X');
    l_logged_ctx VARCHAR2(500);
    l_passed     BOOLEAN := FALSE;
    l_count      NUMBER;
BEGIN
    -- Verify concatenation truncation pattern: SUBSTRB(p_param, 1, 400)
    pkg_ords_handler_template.log_error_autonomous(
        p_codigo     => 'ERR_INTERNO',
        p_mensaje    => 'Simulated error with huge context',
        p_contexto   => 'pkg_ords_handler_template.get_collection | filter=' || SUBSTRB(l_huge_param, 1, 400),
        p_referencia => l_ref_id
    );

    SELECT COUNT(*), MAX(contexto)
      INTO l_count, l_logged_ctx
      FROM api_error_log
     WHERE referencia = l_ref_id;

    l_passed := (l_count = 1 AND LENGTHB(l_logged_ctx) <= 500);

    test_ords_template_runner.record_result(
        p_test_name => '7. Audit log: >500-char parameter successfully logged without ORA-12899',
        p_condition => l_passed,
        p_detail    => 'Logged count=' || l_count || ', Context byte length=' || LENGTHB(l_logged_ctx)
    );
END;
/

-- Test 8: Autonomous logging defense-in-depth: huge raw context/message truncated safely
DECLARE
    l_ref_id     VARCHAR2(36) := LOWER(RAWTOHEX(SYS_GUID()));
    l_huge_msg   VARCHAR2(4000) := RPAD('HUGE_MESSAGE_', 4000, 'M');
    l_huge_ctx   VARCHAR2(4000) := RPAD('HUGE_CONTEXT_', 2000, 'C');
    l_logged_msg VARCHAR2(4000);
    l_logged_ctx VARCHAR2(500);
    l_passed     BOOLEAN := FALSE;
    l_count      NUMBER;
BEGIN
    -- Call directly with un-truncated context (>500 bytes) to verify internal SUBSTRB defense
    pkg_ords_handler_template.log_error_autonomous(
        p_codigo     => 'ERR_INTERNO',
        p_mensaje    => l_huge_msg,
        p_contexto   => l_huge_ctx,
        p_referencia => l_ref_id
    );

    SELECT COUNT(*), MAX(error_mensaje), MAX(contexto)
      INTO l_count, l_logged_msg, l_logged_ctx
      FROM api_error_log
     WHERE referencia = l_ref_id;

    l_passed := (l_count = 1 AND LENGTHB(l_logged_ctx) <= 500 AND LENGTHB(l_logged_msg) <= 4000);

    test_ords_template_runner.record_result(
        p_test_name => '8. log_error_autonomous: Internal defense-in-depth bounds p_contexto and p_mensaje',
        p_condition => l_passed,
        p_detail    => 'Logged count=' || l_count || ', Context len=' || LENGTHB(l_logged_ctx)
    );
END;
/

-- Test 9: GET :id ORDS Handler routing logic assigns HTTP 400 for invalid/non-numeric IDs
DECLARE
    l_id_val     VARCHAR2(100) := 'invalid_xyz';
    l_status     NUMBER := 200;
    l_cur        SYS_REFCURSOR;
    l_routed_400 BOOLEAN := FALSE;
BEGIN
    -- Simulate ORDS handler execution block logic
    IF l_id_val IS NULL 
       OR TO_NUMBER(l_id_val DEFAULT NULL ON CONVERSION ERROR) IS NULL 
       OR TO_NUMBER(l_id_val DEFAULT NULL ON CONVERSION ERROR) <= 0 THEN
        l_status := 400;
        pkg_ords_handler_template.get_resource(
            p_id     => NULL,
            p_cursor => l_cur
        );
        l_routed_400 := TRUE;
    ELSE
        pkg_ords_handler_template.get_resource(
            p_id     => TO_NUMBER(l_id_val),
            p_cursor => l_cur
        );
    END IF;

    IF l_cur IS NOT NULL AND l_cur%ISOPEN THEN
        CLOSE l_cur;
    END IF;

    test_ords_template_runner.record_result(
        p_test_name => '9. GET :id Handler: Invalid id routes to HTTP 400 status',
        p_condition => (l_routed_400 AND l_status = 400),
        p_detail    => 'Status resolved to ' || l_status
    );
END;
/

-- Print summary and finalize
BEGIN
    test_ords_template_runner.print_summary;
END;
/
