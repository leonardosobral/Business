-- Voucher de credito para ads vinculado a contas Business.
-- Status atual de tb_ad_vouchers:
-- 1 = ativo/disponivel para resgate
-- 2 = resgatado
-- 3 = cancelado/inativo

ALTER TABLE tb_ad_vouchers
    ADD COLUMN IF NOT EXISTS id_conta bigint,
    ADD COLUMN IF NOT EXISTS id_usuario_resgate bigint,
    ADD COLUMN IF NOT EXISTS papel_resgate papel_usuario_conta DEFAULT 'OWNER'::papel_usuario_conta,
    ADD COLUMN IF NOT EXISTS observacao text,
    ADD COLUMN IF NOT EXISTS data_resgate timestamp without time zone,
    ADD COLUMN IF NOT EXISTS data_atualizacao timestamp without time zone DEFAULT now();

UPDATE tb_ad_vouchers
SET id_ad_voucher = nextval('tb_ad_vouchers_id_ad_voucher_seq')
WHERE id_ad_voucher IS NULL;

SELECT setval(
    'tb_ad_vouchers_id_ad_voucher_seq',
    GREATEST((SELECT COALESCE(MAX(id_ad_voucher), 1) FROM tb_ad_vouchers), 1)
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = 'tb_ad_vouchers'::regclass
          AND contype = 'p'
    ) THEN
        ALTER TABLE tb_ad_vouchers
            ALTER COLUMN id_ad_voucher SET NOT NULL;

        ALTER TABLE tb_ad_vouchers
            ADD CONSTRAINT tb_ad_vouchers_pkey
                PRIMARY KEY (id_ad_voucher);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'fk_tb_ad_vouchers_conta'
    ) THEN
        ALTER TABLE tb_ad_vouchers
            ADD CONSTRAINT fk_tb_ad_vouchers_conta
                FOREIGN KEY (id_conta)
                REFERENCES tb_contas
                ON UPDATE CASCADE
                ON DELETE SET NULL
                NOT VALID;
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'fk_tb_ad_vouchers_usuario_resgate'
    ) THEN
        ALTER TABLE tb_ad_vouchers
            ADD CONSTRAINT fk_tb_ad_vouchers_usuario_resgate
                FOREIGN KEY (id_usuario_resgate)
                REFERENCES tb_usuarios(id)
                ON UPDATE CASCADE
                ON DELETE SET NULL
                NOT VALID;
    END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS uq_tb_ad_vouchers_codigo_lower
    ON tb_ad_vouchers (lower(codigo))
    WHERE codigo IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_tb_ad_vouchers_conta_status
    ON tb_ad_vouchers (id_conta, status);

CREATE INDEX IF NOT EXISTS idx_tb_ad_vouchers_usuario_resgate
    ON tb_ad_vouchers (id_usuario_resgate);

ALTER TABLE tb_conta_cadastro_solicitacoes
    ADD COLUMN IF NOT EXISTS id_ad_voucher integer,
    ADD COLUMN IF NOT EXISTS voucher_codigo varchar;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'fk_tb_conta_cadastro_solicitacoes_ad_voucher'
    ) THEN
        ALTER TABLE tb_conta_cadastro_solicitacoes
            ADD CONSTRAINT fk_tb_conta_cadastro_solicitacoes_ad_voucher
                FOREIGN KEY (id_ad_voucher)
                REFERENCES tb_ad_vouchers
                ON UPDATE CASCADE
                ON DELETE SET NULL
                NOT VALID;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_tb_conta_cadastro_solicitacoes_ad_voucher
    ON tb_conta_cadastro_solicitacoes (id_ad_voucher);

GRANT SELECT, USAGE ON SEQUENCE tb_ad_vouchers_id_ad_voucher_seq TO runner;
GRANT INSERT, SELECT, UPDATE ON tb_ad_vouchers TO runner;
GRANT INSERT, SELECT, UPDATE ON tb_conta_cadastro_solicitacoes TO runner;
