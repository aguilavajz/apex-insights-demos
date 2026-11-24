# 2026-06-09-ords-professional-patterns

## Overview
Oracle REST Data Services (ORDS) professional handler template (`ords_handler_template.sql`) demonstrating structured audit error logging, per-client sliding-window rate limiting, input sanitization/validation, explicit projection without `SELECT *`, opaque internal error references, and commented ORDS REST module/template/handler registration blocks.

## Interface
- `[ords_handler_template.sql:api_error_log]` — Audit table (`log_id` identity PK, `error_codigo`, `error_mensaje`, `contexto`, `referencia`, `created_at`, `created_by`) with indexes `idx_api_error_log_ref` (`referencia`) and `idx_api_error_log_ts` (`created_at`).
- `[ords_handler_template.sql:api_rate_log]` — Rate-limiting log table (`log_id` identity PK, `client_id`, `endpoint`, `peticion_ts`) with index `idx_rate_log_cliente_ts` (`client_id`, `peticion_ts DESC`).
- `[ords_handler_template.sql:check_rate_limit]` — Standalone PL/SQL procedure `(p_client_id IN VARCHAR2, p_endpoint IN VARCHAR2, p_max_per_min IN NUMBER DEFAULT 60, p_allowed OUT BOOLEAN)`.
- `[ords_handler_template.sql:pkg_ords_handler_template]` — PL/SQL package exposing:
  - Constants: `c_err_validation` (`'ERR_VALIDATION'`), `c_err_not_found` (`'ERR_NOT_FOUND'`), `c_err_interno` (`'ERR_INTERNO'`).
  - `get_collection(p_filter_val IN VARCHAR2, p_cursor OUT SYS_REFCURSOR)` — Opens `p_cursor` with `id, name, email, created_at` from `DUAL` (or opaque error row on exception).
  - `get_resource(p_id IN NUMBER, p_cursor OUT SYS_REFCURSOR)` — Validates `p_id` and opens `p_cursor` with `id, name, email, created_at` from `DUAL` (or validation/internal error row).
  - `post_resource(p_name IN VARCHAR2, p_email IN VARCHAR2, p_result OUT VARCHAR2)` — Validates and sanitizes inputs, returning `JSON_OBJECT` string (`status`, `id`, `message` on success; `status`, `code`, `message` on validation error; `status`, `code`, `message`, `reference` on internal error).
- `[ords_handler_template.sql:ORDS.ENABLE_SCHEMA]` / `[ords_handler_template.sql:ORDS.DEFINE_MODULE]` / `[ords_handler_template.sql:ORDS.DEFINE_TEMPLATE]` / `[ords_handler_template.sql:ORDS.DEFINE_HANDLER]` — Commented-out ORDS setup script defining module `'resources.v1'` (`p_base_path => '/v1/resources/'`, `p_url_mapping_pattern => 'demo-api'`, `p_auto_rest_auth => TRUE`) with templates `'.'` (`GET` 60 req/min, `POST` 30 req/min) and `':id'` (`GET` 60 req/min).

## Invariants
- `[ords_handler_template.sql:check_rate_limit]` — Enforces a 1-minute sliding window (`peticion_ts >= SYSTIMESTAMP - INTERVAL '1' MINUTE`) per `(p_client_id, p_endpoint)`, setting `p_allowed := FALSE` when `l_count >= p_max_per_min`; fails open (`p_allowed := TRUE`) in `WHEN OTHERS`.
- `[ords_handler_template.sql:pkg_ords_handler_template.log_error_autonomous]` — Runs under `PRAGMA AUTONOMOUS_TRANSACTION` and performs `ROLLBACK` on `WHEN OTHERS` so logging failures never abort caller responses.
- `[ords_handler_template.sql:pkg_ords_handler_template.get_resource]` — Rejects `p_id IS NULL OR p_id <= 0` with `c_err_validation`.
- `[ords_handler_template.sql:pkg_ords_handler_template.post_resource]` — Trims `p_name`, lowercases/trims `p_email`, rejects `NULL` inputs or emails failing `REGEXP_LIKE '^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$'` with `c_err_validation`.
- `[ords_handler_template.sql:pkg_ords_handler_template]` — Unhandled exceptions generate an opaque `LOWER(RAWTOHEX(SYS_GUID()))` reference ID returned to the client while full `SQLERRM` is persisted only in `api_error_log`.
- `[ords_handler_template.sql:ORDS.DEFINE_HANDLER]` — Commented handlers derive `client_id` from `HTTP_X_ORDS_CLIENT_ID` falling back to `NVL(OWA_UTIL.get_cgi_env('REMOTE_ADDR'), 'anonymous')`, and map `POST '.'` responses to HTTP `400` (`ERR_VALIDATION`), `500` (other errors), `429` (rate limit), or `201` (created).

## Side Effects
- `[ords_handler_template.sql:api_error_log]` / `[ords_handler_template.sql:api_rate_log]` — Executing the DDL creates tables `api_error_log` and `api_rate_log` plus three indexes (`idx_api_error_log_ref`, `idx_api_error_log_ts`, `idx_rate_log_cliente_ts`), and compiles `check_rate_limit` and `pkg_ords_handler_template`.
- `[ords_handler_template.sql:check_rate_limit]` — Inserts a row into `api_rate_log` and executes `COMMIT` whenever `l_count < p_max_per_min`.
- `[ords_handler_template.sql:pkg_ords_handler_template.log_error_autonomous]` — Inserts an error row into `api_error_log` and commits inside an autonomous transaction on unhandled exceptions.
- `[ords_handler_template.sql:ORDS.ENABLE_SCHEMA]` — When uncommented and run, enables ORDS on `USER`, registers module `'resources.v1'` and handlers, and executes `COMMIT`.

## Verification
- Run: Execute `@ords_handler_template.sql` in SQLcl or Oracle APEX SQL Workshop (optionally uncommenting the ORDS registration block in an ORDS-enabled schema to test `GET /ords/demo-api/v1/resources/`, `POST /ords/demo-api/v1/resources/`, and `GET /ords/demo-api/v1/resources/:id`).
