BEGIN;

CREATE TABLE IF NOT EXISTS tb_usuarios_gestao (
    id_usuario integer PRIMARY KEY REFERENCES tb_usuarios(id) ON UPDATE CASCADE ON DELETE CASCADE,
    ativo boolean NOT NULL DEFAULT true,
    excluido boolean NOT NULL DEFAULT false,
    motivo text,
    data_alteracao timestamp NOT NULL DEFAULT now(),
    id_usuario_alteracao integer REFERENCES tb_usuarios(id) ON UPDATE CASCADE ON DELETE SET NULL,
    data_exclusao timestamp,
    id_usuario_exclusao integer REFERENCES tb_usuarios(id) ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT tb_usuarios_gestao_exclusao_ck CHECK (
        (excluido = false AND data_exclusao IS NULL)
        OR (excluido = true AND ativo = false AND data_exclusao IS NOT NULL)
    )
);

CREATE TABLE IF NOT EXISTS tb_paginas_gestao (
    id_pagina integer PRIMARY KEY REFERENCES tb_paginas(id_pagina) ON UPDATE CASCADE ON DELETE CASCADE,
    ativo boolean NOT NULL DEFAULT true,
    excluido boolean NOT NULL DEFAULT false,
    motivo text,
    data_alteracao timestamp NOT NULL DEFAULT now(),
    id_usuario_alteracao integer REFERENCES tb_usuarios(id) ON UPDATE CASCADE ON DELETE SET NULL,
    data_exclusao timestamp,
    id_usuario_exclusao integer REFERENCES tb_usuarios(id) ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT tb_paginas_gestao_exclusao_ck CHECK (
        (excluido = false AND data_exclusao IS NULL)
        OR (excluido = true AND ativo = false AND data_exclusao IS NOT NULL)
    )
);

CREATE TABLE IF NOT EXISTS tb_usuarios_gestao_auditoria (
    id_auditoria bigserial PRIMARY KEY,
    id_usuario_alvo integer REFERENCES tb_usuarios(id) ON UPDATE CASCADE ON DELETE SET NULL,
    id_pagina_alvo integer REFERENCES tb_paginas(id_pagina) ON UPDATE CASCADE ON DELETE SET NULL,
    id_usuario_autor integer REFERENCES tb_usuarios(id) ON UPDATE CASCADE ON DELETE SET NULL,
    acao varchar(64) NOT NULL,
    dados_anteriores jsonb,
    dados_novos jsonb,
    endereco_ip varchar(64),
    user_agent varchar(512),
    data_criacao timestamp NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS tb_usuarios_gestao_estado_idx
    ON tb_usuarios_gestao (excluido, ativo, data_alteracao DESC);

CREATE INDEX IF NOT EXISTS tb_paginas_gestao_estado_idx
    ON tb_paginas_gestao (excluido, ativo, data_alteracao DESC);

CREATE INDEX IF NOT EXISTS tb_usuarios_gestao_auditoria_usuario_idx
    ON tb_usuarios_gestao_auditoria (id_usuario_alvo, data_criacao DESC);

CREATE INDEX IF NOT EXISTS tb_usuarios_gestao_auditoria_pagina_idx
    ON tb_usuarios_gestao_auditoria (id_pagina_alvo, data_criacao DESC);

CREATE INDEX IF NOT EXISTS tb_resultados_vinculo_usuario_ativo_idx
    ON tb_resultados_vinculo (id_usuario, id_resultado)
    WHERE vinculo_resultado = true;

GRANT SELECT, INSERT, UPDATE, DELETE ON tb_usuarios_gestao TO runner;
GRANT SELECT, INSERT, UPDATE, DELETE ON tb_paginas_gestao TO runner;
GRANT SELECT, INSERT ON tb_usuarios_gestao_auditoria TO runner;
GRANT SELECT, USAGE ON SEQUENCE tb_usuarios_gestao_auditoria_id_auditoria_seq TO runner;

COMMIT;
