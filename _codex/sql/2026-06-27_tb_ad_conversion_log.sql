-- Log de conversoes de turbinados.
-- Objetivo: separar taxa de click (clicks/views) de conversao real.

CREATE TABLE IF NOT EXISTS tb_ad_conversion_log (
    id_conversion bigserial PRIMARY KEY,
    id_ad_evento bigint NOT NULL,
    id_evento integer NOT NULL,
    id_conta bigint NOT NULL,
    id_usuario integer,
    tipo_conversion varchar(40) NOT NULL,
    valor numeric(14, 2),
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    data_criacao timestamp without time zone NOT NULL DEFAULT now(),
    CONSTRAINT ck_tb_ad_conversion_log_tipo CHECK (
        tipo_conversion IN (
            'EVENTO_VIEW',
            'INSCRICAO_CLICK',
            'INSCRICAO_CONFIRMADA'
        )
    )
);

CREATE INDEX IF NOT EXISTS idx_tb_ad_conversion_log_conta_data
    ON tb_ad_conversion_log (id_conta, data_criacao DESC);

CREATE INDEX IF NOT EXISTS idx_tb_ad_conversion_log_ad_data
    ON tb_ad_conversion_log (id_ad_evento, data_criacao DESC);

CREATE INDEX IF NOT EXISTS idx_tb_ad_conversion_log_evento_data
    ON tb_ad_conversion_log (id_evento, data_criacao DESC);

CREATE INDEX IF NOT EXISTS idx_tb_ad_conversion_log_tipo_data
    ON tb_ad_conversion_log (tipo_conversion, data_criacao DESC);

GRANT SELECT, INSERT ON tb_ad_conversion_log TO runner;
GRANT SELECT, USAGE ON SEQUENCE tb_ad_conversion_log_id_conversion_seq TO runner;
