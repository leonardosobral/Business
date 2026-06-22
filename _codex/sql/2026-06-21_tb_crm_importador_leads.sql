-- CRM de inscritos e leads de corrida
-- Objetivo:
--   - importar dados vindos de arquivos (XLSX/CSV) e APIs;
--   - preservar payload bruto;
--   - consolidar pessoas, pedidos e participacoes por versao do evento;
--   - cruzar posteriormente com usuarios Road Runners e resultados.

create schema if not exists crm;

alter schema crm
    owner to runner_dba;

revoke all on schema crm from public;
grant usage on schema crm to runner;

create extension if not exists unaccent with schema public;

set search_path to crm, public;

create or replace function crm_only_digits(p_value text)
returns text
language sql
immutable
set search_path = crm, public
as $$
    select nullif(regexp_replace(coalesce(p_value, ''), '[^0-9]', '', 'g'), '');
$$;

create or replace function crm_normalize_text(p_value text)
returns text
language sql
immutable
set search_path = crm, public
as $$
    select nullif(
        trim(regexp_replace(upper(unaccent(coalesce(p_value, ''))), '\s+', ' ', 'g')),
        ''
    );
$$;

create or replace function crm_normalize_sexo(p_value text)
returns varchar
language plpgsql
immutable
set search_path = crm, public
as $$
declare
    v_key text;
begin
    v_key := regexp_replace(coalesce(crm_normalize_text(p_value), ''), '[^A-Z0-9]+', '', 'g');

    if v_key = '' or v_key in ('NA', 'N/A', 'NI', 'NAOINFORMADO', 'NAODECLARADO', 'SEMRESPOSTA') then
        return null;
    end if;

    if v_key in ('M', 'MASC', 'MASCULINO', 'MALE', 'HOMEM') then
        return 'M';
    end if;

    if v_key in ('F', 'FEM', 'FEMININO', 'FEMALE', 'MULHER') then
        return 'F';
    end if;

    if v_key in ('X', 'OUTRO', 'OUTROS', 'OUTRA', 'NAOBINARIO', 'NAOBINARIA', 'NONBINARY', 'NB', 'DIVERSO', 'DIVERSA') then
        return 'X';
    end if;

    return null;
end;
$$;

create or replace function crm_parse_decimal_br(p_value text)
returns numeric
language plpgsql
immutable
set search_path = crm, public
as $$
declare
    v_value text;
begin
    v_value := trim(coalesce(p_value, ''));

    if v_value = '' then
        return null;
    end if;

    v_value := regexp_replace(v_value, '[^0-9,\.\-]', '', 'g');

    if v_value = '' or v_value = '-' then
        return null;
    end if;

    if position(',' in v_value) > 0 then
        v_value := replace(replace(v_value, '.', ''), ',', '.');
    end if;

    return v_value::numeric;
exception
    when others then
        return null;
end;
$$;

create or replace function crm_parse_date_br(p_value text)
returns date
language plpgsql
immutable
set search_path = crm, public
as $$
declare
    v_value text;
begin
    v_value := trim(coalesce(p_value, ''));

    if v_value = '' then
        return null;
    end if;

    if v_value ~ '^\d{4}-\d{2}-\d{2}' then
        return left(v_value, 10)::date;
    end if;

    if v_value ~ '^\d{2}/\d{2}/\d{4}' then
        return to_date(left(v_value, 10), 'DD/MM/YYYY');
    end if;

    return null;
exception
    when others then
        return null;
end;
$$;

create or replace function crm_parse_timestamp_br(p_value text)
returns timestamp
language plpgsql
immutable
set search_path = crm, public
as $$
declare
    v_value text;
begin
    v_value := trim(coalesce(p_value, ''));

    if v_value = '' then
        return null;
    end if;

    if v_value ~ '^\d{4}-\d{2}-\d{2}' then
        return v_value::timestamp;
    end if;

    if v_value ~ '^\d{2}/\d{2}/\d{4}\s+\d{2}:\d{2}' then
        return to_timestamp(v_value, 'DD/MM/YYYY HH24:MI');
    end if;

    if v_value ~ '^\d{2}/\d{2}/\d{4}$' then
        return to_timestamp(v_value || ' 00:00', 'DD/MM/YYYY HH24:MI');
    end if;

    return null;
exception
    when others then
        return null;
end;
$$;

create or replace function crm_infer_percurso(p_modalidade text)
returns numeric
language plpgsql
immutable
set search_path = crm, public
as $$
declare
    v_text text;
begin
    v_text := crm_normalize_text(p_modalidade);

    if v_text is null then
        return null;
    end if;

    if v_text like '%42K%' or v_text like '%42 KM%' or v_text like '%MARATONA 42%' then
        return 42;
    end if;

    if v_text like '%21K%' or v_text like '%21 KM%' or v_text like '%MEIA MARATONA%' then
        return 21;
    end if;

    if v_text like '%10K%' or v_text like '%10 KM%' then
        return 10;
    end if;

    if v_text like '%5K%' or v_text like '%5 KM%' then
        return 5;
    end if;

    return null;
end;
$$;

create table if not exists tb_crm_evento_series
(
    id_crm_evento_serie serial
        constraint tb_crm_evento_series_pk
            primary key,
    nome_serie          varchar(256)                         not null,
    slug_serie          varchar(128)                         not null,
    descricao           text,
    id_fornecedor       integer
        constraint tb_crm_evento_series_tb_fornecedores_id_fornecedor_fk
            references tb_fornecedores
            on update restrict on delete set null,
    ativo               boolean   default true               not null,
    data_criacao        timestamp default current_timestamp  not null,
    data_atualizacao    timestamp default current_timestamp  not null
);

alter table tb_crm_evento_series
    owner to runner_dba;

create unique index if not exists tb_crm_evento_series_slug_uidx
    on tb_crm_evento_series (slug_serie);

create table if not exists tb_crm_evento_versoes
(
    id_crm_evento_versao serial
        constraint tb_crm_evento_versoes_pk
            primary key,
    id_crm_evento_serie  integer                              not null
        constraint tb_crm_evento_versoes_tb_crm_evento_series_id_fk
            references tb_crm_evento_series
            on update cascade on delete cascade,
    id_evento            integer
        constraint tb_crm_evento_versoes_tb_evento_corridas_id_evento_fk
            references tb_evento_corridas
            on update restrict on delete set null,
    id_parceiro          integer
        constraint tb_crm_evento_versoes_tb_parceiros_id_parceiro_fk
            references public.tb_parceiros
            on update restrict on delete set null,
    fonte                varchar   default 'ticketsports'     not null,
    cod_evento_externo   varchar,
    nome_evento_externo  varchar,
    ano_evento           integer,
    data_evento          date,
    url_inscricao        varchar,
    status_versao        varchar   default 'ativo'            not null,
    payload              jsonb,
    data_criacao         timestamp default current_timestamp  not null,
    data_atualizacao     timestamp default current_timestamp  not null
);

alter table tb_crm_evento_versoes
    owner to runner_dba;

drop index if exists tb_crm_evento_versoes_fonte_cod_uidx;

create unique index if not exists tb_crm_evento_versoes_fonte_cod_uidx
    on tb_crm_evento_versoes (fonte, cod_evento_externo)
    where cod_evento_externo is not null and cod_evento_externo <> '';

create unique index if not exists tb_crm_evento_versoes_fonte_evento_sem_cod_uidx
    on tb_crm_evento_versoes (fonte, id_evento, coalesce(id_parceiro, -1))
    where (cod_evento_externo is null or cod_evento_externo = '') and id_evento is not null;

create index if not exists tb_crm_evento_versoes_serie_ano_idx
    on tb_crm_evento_versoes (id_crm_evento_serie, ano_evento);

create table if not exists tb_crm_conta_evento_versoes
(
    id_crm_conta_evento_versao bigserial
        constraint tb_crm_conta_evento_versoes_pk
            primary key,
    id_conta                    bigint                                  not null
        constraint tb_crm_conta_evento_versoes_tb_contas_id_conta_fk
            references public.tb_contas
            on update cascade on delete cascade,
    id_crm_evento_versao        integer                                 not null
        constraint tb_crm_conta_evento_versoes_tb_crm_evento_versoes_id_fk
            references tb_crm_evento_versoes
            on update cascade on delete cascade,
    status                      public.status_conta_evento default 'ATIVO'::public.status_conta_evento not null,
    usuario_cadastro            bigint
        constraint tb_crm_conta_evento_versoes_tb_usuarios_id_fk
            references public.tb_usuarios
            on update restrict on delete set null,
    origem                      varchar                    default 'manual' not null,
    data_criacao                timestamp with time zone   default now()    not null,
    data_atualizacao            timestamp with time zone   default now()    not null,
    constraint tb_crm_conta_evento_versoes_uidx
        unique (id_conta, id_crm_evento_versao)
);

alter table tb_crm_conta_evento_versoes
    owner to runner_dba;

create index if not exists tb_crm_conta_evento_versoes_versao_idx
    on tb_crm_conta_evento_versoes (id_crm_evento_versao, status);

create index if not exists tb_crm_conta_evento_versoes_conta_idx
    on tb_crm_conta_evento_versoes (id_conta, status);

create table if not exists tb_crm_importacoes
(
    id_crm_importacao       bigserial
        constraint tb_crm_importacoes_pk
            primary key,
    id_crm_evento_versao    integer
        constraint tb_crm_importacoes_tb_crm_evento_versoes_id_fk
            references tb_crm_evento_versoes
            on update cascade on delete set null,
    id_evento               integer
        constraint tb_crm_importacoes_tb_evento_corridas_id_evento_fk
            references tb_evento_corridas
            on update restrict on delete set null,
    id_parceiro             integer
        constraint tb_crm_importacoes_tb_parceiros_id_parceiro_fk
            references public.tb_parceiros
            on update restrict on delete set null,
    id_fornecedor           integer
        constraint tb_crm_importacoes_tb_fornecedores_id_fornecedor_fk
            references tb_fornecedores
            on update restrict on delete set null,
    id_usuario_importacao   integer
        constraint tb_crm_importacoes_tb_usuarios_id_fk
            references tb_usuarios
            on update restrict on delete set null,
    fonte                   varchar                              not null,
    cod_evento_externo      varchar,
    origem_tipo             varchar                              not null
        constraint tb_crm_importacoes_origem_tipo_ck
            check (origem_tipo in ('api', 'arquivo', 'manual')),
    tipo_entidade           varchar   default 'participantes'    not null,
    nome_importacao         varchar                              not null,
    arquivo_nome            varchar,
    arquivo_hash            varchar,
    arquivo_mime            varchar,
    arquivo_tamanho_bytes   bigint,
    aba_nome                varchar,
    api_endpoint            varchar,
    api_parametros          jsonb,
    colunas_raw             jsonb,
    mapeamento              jsonb,
    status_processamento    varchar   default 'recebido'         not null,
    total_linhas            integer   default 0                  not null,
    total_validas           integer   default 0                  not null,
    total_invalidas         integer   default 0                  not null,
    total_duplicadas        integer   default 0                  not null,
    erro_processamento      text,
    data_inicio             timestamp,
    data_fim                timestamp,
    data_criacao            timestamp default current_timestamp  not null,
    data_atualizacao        timestamp default current_timestamp  not null
);

alter table tb_crm_importacoes
    owner to runner_dba;

create unique index if not exists tb_crm_importacoes_arquivo_uidx
    on tb_crm_importacoes (arquivo_hash, coalesce(aba_nome, ''), tipo_entidade)
    where arquivo_hash is not null and arquivo_hash <> '';

create unique index if not exists tb_crm_importacoes_api_uidx
    on tb_crm_importacoes (
        fonte,
        origem_tipo,
        coalesce(api_endpoint, ''),
        coalesce(api_parametros ->> 'cod_evento', ''),
        tipo_entidade
    )
    where origem_tipo = 'api';

create index if not exists tb_crm_importacoes_evento_idx
    on tb_crm_importacoes (id_crm_evento_versao, fonte, origem_tipo);

create table if not exists tb_crm_importacao_linhas
(
    id_crm_importacao_linha bigserial
        constraint tb_crm_importacao_linhas_pk
            primary key,
    id_crm_importacao       bigint                              not null
        constraint tb_crm_importacao_linhas_tb_crm_importacoes_id_fk
            references tb_crm_importacoes
            on update cascade on delete cascade,
    numero_linha            integer                             not null,
    entidade_origem         varchar   default 'participante'     not null,
    chave_externa           varchar,
    raw                     jsonb                               not null,
    normalizado             jsonb,
    nome_atleta             varchar,
    nome_norm               varchar,
    email                   varchar,
    email_norm              varchar,
    tipo_documento          varchar,
    documento               varchar,
    documento_norm          varchar,
    telefone                varchar,
    telefone_norm           varchar,
    data_nascimento         date,
    sexo                    varchar(1),
    cidade                  varchar,
    estado                  varchar,
    pais                    varchar,
    numero_inscricao        varchar,
    numero_pedido           varchar,
    protocolo               varchar,
    numero_peito            varchar,
    percurso                numeric,
    modalidade              varchar,
    categoria               varchar,
    status_inscricao        varchar,
    origem                  varchar,
    campanha                varchar,
    cupom                   varchar,
    camiseta                varchar,
    assessoria              varchar,
    data_pedido             timestamp,
    data_pagamento          timestamp,
    valor                   numeric,
    status_validacao        varchar   default 'pendente'         not null,
    erros                   jsonb,
    avisos                  jsonb,
    data_criacao            timestamp default current_timestamp  not null,
    data_atualizacao        timestamp default current_timestamp  not null,
    constraint tb_crm_importacao_linhas_linha_uidx
        unique (id_crm_importacao, numero_linha, entidade_origem)
);

alter table tb_crm_importacao_linhas
    owner to runner_dba;

create index if not exists tb_crm_importacao_linhas_email_idx
    on tb_crm_importacao_linhas (email_norm);

create index if not exists tb_crm_importacao_linhas_documento_idx
    on tb_crm_importacao_linhas (documento_norm);

create index if not exists tb_crm_importacao_linhas_inscricao_idx
    on tb_crm_importacao_linhas (numero_inscricao);

create table if not exists tb_crm_pessoas
(
    id_crm_pessoa             bigserial
        constraint tb_crm_pessoas_pk
            primary key,
    nome                      varchar                             not null,
    nome_norm                 varchar                             not null,
    email                     varchar,
    email_norm                varchar,
    documento                 varchar,
    documento_norm            varchar,
    telefone                  varchar,
    telefone_norm             varchar,
    data_nascimento           date,
    sexo                      varchar(1),
    cidade                    varchar,
    estado                    varchar,
    pais                      varchar   default 'BR',
    instagram                 varchar,
    assessoria                varchar,
    id_usuario                integer
        constraint tb_crm_pessoas_tb_usuarios_id_fk
            references tb_usuarios
            on update cascade on delete set null,
    match_usuario_status      varchar   default 'nao_processado'  not null,
    match_usuario_confianca   numeric,
    origem_primeiro_contato   varchar,
    consentimento_marketing   boolean,
    base_legal                varchar,
    data_criacao              timestamp default current_timestamp not null,
    data_atualizacao          timestamp default current_timestamp not null
);

