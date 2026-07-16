CREATE TABLE IF NOT EXISTS ads.tb_portal_banners (
    id_banner serial PRIMARY KEY,
    nome varchar(160) NOT NULL,
    canal varchar(80) NOT NULL,
    local_layout varchar(80) NOT NULL,
    tamanho_nome varchar(80),
    largura integer, -- desktop (mantido assim por compatibilidade)
    altura integer, -- desktop (mantido assim por compatibilidade)
    formato varchar(16), -- desktop (mantido assim por compatibilidade)
    alt_text varchar(255),
    arquivo_path varchar(255) NOT NULL, -- desktop (mantido assim por compatibilidade)
    arquivo_original varchar(255), -- desktop (mantido assim por compatibilidade)
    arquivo_mobile_path varchar(255) NOT NULL,
    arquivo_mobile_original varchar(255),
    formato_mobile varchar(16),
    largura_mobile integer,
    altura_mobile integer,
    link_destino varchar(500) NOT NULL,
    link_tipo varchar(20) NOT NULL DEFAULT 'interno',
    abrir_nova_aba boolean NOT NULL DEFAULT false,
    peso_exibicao integer NOT NULL DEFAULT 1,
    prioridade integer NOT NULL DEFAULT 1,
    limite_impressoes integer,
    limite_cliques integer,
    limite_diario integer,
    inicio_exibicao timestamp,
    fim_exibicao timestamp,
    status integer NOT NULL DEFAULT 2,
    observacoes text,
    criado_em timestamp NOT NULL DEFAULT now(),
    atualizado_em timestamp NOT NULL DEFAULT now(),
    criado_por integer,
    atualizado_por integer
);

-- Migra instalacoes anteriores mantendo a imagem atual como fallback mobile.
ALTER TABLE ads.tb_portal_banners
    ADD COLUMN IF NOT EXISTS arquivo_mobile_path varchar(255),
    ADD COLUMN IF NOT EXISTS arquivo_mobile_original varchar(255),
    ADD COLUMN IF NOT EXISTS formato_mobile varchar(16),
    ADD COLUMN IF NOT EXISTS largura_mobile integer,
    ADD COLUMN IF NOT EXISTS altura_mobile integer;

UPDATE ads.tb_portal_banners
SET arquivo_mobile_path = arquivo_path,
    arquivo_mobile_original = coalesce(arquivo_mobile_original, arquivo_original),
    formato_mobile = coalesce(formato_mobile, formato),
    largura_mobile = coalesce(largura_mobile, largura),
    altura_mobile = coalesce(altura_mobile, altura)
WHERE arquivo_mobile_path IS NULL OR trim(arquivo_mobile_path) = '';

ALTER TABLE ads.tb_portal_banners
    ALTER COLUMN arquivo_mobile_path SET NOT NULL;

CREATE INDEX IF NOT EXISTS tb_portal_banners_lookup_idx
    ON ads.tb_portal_banners (canal, local_layout, status);

CREATE INDEX IF NOT EXISTS tb_portal_banners_periodo_idx
    ON ads.tb_portal_banners (inicio_exibicao, fim_exibicao);

CREATE TABLE IF NOT EXISTS ads.tb_portal_banners_log (
    id_banner_log bigserial PRIMARY KEY,
    id_banner integer NOT NULL REFERENCES ads.tb_portal_banners (id_banner) ON DELETE CASCADE,
    tipo_evento varchar(20) NOT NULL,
    canal varchar(80),
    local_layout varchar(80),
    host_origem varchar(255),
    caminho_origem varchar(500),
    origem_site varchar(255),
    id_usuario integer,
    ip_address varchar(64),
    user_agent text,
    request_data jsonb,
    criado_em timestamp NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS tb_portal_banners_log_banner_idx
    ON ads.tb_portal_banners_log (id_banner, tipo_evento, criado_em DESC);

CREATE INDEX IF NOT EXISTS tb_portal_banners_log_slot_idx
    ON ads.tb_portal_banners_log (canal, local_layout, tipo_evento, criado_em DESC);
