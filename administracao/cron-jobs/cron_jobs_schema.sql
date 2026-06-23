CREATE TABLE IF NOT EXISTS public.tb_cron_jobs (
    id_cron_job bigserial PRIMARY KEY,
    nome varchar(160) NOT NULL,
    descricao text,
    projeto varchar(60) NOT NULL DEFAULT 'business',
    ambiente varchar(40) NOT NULL DEFAULT 'prod',
    endpoint_url text NOT NULL,
    http_method varchar(10) NOT NULL DEFAULT 'GET',
    content_type varchar(120) NOT NULL DEFAULT 'application/json',
    request_body text,
    headers_json jsonb NOT NULL DEFAULT '{}'::jsonb,
    auth_mode varchar(40) NOT NULL DEFAULT 'none',
    secret_ref varchar(120),
    interval_minutes integer NOT NULL DEFAULT 60,
    timeout_seconds integer NOT NULL DEFAULT 30,
    retry_limit integer NOT NULL DEFAULT 0,
    ativo boolean NOT NULL DEFAULT true,
    executar_em_atraso boolean NOT NULL DEFAULT true,
    max_runtime_seconds integer NOT NULL DEFAULT 300,
    last_run_at timestamp without time zone,
    next_run_at timestamp without time zone NOT NULL DEFAULT now(),
    last_status varchar(40),
    last_http_status varchar(80),
    last_duration_ms integer,
    last_error text,
    data_criacao timestamp without time zone NOT NULL DEFAULT now(),
    data_atualizacao timestamp without time zone NOT NULL DEFAULT now(),
    id_usuario_criacao bigint,
    id_usuario_atualizacao bigint,
    CONSTRAINT tb_cron_jobs_http_method_chk CHECK (http_method IN ('GET', 'POST', 'PUT', 'PATCH', 'DELETE')),
    CONSTRAINT tb_cron_jobs_auth_mode_chk CHECK (auth_mode IN ('none', 'bearer', 'api_key_header', 'api_key_query', 'hmac_sha256')),
    CONSTRAINT tb_cron_jobs_interval_chk CHECK (interval_minutes >= 1),
    CONSTRAINT tb_cron_jobs_timeout_chk CHECK (timeout_seconds BETWEEN 1 AND 120),
    CONSTRAINT tb_cron_jobs_retry_chk CHECK (retry_limit BETWEEN 0 AND 3)
);

CREATE INDEX IF NOT EXISTS tb_cron_jobs_due_idx
    ON public.tb_cron_jobs (ativo, next_run_at);

CREATE INDEX IF NOT EXISTS tb_cron_jobs_projeto_idx
    ON public.tb_cron_jobs (projeto, ambiente);

CREATE TABLE IF NOT EXISTS public.tb_cron_job_runs (
    id_cron_job_run bigserial PRIMARY KEY,
    id_cron_job bigint NOT NULL REFERENCES public.tb_cron_jobs(id_cron_job) ON DELETE CASCADE,
    trigger_type varchar(40) NOT NULL DEFAULT 'scheduled',
    attempt integer NOT NULL DEFAULT 1,
    started_at timestamp without time zone NOT NULL DEFAULT now(),
    finished_at timestamp without time zone,
    duration_ms integer,
    status varchar(40) NOT NULL DEFAULT 'running',
    http_status varchar(80),
    response_preview text,
    error_message text,
    endpoint_url text,
    request_body_preview text,
    created_by bigint
);

CREATE INDEX IF NOT EXISTS tb_cron_job_runs_job_idx
    ON public.tb_cron_job_runs (id_cron_job, started_at DESC);

CREATE INDEX IF NOT EXISTS tb_cron_job_runs_started_idx
    ON public.tb_cron_job_runs (started_at DESC, id_cron_job_run DESC);

CREATE INDEX IF NOT EXISTS tb_cron_job_runs_status_idx
    ON public.tb_cron_job_runs (status, started_at DESC);
