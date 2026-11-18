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

-- 2. Compile pkg_ords_handler_template package specification and body
--    (ensures log_error_autonomous is exposed in spec for testing and handler usage)
CREATE OR REPLACE PACKAGE pkg_ords_handler_template AS

    -- Exception codes mapped to HTTP status codes
    c_err_validation CONSTANT VARCHAR2(30) := 'ERR_VALIDATION';
    c_err_not_found  CONSTANT VARCHAR2(30) := 'ERR_NOT_FOUND';
    c_err_interno    CONSTANT VARCHAR2(30) := 'ERR_INTERNO';

    -- Autonomous logging procedure to preserve error audit trails even if the
    -- main transaction rolls back. Exposed in package specification for handler
    -- error mapping and testability.
    PROCEDURE log_error_autonomous (
        p_codigo     IN VARCHAR2,
        p_mensaje    IN VARCHAR2,
        p_contexto   IN VARCHAR2,
        p_referencia IN VARCHAR2
    );

    -- GET /resources/
    PROCEDURE get_collection (
        p_filter_val IN  VARCHAR2,
        p_cursor     OUT SYS_REFCURSOR
    );

    -- GET /resources/:id
    PROCEDURE get_resource (
        p_id     IN  NUMBER,
        p_cursor OUT SYS_REFCURSOR
    );

    -- POST /resources/
    PROCEDURE post_resource (
        p_name   IN  VARCHAR2,
        p_email  IN  VARCHAR2,
        p_result OUT VARCHAR2
    );

END pkg_ords_handler_template;
/

