-- =============================================================================
-- Demo: Dashboard Design Best Practices for Data Viz
-- Script: 01_tables.sql
-- Description: Creates the database objects required for the demo.
-- Run this script first, before 02_data.sql.
-- =============================================================================

-- Drop tables if they exist from a previous installation
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE demo_opportunities PURGE';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE demo_kpi_thresholds PURGE';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- -----------------------------------------------------------------------------
-- Main fact table: sales opportunities
-- Simulates a real-world CRM dataset for dashboard patterns.
-- -----------------------------------------------------------------------------
CREATE TABLE demo_opportunities (
    opportunity_id  NUMBER         GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    owner_name      VARCHAR2(100)  NOT NULL,
    region          VARCHAR2(50)   NOT NULL,
    stage           VARCHAR2(30)   NOT NULL
        CONSTRAINT chk_opp_stage CHECK (
            stage IN ('Prospecting','Qualification','Proposal',
                      'Negotiation','Won','Lost','At Risk')
        ),
    amount          NUMBER(12,2)   NOT NULL,
    close_date      DATE           NOT NULL,
    created_at      DATE           DEFAULT SYSDATE NOT NULL
);

-- Indexes for dashboard filter columns (P1_REGION, P1_OWNER, P1_PERIOD)
CREATE INDEX idx_opp_region     ON demo_opportunities (region);
CREATE INDEX idx_opp_owner      ON demo_opportunities (owner_name);
CREATE INDEX idx_opp_close_date ON demo_opportunities (close_date);
CREATE INDEX idx_opp_stage      ON demo_opportunities (stage);

-- -----------------------------------------------------------------------------
-- Configuration table: KPI alert thresholds
-- Used by KPI card queries to drive semantic color (u-success/u-warning/u-danger).
-- -----------------------------------------------------------------------------
CREATE TABLE demo_kpi_thresholds (
    kpi_name          VARCHAR2(50)  NOT NULL PRIMARY KEY,
    warn_threshold    NUMBER        NOT NULL,
    danger_threshold  NUMBER        NOT NULL,
    description       VARCHAR2(200)
);
