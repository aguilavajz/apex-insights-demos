-- =============================================================================
-- APEX Insights — Secure ORDS Handler Package Template
-- -----------------------------------------------------------------------------
-- Target Database: Oracle 19c / 21c
-- Target ORDS:     23.x / 24.x
-- Description:     Production-ready template implementing secure M2M ORDS
--                  endpoints using PL/SQL package encapsulation, rate limiting,
--                  and opaque error masking with autonomous transaction logs.
-- =============================================================================

-- 1. DATABASE TABLES (AUDIT & RATE LOGGING)
-- -----------------------------------------------------------------------------

CREATE TABLE api_error_log (
    log_id         NUMBER         GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    error_codigo   VARCHAR2(50)   NOT NULL,
    error_mensaje  VARCHAR2(4000),
    contexto       VARCHAR2(500),
    referencia     VARCHAR2(36)   NOT NULL,
    created_at     TIMESTAMP      DEFAULT SYSTIMESTAMP NOT NULL,
    created_by     VARCHAR2(100)  DEFAULT SYS_CONTEXT('USERENV','SESSION_USER')
);

CREATE INDEX idx_api_error_log_ref ON api_error_log (referencia);
CREATE INDEX idx_api_error_log_ts  ON api_error_log (created_at);

CREATE TABLE api_rate_log (
    log_id      NUMBER       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id   VARCHAR2(200) NOT NULL,
    endpoint    VARCHAR2(200) NOT NULL,
    peticion_ts TIMESTAMP    DEFAULT SYSTIMESTAMP NOT NULL
);

CREATE INDEX idx_rate_log_cliente_ts ON api_rate_log (client_id, peticion_ts DESC);


-- 2. RATE LIMITING ENGINE
-- -----------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE check_rate_limit (
    p_client_id   IN  VARCHAR2,
    p_endpoint    IN  VARCHAR2,
    p_max_per_min IN  NUMBER DEFAULT 60,
    p_allowed     OUT BOOLEAN
) AS
    l_count NUMBER;
BEGIN
    -- Count requests from client in the last 60 seconds
    SELECT COUNT(*)
      INTO l_count
      FROM api_rate_log
     WHERE client_id   = p_client_id
       AND endpoint    = p_endpoint
       AND peticion_ts >= SYSTIMESTAMP - INTERVAL '1' MINUTE;

    IF l_count >= p_max_per_min THEN
        p_allowed := FALSE;
    ELSE
        p_allowed := TRUE;
        -- Record this request
        INSERT INTO api_rate_log (client_id, endpoint)
        VALUES (p_client_id, p_endpoint);
        COMMIT;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        -- Fail-open: do not block clients if the rate limiter logging fails
        p_allowed := TRUE;
END check_rate_limit;
/


-- 3. TEMPLATE PACKAGE SPECIFICATION
-- -----------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE pkg_ords_handler_template AS

    -- Exception codes mapped to HTTP status codes
    c_err_validation CONSTANT VARCHAR2(30) := 'ERR_VALIDATION';
    c_err_not_found  CONSTANT VARCHAR2(30) := 'ERR_NOT_FOUND';
    c_err_interno    CONSTANT VARCHAR2(30) := 'ERR_INTERNO';

    -- GET /resources/
    PROCEDURE get_collection (
        p_filter_val IN  VARCHAR2,
        p_cursor     OUT SYS_REFCURSOR
    );

    -- GET /resources/:id
    PROCEDURE get_resource (
        p_id     IN  NUMBER,
        p_cursor OUT SYS_REFCURSOR
    );

    -- POST /resources/
    PROCEDURE post_resource (
        p_name   IN  VARCHAR2,
        p_email  IN  VARCHAR2,
        p_result OUT VARCHAR2
    );

END pkg_ords_handler_template;
/


