# Automated Testing with utPLSQL (Demo)

## Overview
This directory contains a self-contained example of Unit Testing in PL/SQL using the [utPLSQL](https://utplsql.org/) framework.
It accompanies the article **"Automated Testing: utPLSQL for Backends"**.

## Subdirectories & Boundaries
- `scripts`: [scripts/README.md](./scripts/README.md) — SQL*Plus / SQLcl runner scripts (`install.sql`, `run_tests.sql`) that compile `pkg_orders` and `ut_pkg_orders`, query `user_objects`, and invoke `ut.run('orders')`.
- `src`: [src/README.md](./src/README.md) — Production PL/SQL package `pkg_orders` (`c_standard_discount`, `calculate_total`).
- `tests`: [tests/ut_pkg_orders.sql](./tests/ut_pkg_orders.sql) — Excluded test-only directory containing the `ut_pkg_orders` utPLSQL suite (`--%suitepath(orders)`).

## 🚀 Prerequisites

1. An Oracle Database (or APEX Service).
2. **utPLSQL v3.1.13+** installed in your database.
3. A user/schema with permissions to create packages.

## 🛠️ How to Run

1. Connect to your database schema (via SQLcl or SQL*Plus).
2. Run the installation script:

    ```sql
    CD scripts/
    @install.sql
    ```

3. Run the tests:

    ```sql
    @run_tests.sql
    ```

## 📊 Expected Output

Running `@run_tests.sql` executes the 4 `--%test` procedures defined in [`tests/ut_pkg_orders.sql`](./tests/ut_pkg_orders.sql):
- `calculate_total_valid` — `Calculate Total - Valid Discount` (`100`, `'WELCOME10'` -> `90`)
- `calculate_total_null_code` — `Calculate Total - Null Code / No Discount` (`100`, `null` -> `100`)
- `calculate_total_invalid_code` — `Calculate Total - Invalid Discount Code` (`100`, `'INVALID'` -> `100`)
- `calculate_total_invalid_amount` — `Calculate Total - Negative Amount raises valid error` (`-50`, `'WELCOME10'` -> `--%throws(-20001)`)

Illustrative utPLSQL output (4 tests passing, 0 failed):

```text
orders
  Orders Package Tests
    Calculate Total - Valid Discount [.002 sec]
    Calculate Total - Null Code / No Discount [.001 sec]
    Calculate Total - Invalid Discount Code [.001 sec]
    Calculate Total - Negative Amount raises valid error [.001 sec]

Finished in .005 seconds
4 tests, 0 failed, 0 errored, 0 disabled, 0 warning(s)
```