alter table tb_crm_pessoas
    owner to runner_dba;

create unique index if not exists tb_crm_pessoas_documento_uidx
    on tb_crm_pessoas (documento_norm)
    where documento_norm is not null and documento_norm <> '';

create unique index if not exists tb_crm_pessoas_email_nome_nasc_uidx
    on tb_crm_pessoas (email_norm, nome_norm, data_nascimento)
    where documento_norm is null
      and email_norm is not null
      and email_norm <> ''
      and data_nascimento is not null;

create index if not exists tb_crm_pessoas_email_idx
    on tb_crm_pessoas (email_norm);

create index if not exists tb_crm_pessoas_nome_nasc_idx
    on tb_crm_pessoas (nome_norm, data_nascimento);

create index if not exists tb_crm_pessoas_usuario_idx
    on tb_crm_pessoas (id_usuario);

create table if not exists tb_crm_pedidos
(
    id_crm_pedido          bigserial
        constraint tb_crm_pedidos_pk
            primary key,
    id_crm_evento_versao   integer
        constraint tb_crm_pedidos_tb_crm_evento_versoes_id_fk
            references tb_crm_evento_versoes
            on update cascade on delete set null,
    id_crm_importacao      bigint
        constraint tb_crm_pedidos_tb_crm_importacoes_id_fk
            references tb_crm_importacoes
            on update cascade on delete set null,
    id_parceiro             integer
        constraint tb_crm_pedidos_tb_parceiros_id_parceiro_fk
            references public.tb_parceiros
            on update restrict on delete set null,
    fonte                  varchar   default 'ticketsports'       not null,
    cod_evento_externo     varchar,
    numero_pedido          varchar                                not null,
    status_pedido          varchar,
    data_pedido            timestamp,
    data_pagamento         timestamp,
    forma_pagamento        varchar,
    tipo_dispositivo       varchar,
    qtd_inscricoes         integer,
    valor_total            numeric,
    valor_taxa             numeric,
    valor_desconto         numeric,
    valor_repasse          numeric,
    responsavel_nome       varchar,
    responsavel_email      varchar,
    responsavel_email_norm varchar,
    responsavel_documento  varchar,
    responsavel_doc_norm   varchar,
    responsavel_telefone   varchar,
    responsavel_tel_norm   varchar,
    responsavel_nascimento date,
    responsavel_endereco   varchar,
    responsavel_numero     varchar,
    responsavel_bairro     varchar,
    responsavel_cidade     varchar,
    responsavel_estado     varchar,
    responsavel_cep        varchar,
    raw                    jsonb,
    data_criacao           timestamp default current_timestamp    not null,
    data_atualizacao       timestamp default current_timestamp    not null
);

alter table tb_crm_pedidos
    owner to runner_dba;

create unique index if not exists tb_crm_pedidos_fonte_evento_pedido_uidx
    on tb_crm_pedidos (fonte, cod_evento_externo, numero_pedido);

create index if not exists tb_crm_pedidos_status_idx
    on tb_crm_pedidos (status_pedido);

create index if not exists tb_crm_pedidos_responsavel_email_idx
    on tb_crm_pedidos (responsavel_email_norm);

create table if not exists tb_crm_participacoes
(
    id_crm_participacao       bigserial
        constraint tb_crm_participacoes_pk
            primary key,
    id_crm_pessoa             bigint                              not null
        constraint tb_crm_participacoes_tb_crm_pessoas_id_fk
            references tb_crm_pessoas
            on update cascade on delete cascade,
    id_crm_pedido             bigint
        constraint tb_crm_participacoes_tb_crm_pedidos_id_fk
            references tb_crm_pedidos
            on update cascade on delete set null,
    id_crm_evento_versao      integer
        constraint tb_crm_participacoes_tb_crm_evento_versoes_id_fk
            references tb_crm_evento_versoes
            on update cascade on delete set null,
    id_crm_importacao_linha   bigint
        constraint tb_crm_participacoes_tb_crm_importacao_linhas_id_fk
            references tb_crm_importacao_linhas
            on update cascade on delete set null,
    id_evento                 integer
        constraint tb_crm_participacoes_tb_evento_corridas_id_evento_fk
            references tb_evento_corridas
            on update restrict on delete set null,
    id_parceiro               integer
        constraint tb_crm_participacoes_tb_parceiros_id_parceiro_fk
            references public.tb_parceiros
            on update restrict on delete set null,
    id_fornecedor             integer
        constraint tb_crm_participacoes_tb_fornecedores_id_fornecedor_fk
            references tb_fornecedores
            on update restrict on delete set null,
    fonte                     varchar   default 'ticketsports'     not null,
    cod_evento_externo        varchar,
    ano_evento                integer,
    nome_evento_externo       varchar,
    data_evento               date,
    numero_inscricao          varchar,
    numero_pedido             varchar,
    protocolo                 varchar,
    id_categoria_externo      varchar,
    lote                      integer,
    numero_peito              varchar,
    percurso                  numeric,
    percurso_label            varchar,
    modalidade                varchar,
    categoria                 varchar,
    status_inscricao          varchar,
    status_participacao       varchar   default 'inscrito'         not null,
    status_pedido             varchar,
    data_pedido               timestamp,
    data_pagamento            timestamp,
    origem                    varchar,
    campanha                  varchar,
    cupom                     varchar,
    valor_unitario            numeric,
    valor_taxa                numeric,
    valor_desconto            numeric,
    valor_desconto_cupom      numeric,
    valor_repasse             numeric,
    camiseta                  varchar,
    assessoria                varchar,
    pace_declarado            varchar,
    instagram                 varchar,
    telefone_whatsapp         varchar,
    interesse_viagem          varchar,
    produtos                  jsonb,
    questionario              jsonb,
    raw                       jsonb,
    id_resultado              integer
        constraint tb_crm_participacoes_tb_resultados_id_fk
            references tb_resultados
            on update cascade on delete set null,
    correu                    boolean,
    concluinte                boolean,
    status_resultado          integer,
    tempo_total               time,
    pace_resultado            time,
    match_resultado_status    varchar   default 'nao_processado'  not null,
    match_resultado_confianca numeric,
    lead_score                numeric,
    lead_score_componentes    jsonb,
    data_criacao              timestamp default current_timestamp not null,
    data_atualizacao          timestamp default current_timestamp not null
);

alter table tb_crm_participacoes
    owner to runner_dba;

create unique index if not exists tb_crm_participacoes_inscricao_uidx
    on tb_crm_participacoes (fonte, cod_evento_externo, numero_inscricao)
    where numero_inscricao is not null and numero_inscricao <> '';

create index if not exists tb_crm_participacoes_pessoa_idx
    on tb_crm_participacoes (id_crm_pessoa);

create index if not exists tb_crm_participacoes_evento_idx
    on tb_crm_participacoes (id_crm_evento_versao, percurso, status_pedido);

create index if not exists tb_crm_participacoes_evento_rr_idx
    on tb_crm_participacoes (id_evento, ano_evento, percurso);

create index if not exists tb_crm_participacoes_evento_externo_idx
    on tb_crm_participacoes (fonte, cod_evento_externo, percurso);

create index if not exists tb_crm_participacoes_status_idx
    on tb_crm_participacoes (status_pedido);

create index if not exists tb_crm_participacoes_data_pedido_idx
    on tb_crm_participacoes (data_pedido desc nulls last, data_criacao desc);

create index if not exists tb_crm_participacoes_resultado_idx
    on tb_crm_participacoes (id_resultado);

create index if not exists tb_crm_participacoes_score_idx
    on tb_crm_participacoes (lead_score desc nulls last);

create unique index if not exists tb_crm_participacoes_importacao_linha_uidx
    on tb_crm_participacoes (id_crm_importacao_linha)
    where id_crm_importacao_linha is not null;

create table if not exists tb_crm_participacao_respostas
(
    id_crm_participacao_resposta bigserial
        constraint tb_crm_participacao_respostas_pk
            primary key,
    id_crm_participacao          bigint                              not null
        constraint tb_crm_participacao_respostas_tb_crm_participacoes_id_fk
            references tb_crm_participacoes
            on update cascade on delete cascade,
    pergunta                     varchar                             not null,
    pergunta_norm                varchar                             not null,
    resposta                     text,
    resposta_norm                text,
    data_criacao                 timestamp default current_timestamp not null
);

alter table tb_crm_participacao_respostas
    owner to runner_dba;

create index if not exists tb_crm_participacao_respostas_pergunta_idx
    on tb_crm_participacao_respostas (pergunta_norm);

create index if not exists tb_crm_participacao_respostas_participacao_idx
    on tb_crm_participacao_respostas (id_crm_participacao);

create table if not exists tb_crm_participacao_produtos
(
    id_crm_participacao_produto bigserial
        constraint tb_crm_participacao_produtos_pk
            primary key,
    id_crm_participacao         bigint                              not null
        constraint tb_crm_participacao_produtos_tb_crm_participacoes_id_fk
            references tb_crm_participacoes
            on update cascade on delete cascade,
    id_produto_externo          varchar,
    id_estoque_externo          varchar,
    nome_produto                varchar                             not null,
    valor_produto               numeric,
    quantidade                  integer default 1                   not null,
    atributo                    jsonb,
    data_criacao                timestamp default current_timestamp not null
);

alter table tb_crm_participacao_produtos
    owner to runner_dba;

create index if not exists tb_crm_participacao_produtos_nome_idx
    on tb_crm_participacao_produtos (crm_normalize_text(nome_produto));

create index if not exists tb_crm_participacao_produtos_participacao_idx
    on tb_crm_participacao_produtos (id_crm_participacao);

drop view if exists vw_crm_leads;
drop view if exists vw_crm_participacoes;

create or replace view vw_crm_participacoes as
select
    part.id_crm_participacao,
    part.id_crm_pessoa,
    part.id_crm_pedido,
    part.id_crm_evento_versao,
    serie.id_crm_evento_serie,
    serie.nome_serie,
    vers.fonte as fonte_evento,
    part.fonte,
    part.id_parceiro,
    part.cod_evento_externo,
    coalesce(evt.nome_evento, part.nome_evento_externo, vers.nome_evento_externo) as nome_evento,
    part.ano_evento,
    coalesce(evt.data_inicial, part.data_evento, vers.data_evento) as data_evento,
    part.id_evento,
    part.numero_inscricao,
    part.numero_pedido,
    part.protocolo,
    part.numero_peito,
    part.percurso,
    part.percurso_label,
    part.modalidade,
    part.categoria,
    part.status_inscricao,
    coalesce(part.status_pedido, ped.status_pedido) as status_pedido,
    part.status_participacao,
    coalesce(part.data_pedido, ped.data_pedido) as data_pedido,
    coalesce(part.data_pagamento, ped.data_pagamento) as data_pagamento,
    part.origem,
    part.campanha,
    part.cupom,
    part.valor_unitario,
    part.valor_repasse,
    part.camiseta,
    part.assessoria,
    part.pace_declarado,
    part.instagram,
    part.telefone_whatsapp,
    part.interesse_viagem,
    pessoa.nome,
    pessoa.nome_norm,
    pessoa.email,
    pessoa.email_norm,
    pessoa.documento,
    pessoa.documento_norm,
    pessoa.telefone,
    pessoa.telefone_norm,
    pessoa.data_nascimento,
    pessoa.sexo,
    pessoa.cidade,
    pessoa.estado,
    pessoa.pais,
    pessoa.id_usuario,
    pessoa.match_usuario_status,
    pessoa.match_usuario_confianca,
    usr.name as usuario_nome,
    usr.email as usuario_email,
    part.id_resultado,
    coalesce(part.correu, res.id_resultado is not null) as correu,
    coalesce(part.concluinte, res.concluinte) as concluinte,
    coalesce(part.status_resultado, res.status_final) as status_resultado,
    coalesce(part.tempo_total, res.tempo_total) as tempo_total,
    coalesce(part.pace_resultado, res.pace) as pace_resultado,
    part.match_resultado_status,
    part.match_resultado_confianca,
    part.lead_score,
    part.lead_score_componentes,
    part.data_criacao,
    part.data_atualizacao
from tb_crm_participacoes part
inner join tb_crm_pessoas pessoa
    on pessoa.id_crm_pessoa = part.id_crm_pessoa
left join tb_crm_pedidos ped
    on ped.id_crm_pedido = part.id_crm_pedido
left join tb_crm_evento_versoes vers
    on vers.id_crm_evento_versao = part.id_crm_evento_versao
left join tb_crm_evento_series serie
    on serie.id_crm_evento_serie = vers.id_crm_evento_serie
left join tb_evento_corridas evt
    on evt.id_evento = part.id_evento
left join tb_usuarios usr
    on usr.id = pessoa.id_usuario
left join tb_resultados res
    on res.id_resultado = part.id_resultado;

alter view vw_crm_participacoes
    owner to runner_dba;

create or replace view vw_crm_leads as
select
    pessoa.id_crm_pessoa,
    pessoa.nome,
    pessoa.email,
    pessoa.documento,
    pessoa.telefone,
    pessoa.cidade,
    pessoa.estado,
    pessoa.id_usuario,
    pessoa.match_usuario_status,
    count(part.id_crm_participacao)::integer as total_participacoes,
    count(distinct part.id_crm_evento_versao)::integer as total_versoes,
    max(coalesce(part.data_evento, vers.data_evento)) as ultima_data_evento,
    max(part.data_pedido) as ultima_data_pedido,
    count(*) filter (where coalesce(part.status_pedido, '') ilike 'Pago')::integer as total_pagos,
    count(*) filter (where coalesce(part.correu, false) = true)::integer as total_corriu,
    count(*) filter (where coalesce(part.concluinte, false) = true)::integer as total_concluiu,
    (
        select pref.percurso
        from tb_crm_participacoes pref
        where pref.id_crm_pessoa = pessoa.id_crm_pessoa
          and pref.percurso is not null
        group by pref.percurso
        order by count(*) desc, max(pref.data_pedido) desc nulls last, pref.percurso
        limit 1
    ) as percurso_preferido,
    max(part.lead_score) as lead_score_maximo,
    avg(part.lead_score) as lead_score_medio
from tb_crm_pessoas pessoa
left join tb_crm_participacoes part
    on part.id_crm_pessoa = pessoa.id_crm_pessoa
left join tb_crm_evento_versoes vers
    on vers.id_crm_evento_versao = part.id_crm_evento_versao
group by
    pessoa.id_crm_pessoa,
    pessoa.nome,
    pessoa.email,
    pessoa.documento,
    pessoa.telefone,
    pessoa.cidade,
    pessoa.estado,
    pessoa.id_usuario,
    pessoa.match_usuario_status;

