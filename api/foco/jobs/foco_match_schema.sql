CREATE TABLE IF NOT EXISTS public.tb_foco_event_match_state (
    id_evento integer PRIMARY KEY
        REFERENCES public.tb_evento_corridas(id_evento)
        ON UPDATE CASCADE ON DELETE CASCADE,
    status varchar(32) NOT NULL DEFAULT 'pending',
    attempts integer NOT NULL DEFAULT 0,
    candidate_count integer NOT NULL DEFAULT 0,
    matched_competition_id varchar,
    matched_competition_name varchar,
    match_mode varchar(40),
    last_checked_at timestamp without time zone,
    next_attempt_at timestamp without time zone,
    processing_until timestamp without time zone,
    reviewed_by bigint,
    reviewed_at timestamp without time zone,
    review_note text,
    last_error text,
    data_criacao timestamp without time zone NOT NULL DEFAULT now(),
    data_atualizacao timestamp without time zone NOT NULL DEFAULT now(),
    CONSTRAINT tb_foco_event_match_state_status_chk CHECK (
        status IN ('pending', 'processing', 'linked', 'review', 'not_found', 'conflict', 'dismissed', 'error')
    ),
    CONSTRAINT tb_foco_event_match_state_attempts_chk CHECK (attempts >= 0),
    CONSTRAINT tb_foco_event_match_state_candidates_chk CHECK (candidate_count >= 0)
);

CREATE INDEX IF NOT EXISTS tb_foco_event_match_state_due_idx
    ON public.tb_foco_event_match_state (status, next_attempt_at);

CREATE SEQUENCE IF NOT EXISTS public.tb_foco_match_candidate_id_seq;

CREATE TABLE IF NOT EXISTS public.tb_foco_event_match_candidates (
    id_foco_event_match_candidate bigint NOT NULL
        DEFAULT nextval('public.tb_foco_match_candidate_id_seq'::regclass)
        PRIMARY KEY,
    id_evento integer NOT NULL
        REFERENCES public.tb_evento_corridas(id_evento)
        ON UPDATE CASCADE ON DELETE CASCADE,
    competition_id varchar NOT NULL,
    competition_name varchar,
    competition_date date,
    place varchar,
    uf varchar(2),
    score numeric(6,2) NOT NULL DEFAULT 0,
    exact_name boolean NOT NULL DEFAULT false,
    exact_date boolean NOT NULL DEFAULT false,
    exact_place boolean NOT NULL DEFAULT false,
    exact_uf boolean NOT NULL DEFAULT false,
    status varchar(24) NOT NULL DEFAULT 'active',
    payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    reviewed_by bigint,
    reviewed_at timestamp without time zone,
    review_note text,
    last_seen_at timestamp without time zone NOT NULL DEFAULT now(),
    CONSTRAINT tb_foco_event_match_candidates_status_chk CHECK (status IN ('active', 'ignored')),
    CONSTRAINT tb_foco_event_match_candidates_event_competition_uindex
        UNIQUE (id_evento, competition_id)
);

CREATE INDEX IF NOT EXISTS tb_foco_event_match_candidates_competition_idx
    ON public.tb_foco_event_match_candidates (competition_id);

CREATE SEQUENCE IF NOT EXISTS public.tb_evento_foco_vinculos_id_seq;

CREATE TABLE IF NOT EXISTS public.tb_evento_foco_vinculos (
    id_evento_foco_vinculo bigint NOT NULL
        DEFAULT nextval('public.tb_evento_foco_vinculos_id_seq'::regclass)
        PRIMARY KEY,
    id_evento integer NOT NULL
        REFERENCES public.tb_evento_corridas(id_evento)
        ON UPDATE CASCADE ON DELETE CASCADE,
    competition_id varchar NOT NULL,
    competition_name varchar,
    competition_date date,
    place varchar,
    uf varchar(2),
    competition_path varchar,
    identification_type varchar NOT NULL DEFAULT 'numero',
    score numeric(6,2),
    match_mode varchar(40),
    status varchar(24) NOT NULL DEFAULT 'active',
    payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_by bigint,
    reviewed_by bigint,
    reviewed_at timestamp without time zone,
    review_note text,
    data_criacao timestamp without time zone NOT NULL DEFAULT now(),
    data_atualizacao timestamp without time zone NOT NULL DEFAULT now(),
    CONSTRAINT tb_evento_foco_vinculos_status_chk CHECK (status IN ('active', 'unlinked')),
    CONSTRAINT tb_evento_foco_vinculos_event_competition_uindex UNIQUE (id_evento, competition_id)
);

CREATE UNIQUE INDEX IF NOT EXISTS tb_evento_foco_vinculos_active_competition_uindex
    ON public.tb_evento_foco_vinculos (competition_id)
    WHERE status = 'active';

CREATE INDEX IF NOT EXISTS tb_evento_foco_vinculos_event_status_idx
    ON public.tb_evento_foco_vinculos (id_evento, status);

INSERT INTO public.tb_evento_foco_vinculos
    (id_evento, competition_id, identification_type, status, payload, match_mode)
SELECT badge.id_evento,
       trim(badge.valor_badge) AS competition_id,
       coalesce(nullif(trim(badge.complemento_badge), ''), 'numero') AS identification_type,
       'active',
       coalesce(badge.badge_raw, '{}'::jsonb),
       'legacy_badge'
