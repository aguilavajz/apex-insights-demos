-- 02_sample_data.sql
-- Insert sample data for testing

WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE;

CREATE OR REPLACE PROCEDURE seed_dynamic_charts_data(p_commit BOOLEAN DEFAULT TRUE) IS
    l_cnt NUMBER;
BEGIN
    -- Prevent duplicate seeding and orphan regions
    SELECT COUNT(*) INTO l_cnt FROM regions;
    IF l_cnt > 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'regions table is already populated. To reseed, delete all rows from orders and regions, or re-run 01_schema.sql.');
    END IF;

    -- Seed standard regions
    INSERT INTO regions (region_name) VALUES ('North America');
    INSERT INTO regions (region_name) VALUES ('Europe');
    INSERT INTO regions (region_name) VALUES ('Asia Pacific');
    INSERT INTO regions (region_name) VALUES ('Latin America');

    -- Generate random orders for the last 2 years using set-based INSERT
    -- Region IDs are derived dynamically via ROW_NUMBER() to guarantee valid FKs
    -- and an exact 25% uniform distribution regardless of identity sequence state.
    INSERT INTO orders (customer_name, order_total, order_date, region_id)
    SELECT
        g.cname,
        g.total,
        g.odate,
        r.region_id
    FROM (
        SELECT
            'Customer ' || LEVEL AS cname,
            ROUND(DBMS_RANDOM.VALUE(100, 5000), 2) AS total,
            TRUNC(SYSDATE - DBMS_RANDOM.VALUE(0, 730)) AS odate,
            TRUNC(DBMS_RANDOM.VALUE(1, 5)) AS target_rn
        FROM DUAL
        CONNECT BY LEVEL <= 1000
    ) g
    JOIN (
        SELECT region_id, ROW_NUMBER() OVER (ORDER BY region_id) AS rn
        FROM regions
    ) r ON r.rn = g.target_rn;

    IF p_commit THEN
        COMMIT;
    END IF;
END seed_dynamic_charts_data;
/

-- Default execution when running this script directly
BEGIN
    seed_dynamic_charts_data(p_commit => TRUE);
END;
/
