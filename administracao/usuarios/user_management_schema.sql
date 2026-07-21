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

-- Atualiza uma referência linha a linha. Quando a troca produzir uma chave já
-- existente, a linha da conta/página de origem é removida como duplicata.
CREATE OR REPLACE FUNCTION user_manager_merge_reference(
    p_schema text,
    p_table text,
    p_column text,
    p_source bigint,
    p_keep bigint
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_row record;
    v_moved integer := 0;
    v_deduplicated integer := 0;
BEGIN
    FOR v_row IN EXECUTE format(
        'SELECT ctid FROM %I.%I WHERE %I = $1 FOR UPDATE',
        p_schema, p_table, p_column
    ) USING p_source
    LOOP
        BEGIN
            EXECUTE format(
                'UPDATE %I.%I SET %I = $1 WHERE ctid = $2',
                p_schema, p_table, p_column
            ) USING p_keep, v_row.ctid;
            v_moved := v_moved + 1;
        EXCEPTION WHEN unique_violation OR check_violation OR exclusion_violation THEN
            EXECUTE format('DELETE FROM %I.%I WHERE ctid = $1', p_schema, p_table)
                USING v_row.ctid;
            v_deduplicated := v_deduplicated + 1;
        END;
    END LOOP;

    RETURN jsonb_build_object('migrados', v_moved, 'deduplicados', v_deduplicated);
END;
$$;

CREATE OR REPLACE FUNCTION user_manager_merge_users(
    p_keep_user integer,
    p_source_user integer,
    p_actor_user integer
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_source_page record;
    v_keep_page integer;
    v_reference record;
    v_result jsonb;
    v_operations jsonb := '[]'::jsonb;
    v_pages_merged integer := 0;
    v_pages_transferred integer := 0;
BEGIN
    IF p_keep_user IS NULL OR p_source_user IS NULL OR p_keep_user = p_source_user THEN
        RAISE EXCEPTION 'As contas de origem e destino devem ser diferentes.';
    END IF;
    IF p_source_user = p_actor_user THEN
        RAISE EXCEPTION 'A conta da sessão administrativa não pode ser removida.';
    END IF;

    -- Serializa merges concorrentes e confirma que ambas as contas existem.
    PERFORM id FROM public.tb_usuarios
     WHERE id IN (p_keep_user, p_source_user)
     ORDER BY id FOR UPDATE;
    IF NOT EXISTS (SELECT 1 FROM public.tb_usuarios WHERE id = p_keep_user)
       OR NOT EXISTS (SELECT 1 FROM public.tb_usuarios WHERE id = p_source_user) THEN
        RAISE EXCEPTION 'Uma das contas selecionadas não existe mais.';
    END IF;

    -- A conta mantida tem prioridade; lacunas cadastrais são preenchidas pela origem.
    WITH source_values AS (
        SELECT * FROM public.tb_usuarios WHERE id = p_source_user
    ), source AS (
        -- Libera identificadores únicos, preservando os valores antigos no CTE.
        UPDATE public.tb_usuarios usr
           SET username = NULL, strava_id = NULL
          FROM source_values old
         WHERE usr.id = old.id
         RETURNING old.*
    )
    UPDATE public.tb_usuarios keep
       SET name = coalesce(nullif(btrim(keep.name), ''), source.name),
           username = coalesce(nullif(btrim(keep.username), ''), source.username),
           aka = coalesce(nullif(btrim(keep.aka), ''), source.aka),
           genero = coalesce(nullif(btrim(keep.genero), ''), source.genero),
           pais = coalesce(nullif(btrim(keep.pais), ''), source.pais),
           estado = coalesce(nullif(btrim(keep.estado), ''), source.estado),
           cidade = coalesce(nullif(btrim(keep.cidade), ''), source.cidade),
           cep = coalesce(nullif(btrim(keep.cep), ''), source.cep),
           endereco = coalesce(nullif(btrim(keep.endereco), ''), source.endereco),
           data_nascimento = coalesce(keep.data_nascimento, source.data_nascimento),
           ano_nascimento = coalesce(keep.ano_nascimento, source.ano_nascimento),
           cbat = coalesce(nullif(btrim(keep.cbat), ''), source.cbat),
           assessoria = coalesce(nullif(btrim(keep.assessoria), ''), source.assessoria),
           ddi_usuario = coalesce(nullif(btrim(keep.ddi_usuario), ''), source.ddi_usuario),
           ddd_usuario = coalesce(nullif(btrim(keep.ddd_usuario), ''), source.ddd_usuario),
           telefone_usuario = coalesce(nullif(btrim(keep.telefone_usuario), ''), source.telefone_usuario),
           imagem_usuario = coalesce(nullif(btrim(keep.imagem_usuario), ''), source.imagem_usuario),
           strava_id = coalesce(keep.strava_id, source.strava_id),
           strava_profile = coalesce(nullif(btrim(keep.strava_profile), ''), source.strava_profile),
           tag_usuario = coalesce(nullif(btrim(keep.tag_usuario), ''), source.tag_usuario),
           url_usuario = coalesce(nullif(btrim(keep.url_usuario), ''), source.url_usuario),
           fonte_lead = coalesce(nullif(btrim(keep.fonte_lead), ''), source.fonte_lead),
           manychat_subscriber_id = coalesce(keep.manychat_subscriber_id, source.manychat_subscriber_id),
           is_admin = coalesce(keep.is_admin, false) OR coalesce(source.is_admin, false),
           is_dev = coalesce(keep.is_dev, false) OR coalesce(source.is_dev, false),
           is_partner = coalesce(keep.is_partner, false) OR coalesce(source.is_partner, false),
           is_email_verified = coalesce(keep.is_email_verified, false) OR coalesce(source.is_email_verified, false),
           optin_usuario = coalesce(keep.optin_usuario, false) OR coalesce(source.optin_usuario, false),
           data_alteracao = now()
      FROM public.tb_usuarios source
     WHERE keep.id = p_keep_user AND source.id = p_source_user;

    -- Perfis do mesmo tipo são consolidados. Tipos que só existem na origem são transferidos.
    FOR v_source_page IN
        SELECT DISTINCT pag.id_pagina, pag.tag_prefix
          FROM public.tb_paginas pag
          JOIN public.tb_paginas_usuarios pu ON pu.id_pagina = pag.id_pagina
         WHERE pu.id_usuario = p_source_user
         ORDER BY pag.id_pagina
    LOOP
        SELECT min(pag.id_pagina) INTO v_keep_page
          FROM public.tb_paginas pag
          JOIN public.tb_paginas_usuarios pu ON pu.id_pagina = pag.id_pagina
         WHERE pu.id_usuario = p_keep_user
           AND pag.tag_prefix = v_source_page.tag_prefix
           AND pag.id_pagina <> v_source_page.id_pagina;

        IF v_keep_page IS NULL THEN
            UPDATE public.tb_paginas SET id_usuario_cadastro = p_keep_user
             WHERE id_pagina = v_source_page.id_pagina AND id_usuario_cadastro = p_source_user;
            INSERT INTO public.tb_paginas_usuarios (id_pagina, id_usuario)
            SELECT v_source_page.id_pagina, p_keep_user
             WHERE NOT EXISTS (
                SELECT 1 FROM public.tb_paginas_usuarios
                 WHERE id_pagina = v_source_page.id_pagina AND id_usuario = p_keep_user
             );
            DELETE FROM public.tb_paginas_usuarios
             WHERE id_pagina = v_source_page.id_pagina AND id_usuario = p_source_user;
            v_pages_transferred := v_pages_transferred + 1;
        ELSE
            UPDATE public.tb_paginas keep
               SET nome = coalesce(nullif(btrim(keep.nome), ''), source.nome),
                   apelido = coalesce(nullif(btrim(keep.apelido), ''), source.apelido),
                   instagram = coalesce(nullif(btrim(keep.instagram), ''), source.instagram),
                   whatsapp = coalesce(nullif(btrim(keep.whatsapp), ''), source.whatsapp),
                   facebook = coalesce(nullif(btrim(keep.facebook), ''), source.facebook),
                   website = coalesce(nullif(btrim(keep.website), ''), source.website),
                   youtube = coalesce(nullif(btrim(keep.youtube), ''), source.youtube),
                   tiktok = coalesce(nullif(btrim(keep.tiktok), ''), source.tiktok),
                   loja = coalesce(nullif(btrim(keep.loja), ''), source.loja),
                   path_imagem = coalesce(nullif(btrim(keep.path_imagem), ''), source.path_imagem),
                   cidade = coalesce(nullif(btrim(keep.cidade), ''), source.cidade),
                   uf = coalesce(nullif(btrim(keep.uf), ''), source.uf),
                   descricao = coalesce(nullif(btrim(keep.descricao), ''), source.descricao),
                   verificado = coalesce(keep.verificado, false) OR coalesce(source.verificado, false),
                   profissional = coalesce(keep.profissional, false) OR coalesce(source.profissional, false)
              FROM public.tb_paginas source
             WHERE keep.id_pagina = v_keep_page AND source.id_pagina = v_source_page.id_pagina;

            FOR v_reference IN
                SELECT DISTINCT n.nspname AS schema_name, c.relname AS table_name, a.attname AS column_name
                  FROM pg_constraint fk
                  JOIN pg_class c ON c.oid = fk.conrelid
                  JOIN pg_namespace n ON n.oid = c.relnamespace
                  JOIN pg_class parent ON parent.oid = fk.confrelid
                  JOIN unnest(fk.conkey) WITH ORDINALITY cols(attnum, ord) ON true
                  JOIN pg_attribute a ON a.attrelid = fk.conrelid AND a.attnum = cols.attnum
                 WHERE fk.contype = 'f' AND parent.oid = 'public.tb_paginas'::regclass
                   AND n.nspname NOT IN ('pg_catalog', 'information_schema')
                   AND c.oid <> 'public.tb_paginas'::regclass
            LOOP
                v_result := public.user_manager_merge_reference(v_reference.schema_name, v_reference.table_name,
                    v_reference.column_name, v_source_page.id_pagina, v_keep_page);
                v_operations := v_operations || jsonb_build_array(jsonb_build_object(
                    'tabela', v_reference.schema_name || '.' || v_reference.table_name,
                    'coluna', v_reference.column_name, 'resumo', v_result));
            END LOOP;
            DELETE FROM public.tb_paginas WHERE id_pagina = v_source_page.id_pagina;
            v_pages_merged := v_pages_merged + 1;
        END IF;
    END LOOP;

    DELETE FROM public.tb_paginas_usuarios a
     USING public.tb_paginas_usuarios b
     WHERE a.ctid > b.ctid AND a.id_pagina = b.id_pagina AND a.id_usuario = b.id_usuario;
    DELETE FROM public.tb_paginas_vinculos WHERE id_pagina_origem = id_pagina_destino;

    -- Todas as referências FK da conta são migradas, inclusive módulos adicionados no futuro.
    FOR v_reference IN
        SELECT DISTINCT n.nspname AS schema_name, c.relname AS table_name, a.attname AS column_name
          FROM pg_constraint fk
          JOIN pg_class c ON c.oid = fk.conrelid
          JOIN pg_namespace n ON n.oid = c.relnamespace
          JOIN pg_class parent ON parent.oid = fk.confrelid
          JOIN unnest(fk.conkey) WITH ORDINALITY cols(attnum, ord) ON true
          JOIN pg_attribute a ON a.attrelid = fk.conrelid AND a.attnum = cols.attnum
         WHERE fk.contype = 'f' AND parent.oid = 'public.tb_usuarios'::regclass
           AND n.nspname NOT IN ('pg_catalog', 'information_schema')
           AND c.oid <> 'public.tb_usuarios'::regclass
    LOOP
        v_result := public.user_manager_merge_reference(v_reference.schema_name, v_reference.table_name,
            v_reference.column_name, p_source_user, p_keep_user);
        v_operations := v_operations || jsonb_build_array(jsonb_build_object(
            'tabela', v_reference.schema_name || '.' || v_reference.table_name,
            'coluna', v_reference.column_name, 'resumo', v_result));
    END LOOP;

    -- A troca do usuário pode fazer duas associações da mesma página convergirem.
    DELETE FROM public.tb_paginas_usuarios a
     USING public.tb_paginas_usuarios b
     WHERE a.ctid > b.ctid AND a.id_pagina = b.id_pagina AND a.id_usuario = b.id_usuario;

    -- Colunas históricas sem FK, mas com o nome canônico, também são preservadas.
    FOR v_reference IN
        SELECT c.table_schema AS schema_name, c.table_name, c.column_name
          FROM information_schema.columns c
          JOIN information_schema.tables tbl ON tbl.table_schema = c.table_schema
                                             AND tbl.table_name = c.table_name
                                             AND tbl.table_type = 'BASE TABLE'
         WHERE c.column_name = 'id_usuario'
           AND c.table_schema NOT IN ('pg_catalog', 'information_schema')
           AND c.table_name <> 'tb_usuarios'
           AND NOT EXISTS (
                SELECT 1
                  FROM pg_constraint fk
                  JOIN pg_class rel ON rel.oid = fk.conrelid
                  JOIN pg_namespace ns ON ns.oid = rel.relnamespace
                  JOIN unnest(fk.conkey) key(attnum) ON true
                  JOIN pg_attribute att ON att.attrelid = rel.oid AND att.attnum = key.attnum
                 WHERE fk.contype = 'f' AND ns.nspname = c.table_schema
                   AND rel.relname = c.table_name AND att.attname = c.column_name
           )
    LOOP
        v_result := public.user_manager_merge_reference(v_reference.schema_name, v_reference.table_name,
            v_reference.column_name, p_source_user, p_keep_user);
        v_operations := v_operations || jsonb_build_array(jsonb_build_object(
            'tabela', v_reference.schema_name || '.' || v_reference.table_name,
            'coluna', v_reference.column_name, 'resumo', v_result));
    END LOOP;

    DELETE FROM public.tb_usuarios WHERE id = p_source_user;

    INSERT INTO public.tb_usuarios_gestao_auditoria
        (id_usuario_alvo, id_usuario_autor, acao, dados_anteriores, dados_novos)
    VALUES (p_keep_user, p_actor_user, 'usuarios_mesclados',
        jsonb_build_object('id_usuario_origem', p_source_user),
        jsonb_build_object('id_usuario_mantido', p_keep_user, 'paginas_mescladas', v_pages_merged,
                           'paginas_transferidas', v_pages_transferred, 'operacoes', v_operations));

    RETURN jsonb_build_object('id_usuario_mantido', p_keep_user, 'id_usuario_removido', p_source_user,
        'paginas_mescladas', v_pages_merged, 'paginas_transferidas', v_pages_transferred,
        'operacoes', v_operations);
END;
$$;

GRANT SELECT, INSERT, UPDATE, DELETE ON tb_usuarios_gestao TO runner;
GRANT SELECT, INSERT, UPDATE, DELETE ON tb_paginas_gestao TO runner;
GRANT SELECT, INSERT ON tb_usuarios_gestao_auditoria TO runner;
GRANT SELECT, USAGE ON SEQUENCE tb_usuarios_gestao_auditoria_id_auditoria_seq TO runner;
REVOKE ALL ON FUNCTION user_manager_merge_reference(text, text, text, bigint, bigint) FROM PUBLIC;
REVOKE ALL ON FUNCTION user_manager_merge_users(integer, integer, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION user_manager_merge_users(integer, integer, integer) TO runner;

COMMIT;