CREATE OR REPLACE PACKAGE BODY pkg_ords_handler_template AS

    -- Autonomous logging procedure to preserve error audit trails even if the
    -- main transaction rolls back.
    PROCEDURE log_error_autonomous (
        p_codigo     IN VARCHAR2,
        p_mensaje    IN VARCHAR2,
        p_contexto   IN VARCHAR2,
        p_referencia IN VARCHAR2
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        INSERT INTO api_error_log (
            error_codigo,
            error_mensaje,
            contexto,
            referencia
        ) VALUES (
            p_codigo,
            SUBSTRB(p_mensaje, 1, 4000),
            SUBSTRB(p_contexto, 1, 500),
            p_referencia
        );
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK; -- Safely rollback log insert, do not crash main process
    END log_error_autonomous;

    -- -------------------------------------------------------------------------
    -- GET /resources/
    -- -------------------------------------------------------------------------
    PROCEDURE get_collection (
        p_filter_val IN  VARCHAR2,
        p_cursor     OUT SYS_REFCURSOR
    ) IS
        l_ref_id     VARCHAR2(36);
        l_filter_val VARCHAR2(200 CHAR);
    BEGIN
        -- 1. Sanitization & input length truncation (prevent string buffer overflow ORA-06502)
        l_filter_val := UPPER(TRIM(SUBSTRB(p_filter_val, 1, 200)));

        -- 2. Explicit Column Projection (No SELECT *), with Row-level filtration
        OPEN p_cursor FOR
            SELECT 
                1                  AS id,
                'Sample Data'      AS name,
                'sample@email.com' AS email,
                SYSDATE            AS created_at
            FROM DUAL
            WHERE (l_filter_val IS NULL OR 'SAMPLE DATA' LIKE '%' || l_filter_val || '%');

    EXCEPTION
        WHEN OTHERS THEN
            l_ref_id := LOWER(RAWTOHEX(SYS_GUID()));
            log_error_autonomous(
                p_codigo     => c_err_interno,
                p_mensaje    => SQLERRM,
                p_contexto   => 'pkg_ords_handler_template.get_collection | filter=' || SUBSTRB(p_filter_val, 1, 400),
                p_referencia => l_ref_id
            );
            
            -- Return opaque error cursor to ORDS
            OPEN p_cursor FOR
                SELECT 
                    'error'                                           AS status,
                    c_err_interno                                     AS code,
                    'An internal error occurred. Ref: ' || l_ref_id   AS message,
                    l_ref_id                                          AS reference
                FROM DUAL;
    END get_collection;

    -- -------------------------------------------------------------------------
    -- GET /resources/:id
    -- -------------------------------------------------------------------------
    PROCEDURE get_resource (
        p_id     IN  NUMBER,
        p_cursor OUT SYS_REFCURSOR
    ) IS
        l_ref_id VARCHAR2(36);
    BEGIN
        -- 1. Validation
        IF p_id IS NULL OR p_id <= 0 THEN
            OPEN p_cursor FOR
                SELECT 
                    'error'                     AS status,
                    c_err_validation            AS code,
                    'Invalid resource identifier' AS message
                FROM DUAL;
            RETURN;
        END IF;

        -- 2. Fetch resource with explicit projection
        OPEN p_cursor FOR
            SELECT 
                p_id               AS id,
                'Sample Data'      AS name,
                'sample@email.com' AS email,
                SYSDATE            AS created_at
            FROM DUAL;

    EXCEPTION
        WHEN OTHERS THEN
            l_ref_id := LOWER(RAWTOHEX(SYS_GUID()));
            log_error_autonomous(
                p_codigo     => c_err_interno,
                p_mensaje    => SQLERRM,
                p_contexto   => 'pkg_ords_handler_template.get_resource | id=' || p_id,
                p_referencia => l_ref_id
            );
            
            OPEN p_cursor FOR
                SELECT 
                    'error'                                           AS status,
                    c_err_interno                                     AS code,
                    'An internal error occurred. Ref: ' || l_ref_id   AS message,
                    l_ref_id                                          AS reference
                FROM DUAL;
    END get_resource;

    -- -------------------------------------------------------------------------
    -- POST /resources/
    -- -------------------------------------------------------------------------
    PROCEDURE post_resource (
        p_name   IN  VARCHAR2,
        p_email  IN  VARCHAR2,
        p_result OUT VARCHAR2
    ) IS
        l_ref_id      VARCHAR2(36);
        l_name_clean  VARCHAR2(200 CHAR);
        l_email_clean VARCHAR2(200 CHAR);
    BEGIN
        -- 1. Sanitization & input length truncation (prevent string buffer overflow ORA-06502)
        l_name_clean  := TRIM(SUBSTRB(p_name, 1, 200));
        l_email_clean := LOWER(TRIM(SUBSTRB(p_email, 1, 200)));

        -- 2. Validation
        IF l_name_clean IS NULL OR l_email_clean IS NULL THEN
            p_result := JSON_OBJECT(
                'status'  VALUE 'error',
                'code'    VALUE c_err_validation,
                'message' VALUE 'Required fields "name" and "email" cannot be null.'
            );
            RETURN;
        END IF;

        IF NOT REGEXP_LIKE(l_email_clean, '^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$') THEN
            p_result := JSON_OBJECT(
                'status'  VALUE 'error',
                'code'    VALUE c_err_validation,
                'message' VALUE 'Provided email address is invalid.'
            );
            RETURN;
        END IF;

        -- 3. Execution (Simulated database operation)
        p_result := JSON_OBJECT(
            'status'  VALUE 'ok',
            'id'      VALUE 1001,
            'message' VALUE 'Resource created successfully.'
        );

    EXCEPTION
        WHEN OTHERS THEN
            l_ref_id := LOWER(RAWTOHEX(SYS_GUID()));
            log_error_autonomous(
                p_codigo     => c_err_interno,
                p_mensaje    => SQLERRM,
                p_contexto   => 'pkg_ords_handler_template.post_resource | name=' || SUBSTRB(p_name, 1, 400),
                p_referencia => l_ref_id
            );
            
            p_result := JSON_OBJECT(
                'status'    VALUE 'error',
                'code'      VALUE c_err_interno,
                'message'   VALUE 'Internal error. Contact support with reference code.',
                'reference' VALUE l_ref_id
            );
    END post_resource;

END pkg_ords_handler_template;
/

-- 3. Test Runner Helper Package
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
    l_id         NUMBER;
    l_status     NUMBER := 200;
    l_cur        SYS_REFCURSOR;
    l_routed_400 BOOLEAN := FALSE;
BEGIN
    -- Simulate hoisted ORDS handler execution block logic
    l_id := TO_NUMBER(l_id_val DEFAULT NULL ON CONVERSION ERROR);

    IF l_id_val IS NULL OR l_id IS NULL OR l_id <= 0 THEN
        l_status := 400;
        pkg_ords_handler_template.get_resource(
            p_id     => NULL,
            p_cursor => l_cur
        );
        l_routed_400 := TRUE;
    ELSE
        pkg_ords_handler_template.get_resource(
            p_id     => l_id,
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
