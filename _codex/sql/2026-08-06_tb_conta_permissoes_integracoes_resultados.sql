-- Autorizacao por capacidade e escopo de integracoes de resultados no Business.
-- A conta nao precisa possuir eventos para receber estas permissoes.

create table if not exists public.tb_business_permissoes
(
    id_permissao    bigserial
        constraint tb_business_permissoes_pk
            primary key,
    codigo           varchar(100)                                          not null,
    descricao        varchar(255)                                          not null,
    ativo            boolean                  default true                  not null,
    data_criacao     timestamp with time zone default now()                 not null,
    data_atualizacao timestamp with time zone default now()                 not null,
    constraint tb_business_permissoes_codigo_uq
        unique (codigo),
    constraint tb_business_permissoes_codigo_ck
        check (codigo ~ '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$')
);

alter table public.tb_business_permissoes
    owner to runner_dba;

create table if not exists public.tb_conta_permissoes
(
    id_conta_permissao bigserial
        constraint tb_conta_permissoes_pk
            primary key,
    id_conta           bigint                                               not null
        constraint tb_conta_permissoes_conta_fk
            references public.tb_contas
            on delete cascade,
    id_permissao       bigint                                               not null
        constraint tb_conta_permissoes_permissao_fk
            references public.tb_business_permissoes
            on delete cascade,
    papel              public.papel_usuario_conta                           not null,
    ativo              boolean                  default true                 not null,
    usuario_concessao  bigint
        constraint tb_conta_permissoes_usuario_fk
            references public.tb_usuarios
            on delete set null,
    data_criacao       timestamp with time zone default now()                not null,
    data_atualizacao   timestamp with time zone default now()                not null,
    constraint tb_conta_permissoes_conta_permissao_papel_uq
        unique (id_conta, id_permissao, papel)
);

alter table public.tb_conta_permissoes
    owner to runner_dba;

create index if not exists tb_conta_permissoes_acesso_idx
    on public.tb_conta_permissoes (id_conta, papel, ativo, id_permissao);

-- Nome curto e explicito para evitar o limite de 63 bytes dos identificadores.
create sequence if not exists public.tb_conta_resultados_integracao_id_seq
    as bigint;

alter sequence public.tb_conta_resultados_integracao_id_seq
    owner to runner_dba;

create table if not exists public.tb_conta_integracoes_resultados
(
    id_conta_integracao_resultado bigint default nextval('public.tb_conta_resultados_integracao_id_seq'::regclass)
        constraint tb_conta_integracoes_resultados_pk
            primary key,
    id_conta                      bigint                                               not null
        constraint tb_conta_integracoes_resultados_conta_fk
            references public.tb_contas
            on delete cascade,
    client_id                     varchar(128)                                         not null,
    cod_timer                     varchar(64)                                          not null,
    external_account_id           varchar(128),
    abrange_contas_externas       boolean                  default false                not null,
    ativo                         boolean                  default true                 not null,
    usuario_cadastro              bigint
        constraint tb_conta_integracoes_resultados_usuario_fk
            references public.tb_usuarios
            on delete set null,
    data_criacao                  timestamp with time zone default now()                not null,
    data_atualizacao              timestamp with time zone default now()                not null,
    constraint tb_conta_integracoes_resultados_client_id_ck
        check (length(trim(client_id)) between 1 and 128),
    constraint tb_conta_integracoes_resultados_timer_ck
        check (length(trim(cod_timer)) between 1 and 64),
    constraint tb_conta_integracoes_resultados_escopo_ck
        check (
            (abrange_contas_externas = true and external_account_id is null)
            or abrange_contas_externas = false
        )
);

alter table public.tb_conta_integracoes_resultados
    owner to runner_dba;

-- Tambem repara bancos onde a tabela foi criada por uma versao anterior da
-- migracao antes de ela falhar no GRANT da sequencia com nome longo.
alter table public.tb_conta_integracoes_resultados
    alter column id_conta_integracao_resultado
        set default nextval('public.tb_conta_resultados_integracao_id_seq'::regclass);

do $$
declare
    maximum_existing_id bigint;
    current_sequence_value bigint;
begin
    select max(id_conta_integracao_resultado)
    into maximum_existing_id
    from public.tb_conta_integracoes_resultados;

    if maximum_existing_id is not null then
        select last_value
        into current_sequence_value
        from public.tb_conta_resultados_integracao_id_seq;

        if maximum_existing_id >= current_sequence_value then
            perform setval(
                'public.tb_conta_resultados_integracao_id_seq'::regclass,
                maximum_existing_id,
                true
            );
        end if;
    end if;
end
$$;

create unique index if not exists tb_conta_integracoes_resultados_escopo_uq
    on public.tb_conta_integracoes_resultados
    (
        id_conta,
        lower(trim(client_id)),
        lower(trim(cod_timer)),
        coalesce(trim(external_account_id), ''),
        abrange_contas_externas
    )
    where ativo = true;

-- Um escopo ativo tem um unico responsavel. Um provedor global e contas externas
-- especificas podem coexistir porque representam niveis diferentes de acesso.
create unique index if not exists tb_conta_integracoes_resultados_client_global_uq
    on public.tb_conta_integracoes_resultados
    (lower(trim(client_id)), lower(trim(cod_timer)))
    where ativo = true and abrange_contas_externas = true;

create unique index if not exists tb_conta_integracoes_resultados_conta_externa_uq
    on public.tb_conta_integracoes_resultados
    (lower(trim(client_id)), lower(trim(cod_timer)), coalesce(trim(external_account_id), ''))
    where ativo = true and abrange_contas_externas = false;

create index if not exists tb_conta_integracoes_resultados_consulta_idx
    on public.tb_conta_integracoes_resultados
    (id_conta, ativo, lower(trim(client_id)), lower(trim(cod_timer)));

insert into public.tb_business_permissoes (codigo, descricao)
values
    ('result_imports.view', 'Visualizar a fila de importacoes de resultados da conta'),
    ('result_imports.process', 'Processar manualmente importacoes de resultados da conta')
on conflict (codigo)
do update set
    descricao = excluded.descricao,
    ativo = true,
    data_atualizacao = now();

-- Nomes de sequencias de bigserial podem ser truncados pelo limite de 63 bytes
-- do PostgreSQL. Resolva o nome efetivo pelo catalogo em vez de pressupor o nome.
do $$
declare
    sequence_name text;
begin
    sequence_name := pg_get_serial_sequence('public.tb_business_permissoes', 'id_permissao');
    if sequence_name is not null then
        execute format('grant select, usage on sequence %s to runner', sequence_name);
    end if;

    sequence_name := pg_get_serial_sequence('public.tb_conta_permissoes', 'id_conta_permissao');
    if sequence_name is not null then
        execute format('grant select, usage on sequence %s to runner', sequence_name);
    end if;

end
$$;

grant select, usage on sequence public.tb_conta_resultados_integracao_id_seq to runner;
grant select on public.tb_business_permissoes to runner;
grant delete, insert, select, update on public.tb_conta_permissoes to runner;
grant delete, insert, select, update on public.tb_conta_integracoes_resultados to runner;
