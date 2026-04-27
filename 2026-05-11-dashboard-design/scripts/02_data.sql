-- =============================================================================
-- Demo: Dashboard Design Best Practices for Data Viz
-- Script: 02_data.sql
-- Description: Populates the demo tables with realistic test data.
-- Run this script after 01_tables.sql.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- KPI Thresholds
-- -----------------------------------------------------------------------------
INSERT INTO demo_kpi_thresholds (kpi_name, warn_threshold, danger_threshold, description)
VALUES ('AT_RISK_COUNT', 5, 10, 'Number of At Risk opportunities');

INSERT INTO demo_kpi_thresholds (kpi_name, warn_threshold, danger_threshold, description)
VALUES ('OVERDUE_COUNT', 3, 8, 'Deals past close_date with open stage');

COMMIT;

-- -----------------------------------------------------------------------------
-- Opportunities — 240 records spread across 12 months
-- Uses deterministic logic (no DBMS_RANDOM) for reproducible results.
-- -----------------------------------------------------------------------------
DECLARE
    TYPE t_owners  IS TABLE OF VARCHAR2(100);
    TYPE t_regions IS TABLE OF VARCHAR2(50);
    TYPE t_stages  IS TABLE OF VARCHAR2(30);

    l_owners  t_owners  := t_owners('Alice Morgan','Bob Chen','Carol Diaz','David Kim','Eva Torres');
    l_regions t_regions := t_regions('NORTH','SOUTH','EAST','WEST','CENTRAL');
    l_stages  t_stages  := t_stages(
        'Won','Won','Won',           -- 3x Won  (~37.5% closed-won)
        'Lost',                      -- 1x Lost  (~12.5%)
        'At Risk',                   -- 1x At Risk
        'Negotiation',               -- 1x Negotiation
        'Proposal',                  -- 1x Proposal
        'Qualification'              -- 1x Qualification
    );

    l_amount     NUMBER;
    l_close_date DATE;
    l_months_ago NUMBER;
    l_row        NUMBER := 0;
BEGIN
    FOR month_offset IN 0..11 LOOP                    -- 12 months back
        FOR day_offset IN 0..19 LOOP                  -- 20 records per month
            l_row := l_row + 1;

            -- Spread close_date across the month (every ~1.5 days)
            l_months_ago := month_offset;
            l_close_date := ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -l_months_ago)
                            + MOD(day_offset * 3, 28);  -- days 0,3,6...27

            -- Vary amounts realistically: $5k–$250k
            l_amount := ROUND(
                (MOD(l_row * 7919 + day_offset * 1031, 245001) + 5000) / 100
            ) * 100;

            INSERT INTO demo_opportunities (
                owner_name,
                region,
                stage,
                amount,
                close_date
            ) VALUES (
                l_owners(MOD(l_row - 1, 5) + 1),
                l_regions(MOD(day_offset, 5) + 1),
                l_stages(MOD(l_row + month_offset, 8) + 1),
                l_amount,
                l_close_date
            );
        END LOOP;
    END LOOP;
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Inserted ' || l_row || ' opportunity records.');
END;
/

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
