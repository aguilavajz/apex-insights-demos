## Zed - Comment Audit & Resolution Report

### Summary of Items Reviewed

Reviewed all observations and alternatives in comments [6746455750](https://github.com/aguilavajz/apex-insights-demos/pull/24#issuecomment-6746455750) and [6746460830](https://github.com/aguilavajz/apex-insights-demos/pull/24#issuecomment-6746460830): **8 items — 4 addressed, 3 justified/kept as is, 1 runtime-validation requirement deferred with the author's approval.**

**Delivery scope:** Audited original PR head `d25251bd06fc96dfe25b5c7ec91b52d2b3b9610d`. Fixes described below are included in the same change set as this report, with commit and push authorized by the author. Production code is unchanged. All file paths below are relative to `2026-01-27-automated-testing-utplsql/`.

### Detailed Breakdown

#### Issue 1: Duplicate unknown/invalid-code test
- **Status:** VALID - FIXED
- **Analysis:** `INVALID_CODE` and `INVALID` both return `100` through the same failed literal comparison. The additional arbitrary unknown string did not add a useful distinct contract.
- **Action Taken / Justification:** Replaced `calculate_total_unknown_code` with `calculate_total_lowercase_code` in `tests/ut_pkg_orders.sql`, asserting `calculate_total(100, 'welcome10') = 100`. Retained the existing invalid-code test.
- **Test Results:** Manual source review and static declaration/body checks passed. Earlier non-persistent Oracle smoke assertions confirmed the lowercase and invalid-code results. Updated utPLSQL execution remains unavailable.

#### Issue 2: Alternative removal/renaming request
- **Status:** VALID - FIXED
- **Analysis:** Removal/renaming was offered as an alternative to replacing the duplicate, not as a separate mandatory refactor.
- **Action Taken / Justification:** Replaced and renamed the procedure consistently in specification and body. Removed the obsolete unknown-code procedure and `INVALID_CODE` literal; the remaining invalid-code test retains its original name and purpose.
- **Test Results:** Static checks found seven unique test declarations and seven matching implementations, with no obsolete procedure or duplicate literal.

#### Issue 3: Case sensitivity characterized as a production defect
- **Status:** INVALID - KEPT AS IS
- **Analysis:** `src/pkg_orders.sql` directly compares `p_discount_code = 'WELCOME10'`. Neither comment establishes a requirement to accept case-insensitive codes. Existing case sensitivity alone is not sufficient evidence of a defect.
- **Action Taken / Justification:** Preserved production behavior rather than adding `UPPER` and changing the accepted-input contract in a testing PR. Documented the existing contract in README and added a regression case for lowercase input.
- **Test Results:** Earlier Oracle smoke assertions returned `90` for `WELCOME10` and `100` for `welcome10`. Manual tracing agrees: lowercase input skips the discount assignment.

#### Issue 4: Incorrect lowercase result and failing-test prediction
- **Status:** INVALID - KEPT AS IS
- **Analysis:** The first comment incorrectly predicted `90` and failure when expecting `100`; the follow-up explicitly corrects this to `100`. The correction is valid and was used throughout this audit.
- **Action Taken / Justification:** No production change for the retracted claim. The new lowercase test expects `100`, not `90`.
- **Test Results:** Manual tracing and the earlier Oracle smoke assertion both confirm `100` for lowercase input.

#### Issue 5: Missing near-miss scenario
- **Status:** VALID - FIXED
- **Analysis:** An unrelated invalid literal would not specifically protect against accidentally changing exact equality to prefix matching.
- **Action Taken / Justification:** Added `calculate_total_near_miss_code`, asserting `calculate_total(100, 'WELCOME100') = 100`.
- **Test Results:** Manual review confirms the near-miss differs from `WELCOME10` and skips the discount. The earlier Oracle smoke assertion passed. Updated utPLSQL execution remains unavailable.

#### Issue 6: Overstated coverage improvement
- **Status:** VALID - FIXED (documentation)
- **Analysis:** Arbitrary invalid, lowercase, and near-miss inputs all take the same existing comparison-false branch. Even the follow-up's statement that lowercase covers a different "path" is not literally correct as branch coverage; its value is a distinct input-contract regression check.
- **Action Taken / Justification:** README now explicitly distinguishes input-contract protection from new branch coverage and lists all seven expected tests instead of three. Example output is labeled illustrative, not an execution record. This report qualifies, rather than repeats, the original PR description's coverage claim.
- **Test Results:** Static checks confirm seven annotated procedures; manual inspection confirms the documented inputs/expectations match the test bodies. No measured coverage percentage is claimed.

#### Issue 7: Compatibility and utPLSQL convention observations
- **Status:** INVALID - KEPT AS IS (no compatibility defect identified)
- **Analysis:** The review's positive compatibility observation is confirmed: the business package signature and implementation are unchanged. The test specification/body remain consistent and use the existing `--%test`, `ut.expect`, and `--%throws(-20001)` patterns.
- **Action Taken / Justification:** No production/API refactor or dependency change. Kept the original valid-code, null-code, invalid-code, negative-amount, and zero-amount cases.
- **Test Results:** Static checks confirm matching declarations/implementations and retention of the negative exception annotation. This is not proof of runtime annotation discovery or package compilation under utPLSQL.

#### Issue 8: Execute the full suite before merge
- **Status:** VALID - DEFERRED (author-approved environment limitation; not marked fixed)
- **Analysis:** The concern remains valid. The author subsequently requested proceeding with manual testing because no suitable test connection is available.
- **Action Taken / Justification:** No further database access or framework installation. Earlier investigation found SQLcl available but utPLSQL inaccessible; running `scripts/run_tests.sql` failed before discovery with `ORA-06550` / `PLS-00201: identifier 'UT.RUN' must be declared` (exit code 2). The existing deployed test body also reported missing `UT.EXPECT`. No database objects were changed. The modified test package has not been deployed.
- **Test Results:** Manually traced all seven scenarios: `(100, WELCOME10) -> 90`, `(100, NULL) -> 100`, `(100, welcome10) -> 100`, `(100, WELCOME100) -> 100`, `(100, INVALID) -> 100`, `(-50, WELCOME10) -> -20001`, and `(0, WELCOME10) -> 0`. All match the test expectations. Earlier independent Oracle smoke assertions against the existing business package also passed all seven. Neither check substitutes for executing the updated utPLSQL package.

### Merge Conflict Verification

GitHub reports **MERGEABLE / CLEAN**. The fetched base branch is an ancestor of the audited PR head; no additional conflict resolution is needed. `git diff --check` passed. The PR branch is already checked out in another worktree, so these local edits were made at the exact PR head in detached HEAD without modifying that worktree.

### Final Test Execution Summary

- **Total Tests Executed:** 7 non-persistent Oracle smoke assertions earlier in this audit; **0 updated utPLSQL tests**.
- **Passed:** 7 smoke assertions | **Failed:** 0 smoke assertions.
- **Manual Review:** All seven scenarios traced successfully; test annotation/declaration/body consistency and whitespace checks passed. Manual review is not counted as additional runtime tests.
- **Full Suite:** Not completed. One utPLSQL runner attempt failed before discovery because `UT.RUN` was unavailable. Other repository SQL suites were not executed.
- **Coverage:** Not measured; no claim of new branch coverage or zero repository-wide regressions.
- **Status:** **ISSUES REMAINING** — full utPLSQL validation is deferred by author approval. The available checks passed, but this is not an ALL TESTS PASSING claim.
