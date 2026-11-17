## 2026-05-11 - Set-based Data Generation in Oracle PL/SQL

**Learning:** Replacing procedural PL/SQL loops (`FOR month IN ... LOOP FOR day IN ... LOOP INSERT INTO ...`) with single set-based SQL `INSERT INTO ... SELECT ... FROM DUAL CONNECT BY LEVEL` eliminates PL/SQL-to-SQL context switching overhead and allows the database SQL engine to execute bulk population in a single set-based pass.

**Action:** Whenever populating test or demo data in Oracle database scripts, construct `INSERT INTO ... SELECT ... CONNECT BY LEVEL <= N` statements using CTEs (`WITH params AS ...`) and `CASE` or expressions instead of PL/SQL procedural loops.
