BEGIN;

CREATE TABLE IF NOT EXISTS tb_agendas (
    id_agenda bigserial PRIMARY KEY,
    chave_publica varchar(64) NOT NULL,
    nome varchar(160) NOT NULL,
    descricao text,
    id_usuario integer NOT NULL REFERENCES tb_usuarios(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    modo varchar(16) NOT NULL DEFAULT 'manual',
    visao_padrao varchar(16) NOT NULL DEFAULT 'futuros',
    dominio_permitido varchar(255) NOT NULL,
    permitir_subdominios boolean NOT NULL DEFAULT false,
    limite_eventos integer NOT NULL DEFAULT 20,
    ordenacao varchar(20) NOT NULL DEFAULT 'data',
    tema_embed varchar(12) NOT NULL DEFAULT 'escuro',
    cor_card_data varchar(7) NOT NULL DEFAULT '#fab120',
    fonte_cards varchar(16) NOT NULL DEFAULT 'trebuchet',
    raio_cards varchar(12) NOT NULL DEFAULT 'atual',
    status varchar(16) NOT NULL DEFAULT 'rascunho',
    versao integer NOT NULL DEFAULT 1,
    criado_por integer REFERENCES tb_usuarios(id) ON UPDATE CASCADE ON DELETE SET NULL,
    atualizado_por integer REFERENCES tb_usuarios(id) ON UPDATE CASCADE ON DELETE SET NULL,
    data_criacao timestamp NOT NULL DEFAULT now(),
    data_atualizacao timestamp NOT NULL DEFAULT now(),
    CONSTRAINT tb_agendas_chave_publica_uk UNIQUE (chave_publica),
    CONSTRAINT tb_agendas_modo_ck CHECK (modo IN ('manual', 'dinamica')),
    CONSTRAINT tb_agendas_visao_ck CHECK (visao_padrao IN ('futuros', 'resultados')),
    CONSTRAINT tb_agendas_ordenacao_ck CHECK (ordenacao IN ('data', 'manual')),
    CONSTRAINT tb_agendas_tema_embed_ck CHECK (tema_embed IN ('claro', 'escuro')),
    CONSTRAINT tb_agendas_cor_card_data_ck CHECK (cor_card_data ~ '^#[0-9a-fA-F]{6}$'),
    CONSTRAINT tb_agendas_fonte_cards_ck CHECK (fonte_cards IN ('trebuchet', 'verdana', 'georgia', 'tahoma', 'monospace')),
    CONSTRAINT tb_agendas_raio_cards_ck CHECK (raio_cards IN ('atual', 'medio', 'suave', 'reto')),
    CONSTRAINT tb_agendas_status_ck CHECK (status IN ('rascunho', 'ativa', 'pausada', 'arquivada')),
    CONSTRAINT tb_agendas_limite_ck CHECK (limite_eventos BETWEEN 1 AND 100)
);

ALTER TABLE tb_agendas
    ADD COLUMN IF NOT EXISTS tema_embed varchar(12) NOT NULL DEFAULT 'escuro';

ALTER TABLE tb_agendas
    ADD COLUMN IF NOT EXISTS cor_card_data varchar(7) NOT NULL DEFAULT '#fab120';

ALTER TABLE tb_agendas
    ADD COLUMN IF NOT EXISTS fonte_cards varchar(16) NOT NULL DEFAULT 'trebuchet';

ALTER TABLE tb_agendas
    ADD COLUMN IF NOT EXISTS raio_cards varchar(12) NOT NULL DEFAULT 'atual';

DO $agenda_visual_constraints$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'tb_agendas_tema_embed_ck'
          AND conrelid = 'tb_agendas'::regclass
    ) THEN
        ALTER TABLE tb_agendas
            ADD CONSTRAINT tb_agendas_tema_embed_ck
            CHECK (tema_embed IN ('claro', 'escuro'));
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'tb_agendas_cor_card_data_ck'
          AND conrelid = 'tb_agendas'::regclass
    ) THEN
        ALTER TABLE tb_agendas
            ADD CONSTRAINT tb_agendas_cor_card_data_ck
            CHECK (cor_card_data ~ '^#[0-9a-fA-F]{6}$');
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'tb_agendas_fonte_cards_ck'
          AND conrelid = 'tb_agendas'::regclass
    ) THEN
        ALTER TABLE tb_agendas
            ADD CONSTRAINT tb_agendas_fonte_cards_ck
            CHECK (fonte_cards IN ('trebuchet', 'verdana', 'georgia', 'tahoma', 'monospace'));
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'tb_agendas_raio_cards_ck'
          AND conrelid = 'tb_agendas'::regclass
    ) THEN
        ALTER TABLE tb_agendas
            ADD CONSTRAINT tb_agendas_raio_cards_ck
            CHECK (raio_cards IN ('atual', 'medio', 'suave', 'reto'));
    END IF;
END
$agenda_visual_constraints$;

CREATE TABLE IF NOT EXISTS tb_agenda_eventos (
    id_agenda_evento bigserial PRIMARY KEY,
    id_agenda bigint NOT NULL REFERENCES tb_agendas(id_agenda) ON UPDATE CASCADE ON DELETE CASCADE,
    id_evento integer NOT NULL REFERENCES tb_evento_corridas(id_evento) ON UPDATE CASCADE ON DELETE CASCADE,
    ordem integer NOT NULL DEFAULT 100,
    adicionado_por integer REFERENCES tb_usuarios(id) ON UPDATE CASCADE ON DELETE SET NULL,
    data_criacao timestamp NOT NULL DEFAULT now(),
    CONSTRAINT tb_agenda_eventos_agenda_evento_uk UNIQUE (id_agenda, id_evento)
);

