-- 02_sample_data.sql
-- Insert sample data for testing

WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE;

DECLARE
    l_cnt NUMBER;
BEGIN
    -- Prevent duplicate seeding and orphan regions
    SELECT COUNT(*) INTO l_cnt FROM regions;
    IF l_cnt > 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'regions already populated; clear before reseeding');
    END IF;

    -- Regions
    INSERT INTO regions (region_name) VALUES ('North America');
    INSERT INTO regions (region_name) VALUES ('Europe');
    INSERT INTO regions (region_name) VALUES ('Asia Pacific');
    INSERT INTO regions (region_name) VALUES ('Latin America');

    -- Generate random orders for the last 2 years using set-based INSERT
    INSERT INTO orders (customer_name, order_total, order_date, region_id)
    SELECT
        'Customer ' || LEVEL,
        ROUND(DBMS_RANDOM.VALUE(100, 5000), 2),
        TRUNC(SYSDATE - DBMS_RANDOM.VALUE(0, 730)), -- Random date in last 2 years
        TRUNC(DBMS_RANDOM.VALUE(1, 5))              -- Uniform random region 1-4
    FROM DUAL
    CONNECT BY LEVEL <= 1000;

    COMMIT;
END;
/
