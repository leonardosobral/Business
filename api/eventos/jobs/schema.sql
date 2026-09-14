-- Audit and deduplication for the description-only rewrite job.
-- Run on the Business datasource as its existing application owner.
CREATE TABLE IF NOT EXISTS public.tb_evento_descricao_rewrites (
    id bigserial PRIMARY KEY,
    id_evento integer NOT NULL REFERENCES public.tb_evento_corridas(id_evento),
    source_hash varchar(32) NOT NULL,
    source_text text NOT NULL,
    status varchar(24) NOT NULL CHECK (status IN
        ('running', 'updated', 'rejected', 'error', 'source_changed')),
    description_before text,
    description_after text,
    model varchar(80) NOT NULL,
    error_code varchar(100),
    created_at timestamptz NOT NULL DEFAULT now(),
    finished_at timestamptz,
    UNIQUE (id_evento, source_hash)
);

CREATE INDEX IF NOT EXISTS tb_evento_descricao_rewrites_status_idx
    ON public.tb_evento_descricao_rewrites (status, created_at DESC);

-- The Portuguese source and the original import remain unchanged by translation.
ALTER TABLE public.tb_evento_corridas ADD COLUMN IF NOT EXISTS descricao_en text;
ALTER TABLE public.tb_evento_corridas ADD COLUMN IF NOT EXISTS descricao_es text;
ALTER TABLE public.tb_evento_corridas ADD COLUMN IF NOT EXISTS descricao_traducoes_meta jsonb;

-- Each attempt is retained. A source may return to an earlier version or its
-- published translation may be cleared, so a source hash is not a unique key.
CREATE TABLE IF NOT EXISTS public.tb_evento_descricao_translations (
    id bigserial PRIMARY KEY,
    id_evento integer NOT NULL REFERENCES public.tb_evento_corridas(id_evento),
    language varchar(2) NOT NULL CHECK (language IN ('en', 'es')),
    source_hash varchar(32) NOT NULL,
    source_text text NOT NULL,
    status varchar(24) NOT NULL CHECK (status IN
        ('running', 'updated', 'rejected', 'error', 'source_changed')),
    description_before text,
    description_after text,
    metadata_before jsonb,
    model varchar(80) NOT NULL,
    error_code varchar(100),
    attempt_count integer NOT NULL DEFAULT 1 CHECK (attempt_count BETWEEN 1 AND 3),
    next_retry_at timestamptz,
    reused_from_id bigint REFERENCES public.tb_evento_descricao_translations(id),
    created_at timestamptz NOT NULL DEFAULT now(),
    finished_at timestamptz
);
ALTER TABLE public.tb_evento_descricao_translations ADD COLUMN IF NOT EXISTS metadata_before jsonb;
CREATE INDEX IF NOT EXISTS tb_evento_descricao_translations_source_idx
    ON public.tb_evento_descricao_translations (id_evento, language, source_hash, id DESC);
CREATE INDEX IF NOT EXISTS tb_evento_descricao_translations_updated_idx
    ON public.tb_evento_descricao_translations (id_evento, language, id DESC)
    WHERE status = 'updated';
CREATE INDEX IF NOT EXISTS tb_evento_descricao_translations_status_idx
    ON public.tb_evento_descricao_translations (status, created_at DESC);
