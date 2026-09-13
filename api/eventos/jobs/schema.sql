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
