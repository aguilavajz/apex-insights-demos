# Automated Testing with utPLSQL (Demo)

This directory contains a self-contained example of Unit Testing in PL/SQL using the [utPLSQL](https://utplsql.org/) framework.
It accompanies the article **"Automated Testing: utPLSQL for Backends"**.

## 📂 Structure

* `src/`: Contains the discount schema (`schema_discounts.sql`) and business logic (`pkg_orders.sql`).
* `tests/`: Contains the test suite (`ut_pkg_orders.sql`).
* `scripts/`: Helper scripts to install (`install.sql`) and run (`run_tests.sql`).

## 🚀 Prerequisites

1. An Oracle Database (or APEX Service).
2. **utPLSQL v3.1.13+** installed in your database.
3. A user/schema with permissions to create tables and packages.

## 🛠️ How to Run

1. Connect to your database schema (via SQLcl or SQL*Plus).
2. Run the installation script (creates the `discounts` table, seeds `'WELCOME10'`, and compiles `pkg_orders` and `ut_pkg_orders`):

    ```sql
    CD scripts/
    @install.sql
    ```

3. Run the tests:

    ```sql
    @run_tests.sql
    ```

## Discount Code Contract

`pkg_orders.calculate_total` looks up discount factors in the `discounts` table (`src/schema_discounts.sql`), which enforces `0 < discount_factor < 1` (rejecting `0` and `1` boundary values) and seeds `WELCOME10` (`0.10`). Existing deployments must install `src/schema_discounts.sql` (or run `scripts/install.sql`) before compiling `src/pkg_orders.sql`.

The lookup preserves an exact, case-sensitive comparison against `discounts.discount_code` without case normalization or whitespace trimming. For an amount of `100`, `WELCOME10` returns `90`; a second seeded code such as `SAVE20` (`0.20`) on `200` returns `160`; lowercase `welcome10`, whitespace-padded `' WELCOME10 '`, the near-miss `WELCOME100`, an unrelated code (`INVALID`), and `NULL` return `100`.

## 📊 Expected Output

The suite contains 9 tests. The following is illustrative expected output, not
an execution record; timings depend on your database:

```text
Running orders_suite...
Orders Package Tests
  Calculate Total - Valid Discount [.002 sec] (OK)
  Calculate Total - Second Valid Discount Code [.001 sec] (OK)
  Calculate Total - Null Code / No Discount [.001 sec] (OK)
  Calculate Total - Lowercase Code / No Discount [.001 sec] (OK)
  Calculate Total - Whitespace Code / No Discount [.001 sec] (OK)
  Calculate Total - Near-Miss Code / No Discount [.001 sec] (OK)
  Calculate Total - Invalid Discount Code [.001 sec] (OK)
  Calculate Total - Negative Amount raises valid error [.001 sec] (OK)
  Calculate Total - Zero Amount [.001 sec] (OK)

Finished in .00612 seconds
9 tests, 0 failed, 0 errored, 0 disabled, 0 warning(s)
```