-- 4. TEMPLATE PACKAGE BODY
-- -----------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE BODY pkg_ords_handler_template AS

    -- Autonomous logging procedure to preserve error audit trails even if the
    -- main transaction rolls back.
    PROCEDURE log_error_autonomous (
        p_codigo     IN VARCHAR2,
        p_mensaje    IN VARCHAR2,
        p_contexto   IN VARCHAR2,
        p_referencia IN VARCHAR2
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        INSERT INTO api_error_log (
            error_codigo,
            error_mensaje,
            contexto,
            referencia
        ) VALUES (
            p_codigo,
            p_mensaje,
            p_contexto,
            p_referencia
        );
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK; -- Safely rollback log insert, do not crash main process
    END log_error_autonomous;

    -- -------------------------------------------------------------------------
    -- GET /resources/
    -- -------------------------------------------------------------------------
    PROCEDURE get_collection (
        p_filter_val IN  VARCHAR2,
        p_cursor     OUT SYS_REFCURSOR
    ) IS
        l_ref_id     VARCHAR2(36);
        l_filter_val VARCHAR2(200);
    BEGIN
        -- 1. Sanitization
        l_filter_val := UPPER(TRIM(p_filter_val));

        -- 2. Explicit Column Projection (No SELECT *), with Row-level filtration
        OPEN p_cursor FOR
            SELECT 
                1                  AS id,
                'Sample Data'      AS name,
                'sample@email.com' AS email,
                SYSDATE            AS created_at
            FROM DUAL
            WHERE (l_filter_val IS NULL OR 'SAMPLE DATA' LIKE '%' || l_filter_val || '%');

    EXCEPTION
        WHEN OTHERS THEN
            l_ref_id := LOWER(RAWTOHEX(SYS_GUID()));
            log_error_autonomous(
                p_codigo     => c_err_interno,
                p_mensaje    => SQLERRM,
                p_contexto   => 'pkg_ords_handler_template.get_collection | filter=' || p_filter_val,
                p_referencia => l_ref_id
            );
            
            -- Return opaque error cursor to ORDS
            OPEN p_cursor FOR
                SELECT 
                    'error'                                           AS status,
                    c_err_interno                                     AS code,
                    'An internal error occurred. Ref: ' || l_ref_id   AS message,
                    l_ref_id                                          AS reference
                FROM DUAL;
    END get_collection;

    -- -------------------------------------------------------------------------
    -- GET /resources/:id
    -- -------------------------------------------------------------------------
    PROCEDURE get_resource (
        p_id     IN  NUMBER,
        p_cursor OUT SYS_REFCURSOR
    ) IS
        l_ref_id VARCHAR2(36);
    BEGIN
        -- 1. Validation
        IF p_id IS NULL OR p_id <= 0 THEN
            OPEN p_cursor FOR
                SELECT 
                    'error'                     AS status,
                    c_err_validation            AS code,
                    'Invalid resource identifier' AS message
                FROM DUAL;
            RETURN;
        END IF;

        -- 2. Fetch resource with explicit projection
        OPEN p_cursor FOR
            SELECT 
                p_id               AS id,
                'Sample Data'      AS name,
                'sample@email.com' AS email,
                SYSDATE            AS created_at
            FROM DUAL;

    EXCEPTION
        WHEN OTHERS THEN
            l_ref_id := LOWER(RAWTOHEX(SYS_GUID()));
            log_error_autonomous(
                p_codigo     => c_err_interno,
                p_mensaje    => SQLERRM,
                p_contexto   => 'pkg_ords_handler_template.get_resource | id=' || p_id,
                p_referencia => l_ref_id
            );
            
            OPEN p_cursor FOR
                SELECT 
                    'error'                                           AS status,
                    c_err_interno                                     AS code,
                    'An internal error occurred. Ref: ' || l_ref_id   AS message,
                    l_ref_id                                          AS reference
                FROM DUAL;
    END get_resource;

    -- -------------------------------------------------------------------------
    -- POST /resources/
    -- -------------------------------------------------------------------------
    PROCEDURE post_resource (
        p_name   IN  VARCHAR2,
        p_email  IN  VARCHAR2,
        p_result OUT VARCHAR2
    ) IS
        l_ref_id      VARCHAR2(36);
        l_name_clean  VARCHAR2(200);
        l_email_clean VARCHAR2(200);
    BEGIN
        -- 1. Sanitization
        l_name_clean  := TRIM(p_name);
        l_email_clean := LOWER(TRIM(p_email));

        -- 2. Validation
        IF l_name_clean IS NULL OR l_email_clean IS NULL THEN
            p_result := JSON_OBJECT(
                'status'  VALUE 'error',
                'code'    VALUE c_err_validation,
                'message' VALUE 'Required fields "name" and "email" cannot be null.'
            );
            RETURN;
        END IF;

        IF NOT REGEXP_LIKE(l_email_clean, '^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$') THEN
            p_result := JSON_OBJECT(
                'status'  VALUE 'error',
                'code'    VALUE c_err_validation,
                'message' VALUE 'Provided email address is invalid.'
            );
            RETURN;
        END IF;

        -- 3. Execution (Simulated database operation)
        p_result := JSON_OBJECT(
            'status'  VALUE 'ok',
            'id'      VALUE 1001,
            'message' VALUE 'Resource created successfully.'
        );

    EXCEPTION
        WHEN OTHERS THEN
            l_ref_id := LOWER(RAWTOHEX(SYS_GUID()));
            log_error_autonomous(
                p_codigo     => c_err_interno,
                p_mensaje    => SQLERRM,
                p_contexto   => 'pkg_ords_handler_template.post_resource | name=' || p_name,
                p_referencia => l_ref_id
            );
            
            p_result := JSON_OBJECT(
                'status'    VALUE 'error',
                'code'      VALUE c_err_interno,
                'message'   VALUE 'Internal error. Contact support with reference code.',
                'reference' VALUE l_ref_id
            );
    END post_resource;

END pkg_ords_handler_template;
/


-- 5. ORDS MODULE REGISTRATION AND ENABLEMENT SCRIPT
-- -----------------------------------------------------------------------------

/*
DECLARE
    -- The schema needs to be enabled for ORDS Base Path mapping.
    -- Execute this block in the schema owning the packages.
BEGIN
    ORDS.ENABLE_SCHEMA(
        p_enabled             => TRUE,
        p_schema              => USER,
        p_url_mapping_type    => 'BASE_PATH',
        p_url_mapping_pattern => 'demo-api',
        p_auto_rest_auth      => TRUE
    );

    -- 1. Define Module
    ORDS.DEFINE_MODULE(
        p_module_name    => 'resources.v1',
        p_base_path      => '/v1/resources/',
        p_items_per_page => 25,
        p_status         => 'PUBLISHED',
        p_comments       => 'Demo API for secure handler template implementation.'
    );

    -- 2. Define Template (Collection)
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'resources.v1',
        p_pattern        => '.',
        p_priority       => 0,
        p_etag_type      => 'HASH',
        p_comments       => 'Resource collection endpoints'
    );

    -- 3. Define GET Handler (Collection)
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'resources.v1',
        p_pattern        => '.',
        p_method         => 'GET',
        p_source_type    => ORDS.source_type_ref_cursor,
        p_items_per_page => 25,
        p_mimes_allowed  => 'application/json',
        p_comments       => 'List resources with optional filter.',
        p_source         => q'[
            DECLARE
                l_allowed   BOOLEAN;
                l_client_id VARCHAR2(200);
            BEGIN
                -- Resolve Client Identifier
                l_client_id := OWA_UTIL.get_cgi_env('HTTP_X_ORDS_CLIENT_ID');
                IF l_client_id IS NULL THEN
                    l_client_id := NVL(OWA_UTIL.get_cgi_env('REMOTE_ADDR'), 'anonymous');
                END IF;

                -- Rate Limit check (60 req/min)
                check_rate_limit(
                    p_client_id   => l_client_id,
                    p_endpoint    => '/v1/resources/',
                    p_max_per_min => 60,
                    p_allowed     => l_allowed
                );

                IF NOT l_allowed THEN
                    -- Hijack the output stream for 429 Rate Limit Response
                    -- Note: Handlers of source_type_ref_cursor expect a cursor.
                    -- In rate-limit cases, we return a cursor containing the error description.
                    :status := 429;
                    OPEN :resultset FOR
                        SELECT 
                            'error'                                     AS status,
                            'ERR_RATE_LIMIT'                            AS code,
                            'Too many requests. Try again in 1 minute.' AS message
                        FROM DUAL;
                    RETURN;
                END IF;

                -- Execute collection query
                pkg_ords_handler_template.get_collection(
                    p_filter_val => :filter,
                    p_cursor     => :resultset
                );
            END;
        ]'
    );

    -- 4. Define POST Handler (Create Resource)
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'resources.v1',
        p_pattern        => '.',
        p_method         => 'POST',
        p_source_type    => ORDS.source_type_plsql,
        p_mimes_allowed  => 'application/json',
        p_comments       => 'Create a new resource.',
        p_source         => q'[
            DECLARE
                l_allowed   BOOLEAN;
                l_client_id VARCHAR2(200);
                l_result    VARCHAR2(4000);
            BEGIN
                l_client_id := OWA_UTIL.get_cgi_env('HTTP_X_ORDS_CLIENT_ID');
                IF l_client_id IS NULL THEN
                    l_client_id := NVL(OWA_UTIL.get_cgi_env('REMOTE_ADDR'), 'anonymous');
                END IF;

                check_rate_limit(
                    p_client_id   => l_client_id,
                    p_endpoint    => '/v1/resources/',
                    p_max_per_min => 30, -- stricter limit for writing operations
                    p_allowed     => l_allowed
                );

                IF NOT l_allowed THEN
                    :status    := 429;
                    :resultado := JSON_OBJECT(
                        'status'  VALUE 'error',
                        'code'    VALUE 'ERR_RATE_LIMIT',
                        'message' VALUE 'Too many requests. Try again in 1 minute.'
                    );
                    RETURN;
                END IF;

                pkg_ords_handler_template.post_resource(
                    p_name   => :name,
                    p_email  => :email,
                    p_result => l_result
                );

                :resultado := l_result;
                
                IF JSON_VALUE(l_result, '$.status') = 'error' THEN
                    IF JSON_VALUE(l_result, '$.code') = 'ERR_VALIDATION' THEN
                        :status := 400;
                    ELSE
                        :status := 500;
                    END IF;
                ELSE
                    :status := 201;
                END IF;
            END;
        ]'
    );

    -- 5. Define Template & Handler for Individual Resource (GET /v1/resources/:id)
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'resources.v1',
        p_pattern        => ':id',
        p_priority       => 0,
        p_etag_type      => 'HASH',
        p_comments       => 'Individual resource resource endpoint'
    );

    ORDS.DEFINE_HANDLER(
        p_module_name    => 'resources.v1',
        p_pattern        => ':id',
        p_method         => 'GET',
        p_source_type    => ORDS.source_type_ref_cursor,
        p_items_per_page => 25,
        p_mimes_allowed  => 'application/json',
        p_comments       => 'Get individual resource details.',
        p_source         => q'[
            DECLARE
                l_allowed   BOOLEAN;
                l_client_id VARCHAR2(200);
            BEGIN
                l_client_id := OWA_UTIL.get_cgi_env('HTTP_X_ORDS_CLIENT_ID');
                IF l_client_id IS NULL THEN
                    l_client_id := NVL(OWA_UTIL.get_cgi_env('REMOTE_ADDR'), 'anonymous');
                END IF;

                check_rate_limit(
                    p_client_id   => l_client_id,
                    p_endpoint    => '/v1/resources/:id',
                    p_max_per_min => 60,
                    p_allowed     => l_allowed
                );

                IF NOT l_allowed THEN
                    :status := 429;
                    OPEN :resultset FOR
                        SELECT 
                            'error'                                     AS status,
                            'ERR_RATE_LIMIT'                            AS code,
                            'Too many requests. Try again in 1 minute.' AS message
                        FROM DUAL;
                    RETURN;
                END IF;

                pkg_ords_handler_template.get_resource(
                    p_id     => TO_NUMBER(:id),
                    p_cursor => :resultset
                );
            END;
        ]'
    );

    COMMIT;
END;
/
*/
