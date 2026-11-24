# src

## Overview
Production PL/SQL source package for the Automated Testing with utPLSQL demo (`2026-01-27-automated-testing-utplsql`), implementing deterministic order discount calculation.

## Interface
- `[pkg_orders.sql:pkg_orders]` — PL/SQL package specification and body (`create or replace package pkg_orders` / `package body pkg_orders`).
- `[pkg_orders.sql:c_standard_discount]` — Public constant (`constant number := 0.10`), representing a 10% discount rate.
- `[pkg_orders.sql:calculate_total]` — Public function `calculate_total(p_amount in number, p_discount_code in varchar2 default null) return number`.

## Invariants
- `[pkg_orders.sql:c_standard_discount]` — Standard discount rate is fixed at `0.10`.
- `[pkg_orders.sql:calculate_total]` — Raises application error `-20001` (`'Order amount cannot be negative'`) whenever `p_amount < 0`.
- `[pkg_orders.sql:calculate_total]` — Applies `c_standard_discount` (`l_total - (l_total * c_standard_discount)`) only when `p_discount_code = 'WELCOME10'`; `null` or any other code returns `p_amount` unchanged.

## Side Effects
- `[pkg_orders.sql:pkg_orders]` — Compiling the DDL script creates or replaces `pkg_orders` in the connected schema; calling `calculate_total` at runtime has `None` (pure computation with no DML, commits, or package-state mutation).

## Verification
- Run: `CD scripts/` then `@install.sql` and `@run_tests.sql` in SQLcl or SQL*Plus.
