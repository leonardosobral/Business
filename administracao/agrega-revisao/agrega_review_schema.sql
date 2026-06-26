CREATE TABLE IF NOT EXISTS public.tb_evento_agrega_review_groups (
    id_evento_agrega_review_group bigserial PRIMARY KEY,
    group_key varchar(128) NOT NULL UNIQUE,
    normalized_name varchar(256) NOT NULL,
    cidade varchar(128) NOT NULL,
    estado varchar(8) NOT NULL,
    candidate_count integer NOT NULL DEFAULT 0,
    max_score numeric(6,2) NOT NULL DEFAULT 0,
    suggested_id_agrega_evento integer NULL REFERENCES public.tb_agrega_eventos(id_agrega_evento),
    status varchar(24) NOT NULL DEFAULT 'review',
    created_by bigint NULL,
    reviewed_by bigint NULL,
    reviewed_at timestamp NULL,
    review_note text NULL,
    data_criacao timestamp NOT NULL DEFAULT now(),
    data_atualizacao timestamp NOT NULL DEFAULT now(),
    CONSTRAINT tb_evento_agrega_review_groups_status_ck
        CHECK (status IN ('review', 'applied', 'ignored'))
);

CREATE TABLE IF NOT EXISTS public.tb_evento_agrega_review_candidates (
    id_evento_agrega_review_candidate bigserial PRIMARY KEY,
    id_evento_agrega_review_group bigint NOT NULL
        REFERENCES public.tb_evento_agrega_review_groups(id_evento_agrega_review_group) ON DELETE CASCADE,
    id_evento integer NOT NULL REFERENCES public.tb_evento_corridas(id_evento),
    id_agrega_evento_atual integer NULL REFERENCES public.tb_agrega_eventos(id_agrega_evento),
    nome_evento varchar(256) NOT NULL,
    normalized_name varchar(256) NOT NULL,
    cidade varchar(128) NOT NULL,
    estado varchar(8) NOT NULL,
    tag varchar NULL,
    data_inicial date NULL,
    score numeric(6,2) NOT NULL DEFAULT 0,
    name_score numeric(6,2) NOT NULL DEFAULT 0,
    city_score numeric(6,2) NOT NULL DEFAULT 0,
    status varchar(24) NOT NULL DEFAULT 'active',
    reviewed_by bigint NULL,
    reviewed_at timestamp NULL,
    review_note text NULL,
    data_criacao timestamp NOT NULL DEFAULT now(),
    data_atualizacao timestamp NOT NULL DEFAULT now(),
    CONSTRAINT tb_evento_agrega_review_candidates_status_ck
        CHECK (status IN ('active', 'applied', 'ignored'))
);

CREATE UNIQUE INDEX IF NOT EXISTS tb_evento_agrega_review_candidates_group_event_uindex
    ON public.tb_evento_agrega_review_candidates(id_evento_agrega_review_group, id_evento);

CREATE INDEX IF NOT EXISTS tb_evento_agrega_review_groups_status_idx
    ON public.tb_evento_agrega_review_groups(status, max_score DESC);

CREATE INDEX IF NOT EXISTS tb_evento_agrega_review_groups_status_fast_idx
    ON public.tb_evento_agrega_review_groups(status, max_score DESC, data_atualizacao DESC, id_evento_agrega_review_group DESC);

CREATE INDEX IF NOT EXISTS tb_evento_agrega_review_groups_status_id_idx
    ON public.tb_evento_agrega_review_groups(status, id_evento_agrega_review_group DESC);

CREATE INDEX IF NOT EXISTS tb_evento_agrega_review_groups_score_idx
    ON public.tb_evento_agrega_review_groups(max_score DESC, data_atualizacao DESC);

CREATE INDEX IF NOT EXISTS tb_evento_agrega_review_candidates_event_idx
    ON public.tb_evento_agrega_review_candidates(id_evento);

ALTER TABLE public.tb_evento_agrega_review_groups
    ADD COLUMN IF NOT EXISTS display_name varchar(256);

UPDATE public.tb_evento_agrega_review_groups
SET display_name = normalized_name
WHERE display_name IS NULL OR trim(display_name) = '';

GRANT SELECT, INSERT, UPDATE, DELETE ON public.tb_evento_agrega_review_groups TO runner;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.tb_evento_agrega_review_candidates TO runner;

DO $$
BEGIN
    EXECUTE format(
        'GRANT USAGE, SELECT ON SEQUENCE %s TO runner',
        pg_get_serial_sequence('public.tb_evento_agrega_review_groups', 'id_evento_agrega_review_group')
    );

    EXECUTE format(
        'GRANT USAGE, SELECT ON SEQUENCE %s TO runner',
        pg_get_serial_sequence('public.tb_evento_agrega_review_candidates', 'id_evento_agrega_review_candidate')
    );
END $$;