alter view vw_crm_leads
    owner to runner_dba;

drop function if exists crm.crm_match_usuarios(bigint);

create or replace function crm_match_usuarios(p_id_conta bigint default null)
returns table (
    pessoas_avaliadas integer,
    pessoas_vinculadas integer,
    pessoas_pendentes integer
)
language plpgsql
set search_path = crm, public
as $$
declare
    v_pessoas_avaliadas integer := 0;
    v_pessoas_vinculadas integer := 0;
    v_pessoas_pendentes integer := 0;
begin
    with elegiveis as (
        select distinct pessoa.id_crm_pessoa
        from crm.tb_crm_pessoas pessoa
        where pessoa.id_usuario is null
          and pessoa.email_norm is not null
          and pessoa.email_norm <> ''
          and (
              p_id_conta is null
              or exists (
                  select 1
                  from crm.tb_crm_participacoes part
                  inner join crm.tb_crm_conta_evento_versoes link
                      on link.id_crm_evento_versao = part.id_crm_evento_versao
                     and link.status = 'ATIVO'::public.status_conta_evento
                  where part.id_crm_pessoa = pessoa.id_crm_pessoa
                    and link.id_conta = p_id_conta
              )
          )
    )
    select count(*)::integer
    into v_pessoas_avaliadas
    from elegiveis;

    with elegiveis as (
        select distinct pessoa.*
        from crm.tb_crm_pessoas pessoa
        where pessoa.id_usuario is null
          and pessoa.email_norm is not null
          and pessoa.email_norm <> ''
          and (
              p_id_conta is null
              or exists (
                  select 1
                  from crm.tb_crm_participacoes part
                  inner join crm.tb_crm_conta_evento_versoes link
                      on link.id_crm_evento_versao = part.id_crm_evento_versao
                     and link.status = 'ATIVO'::public.status_conta_evento
                  where part.id_crm_pessoa = pessoa.id_crm_pessoa
                    and link.id_conta = p_id_conta
              )
          )
    ),
    crm_email_stats as (
        select email_norm,
               count(*)::integer as pessoas_email
        from crm.tb_crm_pessoas
        where email_norm is not null
          and email_norm <> ''
        group by email_norm
    ),
    usuario_email_stats as (
        select nullif(lower(trim(usr.email)), '') as email_norm,
               count(*)::integer as usuarios_email
        from public.tb_usuarios usr
        where nullif(lower(trim(usr.email)), '') is not null
        group by nullif(lower(trim(usr.email)), '')
    ),
    candidatos as (
        select
            elegiveis.id_crm_pessoa,
            usr.id as id_usuario,
            case
                when crm.crm_normalize_text(usr.name) = elegiveis.nome_norm then 'email_nome'
                when elegiveis.data_nascimento is not null and usr.data_nascimento = elegiveis.data_nascimento then 'email_nascimento'
                when crm_email_stats.pessoas_email = 1 then 'email_unico'
            end as match_status,
            case
                when crm.crm_normalize_text(usr.name) = elegiveis.nome_norm then 0.95
                when elegiveis.data_nascimento is not null and usr.data_nascimento = elegiveis.data_nascimento then 0.95
                when crm_email_stats.pessoas_email = 1 then 0.80
            end as match_confianca
        from elegiveis
        inner join public.tb_usuarios usr
            on nullif(lower(trim(usr.email)), '') = elegiveis.email_norm
        inner join usuario_email_stats
            on usuario_email_stats.email_norm = elegiveis.email_norm
           and usuario_email_stats.usuarios_email = 1
        inner join crm_email_stats
            on crm_email_stats.email_norm = elegiveis.email_norm
        where crm.crm_normalize_text(usr.name) = elegiveis.nome_norm
           or (elegiveis.data_nascimento is not null and usr.data_nascimento = elegiveis.data_nascimento)
           or crm_email_stats.pessoas_email = 1
    ),
    melhores as (
        select distinct on (candidatos.id_crm_pessoa)
            candidatos.id_crm_pessoa,
            candidatos.id_usuario,
            candidatos.match_status,
            candidatos.match_confianca
        from candidatos
        where candidatos.match_status is not null
        order by candidatos.id_crm_pessoa,
                 candidatos.match_confianca desc,
                 candidatos.id_usuario
    ),
    atualizados as (
        update crm.tb_crm_pessoas pessoa
        set id_usuario = melhores.id_usuario,
            match_usuario_status = melhores.match_status,
            match_usuario_confianca = melhores.match_confianca,
            data_atualizacao = current_timestamp
        from melhores
        where pessoa.id_crm_pessoa = melhores.id_crm_pessoa
          and pessoa.id_usuario is null
        returning pessoa.id_crm_pessoa
    )
    select count(*)::integer
    into v_pessoas_vinculadas
    from atualizados;

    with elegiveis_pendentes as (
        select distinct pessoa.id_crm_pessoa
        from crm.tb_crm_pessoas pessoa
        where pessoa.id_usuario is null
          and pessoa.email_norm is not null
          and pessoa.email_norm <> ''
          and (
              p_id_conta is null
              or exists (
                  select 1
                  from crm.tb_crm_participacoes part
                  inner join crm.tb_crm_conta_evento_versoes link
                      on link.id_crm_evento_versao = part.id_crm_evento_versao
                     and link.status = 'ATIVO'::public.status_conta_evento
                  where part.id_crm_pessoa = pessoa.id_crm_pessoa
                    and link.id_conta = p_id_conta
              )
          )
    )
    select count(*)::integer
    into v_pessoas_pendentes
    from elegiveis_pendentes;

    return query
    select
        coalesce(v_pessoas_avaliadas, 0),
        coalesce(v_pessoas_vinculadas, 0),
        coalesce(v_pessoas_pendentes, 0);
end;
$$;

drop function if exists crm.crm_match_resultados(bigint, integer);

create or replace function crm_match_resultados(
    p_id_conta bigint default null,
    p_id_evento integer default null
)
returns table (
    participacoes_avaliadas integer,
    participacoes_vinculadas integer,
    pessoas_vinculadas integer,
    participacoes_pendentes integer
)
language plpgsql
set search_path = crm, public
as $$
declare
    v_participacoes_avaliadas integer := 0;
    v_participacoes_vinculadas integer := 0;
    v_pessoas_vinculadas integer := 0;
    v_participacoes_pendentes integer := 0;
begin
    with elegiveis as (
        select part.id_crm_participacao
        from crm.tb_crm_participacoes part
        where part.id_evento is not null
          and part.id_resultado is null
          and (p_id_evento is null or part.id_evento = p_id_evento)
          and (
              p_id_conta is null
              or exists (
                  select 1
                  from crm.tb_crm_conta_evento_versoes link
                  where link.id_crm_evento_versao = part.id_crm_evento_versao
                    and link.status = 'ATIVO'::public.status_conta_evento
                    and link.id_conta = p_id_conta
              )
          )
    )
    select count(*)::integer
    into v_participacoes_avaliadas
    from elegiveis;

    with elegiveis as (
        select
            part.id_crm_participacao,
            part.id_crm_pessoa,
            part.id_evento,
            part.percurso,
            case
                when nullif(crm.crm_only_digits(part.numero_peito), '') ~ '^\d{1,9}$'
                    then nullif(crm.crm_only_digits(part.numero_peito), '')::integer
                else null
            end as numero_peito_num,
            pessoa.nome_norm,
            pessoa.data_nascimento
        from crm.tb_crm_participacoes part
        inner join crm.tb_crm_pessoas pessoa
            on pessoa.id_crm_pessoa = part.id_crm_pessoa
        where part.id_evento is not null
          and part.id_resultado is null
          and (p_id_evento is null or part.id_evento = p_id_evento)
          and (
              p_id_conta is null
              or exists (
                  select 1
                  from crm.tb_crm_conta_evento_versoes link
                  where link.id_crm_evento_versao = part.id_crm_evento_versao
                    and link.status = 'ATIVO'::public.status_conta_evento
                    and link.id_conta = p_id_conta
              )
          )
    ),
    resultados as (
        select
            res.id_resultado,
            res.id_evento,
            res.num_peito,
            crm.crm_normalize_text(res.nome) as nome_norm,
            res.data_nascimento,
            res.percurso,
            res.id_usuario,
            res.concluinte,
            res.status_final,
            res.tempo_total,
            res.pace
        from public.tb_resultados res
        where res.id_evento is not null
          and (p_id_evento is null or res.id_evento = p_id_evento)
    ),
    crm_nome_stats as (
        select id_evento,
               nome_norm,
               count(*)::integer as total
        from elegiveis
        where nome_norm is not null
          and nome_norm <> ''
        group by id_evento, nome_norm
    ),
    res_nome_stats as (
        select id_evento,
               nome_norm,
               count(*)::integer as total
        from resultados
        where nome_norm is not null
          and nome_norm <> ''
        group by id_evento, nome_norm
    ),
    crm_nome_percurso_stats as (
        select id_evento,
               nome_norm,
               percurso,
               count(*)::integer as total
        from elegiveis
        where nome_norm is not null
          and nome_norm <> ''
          and percurso is not null
        group by id_evento, nome_norm, percurso
    ),
    res_nome_percurso_stats as (
        select id_evento,
               nome_norm,
               percurso,
               count(*)::integer as total
        from resultados
        where nome_norm is not null
          and nome_norm <> ''
          and percurso is not null
        group by id_evento, nome_norm, percurso
    ),
    candidatos as (
        select
            elegiveis.id_crm_participacao,
            elegiveis.id_crm_pessoa,
            resultados.id_resultado,
            resultados.id_usuario,
            resultados.concluinte,
            resultados.status_final,
            resultados.tempo_total,
            resultados.pace,
            case
                when elegiveis.numero_peito_num is not null
                     and resultados.num_peito = elegiveis.numero_peito_num
                     and resultados.nome_norm = elegiveis.nome_norm
                    then 'resultado_numero_nome'
                when elegiveis.data_nascimento is not null
                     and resultados.data_nascimento = elegiveis.data_nascimento
                     and resultados.nome_norm = elegiveis.nome_norm
                    then 'resultado_nome_nascimento'
                when elegiveis.percurso is not null
                     and resultados.percurso is not null
                     and abs(resultados.percurso - elegiveis.percurso) < 0.01
                     and resultados.nome_norm = elegiveis.nome_norm
                     and crm_nome_percurso_stats.total = 1
                     and res_nome_percurso_stats.total = 1
                    then 'resultado_nome_percurso_unico'
                when resultados.nome_norm = elegiveis.nome_norm
                     and crm_nome_stats.total = 1
                     and res_nome_stats.total = 1
                    then 'resultado_nome_unico'
            end as match_status,
            case
                when elegiveis.numero_peito_num is not null
                     and resultados.num_peito = elegiveis.numero_peito_num
                     and resultados.nome_norm = elegiveis.nome_norm
                    then 0.99
                when elegiveis.data_nascimento is not null
                     and resultados.data_nascimento = elegiveis.data_nascimento
                     and resultados.nome_norm = elegiveis.nome_norm
                    then 0.98
                when elegiveis.percurso is not null
                     and resultados.percurso is not null
                     and abs(resultados.percurso - elegiveis.percurso) < 0.01
                     and resultados.nome_norm = elegiveis.nome_norm
                     and crm_nome_percurso_stats.total = 1
                     and res_nome_percurso_stats.total = 1
                    then 0.92
                when resultados.nome_norm = elegiveis.nome_norm
                     and crm_nome_stats.total = 1
                     and res_nome_stats.total = 1
                    then 0.88
            end as match_confianca
        from elegiveis
        inner join resultados
            on resultados.id_evento = elegiveis.id_evento
        left join crm_nome_stats
            on crm_nome_stats.id_evento = elegiveis.id_evento
           and crm_nome_stats.nome_norm = elegiveis.nome_norm
        left join res_nome_stats
            on res_nome_stats.id_evento = resultados.id_evento
           and res_nome_stats.nome_norm = resultados.nome_norm
        left join crm_nome_percurso_stats
            on crm_nome_percurso_stats.id_evento = elegiveis.id_evento
           and crm_nome_percurso_stats.nome_norm = elegiveis.nome_norm
           and crm_nome_percurso_stats.percurso = elegiveis.percurso
        left join res_nome_percurso_stats
            on res_nome_percurso_stats.id_evento = resultados.id_evento
           and res_nome_percurso_stats.nome_norm = resultados.nome_norm
           and res_nome_percurso_stats.percurso = resultados.percurso
        where (
            elegiveis.numero_peito_num is not null
            and resultados.num_peito = elegiveis.numero_peito_num
            and resultados.nome_norm = elegiveis.nome_norm
        )
        or (
            elegiveis.data_nascimento is not null
            and resultados.data_nascimento = elegiveis.data_nascimento
            and resultados.nome_norm = elegiveis.nome_norm
        )
        or (
            elegiveis.percurso is not null
            and resultados.percurso is not null
            and abs(resultados.percurso - elegiveis.percurso) < 0.01
            and resultados.nome_norm = elegiveis.nome_norm
            and crm_nome_percurso_stats.total = 1
            and res_nome_percurso_stats.total = 1
        )
        or (
            resultados.nome_norm = elegiveis.nome_norm
            and crm_nome_stats.total = 1
            and res_nome_stats.total = 1
        )
    ),
    melhores as (
        select distinct on (candidatos.id_crm_participacao)
            candidatos.*
        from candidatos
        where candidatos.match_status is not null
        order by candidatos.id_crm_participacao,
                 candidatos.match_confianca desc,
                 (candidatos.id_usuario is not null) desc,
                 candidatos.id_resultado
    ),
    participacoes_atualizadas as (
        update crm.tb_crm_participacoes part
        set id_resultado = melhores.id_resultado,
            correu = true,
            concluinte = coalesce(melhores.concluinte, true),
            status_resultado = melhores.status_final,
            tempo_total = melhores.tempo_total,
            pace_resultado = melhores.pace,
            match_resultado_status = melhores.match_status,
            match_resultado_confianca = melhores.match_confianca,
            lead_score = coalesce(part.lead_score, 0)
                + case when melhores.id_usuario is not null then 40 else 25 end,
            lead_score_componentes = coalesce(part.lead_score_componentes, '{}'::jsonb)
                || jsonb_build_object(
                    'resultado', case when melhores.id_usuario is not null then 40 else 25 end,
                    'resultado_match', melhores.match_status
                ),
            data_atualizacao = current_timestamp
        from melhores
        where part.id_crm_participacao = melhores.id_crm_participacao
          and part.id_resultado is null
        returning part.id_crm_participacao
    ),
    pessoas_atualizadas as (
        update crm.tb_crm_pessoas pessoa
        set id_usuario = melhores.id_usuario,
            match_usuario_status = 'resultado_' || melhores.match_status,
            match_usuario_confianca = melhores.match_confianca,
            data_atualizacao = current_timestamp
        from melhores
        where pessoa.id_crm_pessoa = melhores.id_crm_pessoa
          and pessoa.id_usuario is null
          and melhores.id_usuario is not null
        returning pessoa.id_crm_pessoa
    )
    select
        (select count(*)::integer from participacoes_atualizadas),
        (select count(*)::integer from pessoas_atualizadas)
    into v_participacoes_vinculadas, v_pessoas_vinculadas;

    with elegiveis_pendentes as (
        select part.id_crm_participacao
        from crm.tb_crm_participacoes part
        where part.id_evento is not null
          and part.id_resultado is null
          and (p_id_evento is null or part.id_evento = p_id_evento)
          and (
              p_id_conta is null
              or exists (
                  select 1
                  from crm.tb_crm_conta_evento_versoes link
                  where link.id_crm_evento_versao = part.id_crm_evento_versao
                    and link.status = 'ATIVO'::public.status_conta_evento
                    and link.id_conta = p_id_conta
              )
          )
    )
    select count(*)::integer
    into v_participacoes_pendentes
    from elegiveis_pendentes;

    return query
    select
        coalesce(v_participacoes_avaliadas, 0),
        coalesce(v_participacoes_vinculadas, 0),
        coalesce(v_pessoas_vinculadas, 0),
        coalesce(v_participacoes_pendentes, 0);
