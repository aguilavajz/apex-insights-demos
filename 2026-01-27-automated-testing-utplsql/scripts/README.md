# scripts

## Overview
SQL*Plus / SQLcl runner scripts that compile the `pkg_orders` business logic and `ut_pkg_orders` test suite, verify object compilation status, and execute the `orders` utPLSQL suite.

## Interface
- `[install.sql:@../src/pkg_orders.sql]` — Compiles the `pkg_orders` package specification and body from `../src/pkg_orders.sql`.
- `[install.sql:@../tests/ut_pkg_orders.sql]` — Compiles the `ut_pkg_orders` test package from `../tests/ut_pkg_orders.sql`.
- `[install.sql:user_objects]` — Queries `user_objects` (`object_name`, `status`) filtered to `('PKG_ORDERS', 'UT_PKG_ORDERS')` ordered by `object_name`.
- `[run_tests.sql:ut.run]` — Executes `ut.run('orders')` in an anonymous PL/SQL block (`begin ut.run('orders'); end;`).

## Invariants
- `[install.sql:whenever sqlerror]` — Sets `whenever sqlerror exit sql.sqlcode failure`, aborting immediately on any compilation or SQL error.
- `[install.sql:define off]` — Disables substitution variables (`set define off`), verification output (`set verify off`), and row-count feedback (`set feedback off`), and expects invocation from the `scripts/` working directory because script paths use `../src/` and `../tests/`.
- `[run_tests.sql:ut.run]` — Expects utPLSQL (`ut.run`) to be installed and `ut_pkg_orders` compiled under `--%suitepath(orders)` with `set serveroutput on size unlimited format wrapped` and `set linesize 120`.

## Side Effects
- `[install.sql:define off]` — Modifies SQL*Plus / SQLcl session settings (`define`, `verify`, `feedback`, `whenever sqlerror`), compiles `PKG_ORDERS` and `UT_PKG_ORDERS` in the connected schema, queries `user_objects`, and prints status prompts to stdout.
- `[run_tests.sql:ut.run]` — Modifies SQL*Plus / SQLcl session settings (`serveroutput`, `linesize`), invokes `ut.run('orders')`, and writes test results to stdout via `DBMS_OUTPUT`.

## Verification
- Run: `CD scripts/` then `@install.sql` and `@run_tests.sql` in SQLcl or SQL*Plus.