CREATE TABLE IF NOT EXISTS tb_agenda_filtros (
    id_agenda_filtro bigserial PRIMARY KEY,
    id_agenda bigint NOT NULL REFERENCES tb_agendas(id_agenda) ON UPDATE CASCADE ON DELETE CASCADE,
    campo varchar(24) NOT NULL,
    valor_texto varchar(255),
    valor_numero numeric(10, 3),
    valor_id integer,
    criado_por integer REFERENCES tb_usuarios(id) ON UPDATE CASCADE ON DELETE SET NULL,
    data_criacao timestamp NOT NULL DEFAULT now(),
    CONSTRAINT tb_agenda_filtros_campo_ck CHECK (campo IN ('estado', 'cidade', 'distancia', 'tipo', 'agregador')),
    CONSTRAINT tb_agenda_filtros_valor_ck CHECK (
        valor_texto IS NOT NULL OR valor_numero IS NOT NULL OR valor_id IS NOT NULL
    )
);

CREATE UNIQUE INDEX IF NOT EXISTS tb_agenda_filtros_valor_uk
    ON tb_agenda_filtros (
        id_agenda,
        campo,
        coalesce(valor_texto, ''),
        coalesce(valor_numero, -1),
        coalesce(valor_id, -1)
    );

CREATE TABLE IF NOT EXISTS tb_agenda_credenciais (
    id_agenda_credencial bigserial PRIMARY KEY,
    id_agenda bigint NOT NULL REFERENCES tb_agendas(id_agenda) ON UPDATE CASCADE ON DELETE CASCADE,
    token_prefixo varchar(12) NOT NULL,
    token_hash char(64) NOT NULL,
    ativa boolean NOT NULL DEFAULT true,
    criado_por integer REFERENCES tb_usuarios(id) ON UPDATE CASCADE ON DELETE SET NULL,
    data_criacao timestamp NOT NULL DEFAULT now(),
    data_revogacao timestamp,
    CONSTRAINT tb_agenda_credenciais_hash_uk UNIQUE (token_hash)
);

CREATE TABLE IF NOT EXISTS tb_agenda_acessos (
    id_agenda_acesso bigserial PRIMARY KEY,
    id_agenda bigint REFERENCES tb_agendas(id_agenda) ON UPDATE CASCADE ON DELETE SET NULL,
    formato varchar(16) NOT NULL,
    visao varchar(16),
    dominio_requisitante varchar(255),
    origem varchar(512),
    referer varchar(1024),
    endereco_ip varchar(64),
    user_agent varchar(512),
    status_http integer NOT NULL,
    eventos_retornados integer NOT NULL DEFAULT 0,
    duracao_ms integer,
    data_acesso timestamp NOT NULL DEFAULT now(),
    CONSTRAINT tb_agenda_acessos_formato_ck CHECK (formato IN ('json', 'xml', 'embed'))
);

CREATE INDEX IF NOT EXISTS tb_agendas_usuario_status_idx
    ON tb_agendas (id_usuario, status, data_atualizacao DESC);

CREATE INDEX IF NOT EXISTS tb_agenda_eventos_agenda_ordem_idx
    ON tb_agenda_eventos (id_agenda, ordem, id_agenda_evento);

CREATE INDEX IF NOT EXISTS tb_agenda_filtros_agenda_campo_idx
    ON tb_agenda_filtros (id_agenda, campo);

CREATE INDEX IF NOT EXISTS tb_agenda_credenciais_agenda_ativa_idx
    ON tb_agenda_credenciais (id_agenda, ativa);

CREATE INDEX IF NOT EXISTS tb_agenda_acessos_agenda_data_idx
    ON tb_agenda_acessos (id_agenda, data_acesso DESC);

CREATE INDEX IF NOT EXISTS tb_agenda_acessos_agenda_ip_data_idx
    ON tb_agenda_acessos (id_agenda, endereco_ip, data_acesso DESC);

CREATE INDEX IF NOT EXISTS tb_evento_corridas_agenda_lookup_idx
    ON tb_evento_corridas (ativo, data_final, estado, cidade, tipo_corrida);

CREATE INDEX IF NOT EXISTS tb_evento_corridas_agenda_agregador_idx
    ON tb_evento_corridas (id_agrega_evento);

CREATE INDEX IF NOT EXISTS tb_evento_percursos_agenda_lookup_idx
    ON tb_evento_corridas_percursos (id_evento, percurso_evento, unidade_de_medida);

GRANT SELECT, INSERT, UPDATE, DELETE ON tb_agendas TO runner;
GRANT SELECT, INSERT, UPDATE, DELETE ON tb_agenda_eventos TO runner;
GRANT SELECT, INSERT, UPDATE, DELETE ON tb_agenda_filtros TO runner;
GRANT SELECT, INSERT, UPDATE, DELETE ON tb_agenda_credenciais TO runner;
GRANT SELECT, INSERT, UPDATE, DELETE ON tb_agenda_acessos TO runner;

GRANT SELECT, USAGE ON SEQUENCE tb_agendas_id_agenda_seq TO runner;
GRANT SELECT, USAGE ON SEQUENCE tb_agenda_eventos_id_agenda_evento_seq TO runner;
GRANT SELECT, USAGE ON SEQUENCE tb_agenda_filtros_id_agenda_filtro_seq TO runner;
GRANT SELECT, USAGE ON SEQUENCE tb_agenda_credenciais_id_agenda_credencial_seq TO runner;
GRANT SELECT, USAGE ON SEQUENCE tb_agenda_acessos_id_agenda_acesso_seq TO runner;

COMMIT;
