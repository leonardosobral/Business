CREATE TABLE IF NOT EXISTS tb_portal_runner_app_groups (
    id_group SERIAL PRIMARY KEY,
    nome VARCHAR(120) NOT NULL,
    descricao TEXT,
    ordem INTEGER NOT NULL DEFAULT 1,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    atualizado_em TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS tb_portal_runner_apps (
    id_app SERIAL PRIMARY KEY,
    id_group INTEGER NOT NULL REFERENCES tb_portal_runner_app_groups(id_group) ON DELETE RESTRICT,
    nome VARCHAR(120) NOT NULL,
    url TEXT NOT NULL,
    imagem_url TEXT NOT NULL,
    imagem_original VARCHAR(255),
    alt_text VARCHAR(180),
    abrir_nova_aba BOOLEAN NOT NULL DEFAULT FALSE,
    rel VARCHAR(120),
    ordem INTEGER NOT NULL DEFAULT 1,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    atualizado_em TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS tb_portal_runner_app_groups_ordem_idx
    ON tb_portal_runner_app_groups (ativo, ordem, id_group);

CREATE INDEX IF NOT EXISTS tb_portal_runner_apps_group_ordem_idx
    ON tb_portal_runner_apps (id_group, ativo, ordem, id_app);

INSERT INTO tb_portal_runner_app_groups (id_group, nome, descricao, ordem, ativo)
VALUES
    (1, 'Linha principal', 'Primeira linha do menu Runner Apps.', 1, TRUE),
    (2, 'Linha secundaria', 'Segunda linha do menu Runner Apps.', 2, TRUE)
ON CONFLICT (id_group) DO NOTHING;

SELECT setval(
    pg_get_serial_sequence('tb_portal_runner_app_groups', 'id_group'),
    GREATEST((SELECT max(id_group) FROM tb_portal_runner_app_groups), 1)
);

INSERT INTO tb_portal_runner_apps
    (id_group, nome, url, imagem_url, imagem_original, alt_text, abrir_nova_aba, rel, ordem, ativo)
SELECT seed.id_group,
       seed.nome,
       seed.url,
       seed.imagem_url,
       seed.imagem_original,
       seed.alt_text,
       seed.abrir_nova_aba,
       seed.rel,
       seed.ordem,
       seed.ativo
FROM (
    VALUES
        (1, 'Road Runners', '/', 'https://roadrunners.run/assets/rr_icon.jpg', 'rr_icon.jpg', 'Road Runners', FALSE, '', 1, TRUE),
        (1, 'Open Results', 'https://openresults.run/', 'https://roadrunners.run/assets/or_icon.jpg', 'or_icon.jpg', 'Open Results', TRUE, '', 2, TRUE),
        (1, 'Runners Store', 'https://store.roadrunners.run/', 'https://roadrunners.run/assets/rrs_icon.jpg', 'rrs_icon.jpg', 'Runners Store', TRUE, '', 3, TRUE),
        (2, 'Brasil Gigante', 'https://circuitobrasilgigante.com.br', 'https://roadrunners.run/assets/cbg_icon.png', 'cbg_icon.png', 'Brasil Gigante', TRUE, 'noopener', 1, TRUE),
        (2, 'Circuito Catarinense', 'https://roadrunners.run/circuitocatarinense/', 'https://roadrunners.run/assets/ico_fca.jpg', 'ico_fca.jpg', 'Circuito Catarinense', TRUE, '', 2, TRUE),
        (2, 'Todo Santo Dia', 'https://roadrunners.run/desafio/todosantodia/', 'https://roadrunners.run/assets/ico_tsd.jpg', 'ico_tsd.jpg', 'Todo Santo Dia', TRUE, '', 3, TRUE)
) AS seed(id_group, nome, url, imagem_url, imagem_original, alt_text, abrir_nova_aba, rel, ordem, ativo)
WHERE NOT EXISTS (
    SELECT 1
    FROM tb_portal_runner_apps app
    WHERE app.url = seed.url
);
