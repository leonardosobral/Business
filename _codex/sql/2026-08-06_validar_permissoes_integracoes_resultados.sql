-- Validacao somente leitura da estrutura criada por
-- 2026-08-06_tb_conta_permissoes_integracoes_resultados.sql.
--
-- Resultado esperado:
--   NOTICE: VALIDACAO OK: estrutura, dados-base e privilegios conferidos.
--   Uma linha final com resultado = OK.
--
-- Se algo estiver ausente ou divergente, o bloco termina com uma excecao que
-- lista todos os problemas encontrados. Nenhum dado persistente e alterado.

do $$
declare
    problems text[] := array[]::text[];
    item record;
    actual_default text;
    serial_sequence text;
    maximum_existing_id bigint;
    current_sequence_value bigint;
    sequence_was_called boolean;
    duplicate_count bigint;
    permission_count bigint;
begin
    -- Objetos principais.
    if to_regclass('public.tb_business_permissoes') is null then
        problems := array_append(problems, 'Tabela public.tb_business_permissoes nao existe.');
    end if;

    if to_regclass('public.tb_conta_permissoes') is null then
        problems := array_append(problems, 'Tabela public.tb_conta_permissoes nao existe.');
    end if;

    if to_regclass('public.tb_conta_integracoes_resultados') is null then
        problems := array_append(problems, 'Tabela public.tb_conta_integracoes_resultados nao existe.');
    end if;

    if to_regclass('public.tb_conta_resultados_integracao_id_seq') is null then
        problems := array_append(problems, 'Sequencia public.tb_conta_resultados_integracao_id_seq nao existe.');
    end if;

    -- Colunas, tipos e nulabilidade.
    for item in
        select *
        from (values
            ('tb_business_permissoes', 'id_permissao', 'int8', 'NO'),
            ('tb_business_permissoes', 'codigo', 'varchar', 'NO'),
            ('tb_business_permissoes', 'descricao', 'varchar', 'NO'),
            ('tb_business_permissoes', 'ativo', 'bool', 'NO'),
            ('tb_business_permissoes', 'data_criacao', 'timestamptz', 'NO'),
            ('tb_business_permissoes', 'data_atualizacao', 'timestamptz', 'NO'),

            ('tb_conta_permissoes', 'id_conta_permissao', 'int8', 'NO'),
            ('tb_conta_permissoes', 'id_conta', 'int8', 'NO'),
            ('tb_conta_permissoes', 'id_permissao', 'int8', 'NO'),
            ('tb_conta_permissoes', 'papel', 'papel_usuario_conta', 'NO'),
            ('tb_conta_permissoes', 'ativo', 'bool', 'NO'),
            ('tb_conta_permissoes', 'usuario_concessao', 'int8', 'YES'),
            ('tb_conta_permissoes', 'data_criacao', 'timestamptz', 'NO'),
            ('tb_conta_permissoes', 'data_atualizacao', 'timestamptz', 'NO'),

            ('tb_conta_integracoes_resultados', 'id_conta_integracao_resultado', 'int8', 'NO'),
            ('tb_conta_integracoes_resultados', 'id_conta', 'int8', 'NO'),
            ('tb_conta_integracoes_resultados', 'client_id', 'varchar', 'NO'),
            ('tb_conta_integracoes_resultados', 'cod_timer', 'varchar', 'NO'),
            ('tb_conta_integracoes_resultados', 'external_account_id', 'varchar', 'YES'),
            ('tb_conta_integracoes_resultados', 'abrange_contas_externas', 'bool', 'NO'),
            ('tb_conta_integracoes_resultados', 'ativo', 'bool', 'NO'),
            ('tb_conta_integracoes_resultados', 'usuario_cadastro', 'int8', 'YES'),
            ('tb_conta_integracoes_resultados', 'data_criacao', 'timestamptz', 'NO'),
            ('tb_conta_integracoes_resultados', 'data_atualizacao', 'timestamptz', 'NO')
        ) as expected(table_name, column_name, udt_name, is_nullable)
    loop
        if not exists (
            select 1
            from information_schema.columns columns
            where columns.table_schema = 'public'
              and columns.table_name = item.table_name
              and columns.column_name = item.column_name
              and columns.udt_name = item.udt_name
              and columns.is_nullable = item.is_nullable
        ) then
            problems := array_append(
                problems,
                format(
                    'Coluna public.%I.%I ausente ou divergente; esperado tipo %s e nullable=%s.',
                    item.table_name,
                    item.column_name,
                    item.udt_name,
                    item.is_nullable
                )
            );
        end if;
    end loop;

    -- Constraints esperadas e validadas pelo PostgreSQL.
    for item in
        select *
        from (values
            ('tb_business_permissoes', 'tb_business_permissoes_pk', 'p'),
            ('tb_business_permissoes', 'tb_business_permissoes_codigo_uq', 'u'),
            ('tb_business_permissoes', 'tb_business_permissoes_codigo_ck', 'c'),
            ('tb_conta_permissoes', 'tb_conta_permissoes_pk', 'p'),
            ('tb_conta_permissoes', 'tb_conta_permissoes_conta_fk', 'f'),
            ('tb_conta_permissoes', 'tb_conta_permissoes_permissao_fk', 'f'),
            ('tb_conta_permissoes', 'tb_conta_permissoes_usuario_fk', 'f'),
            ('tb_conta_permissoes', 'tb_conta_permissoes_conta_permissao_papel_uq', 'u'),
            ('tb_conta_integracoes_resultados', 'tb_conta_integracoes_resultados_pk', 'p'),
            ('tb_conta_integracoes_resultados', 'tb_conta_integracoes_resultados_conta_fk', 'f'),
            ('tb_conta_integracoes_resultados', 'tb_conta_integracoes_resultados_usuario_fk', 'f'),
            ('tb_conta_integracoes_resultados', 'tb_conta_integracoes_resultados_client_id_ck', 'c'),
            ('tb_conta_integracoes_resultados', 'tb_conta_integracoes_resultados_timer_ck', 'c'),
            ('tb_conta_integracoes_resultados', 'tb_conta_integracoes_resultados_escopo_ck', 'c')
        ) as expected(table_name, constraint_name, constraint_type)
    loop
        if not exists (
            select 1
            from pg_catalog.pg_constraint constraints
            where constraints.conrelid = to_regclass(format('public.%I', item.table_name))
              and constraints.conname = item.constraint_name
              and constraints.contype::text = item.constraint_type
              and constraints.convalidated = true
        ) then
            problems := array_append(
                problems,
                format(
                    'Constraint public.%I.%I ausente, de tipo incorreto ou nao validada.',
                    item.table_name,
                    item.constraint_name
                )
            );
        end if;
    end loop;

    -- Indices, incluindo unicidade e estado operacional.
    for item in
        select *
        from (values
            ('tb_conta_permissoes_acesso_idx', false),
            ('tb_conta_integracoes_resultados_escopo_uq', true),
            ('tb_conta_integracoes_resultados_client_global_uq', true),
            ('tb_conta_integracoes_resultados_conta_externa_uq', true),
            ('tb_conta_integracoes_resultados_consulta_idx', false)
        ) as expected(index_name, must_be_unique)
    loop
        if not exists (
            select 1
            from pg_catalog.pg_class indexes
            join pg_catalog.pg_namespace namespaces
              on namespaces.oid = indexes.relnamespace
            join pg_catalog.pg_index index_metadata
              on index_metadata.indexrelid = indexes.oid
            where namespaces.nspname = 'public'
              and indexes.relname = item.index_name
              and indexes.relkind = 'i'
              and index_metadata.indisunique = item.must_be_unique
              and index_metadata.indisvalid = true
              and index_metadata.indisready = true
        ) then
            problems := array_append(
                problems,
                format(
                    'Indice public.%I ausente, com unicidade incorreta ou invalido.',
                    item.index_name
                )
            );
        end if;
    end loop;

    -- Donos dos objetos criados.
    for item in
        select *
        from (values
            ('tb_business_permissoes', 'r'),
            ('tb_conta_permissoes', 'r'),
            ('tb_conta_integracoes_resultados', 'r'),
            ('tb_conta_resultados_integracao_id_seq', 'S')
        ) as expected(object_name, relation_kind)
    loop
        if not exists (
            select 1
            from pg_catalog.pg_class objects
            join pg_catalog.pg_namespace namespaces
              on namespaces.oid = objects.relnamespace
            join pg_catalog.pg_roles owners
              on owners.oid = objects.relowner
            where namespaces.nspname = 'public'
              and objects.relname = item.object_name
              and objects.relkind::text = item.relation_kind
              and owners.rolname = 'runner_dba'
        ) then
            problems := array_append(
                problems,
                format('Objeto public.%I nao existe com owner runner_dba.', item.object_name)
            );
        end if;
    end loop;

    -- DEFAULT da chave da integracao deve usar a sequencia curta.
    select columns.column_default
    into actual_default
    from information_schema.columns columns
    where columns.table_schema = 'public'
      and columns.table_name = 'tb_conta_integracoes_resultados'
      and columns.column_name = 'id_conta_integracao_resultado';

    if position('tb_conta_resultados_integracao_id_seq' in coalesce(actual_default, '')) = 0 then
        problems := array_append(
            problems,
            format(
                'DEFAULT de tb_conta_integracoes_resultados.id_conta_integracao_resultado incorreto: %s.',
                coalesce(actual_default, '<null>')
            )
        );
    end if;

    -- Dados-base e duplicidades. Os EXECUTEs evitam erro de parse caso uma
    -- tabela esteja ausente e permitem entregar a lista completa de problemas.
    if to_regclass('public.tb_business_permissoes') is not null then
        execute $query$
            select count(*)
            from public.tb_business_permissoes
            where codigo in ('result_imports.view', 'result_imports.process')
              and ativo = true
        $query$
        into permission_count;

        if permission_count <> 2 then
            problems := array_append(
                problems,
                format(
                    'Esperadas 2 permissoes ativas de importacao; encontradas %s.',
                    permission_count
                )
            );
        end if;
    end if;

    if to_regclass('public.tb_conta_permissoes') is not null then
        execute $query$
            select count(*)
            from (
                select id_conta, id_permissao, papel
                from public.tb_conta_permissoes
                group by id_conta, id_permissao, papel
                having count(*) > 1
            ) duplicates
        $query$
        into duplicate_count;

        if duplicate_count > 0 then
            problems := array_append(
                problems,
                format('Existem %s grupos duplicados em tb_conta_permissoes.', duplicate_count)
            );
        end if;
    end if;

    if to_regclass('public.tb_conta_integracoes_resultados') is not null then
        execute $query$
            select count(*)
            from (
                select lower(trim(client_id)), lower(trim(cod_timer))
                from public.tb_conta_integracoes_resultados
                where ativo = true
                  and abrange_contas_externas = true
                group by lower(trim(client_id)), lower(trim(cod_timer))
                having count(*) > 1
            ) duplicates
        $query$
        into duplicate_count;

        if duplicate_count > 0 then
            problems := array_append(
                problems,
                format('Existem %s escopos globais ativos duplicados.', duplicate_count)
            );
        end if;

        execute $query$
            select count(*)
            from (
                select lower(trim(client_id)),
                       lower(trim(cod_timer)),
                       coalesce(trim(external_account_id), '')
                from public.tb_conta_integracoes_resultados
                where ativo = true
                  and abrange_contas_externas = false
                group by lower(trim(client_id)),
                         lower(trim(cod_timer)),
                         coalesce(trim(external_account_id), '')
                having count(*) > 1
            ) duplicates
        $query$
        into duplicate_count;

        if duplicate_count > 0 then
            problems := array_append(
                problems,
                format('Existem %s escopos externos ativos duplicados.', duplicate_count)
            );
        end if;
    end if;

    -- Estado da sequencia curta em relacao aos IDs ja existentes.
    if to_regclass('public.tb_conta_resultados_integracao_id_seq') is not null
       and to_regclass('public.tb_conta_integracoes_resultados') is not null then
        execute 'select max(id_conta_integracao_resultado) from public.tb_conta_integracoes_resultados'
        into maximum_existing_id;

        execute 'select last_value, is_called from public.tb_conta_resultados_integracao_id_seq'
        into current_sequence_value, sequence_was_called;

        if maximum_existing_id is not null
           and (
               (sequence_was_called and current_sequence_value < maximum_existing_id)
               or (not sequence_was_called and current_sequence_value <= maximum_existing_id)
           ) then
            problems := array_append(
                problems,
                format(
                    'Sequencia curta dessincronizada: last_value=%s, is_called=%s, maior ID=%s.',
                    current_sequence_value,
                    sequence_was_called,
                    maximum_existing_id
                )
            );
        end if;
    end if;

    -- Privilegios usados pela aplicacao.
    if not exists (select 1 from pg_catalog.pg_roles where rolname = 'runner') then
        problems := array_append(problems, 'Role runner nao existe.');
    else
        if to_regclass('public.tb_business_permissoes') is not null
           and not has_table_privilege('runner', 'public.tb_business_permissoes', 'SELECT') then
            problems := array_append(problems, 'runner nao possui SELECT em tb_business_permissoes.');
        end if;

        if to_regclass('public.tb_conta_permissoes') is not null
           and not (
               has_table_privilege('runner', 'public.tb_conta_permissoes', 'SELECT')
               and has_table_privilege('runner', 'public.tb_conta_permissoes', 'INSERT')
               and has_table_privilege('runner', 'public.tb_conta_permissoes', 'UPDATE')
               and has_table_privilege('runner', 'public.tb_conta_permissoes', 'DELETE')
           ) then
            problems := array_append(problems, 'runner nao possui SELECT, INSERT, UPDATE e DELETE em tb_conta_permissoes.');
        end if;

        if to_regclass('public.tb_conta_integracoes_resultados') is not null
           and not (
               has_table_privilege('runner', 'public.tb_conta_integracoes_resultados', 'SELECT')
               and has_table_privilege('runner', 'public.tb_conta_integracoes_resultados', 'INSERT')
               and has_table_privilege('runner', 'public.tb_conta_integracoes_resultados', 'UPDATE')
               and has_table_privilege('runner', 'public.tb_conta_integracoes_resultados', 'DELETE')
           ) then
            problems := array_append(problems, 'runner nao possui SELECT, INSERT, UPDATE e DELETE em tb_conta_integracoes_resultados.');
        end if;

        serial_sequence := pg_get_serial_sequence('public.tb_business_permissoes', 'id_permissao');
        if serial_sequence is null then
            problems := array_append(problems, 'Sequencia serial de tb_business_permissoes.id_permissao nao foi localizada.');
        elsif not (
            has_sequence_privilege('runner', serial_sequence, 'SELECT')
            and has_sequence_privilege('runner', serial_sequence, 'USAGE')
        ) then
            problems := array_append(problems, format('runner nao possui SELECT e USAGE em %s.', serial_sequence));
        end if;

        serial_sequence := pg_get_serial_sequence('public.tb_conta_permissoes', 'id_conta_permissao');
        if serial_sequence is null then
            problems := array_append(problems, 'Sequencia serial de tb_conta_permissoes.id_conta_permissao nao foi localizada.');
        elsif not (
            has_sequence_privilege('runner', serial_sequence, 'SELECT')
            and has_sequence_privilege('runner', serial_sequence, 'USAGE')
        ) then
            problems := array_append(problems, format('runner nao possui SELECT e USAGE em %s.', serial_sequence));
        end if;

        if to_regclass('public.tb_conta_resultados_integracao_id_seq') is not null
           and not (
               has_sequence_privilege(
                   'runner',
                   'public.tb_conta_resultados_integracao_id_seq',
                   'SELECT'
               )
               and has_sequence_privilege(
                   'runner',
                   'public.tb_conta_resultados_integracao_id_seq',
                   'USAGE'
               )
           ) then
            problems := array_append(
                problems,
                'runner nao possui SELECT e USAGE em tb_conta_resultados_integracao_id_seq.'
            );
        end if;
    end if;

    if coalesce(array_length(problems, 1), 0) > 0 then
        raise exception E'VALIDACAO FALHOU (% problema(s)):\n - %',
            array_length(problems, 1),
            array_to_string(problems, E'\n - ');
    end if;

    -- A sequencia abaixo pode ter sobrado da primeira versao da migracao. Ela
    -- nao e usada pelo DEFAULT atual e nao representa falha funcional.
    if to_regclass('public.tb_conta_integracoes_resultad_id_conta_integracao_resultado_seq') is not null then
        raise notice 'AVISO: existe uma sequencia legada sem uso; ela pode ser removida em uma limpeza posterior.';
    end if;

    raise notice 'VALIDACAO OK: estrutura, dados-base e privilegios conferidos.';
end
$$;

select
    'OK'::text as resultado,
    current_database() as banco,
    current_user as usuario_validacao,
    now() as validado_em,
    3 as tabelas_conferidas,
    5 as indices_conferidos,
    2 as permissoes_base_conferidas;
