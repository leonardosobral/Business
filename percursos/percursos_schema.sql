BEGIN;

CREATE TABLE IF NOT EXISTS public.tb_percursos (
    id_percurso bigserial PRIMARY KEY,
    codigo_publico uuid NOT NULL UNIQUE,
    nome varchar(180) NOT NULL,
    cidade varchar(128),
    estado varchar(2),
    pais varchar(2) NOT NULL DEFAULT 'BR',
    distancia_nominal_m integer NOT NULL,
    tipo_percurso varchar(30) NOT NULL DEFAULT 'rua',
    descricao text,
    visibilidade varchar(20) NOT NULL DEFAULT 'privado',
    status varchar(20) NOT NULL DEFAULT 'rascunho',
    id_usuario_criador bigint NOT NULL,
    id_conta_responsavel bigint,
    criado_em timestamp without time zone NOT NULL DEFAULT now(),
    atualizado_em timestamp without time zone NOT NULL DEFAULT now(),
    CONSTRAINT tb_percursos_distancia_chk CHECK (distancia_nominal_m > 0),
    CONSTRAINT tb_percursos_tipo_chk CHECK (tipo_percurso IN ('rua', 'trail', 'misto')),
    CONSTRAINT tb_percursos_visibilidade_chk CHECK (visibilidade IN ('privado', 'compartilhado', 'publico')),
    CONSTRAINT tb_percursos_status_chk CHECK (status IN ('rascunho', 'publicado', 'arquivado'))
);

CREATE INDEX IF NOT EXISTS tb_percursos_busca_idx
    ON public.tb_percursos (status, estado, cidade, distancia_nominal_m);
CREATE INDEX IF NOT EXISTS tb_percursos_conta_idx
    ON public.tb_percursos (id_conta_responsavel, atualizado_em DESC);
CREATE INDEX IF NOT EXISTS tb_percursos_criador_idx
    ON public.tb_percursos (id_usuario_criador, atualizado_em DESC);