end;
$$;

create or replace function crm_sync_ticketsports(
    p_cod_evento integer default null,
    p_nome_serie varchar default 'Maratona Internacional de Floripa',
    p_slug_serie varchar default 'maratona-internacional-de-floripa'
)
returns table (
    total_versoes integer,
    total_importacoes integer,
    total_pedidos integer,
    total_pessoas integer,
    total_participacoes integer
)
language plpgsql
set search_path = crm, public
as $$
declare
    v_id_crm_evento_serie integer;
begin
    insert into tb_crm_evento_series (
        nome_serie,
        slug_serie,
        descricao
    )
    values (
        p_nome_serie,
        p_slug_serie,
        'Serie criada para consolidar importacoes TicketSports/API e arquivos historicos no CRM.'
    )
    on conflict (slug_serie) do update
        set nome_serie = excluded.nome_serie,
            data_atualizacao = current_timestamp
    returning id_crm_evento_serie
    into v_id_crm_evento_serie;

    with eventos as (
        select
            ped.cod_evento::varchar as cod_evento_externo,
            max(nullif(ped.body #>> '{evento,tituloEvento}', '')) as nome_evento_externo,
            max(crm_parse_date_br(ped.body #>> '{evento,realizacao}')) as data_evento,
            count(*)::integer as total_pedidos
        from tb_ticketsports_pedidos ped
        where p_cod_evento is null
           or ped.cod_evento = p_cod_evento
        group by ped.cod_evento
    )
    insert into tb_crm_evento_versoes (
        id_crm_evento_serie,
        id_evento,
        fonte,
        cod_evento_externo,
        nome_evento_externo,
        ano_evento,
        data_evento,
        payload
    )
    select
        v_id_crm_evento_serie,
        evt.id_evento,
        'ticketsports',
        eventos.cod_evento_externo,
        coalesce(eventos.nome_evento_externo, 'TicketSports ' || eventos.cod_evento_externo),
        extract(year from eventos.data_evento)::integer,
        eventos.data_evento,
        jsonb_build_object(
            'origem', 'tb_ticketsports_pedidos',
            'total_pedidos', eventos.total_pedidos
        )
    from eventos
    left join lateral (
        select candidato.id_evento
        from (
            select rel.id_evento,
                   10 as prioridade
            from public.tb_evento_corridas_relaciona rel
            left join public.tb_parceiros par
                on par.id_parceiro = rel.id_parceiro
            where rel.ativo = true
              and rel.id_evento_parceiro = eventos.cod_evento_externo::integer
              and unaccent(lower(par.nome_parceiro)) like '%ticket%'

            union all

            select imp.id_evento_match as id_evento,
                   20 as prioridade
            from public.tb_evento_corridas_importacao imp
            where imp.cod_evento = eventos.cod_evento_externo
              and imp.id_evento_match is not null

            union all

            select evt_url.id_evento,
                   30 as prioridade
            from public.tb_evento_corridas evt_url
            where (
                  coalesce(evt_url.url_inscricao, '') ilike '%ticketsports%'
                  or coalesce(evt_url.url_hotsite, '') ilike '%ticketsports%'
              )
              and (
                  coalesce(evt_url.url_inscricao, '') ilike '%' || eventos.cod_evento_externo || '%'
                  or coalesce(evt_url.url_hotsite, '') ilike '%' || eventos.cod_evento_externo || '%'
              )

            union all

            select evt_id.id_evento,
                   90 as prioridade
            from public.tb_evento_corridas evt_id
            where evt_id.id_evento::varchar = eventos.cod_evento_externo
        ) candidato
        order by candidato.prioridade, candidato.id_evento
        limit 1
    ) evt on true
    on conflict (fonte, cod_evento_externo)
        where cod_evento_externo is not null and cod_evento_externo <> ''
    do update
        set id_crm_evento_serie = excluded.id_crm_evento_serie,
            id_evento = coalesce(excluded.id_evento, tb_crm_evento_versoes.id_evento),
            nome_evento_externo = excluded.nome_evento_externo,
            ano_evento = excluded.ano_evento,
            data_evento = excluded.data_evento,
            payload = excluded.payload,
            data_atualizacao = current_timestamp;

    insert into tb_crm_conta_evento_versoes (
        id_conta,
        id_crm_evento_versao,
        status,
        origem
    )
    select
        cev.id_conta,
        vers.id_crm_evento_versao,
        cev.status,
        'tb_conta_eventos'
    from tb_crm_evento_versoes vers
    inner join public.tb_conta_eventos cev
        on cev.id_evento = vers.id_evento
    where vers.fonte = 'ticketsports'
      and (p_cod_evento is null or vers.cod_evento_externo = p_cod_evento::varchar)
    on conflict (id_conta, id_crm_evento_versao) do update
        set status = excluded.status,
            origem = excluded.origem,
            data_atualizacao = now();

    update tb_crm_importacoes imp
    set id_crm_evento_versao = vers.id_crm_evento_versao,
        id_evento = vers.id_evento,
        cod_evento_externo = vers.cod_evento_externo,
        nome_importacao = 'TicketSports API ' || vers.cod_evento_externo,
        total_linhas = coalesce(cont.total_linhas, 0),
        total_validas = coalesce(cont.total_linhas, 0),
        status_processamento = 'processado',
        data_fim = current_timestamp,
        data_atualizacao = current_timestamp
    from tb_crm_evento_versoes vers
    left join lateral (
        select count(*)::integer as total_linhas
        from tb_ticketsports_participantes tsp
        where tsp.cod_evento::varchar = vers.cod_evento_externo
    ) cont on true
    where imp.fonte = 'ticketsports'
      and imp.origem_tipo = 'api'
      and imp.tipo_entidade = 'participantes'
      and imp.api_endpoint = 'tb_ticketsports'
      and imp.api_parametros ->> 'cod_evento' = vers.cod_evento_externo
      and (p_cod_evento is null or vers.cod_evento_externo = p_cod_evento::varchar);

    insert into tb_crm_importacoes (
        id_crm_evento_versao,
        id_evento,
        fonte,
        cod_evento_externo,
        origem_tipo,
        tipo_entidade,
        nome_importacao,
        api_endpoint,
        api_parametros,
        status_processamento,
        total_linhas,
        total_validas,
        data_inicio,
        data_fim
    )
    select
        vers.id_crm_evento_versao,
        vers.id_evento,
        'ticketsports',
        vers.cod_evento_externo,
        'api',
        'participantes',
        'TicketSports API ' || vers.cod_evento_externo,
        'tb_ticketsports',
        jsonb_build_object('cod_evento', vers.cod_evento_externo),
        'processado',
        coalesce(cont.total_linhas, 0),
        coalesce(cont.total_linhas, 0),
        current_timestamp,
        current_timestamp
    from tb_crm_evento_versoes vers
    left join lateral (
        select count(*)::integer as total_linhas
        from tb_ticketsports_participantes tsp
        where tsp.cod_evento::varchar = vers.cod_evento_externo
    ) cont on true
    where vers.fonte = 'ticketsports'
      and (p_cod_evento is null or vers.cod_evento_externo = p_cod_evento::varchar)
      and not exists (
          select 1
          from tb_crm_importacoes imp
          where imp.fonte = 'ticketsports'
            and imp.origem_tipo = 'api'
            and imp.tipo_entidade = 'participantes'
            and imp.api_endpoint = 'tb_ticketsports'
            and imp.api_parametros ->> 'cod_evento' = vers.cod_evento_externo
      );

    insert into tb_crm_pedidos (
        id_crm_evento_versao,
        id_crm_importacao,
        fonte,
        cod_evento_externo,
        numero_pedido,
        status_pedido,
        data_pedido,
        data_pagamento,
        forma_pagamento,
        tipo_dispositivo,
        qtd_inscricoes,
        valor_total,
        valor_taxa,
        valor_desconto,
        valor_repasse,
        responsavel_nome,
        responsavel_email,
        responsavel_email_norm,
        responsavel_documento,
        responsavel_doc_norm,
        responsavel_telefone,
        responsavel_tel_norm,
        responsavel_nascimento,
        responsavel_endereco,
        responsavel_numero,
        responsavel_bairro,
        responsavel_cidade,
        responsavel_estado,
        responsavel_cep,
        raw
    )
    select
        vers.id_crm_evento_versao,
        imp.id_crm_importacao,
        'ticketsports',
        ped.cod_evento::varchar,
        ped.numero_pedido::varchar,
        nullif(ped.body ->> 'status', ''),
        coalesce(ped.data_pedido, crm_parse_timestamp_br(ped.body ->> 'dataPedido')),
        crm_parse_timestamp_br(ped.body ->> 'dataPagamento'),
        nullif(ped.body ->> 'formaDePagamento', ''),
        nullif(ped.body ->> 'tipoDispositivo', ''),
        case
            when (ped.body ->> 'qtdeInscricao') ~ '^\d+$' then (ped.body ->> 'qtdeInscricao')::integer
            else null
        end,
        crm_parse_decimal_br(ped.body ->> 'valor'),
        crm_parse_decimal_br(ped.body ->> 'taxa'),
        crm_parse_decimal_br(ped.body ->> 'desconto'),
        crm_parse_decimal_br(coalesce(ped.body ->> 'valorRepassePedido', ped.body ->> 'valorRepasse')),
        nullif(ped.body #>> '{responsavel,responsavel}', ''),
        lower(nullif(ped.body #>> '{responsavel,emailResponsavel}', '')),
        lower(nullif(ped.body #>> '{responsavel,emailResponsavel}', '')),
        nullif(ped.body #>> '{responsavel,documentoResponsavel}', ''),
        crm_only_digits(ped.body #>> '{responsavel,documentoResponsavel}'),
        nullif(ped.body #>> '{responsavel,celularResponsavel}', ''),
        crm_only_digits(ped.body #>> '{responsavel,celularResponsavel}'),
        crm_parse_date_br(ped.body #>> '{responsavel,datanascResponsavel}'),
        nullif(ped.body #>> '{responsavel,endereco}', ''),
        nullif(ped.body #>> '{responsavel,numero}', ''),
        nullif(ped.body #>> '{responsavel,bairro}', ''),
        nullif(ped.body #>> '{responsavel,cidade}', ''),
        nullif(ped.body #>> '{responsavel,estado}', ''),
        crm_only_digits(ped.body #>> '{responsavel,cep}'),
        ped.body
    from tb_ticketsports_pedidos ped
    inner join tb_crm_evento_versoes vers
        on vers.fonte = 'ticketsports'
       and vers.cod_evento_externo = ped.cod_evento::varchar
    left join tb_crm_importacoes imp
        on imp.fonte = 'ticketsports'
       and imp.origem_tipo = 'api'
       and imp.tipo_entidade = 'participantes'
       and imp.api_endpoint = 'tb_ticketsports'
       and imp.api_parametros ->> 'cod_evento' = ped.cod_evento::varchar
    where p_cod_evento is null
       or ped.cod_evento = p_cod_evento
    on conflict (fonte, cod_evento_externo, numero_pedido) do update
        set id_crm_evento_versao = excluded.id_crm_evento_versao,
            id_crm_importacao = excluded.id_crm_importacao,
            status_pedido = excluded.status_pedido,
            data_pedido = excluded.data_pedido,
            data_pagamento = excluded.data_pagamento,
            forma_pagamento = excluded.forma_pagamento,
            tipo_dispositivo = excluded.tipo_dispositivo,
            qtd_inscricoes = excluded.qtd_inscricoes,
            valor_total = excluded.valor_total,
            valor_taxa = excluded.valor_taxa,
            valor_desconto = excluded.valor_desconto,
            valor_repasse = excluded.valor_repasse,
            responsavel_nome = excluded.responsavel_nome,
            responsavel_email = excluded.responsavel_email,
            responsavel_email_norm = excluded.responsavel_email_norm,
            responsavel_documento = excluded.responsavel_documento,
            responsavel_doc_norm = excluded.responsavel_doc_norm,
            responsavel_telefone = excluded.responsavel_telefone,
            responsavel_tel_norm = excluded.responsavel_tel_norm,
            responsavel_nascimento = excluded.responsavel_nascimento,
            responsavel_endereco = excluded.responsavel_endereco,
            responsavel_numero = excluded.responsavel_numero,
            responsavel_bairro = excluded.responsavel_bairro,
            responsavel_cidade = excluded.responsavel_cidade,
            responsavel_estado = excluded.responsavel_estado,
            responsavel_cep = excluded.responsavel_cep,
            raw = excluded.raw,
            data_atualizacao = current_timestamp;

    insert into tb_crm_importacao_linhas (
        id_crm_importacao,
        numero_linha,
        entidade_origem,
        chave_externa,
        raw,
        normalizado,
        nome_atleta,
        nome_norm,
        email,
        email_norm,
        tipo_documento,
        documento,
        documento_norm,
        telefone,
        telefone_norm,
        data_nascimento,
        sexo,
        cidade,
        estado,
        pais,
        numero_inscricao,
        numero_pedido,
        protocolo,
        percurso,
        modalidade,
        categoria,
        status_inscricao,
        origem,
        campanha,
        cupom,
        assessoria,
        data_pedido,
        valor,
        status_validacao
    )
    select
        imp.id_crm_importacao,
        tsp.numero_inscricao,
        'ticketsports_participante',
        tsp.numero_inscricao::varchar,
        tsp.body,
        jsonb_build_object(
            'fonte', 'ticketsports',
            'cod_evento', tsp.cod_evento,
            'numero_pedido', tsp.numero_pedido,
            'numero_inscricao', tsp.numero_inscricao
        ),
        nullif(coalesce(tsp.body ->> 'nome', tsp.nome), ''),
        crm_normalize_text(coalesce(tsp.body ->> 'nome', tsp.nome)),
        lower(nullif(coalesce(tsp.body ->> 'email', tsp.email), '')),
        lower(nullif(coalesce(tsp.body ->> 'email', tsp.email), '')),
        nullif(tsp.body ->> 'tipoDocumento', ''),
        nullif(coalesce(tsp.body ->> 'documento', tsp.documento), ''),
        crm_only_digits(coalesce(tsp.body ->> 'documento', tsp.documento)),
        nullif(tsp.body ->> 'celular', ''),
        crm_only_digits(tsp.body ->> 'celular'),
        crm_parse_date_br(tsp.body ->> 'nascimento'),
        crm_normalize_sexo(tsp.body ->> 'sexo'),
        nullif(coalesce(tsp.body ->> 'cidade', tsp.cidade), ''),
        nullif(coalesce(tsp.body ->> 'estado', tsp.estado), ''),
        nullif(tsp.body ->> 'pais', ''),
        tsp.numero_inscricao::varchar,
        tsp.numero_pedido::varchar,
        nullif(tsp.body ->> 'protocolo', ''),
        crm_infer_percurso(coalesce(tsp.body ->> 'modalidade', tsp.modalidade)),
        nullif(coalesce(tsp.body ->> 'modalidade', tsp.modalidade), ''),
        nullif(tsp.body ->> 'categoria', ''),
        ped.status_pedido,
        nullif(tsp.body ->> 'origem', ''),
        nullif(tsp.body ->> 'campanha', ''),
        coalesce(nullif(tsp.body ->> 'tituloCupom', ''), nullif(tsp.body ->> 'codigoCupom', '')),
        nullif(tsp.body ->> 'nome_grupo', ''),
        tsp.data_pedido,
        crm_parse_decimal_br(tsp.body ->> 'valorUnitario'),
        case
            when crm_normalize_text(coalesce(tsp.body ->> 'nome', tsp.nome)) is null then 'invalido'
            else 'valido'
        end
    from tb_ticketsports_participantes tsp
    inner join tb_crm_importacoes imp
        on imp.fonte = 'ticketsports'
       and imp.origem_tipo = 'api'
       and imp.tipo_entidade = 'participantes'
       and imp.api_endpoint = 'tb_ticketsports'
       and imp.api_parametros ->> 'cod_evento' = tsp.cod_evento::varchar
    left join tb_crm_pedidos ped
        on ped.fonte = 'ticketsports'
       and ped.cod_evento_externo = tsp.cod_evento::varchar
       and ped.numero_pedido = tsp.numero_pedido::varchar
    where p_cod_evento is null
       or tsp.cod_evento = p_cod_evento
    on conflict (id_crm_importacao, numero_linha, entidade_origem) do update
        set chave_externa = excluded.chave_externa,
            raw = excluded.raw,
            normalizado = excluded.normalizado,
            nome_atleta = excluded.nome_atleta,
            nome_norm = excluded.nome_norm,
            email = excluded.email,
            email_norm = excluded.email_norm,
            tipo_documento = excluded.tipo_documento,
            documento = excluded.documento,
            documento_norm = excluded.documento_norm,
            telefone = excluded.telefone,
            telefone_norm = excluded.telefone_norm,
            data_nascimento = excluded.data_nascimento,
            sexo = excluded.sexo,
            cidade = excluded.cidade,
            estado = excluded.estado,
            pais = excluded.pais,
            numero_inscricao = excluded.numero_inscricao,
            numero_pedido = excluded.numero_pedido,
            protocolo = excluded.protocolo,
            percurso = excluded.percurso,
            modalidade = excluded.modalidade,
            categoria = excluded.categoria,
            status_inscricao = excluded.status_inscricao,
            origem = excluded.origem,
            campanha = excluded.campanha,
            cupom = excluded.cupom,
            assessoria = excluded.assessoria,
            data_pedido = excluded.data_pedido,
            valor = excluded.valor,
            status_validacao = excluded.status_validacao,
            data_atualizacao = current_timestamp;

    with src as (
        select distinct on (crm_only_digits(coalesce(tsp.body ->> 'documento', tsp.documento)))
            nullif(coalesce(tsp.body ->> 'nome', tsp.nome), '') as nome,
            crm_normalize_text(coalesce(tsp.body ->> 'nome', tsp.nome)) as nome_norm,
            lower(nullif(coalesce(tsp.body ->> 'email', tsp.email), '')) as email,
            lower(nullif(coalesce(tsp.body ->> 'email', tsp.email), '')) as email_norm,
            nullif(coalesce(tsp.body ->> 'documento', tsp.documento), '') as documento,
            crm_only_digits(coalesce(tsp.body ->> 'documento', tsp.documento)) as documento_norm,
            nullif(tsp.body ->> 'celular', '') as telefone,
            crm_only_digits(tsp.body ->> 'celular') as telefone_norm,
            crm_parse_date_br(tsp.body ->> 'nascimento') as data_nascimento,
            crm_normalize_sexo(tsp.body ->> 'sexo') as sexo,
            nullif(coalesce(tsp.body ->> 'cidade', tsp.cidade), '') as cidade,
            nullif(coalesce(tsp.body ->> 'estado', tsp.estado), '') as estado,
            coalesce(nullif(tsp.body ->> 'pais', ''), 'BR') as pais,
            nullif(tsp.body ->> 'nome_grupo', '') as assessoria
        from tb_ticketsports_participantes tsp
        where (p_cod_evento is null or tsp.cod_evento = p_cod_evento)
          and crm_only_digits(coalesce(tsp.body ->> 'documento', tsp.documento)) is not null
          and crm_normalize_text(coalesce(tsp.body ->> 'nome', tsp.nome)) is not null
        order by
            crm_only_digits(coalesce(tsp.body ->> 'documento', tsp.documento)),
            tsp.data_pedido desc nulls last
    )
    insert into tb_crm_pessoas (
        nome,
        nome_norm,
        email,
        email_norm,
        documento,
        documento_norm,
        telefone,
        telefone_norm,
        data_nascimento,
        sexo,
        cidade,
        estado,
        pais,
        assessoria,
        origem_primeiro_contato
    )
    select
        src.nome,
        src.nome_norm,
        src.email,
        src.email_norm,
        src.documento,
        src.documento_norm,
        src.telefone,
        src.telefone_norm,
        src.data_nascimento,
        src.sexo,
        src.cidade,
        src.estado,
        src.pais,
        src.assessoria,
        'ticketsports'
    from src
    on conflict (documento_norm)
        where documento_norm is not null and documento_norm <> ''
    do update
        set nome = coalesce(excluded.nome, tb_crm_pessoas.nome),
            nome_norm = coalesce(excluded.nome_norm, tb_crm_pessoas.nome_norm),
            email = coalesce(excluded.email, tb_crm_pessoas.email),
            email_norm = coalesce(excluded.email_norm, tb_crm_pessoas.email_norm),
            telefone = coalesce(excluded.telefone, tb_crm_pessoas.telefone),
            telefone_norm = coalesce(excluded.telefone_norm, tb_crm_pessoas.telefone_norm),
            data_nascimento = coalesce(excluded.data_nascimento, tb_crm_pessoas.data_nascimento),
            sexo = coalesce(excluded.sexo, tb_crm_pessoas.sexo),
            cidade = coalesce(excluded.cidade, tb_crm_pessoas.cidade),
            estado = coalesce(excluded.estado, tb_crm_pessoas.estado),
            pais = coalesce(excluded.pais, tb_crm_pessoas.pais),
            assessoria = coalesce(excluded.assessoria, tb_crm_pessoas.assessoria),
            data_atualizacao = current_timestamp;

    with src as (
        select distinct on (
            lower(nullif(coalesce(tsp.body ->> 'email', tsp.email), '')),
            crm_normalize_text(coalesce(tsp.body ->> 'nome', tsp.nome)),
            crm_parse_date_br(tsp.body ->> 'nascimento')
        )
            nullif(coalesce(tsp.body ->> 'nome', tsp.nome), '') as nome,
            crm_normalize_text(coalesce(tsp.body ->> 'nome', tsp.nome)) as nome_norm,
            lower(nullif(coalesce(tsp.body ->> 'email', tsp.email), '')) as email,
            lower(nullif(coalesce(tsp.body ->> 'email', tsp.email), '')) as email_norm,
            nullif(tsp.body ->> 'celular', '') as telefone,
            crm_only_digits(tsp.body ->> 'celular') as telefone_norm,
            crm_parse_date_br(tsp.body ->> 'nascimento') as data_nascimento,
            crm_normalize_sexo(tsp.body ->> 'sexo') as sexo,
            nullif(coalesce(tsp.body ->> 'cidade', tsp.cidade), '') as cidade,
            nullif(coalesce(tsp.body ->> 'estado', tsp.estado), '') as estado,
            coalesce(nullif(tsp.body ->> 'pais', ''), 'BR') as pais,
            nullif(tsp.body ->> 'nome_grupo', '') as assessoria
        from tb_ticketsports_participantes tsp
        where (p_cod_evento is null or tsp.cod_evento = p_cod_evento)
          and crm_only_digits(coalesce(tsp.body ->> 'documento', tsp.documento)) is null
          and lower(nullif(coalesce(tsp.body ->> 'email', tsp.email), '')) is not null
          and crm_normalize_text(coalesce(tsp.body ->> 'nome', tsp.nome)) is not null
          and crm_parse_date_br(tsp.body ->> 'nascimento') is not null
        order by
            lower(nullif(coalesce(tsp.body ->> 'email', tsp.email), '')),
            crm_normalize_text(coalesce(tsp.body ->> 'nome', tsp.nome)),
            crm_parse_date_br(tsp.body ->> 'nascimento'),
            tsp.data_pedido desc nulls last
    )
    insert into tb_crm_pessoas (
        nome,
        nome_norm,
        email,
        email_norm,
        telefone,
        telefone_norm,
        data_nascimento,
        sexo,
        cidade,
        estado,
        pais,
        assessoria,
        origem_primeiro_contato
    )
    select
        src.nome,
        src.nome_norm,
        src.email,
        src.email_norm,
        src.telefone,
        src.telefone_norm,
        src.data_nascimento,
        src.sexo,
        src.cidade,
        src.estado,
        src.pais,
        src.assessoria,
        'ticketsports'
    from src
    on conflict (email_norm, nome_norm, data_nascimento)
        where documento_norm is null
          and email_norm is not null
          and email_norm <> ''
          and data_nascimento is not null
    do update
        set telefone = coalesce(excluded.telefone, tb_crm_pessoas.telefone),
            telefone_norm = coalesce(excluded.telefone_norm, tb_crm_pessoas.telefone_norm),
            sexo = coalesce(excluded.sexo, tb_crm_pessoas.sexo),
            cidade = coalesce(excluded.cidade, tb_crm_pessoas.cidade),
            estado = coalesce(excluded.estado, tb_crm_pessoas.estado),
            pais = coalesce(excluded.pais, tb_crm_pessoas.pais),
            assessoria = coalesce(excluded.assessoria, tb_crm_pessoas.assessoria),
            data_atualizacao = current_timestamp;

    with src as (
        select
            tsp.*,
            crm_only_digits(coalesce(tsp.body ->> 'documento', tsp.documento)) as documento_norm,
            lower(nullif(coalesce(tsp.body ->> 'email', tsp.email), '')) as email_norm,
            crm_normalize_text(coalesce(tsp.body ->> 'nome', tsp.nome)) as nome_norm,
            crm_parse_date_br(tsp.body ->> 'nascimento') as data_nascimento_norm,
            crm_infer_percurso(coalesce(tsp.body ->> 'modalidade', tsp.modalidade)) as percurso_norm
        from tb_ticketsports_participantes tsp
        where p_cod_evento is null
           or tsp.cod_evento = p_cod_evento
    ),
    vinculada as (
        select
            src.*,
            coalesce(pessoa_doc.id_crm_pessoa, pessoa_email.id_crm_pessoa) as id_crm_pessoa,
            vers.id_crm_evento_versao,
            vers.id_evento,
            vers.ano_evento,
            vers.nome_evento_externo,
            vers.data_evento,
            ped.id_crm_pedido,
            ped.status_pedido,
            ped.data_pagamento,
            linha.id_crm_importacao_linha
        from src
        inner join tb_crm_evento_versoes vers
            on vers.fonte = 'ticketsports'
           and vers.cod_evento_externo = src.cod_evento::varchar
        left join tb_crm_pedidos ped
            on ped.fonte = 'ticketsports'
           and ped.cod_evento_externo = src.cod_evento::varchar
           and ped.numero_pedido = src.numero_pedido::varchar
        left join tb_crm_importacoes imp
            on imp.fonte = 'ticketsports'
           and imp.origem_tipo = 'api'
           and imp.tipo_entidade = 'participantes'
           and imp.api_endpoint = 'tb_ticketsports'
           and imp.api_parametros ->> 'cod_evento' = src.cod_evento::varchar
        left join tb_crm_importacao_linhas linha
            on linha.id_crm_importacao = imp.id_crm_importacao
           and linha.numero_linha = src.numero_inscricao
           and linha.entidade_origem = 'ticketsports_participante'
        left join tb_crm_pessoas pessoa_doc
            on pessoa_doc.documento_norm = src.documento_norm
           and src.documento_norm is not null
        left join tb_crm_pessoas pessoa_email
            on pessoa_doc.id_crm_pessoa is null
           and pessoa_email.documento_norm is null
           and pessoa_email.email_norm = src.email_norm
           and pessoa_email.nome_norm = src.nome_norm
           and pessoa_email.data_nascimento = src.data_nascimento_norm
    )
    insert into tb_crm_participacoes (
        id_crm_pessoa,
        id_crm_pedido,
        id_crm_evento_versao,
        id_crm_importacao_linha,
        id_evento,
        fonte,
        cod_evento_externo,
        ano_evento,
        nome_evento_externo,
        data_evento,
        numero_inscricao,
        numero_pedido,
        protocolo,
        id_categoria_externo,
        lote,
        percurso,
        percurso_label,
        modalidade,
        categoria,
        status_inscricao,
        status_pedido,
        data_pedido,
        data_pagamento,
        origem,
        campanha,
        cupom,
        valor_unitario,
        valor_taxa,
        valor_desconto,
        valor_desconto_cupom,
        valor_repasse,
        assessoria,
        produtos,
        questionario,
        raw,
        lead_score,
        lead_score_componentes
    )
    select
        vinculada.id_crm_pessoa,
        vinculada.id_crm_pedido,
        vinculada.id_crm_evento_versao,
        vinculada.id_crm_importacao_linha,
        vinculada.id_evento,
        'ticketsports',
        vinculada.cod_evento::varchar,
        vinculada.ano_evento,
        vinculada.nome_evento_externo,
        vinculada.data_evento,
        vinculada.numero_inscricao::varchar,
        vinculada.numero_pedido::varchar,
        nullif(vinculada.body ->> 'protocolo', ''),
        nullif(vinculada.body ->> 'id_Categoria', ''),
        case
            when (vinculada.body ->> 'lote') ~ '^\d+$' then (vinculada.body ->> 'lote')::integer
            else null
        end,
        vinculada.percurso_norm,
        case when vinculada.percurso_norm is not null then vinculada.percurso_norm::varchar || 'K' end,
        nullif(coalesce(vinculada.body ->> 'modalidade', vinculada.modalidade), ''),
        nullif(vinculada.body ->> 'categoria', ''),
        vinculada.status_pedido,
        vinculada.status_pedido,
        coalesce(vinculada.data_pedido, crm_parse_timestamp_br(vinculada.body ->> 'dataPedido')),
        vinculada.data_pagamento,
        nullif(vinculada.body ->> 'origem', ''),
        nullif(vinculada.body ->> 'campanha', ''),
        coalesce(nullif(vinculada.body ->> 'tituloCupom', ''), nullif(vinculada.body ->> 'codigoCupom', '')),
        crm_parse_decimal_br(vinculada.body ->> 'valorUnitario'),
        crm_parse_decimal_br(vinculada.body ->> 'valorTaxa'),
        crm_parse_decimal_br(vinculada.body ->> 'valorDesconto'),
        crm_parse_decimal_br(vinculada.body ->> 'valorDescontoCupom'),
        crm_parse_decimal_br(vinculada.body ->> 'valorRepasse'),
        nullif(vinculada.body ->> 'nome_grupo', ''),
        vinculada.body -> 'produtos',
        vinculada.body -> 'questionario',
        vinculada.body,
        (
            case when coalesce(vinculada.status_pedido, '') ilike 'Pago' then 50 else 10 end
            + case when vinculada.documento_norm is not null then 15 else 0 end
            + case when vinculada.email_norm is not null then 10 else 0 end
            + case when vinculada.percurso_norm >= 21 then 10 when vinculada.percurso_norm is not null then 5 else 0 end
        )::numeric,
        jsonb_build_object(
            'status_pago', case when coalesce(vinculada.status_pedido, '') ilike 'Pago' then 50 else 10 end,
            'documento', case when vinculada.documento_norm is not null then 15 else 0 end,
            'email', case when vinculada.email_norm is not null then 10 else 0 end,
            'percurso', case when vinculada.percurso_norm >= 21 then 10 when vinculada.percurso_norm is not null then 5 else 0 end
        )
    from vinculada
    where vinculada.id_crm_pessoa is not null
    on conflict (fonte, cod_evento_externo, numero_inscricao)
        where numero_inscricao is not null and numero_inscricao <> ''
    do update
        set id_crm_pessoa = excluded.id_crm_pessoa,
            id_crm_pedido = excluded.id_crm_pedido,
            id_crm_evento_versao = excluded.id_crm_evento_versao,
            id_crm_importacao_linha = excluded.id_crm_importacao_linha,
            id_evento = excluded.id_evento,
            ano_evento = excluded.ano_evento,
            nome_evento_externo = excluded.nome_evento_externo,
            data_evento = excluded.data_evento,
            numero_pedido = excluded.numero_pedido,
            protocolo = excluded.protocolo,
            id_categoria_externo = excluded.id_categoria_externo,
            lote = excluded.lote,
            percurso = excluded.percurso,
            percurso_label = excluded.percurso_label,
            modalidade = excluded.modalidade,
            categoria = excluded.categoria,
            status_inscricao = excluded.status_inscricao,
            status_pedido = excluded.status_pedido,
            data_pedido = excluded.data_pedido,
            data_pagamento = excluded.data_pagamento,
            origem = excluded.origem,
            campanha = excluded.campanha,
            cupom = excluded.cupom,
            valor_unitario = excluded.valor_unitario,
            valor_taxa = excluded.valor_taxa,
            valor_desconto = excluded.valor_desconto,
            valor_desconto_cupom = excluded.valor_desconto_cupom,
            valor_repasse = excluded.valor_repasse,
            assessoria = excluded.assessoria,
            produtos = excluded.produtos,
            questionario = excluded.questionario,
            raw = excluded.raw,
            lead_score = excluded.lead_score,
            lead_score_componentes = excluded.lead_score_componentes,
            data_atualizacao = current_timestamp;

    perform 1
    from crm.crm_match_resultados(null, null)
    limit 1;

    perform 1
    from crm.crm_match_usuarios(null)
    limit 1;

    return query
    select
        (
            select count(*)::integer
            from tb_crm_evento_versoes vers
            where vers.fonte = 'ticketsports'
              and (p_cod_evento is null or vers.cod_evento_externo = p_cod_evento::varchar)
        ) as total_versoes,
        (
            select count(*)::integer
            from tb_crm_importacoes imp
            where imp.fonte = 'ticketsports'
              and imp.origem_tipo = 'api'
              and imp.tipo_entidade = 'participantes'
              and (p_cod_evento is null or imp.api_parametros ->> 'cod_evento' = p_cod_evento::varchar)
        ) as total_importacoes,
        (
            select count(*)::integer
            from tb_crm_pedidos ped
            where ped.fonte = 'ticketsports'
              and (p_cod_evento is null or ped.cod_evento_externo = p_cod_evento::varchar)
        ) as total_pedidos,
        (
            select count(distinct part.id_crm_pessoa)::integer
            from tb_crm_participacoes part
            where part.fonte = 'ticketsports'
              and (p_cod_evento is null or part.cod_evento_externo = p_cod_evento::varchar)
        ) as total_pessoas,
        (
            select count(*)::integer
            from tb_crm_participacoes part
            where part.fonte = 'ticketsports'
              and (p_cod_evento is null or part.cod_evento_externo = p_cod_evento::varchar)
        ) as total_participacoes;
end;
$$;

drop function if exists crm.crm_link_fonte_evento(varchar, integer, varchar, integer, bigint, varchar, jsonb);

create or replace function crm_link_fonte_evento(
    p_fonte varchar,
    p_id_evento integer,
    p_cod_evento_externo varchar default null,
    p_id_parceiro integer default null,
    p_usuario_cadastro bigint default null,
    p_nome_evento_externo varchar default null,
    p_payload jsonb default '{}'::jsonb
)
returns table (
    fonte varchar,
    evento_codigo_externo varchar,
    evento_rr_id integer,
    evento_rr_nome varchar,
    parceiro_id integer,
    crm_evento_versao_id integer,
    total_participacoes integer,
    total_resultados_vinculados integer,
    total_usuarios_vinculados integer
)
language plpgsql
set search_path = crm, public
as $$
declare
    v_fonte varchar;
    v_cod_evento_externo varchar;
    v_id_crm_evento_serie integer;
    v_id_crm_evento_versao integer;
    v_match record;
begin
    v_fonte := nullif(lower(trim(coalesce(p_fonte, ''))), '');
    v_cod_evento_externo := nullif(trim(coalesce(p_cod_evento_externo, '')), '');

    if v_fonte is null then
        raise exception 'p_fonte e obrigatorio';
    end if;

    if p_id_evento is null then
        raise exception 'p_id_evento e obrigatorio';
    end if;

    if not exists (
        select 1
        from public.tb_evento_corridas evt
        where evt.id_evento = p_id_evento
    ) then
        raise exception 'Evento Road Runners % nao encontrado', p_id_evento;
    end if;

    if p_id_parceiro is not null and not exists (
        select 1
        from public.tb_parceiros par
        where par.id_parceiro = p_id_parceiro
    ) then
        raise exception 'Parceiro % nao encontrado', p_id_parceiro;
    end if;

    insert into crm.tb_crm_evento_series (
        nome_serie,
        slug_serie,
        descricao
    )
    values (
        'Eventos Road Runners CRM',
        'eventos-roadrunners-crm',
        'Serie generica para fontes de inscricao vinculadas diretamente a eventos Road Runners.'
    )
    on conflict (slug_serie) do update
        set nome_serie = excluded.nome_serie,
            data_atualizacao = current_timestamp
    returning id_crm_evento_serie
    into v_id_crm_evento_serie;

    select vers.id_crm_evento_versao
    into v_id_crm_evento_versao
    from crm.tb_crm_evento_versoes vers
    where vers.fonte = v_fonte
      and (
          (v_cod_evento_externo is not null and vers.cod_evento_externo = v_cod_evento_externo)
          or (
              v_cod_evento_externo is null
              and (vers.cod_evento_externo is null or vers.cod_evento_externo = '')
              and vers.id_evento = p_id_evento
              and coalesce(vers.id_parceiro, -1) = coalesce(p_id_parceiro, -1)
          )
      )
    order by case when vers.id_evento = p_id_evento then 0 else 1 end,
             vers.id_crm_evento_versao
    limit 1;

    if v_id_crm_evento_versao is null then
        insert into crm.tb_crm_evento_versoes (
            id_crm_evento_serie,
            id_evento,
            id_parceiro,
            fonte,
            cod_evento_externo,
            nome_evento_externo,
            ano_evento,
            data_evento,
            payload
        )
        select
            v_id_crm_evento_serie,
            evt.id_evento,
            p_id_parceiro,
            v_fonte,
            v_cod_evento_externo,
            coalesce(p_nome_evento_externo, evt.nome_evento),
            extract(year from evt.data_inicial)::integer,
            evt.data_inicial,
            coalesce(p_payload, '{}'::jsonb)
                || jsonb_build_object(
                    'id_evento_origem', 'manual',
                    'id_evento_usuario_cadastro', p_usuario_cadastro
                )
        from public.tb_evento_corridas evt
        where evt.id_evento = p_id_evento
        returning id_crm_evento_versao
        into v_id_crm_evento_versao;
    else
        update crm.tb_crm_evento_versoes vers
        set id_crm_evento_serie = coalesce(vers.id_crm_evento_serie, v_id_crm_evento_serie),
            id_evento = p_id_evento,
            id_parceiro = coalesce(p_id_parceiro, vers.id_parceiro),
            cod_evento_externo = coalesce(v_cod_evento_externo, vers.cod_evento_externo),
            nome_evento_externo = coalesce(p_nome_evento_externo, vers.nome_evento_externo),
            ano_evento = coalesce(vers.ano_evento, extract(year from evt.data_inicial)::integer),
            data_evento = coalesce(vers.data_evento, evt.data_inicial),
            payload = coalesce(vers.payload, '{}'::jsonb)
                || coalesce(p_payload, '{}'::jsonb)
                || jsonb_build_object(
                    'id_evento_origem', 'manual',
                    'id_evento_usuario_cadastro', p_usuario_cadastro
                ),
            data_atualizacao = current_timestamp
        from public.tb_evento_corridas evt
        where vers.id_crm_evento_versao = v_id_crm_evento_versao
          and evt.id_evento = p_id_evento;
    end if;

    update crm.tb_crm_importacoes imp
    set id_crm_evento_versao = v_id_crm_evento_versao,
        id_evento = p_id_evento,
        id_parceiro = coalesce(p_id_parceiro, imp.id_parceiro),
        cod_evento_externo = coalesce(v_cod_evento_externo, imp.cod_evento_externo),
        data_atualizacao = current_timestamp
    where imp.fonte = v_fonte
      and (
          (v_cod_evento_externo is not null and (
              imp.cod_evento_externo = v_cod_evento_externo
              or imp.api_parametros ->> 'cod_evento' = v_cod_evento_externo
          ))
          or (
              v_cod_evento_externo is null
              and imp.id_evento = p_id_evento
              and imp.id_crm_evento_versao is null
          )
      );

    update crm.tb_crm_participacoes part
    set id_crm_evento_versao = v_id_crm_evento_versao,
        id_evento = p_id_evento,
        id_parceiro = coalesce(p_id_parceiro, part.id_parceiro),
        data_atualizacao = current_timestamp
    where part.fonte = v_fonte
      and (
          (v_cod_evento_externo is not null and part.cod_evento_externo = v_cod_evento_externo)
          or (
              v_cod_evento_externo is null
              and part.id_evento = p_id_evento
              and part.id_crm_evento_versao is null
          )
      );

    update crm.tb_crm_pedidos ped
    set id_crm_evento_versao = v_id_crm_evento_versao,
        id_parceiro = coalesce(p_id_parceiro, ped.id_parceiro),
        data_atualizacao = current_timestamp
    where ped.fonte = v_fonte
      and (
          (v_cod_evento_externo is not null and ped.cod_evento_externo = v_cod_evento_externo)
          or (
              v_cod_evento_externo is null
              and ped.id_crm_evento_versao is null
              and exists (
                  select 1
                  from crm.tb_crm_importacoes imp
                  where imp.id_crm_importacao = ped.id_crm_importacao
                    and imp.fonte = v_fonte
                    and imp.id_evento = p_id_evento
              )
          )
      );

    insert into crm.tb_crm_conta_evento_versoes (
        id_conta,
        id_crm_evento_versao,
        status,
        usuario_cadastro,
        origem
    )
    select
        cev.id_conta,
        v_id_crm_evento_versao,
        cev.status,
        p_usuario_cadastro,
        'tb_conta_eventos'
    from public.tb_conta_eventos cev
    where cev.id_evento = p_id_evento
    on conflict (id_conta, id_crm_evento_versao) do update
        set status = excluded.status,
            usuario_cadastro = coalesce(excluded.usuario_cadastro, crm.tb_crm_conta_evento_versoes.usuario_cadastro),
            origem = excluded.origem,
            data_atualizacao = now();

    select *
    into v_match
    from crm.crm_match_resultados(null, p_id_evento)
    limit 1;

    return query
    select
        vers.fonte,
        vers.cod_evento_externo,
        evt.id_evento,
        evt.nome_evento,
        vers.id_parceiro,
        vers.id_crm_evento_versao,
        (
            select count(*)::integer
            from crm.tb_crm_participacoes part
            where part.id_crm_evento_versao = vers.id_crm_evento_versao
        ) as total_participacoes,
        coalesce(v_match.participacoes_vinculadas, 0)::integer as total_resultados_vinculados,
        coalesce(v_match.pessoas_vinculadas, 0)::integer as total_usuarios_vinculados
    from crm.tb_crm_evento_versoes vers
    inner join public.tb_evento_corridas evt
        on evt.id_evento = p_id_evento
    where vers.id_crm_evento_versao = v_id_crm_evento_versao;
end;
$$;

drop function if exists crm.crm_link_ticketsports_evento(integer, integer, bigint);

create or replace function crm_link_ticketsports_evento(
    p_cod_evento integer,
    p_id_evento integer,
    p_usuario_cadastro bigint default null
)
returns table (
    evento_codigo_externo varchar,
    evento_rr_id integer,
    evento_rr_nome varchar,
    crm_evento_versao_id integer,
    total_participacoes integer,
    total_resultados_vinculados integer,
    total_usuarios_vinculados integer
)
language plpgsql
set search_path = crm, public
as $$
begin
    if p_cod_evento is null then
        raise exception 'p_cod_evento e obrigatorio';
    end if;

    perform 1
    from crm.crm_sync_ticketsports(p_cod_evento)
    limit 1;

    return query
    select
        link.evento_codigo_externo,
        link.evento_rr_id,
        link.evento_rr_nome,
        link.crm_evento_versao_id,
        link.total_participacoes,
        link.total_resultados_vinculados,
        link.total_usuarios_vinculados
    from crm.crm_link_fonte_evento(
        'ticketsports',
        p_id_evento,
        p_cod_evento::varchar,
        null,
        p_usuario_cadastro,
        null,
        jsonb_build_object('wrapper', 'crm_link_ticketsports_evento')
    ) link;
end;
$$;

drop function if exists crm.crm_criar_importacao_arquivo(integer, varchar, varchar, varchar, varchar, integer, varchar, integer, varchar, bigint, jsonb);

create or replace function crm_criar_importacao_arquivo(
    p_id_evento integer,
    p_fonte varchar,
    p_nome_importacao varchar,
    p_arquivo_nome varchar,
    p_arquivo_hash varchar default null,
    p_usuario_importacao integer default null,
    p_cod_evento_externo varchar default null,
    p_id_parceiro integer default null,
    p_arquivo_mime varchar default null,
    p_arquivo_tamanho_bytes bigint default null,
    p_mapeamento jsonb default null
)
returns table (
    id_crm_importacao bigint,
    id_crm_evento_versao integer,
    id_evento integer,
    fonte varchar,
    cod_evento_externo varchar,
    status_processamento varchar
)
language plpgsql
set search_path = crm, public
as $$
declare
    v_link record;
begin
    select *
    into v_link
    from crm.crm_link_fonte_evento(
        p_fonte,
        p_id_evento,
        p_cod_evento_externo,
        p_id_parceiro,
        p_usuario_importacao,
        null,
        jsonb_build_object('origem', 'arquivo')
    )
    limit 1;

    return query
    insert into crm.tb_crm_importacoes (
        id_crm_evento_versao,
        id_evento,
        id_parceiro,
        id_usuario_importacao,
        fonte,
        cod_evento_externo,
        origem_tipo,
        tipo_entidade,
        nome_importacao,
        arquivo_nome,
        arquivo_hash,
        arquivo_mime,
        arquivo_tamanho_bytes,
        mapeamento,
        status_processamento,
        data_inicio
    )
    values (
        v_link.crm_evento_versao_id,
        p_id_evento,
        p_id_parceiro,
        p_usuario_importacao,
        nullif(lower(trim(coalesce(p_fonte, ''))), ''),
        nullif(trim(coalesce(p_cod_evento_externo, '')), ''),
        'arquivo',
        'participantes',
        coalesce(nullif(trim(p_nome_importacao), ''), p_arquivo_nome, 'Importacao arquivo CRM'),
        p_arquivo_nome,
        nullif(trim(coalesce(p_arquivo_hash, '')), ''),
        p_arquivo_mime,
        p_arquivo_tamanho_bytes,
        p_mapeamento,
        'recebido',
        current_timestamp
    )
    on conflict (arquivo_hash, coalesce(aba_nome, ''), tipo_entidade)
        where arquivo_hash is not null and arquivo_hash <> ''
    do update
        set id_crm_evento_versao = excluded.id_crm_evento_versao,
            id_evento = excluded.id_evento,
            id_parceiro = excluded.id_parceiro,
            id_usuario_importacao = coalesce(excluded.id_usuario_importacao, crm.tb_crm_importacoes.id_usuario_importacao),
            fonte = excluded.fonte,
            cod_evento_externo = excluded.cod_evento_externo,
            nome_importacao = excluded.nome_importacao,
            arquivo_nome = excluded.arquivo_nome,
            arquivo_mime = excluded.arquivo_mime,
            arquivo_tamanho_bytes = excluded.arquivo_tamanho_bytes,
            mapeamento = excluded.mapeamento,
            status_processamento = 'recebido',
            total_linhas = 0,
            total_validas = 0,
            total_invalidas = 0,
            total_duplicadas = 0,
            erro_processamento = null,
            data_inicio = current_timestamp,
            data_fim = null,
            data_atualizacao = current_timestamp
    returning
        tb_crm_importacoes.id_crm_importacao,
        tb_crm_importacoes.id_crm_evento_versao,
        tb_crm_importacoes.id_evento,
        tb_crm_importacoes.fonte,
        tb_crm_importacoes.cod_evento_externo,
        tb_crm_importacoes.status_processamento;
end;
$$;

drop function if exists crm.crm_processar_importacao_arquivo(bigint);

create or replace function crm_processar_importacao_arquivo(
    p_id_crm_importacao bigint
)
returns table (
    linhas_total integer,
    linhas_validas integer,
    linhas_invalidas integer,
    pessoas_upsert integer,
    participacoes_upsert integer,
    resultados_vinculados integer,
    usuarios_vinculados integer
)
language plpgsql
set search_path = crm, public
as $$
declare
    v_importacao record;
    v_linhas_total integer := 0;
    v_linhas_validas integer := 0;
    v_linhas_invalidas integer := 0;
    v_pessoas_total integer := 0;
    v_row_count integer := 0;
    v_participacoes_total integer := 0;
    v_match record;
begin
    select imp.*
    into v_importacao
    from crm.tb_crm_importacoes imp
    where imp.id_crm_importacao = p_id_crm_importacao;

    if not found then
        raise exception 'Importacao CRM % nao encontrada', p_id_crm_importacao;
    end if;

    update crm.tb_crm_importacao_linhas linha
    set nome_norm = crm_normalize_text(linha.nome_atleta),
        email_norm = lower(nullif(trim(coalesce(linha.email, '')), '')),
        documento_norm = crm_only_digits(linha.documento),
        telefone_norm = crm_only_digits(linha.telefone),
        sexo = crm_normalize_sexo(linha.sexo),
        estado = upper(nullif(trim(coalesce(linha.estado, '')), '')),
        pais = coalesce(nullif(trim(linha.pais), ''), 'BR'),
        percurso = coalesce(linha.percurso, crm_infer_percurso(coalesce(linha.modalidade, linha.categoria))),
        status_validacao = case
            when crm_normalize_text(linha.nome_atleta) is null then 'invalido'
            else 'valido'
        end,
        erros = case
            when crm_normalize_text(linha.nome_atleta) is null
                then jsonb_build_array('nome_obrigatorio')
            else null
        end,
        data_atualizacao = current_timestamp
    where linha.id_crm_importacao = p_id_crm_importacao;

    select
        count(*)::integer,
        count(*) filter (where linha.status_validacao = 'valido')::integer,
        count(*) filter (where linha.status_validacao <> 'valido')::integer
    into v_linhas_total, v_linhas_validas, v_linhas_invalidas
    from crm.tb_crm_importacao_linhas linha
    where linha.id_crm_importacao = p_id_crm_importacao;

    delete from crm.tb_crm_participacoes part
    using crm.tb_crm_importacao_linhas linha
    where part.id_crm_importacao_linha = linha.id_crm_importacao_linha
      and linha.id_crm_importacao = p_id_crm_importacao
      and linha.status_validacao <> 'valido';

    with src as (
        select distinct on (linha.documento_norm)
            linha.*
        from crm.tb_crm_importacao_linhas linha
        where linha.id_crm_importacao = p_id_crm_importacao
          and linha.status_validacao = 'valido'
          and linha.documento_norm is not null
          and linha.documento_norm <> ''
        order by linha.documento_norm, linha.numero_linha
    )
    insert into crm.tb_crm_pessoas (
        nome,
        nome_norm,
        email,
        email_norm,
        documento,
        documento_norm,
        telefone,
        telefone_norm,
        data_nascimento,
        sexo,
        cidade,
        estado,
        pais,
        assessoria,
        origem_primeiro_contato
    )
    select
        src.nome_atleta,
        src.nome_norm,
        src.email,
        src.email_norm,
        src.documento,
        src.documento_norm,
        src.telefone,
        src.telefone_norm,
        src.data_nascimento,
        src.sexo,
        src.cidade,
        src.estado,
        coalesce(src.pais, 'BR'),
        src.assessoria,
        v_importacao.fonte
    from src
    on conflict (documento_norm)
        where documento_norm is not null and documento_norm <> ''
    do update
        set nome = coalesce(excluded.nome, tb_crm_pessoas.nome),
            nome_norm = coalesce(excluded.nome_norm, tb_crm_pessoas.nome_norm),
            email = coalesce(excluded.email, tb_crm_pessoas.email),
            email_norm = coalesce(excluded.email_norm, tb_crm_pessoas.email_norm),
            telefone = coalesce(excluded.telefone, tb_crm_pessoas.telefone),
            telefone_norm = coalesce(excluded.telefone_norm, tb_crm_pessoas.telefone_norm),
            data_nascimento = coalesce(excluded.data_nascimento, tb_crm_pessoas.data_nascimento),
            sexo = coalesce(excluded.sexo, tb_crm_pessoas.sexo),
            cidade = coalesce(excluded.cidade, tb_crm_pessoas.cidade),
            estado = coalesce(excluded.estado, tb_crm_pessoas.estado),
            pais = coalesce(excluded.pais, tb_crm_pessoas.pais),
            assessoria = coalesce(excluded.assessoria, tb_crm_pessoas.assessoria),
            data_atualizacao = current_timestamp;

    get diagnostics v_row_count = row_count;
    v_pessoas_total := v_pessoas_total + v_row_count;

    with src as (
        select distinct on (linha.email_norm, linha.nome_norm, linha.data_nascimento)
            linha.*
        from crm.tb_crm_importacao_linhas linha
        where linha.id_crm_importacao = p_id_crm_importacao
          and linha.status_validacao = 'valido'
          and linha.documento_norm is null
          and linha.email_norm is not null
          and linha.email_norm <> ''
          and linha.nome_norm is not null
          and linha.data_nascimento is not null
        order by linha.email_norm, linha.nome_norm, linha.data_nascimento, linha.numero_linha
    )
    insert into crm.tb_crm_pessoas (
        nome,
        nome_norm,
        email,
        email_norm,
        telefone,
        telefone_norm,
        data_nascimento,
        sexo,
        cidade,
        estado,
        pais,
        assessoria,
        origem_primeiro_contato
    )
    select
        src.nome_atleta,
        src.nome_norm,
        src.email,
        src.email_norm,
        src.telefone,
        src.telefone_norm,
        src.data_nascimento,
        src.sexo,
        src.cidade,
        src.estado,
        coalesce(src.pais, 'BR'),
        src.assessoria,
        v_importacao.fonte
    from src
    on conflict (email_norm, nome_norm, data_nascimento)
        where documento_norm is null
          and email_norm is not null
          and email_norm <> ''
          and data_nascimento is not null
    do update
        set telefone = coalesce(excluded.telefone, tb_crm_pessoas.telefone),
            telefone_norm = coalesce(excluded.telefone_norm, tb_crm_pessoas.telefone_norm),
            sexo = coalesce(excluded.sexo, tb_crm_pessoas.sexo),
            cidade = coalesce(excluded.cidade, tb_crm_pessoas.cidade),
            estado = coalesce(excluded.estado, tb_crm_pessoas.estado),
            pais = coalesce(excluded.pais, tb_crm_pessoas.pais),
            assessoria = coalesce(excluded.assessoria, tb_crm_pessoas.assessoria),
            data_atualizacao = current_timestamp;

    get diagnostics v_row_count = row_count;
    v_pessoas_total := v_pessoas_total + v_row_count;

    with src as (
        select distinct on (linha.email_norm, linha.nome_norm)
            linha.*
        from crm.tb_crm_importacao_linhas linha
        where linha.id_crm_importacao = p_id_crm_importacao
          and linha.status_validacao = 'valido'
          and linha.documento_norm is null
          and linha.data_nascimento is null
          and linha.email_norm is not null
          and linha.email_norm <> ''
          and linha.nome_norm is not null
        order by linha.email_norm, linha.nome_norm, linha.numero_linha
    )
    insert into crm.tb_crm_pessoas (
        nome,
        nome_norm,
        email,
        email_norm,
        telefone,
        telefone_norm,
        sexo,
        cidade,
        estado,
        pais,
        assessoria,
        origem_primeiro_contato
    )
    select
        src.nome_atleta,
        src.nome_norm,
        src.email,
        src.email_norm,
        src.telefone,
        src.telefone_norm,
        src.sexo,
        src.cidade,
        src.estado,
        coalesce(src.pais, 'BR'),
        src.assessoria,
        v_importacao.fonte
    from src
    where not exists (
        select 1
        from crm.tb_crm_pessoas pessoa
        where pessoa.documento_norm is null
          and pessoa.email_norm = src.email_norm
          and pessoa.nome_norm = src.nome_norm
    );

    get diagnostics v_row_count = row_count;
    v_pessoas_total := v_pessoas_total + v_row_count;

    with vinculada as (
        select
            linha.*,
            coalesce(pessoa_doc.id_crm_pessoa, pessoa_email_data.id_crm_pessoa, pessoa_email_nome.id_crm_pessoa) as id_crm_pessoa
        from crm.tb_crm_importacao_linhas linha
        left join crm.tb_crm_pessoas pessoa_doc
            on pessoa_doc.documento_norm = linha.documento_norm
           and linha.documento_norm is not null
           and linha.documento_norm <> ''
        left join crm.tb_crm_pessoas pessoa_email_data
            on pessoa_doc.id_crm_pessoa is null
           and pessoa_email_data.documento_norm is null
           and pessoa_email_data.email_norm = linha.email_norm
           and pessoa_email_data.nome_norm = linha.nome_norm
           and pessoa_email_data.data_nascimento = linha.data_nascimento
           and linha.email_norm is not null
           and linha.data_nascimento is not null
        left join lateral (
            select pessoa_email.id_crm_pessoa
            from crm.tb_crm_pessoas pessoa_email
            where pessoa_doc.id_crm_pessoa is null
              and pessoa_email_data.id_crm_pessoa is null
              and pessoa_email.documento_norm is null
              and pessoa_email.email_norm = linha.email_norm
              and pessoa_email.nome_norm = linha.nome_norm
              and linha.email_norm is not null
            order by pessoa_email.data_atualizacao desc, pessoa_email.id_crm_pessoa desc
            limit 1
        ) pessoa_email_nome on true
        where linha.id_crm_importacao = p_id_crm_importacao
          and linha.status_validacao = 'valido'
    )
    insert into crm.tb_crm_participacoes (
        id_crm_pessoa,
        id_crm_evento_versao,
        id_crm_importacao_linha,
        id_evento,
        id_parceiro,
        fonte,
        cod_evento_externo,
        ano_evento,
        nome_evento_externo,
        data_evento,
        numero_inscricao,
        numero_pedido,
        protocolo,
        numero_peito,
        percurso,
        percurso_label,
        modalidade,
        categoria,
        status_inscricao,
        status_pedido,
        data_pedido,
        data_pagamento,
        origem,
        campanha,
        cupom,
        valor_unitario,
        camiseta,
        assessoria,
        raw,
        lead_score,
        lead_score_componentes
    )
    select
        vinculada.id_crm_pessoa,
        v_importacao.id_crm_evento_versao,
        vinculada.id_crm_importacao_linha,
        v_importacao.id_evento,
        v_importacao.id_parceiro,
        v_importacao.fonte,
        v_importacao.cod_evento_externo,
        extract(year from evt.data_inicial)::integer,
        evt.nome_evento,
        evt.data_inicial,
        coalesce(nullif(vinculada.numero_inscricao, ''), vinculada.id_crm_importacao_linha::varchar),
        nullif(vinculada.numero_pedido, ''),
        nullif(vinculada.protocolo, ''),
        nullif(vinculada.numero_peito, ''),
        vinculada.percurso,
        case when vinculada.percurso is not null then vinculada.percurso::varchar || 'K' end,
        nullif(vinculada.modalidade, ''),
        nullif(vinculada.categoria, ''),
        coalesce(nullif(vinculada.status_inscricao, ''), 'importado'),
        coalesce(nullif(vinculada.status_inscricao, ''), 'importado'),
        vinculada.data_pedido,
        vinculada.data_pagamento,
        nullif(vinculada.origem, ''),
        nullif(vinculada.campanha, ''),
        nullif(vinculada.cupom, ''),
        vinculada.valor,
        nullif(vinculada.camiseta, ''),
        nullif(vinculada.assessoria, ''),
        vinculada.raw,
        (
            25
            + case when vinculada.documento_norm is not null then 15 else 0 end
            + case when vinculada.email_norm is not null then 10 else 0 end
            + case when vinculada.percurso >= 21 then 10 when vinculada.percurso is not null then 5 else 0 end
        )::numeric,
        jsonb_build_object(
            'importado_arquivo', 25,
            'documento', case when vinculada.documento_norm is not null then 15 else 0 end,
            'email', case when vinculada.email_norm is not null then 10 else 0 end,
            'percurso', case when vinculada.percurso >= 21 then 10 when vinculada.percurso is not null then 5 else 0 end
        )
    from vinculada
    left join public.tb_evento_corridas evt
        on evt.id_evento = v_importacao.id_evento
    where vinculada.id_crm_pessoa is not null
    on conflict (id_crm_importacao_linha)
        where id_crm_importacao_linha is not null
    do update
        set id_crm_pessoa = excluded.id_crm_pessoa,
            id_crm_evento_versao = excluded.id_crm_evento_versao,
            id_evento = excluded.id_evento,
            id_parceiro = excluded.id_parceiro,
            fonte = excluded.fonte,
            cod_evento_externo = excluded.cod_evento_externo,
            ano_evento = excluded.ano_evento,
            nome_evento_externo = excluded.nome_evento_externo,
            data_evento = excluded.data_evento,
            numero_inscricao = excluded.numero_inscricao,
            numero_pedido = excluded.numero_pedido,
            protocolo = excluded.protocolo,
            numero_peito = excluded.numero_peito,
            percurso = excluded.percurso,
            percurso_label = excluded.percurso_label,
            modalidade = excluded.modalidade,
            categoria = excluded.categoria,
            status_inscricao = excluded.status_inscricao,
            status_pedido = excluded.status_pedido,
            data_pedido = excluded.data_pedido,
            data_pagamento = excluded.data_pagamento,
            origem = excluded.origem,
            campanha = excluded.campanha,
            cupom = excluded.cupom,
            valor_unitario = excluded.valor_unitario,
            camiseta = excluded.camiseta,
            assessoria = excluded.assessoria,
            raw = excluded.raw,
            lead_score = excluded.lead_score,
            lead_score_componentes = excluded.lead_score_componentes,
            data_atualizacao = current_timestamp;

    get diagnostics v_participacoes_total = row_count;

    update crm.tb_crm_importacoes imp
    set status_processamento = case when v_linhas_invalidas > 0 then 'processado_com_erros' else 'processado' end,
        total_linhas = v_linhas_total,
        total_validas = v_linhas_validas,
        total_invalidas = v_linhas_invalidas,
        data_fim = current_timestamp,
        data_atualizacao = current_timestamp
    where imp.id_crm_importacao = p_id_crm_importacao;

    select *
    into v_match
    from crm.crm_match_resultados(null, v_importacao.id_evento)
    limit 1;

    perform 1
    from crm.crm_match_usuarios(null)
    limit 1;

    return query
    select
        v_linhas_total,
        v_linhas_validas,
        v_linhas_invalidas,
        v_pessoas_total,
        v_participacoes_total,
        coalesce(v_match.participacoes_vinculadas, 0)::integer,
        coalesce(v_match.pessoas_vinculadas, 0)::integer;
end;
$$;

drop function if exists crm.crm_link_ticketsports_conta(integer, bigint, bigint);

create or replace function crm_link_ticketsports_conta(
    p_cod_evento integer,
    p_id_conta bigint,
    p_usuario_cadastro bigint default null
)
returns table (
    conta_id bigint,
    conta_nome varchar,
    crm_evento_versao_id integer,
    evento_codigo_externo varchar,
    evento_nome_externo varchar,
    vinculo_status varchar
)
language plpgsql
set search_path = crm, public
as $$
begin
    if p_cod_evento is null then
        raise exception 'p_cod_evento e obrigatorio';
    end if;

    if not exists (
        select 1
        from public.tb_contas cont
        where cont.id_conta = p_id_conta
    ) then
        raise exception 'Conta % nao encontrada', p_id_conta;
    end if;

    perform 1
    from crm.crm_sync_ticketsports(p_cod_evento)
    limit 1;

    insert into crm.tb_crm_conta_evento_versoes (
        id_conta,
        id_crm_evento_versao,
        status,
        usuario_cadastro,
        origem
    )
    select
        p_id_conta,
        vers.id_crm_evento_versao,
        'ATIVO'::public.status_conta_evento,
        p_usuario_cadastro,
        'manual'
    from crm.tb_crm_evento_versoes vers
    where vers.fonte = 'ticketsports'
      and vers.cod_evento_externo = p_cod_evento::varchar
    on conflict (id_conta, id_crm_evento_versao) do update
        set status = 'ATIVO'::public.status_conta_evento,
            usuario_cadastro = coalesce(excluded.usuario_cadastro, crm.tb_crm_conta_evento_versoes.usuario_cadastro),
            origem = excluded.origem,
            data_atualizacao = now();

    return query
    select
        cont.id_conta,
        cont.nome_conta,
        vers.id_crm_evento_versao,
        vers.cod_evento_externo,
        vers.nome_evento_externo,
        link.status::varchar
    from crm.tb_crm_conta_evento_versoes link
    inner join public.tb_contas cont
        on cont.id_conta = link.id_conta
    inner join crm.tb_crm_evento_versoes vers
        on vers.id_crm_evento_versao = link.id_crm_evento_versao
    where link.id_conta = p_id_conta
      and vers.fonte = 'ticketsports'
      and vers.cod_evento_externo = p_cod_evento::varchar;
end;
$$;

create or replace function tb_crm_set_data_atualizacao()
returns trigger
language plpgsql
set search_path = crm, public
as $$
begin
    new.data_atualizacao := current_timestamp;
    return new;
end;
$$;

drop trigger if exists trg_tb_crm_evento_series_atualizacao on tb_crm_evento_series;
create trigger trg_tb_crm_evento_series_atualizacao
    before update on tb_crm_evento_series
    for each row
    execute function tb_crm_set_data_atualizacao();

drop trigger if exists trg_tb_crm_evento_versoes_atualizacao on tb_crm_evento_versoes;
create trigger trg_tb_crm_evento_versoes_atualizacao
    before update on tb_crm_evento_versoes
    for each row
    execute function tb_crm_set_data_atualizacao();

drop trigger if exists trg_tb_crm_conta_evento_versoes_atualizacao on tb_crm_conta_evento_versoes;
create trigger trg_tb_crm_conta_evento_versoes_atualizacao
    before update on tb_crm_conta_evento_versoes
    for each row
    execute function tb_crm_set_data_atualizacao();

drop trigger if exists trg_tb_crm_importacoes_atualizacao on tb_crm_importacoes;
create trigger trg_tb_crm_importacoes_atualizacao
    before update on tb_crm_importacoes
    for each row
    execute function tb_crm_set_data_atualizacao();

drop trigger if exists trg_tb_crm_importacao_linhas_atualizacao on tb_crm_importacao_linhas;
create trigger trg_tb_crm_importacao_linhas_atualizacao
    before update on tb_crm_importacao_linhas
    for each row
    execute function tb_crm_set_data_atualizacao();

drop trigger if exists trg_tb_crm_pessoas_atualizacao on tb_crm_pessoas;
create trigger trg_tb_crm_pessoas_atualizacao
    before update on tb_crm_pessoas
    for each row
    execute function tb_crm_set_data_atualizacao();

drop trigger if exists trg_tb_crm_pedidos_atualizacao on tb_crm_pedidos;
create trigger trg_tb_crm_pedidos_atualizacao
    before update on tb_crm_pedidos
    for each row
    execute function tb_crm_set_data_atualizacao();

drop trigger if exists trg_tb_crm_participacoes_atualizacao on tb_crm_participacoes;
create trigger trg_tb_crm_participacoes_atualizacao
    before update on tb_crm_participacoes
    for each row
    execute function tb_crm_set_data_atualizacao();

comment on table tb_crm_evento_series is
    'Agrupa versoes anuais do mesmo evento para CRM e lead scoring.';

comment on table tb_crm_evento_versoes is
    'Mapeia uma versao anual do evento em uma fonte externa/API para um evento Road Runners.';

comment on table tb_crm_conta_evento_versoes is
    'Vincula uma versao de evento importada no CRM a uma conta Business para controle de acesso.';

comment on table tb_crm_importacoes is
    'Cabecalho auditavel de importacoes vindas de arquivo, API ou insercao manual.';

comment on table tb_crm_importacao_linhas is
    'Linhas brutas e normalizadas de cada importacao, preservando payload original.';

comment on table tb_crm_pessoas is
    'Pessoa/lead canonico deduplicado a partir das fontes de inscricao.';

comment on table tb_crm_pedidos is
    'Pedido transacional importado de APIs ou arquivos de plataformas de inscricao.';

comment on table tb_crm_participacoes is
    'Inscricao/participacao canonica de uma pessoa em uma versao de evento.';

comment on table tb_crm_participacao_respostas is
    'Respostas normalizadas de questionarios de inscricao.';

comment on table tb_crm_participacao_produtos is
    'Produtos e adicionais associados a uma participacao.';

comment on function crm_sync_ticketsports(integer, varchar, varchar) is
    'Materializa tb_ticketsports_pedidos e tb_ticketsports_participantes nas tabelas canonicas do CRM.';

comment on function crm_match_usuarios(bigint) is
    'Vincula pessoas CRM a usuarios Road Runners com matching conservador por email, nome e data de nascimento.';

comment on function crm_match_resultados(bigint, integer) is
    'Vincula participacoes CRM a resultados Road Runners e usa resultado reconhecido para preencher id_usuario.';

comment on function crm_link_fonte_evento(varchar, integer, varchar, integer, bigint, varchar, jsonb) is
    'Vincula qualquer fonte externa de inscricoes a um evento Road Runners canonico.';

comment on function crm_link_ticketsports_evento(integer, integer, bigint) is
    'Vincula um cod_evento TicketSports a um id_evento Road Runners e processa resultados reconhecidos.';

comment on function crm_criar_importacao_arquivo(integer, varchar, varchar, varchar, varchar, integer, varchar, integer, varchar, bigint, jsonb) is
    'Cria cabecalho de importacao de arquivo ja vinculado a fonte e evento Road Runners.';

comment on function crm_processar_importacao_arquivo(bigint) is
    'Processa linhas normalizadas de uma importacao de arquivo para pessoas e participacoes CRM.';

comment on function crm_link_ticketsports_conta(integer, bigint, bigint) is
    'Sincroniza um cod_evento TicketSports e vincula sua versao CRM a uma conta Business.';

grant insert, select, update on tb_crm_evento_series to runner;
grant insert, select, update on tb_crm_evento_versoes to runner;
grant insert, select, update on tb_crm_conta_evento_versoes to runner;
grant insert, select, update on tb_crm_importacoes to runner;
grant insert, select, update on tb_crm_importacao_linhas to runner;
grant insert, select, update on tb_crm_pessoas to runner;
grant insert, select, update on tb_crm_pedidos to runner;
grant insert, select, update on tb_crm_participacoes to runner;
grant insert, select, update on tb_crm_participacao_respostas to runner;
grant insert, select, update on tb_crm_participacao_produtos to runner;
grant select on vw_crm_participacoes to runner;
grant select on vw_crm_leads to runner;
grant execute on function crm_match_usuarios(bigint) to runner;
grant execute on function crm_match_resultados(bigint, integer) to runner;
grant execute on function crm_normalize_sexo(text) to runner;
grant execute on function crm_link_fonte_evento(varchar, integer, varchar, integer, bigint, varchar, jsonb) to runner;
grant execute on function crm_sync_ticketsports(integer, varchar, varchar) to runner;
grant execute on function crm_link_ticketsports_evento(integer, integer, bigint) to runner;
grant execute on function crm_criar_importacao_arquivo(integer, varchar, varchar, varchar, varchar, integer, varchar, integer, varchar, bigint, jsonb) to runner;
grant execute on function crm_processar_importacao_arquivo(bigint) to runner;
grant execute on function crm_link_ticketsports_conta(integer, bigint, bigint) to runner;

grant select, usage on sequence tb_crm_evento_series_id_crm_evento_serie_seq to runner;
grant select, usage on sequence tb_crm_evento_versoes_id_crm_evento_versao_seq to runner;
grant select, usage on sequence tb_crm_conta_evento_versoes_id_crm_conta_evento_versao_seq to runner;
grant select, usage on sequence tb_crm_importacoes_id_crm_importacao_seq to runner;
grant select, usage on sequence tb_crm_importacao_linhas_id_crm_importacao_linha_seq to runner;
grant select, usage on sequence tb_crm_pessoas_id_crm_pessoa_seq to runner;
grant select, usage on sequence tb_crm_pedidos_id_crm_pedido_seq to runner;
grant select, usage on sequence tb_crm_participacoes_id_crm_participacao_seq to runner;
grant select, usage on sequence tb_crm_participacao_respostas_id_crm_participacao_resposta_seq to runner;
grant select, usage on sequence tb_crm_participacao_produtos_id_crm_participacao_produto_seq to runner;
