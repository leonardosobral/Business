-- Apply once with the existing Business schema-owner role. No runtime DDL.
-- Only new objects; no grants, role changes, existing-table changes or deletes.
BEGIN;
-- Create only this module's new objects under the existing application owner.
-- This changes neither the role's grants nor the ColdFusion datasource settings.
SET LOCAL ROLE runner_dba;
CREATE TABLE IF NOT EXISTS public.tb_evento_geocoding (
    id bigserial PRIMARY KEY,
    id_evento integer NOT NULL REFERENCES public.tb_evento_corridas(id_evento),
    source_hash char(64) NOT NULL,
    source_snapshot jsonb NOT NULL,
    source_values jsonb NOT NULL,
    status varchar(32) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','running','auto_applied','approved','rejected','city_suggestion','needs_review','insufficient_data','conflict','error','errors_exhausted')),
    decision jsonb NOT NULL DEFAULT '{}'::jsonb,
    proposal_revision bigint NOT NULL DEFAULT 1,
    attempts integer NOT NULL DEFAULT 0 CHECK (attempts >= 0),
    priority integer NOT NULL DEFAULT 100,
    lease_token varchar(64), lease_until timestamptz, next_retry_at timestamptz,
    error_code varchar(64), created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    updated_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    UNIQUE(id_evento,source_hash)
);
CREATE INDEX IF NOT EXISTS tb_evento_geocoding_queue_idx ON public.tb_evento_geocoding(status,next_retry_at,priority,id);
CREATE INDEX IF NOT EXISTS tb_evento_geocoding_event_idx ON public.tb_evento_geocoding(id_evento,id DESC);
CREATE TABLE IF NOT EXISTS public.tb_evento_geocoding_audit (
    id bigserial PRIMARY KEY, work_id bigint REFERENCES public.tb_evento_geocoding(id),
    id_evento integer NOT NULL REFERENCES public.tb_evento_corridas(id_evento),
    action varchar(32) NOT NULL, actor varchar(64) NOT NULL,
    source_hash char(64) NOT NULL, coordinates_before text, coordinates_after text,
    details jsonb NOT NULL DEFAULT '{}'::jsonb, created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE INDEX IF NOT EXISTS tb_evento_geocoding_audit_event_idx ON public.tb_evento_geocoding_audit(id_evento,created_at DESC,id DESC);
CREATE TABLE IF NOT EXISTS public.tb_geocoding_cache (
    cache_key varchar(64) PRIMARY KEY, query_text text NOT NULL,
    response jsonb NOT NULL, expires_at timestamptz,
    last_call_at timestamptz, cooldown_until timestamptz,
    provider_lease_token varchar(64), provider_lease_until timestamptz,
    updated_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
INSERT INTO public.tb_geocoding_cache(cache_key,query_text,response)
VALUES('__control__','control','{"enabled":false,"dailyLimit":1000,"validatedFingerprint":"","blockedReason":""}'::jsonb)
ON CONFLICT(cache_key) DO NOTHING;
CREATE TABLE IF NOT EXISTS public.tb_geocoding_usage_daily (
    usage_date date NOT NULL, provider varchar(32) NOT NULL,
    calls integer NOT NULL DEFAULT 0 CHECK(calls >= 0),
    PRIMARY KEY(usage_date,provider)
);
COMMIT;