CREATE TABLE IF NOT EXISTS public.tb_evento_percursos_gpx (
    id_evento_percurso_gpx bigserial PRIMARY KEY,
    id_evento integer NOT NULL REFERENCES public.tb_evento_corridas(id_evento) ON DELETE CASCADE,
    id_evento_percurso integer REFERENCES public.tb_evento_corridas_percursos(id_evento_percurso) ON UPDATE CASCADE ON DELETE CASCADE,
    id_percurso bigint NOT NULL REFERENCES public.tb_percursos(id_percurso) ON DELETE CASCADE,
    id_usuario_criador bigint NOT NULL,
    criado_em timestamp with time zone NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS tb_evento_percursos_gpx_manual_uq
    ON public.tb_evento_percursos_gpx (id_evento, id_percurso)
    WHERE id_evento_percurso IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS tb_evento_percursos_gpx_modalidade_uq
    ON public.tb_evento_percursos_gpx (id_evento_percurso)
    WHERE id_evento_percurso IS NOT NULL;
CREATE INDEX IF NOT EXISTS tb_evento_percursos_gpx_percurso_idx
    ON public.tb_evento_percursos_gpx (id_percurso, id_evento);
CREATE INDEX IF NOT EXISTS tb_evento_percursos_gpx_evento_idx
    ON public.tb_evento_percursos_gpx (id_evento, id_percurso);
CREATE INDEX IF NOT EXISTS tb_conta_eventos_evento_conta_status_idx
    ON public.tb_conta_eventos (id_evento, id_conta, status);

CREATE TABLE IF NOT EXISTS public.tb_percurso_arquivos (
    id_percurso_arquivo bigserial PRIMARY KEY,
    id_percurso bigint NOT NULL REFERENCES public.tb_percursos(id_percurso) ON DELETE RESTRICT,
    versao integer NOT NULL,
    storage_key varchar(512) NOT NULL,
    geojson_storage_key varchar(512) NOT NULL,
    nome_original varchar(255) NOT NULL,
    mime_type varchar(100),
    tamanho_bytes bigint NOT NULL,
    sha256 char(64) NOT NULL,
    quantidade_pontos integer NOT NULL,
    distancia_gpx_m numeric(14,2) NOT NULL,
    elevacao_min_m numeric(10,2),
    elevacao_max_m numeric(10,2),
    ganho_elevacao_m numeric(12,2),
    bbox_min_lat numeric(10,7) NOT NULL,
    bbox_min_lng numeric(10,7) NOT NULL,
    bbox_max_lat numeric(10,7) NOT NULL,
    bbox_max_lng numeric(10,7) NOT NULL,
    ativo boolean NOT NULL DEFAULT true,
    id_usuario_criador bigint NOT NULL,
    criado_em timestamp without time zone NOT NULL DEFAULT now(),
    CONSTRAINT tb_percurso_arquivos_versao_uq UNIQUE (id_percurso, versao),
    CONSTRAINT tb_percurso_arquivos_pontos_chk CHECK (quantidade_pontos >= 2),
    CONSTRAINT tb_percurso_arquivos_tamanho_chk CHECK (tamanho_bytes > 0)
);

CREATE INDEX IF NOT EXISTS tb_percurso_arquivos_percurso_idx
    ON public.tb_percurso_arquivos (id_percurso, versao DESC);
CREATE INDEX IF NOT EXISTS tb_percurso_arquivos_hash_idx
    ON public.tb_percurso_arquivos (sha256);

CREATE TABLE IF NOT EXISTS public.tb_percurso_historico (
    id_historico bigserial PRIMARY KEY,
    id_percurso bigint NOT NULL REFERENCES public.tb_percursos(id_percurso) ON DELETE RESTRICT,
    id_percurso_arquivo bigint REFERENCES public.tb_percurso_arquivos(id_percurso_arquivo) ON DELETE SET NULL,
    id_usuario bigint NOT NULL,
    acao varchar(50) NOT NULL,
    dados jsonb NOT NULL DEFAULT '{}'::jsonb,
    endereco_ip varchar(64),
    criado_em timestamp without time zone NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS tb_percurso_historico_percurso_idx
    ON public.tb_percurso_historico (id_percurso, criado_em DESC);

CREATE TABLE IF NOT EXISTS public.tb_percurso_migracoes_strava (
    id_migracao bigserial PRIMARY KEY,
    id_evento_percurso integer NOT NULL REFERENCES public.tb_evento_corridas_percursos(id_evento_percurso) ON UPDATE CASCADE ON DELETE RESTRICT,
    id_evento integer NOT NULL REFERENCES public.tb_evento_corridas(id_evento) ON UPDATE CASCADE ON DELETE RESTRICT,
    strava_route_id varchar(128) NOT NULL,
    strava_url varchar(512) NOT NULL,
    status varchar(24) NOT NULL DEFAULT 'pendente',
    id_percurso bigint REFERENCES public.tb_percursos(id_percurso) ON DELETE SET NULL,
    id_percurso_arquivo bigint REFERENCES public.tb_percurso_arquivos(id_percurso_arquivo) ON DELETE SET NULL,
    sha256 char(64),
    distancia_gpx_m numeric(14,2),
    tentativas integer NOT NULL DEFAULT 0,
    ultimo_http_status integer,
    mensagem text,
    dados jsonb NOT NULL DEFAULT '{}'::jsonb,
    id_usuario_ultima_acao bigint,
    data_criacao timestamp with time zone NOT NULL DEFAULT now(),
    data_atualizacao timestamp with time zone NOT NULL DEFAULT now(),
    data_ultima_tentativa timestamp with time zone,
    data_conclusao timestamp with time zone,
    CONSTRAINT tb_percurso_migracoes_strava_modalidade_uq UNIQUE (id_evento_percurso),
    CONSTRAINT tb_percurso_migracoes_strava_status_chk CHECK (status IN ('pendente','processando','validado','migrado','reutilizado','revisao','erro','ignorado')),
    CONSTRAINT tb_percurso_migracoes_strava_tentativas_chk CHECK (tentativas >= 0)
);

CREATE INDEX IF NOT EXISTS tb_percurso_migracoes_strava_status_idx
    ON public.tb_percurso_migracoes_strava (status, data_atualizacao, id_evento_percurso);
CREATE INDEX IF NOT EXISTS tb_percurso_migracoes_strava_rota_idx
    ON public.tb_percurso_migracoes_strava (strava_route_id);

GRANT SELECT, INSERT, UPDATE ON public.tb_percursos TO runner;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.tb_evento_percursos_gpx TO runner;
GRANT SELECT, INSERT, UPDATE ON public.tb_percurso_arquivos TO runner;
GRANT SELECT, INSERT ON public.tb_percurso_historico TO runner;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.tb_percurso_migracoes_strava TO runner;
GRANT USAGE, SELECT ON SEQUENCE public.tb_percursos_id_percurso_seq TO runner;
GRANT USAGE, SELECT ON SEQUENCE public.tb_evento_percursos_gpx_id_evento_percurso_gpx_seq TO runner;
GRANT USAGE, SELECT ON SEQUENCE public.tb_percurso_arquivos_id_percurso_arquivo_seq TO runner;
GRANT USAGE, SELECT ON SEQUENCE public.tb_percurso_historico_id_historico_seq TO runner;
GRANT USAGE, SELECT ON SEQUENCE public.tb_percurso_migracoes_strava_id_migracao_seq TO runner;

COMMIT;
