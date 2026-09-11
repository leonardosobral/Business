BEGIN;

CREATE TABLE IF NOT EXISTS public.tb_business_remember_devices (
    selector char(32) PRIMARY KEY CHECK (selector ~ '^[a-f0-9]{32}$'),
    user_id integer NOT NULL REFERENCES public.tb_usuarios(id) ON DELETE CASCADE,
    google_subject varchar(255) NOT NULL,
    email varchar(256) NOT NULL,
    token_hash char(64) NOT NULL CHECK (token_hash ~ '^[a-f0-9]{64}$'),
    previous_hash char(64),
    previous_valid_until timestamptz,
    issued_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    rotated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_used_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at timestamptz NOT NULL DEFAULT (CURRENT_TIMESTAMP + interval '30 days'),
    revoked_at timestamptz
);

ALTER TABLE public.tb_business_remember_devices OWNER TO runner_dba;
REVOKE ALL ON public.tb_business_remember_devices FROM PUBLIC;
CREATE INDEX IF NOT EXISTS tb_business_remember_devices_user_idx
    ON public.tb_business_remember_devices (user_id);
CREATE INDEX IF NOT EXISTS tb_business_remember_devices_expiry_idx
    ON public.tb_business_remember_devices (expires_at);

COMMENT ON TABLE public.tb_business_remember_devices IS
    'Business remembered browsers. Only SHA-256 credential hashes; thirty-day sliding expiry; logout revokes one browser.';
COMMIT;
