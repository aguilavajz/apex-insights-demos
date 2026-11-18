## 2026-06-09 - ORDS Handler Input Truncation, Byte-Semantics, and Safe Conversion
**Vulnerability:** ORDS handlers directly assigned unrestricted HTTP query and body parameters (`p_filter_val`, `p_name`, `p_email`) to fixed-width `VARCHAR2(200)` variables, converted path parameter `:id` directly using `TO_NUMBER(:id)` without error handling, concatenated untruncated inputs into error logging contexts, and returned HTTP 200 for validation errors. Oversized inputs triggered unhandled `ORA-06502: numeric or value error: character string buffer too small`, non-numeric `:id` values triggered unhandled `ORA-01722: invalid number` exceptions, and long inputs caused `ORA-12899` in `api_error_log.contexto`, silently losing audit logs.
**Learning:** In PL/SQL ORDS REST handlers:
1. Incoming parameters are bound dynamically. Under `AL32UTF8` and default `NLS_LENGTH_SEMANTICS=BYTE`, character-based truncation (`SUBSTR`) allows multi-byte characters to exceed byte capacity, triggering `ORA-06502`.
2. Concatenating raw inputs in exception handling can exceed `VARCHAR2(500)` logging columns, triggering `ORA-12899` which rolls back autonomous audit log inserts silently.
3. In ORDS ref cursor handlers, failing to explicitly assign `:status := 400` defaults HTTP responses to 200 OK even when returning validation error structures.
4. Autonomous error logging procedures must be declared in the package specification so that handler blocks and test suites can invoke and verify logging behavior without `PLS-00302`. Hoisting parameter conversion to local variables avoids redundant parsing.
**Prevention:**
1. Truncate incoming string parameters using byte-aware truncation `SUBSTRB(p_param, 1, max_bytes)` and declare variables with explicit character semantics `VARCHAR2(max CHAR)` to safeguard against buffer overflows.
2. Truncate all parameters before concatenating into logging contexts (`SUBSTRB(p_param, 1, 400)`), and enforce defense-in-depth truncation (`SUBSTRB(p_contexto, 1, 500)`) inside `log_error_autonomous`.
3. Safely convert numeric path parameters using `TO_NUMBER(p_param DEFAULT NULL ON CONVERSION ERROR)` and explicitly assign `:status := 400` in ORDS handlers when validation fails.
4. Expose `log_error_autonomous` in package specifications for handler access and unit testability, and hoist conversions into a local variable (`l_id NUMBER`).
