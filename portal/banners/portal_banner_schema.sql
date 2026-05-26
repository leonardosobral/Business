CREATE TABLE IF NOT EXISTS tb_portal_banners (
    id_banner serial PRIMARY KEY,
    nome varchar(160) NOT NULL,
    canal varchar(80) NOT NULL,
    local_layout varchar(80) NOT NULL,
    tamanho_nome varchar(80),
    largura integer,
    altura integer,
    formato varchar(16),
    alt_text varchar(255),
    arquivo_path varchar(255) NOT NULL,
    arquivo_original varchar(255),
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

CREATE INDEX IF NOT EXISTS tb_portal_banners_lookup_idx
    ON tb_portal_banners (canal, local_layout, status);

CREATE INDEX IF NOT EXISTS tb_portal_banners_periodo_idx
    ON tb_portal_banners (inicio_exibicao, fim_exibicao);

CREATE TABLE IF NOT EXISTS tb_portal_banners_log (
    id_banner_log bigserial PRIMARY KEY,
    id_banner integer NOT NULL REFERENCES tb_portal_banners (id_banner) ON DELETE CASCADE,
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
    ON tb_portal_banners_log (id_banner, tipo_evento, criado_em DESC);

CREATE INDEX IF NOT EXISTS tb_portal_banners_log_slot_idx
    ON tb_portal_banners_log (canal, local_layout, tipo_evento, criado_em DESC);