FROM (
    SELECT DISTINCT ON (trim(valor_badge))
           id_evento, valor_badge, complemento_badge, badge_raw
    FROM public.tb_badges
    WHERE badge = 'foco'
      AND percurso = 0
      AND length(trim(coalesce(valor_badge, ''))) > 0
    ORDER BY trim(valor_badge), id_evento
) badge
ON CONFLICT (id_evento, competition_id)
DO UPDATE SET
    identification_type = excluded.identification_type,
    status = 'active',
    payload = excluded.payload,
    data_atualizacao = now();

UPDATE public.tb_evento_foco_vinculos link
SET competition_name = coalesce(
        nullif(trim(link.competition_name), ''),
        nullif(trim(candidate.competition_name), ''),
        nullif(trim(candidate.payload ->> 'competition_name'), '')
    ),
    competition_date = coalesce(
        link.competition_date,
        candidate.competition_date,
        CASE
            WHEN (candidate.payload ->> 'date') ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
            THEN (left(candidate.payload ->> 'date', 10))::date
            ELSE NULL
        END
    ),
    place = coalesce(
        nullif(trim(link.place), ''),
        nullif(trim(candidate.place), ''),
        nullif(trim(candidate.payload ->> 'place'), '')
    ),
    uf = coalesce(
        nullif(trim(link.uf), ''),
        nullif(trim(candidate.uf), ''),
        nullif(trim(candidate.payload ->> 'UF'), '')
    ),
    competition_path = coalesce(
        nullif(trim(link.competition_path), ''),
        nullif(trim(candidate.payload ->> 'competition_path'), '')
    ),
    payload = CASE
        WHEN link.payload = '{}'::jsonb AND candidate.payload IS NOT NULL
        THEN candidate.payload
        ELSE link.payload
    END,
    data_atualizacao = now()
FROM public.tb_foco_event_match_candidates candidate
WHERE candidate.id_evento = link.id_evento
  AND trim(candidate.competition_id) = trim(link.competition_id)
  AND link.status = 'active'
  AND (
      length(trim(coalesce(link.competition_name, ''))) = 0
      OR link.competition_date IS NULL
      OR length(trim(coalesce(link.place, ''))) = 0
      OR length(trim(coalesce(link.uf, ''))) = 0
      OR length(trim(coalesce(link.competition_path, ''))) = 0
      OR link.payload = '{}'::jsonb
  );

ALTER TABLE public.tb_foco_event_match_candidates
    ALTER COLUMN id_foco_event_match_candidate
    SET DEFAULT nextval('public.tb_foco_match_candidate_id_seq'::regclass);

ALTER TABLE public.tb_foco_event_match_candidates
    ADD COLUMN IF NOT EXISTS status varchar(24) NOT NULL DEFAULT 'active';

ALTER TABLE public.tb_foco_event_match_candidates
    ADD COLUMN IF NOT EXISTS reviewed_by bigint;

ALTER TABLE public.tb_foco_event_match_candidates
    ADD COLUMN IF NOT EXISTS reviewed_at timestamp without time zone;

ALTER TABLE public.tb_foco_event_match_candidates
    ADD COLUMN IF NOT EXISTS review_note text;

ALTER TABLE public.tb_foco_event_match_candidates
    DROP CONSTRAINT IF EXISTS tb_foco_event_match_candidates_status_chk;

ALTER TABLE public.tb_foco_event_match_candidates
    ADD CONSTRAINT tb_foco_event_match_candidates_status_chk CHECK (status IN ('active', 'ignored'));

ALTER TABLE public.tb_foco_event_match_state
    DROP CONSTRAINT IF EXISTS tb_foco_event_match_state_status_chk;

ALTER TABLE public.tb_foco_event_match_state
    ADD CONSTRAINT tb_foco_event_match_state_status_chk CHECK (
        status IN ('pending', 'processing', 'linked', 'review', 'not_found', 'conflict', 'dismissed', 'error')
    );

ALTER TABLE public.tb_foco_event_match_state
    ADD COLUMN IF NOT EXISTS reviewed_by bigint;

ALTER TABLE public.tb_foco_event_match_state
    ADD COLUMN IF NOT EXISTS reviewed_at timestamp without time zone;

ALTER TABLE public.tb_foco_event_match_state
    ADD COLUMN IF NOT EXISTS review_note text;

ALTER TABLE public.tb_foco_event_match_state OWNER TO runner_dba;
ALTER TABLE public.tb_foco_event_match_candidates OWNER TO runner_dba;
ALTER SEQUENCE public.tb_foco_match_candidate_id_seq OWNER TO runner_dba;
ALTER SEQUENCE public.tb_foco_match_candidate_id_seq
    OWNED BY public.tb_foco_event_match_candidates.id_foco_event_match_candidate;
ALTER TABLE public.tb_evento_foco_vinculos OWNER TO runner_dba;
ALTER SEQUENCE public.tb_evento_foco_vinculos_id_seq OWNER TO runner_dba;
ALTER SEQUENCE public.tb_evento_foco_vinculos_id_seq
    OWNED BY public.tb_evento_foco_vinculos.id_evento_foco_vinculo;

GRANT SELECT, INSERT, UPDATE ON public.tb_foco_event_match_state TO runner;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.tb_foco_event_match_candidates TO runner;
GRANT SELECT, USAGE ON SEQUENCE public.tb_foco_match_candidate_id_seq TO runner;
GRANT SELECT, INSERT, UPDATE ON public.tb_evento_foco_vinculos TO runner;
GRANT SELECT, USAGE ON SEQUENCE public.tb_evento_foco_vinculos_id_seq TO runner;
