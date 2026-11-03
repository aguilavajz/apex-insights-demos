-- =============================================================================
-- Demo: Dashboard Design Best Practices for Data Viz
-- Script: 02_data.sql
-- Description: Populates the demo tables with realistic test data.
-- Run this script after 01_tables.sql.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Opportunities — 240 records spread across 12 months
-- Optimized set-based INSERT using CONNECT BY LEVEL instead of PL/SQL loops
-- to eliminate PL/SQL engine context switching and improve script execution speed.
-- Uses deterministic logic for reproducible results.
-- -----------------------------------------------------------------------------
INSERT INTO demo_opportunities (
    owner_name,
    region,
    stage,
    amount,
    close_date
)
WITH params AS (
    SELECT
        LEVEL AS row_num,
        TRUNC((LEVEL - 1) / 20) AS month_offset,
        MOD(LEVEL - 1, 20) AS day_offset
    FROM DUAL
    CONNECT BY LEVEL <= 240
)
SELECT
    CASE MOD(row_num - 1, 5)
        WHEN 0 THEN 'Alice Morgan'
        WHEN 1 THEN 'Bob Chen'
        WHEN 2 THEN 'Carol Diaz'
        WHEN 3 THEN 'David Kim'
        WHEN 4 THEN 'Eva Torres'
    END AS owner_name,
    CASE MOD(day_offset, 5)
        WHEN 0 THEN 'NORTH'
        WHEN 1 THEN 'SOUTH'
        WHEN 2 THEN 'EAST'
        WHEN 3 THEN 'WEST'
        WHEN 4 THEN 'CENTRAL'
    END AS region,
    CASE MOD(row_num + month_offset, 8)
        WHEN 0 THEN 'Won'
        WHEN 1 THEN 'Won'
        WHEN 2 THEN 'Won'
        WHEN 3 THEN 'Lost'
        WHEN 4 THEN 'At Risk'
        WHEN 5 THEN 'Negotiation'
        WHEN 6 THEN 'Proposal'
        WHEN 7 THEN 'Qualification'
    END AS stage,
    ROUND((MOD(row_num * 7919 + day_offset * 1031, 245001) + 5000) / 100) * 100 AS amount,
    ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -month_offset) + MOD(day_offset * 3, 28) AS close_date
FROM params;

COMMIT;

-- Verification
SELECT
    stage,
    COUNT(*)         AS record_count,
    SUM(amount)      AS total_value,
    MIN(close_date)  AS earliest,
    MAX(close_date)  AS latest
FROM demo_opportunities
GROUP BY stage
ORDER BY record_count DESC;
