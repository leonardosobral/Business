-- Migration incremental para o fluxo de cadastro externo Business.
-- Rodar no DataGrip antes de habilitar/aprovar solicitacoes em /administracao/contas/.

DO $$
BEGIN
    CREATE TYPE status_conta_cadastro_solicitacao AS ENUM ('PENDENTE', 'APROVADA', 'RECUSADA', 'CANCELADA');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

ALTER TYPE status_conta_cadastro_solicitacao OWNER TO runner_dba;

CREATE TABLE IF NOT EXISTS tb_conta_cadastro_solicitacoes
(
    id_solicitacao       bigserial PRIMARY KEY,
    nome_empresa         varchar(160) NOT NULL,
    tipo_titular         tipo_titular_conta NOT NULL,
    documento            varchar(20) NOT NULL,
    nome_responsavel     varchar(200) NOT NULL,
    email_responsavel    varchar(255) NOT NULL,
    telefone_responsavel varchar(30),
    site                 varchar(256),
    cidade               varchar(128),
    estado               varchar(2),
    tipo_prestador       varchar(80) NOT NULL,
    mensagem             text,
    id_usuario           bigint
        CONSTRAINT fk_conta_cadastro_solicitacoes_usuario
            REFERENCES tb_usuarios,
    id_conta             bigint
        CONSTRAINT fk_conta_cadastro_solicitacoes_conta
            REFERENCES tb_contas,
    status               status_conta_cadastro_solicitacao DEFAULT 'PENDENTE'::status_conta_cadastro_solicitacao NOT NULL,
    id_usuario_revisor   bigint
        CONSTRAINT fk_conta_cadastro_solicitacoes_revisor
            REFERENCES tb_usuarios,
    observacao_revisor   text,
    data_criacao         timestamp with time zone DEFAULT now() NOT NULL,
    data_revisao         timestamp with time zone
);

ALTER TABLE tb_conta_cadastro_solicitacoes OWNER TO runner_dba;

CREATE INDEX IF NOT EXISTS idx_tb_conta_cadastro_solicitacoes_status
    ON tb_conta_cadastro_solicitacoes (status, data_criacao);

CREATE INDEX IF NOT EXISTS idx_tb_conta_cadastro_solicitacoes_documento
    ON tb_conta_cadastro_solicitacoes (documento);

CREATE INDEX IF NOT EXISTS idx_tb_conta_cadastro_solicitacoes_email
    ON tb_conta_cadastro_solicitacoes (email_responsavel);

GRANT SELECT, USAGE ON SEQUENCE tb_conta_cadastro_solicitacoes_id_solicitacao_seq TO runner;
GRANT INSERT, SELECT, UPDATE ON tb_conta_cadastro_solicitacoes TO runner;
