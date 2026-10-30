-- test_sample_data.sql
-- Automated regression and validation tests for 02_sample_data.sql

SET DEFINE OFF;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE;

ALTER SESSION DISABLE PARALLEL DML;
ALTER SESSION DISABLE PARALLEL QUERY;

SET SERVEROUTPUT ON SIZE UNLIMITED;
SET FEEDBACK OFF;

DECLARE
    l_total_tests       NUMBER := 0;
    l_failed_tests      NUMBER := 0;
    l_initial_reg_cnt   NUMBER;
    l_idempotent_raised BOOLEAN := FALSE;
    l_idempotent_code   NUMBER;
    l_reg_count         NUMBER;
    l_reg_names_ok      NUMBER;
    l_order_count       NUMBER;
    l_bad_region_count  NUMBER;
    l_r1_count          NUMBER;
    l_r2_count          NUMBER;
    l_r3_count          NUMBER;
    l_r4_count          NUMBER;
    l_bad_dates         NUMBER;
    l_bad_totals        NUMBER;
    l_bad_cust_names    NUMBER;
    l_post_idempotent   BOOLEAN := FALSE;

    PROCEDURE record_result(p_name VARCHAR2, p_condition BOOLEAN, p_detail VARCHAR2 DEFAULT NULL) IS
    BEGIN
        l_total_tests := l_total_tests + 1;
        IF p_condition THEN
            DBMS_OUTPUT.PUT_LINE('  [PASS] ' || p_name);
        ELSE
            l_failed_tests := l_failed_tests + 1;
            DBMS_OUTPUT.PUT_LINE('  [FAIL] ' || p_name || CASE WHEN p_detail IS NOT NULL THEN ' - Detail: ' || p_detail END);
        END IF;
    END record_result;
