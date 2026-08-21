-- 02_sample_data.sql
-- Insert sample data for testing

BEGIN
    -- Regions
    INSERT INTO regions (region_name) VALUES ('North America');
    INSERT INTO regions (region_name) VALUES ('Europe');
    INSERT INTO regions (region_name) VALUES ('Asia Pacific');
    INSERT INTO regions (region_name) VALUES ('Latin America');

    -- Generate random orders for the last 2 years
    INSERT INTO orders (customer_name, order_total, order_date, region_id)
    SELECT
        'Customer ' || LEVEL,
        ROUND(DBMS_RANDOM.VALUE(100, 5000), 2),
        TRUNC(SYSDATE - DBMS_RANDOM.VALUE(0, 730)), -- Random date in last 2 years
        ROUND(DBMS_RANDOM.VALUE(1, 4)) -- Random region 1-4
    FROM DUAL
    CONNECT BY LEVEL <= 1000;
    
    COMMIT;
END;
/
