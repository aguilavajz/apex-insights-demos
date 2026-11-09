# Automated Testing with utPLSQL (Demo)

This directory contains a self-contained example of Unit Testing in PL/SQL using the [utPLSQL](https://utplsql.org/) framework.
It accompanies the article **"Automated Testing: utPLSQL for Backends"**.

## 📂 Structure

* `src/`: Contains the business logic (`pkg_orders`).
* `tests/`: Contains the test suite (`ut_pkg_orders`).
* `scripts/`: Helper scripts to install and run.

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

## Discount Code Contract

The demo preserves the existing literal, case-sensitive comparison with
`WELCOME10`. For an amount of `100`, that code returns `90`; lowercase
`welcome10`, the near-miss `WELCOME100`, an unrelated code, and `NULL` return
`100`. The lowercase and near-miss tests protect this input contract against
case normalization or prefix matching; they do not add new execution branches.

## 📊 Expected Output

The suite contains 7 tests. The following is illustrative expected output, not
an execution record; timings depend on your database:

```text
Running orders_suite...
Orders Package Tests
  Calculate Total - Valid Discount [.002 sec] (OK)
  Calculate Total - Null Code / No Discount [.001 sec] (OK)
  Calculate Total - Lowercase Code / No Discount [.001 sec] (OK)
  Calculate Total - Near-Miss Code / No Discount [.001 sec] (OK)
  Calculate Total - Invalid Discount Code [.001 sec] (OK)
  Calculate Total - Negative Amount raises valid error [.001 sec] (OK)
  Calculate Total - Zero Amount [.001 sec] (OK)

7 tests, 0 failed, 0 errored, 0 disabled, 0 warning(s)
```