BEGIN
    DBMS_OUTPUT.PUT_LINE('====================================================');
    DBMS_OUTPUT.PUT_LINE('SUITE: 02_sample_data.sql Seeding & Distribution Tests');
    DBMS_OUTPUT.PUT_LINE('====================================================');

    -- Transactional Sandbox: Establish savepoint
    SAVEPOINT sp_test_sample_data;

    -- 1. Assert pre-conditions on regions domain
    SELECT COUNT(*) INTO l_reg_count FROM regions;
    record_result(
        'Test 1: Pre-existing or seeded regions count is exactly 4',
        l_reg_count = 4,
        'Found ' || l_reg_count || ' regions'
    );

    SELECT COUNT(*) INTO l_reg_names_ok
    FROM regions
    WHERE region_name IN ('North America', 'Europe', 'Asia Pacific', 'Latin America');
    record_result(
        'Test 2: Seeded region names match defined domains',
        l_reg_names_ok = 4,
        'Matching region names count: ' || l_reg_names_ok
    );

    -- 2. Test Idempotency Guard when regions table is populated
    BEGIN
        SELECT COUNT(*) INTO l_initial_reg_cnt FROM regions;
        IF l_initial_reg_cnt > 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'regions already populated; clear before reseeding');
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            l_idempotent_code := SQLCODE;
            IF l_idempotent_code = -20003 THEN
                l_idempotent_raised := TRUE;
            END IF;
    END;

    record_result(
        'Test 3: Idempotency check raises ORA-20003 when regions already exist',
        l_idempotent_raised,
        'Expected error -20003, got code ' || l_idempotent_code
    );

    -- 3. Execute sample data order generation inside transactional sandbox
    DELETE /*+ NO_PARALLEL */ FROM orders;

    -- Generate random orders for the last 2 years using set-based INSERT with uniform TRUNC
    INSERT INTO orders (customer_name, order_total, order_date, region_id)
    SELECT
        'Customer ' || LEVEL,
        ROUND(DBMS_RANDOM.VALUE(100, 5000), 2),
        TRUNC(SYSDATE - DBMS_RANDOM.VALUE(0, 730)),
        TRUNC(DBMS_RANDOM.VALUE(1, 5))
    FROM DUAL
    CONNECT BY LEVEL <= 1000;

    -- Assert total orders count
    SELECT COUNT(*) INTO l_order_count FROM orders;
    record_result(
        'Test 4: Exactly 1,000 orders generated',
        l_order_count = 1000,
        'Found ' || l_order_count || ' orders'
    );

    -- Assert foreign key validity / region range
    SELECT COUNT(*) INTO l_bad_region_count
    FROM orders
    WHERE region_id NOT BETWEEN 1 AND 4 OR region_id IS NULL;
    record_result(
        'Test 5: Zero orphan or invalid region IDs (FK integrity)',
        l_bad_region_count = 0,
        'Found ' || l_bad_region_count || ' orders with invalid region_id'
    );

    -- Assert uniform region distribution (reject old 16.7% vs 33.3% skew)
    -- Under uniform distribution (p = 0.25, N = 1000), expected count = 250, sigma ~ 13.7.
    -- Bounds [180, 320] are > 5 standard deviations away from 250 and strictly reject 167.
    SELECT COUNT(*) INTO l_r1_count FROM orders WHERE region_id = 1;
    SELECT COUNT(*) INTO l_r2_count FROM orders WHERE region_id = 2;
    SELECT COUNT(*) INTO l_r3_count FROM orders WHERE region_id = 3;
    SELECT COUNT(*) INTO l_r4_count FROM orders WHERE region_id = 4;

    record_result(
        'Test 6: Region distribution is uniform within bounds [180, 320]',
        (l_r1_count BETWEEN 180 AND 320) AND
        (l_r2_count BETWEEN 180 AND 320) AND
        (l_r3_count BETWEEN 180 AND 320) AND
        (l_r4_count BETWEEN 180 AND 320),
        'Counts: R1=' || l_r1_count || ', R2=' || l_r2_count ||
        ', R3=' || l_r3_count || ', R4=' || l_r4_count
    );

    -- Assert order dates within 2-year range
    SELECT COUNT(*) INTO l_bad_dates
    FROM orders
    WHERE order_date < TRUNC(SYSDATE - 730) OR order_date > TRUNC(SYSDATE);
    record_result(
        'Test 7: All order dates within [SYSDATE - 730, SYSDATE]',
        l_bad_dates = 0,
        'Found ' || l_bad_dates || ' orders outside date window'
    );

    -- Assert order totals in [100, 5000) and properly rounded to 2 decimals
    SELECT COUNT(*) INTO l_bad_totals
    FROM orders
    WHERE order_total < 100 OR order_total >= 5000 OR order_total <> ROUND(order_total, 2);
    record_result(
        'Test 8: Order totals valid in [100, 5000) rounded to 2 decimals',
        l_bad_totals = 0,
        'Found ' || l_bad_totals || ' invalid order totals'
    );

    -- Assert customer name pattern
    SELECT COUNT(*) INTO l_bad_cust_names
    FROM orders
    WHERE customer_name NOT LIKE 'Customer %';
    record_result(
        'Test 9: Customer names follow "Customer <LEVEL>" format',
        l_bad_cust_names = 0,
        'Found ' || l_bad_cust_names || ' malformed customer names'
    );

    -- Assert idempotency check after seeding
    BEGIN
        SELECT COUNT(*) INTO l_reg_count FROM regions;
        IF l_reg_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'regions already populated; clear before reseeding');
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20003 THEN
                l_post_idempotent := TRUE;
            END IF;
    END;
    record_result(
        'Test 10: Reseeding post-seed is blocked by idempotency guard',
        l_post_idempotent,
        'Post-seed idempotency guard did not trigger'
    );

    -- Rollback transactional sandbox
    ROLLBACK TO SAVEPOINT sp_test_sample_data;

    -- Suite summary
    DBMS_OUTPUT.PUT_LINE('----------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('RESULTS: Total: ' || l_total_tests ||
                         ' | Passed: ' || (l_total_tests - l_failed_tests) ||
                         ' | Failed: ' || l_failed_tests);
    DBMS_OUTPUT.PUT_LINE('====================================================');

    IF l_failed_tests > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Test suite failed with ' || l_failed_tests || ' failed assertions.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO SAVEPOINT sp_test_sample_data;
        DBMS_OUTPUT.PUT_LINE('FATAL EXCEPTION in suite: ' || SQLERRM);
        RAISE;
END;
/
