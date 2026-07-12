create schema if not exists ads authorization runner_dba;

grant usage on schema ads to runner;

create sequence tb_bagdes_id_badge_seq
    as integer;

alter sequence tb_bagdes_id_badge_seq owner to runner_dba;

grant select, usage on sequence tb_bagdes_id_badge_seq to runner;

create sequence tb_categorias_id_categoria_seq;

alter sequence tb_categorias_id_categoria_seq owner to runner_dba;

grant select, update, usage on sequence tb_categorias_id_categoria_seq to runner;

create sequence tb_conteudo_id_conteudo_seq;

alter sequence tb_conteudo_id_conteudo_seq owner to runner_dba;

grant select, update, usage on sequence tb_conteudo_id_conteudo_seq to runner;

create sequence tb_log_id_log_seq;

alter sequence tb_log_id_log_seq owner to runner_dba;

grant select, update, usage on sequence tb_log_id_log_seq to runner;

create sequence tb_resultados_nova_id_resultado_seq
    as integer;

alter sequence tb_resultados_nova_id_resultado_seq owner to runner_dba;

grant select, update, usage on sequence tb_resultados_nova_id_resultado_seq to runner;

create sequence usuarios_id_seq
    as integer;

alter sequence usuarios_id_seq owner to runner_dba;

grant select, update, usage on sequence usuarios_id_seq to runner;

create sequence tb_carga_crono_num_inscricao_seq
    as integer;

alter sequence tb_carga_crono_num_inscricao_seq owner to runner_dba;

grant select, usage on sequence tb_carga_crono_num_inscricao_seq to runner;

create sequence ads.tb_evento_ads_id_evento_ad_seq
    as integer;

alter sequence ads.tb_evento_ads_id_evento_ad_seq owner to runner_dba;

grant select, usage on sequence ads.tb_evento_ads_id_evento_ad_seq to runner;

-- Unknown how to generate base type type

alter type gtrgm owner to runner_dba;

create type tipo_titular_conta as enum ('PF', 'PJ');

alter type tipo_titular_conta owner to runner_dba;

create type status_conta as enum ('ATIVA', 'SUSPENSA', 'CANCELADA', 'PENDENTE');

alter type status_conta owner to runner_dba;

create type status_usuario_conta as enum ('ATIVO', 'INATIVO', 'CONVIDADO', 'BLOQUEADO');

alter type status_usuario_conta owner to runner_dba;

create type papel_usuario_conta as enum ('OWNER', 'ADMIN', 'OPERADOR', 'VISUALIZADOR');

alter type papel_usuario_conta owner to runner_dba;

create type status_conta_evento as enum ('ATIVO', 'INATIVO', 'PENDENTE');

alter type status_conta_evento owner to runner_dba;

create type status_conta_cadastro_solicitacao as enum ('PENDENTE', 'APROVADA', 'RECUSADA', 'CANCELADA');

alter type status_conta_cadastro_solicitacao owner to runner_dba;

create table desafio_leads
(
    num_inscricao   integer not null
        constraint desafio_leads_pk
            primary key,
    nome            varchar,
    data_nascimento date,
    email           varchar,
    documento       varchar,
    genero          varchar,
    telefone        varchar,
    celular         varchar,
    endereco        varchar,
    numero          varchar,
    complemento     varchar,
    bairro          varchar,
    cidade          varchar,
    uf              varchar,
    cep             varchar,
    pais            varchar,
    num_pedido      integer,
    id_usuario      integer
);

alter table desafio_leads
    owner to runner_dba;

create index desafio_leads_email_index
    on desafio_leads (email);

create unique index desafio_leads_id_usuario_uindex
    on desafio_leads (id_usuario);

create index desafio_leads_nome_index
    on desafio_leads (nome);

grant insert, select, update on desafio_leads to runner;

create table tb_agrega_eventos
(
    id_agrega_evento     serial
        constraint tb_agrega_eventos_pk
            primary key,
    nome_evento_agregado varchar(256)                                   not null,
    tipo_agregacao       varchar(24)                                    not null,
    tag                  varchar,
    id_tema              integer default 1                              not null,
    divisao              varchar default 'distancia'::character varying not null,
    ordem                integer default 300                            not null
);

alter table tb_agrega_eventos
    owner to runner_dba;

grant select, usage on sequence tb_agrega_eventos_id_agrega_evento_seq to runner;

create unique index tb_agrega_eventos_id_agrega_evento_uindex
    on tb_agrega_eventos (id_agrega_evento);

grant insert, select, update on tb_agrega_eventos to runner;

create table tb_agregadores
(
    id_agregador        serial
        constraint tb_agregadores_pk
            primary key,
    agregador_nome      varchar(128)                                 not null,
    agregador_tag       varchar(128)                                 not null,
    agregador_descricao text,
    id_agregador_pai    integer
        constraint tb_agregadores_tb_agregadores_id_agregador_fk
            references tb_agregadores
            on update set null on delete set null,
    id_tema             integer default 0                            not null,
    agregador_tipo      varchar default 'eventos'::character varying not null,
    ordem               integer default 200                          not null
);

alter table tb_agregadores
    owner to runner_dba;

grant select, usage on sequence tb_agregadores_id_agregador_seq to runner;

create unique index tb_agregadores_agregador_tag_uindex
    on tb_agregadores (agregador_tag);

grant insert, select, update on tb_agregadores to runner;

create table tb_atletas_estrangeiros
(
    id_atleta     serial,
    nome_atleta   varchar,
    nacionalidade varchar,
    data_inicio   date,
    data_fim      date
);

alter table tb_atletas_estrangeiros
    owner to postgres;

grant select, usage on sequence tb_atletas_estrangeiros_id_atleta_seq to runner;

grant insert, select, update on tb_atletas_estrangeiros to runner;

create table tb_badges_tipos
(
    badge           varchar(48)                                   not null
        constraint tb_badges_tipos_pk
            primary key,
    image_path      varchar,
    badge_descricao varchar,
    ordem           integer default 100                           not null,
    ativo           boolean default true                          not null,
    site            varchar default 'RR'::character varying       not null,
    tipo_badge      varchar default 'percurso'::character varying not null,
    min_km          integer default 0                             not null,
    badge_tooltip   varchar
);

alter table tb_badges_tipos
    owner to runner_dba;

grant insert, select, update on tb_badges_tipos to runner;

create table tb_bi
(
    id_bi        serial
        constraint tb_bi_pk
            primary key,
    bi_nome      varchar(128)        not null,
    bi_tag       varchar(128)        not null,
    bi_descricao text,
    id_tema      integer default 0   not null,
    ordem        integer default 100 not null
);

alter table tb_bi
    owner to runner_dba;

grant select, usage on sequence tb_bi_id_bi_seq to runner;

create unique index tb_bi_bi_tag_uindex
    on tb_bi (bi_tag);

grant insert, select, update on tb_bi to runner;

create table tb_categoria
(
    tag_categoria varchar not null
        primary key,
    categoria     varchar not null
        unique
);

alter table tb_categoria
    owner to runner_dba;

grant insert, select, update on tb_categoria to runner;

create table tb_categoria_corridas
(
    id_categoria   integer default nextval('tb_categorias_id_categoria_seq'::regclass) not null
        constraint tb_categorias_pkey
            primary key,
    nome_categoria varchar
);

alter table tb_categoria_corridas
    owner to runner_dba;

alter sequence tb_categorias_id_categoria_seq owned by tb_categoria_corridas.id_categoria;

grant insert, select, update on tb_categoria_corridas to runner;

create table tb_cidades
(
    cod_uf        integer    not null,
    uf            varchar(2) not null,
    nome_uf       varchar,
    cod_cidade    integer    not null
        constraint tb_cidades_pk
            primary key,
    nome_cidade   varchar    not null,
    tag_cidade    varchar    not null,
    id_localidade integer
);

alter table tb_cidades
    owner to runner_dba;

create unique index tb_cidades_cod_cidade_uindex
    on tb_cidades (cod_cidade);

create index tb_cidades_nome_cidade_index
    on tb_cidades (nome_cidade);

grant insert, select, update on tb_cidades to runner;

create table tb_clima_estacoes
(
    id_clima_estacao serial
        constraint tb_clima_estacoes_pk
            primary key,
    cod_cidade       integer,
    cidade           varchar,
    estado           varchar,
    latitude         varchar,
    longitude        varchar,
    altitude         varchar,
    cod_estacao      varchar
);

alter table tb_clima_estacoes
    owner to runner_dba;

grant select, usage on sequence tb_clima_estacoes_id_clima_estacao_seq to runner;

create unique index tb_clima_estacoes_id_clima_estacao_uindex
    on tb_clima_estacoes (id_clima_estacao);

grant insert, select, update on tb_clima_estacoes to runner;

create table tb_clima_historico
(
    data_tempo         date    not null,
    hora_tempo         time    not null,
    precipitacao_total numeric not null,
    radiacao           numeric,
    temperatura        numeric not null,
    umidade            numeric not null,
    vento_velocidade   numeric not null,
    cod_estacao        varchar
);

alter table tb_clima_historico
    owner to runner_dba;

grant insert, select, update on tb_clima_historico to runner;

create table tb_clima_temp
(
    campo_1  varchar,
    campo_2  varchar,
    campo_3  varchar,
    campo_4  varchar,
    campo_5  varchar,
    campo_6  varchar,
    campo_7  varchar,
    campo_8  varchar,
    campo_9  varchar,
    campo_10 varchar,
    campo_11 varchar,
    campo_12 varchar,
    campo_13 varchar,
    campo_14 varchar,
    campo_15 varchar,
    campo_16 varchar,
    campo_17 varchar,
    campo_18 varchar,
    campo_19 varchar
);

alter table tb_clima_temp
    owner to runner_dba;

grant insert, select, update on tb_clima_temp to runner;

create table tb_conteudo
(
    id_conteudo     integer   default nextval('tb_conteudo_id_conteudo_seq'::regclass) not null
        primary key,
    titulo          varchar,
    resumo          varchar,
    link            varchar,
    imagem          varchar,
    conteudo        text,
    data_publicacao timestamp default now()                                            not null
);

alter table tb_conteudo
    owner to runner_dba;

alter sequence tb_conteudo_id_conteudo_seq owned by tb_conteudo.id_conteudo;

grant delete, insert, select, update on tb_conteudo to runner;

create table tb_convite
(
    id_convite   serial,
    chave_acesso varchar not null,
    id_usuario   integer,
    data_aceite  timestamp,
    id_remetente integer,
    tipo_convite varchar
);

alter table tb_convite
    owner to postgres;

grant select, usage on sequence tb_convite_id_convite_seq to runner;

create unique index tb_convite_chave_acesso_id_usuario_uindex
    on tb_convite (chave_acesso, id_usuario);

grant insert, select, update on tb_convite to runner;

create table tb_crm
(
    id_interacao           serial,
    id_usuario             integer                                            not null,
    status                 varchar   default 'atendimento'::character varying not null,
    descricao              varchar,
    id_usuario_atendimento integer   default 0                                not null,
    data_interacao         timestamp default now()                            not null
);

alter table tb_crm
    owner to runner_dba;

grant select, usage on sequence tb_crm_id_interacao_seq to runner;

grant insert, select, update on tb_crm to runner;

create table tb_cupom
(
    id_cupom       serial
        constraint tb_cupom_pk
            primary key,
    cupom          varchar(32),
    descricao      varchar(256),
    parceiro       varchar(256),
    condicoes      varchar(256),
    data_cadastro  date    default now() not null,
    data_expiracao date,
    url            varchar,
    ativo          boolean default true  not null
);

alter table tb_cupom
    owner to runner_dba;

grant select, usage on sequence tb_cupom_id_cupom_seq to runner;

grant insert, select, update on tb_cupom to runner;

create table tb_estatistica_corridas
(
    id_estatistica_corrida      uuid         not null
        constraint tb_estatistica_corridas_pk
            primary key,
    chave_referencia            varchar(128) not null,
    bruto_tempo_minimo          time,
    bruto_tempo_medio           time,
    bruto_tempo_mediana         time,
    bruto_pace_minimo           time,
    bruto_pace_medio            time,
    bruto_pace_mediana          time,
    bruto_tempo_minimo_top_10   time,
    bruto_tempo_medio_top_10    time,
    bruto_tempo_mediana_top_10  time,
    bruto_pace_minimo_top_10    time,
    bruto_pace_medio_top_10     time,
    bruto_pace_mediana_top_10   time,
    bruto_tempo_minimo_top_100  time,
    bruto_tempo_medio_top_100   time,
    bruto_tempo_mediana_top_100 time,
    bruto_pace_minimo_top_100   time,
    bruto_pace_medio_top_100    time,
    bruto_pace_mediana_top_100  time,
    total_tempo_minimo          time,
    total_tempo_medio           time,
    total_tempo_mediana         time,
    total_pace_minimo           time,
    total_pace_medio            time,
    total_pace_mediana          time,
    total_tempo_minimo_top_10   time,
    total_tempo_medio_top_10    time,
    total_tempo_mediana_top_10  time,
    total_pace_minimo_top_10    time,
    total_pace_medio_top_10     time,
    total_pace_mediana_top_10   time,
    total_tempo_minimo_top_100  time,
    total_tempo_medio_top_100   time,
    total_tempo_mediana_top_100 time,
    total_pace_minimo_top_100   time,
    total_pace_medio_top_100    time,
    total_pace_mediana_top_100  time
);

alter table tb_estatistica_corridas
    owner to runner_dba;

create unique index tb_estatistica_corridas_id_estatistica_corrida_uindex
    on tb_estatistica_corridas (id_estatistica_corrida);

grant insert, select, update on tb_estatistica_corridas to runner;

create table tb_evento_circuitos_cupom
(
    id_evento_cupom      serial,
    id_cupom             integer not null
        constraint tb_evento_circuitos_cupom_tb_cupom_id_cupom_fk
            references tb_cupom,
    id_agrega_evento     integer not null
        constraint tb_evento_circuitos_cupom_tb_evento_corridas_id_agrega_fk
            references tb_agrega_eventos,
    qtd_limite_cupom     integer,
    data_cadastro        date,
    data_validade_inicio date,
    data_validade_fim    date
);

alter table tb_evento_circuitos_cupom
    owner to runner_dba;

grant select, usage on sequence tb_evento_circuitos_cupom_id_evento_cupom_seq to runner;

grant delete, insert, select, update on tb_evento_circuitos_cupom to runner;

create table tb_evento_corridas
(
    id_evento             serial
        constraint tb_evento_corridas_pk
            primary key,
    nome_evento           varchar                                     not null,
    cidade                varchar,
    estado                varchar(2),
    tag                   varchar(256),
    homologado            boolean,
    url_resultado         varchar,
    url_wiclax            varchar,
    cod_cidade            integer,
    id_agrega_evento      integer,
    pais                  varchar(2) default 'BR'::character varying  not null,
    data_inicial          date                                        not null,
    data_final            date                                        not null,
    descricao             text,
    endereco              varchar,
    coordenadas           varchar,
    imagem                varchar,
    destaque              varchar,
    categorias            varchar,
    url_inscricao         varchar,
    info_duplicado        varchar,
    nome_simplificado     varchar,
    organizador           varchar,
    obs                   varchar,
    tipo_corrida          varchar    default 'rua'::character varying not null,
    ranking               varchar,
    id_tema               integer    default 1                        not null,
    data_processamento    timestamp,
    resumo                varchar(150),
    tag_301               varchar(256),
    ativo                 boolean    default true                     not null,
    data_inclusao         timestamp  default now()                    not null,
    nome_evento_full_text tsvector,
    obs_resultado         varchar,
    status_evento         varchar,
    resultado_completo    boolean    default true                     not null,
    url_hotsite           varchar,
    url_imagem            varchar,
    id_fornecedor         integer,
    url_imagem_listagem   varchar,
    descricao_original    text,
    obs_homologacao       varchar,
    cronometragem         varchar,
    realizacao            varchar,
    cobertura             varchar,
    url_regulamento       varchar
);

alter table tb_evento_corridas
    owner to runner_dba;

grant select, usage on sequence tb_evento_corridas_id_evento_seq to runner;

create table tb_agregadores_eventos
(
    agregador_tag varchar(120) not null
        constraint tb_agregadores_eventos_tb_agregadores_agregador_tag_fk
            references tb_agregadores (agregador_tag)
            on update restrict on delete restrict,
    id_evento     integer      not null
        constraint tb_agregadores_eventos_tb_evento_corridas_id_evento_fk
            references tb_evento_corridas
            on update restrict on delete restrict,
    percursos     varchar
);

alter table tb_agregadores_eventos
    owner to runner_dba;

grant insert, select, update on tb_agregadores_eventos to runner;

create table tb_badges
(
    id_badge          integer default nextval('tb_bagdes_id_badge_seq'::regclass) not null
        constraint tb_badges_pk
            primary key,
    id_evento         integer                                                     not null
        constraint tb_badges_tb_evento_corridas_id_evento_fk
            references tb_evento_corridas
            on update cascade on delete cascade,
    percurso          numeric default 0                                           not null,
    badge             varchar(48)                                                 not null
        constraint tb_badges_tb_badges_tipos_badge_fk
            references tb_badges_tipos
            on update restrict on delete restrict,
    valor_badge       varchar,
    complemento_badge varchar,
    flag_badge        boolean default true,
    badge_raw         jsonb
);

alter table tb_badges
    owner to runner_dba;

alter sequence tb_bagdes_id_badge_seq owned by tb_badges.id_badge;

create unique index tb_badges_id_evento_percurso_badge_uindex
    on tb_badges (id_evento, percurso, badge);

grant insert, select, update on tb_badges to runner;

create index tb_evento_corridas_nome_evento_full_text_idx
    on tb_evento_corridas using gin (nome_evento_full_text);

create index tb_evento_corridas_nome_evento_index
    on tb_evento_corridas (nome_evento);

create unique index tb_evento_corridas_tag_uindex
    on tb_evento_corridas (tag);

grant insert, select, update on tb_evento_corridas to runner;

grant select on tb_evento_corridas to liverunners_dba;

create table tb_evento_corridas_cupom
(
    id_evento_cupom      serial,
    id_cupom             integer not null
        constraint tb_evento_corridas_cupom_tb_cupom_id_cupom_fk
            references tb_cupom,
    id_evento            integer not null
        constraint tb_evento_corridas_cupom_tb_evento_corridas_id_evento_fk
            references tb_evento_corridas,
    qtd_limite_cupom     integer,
    data_cadastro        date,
    data_validade_inicio date,
    data_validade_fim    date
);

alter table tb_evento_corridas_cupom
    owner to runner_dba;

grant select, usage on sequence tb_evento_corridas_cupom_id_evento_cupom_seq to runner;

grant delete, insert, select, update on tb_evento_corridas_cupom to runner;

create table tb_evento_corridas_fornecedores
(
    id_evento          integer not null
        constraint tb_evento_corridas_fornecedores_tb_evento_corridas_id_evento_fk
            references tb_evento_corridas
            on update restrict on delete restrict,
    id_fornecedor_tipo integer not null,
    id_fornecedor      integer not null,
    link_website       varchar
);

alter table tb_evento_corridas_fornecedores
    owner to runner_dba;

create unique index tb_evento_corridas_fornecedores_id_evento_id_fornecedor_tipo_id
    on tb_evento_corridas_fornecedores (id_evento, id_fornecedor_tipo, id_fornecedor);

grant insert, select, update on tb_evento_corridas_fornecedores to runner;

create table tb_evento_corridas_importacao
(
    id_evento         serial
        constraint tb_evento_corridas_importacao_pk
            primary key,
    cod_evento        varchar
        unique,
    nome_evento       varchar                                    not null,
    cidade            varchar,
    data_inicial      varchar,
    estado            varchar,
    tag               varchar(256),
    data_final        varchar,
    descricao         text,
    endereco          varchar,
    coordenadas       varchar,
    categorias        varchar,
    url_inscricao     varchar,
    pais              varchar   default 'BR'::character varying,
    url_resultado     varchar,
    id_evento_match   integer,
    nome_simplificado varchar,
    organizador       varchar,
    obs               varchar,
    tipo_corrida      varchar   default 'rua'::character varying not null,
    id_usuario        integer   default 0                        not null,
    data_inclusao     timestamp default now()                    not null
);

alter table tb_evento_corridas_importacao
    owner to runner_dba;

grant select, update, usage on sequence tb_evento_corridas_importacao_id_evento_seq to runner;

grant insert, select, update on tb_evento_corridas_importacao to runner;

create table tb_evento_corridas_relaciona
(
    id_evento_corrida_relaciona serial
        constraint tb_evento_corridas_relaciona_pk
            primary key,
    id_evento                   integer                 not null
        constraint tb_evento_corridas_relaciona_tb_evento_corridas_id_evento_fk
            references tb_evento_corridas
            on update cascade on delete cascade,
    id_parceiro                 integer,
    id_evento_parceiro          integer                 not null,
    ativo                       boolean   default true  not null,
    data_cadastro               timestamp default now() not null,
    nome_variavel               varchar(64),
    percurso                    integer
);

alter table tb_evento_corridas_relaciona
    owner to runner_dba;

grant select, usage on sequence tb_evento_corridas_relaciona_id_evento_corrida_relaciona_seq to runner;

create unique index tb_evento_corridas_relaciona_id_evento_corrida_relaciona_uindex
    on tb_evento_corridas_relaciona (id_evento_corrida_relaciona);

create unique index tb_evento_corridas_relaciona_id_evento_id_parceiro_id_evento_pa
    on tb_evento_corridas_relaciona (id_evento, id_parceiro, id_evento_parceiro, percurso);

grant insert, select, update on tb_evento_corridas_relaciona to runner;

create table tb_fornecedores
(
    id_fornecedor     serial
        constraint tb_fornecedores_pk
            primary key,
    nome_fornecedor   varchar(128)                                   not null,
    tipo_pessoa       char                                           not null,
    cnpj_cpf          varchar(14),
    ativo             boolean     default true                       not null,
    data_cadastro     timestamp   default now()                      not null,
    usuario_cadastro  varchar(64) default 'admin'::character varying not null,
    data_alteracao    timestamp,
    usuario_alteracao varchar(64),
    tag_fornecedor    varchar,
    imagem_fornecedor varchar,
    site_fornecedor   varchar,
    resumo_fornecedor varchar,
    id_tema           integer     default 1                          not null,
    cidade            varchar,
    estado            varchar(2),
    tag_tipo          varchar,
    status            integer     default 1                          not null
);

alter table tb_fornecedores
    owner to runner_dba;

grant select, update, usage on sequence tb_fornecedores_id_fornecedor_seq to runner;

create unique index tb_fornecedores_id_fornecedor_uindex
    on tb_fornecedores (id_fornecedor);

grant insert, select, update on tb_fornecedores to runner;

grant select on tb_fornecedores to liverunners_dba;

create table tb_fornecedores_tipos
(
    id_fornecedor_tipo serial
        constraint tb_fornecedores_tipos_pk
            primary key,
    descricao_tipo     varchar(256) not null,
    tag_tipo           varchar
);

alter table tb_fornecedores_tipos
    owner to runner_dba;

grant select, usage on sequence tb_fornecedores_tipos_id_fornecedor_tipo_seq to runner;

create unique index tb_fornecedores_tipos_id_fornecedor_tipo_uindex
    on tb_fornecedores_tipos (id_fornecedor_tipo);

create unique index tb_fornecedores_tipos_tag_tipo_uindex
    on tb_fornecedores_tipos (tag_tipo);

grant insert, select, update on tb_fornecedores_tipos to runner;

create table tb_leads
(
    id_lead       serial
        constraint tb_leads_pk
            primary key,
    nome          varchar,
    email         varchar                 not null,
    telefone      varchar,
    data_inclusao timestamp default now() not null,
    body          varchar,
    empresa       varchar
);

alter table tb_leads
    owner to runner_dba;

grant select, update, usage on sequence tb_leads_id_lead_seq to runner;

grant insert, select, update on tb_leads to runner;

create table tb_log
(
    id_log         integer   default nextval('tb_log_id_log_seq'::regclass) not null
        primary key,
    log_item       varchar(64),
    log_item_id    varchar,
    log_user       varchar(512),
    log_timestamp  timestamp default now()                                  not null,
    site           varchar   default 'CT'::character varying                not null,
    log_user_agent varchar
);

alter table tb_log
    owner to runner_dba;

alter sequence tb_log_id_log_seq owned by tb_log.id_log;

create index tb_log_log_item_log_timestamp_index
    on tb_log (log_item, log_timestamp);

grant insert, select, update on tb_log to runner;

create table tb_media
(
    id_media         serial
        primary key,
    media_url        varchar(512),
    media_tipo       varchar(16),
    media_titulo     text,
    media_descricao  text,
    media_metatags   text,
    data_publicacao  timestamp,
    pub_status       boolean default true not null,
    media_canal_nome varchar(255),
    media_canal_slug varchar(120)
);

alter table tb_media
    owner to runner_dba;

grant select, update, usage on sequence tb_media_id_media_seq to runner;

create unique index tb_media_media_url_uindex
    on tb_media (media_url);

grant insert, select, update on tb_media to runner;

create table tb_nome_full_text
(
    id   integer,
    nome tsvector
);

alter table tb_nome_full_text
    owner to runner_dba;

create index tb_nome_full_text_nome_idx
    on tb_nome_full_text using gin (nome);

grant insert, select, update on tb_nome_full_text to runner;

create table tb_notifica
(
    id_notifica          serial
        constraint tb_notifica_pk
            primary key,
    id_usuario           integer   not null,
    data_publicacao      timestamp not null,
    data_expiracao       timestamp,
    data_leitura         timestamp,
    id_notifica_template integer,
    conteudo_notifica    text,
    link                 varchar,
    icone                varchar
);

alter table tb_notifica
    owner to runner_dba;

grant select, usage on sequence tb_notifica_id_notifica_seq to runner;

create index tb_notifica_id_usuario_index
    on tb_notifica (id_usuario);

create unique index tb_notifica_id_usuario_id_notifica_template_uindex
    on tb_notifica (id_usuario, id_notifica_template);

grant insert, select, update on tb_notifica to runner;

create table tb_notifica_template
(
    id_notifica_template serial
        constraint tb_notifica_template_pk
            primary key,
    data_publicacao      timestamp not null,
    data_expiracao       timestamp,
    conteudo_template    text,
    link                 varchar,
    icone                varchar,
    campanha             varchar
);

alter table tb_notifica_template
    owner to runner_dba;

grant select, usage on sequence tb_notifica_template_id_notifica_template_seq to runner;

grant insert, select, update on tb_notifica_template to runner;

create table tb_paginas_cupom
(
    id_paginas_cupom serial,
    id_pagina        integer not null,
    id_cupom         integer
        constraint tb_paginas_cupom_tb_cupom_id_cupom_fk
            references tb_cupom
            on update restrict on delete restrict
);

alter table tb_paginas_cupom
    owner to runner_dba;

grant select, usage on sequence tb_paginas_cupom_id_paginas_cupom_seq to runner;

create unique index tb_paginas_cupom_id_paginas_id_cupom_uindex
    on tb_paginas_cupom (id_pagina, id_cupom);

grant delete, insert, select, update on tb_paginas_cupom to runner;

create table tb_paises_iso3166
(
    id_paises_iso3166 serial
        constraint tb_paises_iso3166_pk
            primary key,
    cod_alpha2        char(2)      not null,
    cod_alpha3        char(3)      not null,
    cod_numerico      integer      not null,
    nome_pais         varchar(128) not null,
    nome_pais_br      varchar(128),
    ddi               varchar
);

alter table tb_paises_iso3166
    owner to postgres;

grant select, usage on sequence tb_paises_iso3166_id_paises_iso3166_seq to runner;

create unique index tb_paises_iso3166_id_paises_iso3166_uindex
    on tb_paises_iso3166 (id_paises_iso3166);

grant insert, select, update on tb_paises_iso3166 to runner;

create table tb_parceiros
(
    id_parceiro   serial
        constraint tb_parceiros_pk
            primary key,
    nome_parceiro varchar(128)             not null,
    tipo_pessoa   char default 'J'::bpchar not null,
    cnpj          varchar(14),
    cpf           varchar(11)
);

alter table tb_parceiros
    owner to runner_dba;

grant select, usage on sequence tb_parceiros_id_parceiro_seq to runner;

create unique index tb_parceiros_id_parceiro_uindex
    on tb_parceiros (id_parceiro);

grant delete, insert, select, update on tb_parceiros to runner;

create table tb_permissoes
(
    id_permissao          serial,
    id_usuario            integer default 0                  not null,
    tag                   varchar,
    data_limite_permissao date    default '2025-12-31'::date not null,
    tipo                  varchar default 'eventos'::character varying
);

alter table tb_permissoes
    owner to runner_dba;

grant select, usage on sequence tb_permissoes_id_permissao_seq to runner;

create unique index tb_permissoes_tag_id_usuario_tipo_uindex
    on tb_permissoes (tag, id_usuario, tipo);

grant insert, select, update on tb_permissoes to runner;

create table tb_permit_atualiza
(
    id_evento integer,
    percurso  integer,
    id_permit integer
);

alter table tb_permit_atualiza
    owner to runner_dba;

grant insert, select, update on tb_permit_atualiza to runner;

create table tb_permits
(
    id_permit        serial
        constraint tb_permits_pk
            primary key,
    id_parceiro      integer      not null,
    nome_prova       text         not null,
    data_prova       date         not null,
    percurso         varchar,
    id_tipo_permit   integer      not null,
    cidade           varchar(128) not null,
    estado           varchar(2)   not null,
    pais             varchar(64)  not null,
    descricao_permit varchar(256),
    informacoes      text
);

alter table tb_permits
    owner to runner_dba;

grant select, usage on sequence tb_permits_id_permit_seq to runner;

create table tb_evento_corridas_percursos
(
    id_evento_percurso serial
        constraint tb_evento_corridas_percursos_pk
            primary key,
    percurso_evento    numeric               not null,
    unidade_de_medida  varchar               not null,
    id_evento          integer               not null
        constraint tb_evento_corridas_percursos_tb_evento_corridas_id_evento_fk
            references tb_evento_corridas
            on update cascade on delete cascade,
    data_percurso      date                  not null,
    hora_largada       time,
    mapa               varchar,
    tipo_corrida       varchar,
    percurso_bloqueado boolean default false not null,
    id_permit          integer
        constraint tb_evento_corridas_percursos_tb_permits_id_permit_fk
            references tb_permits
            on update set null on delete set null,
    rp_m               time,
    rp_f               time,
    hora_corte         time
);

alter table tb_evento_corridas_percursos
    owner to runner_dba;

grant select, usage on sequence tb_evento_corridas_percursos_id_evento_percurso_seq to runner;

create unique index tb_evento_corridas_percursos_id_evento_percurso_uindex
    on tb_evento_corridas_percursos (id_evento_percurso);

create unique index tb_evento_corridas_percursos_id_evento_percurso_uindex_2
    on tb_evento_corridas_percursos (id_evento, percurso_evento);

grant insert, select, update on tb_evento_corridas_percursos to runner;

grant select on tb_evento_corridas_percursos to liverunners_dba;

create unique index tb_permits_id_permit_uindex
    on tb_permits (id_permit);

grant insert, select, update on tb_permits to runner;

create table tb_powerups
(
    id_powerup serial
        constraint tb_powerups_pk
            primary key,
    titulo     varchar,
    imagem     varchar,
    descricao  varchar,
    tag        varchar,
    ativo      boolean default false not null,
    liberado   boolean default false
);

alter table tb_powerups
    owner to runner_dba;

grant select, usage on sequence tb_powerups_id_powerup_seq to runner;

grant insert, select, update on tb_powerups to runner;

create table tb_powerups_permissoes
(
    id_permissao serial
        constraint tb_powerups_permissoes_pk
            primary key,
    id_powerup   integer               not null,
    tag          varchar,
    descricao    varchar,
    obrigatorio  boolean default false not null,
    ordenacao    integer default 0     not null
);

alter table tb_powerups_permissoes
    owner to runner_dba;

grant select, usage on sequence tb_powerups_permissoes_id_permissao_seq to runner;

grant insert, select, update on tb_powerups_permissoes to runner;

create table tb_powerups_permissoes_usuario
(
    id_permissao_usuario serial
        constraint tb_powerups_permissoes_usuario_pk
            primary key,
    id_permissao         integer                 not null,
    id_usuario           integer,
    data_permissao       timestamp default now() not null
);

alter table tb_powerups_permissoes_usuario
    owner to runner_dba;

grant select, usage on sequence tb_powerups_permissoes_usuario_id_permissao_usuario_seq to runner;

create unique index tb_powerups_permissoes_usuario_id_permissao_id_usuario_uindex
    on tb_powerups_permissoes_usuario (id_permissao, id_usuario);

grant delete, insert, select, update on tb_powerups_permissoes_usuario to runner;

create table tb_resultados_obs
(
    id_evento integer not null,
    num_peito integer not null,
    obs       varchar not null,
    constraint tb_resultados_obs_pk
        primary key (id_evento, obs, num_peito)
);

alter table tb_resultados_obs
    owner to runner_dba;

grant insert, select, update on tb_resultados_obs to runner;

create table tb_resultados_processa
(
    cod_evento                 varchar(64)           not null,
    id_evento                  integer,
    data_processamento_inicial timestamp,
    data_processamento_final   timestamp,
    chave_processamento        uuid,
    erro_execucao              boolean default false not null,
    chave_verificacao          uuid
);

alter table tb_resultados_processa
    owner to runner_dba;

grant insert, select, update on tb_resultados_processa to runner;

create table tb_resultados_processa_logs
(
    id_resultado_processa_log serial,
    id_evento                 integer,
    cod_evento                varchar(64)           not null,
    data_processamento        timestamp             not null,
    chave_processamento       uuid,
    erro_execucao             boolean default false not null,
    log_execucao              text
);

alter table tb_resultados_processa_logs
    owner to runner_dba;

grant select, usage on sequence tb_resultados_processa_logs_id_resultado_processa_log_seq to runner;

grant insert, select, update on tb_resultados_processa_logs to runner;

create table tb_resultados_resumo
(
    id_resultado_resumo serial,
    id_evento           integer not null
        constraint tb_resultados_resumo_tb_evento_corridas_id_evento_fk
            references tb_evento_corridas
            on update cascade on delete cascade,
    percurso            integer not null,
    modalidade          varchar not null,
    concluintes         integer not null,
    tipo_corrida        varchar,
    inscritos           integer,
    pace_medio          time,
    pace_medio_top_10   time,
    pace_medio_top_100  time,
    concluintes_sub3    integer
);

alter table tb_resultados_resumo
    owner to runner_dba;

grant select, usage on sequence tb_resultados_resumo_id_resultado_resumo_seq to runner;

create unique index tb_resultados_resumo_id_evento_percurso_uindex
    on tb_resultados_resumo (id_evento, percurso, modalidade);

grant insert, select, update on tb_resultados_resumo to runner;

grant select on tb_resultados_resumo to liverunners_dba;

create table tb_resultados_resumo_2025
(
    id_resultado_resumo      serial,
    id_evento                integer not null
        constraint tb_resultados_resumo_2025_tb_evento_corridas_id_evento_fk
            references tb_evento_corridas
            on update cascade on delete cascade,
    percurso                 numeric not null,
    modalidade               varchar not null,
    sexo                     varchar,
    concluintes              integer not null,
    tipo_corrida             varchar,
    inscritos                integer,
    pace_menor               time,
    pace_medio               time,
    pace_maior               time,
    pace_medio_top_10        time,
    pace_medio_top_100       time,
    pace_medio_5_porcento    time,
    pace_medio_10_porcento   time,
    pace_medio_50_porcento   time,
    limite_a                 time,
    limite_a_concluintes     integer,
    limite_b                 time,
    limite_b_concluintes     integer,
    limite_elite             time,
    limite_elite_concluintes integer,
    percentil                time,
    percentil_sem_desvio     time
);

alter table tb_resultados_resumo_2025
    owner to runner_dba;

grant select, usage on sequence tb_resultados_resumo_2025_id_resultado_resumo_seq to runner;

create unique index tb_resultados_resumo_2025_id_evento_percurso_uindex
    on tb_resultados_resumo_2025 (id_evento, percurso, modalidade, sexo);

grant insert, select, update on tb_resultados_resumo_2025 to runner;

create table tb_resultados_resumo_backup
(
    id_resultado_resumo integer,
    id_evento           integer,
    percurso            integer,
    concluintes         integer
);

alter table tb_resultados_resumo_backup
    owner to runner_dba;

grant insert, select, update on tb_resultados_resumo_backup to runner;

create table tb_resultados_resumo_limites
(
    percurso     integer not null,
    limite_a     time,
    limite_b     time,
    limite_elite time,
    id_evento    integer
);

alter table tb_resultados_resumo_limites
    owner to runner_dba;

create unique index tb_resultados_resumo_limites_percurso_idx
    on tb_resultados_resumo_limites (percurso, id_evento);

grant insert, select, update on tb_resultados_resumo_limites to runner;

create table tb_resultados_temp
(
    id_resultado            serial,
    num_peito               varchar,
    nome                    varchar,
    categoria               varchar,
    id_evento               varchar,
    modalidade              varchar,
    pace                    varchar,
    percurso                varchar,
    sexo                    varchar,
    tempo_bruto             varchar,
    tempo_total             varchar,
    classificacao_categoria varchar,
    classificacao_sexo      varchar,
    classificacao_total     varchar,
    velocidade_media        varchar,
    equipe                  varchar,
    chave_processamento     uuid,
    data_nascimento         varchar,
    nacionalidade           varchar,
    hora_largada            varchar,
    np                      varchar,
    id_usuario              integer,
    status_final            varchar
);

alter table tb_resultados_temp
    owner to runner_dba;

grant select, update, usage on sequence tb_resultados_temp_id_resultado_seq to runner;

create index tb_resultados_temp_id_evento_index
    on tb_resultados_temp (id_evento);

create index tb_resultados_temp_num_peito_id_evento_index
    on tb_resultados_temp (num_peito, id_evento);

grant delete, insert, select, update on tb_resultados_temp to runner;

create table tb_strava_activities
(
    activity_id          bigint                                               not null
        constraint tb_strava_activities_pk
            primary key,
    athlete_id           bigint                                               not null,
    distance             double precision,
    type                 varchar,
    start_date           timestamp,
    title                varchar,
    moving_time          integer,
    strava_raw           jsonb,
    resource_state       integer          default 1                           not null,
    processed            boolean          default false,
    id_athlete_owner     integer          default 0                           not null,
    id_athlete_donation  integer          default 0                           not null,
    activity_date        date,
    activity_source      varchar          default 'strava'::character varying not null,
    total_elevation_gain double precision default 0                           not null,
    updated              timestamp        default now()                       not null,
    calories             double precision default 0                           not null,
    fingerprint          varchar(64),
    processed_at         timestamp,
    hex_count            integer          default 0                           not null,
    gorunners_user_id    uuid,
    elapsed_time         integer
);

alter table tb_strava_activities
    owner to runner_dba;

create index tb_strava_activities_activity_date_athlete_id_index
    on tb_strava_activities (activity_date, athlete_id);

create index tb_strava_activities_id_athlete_donation_activity_date_type_ind
    on tb_strava_activities (id_athlete_donation, activity_date, type);

create index tb_strava_activities_start_date_athlete_id_type_index
    on tb_strava_activities (start_date, athlete_id, type);

create index tb_strava_activities_type_start_date_index
    on tb_strava_activities (type, start_date);

create unique index tb_strava_activities_fingerprint_uq
    on tb_strava_activities (fingerprint)
    where (fingerprint IS NOT NULL);

create index tb_strava_activities_gorunners_user_id_idx
    on tb_strava_activities (gorunners_user_id)
    where (gorunners_user_id IS NOT NULL);

create index tb_strava_activities_pending_idx
    on tb_strava_activities (gorunners_user_id, start_date)
    where (processed_at IS NULL);

grant insert, select, update on tb_strava_activities to runner;

grant select on tb_strava_activities to gorunners_usu;

grant insert, select, update on tb_strava_activities to gorunners_dba;

create table tb_temas
(
    id_tema     serial
        constraint tb_temas_pk
            primary key,
    logo        varchar,
    app_ios     varchar,
    app_android varchar,
    cor_fundo   varchar,
    cor_fonte   varchar,
    cor_botoes  varchar,
    website     varchar,
    instagram   varchar,
    banner      varchar,
    youtube     varchar,
    tag         varchar
);

alter table tb_temas
    owner to runner_dba;

grant select, usage on sequence tb_temas_id_tema_seq to runner;

create unique index tb_temas_id_tema_uindex
    on tb_temas (id_tema);

grant insert, select, update on tb_temas to runner;

create table tb_ticketsports_participantes
(
    numero_inscricao integer not null,
    numero_pedido    integer not null,
    cod_evento       integer not null,
    body             jsonb,
    data_pedido      timestamp,
    email            varchar,
    nome             varchar,
    cidade           varchar,
    estado           varchar,
    documento        varchar,
    modalidade       varchar,
    constraint tb_ticketsports_participantes_pk
        primary key (numero_inscricao, cod_evento)
);

alter table tb_ticketsports_participantes
    owner to runner_dba;

create index tb_ticketsports_participantes_email_index
    on tb_ticketsports_participantes (email);

create index tb_ticketsports_participantes_documento_index
    on tb_ticketsports_participantes (documento);

grant insert, select, update on tb_ticketsports_participantes to runner;

create table tb_ticketsports_pedidos
(
    numero_pedido integer not null,
    cod_evento    integer not null,
    body          jsonb,
    data_pedido   timestamp,
    constraint tb_ticketsports_pedidos_pk
        primary key (numero_pedido, cod_evento)
);

alter table tb_ticketsports_pedidos
    owner to runner_dba;

grant insert, select, update on tb_ticketsports_pedidos to runner;

create table tb_tipos_objetos
(
    nome_objeto      varchar(128) not null
        constraint tb_tipos_objetos_pk
            primary key,
    definicao_objeto varchar(128) not null
);

alter table tb_tipos_objetos
    owner to runner_dba;

create table tb_parceiros_objetos
(
    id_parceiro   integer      not null,
    nome_objeto   varchar(128) not null
        constraint tb_parceiros_objetos_tb_tipos_objetos_nome_objeto_fk
            references tb_tipos_objetos
            on update restrict on delete restrict,
    json_objeto   jsonb,
    string_objeto varchar,
    constraint tb_parceiros_objetos_pk
        primary key (id_parceiro, nome_objeto)
);

alter table tb_parceiros_objetos
    owner to runner_dba;

create unique index tb_parceiros_objetos_id_parceiro_uindex
    on tb_parceiros_objetos (id_parceiro);

grant insert, select, update on tb_parceiros_objetos to runner;

grant insert, select, update on tb_tipos_objetos to runner;

create table tb_tipos_permit
(
    id_tipo_permit serial
        constraint tb_tipos_permit_pk
            primary key,
    nome_permit    varchar(128) not null,
    id_parceiro    integer      not null
);

alter table tb_tipos_permit
    owner to runner_dba;

grant select, usage on sequence tb_tipos_permit_id_tipo_permit_seq to runner;

create unique index tb_tipos_permit_id_tipo_permit_uindex
    on tb_tipos_permit (id_tipo_permit);

grant insert, select, update on tb_tipos_permit to runner;

create table tb_transacoes
(
    transacao_id          serial
        constraint tb_transacoes_pk
            primary key,
    codigo_transacao      varchar                 not null,
    origem_transacao      varchar                 not null,
    valor_transacao       numeric,
    metodo_pagamento      varchar,
    status_atual          varchar                 not null,
    data_criacao          timestamp default now() not null,
    data_ultima_alteracao timestamp,
    id_ultima_alteracao   integer,
    id_usuario            integer,
    json_transacao        jsonb,
    body                  text
);

alter table tb_transacoes
    owner to runner_dba;

grant select, usage on sequence tb_transacoes_transacao_id_seq to runner;

grant insert, select, update on tb_transacoes to runner;

create table tb_uf
(
    cod_uf      integer    not null
        constraint tb_uf_pk
            primary key,
    uf          varchar(2) not null,
    nome_uf     varchar    not null,
    regiao      varchar(16),
    nome_regiao varchar
);

alter table tb_uf
    owner to runner_dba;

create unique index tb_uf_cod_uf_uindex
    on tb_uf (cod_uf);

grant insert, select, update on tb_uf to runner;

create table tb_usuarios
(
    id                                 integer   default nextval('usuarios_id_seq'::regclass) not null
        constraint usuarios_pk
            primary key,
    name                               varchar(256)                                           not null,
    email                              varchar(256)                                           not null,
    password                           text,
    verification_key                   varchar(250),
    is_email_verified                  boolean   default false                                not null,
    data_criacao                       timestamp default now()                                not null,
    ddd_usuario                        varchar(4),
    telefone_usuario                   varchar(24),
    imagem_usuario                     varchar(256),
    is_admin                           boolean   default false                                not null,
    optin_usuario                      boolean   default false                                not null,
    strava_code                        varchar(2048),
    strava_scope                       varchar(2048),
    strava_access_token                varchar(2048),
    strava_expires_at                  integer,
    strava_expires_in                  integer,
    strava_refresh_token               varchar(2048),
    strava_token_type                  varchar(2048),
    strava_id                          integer,
    strava_bio                         text,
    strava_city                        varchar(512),
    strava_country                     varchar(512),
    strava_created_at                  timestamp,
    strava_firstname                   varchar(128),
    strava_follower                    varchar,
    strava_friend                      varchar,
    strava_badge_type_id               integer,
    strava_lastname                    varchar(128),
    strava_premium                     boolean,
    strava_profile                     varchar(2048),
    strava_profile_medium              varchar(2048),
    strava_resource_state              integer,
    strava_sex                         varchar(1),
    strava_state                       varchar(512),
    strava_summit                      boolean,
    strava_updated_at                  timestamp,
    strava_username                    varchar(128),
    strava_weight                      double precision,
    strava_full_athlete_type           integer,
    strava_full_can_follow             boolean,
    strava_full_blocked                boolean,
    strava_full_date_preference        varchar(32),
    strava_full_follower_count         integer,
    strava_full_friend_count           integer,
    strava_full_ftp                    varchar,
    strava_full_is_winback_via_upload  boolean,
    strava_full_is_winback_via_view    boolean,
    strava_full_measurement_preference varchar(32),
    strava_full_mutual_friend_count    integer,
    strava_full_clubs                  jsonb,
    strava_full_shoes                  jsonb,
    strava_full_bikes                  jsonb,
    data_alteracao                     timestamp,
    username                           varchar,
    tag_usuario                        varchar,
    url_usuario                        varchar,
    fonte_lead                         varchar,
    cidade                             varchar,
    estado                             varchar(2),
    data_nascimento                    date,
    aka                                varchar,
    assessoria                         varchar,
    is_dev                             boolean   default false                                not null,
    is_partner                         boolean   default false                                not null,
    genero                             varchar,
    cbat                               varchar,
    pedido_366                         integer,
    inscricao_366                      integer,
    pais                               varchar   default 'BR'::character varying              not null,
    cep                                varchar(9),
    ddi_usuario                        varchar(3),
    endereco                           varchar,
    manychat_subscriber_id             bigint,
    ano_nascimento                     integer,
    ficha_medica                       jsonb,
    strava                             jsonb,
    rp                                 jsonb,
    partner_info                       jsonb,
    data_statisticas                   timestamp
);

alter table tb_usuarios
    owner to runner_dba;

alter sequence usuarios_id_seq owned by tb_usuarios.id;

create table desafio_cna
(
    id_usuario     integer                                             not null
        constraint desafio_cna_pk
            primary key
        constraint desafio_cna_tb_usuarios_id_fk
            references tb_usuarios,
    num_pedido     varchar,
    status         varchar   default 'I'::character varying            not null,
    produto        varchar   default 'inscricao365'::character varying not null,
    data_inscricao timestamp default CURRENT_TIMESTAMP                 not null,
    doador         boolean   default false                             not null,
    obs_pedido     varchar
);

alter table desafio_cna
    owner to runner_dba;

grant insert, select, update on desafio_cna to runner;

create table tb_desafios_rr
(
    id_agregador   integer                             not null
        constraint desafios_rr_tb_agregadores_id_fk
            references tb_agregadores,
    id_usuario     integer                             not null
        constraint desafio_cna_tb_usuarios_id_fk
            references tb_usuarios,
    data_inscricao timestamp default CURRENT_TIMESTAMP not null,
    constraint tb_desafios_rr_pk
        primary key (id_usuario, id_agregador)
);

alter table tb_desafios_rr
    owner to runner_dba;

grant insert, select, update on tb_desafios_rr to runner;

create table tb_desafios_rr_provas
(
    id_agregador   integer                             not null
        constraint tb_desafios_rr_provas_tb_agregadores_id_agregador_fk
            references tb_agregadores
            on update restrict on delete restrict,
    id_usuario     integer                             not null
        constraint tb_desafios_rr_provas_tb_usuarios_id_fk
            references tb_usuarios
            on update restrict on delete restrict,
    id_evento      integer                             not null
        constraint tb_desafios_rr_provas_tb_evento_corridas_id_evento_fk
            references tb_evento_corridas
            on update restrict on delete restrict,
    num_pedido     varchar,
    status         varchar,
    data_inscricao timestamp default CURRENT_TIMESTAMP not null,
    num_peito      integer,
    obs_pedido     varchar,
    constraint tb_desafios_rr_provas_pk
        primary key (id_agregador, id_usuario, id_evento)
);

alter table tb_desafios_rr_provas
    owner to runner_dba;

grant insert, select, update on tb_desafios_rr_provas to runner;

create table tb_evento_corridas_checkin
(
    id_evento_corridas_checkin serial
        constraint tb_evento_corridas_checkin_pk
            primary key,
    id_usuario                 integer                             not null
        constraint tb_evento_corridas_checkin_tb_usuarios_id_usuario_fk
            references tb_usuarios
            on update cascade on delete cascade,
    tipo_checkin               varchar                             not null,
    id_evento                  integer                             not null,
    id_fornecedor              integer
        constraint tb_evento_corridas_checkin_tb_fornecedores_id_fornecedor_fk
            references tb_fornecedores
            on update cascade on delete cascade,
    data_checkin               timestamp default CURRENT_TIMESTAMP not null,
    id_usuario_checkin         integer
        constraint tb_evento_corridas_checkin_tb_usuarios_id_fk
            references tb_usuarios
            on update cascade on delete cascade,
    id_pagina                  integer
);

alter table tb_evento_corridas_checkin
    owner to runner_dba;

grant select, usage on sequence tb_evento_corridas_checkin_id_evento_corridas_checkin_seq to runner;

create unique index tb_evento_corridas_checkin_backup_duplicate
    on tb_evento_corridas_checkin (id_usuario, id_evento, id_fornecedor);

create unique index tb_evento_corridas_checkin_duplicate
    on tb_evento_corridas_checkin (id_usuario, id_evento, id_fornecedor);

create unique index tb_evento_corridas_checkin_id_evento_id_usuario_tipo_checkin_ui
    on tb_evento_corridas_checkin (id_evento, id_usuario, tipo_checkin);

grant insert, select, update on tb_evento_corridas_checkin to runner;

create table tb_paginas
(
    id_pagina           serial
        primary key,
    id_usuario_cadastro integer                                     not null
        constraint tb_paginas_tb_usuarios_id_fk
            references tb_usuarios,
    nome                varchar(128)                                not null,
    apelido             varchar(128),
    instagram           varchar,
    instagram_publico   boolean default true                        not null,
    whatsapp            varchar,
    whatsapp_publico    boolean default false                       not null,
    facebook            varchar,
    facebook_publico    boolean default true                        not null,
    website             varchar,
    website_publico     boolean default true                        not null,
    youtube             varchar,
    youtube_publico     boolean default true                        not null,
    tiktok              varchar,
    tiktok_publico      boolean default true                        not null,
    loja                varchar,
    loja_publico        boolean default true                        not null,
    path_imagem         varchar,
    id_cidade           integer,
    cidade              varchar,
    uf                  varchar(2),
    verificado          boolean default false                       not null,
    tag                 varchar
        constraint tag_pk
            unique,
    tag_prefix          varchar default 'atleta'::character varying not null,
    profissional        boolean default false                       not null,
    descricao           varchar,
    perfil_publico      boolean default true                        not null
);

alter table tb_paginas
    owner to runner_dba;

grant select, usage on sequence tb_paginas_id_pagina_seq to runner;

create index tb_paginas_id_usuario_cadastro_tag_prefix_index
    on tb_paginas (id_usuario_cadastro, tag_prefix);

grant insert, select, update on tb_paginas to runner;

grant select on tb_paginas to gorunners_usu;

grant select on tb_paginas to gorunners_dba;

create table tb_paginas_feed
(
    id_pagina_feed   bigserial,
    id_pagina        integer              not null
        constraint tb_paginas_feed_tb_paginas_id_pagina_fk
            references tb_paginas
            on update cascade on delete cascade,
    titulo           varchar,
    descricao        varchar,
    referencia       varchar,
    id_referencia    bigint,
    publico          boolean default true not null,
    data_atualizacao timestamp,
    id_usuario       integer              not null
        constraint tb_paginas_feed_tb_usuarios_id_fk
            references tb_usuarios
            on update cascade on delete cascade,
    status           integer default 1    not null
);

alter table tb_paginas_feed
    owner to runner_dba;

grant select, usage on sequence tb_paginas_feed_id_pagina_feed_seq to runner;

create unique index tb_paginas_feed_id_pagina_referencia_id_referencia_uindex
    on tb_paginas_feed (id_pagina, referencia, id_referencia);

grant insert, select, update on tb_paginas_feed to runner;

create table tb_paginas_usuarios
(
    id_pagina_usuario serial
        constraint tb_paginas_usuarios_pk
            primary key,
    id_pagina         integer not null
        constraint tb_paginas_usuarios_tb_paginas_id_pagina_fk
            references tb_paginas
            on update restrict on delete restrict,
    id_usuario        integer not null
        constraint tb_paginas_usuarios_tb_usuarios_id_fk
            references tb_usuarios
            on update restrict on delete restrict
);

alter table tb_paginas_usuarios
    owner to runner_dba;

grant select, usage on sequence tb_paginas_usuarios_id_pagina_usuario_seq to runner;

grant insert, select, update on tb_paginas_usuarios to runner;

create table tb_paginas_vinculos
(
    id_pagina_origem    integer                             not null
        constraint tb_paginas_vinculos_tb_paginas_id_pagina_fk
            references tb_paginas
            on update cascade on delete cascade,
    id_pagina_destino   integer                             not null
        constraint tb_vinculos_tb_paginas_id_pagina_fk2
            references tb_paginas
            on update cascade on delete cascade,
    tipo_vinculo        integer                             not null,
    vinculo_validado    boolean   default true              not null,
    id_usuario_cadastro integer                             not null
        constraint tb_paginas_vinculos_tb_usuarios_id_fk
            references tb_usuarios
            on update cascade on delete cascade,
    data_cadastramento  timestamp default CURRENT_TIMESTAMP not null,
    constraint tb_paginas_vinculos_pk
        primary key (id_pagina_origem, id_pagina_destino, tipo_vinculo)
);

alter table tb_paginas_vinculos
    owner to runner_dba;

create index tb_paginas_vinculos_id_pagina_destino_id_pagina_origem_index
    on tb_paginas_vinculos (id_pagina_destino, id_pagina_origem);

grant delete, insert, select, update on tb_paginas_vinculos to runner;

create unique index tb_usuarios_email_uindex
    on tb_usuarios (email);

create unique index tb_usuarios_username_uindex
    on tb_usuarios (username);

grant insert, select, update on tb_usuarios to runner;

grant select on tb_usuarios to gorunners_usu;

grant select on tb_usuarios to gorunners_dba;

create table tb_usuarios_fornecedores
(
    id_usuarios_fornecedores serial,
    id_usuario               integer     not null,
    id_fornecedor            integer     not null,
    id_tipo_fornecedor       integer     not null,
    tipo_relacionamento      varchar(32) not null
);

alter table tb_usuarios_fornecedores
    owner to runner_dba;

grant select, usage on sequence tb_usuarios_fornecedores_id_usuarios_fornecedores_seq to runner;

grant delete, insert, select, update on tb_usuarios_fornecedores to runner;

create table tb_webhook
(
    id_call    serial
        constraint tb_webhook_pk
            primary key,
    service    varchar,
    body       text,
    fieldnames varchar,
    call_date  timestamp default now() not null,
    referencia varchar,
    status     varchar
);

alter table tb_webhook
    owner to postgres;

grant select, usage on sequence tb_webhook_id_call_seq to runner;

create index tb_webhook_referencia_call_date_index
    on tb_webhook (referencia, call_date);

grant delete, insert, select, update on tb_webhook to runner;

create table tbbi_dim_data
(
    id_data                  serial
        constraint tbbi_dim_data_pk
            primary key,
    data_referencia          date        not null,
    ano                      integer     not null,
    mes                      integer     not null,
    mes_extenso              varchar(24) not null,
    dia                      integer     not null,
    dia_do_ano               integer     not null,
    dia_da_semana            varchar(24) not null,
    semana_calendario        integer     not null,
    data_formatada           varchar(10) not null,
    trimestre                varchar(8)  not null,
    trimestre_ano            varchar(12) not null,
    mes_ano                  varchar(12) not null,
    ano_semana_calendario    varchar(24),
    tipo_dia_semana          varchar(24) not null,
    feriado_nacional         varchar(24) not null,
    calendario_inicio_semana varchar(24) not null,
    calendario_final_semana  varchar(24) not null
);

alter table tbbi_dim_data
    owner to runner_dba;

grant select, usage on sequence tbbi_dim_data_id_data_seq to runner;

create unique index tbbi_dim_data_id_data_uindex
    on tbbi_dim_data (id_data);

grant insert, select, update on tbbi_dim_data to runner;

create table tbbi_dim_localidade
(
    id_localidade     serial
        constraint tbbi_dim_localidade_pk
            primary key,
    nome_pais         varchar(128)          not null,
    regiao            varchar(64)           not null,
    estado            varchar               not null,
    nome_estado       varchar(128),
    nome_cidade       varchar(128)          not null,
    capital           boolean default false not null,
    id_paises_iso3166 integer default 0     not null
);

alter table tbbi_dim_localidade
    owner to runner_dba;

grant select, usage on sequence tbbi_dim_localidade_id_localidade_seq to runner;

create unique index tbbi_dim_localidade_id_localidade_uindex
    on tbbi_dim_localidade (id_localidade);

grant insert, select, update on tbbi_dim_localidade to runner;

create table tbbi_fat_resultado
(
    id_fat_resultado     serial,
    id_data              integer              not null,
    id_localidade        integer              not null,
    id_evento            integer              not null,
    id_resultado         integer              not null,
    num_peito            integer              not null,
    nome                 varchar              not null,
    data_nascimento      date,
    evento_homologado    boolean              not null,
    modalidade           varchar,
    pace                 time,
    percurso             numeric,
    sexo                 varchar,
    tempo_bruto          time,
    tempo_total          time,
    velocidade_media     numeric,
    nome_categoria       varchar,
    resultado_homologado boolean default true not null,
    concluinte           boolean default true not null,
    nacionalidade        varchar(8),
    status_final         integer default 0,
    hora_largada         time
);

alter table tbbi_fat_resultado
    owner to runner_dba;

grant select, usage on sequence tbbi_fat_resultado_id_fat_resultado_seq to runner;

grant insert, select, update on tbbi_fat_resultado to runner;

create table temp_assessorias
(
    id_assessoria            serial,
    nome_assessoria          varchar,
    nome_assessoria_tsvector tsvector,
    qtd_atletas              integer,
    qtd_eventos              integer
);

alter table temp_assessorias
    owner to runner_dba;

grant select, usage on sequence temp_assessorias_id_assessoria_seq to runner;

grant insert, select, update on temp_assessorias to runner;

create table tb_agregadores_cidades
(
    agregador_tag varchar(120) not null,
    id_cidade     integer,
    cidade        varchar
);

alter table tb_agregadores_cidades
    owner to runner_dba;

grant insert, select, update on tb_agregadores_cidades to runner;

create table tb_inscricoes
(
    num_pedido            serial,
    id_usuario            integer,
    id_evento             integer                 not null,
    body                  jsonb,
    data_pedido           timestamp default now() not null,
    data_checkin          timestamp,
    flag_sorteio          boolean,
    observacoes           varchar,
    nome                  varchar,
    modalidade            varchar,
    num_peito             integer,
    documento             varchar,
    genero                varchar,
    data_nascimento       date,
    num_inscricao_externo varchar,
    data_scan             timestamp,
    constraint tb_inscricoes_pk
        unique (id_evento, id_usuario)
);

alter table tb_inscricoes
    owner to runner_dba;

grant select, usage on sequence tb_inscricoes_num_pedido_seq to runner;

create unique index tb_inscricoes_id_evento_num_peito__uindex
    on tb_inscricoes (id_evento, num_peito);

grant insert, select, update on tb_inscricoes to runner;

create table desafios
(
    id_usuario           integer                                             not null
        constraint desafios_tb_usuarios_id_fk
            references tb_usuarios,
    num_pedido           varchar,
    status               varchar   default 'I'::character varying            not null,
    produto              varchar   default 'inscricao365'::character varying not null,
    data_inscricao       timestamp default CURRENT_TIMESTAMP                 not null,
    obs_pedido           varchar,
    body                 jsonb,
    desafio              varchar,
    status_final         varchar,
    dias_corridos        integer,
    maior_sequencia_dias integer,
    constraint desafios_pk
        primary key (id_usuario, produto)
);

alter table desafios
    owner to runner_dba;

grant insert, select, update on desafios to runner;

create table tb_resultados_resumo_cidades
(
    id_resultado_resumo_cidade serial,
    id_cidade                  integer          not null
        constraint tb_resultados_resumo_cidades_tb_evento_corridas_id_cidade_fk
            references tb_cidades
            on update cascade on delete cascade,
    cidade                     varchar          not null,
    estado                     varchar          not null,
    concluintes                integer          not null,
    tipo_corrida               varchar,
    inscritos                  integer,
    percurso                   numeric,
    min_concluintes            integer          not null,
    max_concluintes            integer          not null,
    ratio_concluintes          double precision not null,
    populacao                  integer default 0,
    qtd_eventos                integer,
    tipo_analise               integer
);

alter table tb_resultados_resumo_cidades
    owner to runner_dba;

grant select, usage on sequence tb_resultados_resumo_cidades_id_resultado_resumo_cidade_seq to runner;

create unique index tb_resultados_resumo_cidades_id_cidade_percurso_uindex
    on tb_resultados_resumo_cidades (id_cidade, tipo_corrida, percurso, tipo_analise);

grant insert, select, update on tb_resultados_resumo_cidades to runner;

create table tb_ibge_populacao
(
    uf               varchar,
    cod_uf           varchar,
    cod_mun          varchar,
    codigo_municipio integer,
    cidade           varchar,
    populacao        integer
);

alter table tb_ibge_populacao
    owner to runner_dba;

grant insert, select, update on tb_ibge_populacao to runner;

create table desafios_obs
(
    id_desafio_obs serial,
    id_usuario     integer                 not null,
    produto        varchar,
    obs            text,
    id_atendente   integer,
    data_obs       timestamp default now() not null
);

alter table desafios_obs
    owner to runner_dba;

grant select, usage on sequence desafios_obs_id_desafio_obs_seq to runner;

grant insert, select, update on desafios_obs to runner;

create table tb_leaderboard_pc
(
    id_pc      serial
        constraint tb_leaderboard_pc_pk
            primary key,
    id_evento  integer               not null,
    distancia  numeric               not null,
    id_externo varchar,
    pc_oficial boolean default false not null
);

alter table tb_leaderboard_pc
    owner to runner_dba;

grant select, usage on sequence tb_leaderboard_pc_id_pc_seq to runner;

create index tb_leaderboard_pc_id_evento_distancia_idx
    on tb_leaderboard_pc (id_evento, distancia);

grant insert, select, update on tb_leaderboard_pc to runner;

create table tb_leaderboard_marca
(
    id_marca    serial
        constraint tb_leaderboard_marca_pk
            primary key,
    id_evento   integer not null,
    id_pc       integer not null,
    num_peito   integer not null,
    marca       timestamp,
    tempo_total time
);

alter table tb_leaderboard_marca
    owner to runner_dba;

grant select, usage on sequence tb_leaderboard_marca_id_marca_seq to runner;

create unique index tb_leaderboard_marca_id_evento_id_pc_num_peito_uindex
    on tb_leaderboard_marca (id_evento, id_pc, num_peito);

create index tb_leaderboard_marca_id_evento_id_pc_idx
    on tb_leaderboard_marca (id_evento, id_pc);

grant insert, select, update on tb_leaderboard_marca to runner;

create table tb_evento_corridas_temp
(
    id_evento           serial
        constraint tb_evento_corridas_temp_pk
            primary key,
    cod_evento          varchar
        unique,
    nome_evento         varchar                                  not null,
    cidade              varchar,
    data_inicial        varchar,
    estado              varchar,
    tag                 varchar(256),
    data_final          varchar,
    descricao           text,
    endereco            varchar,
    coordenadas         varchar,
    categorias          varchar,
    url_inscricao       varchar,
    pais                varchar default 'BR'::character varying,
    url_resultado       varchar,
    id_evento_match     integer,
    nome_simplificado   varchar,
    organizador         varchar,
    obs                 varchar,
    tipo_corrida        varchar default 'rua'::character varying not null,
    id_usuario          integer default 0                        not null,
    url_wiclax          varchar,
    url_imagem          varchar,
    url_imagem_listagem varchar,
    url_hotsite         varchar,
    url_regulamento     varchar
);

alter table tb_evento_corridas_temp
    owner to runner_dba;

grant select, usage on sequence tb_evento_corridas_temp_id_evento_seq to runner;

grant insert, select, update on tb_evento_corridas_temp to runner;

create table tb_leaderboard_evento
(
    id_evento        integer                 not null,
    tempo            varchar,
    largada          timestamp,
    temperatura      numeric,
    umidade          numeric,
    vento            numeric,
    data_atualizacao timestamp default now() not null
);

alter table tb_leaderboard_evento
    owner to runner_dba;

create unique index tb_leaderboard_evento_id_evento_uindex
    on tb_leaderboard_evento (id_evento);

grant insert, select, update on tb_leaderboard_evento to runner;

create table sso_codes
(
    id         bigserial
        primary key,
    code_hash  varchar(128)            not null,
    user_id    varchar(64)             not null,
    audience   varchar(255)            not null,
    expires_at timestamp               not null,
    used       boolean   default false not null,
    nonce      varchar(64),
    ua_hash    varchar(64),
    ip_hash    varchar(64),
    created_at timestamp default now() not null
);

alter table sso_codes
    owner to runner_dba;

grant select, usage on sequence sso_codes_id_seq to runner;

create index sso_codes_code_hash_idx
    on sso_codes (code_hash);

grant insert, select, update on sso_codes to runner;

create table tb_carga_crono
(
    num_inscricao      integer   default nextval('tb_carga_crono_num_inscricao_seq'::regclass),
    protocolo          varchar,
    categoria          varchar,
    num_peito          integer,
    chip               varchar,
    modalidade         varchar,
    nome               varchar,
    data_nascimento    varchar,
    idade              integer,
    idoso              varchar,
    documento          varchar,
    genero             varchar,
    celular            varchar,
    pais               varchar,
    equipe             varchar,
    ticketeira         varchar,
    contato_emergencia varchar,
    id_evento          integer,
    data_importacao    timestamp default now() not null,
    id_carga           integer generated always as identity
);

alter table tb_carga_crono
    owner to runner_dba;

alter sequence tb_carga_crono_num_inscricao_seq owned by tb_carga_crono.num_inscricao;

grant select, usage on sequence tb_carga_crono_id_carga_seq to runner;

grant insert, select, update on tb_carga_crono to runner;

create table tb_carga_racezone
(
    number       varchar,
    name         varchar,
    document     varchar,
    gender       varchar,
    birthday     varchar,
    deliveredkit varchar,
    deliveredby  varchar,
    deliveredat  varchar,
    changedinkit varchar,
    idoso        varchar,
    pais         varchar,
    telefone     varchar,
    protocolo    varchar,
    inscricao    varchar,
    numinscricao varchar,
    route        varchar,
    team         varchar,
    tshirt       varchar,
    kit          varchar,
    heat         varchar
);

alter table tb_carga_racezone
    owner to runner_dba;

grant insert, select, update on tb_carga_racezone to runner;

create table ads.tb_ad_eventos
(
    id_ad_evento  integer default nextval('ads.tb_evento_ads_id_evento_ad_seq'::regclass) not null,
    id_evento     integer                                                             not null,
    escopo        varchar,
    cpc_max       numeric(14, 2),
    limite_diario numeric(14, 2),
    limite_ad     numeric(14, 2),
    inicio_ad     timestamp,
    final_ad      timestamp,
    status        integer default 1                                                   not null,
    configuracoes jsonb,
    qualidade     integer default 5                                                   not null,
    locais        jsonb
);

alter table ads.tb_ad_eventos
    owner to runner_dba;

alter sequence ads.tb_evento_ads_id_evento_ad_seq owned by ads.tb_ad_eventos.id_ad_evento;

grant insert, select, update on ads.tb_ad_eventos to runner;

create table ads.tb_ad_vouchers
(
    id_ad_voucher      serial,
    codigo             varchar,
    id_fornecedor      integer,
    credito            numeric(14, 2),
    credito_disponivel numeric(14, 2),
    status             integer default 1     not null,
    data_criacao       date    default now() not null,
    data_expiracao     date
);

alter table ads.tb_ad_vouchers
    owner to runner_dba;

grant select, usage on sequence ads.tb_ad_vouchers_id_ad_voucher_seq to runner;

grant insert, select, update on ads.tb_ad_vouchers to runner;

create table ads.tb_ad_log
(
    id_ad_log     serial,
    tipo_ad       varchar,
    id_ad         integer,
    valor_ad      numeric(14, 2) default 0     not null,
    contexto      jsonb,
    data_insercao timestamp      default now() not null,
    id_usuario    integer,
    status        integer        default 1     not null
);

alter table ads.tb_ad_log
    owner to runner_dba;

grant select, usage on sequence ads.tb_ad_log_id_ad_log_seq to runner;

grant insert, select, update on ads.tb_ad_log to runner;

create table ads.click_nonce
(
    nonce      text                                   not null
        primary key,
    created_at timestamp with time zone default now() not null
);

alter table ads.click_nonce
    owner to runner_dba;

grant insert, select, update on ads.click_nonce to runner;

create table ads.click_rate_limit
(
    id         bigserial
        primary key,
    ip         text                                   not null,
    campanha   text                                   not null,
    created_at timestamp with time zone default now() not null
);

alter table ads.click_rate_limit
    owner to runner_dba;

grant insert, select, update on ads.click_rate_limit to runner;

create table ads.clicks
(
    id         bigserial
        primary key,
    campanha   text                                   not null,
    dest       text                                   not null,
    ts_signed  bigint                                 not null,
    nonce      text                                   not null,
    ip         text,
    user_agent text,
    referer    text,
    valid_sig  boolean                  default true  not null,
    created_at timestamp with time zone default now() not null
);

alter table ads.clicks
    owner to runner_dba;

grant insert, select, update on ads.clicks to runner;

create table ads.pings
(
    id         bigserial
        primary key,
    campanha   text                                   not null,
    ip         text,
    user_agent text,
    referer    text,
    created_at timestamp with time zone default now() not null
);

alter table ads.pings
    owner to runner_dba;

grant insert, select, update on ads.pings to runner;

create table ads.ping_nonce
(
    nonce      text                                   not null
        primary key,
    created_at timestamp with time zone default now() not null
);

alter table ads.ping_nonce
    owner to runner_dba;

grant insert, select, update on ads.ping_nonce to runner;

create table ads.click_audit
(
    id         bigserial
        primary key,
    campanha   text,
    nonce      text,
    reason     text,
    created_at timestamp with time zone default now() not null
);

alter table ads.click_audit
    owner to runner_dba;

grant insert, select, update on ads.click_audit to runner;

create table ads.impressions
(
    impression_id text                                   not null
        primary key,
    campanha      text                                   not null,
    ts_signed     bigint                                 not null,
    nonce         text                                   not null,
    ip            text,
    user_agent    text,
    referer       text,
    view_ms       integer,
    ratio_peak    numeric(5, 2),
    valid_sig     boolean                  default true  not null,
    created_at    timestamp with time zone default now() not null
);

alter table ads.impressions
    owner to runner_dba;

grant insert, select, update on ads.impressions to runner;

create table desafios_eventos
(
    id_desafio    serial,
    titulo        varchar(128)                                  not null,
    tag           varchar(128)                                  not null,
    descricao     text,
    data_inicio   date,
    id_tema       integer default 0                             not null,
    ordem         integer default 100                           not null,
    data_fim      date,
    slogan        varchar,
    imagem        varchar,
    hotsite       varchar,
    regras_strava varchar,
    timeframe     varchar default 'continuo'::character varying not null,
    sponsors      varchar,
    loja          varchar,
    ativo         boolean default true                          not null,
    regulamento   varchar,
    suporte       varchar,
    destaque      boolean default false                         not null,
    badge         varchar,
    flg_pago      boolean default false                         not null,
    flg_strava    boolean default true                          not null,
    flg_cupom     boolean default false                         not null
);

alter table desafios_eventos
    owner to runner_dba;

grant insert, select, update on desafios_eventos to runner;

create table desafios_produtos
(
    id_produto     serial,
    desafio        varchar           not null,
    codigo_produto varchar,
    nome_produto   varchar,
    valor_produto  numeric default 0 not null
);

alter table desafios_produtos
    owner to runner_dba;

create table tb_mailing
(
    id_mailing    serial,
    id_usuario    integer,
    cod_campanha  varchar,
    email         varchar               not null,
    nome          varchar,
    assunto       varchar               not null,
    descricao     varchar,
    conteudo      text                  not null,
    data_disparo  timestamp,
    resposta_api  text,
    resposta_json jsonb,
    data_envio    timestamp,
    enviado       boolean default false not null,
    recebido      boolean default false not null,
    aberto        integer default 0     not null,
    clicks        integer default 0     not null,
    bounce        varchar
);

alter table tb_mailing
    owner to runner_dba;

create table listas_importadas
(
    origem               varchar,
    numero               varchar,
    lote                 varchar,
    modalidade           varchar,
    sub_modalidade       varchar,
    nome                 varchar,
    data_nascimento      varchar,
    email                varchar,
    tipo_doc             varchar,
    documento            varchar,
    sexo                 varchar,
    celular              varchar,
    endereco             varchar,
    endereco_numero      varchar,
    endereco_complemento varchar,
    cep                  varchar,
    bairro               varchar,
    cidade               varchar,
    uf                   varchar,
    pais                 varchar,
    assessoria           varchar,
    pedido               varchar,
    camiseta             varchar,
    evento               varchar
);

alter table listas_importadas
    owner to runner_dba;

create table tb_paginas_feed_interacoes
(
    id_interacao   serial,
    id_pagina_feed integer                                       not null,
    id_pagina      integer                                       not null,
    tipo_interacao varchar   default 'banana'::character varying not null,
    data_interacao timestamp default now()                       not null
);

alter table tb_paginas_feed_interacoes
    owner to runner_dba;

create table tb_paginas_badges
(
    id_pagina_badge  serial,
    id_pagina        integer            not null,
    badge            varchar            not null,
    valor            varchar,
    contador         integer,
    meta             integer,
    data_atualizacao date default now() not null,
    constraint tb_paginas_badges_pk
        unique (badge, id_pagina)
);

alter table tb_paginas_badges
    owner to runner_dba;

grant select on tb_paginas_badges to runner;

create table tb_paginas_badges_tipos
(
    badge           varchar(48)                                   not null
        constraint tb_paginas_badges_tipos_pk
            primary key,
    image_path      varchar,
    badge_descricao varchar,
    ordem           integer default 1000                          not null,
    ativo           boolean default true                          not null,
    site            varchar default 'RR'::character varying       not null,
    tipo_badge      varchar default 'percurso'::character varying not null,
    badge_tooltip   varchar,
    badge_link      varchar
);

alter table tb_paginas_badges_tipos
    owner to runner_dba;

grant select on tb_paginas_badges_tipos to runner;

create table tb_listas_importadas
(
    id_lista_importada serial
        constraint tb_listas_importadas_pk
            primary key,
    nome_lista         varchar                             not null,
    id_fornecedor      integer                             not null
        constraint tb_listas_importadas_tb_fornecedores_id_fornecedor_fk
            references tb_fornecedores
            on update restrict on delete restrict,
    id_usuario         integer                             not null
        constraint tb_listas_importadas_tb_usuarios_id_fk
            references tb_usuarios
            on update restrict on delete restrict,
    id_evento          integer
        constraint tb_listas_importadas_tb_evento_corridas_id_evento_fk
            references tb_evento_corridas
            on update set null on delete set null,
    tipo_lista         varchar                             not null,
    data_criacao       timestamp default CURRENT_TIMESTAMP not null,
    data_atualizacao   timestamp default CURRENT_TIMESTAMP not null
);

alter table tb_listas_importadas
    owner to runner_dba;

create table tb_listas_conteudos
(
    id_lista_conteudo    serial
        constraint tb_listas_conteudos_pk
            primary key,
    id_lista_importada   integer not null
        constraint tb_listas_conteudos_tb_listas_importadas_id_lista_importada_fk
            references tb_listas_importadas
            on update cascade on delete cascade,
    nome_atleta          varchar not null,
    email                varchar,
    tipo_documento       varchar,
    numero_documento     varchar,
    telefone             varchar,
    endereco             varchar,
    endereco_numero      varchar,
    endereco_complemento varchar,
    cep                  varchar,
    cidade               varchar,
    estado               varchar,
    pais                 varchar,
    numero_inscricao     varchar,
    numero_pedido        varchar,
    categoria            varchar,
    modalidade           varchar,
    tamanho_camiseta     varchar,
    nome_assessoria      varchar,
    numero_peito         integer,
    tempo_bruto          varchar,
    classificacao        varchar
);

alter table tb_listas_conteudos
    owner to runner_dba;

create table tb_listas_usuarios
(
    id_lista_conteudo integer
        constraint tb_listas_usuarios_tb_listas_conteudos_id_lista_conteudo_fk
            references tb_listas_conteudos
            on update cascade on delete cascade,
    id_usuario        integer
        constraint tb_listas_usuarios_tb_usuarios_id_fk
            references tb_usuarios
            on update cascade on delete cascade
);

alter table tb_listas_usuarios
    owner to runner_dba;

create table tb_paginas_badges_teste
(
    id_pagina_badge_teste serial,
    id_pagina             integer            not null,
    badge                 varchar            not null,
    valor                 varchar,
    contador              integer,
    meta                  integer,
    data_atualizacao      date default now() not null
);

alter table tb_paginas_badges_teste
    owner to runner_dba;

grant select on tb_paginas_badges_teste to runner;

create table notebook_cells
(
    id          bigserial
        primary key,
    notebook_id bigint                                 not null,
    cell_order  integer                                not null,
    cell_type   text                                   not null,
    lang        text,
    content     text                                   not null,
    updated_at  timestamp with time zone default now() not null
);

alter table notebook_cells
    owner to runner_dba;

create index idx_notebook_cells_notebook_order
    on notebook_cells (notebook_id, cell_order);

create table notebooks
(
    notebook_id    serial,
    notebook_title varchar,
    tag            varchar,
    call_order     integer default 1 not null
);

alter table notebooks
    owner to runner_dba;

create table tb_tipos_status_final
(
    id_tipo_status_final   integer     not null
        constraint tb_tipos_status_final_pk
            primary key,
    descricao_status_final varchar(50) not null
);

alter table tb_tipos_status_final
    owner to runner_dba;

create table tb_resultados
(
    id_resultado            integer default nextval('tb_resultados_nova_id_resultado_seq'::regclass) not null
        constraint tb_resultados_nova_pkey
            primary key,
    num_peito               integer,
    nome                    varchar,
    data_nascimento         date,
    id_evento               integer
        constraint tb_resultados_tb_evento_corridas_id_evento_fk
            references tb_evento_corridas
            on delete restrict,
    modalidade              varchar,
    pace                    time,
    percurso                numeric,
    sexo                    varchar,
    tempo_bruto             time,
    tempo_total             time,
    classificacao_categoria numeric,
    classificacao_sexo      numeric,
    classificacao_total     numeric,
    velocidade_media        numeric,
    equipe                  varchar,
    nome_categoria          varchar,
    id_usuario              integer
        constraint tb_resultados_tb_usuarios_id_fk
            references tb_usuarios
            on delete set null,
    id_categoria            integer,
    homologado              boolean default true                                                     not null,
    concluinte              boolean default true,
    chave_processamento     uuid,
    chave_verificacao       uuid,
    nacionalidade           varchar(8),
    status_final            integer default 0
        constraint tb_resultados_tb_tipos_status_final_id_tipo_status_final_fk
            references tb_tipos_status_final
            on update restrict on delete restrict,
    hora_largada            time,
    tempo_f1_categoria      time,
    tempo_f1_sexo           time,
    tempo_f1_total          time,
    posicao_ranking         integer,
    classificacao_pais      integer,
    pcd                     boolean default false                                                    not null,
    nome_full_text          tsvector,
    idade_range             int4range,
    nome_normalizado        text
);

alter table tb_resultados
    owner to runner_dba;

alter sequence tb_resultados_nova_id_resultado_seq owned by tb_resultados.id_resultado;

create index tb_resultados_id_evento_num_peito_index
    on tb_resultados (id_evento, num_peito);

create index tb_resultados_id_evento_percurso_modalidade_index
    on tb_resultados (id_evento, percurso, modalidade);

create unique index tb_resultados_id_evento_percurso_num_peito_sexo_nome_uindex
    on tb_resultados (id_evento, percurso, num_peito, sexo, nome);

create unique index tb_resultados_id_evento_percurso_num_peito_uindex
    on tb_resultados (id_evento, percurso, num_peito);

create index tb_resultados_id_usuario_index
    on tb_resultados (id_usuario);

create index tb_resultados_nome_concluinte_index
    on tb_resultados (nome, concluinte);

create index tb_resultados_nome_full_text_idx
    on tb_resultados using gin (nome_full_text);

create index tb_resultados_idade_range_gist
    on tb_resultados using gist (idade_range);

create index idx_result_nome_norm_trgm
    on tb_resultados using gin (nome_normalizado gin_trgm_ops);

grant insert, select, update on tb_resultados to runner;

grant select on tb_resultados to liverunners_dba;

create table tb_resultados_vinculo
(
    id_resultado_vinculo   serial
        constraint tb_resultados_vinculo_pk
            primary key,
    id_resultado           integer                             not null
        constraint tb_resultados_vinculo_tb_resultados_id_resultado_fk
            references tb_resultados
            on delete cascade,
    id_usuario             integer                             not null
        constraint tb_resultados_vinculo_tb_usuarios_id_fk
            references tb_usuarios
            on delete cascade,
    vinculo_resultado      boolean   default true              not null,
    id_usuario_responsavel integer                             not null,
    data_vinculo           timestamp default CURRENT_TIMESTAMP not null,
    vinculo_aprovado       boolean,
    data_aprovacao         timestamp
);

alter table tb_resultados_vinculo
    owner to postgres;

grant select, usage on sequence tb_resultados_vinculo_id_resultado_vinculo_seq to runner;

create unique index tb_resultados_vinculo_id_resultado_id_usuario_uindex
    on tb_resultados_vinculo (id_resultado, id_usuario);

create unique index tb_resultados_vinculo_id_resultado_vinculo_uindex
    on tb_resultados_vinculo (id_resultado_vinculo);

grant insert, select, update on tb_resultados_vinculo to runner;

create table pimenta_tb_rs
(
    id_resultado            serial
        constraint tb_rs_pk
            primary key,
    num_peito               integer,
    nome                    varchar,
    data_nascimento         date,
    id_evento               integer,
    modalidade              varchar,
    pace                    time,
    percurso                numeric,
    sexo                    varchar,
    tempo_bruto             time,
    tempo_total             time,
    classificacao_categoria numeric,
    classificacao_sexo      numeric,
    classificacao_total     numeric,
    velocidade_media        numeric,
    equipe                  varchar,
    nome_categoria          varchar,
    id_usuario              integer,
    id_categoria            integer,
    homologado              boolean default true  not null,
    concluinte              boolean default true,
    chave_processamento     uuid,
    chave_verificacao       uuid,
    nacionalidade           varchar(8),
    status_final            integer default 0,
    hora_largada            time,
    tempo_f1_categoria      time,
    tempo_f1_sexo           time,
    tempo_f1_total          time,
    posicao_ranking         integer,
    classificacao_pais      integer,
    pcd                     boolean default false not null,
    nome_full_text          tsvector,
    idade_range             int4range,
    nome_normalizado        text
);

alter table pimenta_tb_rs
    owner to runner_dba;

create unique index tb_rs_uindex1
    on pimenta_tb_rs (id_evento, percurso, num_peito, sexo, nome);

create unique index pimenta_tb_rs_id_evento_percurso_num_peito_uindex
    on pimenta_tb_rs (id_evento, percurso, num_peito);

create index idx_pessoa_nome_norm_trgm
    on pimenta_tb_rs using gin (nome_normalizado gin_trgm_ops);

grant insert, select, update on pimenta_tb_rs to runner;

create table pimenta_tb_rs_versao
(
    id_resultado              integer,
    id_resultado_versao       integer,
    num_peito                 integer,
    nome                      varchar,
    data_nascimento           date,
    id_evento                 integer,
    modalidade                varchar,
    pace                      time,
    percurso                  numeric,
    sexo                      varchar,
    tempo_bruto               time,
    tempo_total               time,
    classificacao_categoria   numeric,
    classificacao_sexo        numeric,
    classificacao_total       numeric,
    velocidade_media          numeric,
    equipe                    varchar,
    nome_categoria            varchar,
    id_usuario                integer,
    id_categoria              integer,
    homologado                boolean default true  not null,
    concluinte                boolean default true,
    chave_processamento       uuid,
    chave_verificacao         uuid,
    nacionalidade             varchar(8),
    status_final              integer default 0,
    hora_largada              time,
    tempo_f1_categoria        time,
    tempo_f1_sexo             time,
    tempo_f1_total            time,
    posicao_ranking           integer,
    classificacao_pais        integer,
    pcd                       boolean default false not null,
    nome_full_text            tsvector,
    idade_range               int4range,
    id_resultado_versao_atual integer
);

alter table pimenta_tb_rs_versao
    owner to runner_dba;

create unique index pimenta_tb_rs_versao_id_resultado_id_resultado_versao_uindex
    on pimenta_tb_rs_versao (id_resultado, id_resultado_versao);

create unique index tb_rs_versao_uindex1
    on pimenta_tb_rs_versao (id_evento, percurso, num_peito);

grant insert, select, update on pimenta_tb_rs_versao to runner;

create table tbbi_dim_organizador
(
    id_organizador   integer      not null
        constraint tbbi_dim_organizador_pk
            primary key,
    nome_organizador varchar(128) not null
);

alter table tbbi_dim_organizador
    owner to runner_dba;

grant insert, select, update on tbbi_dim_organizador to runner;

create table tbbi_dim_cronometragem
(
    id_cronometragem   integer      not null
        constraint tbbi_dim_cronometragem_pk
            primary key,
    nome_cronometragem varchar(128) not null
);

alter table tbbi_dim_cronometragem
    owner to runner_dba;

grant insert, select, update on tbbi_dim_cronometragem to runner;

create table tbbi_dim_faixas
(
    id_faixa   integer      not null
        constraint tbbi_dim_faixas_pk
            primary key,
    nome_faixa varchar(128) not null
);

alter table tbbi_dim_faixas
    owner to runner_dba;

grant insert, select, update on tbbi_dim_faixas to runner;

create table tbbi_dim_geracoes
(
    id_geracao   integer      not null
        constraint tbbi_dim_geracoes_pk
            primary key,
    nome_geracao varchar(128) not null
);

alter table tbbi_dim_geracoes
    owner to runner_dba;

grant insert, select, update on tbbi_dim_geracoes to runner;

create table pimenta_organizadores
(
    organizador       varchar,
    nome_original     varchar,
    nome_normalizado  varchar,
    tag_identificacao varchar,
    nome_agrupado     varchar
);

alter table pimenta_organizadores
    owner to runner_dba;

create table tbbi_dim_organizacao_2025
(
    id_organizacao integer not null,
    agrupamento    varchar not null,
    nome_padrao    varchar not null,
    nome_original  varchar not null
);

alter table tbbi_dim_organizacao_2025
    owner to runner_dba;

create index tbbi_dim_organizacao_2025_agrupamento_nome_original_index
    on tbbi_dim_organizacao_2025 (agrupamento, nome_original);

create table tbbi_dim_cbat_categorias
(
    id_cbat_categoria   integer      not null
        constraint tbbi_dim_cbat_categorias_pk
            primary key,
    nome_cbat_categoria varchar(128) not null
);

alter table tbbi_dim_cbat_categorias
    owner to runner_dba;

grant insert, select, update on tbbi_dim_cbat_categorias to runner;

create table tbbi_fat_perfil_br_2025
(
    id_fat_perfil_br_2025 serial,
    id_data               integer    not null,
    id_localidade         integer    not null,
    id_evento             integer    not null,
    id_organizador        integer    not null,
    id_cronometrador      integer    not null,
    id_resultado          integer    not null,
    id_geracao            integer    not null,
    id_cbat_categoria     integer    not null,
    id_faixa              integer    not null,
    data_evento           date       not null,
    percurso              numeric    not null,
    sexo                  varchar(1) not null,
    tempo_total           time,
    idade_range           int4range,
    id_usuario            integer,
    id_atleta_strava      integer,
    pcd                   boolean default false,
    evento_homologado     boolean default true,
    resultado_homologado  boolean default true,
    ranking_evento        varchar
);

alter table tbbi_fat_perfil_br_2025
    owner to runner_dba;

grant insert, select, update on tbbi_fat_perfil_br_2025 to runner;

create table tb_resultados_logs
(
    log_id           bigserial
        primary key,
    trace_id         uuid                                                                     not null,
    run_id           uuid                                                                     not null,
    cod_evento       varchar                                                                  not null,
    percurso         varchar,
    num_peito        varchar,
    service_name     varchar                  default 'resultados-service'::character varying not null,
    service_version  varchar                  default '1.0.0'::character varying              not null,
    environment      varchar                  default 'prod'::character varying               not null,
    severity         varchar                                                                  not null,
    processing_stage varchar                                                                  not null,
    error_code       varchar,
    rule_version     varchar                  default 'v1'::character varying,
    event_timestamp  timestamp with time zone default now()                                   not null,
    payload          jsonb,
    constraint uq_log_idempotente
        unique (cod_evento, percurso, num_peito, severity, processing_stage)
);

alter table tb_resultados_logs
    owner to runner_dba;

create index idx_logs_evento
    on tb_resultados_logs (cod_evento);

create index idx_logs_trace
    on tb_resultados_logs (trace_id);

create index idx_logs_severity
    on tb_resultados_logs (severity);

create index idx_logs_timestamp
    on tb_resultados_logs (event_timestamp);

create index idx_logs_payload_gin
    on tb_resultados_logs using gin (payload);

grant insert, select, update on tb_resultados_logs to runner;

create table pimenta_tb_rs_temp
(
    id_resultado            serial,
    num_peito               varchar,
    nome                    varchar,
    categoria               varchar,
    id_evento               varchar,
    modalidade              varchar,
    pace                    varchar,
    percurso                varchar,
    sexo                    varchar,
    tempo_bruto             varchar,
    tempo_total             varchar,
    classificacao_categoria varchar,
    classificacao_sexo      varchar,
    classificacao_total     varchar,
    velocidade_media        varchar,
    equipe                  varchar,
    chave_processamento     uuid,
    data_nascimento         varchar,
    nacionalidade           varchar,
    hora_largada            varchar,
    np                      varchar,
    id_usuario              integer,
    status_final            varchar
);

alter table pimenta_tb_rs_temp
    owner to runner_dba;

grant select, update, usage on sequence pimenta_tb_rs_temp_id_resultado_seq to runner;

create index pimenta_tb_rs_temp_id_evento_index
    on pimenta_tb_rs_temp (id_evento);

create index pimenta_tb_rs_temp_num_peito_id_evento_index
    on pimenta_tb_rs_temp (num_peito, id_evento);

grant delete, insert, select, update on pimenta_tb_rs_temp to runner;

create table tb_busca_ia_cache
(
    id_cache     bigserial
        primary key,
    termo_busca  varchar(255)                                   not null,
    filtros_json jsonb                                          not null,
    criado_em    timestamp default now()                        not null,
    expira_em    timestamp default (now() + '7 days'::interval) not null
);

alter table tb_busca_ia_cache
    owner to runner_dba;

create index idx_tb_busca_ia_cache_termo
    on tb_busca_ia_cache (termo_busca);

create index idx_tb_busca_ia_cache_expira
    on tb_busca_ia_cache (expira_em);

grant insert, select, update on tb_busca_ia_cache to runner;

create table controle_backfill_nome
(
    id_lote            bigserial
        primary key,
    id_inicial         bigint                                                        not null,
    id_final           bigint                                                        not null,
    status             varchar(20)              default 'pending'::character varying not null,
    dt_criacao         timestamp with time zone default now()                        not null,
    dt_inicio          timestamp with time zone,
    dt_fim             timestamp with time zone,
    linhas_previstas   bigint,
    linhas_atualizadas bigint,
    tentativas         integer                  default 0                            not null,
    pid_worker         integer,
    erro               text
);

alter table controle_backfill_nome
    owner to runner_dba;

create index idx_controle_backfill_nome_status
    on controle_backfill_nome (status, id_lote);

create table tb_resultados_desvincular
(
    id_resultado_desvincular bigserial
        constraint tb_resultados_desvincular_pk
            primary key,
    id_resultado             bigint                  not null,
    id_usuario               bigint                  not null,
    data_registro            timestamp default now() not null
);

alter table tb_resultados_desvincular
    owner to runner_dba;

grant select, update, usage on sequence tb_resultados_desvincular_id_resultado_desvincular_seq to runner;

create unique index tb_resultados_desvincular_id_resultado_id_usuario_uindex
    on tb_resultados_desvincular (id_resultado, id_usuario);

grant insert, select, update on tb_resultados_desvincular to runner;

create table tb_runtrack_sessoes
(
    id_sessao           bigserial
        primary key,
    session_uuid        varchar(64)                                                    not null
        unique,
    event_id            integer                                                        not null
        references tb_evento_corridas,
    athlete_user_id     integer
        references tb_usuarios,
    external_session_id varchar(120),
    device_id           varchar(120),
    source_app          varchar(50)              default 'runtrack'::character varying not null,
    session_status      varchar(30)              default 'active'::character varying   not null,
    timezone            varchar(64),
    started_at          timestamp with time zone default now()                         not null,
    ended_at            timestamp with time zone,
    metadata            jsonb,
    created_at          timestamp with time zone default now()                         not null,
    updated_at          timestamp with time zone default now()                         not null,
    session_token       varchar(96),
    last_point_at       timestamp with time zone,
    total_points        integer                  default 0                             not null
);

alter table tb_runtrack_sessoes
    owner to runner_dba;

create index tb_runtrack_sessoes_event_idx
    on tb_runtrack_sessoes (event_id);

create index tb_runtrack_sessoes_athlete_idx
    on tb_runtrack_sessoes (athlete_user_id);

create index tb_runtrack_sessoes_status_idx
    on tb_runtrack_sessoes (session_status);

create index tb_runtrack_sessoes_event_status_idx
    on tb_runtrack_sessoes (event_id asc, session_status asc, updated_at desc);

create unique index tb_runtrack_sessoes_session_token_uq
    on tb_runtrack_sessoes (session_token)
    where (session_token IS NOT NULL);

create table tb_runtrack_pontos_gps
(
    id_ponto    bigserial
        primary key,
    id_sessao   bigint                                 not null
        references tb_runtrack_sessoes
            on delete cascade,
    recorded_at timestamp with time zone               not null,
    latitude    numeric(10, 7)                         not null,
    longitude   numeric(10, 7)                         not null,
    altitude_m  numeric(8, 2),
    accuracy_m  numeric(8, 2),
    speed_mps   numeric(8, 3),
    heading_deg numeric(6, 2),
    distance_m  numeric(10, 2),
    heart_rate  integer,
    payload     jsonb,
    created_at  timestamp with time zone default now() not null
);

alter table tb_runtrack_pontos_gps
    owner to runner_dba;

create unique index tb_runtrack_pontos_gps_dedupe_uq
    on tb_runtrack_pontos_gps (id_sessao, recorded_at, latitude, longitude);

create index tb_runtrack_pontos_gps_sessao_idx
    on tb_runtrack_pontos_gps (id_sessao, recorded_at);

create index tb_runtrack_pontos_gps_created_idx
    on tb_runtrack_pontos_gps (created_at desc);

create table tb_youtube_canais
(
    id_youtube_canal       serial
        primary key,
    code                   varchar(120)                                     not null
        unique,
    name                   varchar(255)                                     not null,
    source_type            varchar(20) default 'channel'::character varying not null
        constraint tb_youtube_canais_source_type_ck
            check ((source_type)::text = ANY
                   ((ARRAY ['channel'::character varying, 'playlist'::character varying])::text[])),
    channel_id             varchar(80),
    channel_handle         varchar(255),
    playlist_id            varchar(80),
    id_pagina              integer,
    id_usuario             integer,
    max_results            integer     default 3                            not null
        constraint tb_youtube_canais_max_results_ck
            check ((max_results >= 1) AND (max_results <= 50)),
    enabled                boolean     default true                         not null,
    sort_order             integer     default 0                            not null,
    created_at             timestamp   default now()                        not null,
    updated_at             timestamp   default now()                        not null,
    logotipo               text,
    descricao              text,
    instagram_url          text,
    logotipo_arquivo       bytea,
    logotipo_mime          varchar(120),
    logotipo_nome_arquivo  varchar(255),
    logotipo_atualizado_em timestamp,
    constraint tb_youtube_canais_source_data_ck
        check ((((source_type)::text = 'channel'::text) AND
                ((channel_id IS NOT NULL) OR (channel_handle IS NOT NULL))) OR
               (((source_type)::text = 'playlist'::text) AND (playlist_id IS NOT NULL)))
);

alter table tb_youtube_canais
    owner to runner_dba;

create index tb_youtube_canais_enabled_idx
    on tb_youtube_canais (enabled, sort_order, id_youtube_canal);

create table tb_evento_treinos_config
(
    id_treino_config            bigserial
        primary key,
    id_evento                   integer                 not null
        unique
        constraint tb_evento_treinos_config_tb_evento_corridas_id_evento_fk
            references tb_evento_corridas
            on update restrict on delete restrict,
    ativo                       boolean   default true  not null,
    data_abertura_inscricao     timestamp,
    data_encerramento_inscricao timestamp,
    limite_inscritos            integer,
    criado_em                   timestamp default now() not null,
    atualizado_em               timestamp default now() not null,
    id_evento_pai               integer
        constraint tb_evento_treinos_config_tb_evento_corridas_id_evento_fk2
            references tb_evento_corridas
            on update set null on delete set null
);

alter table tb_evento_treinos_config
    owner to runner_dba;

create index idx_tb_evento_treinos_config_evento
    on tb_evento_treinos_config (id_evento);

create table tb_helpdesk_setores
(
    id_setor               serial
        primary key,
    nome_setor             varchar(120)            not null,
    descricao_setor        text,
    id_usuario_responsavel integer
                                                   references tb_usuarios
                                                       on delete set null,
    ativo                  boolean   default true  not null,
    created_at             timestamp default now() not null,
    updated_at             timestamp default now() not null
);

alter table tb_helpdesk_setores
    owner to runner_dba;

create table tb_helpdesk_chamados
(
    id_chamado serial
        primary key,
    protocolo  varchar(40)                                     not null
        unique,
    id_usuario integer                                         not null
        references tb_usuarios
            on delete cascade,
    id_setor   integer                                         not null
        references tb_helpdesk_setores
            on delete restrict,
    assunto    varchar(180)                                    not null,
    status     varchar(40) default 'aberto'::character varying not null,
    created_at timestamp   default now()                       not null,
    updated_at timestamp   default now()                       not null
);

alter table tb_helpdesk_chamados
    owner to runner_dba;

create index idx_helpdesk_chamados_usuario
    on tb_helpdesk_chamados (id_usuario asc, updated_at desc);

create index idx_helpdesk_chamados_setor
    on tb_helpdesk_chamados (id_setor, status);

create table tb_helpdesk_mensagens
(
    id_mensagem serial
        primary key,
    id_chamado  integer                 not null
        references tb_helpdesk_chamados
            on delete cascade,
    id_usuario  integer                 not null
        references tb_usuarios
            on delete restrict,
    mensagem    text                    not null,
    interno     boolean   default false not null,
    created_at  timestamp default now() not null
);

alter table tb_helpdesk_mensagens
    owner to runner_dba;

create index idx_helpdesk_mensagens_chamado
    on tb_helpdesk_mensagens (id_chamado, created_at);

create table tb_push_subscription
(
    id_push_subscription bigserial
        primary key,
    id_usuario           integer                 not null,
    ambiente             varchar(16)             not null,
    endpoint             text                    not null,
    p256dh               varchar(512)            not null,
    auth                 varchar(512)            not null,
    subscription_json    jsonb                   not null,
    user_agent           text,
    device_label         varchar(120),
    ativo                boolean   default true  not null,
    granted_at           timestamp default now() not null,
    revoked_at           timestamp,
    last_seen_at         timestamp default now() not null,
    created_at           timestamp default now() not null,
    updated_at           timestamp default now() not null
);

alter table tb_push_subscription
    owner to runner_dba;

create unique index uq_tb_push_subscription_ambiente_endpoint
    on tb_push_subscription (ambiente, endpoint);

create index idx_tb_push_subscription_usuario_ativo
    on tb_push_subscription (id_usuario, ativo);

create index idx_tb_push_subscription_ambiente_ativo
    on tb_push_subscription (ambiente, ativo);

create table tb_push_preference
(
    id_usuario       integer                 not null
        primary key,
    receber_push     boolean   default true  not null,
    push_resultados  boolean   default true  not null,
    push_desafios    boolean   default true  not null,
    push_atendimento boolean   default true  not null,
    push_sistema     boolean   default true  not null,
    updated_at       timestamp default now() not null
);

alter table tb_push_preference
    owner to runner_dba;

create table tb_leaderboard_config
(
    id_leaderboard_config serial
        primary key,
    id_evento             integer                 not null
        unique
        references tb_evento_corridas
            on update cascade on delete cascade,
    titulo                varchar,
    ativo                 boolean   default true  not null,
    data_inicio           date,
    data_fim              date,
    observacoes           text,
    data_inclusao         timestamp default now() not null,
    data_atualizacao      timestamp default now() not null,
    youtube_video_id      varchar
);

alter table tb_leaderboard_config
    owner to runner_dba;

grant select, usage on sequence tb_leaderboard_config_id_leaderboard_config_seq to runner;

create index tb_leaderboard_config_ativo_datas_idx
    on tb_leaderboard_config (ativo, data_inicio, data_fim);

create index tb_leaderboard_config_id_evento_idx
    on tb_leaderboard_config (id_evento);

grant delete, insert, select, update on tb_leaderboard_config to runner;

create table tb_leaderboard_percurso
(
    id_leaderboard_percurso serial
        primary key,
    id_evento               integer                 not null
        references tb_evento_corridas
            on update cascade on delete cascade,
    percurso                numeric                 not null,
    titulo                  varchar,
    ativo                   boolean   default true  not null,
    limite_parcial          integer   default 5     not null,
    limite_final            integer   default 10    not null,
    data_inclusao           timestamp default now() not null,
    data_atualizacao        timestamp default now() not null,
    unidade_de_medida       varchar,
    rp_m                    time,
    rp_f                    time,
    unique (id_evento, percurso)
);

alter table tb_leaderboard_percurso
    owner to runner_dba;

grant select, usage on sequence tb_leaderboard_percurso_id_leaderboard_percurso_seq to runner;

create index tb_leaderboard_percurso_id_evento_idx
    on tb_leaderboard_percurso (id_evento, ativo, percurso);

create unique index tb_leaderboard_percurso_id_evento_percurso_uidx
    on tb_leaderboard_percurso (id_evento, percurso);

grant delete, insert, select, update on tb_leaderboard_percurso to runner;

create table tb_leaderboard_startlist
(
    id_startlist      serial
        primary key,
    id_evento         integer                                       not null
        references tb_evento_corridas
            on update cascade on delete cascade,
    percurso          numeric                                       not null,
    num_peito         integer                                       not null,
    nome              varchar,
    sexo              varchar,
    categoria         varchar,
    modalidade        varchar,
    nacionalidade     varchar,
    equipe            varchar,
    id_usuario        integer,
    data_nascimento   varchar,
    hora_largada      varchar,
    status_final      varchar,
    id_resultado_temp integer,
    origem            varchar   default 'manual'::character varying not null,
    data_inclusao     timestamp default now()                       not null,
    data_atualizacao  timestamp default now()                       not null,
    unique (id_evento, percurso, num_peito),
    constraint tb_leaderboard_startlist_evento_percurso_fk
        foreign key (id_evento, percurso) references tb_evento_corridas_percursos (id_evento, percurso_evento)
            on update cascade on delete cascade
);

alter table tb_leaderboard_startlist
    owner to runner_dba;

grant select, usage on sequence tb_leaderboard_startlist_id_startlist_seq to runner;

create index tb_leaderboard_startlist_evento_percurso_sexo_idx
    on tb_leaderboard_startlist (id_evento, percurso, sexo);

create index tb_leaderboard_startlist_id_usuario_idx
    on tb_leaderboard_startlist (id_usuario);

create index tb_leaderboard_startlist_num_peito_evento_idx
    on tb_leaderboard_startlist (num_peito, id_evento);

grant delete, insert, select, update on tb_leaderboard_startlist to runner;

grant select on tb_leaderboard_startlist to liverunners_dba;

create table ads.tb_portal_banners
(
    id_banner         serial
        primary key,
    nome              varchar(160)                                     not null,
    canal             varchar(80)                                      not null,
    local_layout      varchar(80)                                      not null,
    tamanho_nome      varchar(80),
    largura           integer,
    altura            integer,
    formato           varchar(16),
    alt_text          varchar(255),
    arquivo_path      varchar(255)                                     not null,
    arquivo_original  varchar(255),
    link_destino      varchar(500)                                     not null,
    link_tipo         varchar(20) default 'interno'::character varying not null,
    abrir_nova_aba    boolean     default false                        not null,
    peso_exibicao     integer     default 1                            not null,
    prioridade        integer     default 1                            not null,
    limite_impressoes integer,
    limite_cliques    integer,
    limite_diario     integer,
    inicio_exibicao   timestamp,
    fim_exibicao      timestamp,
    status            integer     default 2                            not null,
    observacoes       text,
    criado_em         timestamp   default now()                        not null,
    atualizado_em     timestamp   default now()                        not null,
    criado_por        integer,
    atualizado_por    integer
);

alter table ads.tb_portal_banners
    owner to runner_dba;

create index tb_portal_banners_lookup_idx
    on ads.tb_portal_banners (canal, local_layout, status);

create index tb_portal_banners_periodo_idx
    on ads.tb_portal_banners (inicio_exibicao, fim_exibicao);

create table ads.tb_portal_banners_log
(
    id_banner_log  bigserial
        primary key,
    id_banner      integer                 not null
        references ads.tb_portal_banners
            on delete cascade,
    tipo_evento    varchar(20)             not null,
    canal          varchar(80),
    local_layout   varchar(80),
    host_origem    varchar(255),
    caminho_origem varchar(500),
    origem_site    varchar(255),
    id_usuario     integer,
    ip_address     varchar(64),
    user_agent     text,
    request_data   jsonb,
    criado_em      timestamp default now() not null
);

alter table ads.tb_portal_banners_log
    owner to runner_dba;

create index tb_portal_banners_log_banner_idx
    on ads.tb_portal_banners_log (id_banner asc, tipo_evento asc, criado_em desc);

create index tb_portal_banners_log_slot_idx
    on ads.tb_portal_banners_log (canal asc, local_layout asc, tipo_evento asc, criado_em desc);

create table tb_crawlers
(
    id_crawler              bigserial
        primary key,
    nome_crawler            varchar(160)                                                    not null,
    site                    varchar(255),
    area                    varchar(30)                                                     not null
        constraint tb_crawlers_area_chk
            check ((area)::text = ANY
                   ((ARRAY ['evento'::character varying, 'resultado'::character varying, 'link_resultado'::character varying, 'mapeamento'::character varying])::text[])),
    nome_arquivo            varchar(255)                                                    not null
        unique,
    status                  varchar(30)              default 'Verificar'::character varying not null
        constraint tb_crawlers_status_chk
            check ((status)::text = ANY
                   ((ARRAY ['Manual'::character varying, 'Validado'::character varying, 'Verificar'::character varying, 'Em construção'::character varying, 'Erro'::character varying])::text[])),
    observacao              text,
    site_url                text,
    cobertura               text,
    run_semanal             boolean                  default false                          not null,
    cron_habilitado         boolean                  default false                          not null,
    cron_dia_semana         smallint
        constraint tb_crawlers_cron_dia_semana_chk
            check ((cron_dia_semana IS NULL) OR ((cron_dia_semana >= 0) AND (cron_dia_semana <= 6))),
    cron_hora               time,
    ultimo_webhook_salvo    text,
    ultimo_log              text,
    ultima_execucao_em      timestamp with time zone,
    ultima_execucao_sucesso boolean,
    ultima_duracao_ms       integer                  default 0                              not null,
    total_execucoes         integer                  default 0                              not null,
    created_at              timestamp with time zone default now()                          not null,
    updated_at              timestamp with time zone default now()                          not null
);

alter table tb_crawlers
    owner to runner_dba;

create index tb_crawlers_area_idx
    on tb_crawlers (area);

create index tb_crawlers_status_idx
    on tb_crawlers (status);

create index tb_crawlers_run_semanal_idx
    on tb_crawlers (run_semanal);

create index tb_crawlers_ultima_execucao_em_idx
    on tb_crawlers (ultima_execucao_em desc);

create table tb_crawlers_execucoes
(
    id_execucao   bigserial
        primary key,
    id_crawler    bigint                                 not null
        constraint tb_crawlers_execucoes_crawler_fk
            references tb_crawlers
            on delete cascade,
    data_execucao timestamp with time zone default now() not null,
    sucesso       boolean                  default false not null,
    duracao_ms    integer                  default 0     not null,
    total_itens   integer                  default 0     not null,
    log_execucao  text,
    webhook_salvo text,
    observacao    text,
    area          varchar(30)                            not null
);

alter table tb_crawlers_execucoes
    owner to runner_dba;

create index tb_crawlers_execucoes_id_crawler_idx
    on tb_crawlers_execucoes (id_crawler);

create index tb_crawlers_execucoes_data_execucao_idx
    on tb_crawlers_execucoes (data_execucao desc);

create index tb_crawlers_execucoes_area_idx
    on tb_crawlers_execucoes (area);

create table tb_financeiro_indicadores
(
    id_indicador         serial
        primary key,
    codigo_indicador     varchar(80)                                         not null
        unique,
    grupo_slug           varchar(60)                                         not null,
    grupo_nome           varchar(120)                                        not null,
    nome_indicador       varchar(140)                                        not null,
    tipo_unidade         varchar(30) default 'percentual'::character varying not null
        constraint ck_tb_financeiro_indicadores_tipo_unidade
            check ((tipo_unidade)::text = ANY
                   ((ARRAY ['percentual'::character varying, 'multiplo'::character varying, 'moeda'::character varying, 'numero'::character varying])::text[])),
    formula_resumida     varchar(500),
    componentes_formula  varchar(500),
    descricao_indicador  text,
    bom_quando           text,
    fonte_valor          varchar(180),
    faixa_otima_min      numeric,
    faixa_otima_max      numeric,
    faixa_ok_min         numeric,
    faixa_ok_max         numeric,
    ordem_exibicao       integer     default 0                               not null,
    ativo                boolean     default true                            not null,
    atualizado_em        timestamp   default now()                           not null,
    criado_em            timestamp   default now()                           not null,
    periodicidade_padrao varchar(30) default 'anual'::character varying      not null,
    permite_valor_final  boolean     default true                            not null,
    usa_componentes      boolean     default false                           not null,
    casas_decimais       integer     default 2                               not null
        constraint ck_tb_financeiro_indicadores_casas_decimais
            check ((casas_decimais >= 0) AND (casas_decimais <= 6))
);

alter table tb_financeiro_indicadores
    owner to runner_dba;

create index idx_tb_financeiro_indicadores_grupo
    on tb_financeiro_indicadores (grupo_slug, ordem_exibicao);

create table tb_financeiro_valores
(
    id_valor        serial
        primary key,
    id_indicador    integer                                        not null
        references tb_financeiro_indicadores,
    periodo_tipo    varchar(30) default 'anual'::character varying not null,
    periodo_label   varchar(120),
    referencia_data date,
    valor_calculado numeric,
    notas           text,
    atualizado_por  varchar(180),
    atualizado_em   timestamp   default now()                      not null
);

alter table tb_financeiro_valores
    owner to runner_dba;

create index idx_tb_financeiro_valores_indicador_data
    on tb_financeiro_valores (id_indicador asc, referencia_data desc, atualizado_em desc);

create index idx_tb_financeiro_valores_indicador
    on tb_financeiro_valores (id_indicador asc, id_valor desc);

create table tb_financeiro_presets
(
    id_preset         serial
        primary key,
    slug_preset       varchar(80)             not null
        unique,
    nome_preset       varchar(120)            not null,
    perfil_alvo       varchar(80),
    descricao_preset  text,
    insight_preset    text,
    indicadores_chave varchar(500),
    ordem_exibicao    integer   default 0     not null,
    ativo             boolean   default true  not null,
    criado_em         timestamp default now() not null
);

alter table tb_financeiro_presets
    owner to runner_dba;

create index idx_tb_financeiro_presets_ordem
    on tb_financeiro_presets (ordem_exibicao, slug_preset);

create table tb_financeiro_valor_componentes
(
    id_valor_componente serial
        primary key,
    id_valor            integer                 not null
        references tb_financeiro_valores
            on delete cascade,
    id_indicador        integer                 not null
        references tb_financeiro_indicadores,
    nome_componente     varchar(180)            not null,
    valor_componente    numeric,
    ordem_exibicao      integer   default 0     not null,
    criado_em           timestamp default now() not null
);

alter table tb_financeiro_valor_componentes
    owner to runner_dba;

create index idx_tb_financeiro_valor_componentes_indicador
    on tb_financeiro_valor_componentes (id_indicador, id_valor, ordem_exibicao);

create table tb_portal_runner_app_groups
(
    id_group      serial
        primary key,
    nome          varchar(120)            not null,
    descricao     text,
    ordem         integer   default 1     not null,
    ativo         boolean   default true  not null,
    criado_em     timestamp default now() not null,
    atualizado_em timestamp default now() not null
);

alter table tb_portal_runner_app_groups
    owner to runner_dba;

create index tb_portal_runner_app_groups_ordem_idx
    on tb_portal_runner_app_groups (ativo, ordem, id_group);

create table tb_portal_runner_apps
(
    id_app          serial
        primary key,
    id_group        integer                 not null
        references tb_portal_runner_app_groups
            on delete restrict,
    nome            varchar(120)            not null,
    url             text                    not null,
    imagem_url      text                    not null,
    imagem_original varchar(255),
    alt_text        varchar(180),
    abrir_nova_aba  boolean   default false not null,
    rel             varchar(120),
    ordem           integer   default 1     not null,
    ativo           boolean   default true  not null,
    criado_em       timestamp default now() not null,
    atualizado_em   timestamp default now() not null
);

alter table tb_portal_runner_apps
    owner to runner_dba;

create index tb_portal_runner_apps_group_ordem_idx
    on tb_portal_runner_apps (id_group, ativo, ordem, id_app);

create table tb_busca_log
(
    id_busca_log        bigserial
        primary key,
    id_busca_log_parent bigint
        references tb_busca_log,
    log_timestamp       timestamp default now()                   not null,
    site                varchar   default 'CT'::character varying not null,
    ambiente            varchar(32),
    origem              varchar(96),
    etapa               varchar(32),
    busca_modo          varchar(32),
    busca_tipo          varchar(32),
    busca_scope         varchar(32),
    tipo_termo          varchar(32),
    termo_original      varchar,
    termo_livre         varchar,
    modelo              varchar(120),
    usou_ia             boolean   default false                   not null,
    fallback_usado      boolean   default false                   not null,
    fallback_motivo     varchar(96),
    erro                text,
    http_status         varchar(64),
    id_usuario          integer,
    id_pagina           integer,
    usuario_verificado  boolean   default false                   not null,
    ip                  varchar(64),
    user_agent          varchar,
    filtros_json        jsonb     default '{}'::jsonb             not null,
    contagens_json      jsonb     default '{}'::jsonb             not null,
    request_json        jsonb     default '{}'::jsonb             not null,
    ia_json             jsonb     default '{}'::jsonb             not null,
    payload_json        jsonb     default '{}'::jsonb             not null
);

alter table tb_busca_log
    owner to runner_dba;

grant select, update, usage on sequence tb_busca_log_id_busca_log_seq to runner;

create index idx_tb_busca_log_timestamp
    on tb_busca_log (log_timestamp desc);

create index idx_tb_busca_log_parent
    on tb_busca_log (id_busca_log_parent);

create index idx_tb_busca_log_tipo
    on tb_busca_log (busca_tipo, busca_scope, etapa);

create index idx_tb_busca_log_usuario
    on tb_busca_log (id_usuario asc, log_timestamp desc);

create index idx_tb_busca_log_termo
    on tb_busca_log using gin (to_tsvector('simple'::regconfig, COALESCE(termo_original, ''::character varying)::text));

create index idx_tb_busca_log_filtros_json
    on tb_busca_log using gin (filtros_json);

create index idx_tb_busca_log_payload_json
    on tb_busca_log using gin (payload_json);

grant insert, select, update on tb_busca_log to runner;

create table tb_resultados_usuario_142x
(
    id_resultado            integer,
    num_peito               integer,
    nome                    text,
    data_nascimento         date,
    id_evento               integer,
    modalidade              text,
    pace                    time,
    percurso                integer,
    sexo                    text,
    tempo_bruto             time,
    tempo_total             time,
    classificacao_categoria integer,
    classificacao_sexo      integer,
    classificacao_total     integer,
    velocidade_media        integer,
    equipe                  text,
    nome_categoria          text,
    id_usuario              integer,
    id_categoria            integer,
    homologado              boolean,
    concluinte              boolean,
    chave_processamento     uuid,
    chave_verificacao       uuid,
    nacionalidade           text,
    status_final            integer,
    hora_largada            time,
    tempo_f1_categoria      time,
    tempo_f1_sexo           time,
    tempo_f1_total          time,
    posicao_ranking         integer,
    classificacao_pais      integer,
    pcd                     boolean,
    nome_full_text          tsvector,
    idade_range             int4range,
    nome_normalizado        text
);

alter table tb_resultados_usuario_142x
    owner to runner_dba;

create table tb_contas
(
    id_conta           bigserial
        primary key,
    nome_conta         varchar(160)                                              not null,
    tipo_titular       tipo_titular_conta                                        not null,
    documento          varchar(20)                                               not null
        constraint unq_tb_contas_documento
            unique,
    nome_titular       varchar(200)                                              not null,
    email_principal    varchar(255),
    telefone_principal varchar(30),
    status             status_conta             default 'PENDENTE'::status_conta not null,
    data_criacao       timestamp with time zone default now()                    not null,
    data_atualizacao   timestamp with time zone default now()                    not null
);

alter table tb_contas
    owner to runner_dba;

grant select, usage on sequence tb_contas_id_conta_seq to runner;

grant delete, insert, references, select, trigger, truncate, update on tb_contas to runner;

create table tb_conta_usuarios
(
    id_conta_usuario bigserial
        primary key,
    id_conta         bigint                                                             not null
        constraint fk_conta_usuarios_conta
            references tb_contas
            on delete cascade,
    id_usuario       bigint                                                             not null
        constraint fk_conta_usuarios_usuario
            references tb_usuarios
            on delete cascade,
    papel            papel_usuario_conta      default 'OPERADOR'::papel_usuario_conta   not null,
    status           status_usuario_conta     default 'CONVIDADO'::status_usuario_conta not null,
    usuario_convite  bigint
        constraint fk_conta_usuarios_convite
            references tb_usuarios,
    data_convite     timestamp with time zone,
    data_aceite      timestamp with time zone,
    data_criacao     timestamp with time zone default now()                             not null,
    data_atualizacao timestamp with time zone default now()                             not null,
    constraint uq_tb_conta_usuarios
        unique (id_conta, id_usuario)
);

alter table tb_conta_usuarios
    owner to runner_dba;

grant select, usage on sequence tb_conta_usuarios_id_conta_usuario_seq to runner;

grant delete, insert, references, select, trigger, truncate, update on tb_conta_usuarios to runner;

create table tb_conta_eventos
(
    id_conta_evento  bigserial
        primary key,
    id_conta         bigint                                                        not null
        constraint fk_conta_eventos_conta
            references tb_contas
            on delete cascade,
    id_evento        integer                                                       not null
        constraint fk_conta_eventos_evento
            references tb_evento_corridas
            on delete cascade,
    status           status_conta_evento      default 'ATIVO'::status_conta_evento not null,
    usuario_cadastro bigint
        constraint fk_conta_eventos_usuario_cadastro
            references tb_usuarios
            on delete restrict,
    data_criacao     timestamp with time zone default now()                        not null,
    data_atualizacao timestamp with time zone default now()                        not null,
    constraint uq_tb_conta_eventos
        unique (id_conta, id_evento)
);

alter table tb_conta_eventos
    owner to runner_dba;

grant select, usage on sequence tb_conta_eventos_id_conta_evento_seq to runner;

grant delete, insert, references, select, trigger, truncate, update on tb_conta_eventos to runner;

create table tb_conta_evento_solicitacoes
(
    id_solicitacao         bigserial
        primary key,
    id_conta               bigint                                                         not null
        references tb_contas,
    id_evento              integer                                                        not null
        references tb_evento_corridas,
    id_usuario_solicitante bigint
        references tb_usuarios,
    url_informada          varchar(512),
    tag_informada          varchar(512),
    mensagem               text,
    status                 varchar(20)              default 'PENDENTE'::character varying not null,
    id_usuario_revisor     bigint
        references tb_usuarios,
    observacao_revisor     text,
    data_criacao           timestamp with time zone default now()                         not null,
    data_revisao           timestamp with time zone
);

alter table tb_conta_evento_solicitacoes
    owner to runner_dba;

grant select, usage on sequence tb_conta_evento_solicitacoes_id_solicitacao_seq to runner;

grant delete, insert, references, select, trigger, truncate, update on tb_conta_evento_solicitacoes to runner;

create table tb_conta_cadastro_solicitacoes
(
    id_solicitacao       bigserial
        primary key,
    nome_empresa         varchar(160)                                                                            not null,
    tipo_titular         tipo_titular_conta                                                                      not null,
    documento            varchar(20)                                                                             not null,
    nome_responsavel     varchar(200)                                                                            not null,
    email_responsavel    varchar(255)                                                                            not null,
    telefone_responsavel varchar(30),
    site                 varchar(256),
    cidade               varchar(128),
    estado               varchar(2),
    tipo_prestador       varchar(80)                                                                             not null,
    mensagem             text,
    id_usuario           bigint
        constraint fk_conta_cadastro_solicitacoes_usuario
            references tb_usuarios,
    id_conta             bigint
        constraint fk_conta_cadastro_solicitacoes_conta
            references tb_contas,
    status               status_conta_cadastro_solicitacao default 'PENDENTE'::status_conta_cadastro_solicitacao not null,
    id_usuario_revisor   bigint
        constraint fk_conta_cadastro_solicitacoes_revisor
            references tb_usuarios,
    observacao_revisor   text,
    data_criacao         timestamp with time zone          default now()                                         not null,
    data_revisao         timestamp with time zone
);

alter table tb_conta_cadastro_solicitacoes
    owner to runner_dba;

grant select, usage on sequence tb_conta_cadastro_solicitacoes_id_solicitacao_seq to runner;

create index idx_tb_conta_cadastro_solicitacoes_status
    on tb_conta_cadastro_solicitacoes (status, data_criacao);

create index idx_tb_conta_cadastro_solicitacoes_documento
    on tb_conta_cadastro_solicitacoes (documento);

create index idx_tb_conta_cadastro_solicitacoes_email
    on tb_conta_cadastro_solicitacoes (email_responsavel);

grant insert, select, update on tb_conta_cadastro_solicitacoes to runner;

create materialized view vw_resultados_resumo_2025 as
WITH tot AS (
         SELECT tb_resultados.id_evento,
            tb_resultados.percurso,
            tb_resultados.modalidade,
            count(*) AS tot_atletas
           FROM tb_resultados
          GROUP BY tb_resultados.id_evento, tb_resultados.percurso, tb_resultados.modalidade
        )
 SELECT res.id_evento,
    res.percurso,
    res.modalidade,
    count(*) FILTER (WHERE res.homologado = true AND res.concluinte = true AND res.status_final = 0) AS concluintes,
    count(*) AS inscritos,
    min(res.pace) FILTER (WHERE res.homologado = true AND res.concluinte = true AND res.status_final = 0 AND res.pace IS NOT NULL) AS pace_menor,
    avg(res.pace::interval) FILTER (WHERE res.homologado = true AND res.concluinte = true AND res.status_final = 0 AND res.pace IS NOT NULL) AS pace_medio,
    max(res.pace) FILTER (WHERE res.homologado = true AND res.concluinte = true AND res.status_final = 0 AND res.pace IS NOT NULL) AS pace_maior,
    avg(res.pace::interval) FILTER (WHERE res.homologado = true AND res.concluinte = true AND res.status_final = 0 AND res.pace IS NOT NULL AND (res.classificacao_total <= 10::numeric OR res.classificacao_sexo <= 10::numeric)) AS pace_medio_top_10,
    avg(res.pace::interval) FILTER (WHERE res.homologado = true AND res.concluinte = true AND res.status_final = 0 AND res.pace IS NOT NULL AND (res.classificacao_total <= 100::numeric OR res.classificacao_sexo <= 100::numeric)) AS pace_medio_top_100,
    avg(res.pace::interval) FILTER (WHERE res.homologado = true AND res.concluinte = true AND res.status_final = 0 AND res.pace IS NOT NULL AND (res.classificacao_total <= (tot.tot_atletas::numeric * 0.05) OR res.classificacao_sexo <= (tot.tot_atletas::numeric * 0.05))) AS pace_medio_5_porcento,
    avg(res.pace::interval) FILTER (WHERE res.homologado = true AND res.concluinte = true AND res.status_final = 0 AND res.pace IS NOT NULL AND (res.classificacao_total <= (tot.tot_atletas::numeric * 0.10) OR res.classificacao_sexo <= (tot.tot_atletas::numeric * 0.10))) AS pace_medio_10_porcento,
    avg(res.pace::interval) FILTER (WHERE res.homologado = true AND res.concluinte = true AND res.status_final = 0 AND res.pace IS NOT NULL AND (res.classificacao_total <= (tot.tot_atletas::numeric * 0.50) OR res.classificacao_sexo <= (tot.tot_atletas::numeric * 0.50))) AS pace_medio_50_porcento,
    ( SELECT tb_resultados_resumo_limites.limite_a
           FROM tb_resultados_resumo_limites
          WHERE tb_resultados_resumo_limites.percurso::numeric = res.percurso AND (tb_resultados_resumo_limites.id_evento = res.id_evento OR tb_resultados_resumo_limites.id_evento IS NULL)
          ORDER BY (
                CASE
                    WHEN tb_resultados_resumo_limites.id_evento IS NULL THEN 1
                    ELSE 0
                END)
         LIMIT 1) AS limite_a,
    count(*) FILTER (WHERE res.homologado = true AND res.concluinte = true AND res.status_final = 0 AND res.tempo_total < (( SELECT tb_resultados_resumo_limites.limite_a
           FROM tb_resultados_resumo_limites
          WHERE tb_resultados_resumo_limites.percurso::numeric = res.percurso AND (tb_resultados_resumo_limites.id_evento = res.id_evento OR tb_resultados_resumo_limites.id_evento IS NULL)))) AS limite_a_concluintes,
    ( SELECT tb_resultados_resumo_limites.limite_b
           FROM tb_resultados_resumo_limites
          WHERE tb_resultados_resumo_limites.percurso::numeric = res.percurso AND (tb_resultados_resumo_limites.id_evento = res.id_evento OR tb_resultados_resumo_limites.id_evento IS NULL)
          ORDER BY (
                CASE
                    WHEN tb_resultados_resumo_limites.id_evento IS NULL THEN 1
                    ELSE 0
                END)
         LIMIT 1) AS limite_b,
    count(*) FILTER (WHERE res.homologado = true AND res.concluinte = true AND res.status_final = 0 AND res.tempo_total < (( SELECT tb_resultados_resumo_limites.limite_b
           FROM tb_resultados_resumo_limites
          WHERE tb_resultados_resumo_limites.percurso::numeric = res.percurso AND (tb_resultados_resumo_limites.id_evento = res.id_evento OR tb_resultados_resumo_limites.id_evento IS NULL)))) AS limite_b_concluintes,
    ( SELECT tb_resultados_resumo_limites.limite_elite
           FROM tb_resultados_resumo_limites
          WHERE tb_resultados_resumo_limites.percurso::numeric = res.percurso AND (tb_resultados_resumo_limites.id_evento = res.id_evento OR tb_resultados_resumo_limites.id_evento IS NULL)
          ORDER BY (
                CASE
                    WHEN tb_resultados_resumo_limites.id_evento IS NULL THEN 1
                    ELSE 0
                END)
         LIMIT 1) AS limite_elite,
    count(*) FILTER (WHERE res.homologado = true AND res.concluinte = true AND res.status_final = 0 AND res.tempo_total < (( SELECT tb_resultados_resumo_limites.limite_elite
           FROM tb_resultados_resumo_limites
          WHERE tb_resultados_resumo_limites.percurso::numeric = res.percurso AND (tb_resultados_resumo_limites.id_evento = res.id_evento OR tb_resultados_resumo_limites.id_evento IS NULL)))) AS limite_elite_concluintes,
    percentile_cont(0.5::double precision) WITHIN GROUP (ORDER BY (res.pace::interval)) FILTER (WHERE res.homologado = true AND res.concluinte = true AND res.status_final = 0 AND res.pace IS NOT NULL) AS percentil,
    ( SELECT percentile_cont(0.5::double precision) WITHIN GROUP (ORDER BY (ris.pace::interval)) AS percentile_cont
           FROM tb_resultados ris
          WHERE ris.id_evento = res.id_evento AND ris.percurso = res.percurso AND ris.modalidade::text = res.modalidade::text AND ris.pace::interval >= (( SELECT percentile_cont(0.1::double precision) WITHIN GROUP (ORDER BY (r1.pace::interval)) AS percentile_cont
                   FROM tb_resultados r1
                  WHERE r1.id_evento = res.id_evento AND r1.percurso = res.percurso AND r1.modalidade::text = res.modalidade::text)) AND ris.pace::interval <= (( SELECT percentile_cont(0.7::double precision) WITHIN GROUP (ORDER BY (r1.pace::interval)) AS percentile_cont
                   FROM tb_resultados r1
                  WHERE r1.id_evento = res.id_evento AND r1.percurso = res.percurso AND r1.modalidade::text = res.modalidade::text))) AS percentil_sem_desvio
   FROM tb_resultados res
     JOIN tot ON tot.id_evento = res.id_evento AND tot.percurso = res.percurso AND tot.modalidade::text = res.modalidade::text
  GROUP BY res.id_evento, res.percurso, res.modalidade;

alter materialized view vw_resultados_resumo_2025 owner to runner_dba;

grant insert, select, update on vw_resultados_resumo_2025 to runner;

create materialized view vwbi_fat_perfil_br_2025_treinos as
WITH desafio_365 AS (
         SELECT des_1.id_usuario,
            usu.strava_id,
                CASE
                    WHEN des_1.dias_corridos = 365 THEN 'Finalizou'::text
                    WHEN des_1.dias_corridos > 0 THEN 'Participou'::text
                    ELSE NULL::text
                END AS desafio_365
           FROM tb_usuarios usu
             JOIN vw_desafio_365_final des_1 ON des_1.id_usuario = usu.id
        )
 SELECT COALESCE(act.activity_date::timestamp without time zone, act.start_date)::date AS data_treino,
    act.athlete_id AS id_atleta_strava,
    des.id_usuario,
    act.type AS tipo_treino,
    round((act.distance / 1000::double precision)::numeric, 2) AS distancia_treino,
    des.desafio_365,
    dda.id_data,
    dda.data_referencia,
    dda.ano,
    dda.mes,
    dda.mes_extenso,
    dda.dia,
    dda.dia_do_ano,
    dda.dia_da_semana,
    dda.semana_calendario,
    dda.data_formatada,
    dda.trimestre,
    dda.trimestre_ano,
    dda.mes_ano,
    dda.ano_semana_calendario,
    dda.tipo_dia_semana,
    dda.feriado_nacional,
    dda.calendario_inicio_semana,
    dda.calendario_final_semana
   FROM tb_strava_activities act
     LEFT JOIN desafio_365 des ON des.strava_id = act.athlete_id
     JOIN tbbi_dim_data dda ON dda.data_referencia = COALESCE(act.activity_date::timestamp without time zone, act.start_date)::date
  WHERE COALESCE(act.activity_date::timestamp without time zone, act.start_date)::date >= '2025-01-01'::date AND COALESCE(act.activity_date::timestamp without time zone, act.start_date)::date <= '2025-12-31'::date
  ORDER BY (COALESCE(act.activity_date::timestamp without time zone, act.start_date)::date);

alter materialized view vwbi_fat_perfil_br_2025_treinos owner to runner_dba;

grant select on vwbi_fat_perfil_br_2025_treinos to akkio_user;

create view pg_stat_statements_info(dealloc, stats_reset) as
SELECT dealloc,
    stats_reset
   FROM pg_stat_statements_info() pg_stat_statements_info(dealloc, stats_reset);

alter table pg_stat_statements_info
    owner to postgres;

grant select on pg_stat_statements_info to public;

grant insert, select, update on pg_stat_statements_info to runner;

create view pg_stat_statements
            (userid, dbid, toplevel, queryid, query, plans, total_plan_time, min_plan_time, max_plan_time,
             mean_plan_time, stddev_plan_time, calls, total_exec_time, min_exec_time, max_exec_time, mean_exec_time,
             stddev_exec_time, rows, shared_blks_hit, shared_blks_read, shared_blks_dirtied, shared_blks_written,
             local_blks_hit, local_blks_read, local_blks_dirtied, local_blks_written, temp_blks_read, temp_blks_written,
             shared_blk_read_time, shared_blk_write_time, local_blk_read_time, local_blk_write_time, temp_blk_read_time,
             temp_blk_write_time, wal_records, wal_fpi, wal_bytes, jit_functions, jit_generation_time,
             jit_inlining_count, jit_inlining_time, jit_optimization_count, jit_optimization_time, jit_emission_count,
             jit_emission_time, jit_deform_count, jit_deform_time, stats_since, minmax_stats_since)
as
SELECT userid,
    dbid,
    toplevel,
    queryid,
    query,
    plans,
    total_plan_time,
    min_plan_time,
    max_plan_time,
    mean_plan_time,
    stddev_plan_time,
    calls,
    total_exec_time,
    min_exec_time,
    max_exec_time,
    mean_exec_time,
    stddev_exec_time,
    rows,
    shared_blks_hit,
    shared_blks_read,
    shared_blks_dirtied,
    shared_blks_written,
    local_blks_hit,
    local_blks_read,
    local_blks_dirtied,
    local_blks_written,
    temp_blks_read,
    temp_blks_written,
    shared_blk_read_time,
    shared_blk_write_time,
    local_blk_read_time,
    local_blk_write_time,
    temp_blk_read_time,
    temp_blk_write_time,
    wal_records,
    wal_fpi,
    wal_bytes,
    jit_functions,
    jit_generation_time,
    jit_inlining_count,
    jit_inlining_time,
    jit_optimization_count,
    jit_optimization_time,
    jit_emission_count,
    jit_emission_time,
    jit_deform_count,
    jit_deform_time,
    stats_since,
    minmax_stats_since
   FROM pg_stat_statements(true) pg_stat_statements(userid, dbid, toplevel, queryid, query, plans, total_plan_time, min_plan_time, max_plan_time, mean_plan_time, stddev_plan_time, calls, total_exec_time, min_exec_time, max_exec_time, mean_exec_time, stddev_exec_time, rows, shared_blks_hit, shared_blks_read, shared_blks_dirtied, shared_blks_written, local_blks_hit, local_blks_read, local_blks_dirtied, local_blks_written, temp_blks_read, temp_blks_written, shared_blk_read_time, shared_blk_write_time, local_blk_read_time, local_blk_write_time, temp_blk_read_time, temp_blk_write_time, wal_records, wal_fpi, wal_bytes, jit_functions, jit_generation_time, jit_inlining_count, jit_inlining_time, jit_optimization_count, jit_optimization_time, jit_emission_count, jit_emission_time, jit_deform_count, jit_deform_time, stats_since, minmax_stats_since);

alter table pg_stat_statements
    owner to postgres;

grant select on pg_stat_statements to public;

grant insert, select, update on pg_stat_statements to runner;

create view vw_airflow_eventos
            (id_evento, nome_evento, data_inicial, data_final, url_inscricao, url_wiclax, url_resultado) as
SELECT id_evento,
    nome_evento,
    data_inicial,
    data_final,
    url_inscricao,
    url_wiclax,
    url_resultado
   FROM tb_evento_corridas;

alter table vw_airflow_eventos
    owner to runner_dba;

grant insert, select, update on vw_airflow_eventos to runner;

create view vw_bi_fat_resultado
            (id_data, data_referencia, ano, mes, mes_extenso, dia, dia_do_ano, dia_da_semana, semana_calendario,
             data_formatada, trimestre, trimestre_ano, mes_ano, ano_semana_calendario, tipo_dia_semana,
             feriado_nacional, calendario_inicio_semana, calendario_final_semana, id_localidade, nome_pais, regiao,
             estado, nome_estado, nome_cidade, capital, id_paises_iso3166, id_evento, id_resultado, num_peito, nome,
             data_nascimento, evento_homologado, modalidade, pace, percurso, sexo, tempo_bruto, tempo_total,
             velocidade_media, nome_categoria, resultado_homologado, concluinte, nacionalidade, status_final,
             hora_largada)
as
SELECT dta.id_data,
    dta.data_referencia,
    dta.ano,
    dta.mes,
    dta.mes_extenso,
    dta.dia,
    dta.dia_do_ano,
    dta.dia_da_semana,
    dta.semana_calendario,
    dta.data_formatada,
    dta.trimestre,
    dta.trimestre_ano,
    dta.mes_ano,
    dta.ano_semana_calendario,
    dta.tipo_dia_semana,
    dta.feriado_nacional,
    dta.calendario_inicio_semana,
    dta.calendario_final_semana,
    loc.id_localidade,
    loc.nome_pais,
    loc.regiao,
    loc.estado,
    loc.nome_estado,
    loc.nome_cidade,
    loc.capital,
    loc.id_paises_iso3166,
    res.id_evento,
    res.id_resultado,
    res.num_peito,
    res.nome,
    res.data_nascimento,
    res.evento_homologado,
    res.modalidade,
    res.pace,
    res.percurso,
    res.sexo,
    res.tempo_bruto,
    res.tempo_total,
    res.velocidade_media,
    res.nome_categoria,
    res.resultado_homologado,
    res.concluinte,
    res.nacionalidade,
    res.status_final,
    res.hora_largada
   FROM tbbi_fat_resultado res
     JOIN tbbi_dim_data dta ON dta.id_data = res.id_data
     JOIN tbbi_dim_localidade loc ON loc.id_localidade = res.id_localidade;

alter table vw_bi_fat_resultado
    owner to runner_dba;

grant insert, select, update on vw_bi_fat_resultado to runner;

create view vw_evento_corridas_cupom
            (id_evento_cupom, id_cupom, tipo_evento, id_evento_agrega, qtd_limite_cupom, data_cadastro_cupom_evento,
             data_validade_inicio, data_validade_fim, cupom, descricao, parceiro, condicoes, data_cadastro,
             data_expiracao)
as
SELECT cc.id_evento_cupom,
    cc.id_cupom,
    1 AS tipo_evento,
    cc.id_evento AS id_evento_agrega,
    cc.qtd_limite_cupom,
    cc.data_cadastro AS data_cadastro_cupom_evento,
    cc.data_validade_inicio,
    cc.data_validade_fim,
    cp.cupom,
    cp.descricao,
    cp.parceiro,
    cp.condicoes,
    cp.data_cadastro,
    cp.data_expiracao
   FROM tb_evento_corridas_cupom cc
     JOIN tb_cupom cp ON cp.id_cupom = cc.id_cupom
UNION ALL
 SELECT cc.id_evento_cupom,
    cc.id_cupom,
    2 AS tipo_evento,
    cc.id_agrega_evento AS id_evento_agrega,
    cc.qtd_limite_cupom,
    cc.data_cadastro AS data_cadastro_cupom_evento,
    cc.data_validade_inicio,
    cc.data_validade_fim,
    cp.cupom,
    cp.descricao,
    cp.parceiro,
    cp.condicoes,
    cp.data_cadastro,
    cp.data_expiracao
   FROM tb_evento_circuitos_cupom cc
     JOIN tb_cupom cp ON cp.id_cupom = cc.id_cupom;

alter table vw_evento_corridas_cupom
    owner to runner_dba;

grant insert, select, update on vw_evento_corridas_cupom to runner;

create view vw_evento_corridas
            (id_evento, nome_evento, cidade, estado, pais, categorias, coordenadas, data_inicial, data_final, tag,
             destaque, tipo_corrida, url_inscricao, url_resultado, status_evento, id_tema, id_agrega_evento,
             id_foco_radical, week, month, year, tag_cidade, badges, concluintes, lista_percursos, max_percurso, cupom,
             lista_percursos_resultado, is_maratona)
as
SELECT id_evento,
    nome_evento,
    cidade,
    estado,
    pais,
    categorias,
    coordenadas,
    data_inicial,
    data_final,
    tag,
    destaque,
    tipo_corrida,
    url_inscricao,
    url_resultado,
    status_evento,
    id_tema,
    id_agrega_evento,
    ''::text AS id_foco_radical,
    date_part('week'::text, data_final) AS week,
    date_part('month'::text, data_final) AS month,
    date_part('year'::text, data_final) AS year,
    translate(lower(cidade::text), ' ''àáâãäéèëêíìïîóòõöôúùüûçÇ%.+!&ªº°'::text, '--aaaaaeeeeiiiiooooouuuucc'::text) AS tag_cidade,
    ( SELECT json_agg(row_to_json(linha.*)) AS json_agg
           FROM ( SELECT DISTINCT bd.badge,
                    bd.valor_badge,
                    bd.percurso,
                    tip.badge_tooltip,
                    tip.ordem
                   FROM tb_badges bd
                     JOIN tb_badges_tipos tip ON tip.badge::text = bd.badge::text
                  WHERE bd.id_evento = evt.id_evento AND tip.ativo = true
                  ORDER BY tip.ordem) linha) AS badges,
    ( SELECT sum(res.concluintes) AS sum
           FROM tb_resultados_resumo res
          WHERE res.id_evento = evt.id_evento) AS concluintes,
    ( SELECT json_agg(json_build_object('percurso', pcr.percurso_evento, 'unidade', pcr.unidade_de_medida, 'tipo_corrida', pcr.tipo_corrida, 'mapa', pcr.mapa) ORDER BY pcr.percurso_evento) AS json_agg
           FROM tb_evento_corridas_percursos pcr
          WHERE pcr.id_evento = evt.id_evento) AS lista_percursos,
    ( SELECT max(pcr.percurso_evento) AS max
           FROM tb_evento_corridas_percursos pcr
          WHERE pcr.id_evento = evt.id_evento) AS max_percurso,
    ( SELECT vw_evento_corridas_cupom.condicoes
           FROM vw_evento_corridas_cupom
          WHERE (vw_evento_corridas_cupom.id_evento_agrega = evt.id_evento AND vw_evento_corridas_cupom.tipo_evento = 1 OR vw_evento_corridas_cupom.id_evento_agrega = evt.id_agrega_evento AND vw_evento_corridas_cupom.tipo_evento = 2) AND CURRENT_DATE >= vw_evento_corridas_cupom.data_validade_inicio AND CURRENT_DATE <= vw_evento_corridas_cupom.data_validade_fim) AS cupom,
    ( SELECT json_agg(json_build_object('percurso', pcr.percurso, 'modalidade', pcr.modalidade, 'concluintes', pcr.concluintes) ORDER BY pcr.percurso) AS json_agg
           FROM tb_resultados_resumo pcr
          WHERE pcr.id_evento = evt.id_evento) AS lista_percursos_resultado,
    ( SELECT pcr.percurso_evento
           FROM tb_evento_corridas_percursos pcr
          WHERE pcr.id_evento = evt.id_evento AND pcr.percurso_evento = 42::numeric
         LIMIT 1) AS is_maratona
   FROM tb_evento_corridas evt
  WHERE ativo = true;

alter table vw_evento_corridas
    owner to runner_dba;

grant insert, select, update on vw_evento_corridas to runner;

create view vw_pimenta (activity_id, activity_date, athlete_id, id_athlete_owner, start_date, distance) as
WITH c1 AS (
         SELECT t.athlete_id,
            t.activity_date,
            min(t.start_date) AS primeira_corrida,
            count(*) AS total
           FROM tb_strava_activities t
          WHERE t.activity_date >= '2025-01-24'::date AND (t.type::text = ANY (ARRAY['Run'::character varying::text, 'VirtualRun'::character varying::text, 'TrailRun'::character varying::text])) AND t.distance >= 990::double precision
          GROUP BY t.athlete_id, t.activity_date
         HAVING count(*) > 1
          ORDER BY t.activity_date, t.athlete_id
        )
 SELECT strava.activity_id,
    strava.activity_date,
    strava.athlete_id,
        CASE
            WHEN strava.start_date = c1.primeira_corrida THEN 0::bigint
            ELSE strava.athlete_id
        END AS id_athlete_owner,
    strava.start_date,
    strava.distance
   FROM tb_strava_activities strava
     JOIN c1 ON c1.activity_date = strava.activity_date AND c1.athlete_id = strava.athlete_id
  WHERE (strava.type::text = ANY (ARRAY['Run'::character varying::text, 'VirtualRun'::character varying::text, 'TrailRun'::character varying::text])) AND strava.distance >= 990::double precision
  ORDER BY strava.activity_date, strava.athlete_id, strava.start_date;

alter table vw_pimenta
    owner to runner_dba;

grant insert, select, update on vw_pimenta to runner;

create view akkio_bi_vw_resultados_resumo
            (id_resultado_resumo, id_evento, nome_evento, cidade, estado, nome_regiao, pais, tag, url_inscricao,
             data_inicial, data_final, organizador, tipo_corrida, percurso, modalidade, sexo, concluintes, inscritos,
             pace_menor, pace_medio, pace_maior, pace_medio_top_10, pace_medio_top_100, pace_medio_5_porcento,
             pace_medio_10_porcento, pace_medio_50_porcento, limite_a, limite_a_concluintes, limite_b,
             limite_b_concluintes, limite_elite, limite_elite_concluintes, percentil, percentil_sem_desvio)
as
SELECT res.id_resultado_resumo,
    res.id_evento,
    evt.nome_evento,
    evt.cidade,
    evt.estado,
    uf.nome_regiao,
    evt.pais,
    evt.tag,
        CASE
            WHEN length(TRIM(BOTH FROM evt.url_inscricao)) = 0 THEN 'Não informado'::text
            ELSE COALESCE(TRIM(BOTH FROM evt.url_inscricao), 'Não informado'::text)
        END AS url_inscricao,
    evt.data_inicial,
    evt.data_final,
        CASE
            WHEN length(TRIM(BOTH FROM evt.organizador)) = 0 THEN 'Não informado'::character varying
            ELSE COALESCE(evt.organizador, 'Não informado'::character varying)
        END AS organizador,
    evt.tipo_corrida,
    res.percurso,
    res.modalidade,
    res.sexo,
    res.concluintes,
    res.inscritos,
    res.pace_menor,
    res.pace_medio,
    res.pace_maior,
    res.pace_medio_top_10,
    res.pace_medio_top_100,
    res.pace_medio_5_porcento,
    res.pace_medio_10_porcento,
    res.pace_medio_50_porcento,
    res.limite_a,
    res.limite_a_concluintes,
    res.limite_b,
    res.limite_b_concluintes,
    res.limite_elite,
    res.limite_elite_concluintes,
    res.percentil,
    res.percentil_sem_desvio
   FROM tb_resultados_resumo_2025 res
     JOIN tb_evento_corridas evt ON evt.id_evento = res.id_evento
     JOIN tb_uf uf ON uf.uf::text = evt.estado::text;

alter table akkio_bi_vw_resultados_resumo
    owner to runner_dba;

grant insert, select, update on akkio_bi_vw_resultados_resumo to runner;

grant select on akkio_bi_vw_resultados_resumo to akkio_user;

create view vw_cupom
            (tipo_cupom, id_pagina, id_tipo_cupom, nome_tipo_cupom, id_cupom, cupom, descricao, parceiro, condicoes,
             data_cadastro, data_expiracao, curl, ativo, id_evento, url_inscricao)
as
SELECT 'pagina'::text AS tipo_cupom,
    pg.id_pagina,
    pg.id_pagina AS id_tipo_cupom,
    tp.nome AS nome_tipo_cupom,
    cp.id_cupom,
    cp.cupom,
    cp.descricao,
    cp.parceiro,
    cp.condicoes,
    cp.data_cadastro,
    cp.data_expiracao,
    cp.url AS curl,
    cp.ativo,
    NULL::integer AS id_evento,
    NULL::character varying AS url_inscricao
   FROM tb_cupom cp
     JOIN tb_paginas_cupom pg ON pg.id_cupom = cp.id_cupom
     JOIN tb_paginas tp ON tp.id_pagina = pg.id_pagina
  WHERE NOT (EXISTS ( SELECT ev.id_cupom
           FROM tb_evento_circuitos_cupom ev
          WHERE ev.id_cupom = cp.id_cupom)) AND NOT (EXISTS ( SELECT cr.id_cupom
           FROM tb_evento_corridas_cupom cr
          WHERE cr.id_cupom = cp.id_cupom))
UNION ALL
 SELECT 'evento'::text AS tipo_cupom,
    1 AS id_pagina,
    pg.id_evento AS id_tipo_cupom,
    tp.nome_evento AS nome_tipo_cupom,
    cp.id_cupom,
    cp.cupom,
    cp.descricao,
    cp.parceiro,
    cp.condicoes,
    cp.data_cadastro,
    cp.data_expiracao,
    COALESCE(tp.url_inscricao, tp.url_hotsite) AS curl,
    cp.ativo,
    tp.id_evento,
    tp.url_inscricao
   FROM tb_cupom cp
     JOIN tb_evento_corridas_cupom pg ON pg.id_cupom = cp.id_cupom
     JOIN tb_evento_corridas tp ON tp.id_evento = pg.id_evento AND tp.data_inicial > CURRENT_DATE
UNION ALL
 SELECT 'circuito'::text AS tipo_cupom,
    1 AS id_pagina,
    pg.id_agrega_evento AS id_tipo_cupom,
    tp.nome_evento AS nome_tipo_cupom,
    cp.id_cupom,
    cp.cupom,
    cp.descricao,
    cp.parceiro,
    cp.condicoes,
    cp.data_cadastro,
    cp.data_expiracao,
    COALESCE(tp.url_inscricao, tp.url_hotsite) AS curl,
    cp.ativo,
    tp.id_evento,
    tp.url_inscricao
   FROM tb_cupom cp
     JOIN tb_evento_circuitos_cupom pg ON pg.id_cupom = cp.id_cupom
     JOIN tb_evento_corridas tp ON tp.id_agrega_evento = pg.id_agrega_evento AND tp.data_inicial > CURRENT_DATE;

alter table vw_cupom
    owner to runner_dba;

grant insert, select, update on vw_cupom to runner;

create view vw_desafio_365_final(id_usuario, dias_corridos) as
SELECT id_usuario,
    count(DISTINCT dias_corridos) AS dias_corridos
   FROM ( SELECT DISTINCT des.id_usuario,
            stv.activity_date AS dias_corridos
           FROM tb_strava_activities stv
             JOIN tb_usuarios usu ON usu.strava_id = stv.athlete_id
             JOIN desafios des ON des.id_usuario = usu.id
          WHERE (stv.type::text = ANY (ARRAY['Run'::character varying, 'VirtualRun'::character varying, 'TrailRun'::character varying]::text[])) AND stv.distance >= 990::double precision AND des.produto::text ~~ '%365%'::text AND stv.activity_date >= '2025-01-01'::date AND stv.activity_date <= '2025-12-31'::date
        UNION ALL
         SELECT DISTINCT des.id_usuario,
            stv.activity_date AS dias_corridos
           FROM tb_strava_activities stv
             JOIN tb_usuarios usu ON usu.strava_id = stv.id_athlete_donation
             JOIN desafios des ON des.id_usuario = usu.id
          WHERE (stv.type::text = ANY (ARRAY['Run'::character varying, 'VirtualRun'::character varying, 'TrailRun'::character varying]::text[])) AND stv.distance >= 990::double precision AND des.produto::text ~~ '%365%'::text AND stv.activity_date >= '2025-01-01'::date AND stv.activity_date <= '2025-12-31'::date) my_qry
  GROUP BY id_usuario;

alter table vw_desafio_365_final
    owner to runner_dba;

create view vw_desafio_366_final(id_usuario, dias_corridos) as
SELECT id_usuario,
    count(DISTINCT dias_corridos) AS dias_corridos
   FROM ( SELECT DISTINCT des.id_usuario,
            stv.activity_date AS dias_corridos
           FROM tb_strava_activities stv
             JOIN tb_usuarios usu ON usu.strava_id = stv.athlete_id
             JOIN desafios des ON des.id_usuario = usu.id
          WHERE (stv.type::text = ANY (ARRAY['Run'::character varying, 'VirtualRun'::character varying, 'TrailRun'::character varying]::text[])) AND stv.distance >= 990::double precision AND des.desafio::text = 'desafio366'::text AND stv.activity_date >= '2024-01-01'::date AND stv.activity_date <= '2024-12-31'::date
        UNION ALL
         SELECT DISTINCT des.id_usuario,
            stv.activity_date AS dias_corridos
           FROM tb_strava_activities stv
             JOIN tb_usuarios usu ON usu.strava_id = stv.id_athlete_donation
             JOIN desafios des ON des.id_usuario = usu.id
          WHERE (stv.type::text = ANY (ARRAY['Run'::character varying, 'VirtualRun'::character varying, 'TrailRun'::character varying]::text[])) AND stv.distance >= 990::double precision AND des.desafio::text = 'desafio366'::text AND stv.activity_date >= '2024-01-01'::date AND stv.activity_date <= '2024-12-31'::date) my_qry
  GROUP BY id_usuario;

alter table vw_desafio_366_final
    owner to runner_dba;

create view vw_resultados
            (id_resultado, num_peito, nome, data_nascimento, id_evento, modalidade, pace, percurso, sexo, tempo_bruto,
             tempo_total, classificacao_categoria, classificacao_sexo, classificacao_total, velocidade_media, equipe,
             nome_categoria, id_usuario, id_categoria, homologado, concluinte, chave_processamento, chave_verificacao,
             nacionalidade, status_final, hora_largada, tempo_f1_categoria, tempo_f1_sexo, tempo_f1_total,
             posicao_ranking, classificacao_pais, pcd, nome_full_text, idade_range)
as
SELECT id_resultado,
    num_peito,
    nome,
    data_nascimento,
    id_evento,
    modalidade,
    pace,
    percurso,
    sexo,
    tempo_bruto,
    tempo_total,
    classificacao_categoria,
    classificacao_sexo,
    classificacao_total,
    velocidade_media,
    equipe,
    nome_categoria,
    id_usuario,
    id_categoria,
    homologado,
    concluinte,
    chave_processamento,
    chave_verificacao,
    nacionalidade,
    status_final,
    hora_largada,
    tempo_f1_categoria,
    tempo_f1_sexo,
    tempo_f1_total,
    posicao_ranking,
    classificacao_pais,
    pcd,
    nome_full_text,
    idade_range
   FROM tb_resultados
  WHERE status_final = 0 AND homologado = true;

alter table vw_resultados
    owner to runner_dba;

create view vwbi_fat_perfil_br_2025
            (id_fat_perfil_br_2025, id_evento, id_resultado, data_evento, percurso, sexo, tempo_total,
             tempo_total_segundos, idade_range, id_usuario, id_atleta_strava, pcd, evento_homologado,
             resultado_homologado, id_data, data_referencia, ano, mes, mes_extenso, dia, dia_do_ano, dia_da_semana,
             semana_calendario, data_formatada, trimestre, trimestre_ano, mes_ano, ano_semana_calendario,
             tipo_dia_semana, feriado_nacional, calendario_inicio_semana, calendario_final_semana, id_localidade,
             nome_pais, regiao, estado, nome_estado, nome_cidade, capital, id_paises_iso3166, id_geracao, nome_geracao,
             id_faixa, nome_faixa, id_cbat_categoria, nome_cbat_categoria, id_organizacao, agrupamento, nome_padrao,
             nome_original, id_cronometragem, nome_cronometragem)
as
SELECT tbbi_fat_perfil_br_2025.id_fat_perfil_br_2025,
    tbbi_fat_perfil_br_2025.id_evento,
    tbbi_fat_perfil_br_2025.id_resultado,
    tbbi_fat_perfil_br_2025.data_evento,
    tbbi_fat_perfil_br_2025.percurso,
    tbbi_fat_perfil_br_2025.sexo,
    tbbi_fat_perfil_br_2025.tempo_total,
    EXTRACT(epoch FROM tbbi_fat_perfil_br_2025.tempo_total)::integer AS tempo_total_segundos,
    tbbi_fat_perfil_br_2025.idade_range,
    tbbi_fat_perfil_br_2025.id_usuario,
    tbbi_fat_perfil_br_2025.id_atleta_strava,
    tbbi_fat_perfil_br_2025.pcd,
    tbbi_fat_perfil_br_2025.evento_homologado,
    tbbi_fat_perfil_br_2025.resultado_homologado,
    dd.id_data,
    dd.data_referencia,
    dd.ano,
    dd.mes,
    dd.mes_extenso,
    dd.dia,
    dd.dia_do_ano,
    dd.dia_da_semana,
    dd.semana_calendario,
    dd.data_formatada,
    dd.trimestre,
    dd.trimestre_ano,
    dd.mes_ano,
    dd.ano_semana_calendario,
    dd.tipo_dia_semana,
    dd.feriado_nacional,
    dd.calendario_inicio_semana,
    dd.calendario_final_semana,
    dl.id_localidade,
    dl.nome_pais,
    dl.regiao,
    dl.estado,
    dl.nome_estado,
    dl.nome_cidade,
    dl.capital,
    dl.id_paises_iso3166,
    dg.id_geracao,
    dg.nome_geracao,
    df.id_faixa,
    df.nome_faixa,
    dfc.id_cbat_categoria,
    dfc.nome_cbat_categoria,
    ni.id_organizacao,
    ni.agrupamento,
    ni.nome_padrao,
    ni.nome_original,
    dc.id_cronometragem,
    dc.nome_cronometragem
   FROM tbbi_fat_perfil_br_2025
     JOIN tbbi_dim_data dd ON dd.id_data = tbbi_fat_perfil_br_2025.id_data
     JOIN tbbi_dim_localidade dl ON dl.id_localidade = tbbi_fat_perfil_br_2025.id_localidade
     JOIN tbbi_dim_geracoes dg ON dg.id_geracao = tbbi_fat_perfil_br_2025.id_geracao
     JOIN tbbi_dim_faixas df ON df.id_faixa = tbbi_fat_perfil_br_2025.id_faixa
     JOIN tbbi_dim_cbat_categorias dfc ON dfc.id_cbat_categoria = tbbi_fat_perfil_br_2025.id_cbat_categoria
     JOIN tbbi_dim_organizacao_2025 ni ON ni.id_organizacao = tbbi_fat_perfil_br_2025.id_organizador
     JOIN tbbi_dim_cronometragem dc ON dc.id_cronometragem = tbbi_fat_perfil_br_2025.id_cronometrador;

alter table vwbi_fat_perfil_br_2025
    owner to runner_dba;

grant select on vwbi_fat_perfil_br_2025 to runner;

grant select on vwbi_fat_perfil_br_2025 to akkio_user;

create view vw_evento_corridas_cr
            (id_evento, cidade, estado, tag, homologado, url_resultado, url_wiclax, cod_cidade, id_agrega_evento, pais,
             data_inicial, data_final, descricao, endereco, coordenadas, imagem, destaque, categorias, url_inscricao,
             info_duplicado, nome_simplificado, organizador, obs, tipo_corrida, ranking, id_tema, data_processamento,
             resumo, tag_301, ativo, data_inclusao, nome_evento_full_text, obs_resultado, status_evento,
             resultado_completo, url_hotsite, url_imagem, id_fornecedor, url_imagem_listagem, descricao_original,
             obs_homologacao, cronometragem, realizacao, cobertura, url_regulamento)
as
SELECT eve.id_evento,
    eve.cidade,
    eve.estado,
    eve.tag,
    eve.homologado,
    eve.url_resultado,
    eve.url_wiclax,
    eve.cod_cidade,
    eve.id_agrega_evento,
    eve.pais,
    eve.data_inicial,
    eve.data_final,
    eve.descricao,
    eve.endereco,
    eve.coordenadas,
    eve.imagem,
    eve.destaque,
    eve.categorias,
    eve.url_inscricao,
    eve.info_duplicado,
    eve.nome_simplificado,
    eve.organizador,
    eve.obs,
    eve.tipo_corrida,
    eve.ranking,
    eve.id_tema,
    eve.data_processamento,
    eve.resumo,
    eve.tag_301,
    eve.ativo,
    eve.data_inclusao,
    eve.nome_evento_full_text,
    eve.obs_resultado,
    eve.status_evento,
    eve.resultado_completo,
    eve.url_hotsite,
    eve.url_imagem,
    eve.id_fornecedor,
    eve.url_imagem_listagem,
    eve.descricao_original,
    eve.obs_homologacao,
    eve.cronometragem,
    eve.realizacao,
    eve.cobertura,
    eve.url_regulamento
   FROM tb_evento_corridas eve
     JOIN tb_agregadores_eventos age ON age.id_evento = eve.id_evento
  WHERE age.agregador_tag::text = 'contra-relogio'::text;

alter table vw_evento_corridas_cr
    owner to runner_dba;

grant insert, select, update on vw_evento_corridas_cr to runner;

create function pg_stat_statements_info(out dealloc unknown, out stats_reset unknown) returns record
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function pg_stat_statements_info(out unknown, out unknown) owner to postgres;

create function pg_stat_statements(showtext unknown, out userid unknown, out dbid unknown, out toplevel unknown, out queryid unknown, out query unknown, out plans unknown, out total_plan_time unknown, out min_plan_time unknown, out max_plan_time unknown, out mean_plan_time unknown, out stddev_plan_time unknown, out calls unknown, out total_exec_time unknown, out min_exec_time unknown, out max_exec_time unknown, out mean_exec_time unknown, out stddev_exec_time unknown, out rows unknown, out shared_blks_hit unknown, out shared_blks_read unknown, out shared_blks_dirtied unknown, out shared_blks_written unknown, out local_blks_hit unknown, out local_blks_read unknown, out local_blks_dirtied unknown, out local_blks_written unknown, out temp_blks_read unknown, out temp_blks_written unknown, out shared_blk_read_time unknown, out shared_blk_write_time unknown, out local_blk_read_time unknown, out local_blk_write_time unknown, out temp_blk_read_time unknown, out temp_blk_write_time unknown, out wal_records unknown, out wal_fpi unknown, out wal_bytes unknown, out jit_functions unknown, out jit_generation_time unknown, out jit_inlining_count unknown, out jit_inlining_time unknown, out jit_optimization_count unknown, out jit_optimization_time unknown, out jit_emission_count unknown, out jit_emission_time unknown, out jit_deform_count unknown, out jit_deform_time unknown, out stats_since unknown, out minmax_stats_since unknown) returns setof record
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function pg_stat_statements(unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown, out unknown) owner to postgres;

create function pg_stat_statements_reset(userid unknown default 0, dbid unknown default 0, queryid unknown default 0, minmax_only unknown default false) returns timestamp with time zone
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function pg_stat_statements_reset(unknown, unknown, unknown, unknown) owner to postgres;

create function unaccent(unknown, unknown) returns text
    stable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function unaccent(unknown, unknown) owner to postgres;

create function unaccent(unknown) returns text
    stable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function unaccent(unknown) owner to postgres;

create function unaccent_init(unknown) returns internal
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function unaccent_init(unknown) owner to postgres;

create function unaccent_lexize(unknown, unknown, unknown, unknown) returns internal
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function unaccent_lexize(unknown, unknown, unknown, unknown) owner to postgres;

create procedure atualiza()
    language plpgsql
as
$$
DECLARE
rec_eventos        record;

cur_eventos cursor for
select
    id_evento,
    nome_evento,
    data_inicial,
    data_final,
    categorias
from
    tb_evento_corridas;


BEGIN
    open cur_eventos;
    loop
        fetch cur_eventos into rec_eventos;
        exit when not found;

        call grava_evento_corridas_percursos(rec_eventos.id_evento,rec_eventos.nome_evento,rec_eventos.data_inicial,rec_eventos.data_final,rec_eventos.categorias);

    end loop;

    close cur_eventos;


END
$$;

alter procedure atualiza() owner to runner_dba;

create procedure atualiza_classific_f1(IN p_cod_evento integer)
    language plpgsql
as
$$
DECLARE

var_class_percurso  integer;
var_class_sexo      integer;
var_class_categ     integer;
var_class_pais      integer;
var_tempo_f1        time;

var_percurso_ant    decimal;
var_sexo_ant        varchar;
var_categ_ant       varchar;
var_nacionalidade_ant varchar;
var_modalidade_ant  varchar;

rec_percurso        record;
rec_categ           record;
rec_pais            record;
rec_atualiza        record;


cur_percurso cursor for
select
    id_evento,
    id_resultado,
    modalidade,
    num_peito,
    nome_categoria,
    sexo,
    percurso,
    pace,
    tempo_total
from
    tb_resultados where id_evento = p_cod_evento and
    concluinte      = true and
    status_final    = 0
order by modalidade,sexo,percurso,pace,tempo_total,nome_categoria desc;

cur_categ cursor for
select
    id_evento,
    id_resultado,
    modalidade,
    num_peito,
    nome_categoria,
    sexo,
    percurso,
    pace,
    tempo_total
from
    tb_resultados where id_evento = p_cod_evento and
    concluinte = true and
    status_final = 0
order by modalidade,sexo,percurso,nome_categoria,pace,tempo_total;

cur_pais cursor for
select
    id_evento,
    id_resultado,
    modalidade,
    num_peito,
    nome_categoria,
    nacionalidade,
    sexo,
    percurso,
    pace,
    tempo_total
from
    tb_resultados where id_evento = p_cod_evento and
    concluinte = true and
    status_final = 0
order by modalidade,sexo,percurso,nacionalidade,pace,tempo_total,nome_categoria desc;


BEGIN
    var_class_percurso  := 0;
    var_percurso_ant    := 0;
    var_sexo_ant        := ' ';
    var_modalidade_ant  := ' ';
    var_tempo_f1        := null;

    -- update tb_resultados
    -- set
    --     classificacao_total     = null,
    --     classificacao_sexo      = null,
    --     tempo_f1_sexo           = null
    -- where
    --     id_evento = p_cod_evento;

    select
        sum(coalesce(classificacao_categoria,0)) as atualiza_categ,
        sum(coalesce(classificacao_total,0)) as atualiza_total,
        sum(coalesce(classificacao_sexo,0)) as atualiza_sexo
    into
        rec_atualiza
    from
        tb_resultados
    where
        id_evento = p_cod_evento;

    open cur_percurso;
    loop
        fetch cur_percurso into rec_percurso;
        exit when not found;

        if rec_percurso.percurso != var_percurso_ant or rec_percurso.sexo != var_sexo_ant or rec_percurso.modalidade != var_modalidade_ant then
            var_percurso_ant    := rec_percurso.percurso;
            var_sexo_ant        := rec_percurso.sexo;
            var_modalidade_ant  := rec_percurso.modalidade;
            var_class_percurso  := 0;
            var_tempo_f1        := rec_percurso.tempo_total;
        end if;

        var_class_percurso  := var_class_percurso + 1;

        if rec_atualiza.atualiza_total = 0 then
            update tb_resultados
            set
                classificacao_total     = var_class_percurso
            where
                id_evento = rec_percurso.id_evento and
                id_resultado = rec_percurso.id_resultado;
        end if;

        if rec_atualiza.atualiza_sexo = 0 then
            update tb_resultados
            set
                classificacao_sexo      = var_class_percurso,
                tempo_f1_sexo           = rec_percurso.tempo_total - var_tempo_f1
            where
                id_evento = rec_percurso.id_evento and
                id_resultado = rec_percurso.id_resultado;
        end if;

        update tb_resultados
        set
            tempo_f1_sexo           = rec_percurso.tempo_total - var_tempo_f1
        where
            id_evento = rec_percurso.id_evento and
            id_resultado = rec_percurso.id_resultado;

    end loop;

    close cur_percurso;

    var_class_percurso  := 0;
    var_class_categ     := 0;
    var_percurso_ant    := 0;
    var_sexo_ant        := ' ';
    var_categ_ant       := ' ';
    var_modalidade_ant  := ' ';
    var_tempo_f1        := null;

    open cur_categ;
    loop
        fetch cur_categ into rec_categ;
        exit when not found;

        if rec_categ.percurso != var_percurso_ant or rec_categ.sexo != var_sexo_ant or rec_categ.nome_categoria != var_categ_ant or rec_categ.modalidade != var_modalidade_ant then
            var_percurso_ant    := rec_categ.percurso;
            var_sexo_ant        := rec_categ.sexo;
            var_modalidade_ant  := rec_categ.modalidade;
            var_categ_ant       := rec_categ.nome_categoria;
            var_tempo_f1        := rec_categ.tempo_total;
            var_class_categ     := 0;
        end if;

        var_class_categ  := var_class_categ + 1;

        if rec_atualiza.atualiza_categ = 0 then
            update tb_resultados
            set
                classificacao_categoria = var_class_categ,
                tempo_f1_categoria      = rec_categ.tempo_total - var_tempo_f1
            where
                id_evento = rec_categ.id_evento and
                id_resultado = rec_categ.id_resultado;
        end if;

        update tb_resultados
        set
            tempo_f1_categoria      = rec_categ.tempo_total - var_tempo_f1
        where
            id_evento = rec_categ.id_evento and
            id_resultado = rec_categ.id_resultado;

    end loop;
    close cur_categ;

    var_class_pais      := 0;
    var_percurso_ant    := 0;
    var_sexo_ant        := ' ';
    var_categ_ant       := ' ';
    var_modalidade_ant  := ' ';
    var_nacionalidade_ant := ' ';

    open cur_pais;
    loop
        fetch cur_pais into rec_pais;
        exit when not found;

        if rec_pais.percurso != var_percurso_ant or rec_pais.sexo != var_sexo_ant or rec_pais.nacionalidade != var_nacionalidade_ant or rec_pais.modalidade != var_modalidade_ant  then
            var_percurso_ant        := rec_pais.percurso;
            var_sexo_ant            := rec_pais.sexo;
            var_modalidade_ant      := rec_pais.modalidade;
            var_nacionalidade_ant   := rec_pais.nacionalidade;
            var_tempo_f1            := rec_pais.tempo_total;
            var_class_pais          := 0;
        end if;

        var_class_pais  := var_class_pais + 1;

        update tb_resultados
        set
            classificacao_pais  = var_class_pais
        where
            id_evento = rec_pais.id_evento and
            id_resultado = rec_pais.id_resultado;

    end loop;
    close cur_pais;

    update tb_resultados
    set
        classificacao_total     = null,
        classificacao_categoria = null,
        classificacao_sexo      = null,
        tempo_f1_categoria      = null,
        tempo_f1_sexo           = null
    where
        id_evento    = rec_percurso.id_evento and
        ( concluinte = false or status_final > 0 );

END
$$;

alter procedure atualiza_classific_f1(unknown) owner to runner_dba;

grant execute on procedure atualiza_classific_f1(unknown) to runner;

create procedure atualiza_classific_f1_v2(IN p_cod_evento integer, IN p_clas_total boolean, IN p_clas_sexo boolean, IN p_clas_categ boolean)
    language plpgsql
as
$$
DECLARE

var_class_percurso  integer;
var_class_sexo      integer;
var_class_categ     integer;
var_class_pais      integer;
var_tempo_f1        time;

var_percurso_ant    decimal;
var_sexo_ant        varchar;
var_categ_ant       varchar;
var_nacionalidade_ant varchar;
var_modalidade_ant  varchar;

rec_percurso        record;
rec_categ           record;
rec_pais            record;


cur_percurso cursor for
select
    id_evento,
    id_resultado,
    modalidade,
    num_peito,
    nome_categoria,
    sexo,
    percurso,
    pace,
    tempo_total
from
    tb_resultados where id_evento = p_cod_evento and
    concluinte      = true and
    status_final    = 0
order by modalidade,sexo,percurso,pace,tempo_total,nome_categoria desc;

cur_categ cursor for
select
    id_evento,
    id_resultado,
    modalidade,
    num_peito,
    nome_categoria,
    sexo,
    percurso,
    pace,
    tempo_total
from
    tb_resultados where id_evento = p_cod_evento and
    concluinte = true and
    status_final = 0
order by modalidade,sexo,percurso,nome_categoria,pace,tempo_total;

cur_pais cursor for
select
    id_evento,
    id_resultado,
    modalidade,
    num_peito,
    nome_categoria,
    nacionalidade,
    sexo,
    percurso,
    pace,
    tempo_total
from
    tb_resultados where id_evento = p_cod_evento and
    concluinte = true and
    status_final = 0
order by modalidade,sexo,percurso,nacionalidade,pace,tempo_total,nome_categoria desc;


BEGIN
    var_class_percurso  := 0;
    var_percurso_ant    := 0;
    var_sexo_ant        := ' ';
    var_modalidade_ant  := ' ';
    var_tempo_f1        := null;

    if p_clas_total = true then
        update tb_resultados
        set
            classificacao_total     = null,
            tempo_f1_sexo           = null
        where
            id_evento = p_cod_evento;
        insert into tb_resultados_processa_logs
            ( cod_evento, data_processamento, erro_execucao, log_execucao )
        values
            ( p_cod_evento, current_timestamp, false,'Atualização da classificação total foi executada');
    end if;

    if p_clas_sexo = true then
        update tb_resultados
        set
            classificacao_sexo      = null,
            tempo_f1_sexo           = null
        where
            id_evento = p_cod_evento;
    end if;


    open cur_percurso;
    loop
        fetch cur_percurso into rec_percurso;
        exit when not found;

        if rec_percurso.percurso != var_percurso_ant or rec_percurso.sexo != var_sexo_ant or rec_percurso.modalidade != var_modalidade_ant then
            var_percurso_ant    := rec_percurso.percurso;
            var_sexo_ant        := rec_percurso.sexo;
            var_modalidade_ant  := rec_percurso.modalidade;
            var_class_percurso  := 0;
            var_tempo_f1        := rec_percurso.tempo_total;
        end if;

        var_class_percurso  := var_class_percurso + 1;

        if p_clas_total = true then
            update tb_resultados
            set
                classificacao_total     = var_class_percurso,
                tempo_f1_sexo           = rec_percurso.tempo_total - var_tempo_f1
            where
                id_evento = rec_percurso.id_evento and
                id_resultado = rec_percurso.id_resultado;
        end if;

        if p_clas_sexo = true then
            update tb_resultados
            set
                classificacao_sexo      = var_class_percurso,
                tempo_f1_sexo           = rec_percurso.tempo_total - var_tempo_f1
            where
                id_evento = rec_percurso.id_evento and
                id_resultado = rec_percurso.id_resultado;
        end if;
    end loop;

    close cur_percurso;

    var_class_percurso  := 0;
    var_class_categ     := 0;
    var_percurso_ant    := 0;
    var_sexo_ant        := ' ';
    var_categ_ant       := ' ';
    var_modalidade_ant  := ' ';
    var_tempo_f1        := null;

    if p_clas_categ = true then
        open cur_categ;
        loop
            fetch cur_categ into rec_categ;
            exit when not found;

            if rec_categ.percurso != var_percurso_ant or rec_categ.sexo != var_sexo_ant or rec_categ.nome_categoria != var_categ_ant or rec_categ.modalidade != var_modalidade_ant then
                var_percurso_ant := rec_categ.percurso;
                var_sexo_ant     := rec_categ.sexo;
                var_modalidade_ant  := rec_categ.modalidade;
                var_categ_ant    := rec_categ.nome_categoria;
                var_tempo_f1     := rec_categ.tempo_total;
                var_class_categ  := 0;
            end if;

            var_class_categ  := var_class_categ + 1;

            update tb_resultados
            set
                classificacao_categoria = var_class_categ,
                tempo_f1_categoria      = rec_categ.tempo_total - var_tempo_f1
            where
                id_evento = rec_categ.id_evento and
                id_resultado = rec_categ.id_resultado;

        end loop;
        close cur_categ;
    end if;

    var_class_pais      := 0;
    var_percurso_ant    := 0;
    var_sexo_ant        := ' ';
    var_categ_ant       := ' ';
    var_modalidade_ant  := ' ';
    var_nacionalidade_ant := ' ';

    open cur_pais;
    loop
        fetch cur_pais into rec_pais;
        exit when not found;

        if rec_pais.percurso != var_percurso_ant or rec_pais.sexo != var_sexo_ant or rec_pais.nacionalidade != var_nacionalidade_ant or rec_pais.modalidade != var_modalidade_ant  then
            var_percurso_ant        := rec_pais.percurso;
            var_sexo_ant            := rec_pais.sexo;
            var_modalidade_ant      := rec_pais.modalidade;
            var_nacionalidade_ant   := rec_pais.nacionalidade;
            var_tempo_f1            := rec_pais.tempo_total;
            var_class_pais          := 0;
        end if;

        var_class_pais  := var_class_pais + 1;

        update tb_resultados
        set
            classificacao_pais  = var_class_pais
        where
            id_evento = rec_pais.id_evento and
            id_resultado = rec_pais.id_resultado;

    end loop;
    close cur_pais;

    update tb_resultados
    set
        classificacao_total     = null,
        classificacao_categoria = null,
        classificacao_sexo      = null,
        tempo_f1_categoria      = null,
        tempo_f1_sexo           = null
    where
        id_evento    = rec_percurso.id_evento and
        ( concluinte = false or status_final > 0 );

END
$$;

alter procedure atualiza_classific_f1_v2(unknown, unknown, unknown, unknown) owner to runner_dba;

grant execute on procedure atualiza_classific_f1_v2(unknown, unknown, unknown, unknown) to runner;

create procedure atualiza_ranking()
    language plpgsql
as
$$
DECLARE

var_class_percurso  integer;

var_percurso_ant    decimal;
var_sexo_ant        varchar;
var_ano_ant         integer;

rec_percurso        record;

cur_percurso cursor for
select
    extract(year from evt.data_inicial)::integer as ano,
    res.id_evento,
    res.id_resultado,
    res.num_peito,
    res.nome_categoria,
    res.sexo,
    res.percurso,
    res.pace,
    res.tempo_total
from
    tb_resultados res
    inner join tb_evento_corridas evt on evt.id_evento = res.id_evento
    where res.concluinte  = true and
    res.homologado       = true  and
    evt.homologado       = true  and
    res.pcd              = false and
    res.status_final     = 0
order by ano,sexo,percurso,pace,tempo_total,nome_categoria desc;

BEGIN
        update tb_resultados
        set
            posicao_ranking  = null
        where
            id_evento  > 0;

    var_class_percurso  := 0;
    var_ano_ant         := 0;
    var_percurso_ant    := 0;
    var_sexo_ant        := ' ';

    open cur_percurso;
    loop
        fetch cur_percurso into rec_percurso;
        exit when not found;

        if rec_percurso.percurso != var_percurso_ant or rec_percurso.sexo != var_sexo_ant or rec_percurso.ano != var_ano_ant then
            var_percurso_ant    := rec_percurso.percurso;
            var_sexo_ant        := rec_percurso.sexo;
            var_ano_ant         := rec_percurso.ano;
            var_class_percurso  := 0;
        end if;

        var_class_percurso  := var_class_percurso + 1;

        update tb_resultados
        set
            posicao_ranking         = var_class_percurso
        where
            id_evento    = rec_percurso.id_evento and
            id_resultado = rec_percurso.id_resultado;

    end loop;

    close cur_percurso;

END
$$;

alter procedure atualiza_ranking() owner to runner_dba;

grant execute on procedure atualiza_ranking() to runner;

create procedure atualiza_resultados_resumo(IN p_cod_evento integer)
    language plpgsql
as
$$
DECLARE

BEGIN
    delete from tb_resultados_resumo where id_evento = p_cod_evento;

    insert into tb_resultados_resumo
    ( id_evento, percurso, modalidade, concluintes,inscritos,pace_medio,pace_medio_top_10,pace_medio_top_100,concluintes_sub3 )
      select
        id_evento,
        percurso,
        modalidade,
        count(*) FILTER (WHERE homologado = true and concluinte=true and status_final=0) as concluintes,
        count(*) as inscritos,
        avg(pace) FILTER (WHERE homologado = true and concluinte=true and status_final=0 and pace is not null) as pace_medio,
        avg(pace) FILTER (WHERE homologado = true and concluinte=true and status_final=0 and pace is not null and ( classificacao_total <= 10 or classificacao_sexo <= 10) ) as pace_medio_top_10,
        avg(pace) FILTER (WHERE homologado = true and concluinte=true and status_final=0 and pace is not null and ( classificacao_total <= 100 or classificacao_sexo <= 100)) as pace_medio_top_100,
        count(*)  FILTER (WHERE homologado = true and concluinte=true and status_final=0 and tempo_total < '03:00:00'::time and percurso >= 42) as concluintes_sub3    from tb_resultados
    where id_evento  = p_cod_evento
    group by id_evento,percurso,modalidade;

    UPDATE tb_resultados_resumo
    SET tipo_corrida=subquery.tipo_corrida
    FROM (SELECT id_evento,percurso_evento,tipo_corrida from tb_evento_corridas_percursos
    ) AS subquery
    WHERE
    tb_resultados_resumo.id_evento  = p_cod_evento
    and tb_resultados_resumo.id_evento = subquery.id_evento
    and tb_resultados_resumo.percurso = subquery.percurso_evento;

    UPDATE tb_resultados_resumo
    SET tipo_corrida=subquery.tipo_corrida
    FROM (SELECT id_evento,percurso_evento,tipo_corrida from tb_evento_corridas_percursos
    ) AS subquery
    WHERE
    tb_resultados_resumo.tipo_corrida is null
    and tb_resultados_resumo.id_evento = subquery.id_evento
    and tb_resultados_resumo.percurso = subquery.percurso_evento;

END
$$;

alter procedure atualiza_resultados_resumo(unknown) owner to runner_dba;

create procedure atualiza_resultados_resumo_2025(IN p_cod_evento integer)
    language plpgsql
as
$$
DECLARE

BEGIN
    delete from tb_resultados_resumo_2025 where id_evento = p_cod_evento;

    insert into tb_resultados_resumo_2025
    (   id_evento,
        percurso,
        modalidade,
        sexo,
        concluintes,
        inscritos,
        pace_menor,
        pace_medio,
        pace_maior,
        pace_medio_top_10,
        pace_medio_top_100,
        pace_medio_5_porcento,
        pace_medio_10_porcento,
        pace_medio_50_porcento,
        limite_a,
        limite_a_concluintes,
        limite_b,
        limite_b_concluintes,
        limite_elite,
        limite_elite_concluintes,
        percentil,
        percentil_sem_desvio
    )
    WITH tot AS (
        SELECT
            id_evento,
            percurso,
            modalidade,
            sexo,
            count(*) as tot_atletas
        FROM
            tb_resultados
        where
            id_evento = p_cod_evento
        GROUP BY
            id_evento,
            percurso,
            modalidade,
            sexo
    )
        select
            res.id_evento,
            res.percurso,
            res.modalidade,
            res.sexo,
            count(*) FILTER (WHERE homologado = true and concluinte=true and status_final=0) as concluintes,
            count(*) as inscritos,
            min(pace) FILTER (WHERE homologado = true and concluinte=true and status_final=0 and pace is not null) as pace_menor,
            avg(pace) FILTER (WHERE homologado = true and concluinte=true and status_final=0 and pace is not null) as pace_medio,
            max(pace) FILTER (WHERE homologado = true and concluinte=true and status_final=0 and pace is not null) as pace_maior,
            avg(pace) FILTER (WHERE homologado = true and concluinte=true and status_final=0 and pace is not null and ( classificacao_total <= 10  or classificacao_sexo <= 10)) as pace_medio_top_10,
            avg(pace) FILTER (WHERE homologado = true and concluinte=true and status_final=0 and pace is not null and ( classificacao_total <= 100 or classificacao_sexo <= 100)) as pace_medio_top_100,
            avg(pace) FILTER (WHERE homologado = true and concluinte=true and status_final=0 and pace is not null and ( classificacao_total <= (tot_atletas * 0.05) or classificacao_sexo <= (tot_atletas * 0.05))) as pace_medio_5_porcento,
            avg(pace) FILTER (WHERE homologado = true and concluinte=true and status_final=0 and pace is not null and ( classificacao_total <= (tot_atletas * 0.10) or classificacao_sexo <= (tot_atletas * 0.10))) as pace_medio_10_porcento,
            avg(pace) FILTER (WHERE homologado = true and concluinte=true and status_final=0 and pace is not null and ( classificacao_total <= (tot_atletas * 0.50) or classificacao_sexo <= (tot_atletas * 0.50))) as pace_medio_50_porcento,
            (select limite_a from tb_resultados_resumo_limites where percurso = res.percurso and (id_evento = res.id_evento or id_evento is null) order by case when id_evento is null then 1 else 0 end limit 1) as limite_a,
            count(*)  FILTER (WHERE homologado = true and concluinte=true and status_final=0 and tempo_total < (select limite_a from tb_resultados_resumo_limites where percurso = res.percurso and (id_evento = res.id_evento or id_evento is null))  ) as limite_a_concluintes,
            (select limite_b from tb_resultados_resumo_limites where percurso = res.percurso and (id_evento = res.id_evento or id_evento is null) order by case when id_evento is null then 1 else 0 end limit 1) as limite_b,
            count(*)  FILTER (WHERE homologado = true and concluinte=true and status_final=0 and tempo_total < (select limite_b from tb_resultados_resumo_limites where percurso = res.percurso and (id_evento = res.id_evento or id_evento is null))  ) as limite_b_concluintes,
            (select limite_elite from tb_resultados_resumo_limites where percurso = res.percurso and (id_evento = res.id_evento or id_evento is null) order by case when id_evento is null then 1 else 0 end limit 1) as limite_elite,
            count(*)  FILTER (WHERE homologado = true and concluinte=true and status_final=0 and tempo_total < (select limite_elite from tb_resultados_resumo_limites where percurso = res.percurso and (id_evento = res.id_evento or id_evento is null))  ) as limite_elite_concluintes,
            percentile_cont(0.5) within group (order by pace asc) FILTER (WHERE homologado = true and concluinte=true and status_final=0 and pace is not null) as percentil,
            ( select percentile_cont(0.5) within group (order by pace asc)
              from tb_resultados ris
              where ris.id_evento = res.id_evento and
              ris.percurso = res.percurso and
              ris.modalidade = res.modalidade and
              ris.sexo = res.sexo and
              ris.pace >= ( select percentile_cont(0.1) within group (order by pace asc) from tb_resultados r1 where r1.id_evento = res.id_evento and r1.percurso = res.percurso and r1.modalidade = res.modalidade and r1.sexo = res.sexo ) and
              ris.pace <= ( select percentile_cont(0.7) within group (order by pace asc) from tb_resultados r1 where r1.id_evento = res.id_evento and r1.percurso = res.percurso and r1.modalidade = res.modalidade and r1.sexo = res.sexo )
            ) as percentil_sem_desvio
        from tb_resultados res
            inner join tot on tot.id_evento = res.id_evento and tot.percurso = res.percurso and tot.modalidade = res.modalidade and tot.sexo = res.sexo
            where res.id_evento  = p_cod_evento
            group by res.id_evento,res.percurso,res.modalidade,res.sexo;

insert into tb_resultados_resumo_2025
    (   id_evento,
        percurso,
        modalidade,
        concluintes,
        inscritos,
        pace_menor,
        pace_medio,
        pace_maior,
        pace_medio_top_10,
        pace_medio_top_100,
        pace_medio_5_porcento,
        pace_medio_10_porcento,
        pace_medio_50_porcento,
        limite_a,
        limite_a_concluintes,
        limite_b,
        limite_b_concluintes,
        limite_elite,
        limite_elite_concluintes,
        percentil,
        percentil_sem_desvio
    )
    WITH tot AS (
        SELECT
            id_evento,
            percurso,
            modalidade,
            count(*) as tot_atletas
        FROM
            tb_resultados
        where
            id_evento = p_cod_evento
        GROUP BY
            id_evento,
            percurso,
            modalidade
    )
        select
            res.id_evento,
            res.percurso,
            res.modalidade,
            count(*) FILTER (WHERE homologado = true and concluinte=true and status_final=0) as concluintes,
            count(*) as inscritos,
            min(pace) FILTER (WHERE homologado = true and concluinte=true and status_final=0 and pace is not null) as pace_menor,
            avg(pace) FILTER (WHERE homologado = true and concluinte=true and status_final=0 and pace is not null) as pace_medio,
            max(pace) FILTER (WHERE homologado = true and concluinte=true and status_final=0 and pace is not null) as pace_maior,
            avg(pace) FILTER (WHERE homologado = true and concluinte=true and status_final=0 and pace is not null and ( classificacao_total <= 10  or classificacao_sexo <= 10)) as pace_medio_top_10,
            avg(pace) FILTER (WHERE homologado = true and concluinte=true and status_final=0 and pace is not null and ( classificacao_total <= 100 or classificacao_sexo <= 100)) as pace_medio_top_100,
            avg(pace) FILTER (WHERE homologado = true and concluinte=true and status_final=0 and pace is not null and ( classificacao_total <= (tot_atletas * 0.05) or classificacao_sexo <= (tot_atletas * 0.05))) as pace_medio_5_porcento,
            avg(pace) FILTER (WHERE homologado = true and concluinte=true and status_final=0 and pace is not null and ( classificacao_total <= (tot_atletas * 0.10) or classificacao_sexo <= (tot_atletas * 0.10))) as pace_medio_10_porcento,
            avg(pace) FILTER (WHERE homologado = true and concluinte=true and status_final=0 and pace is not null and ( classificacao_total <= (tot_atletas * 0.50) or classificacao_sexo <= (tot_atletas * 0.50))) as pace_medio_50_porcento,
            (select limite_a from tb_resultados_resumo_limites where percurso = res.percurso and (id_evento = res.id_evento or id_evento is null) order by case when id_evento is null then 1 else 0 end limit 1) as limite_a,
            count(*)  FILTER (WHERE homologado = true and concluinte=true and status_final=0 and tempo_total < (select limite_a from tb_resultados_resumo_limites where percurso = res.percurso and (id_evento = res.id_evento or id_evento is null))  ) as limite_a_concluintes,
            (select limite_b from tb_resultados_resumo_limites where percurso = res.percurso and (id_evento = res.id_evento or id_evento is null) order by case when id_evento is null then 1 else 0 end limit 1) as limite_b,
            count(*)  FILTER (WHERE homologado = true and concluinte=true and status_final=0 and tempo_total < (select limite_b from tb_resultados_resumo_limites where percurso = res.percurso and (id_evento = res.id_evento or id_evento is null))  ) as limite_b_concluintes,
            (select limite_elite from tb_resultados_resumo_limites where percurso = res.percurso and (id_evento = res.id_evento or id_evento is null) order by case when id_evento is null then 1 else 0 end limit 1) as limite_elite,
            count(*)  FILTER (WHERE homologado = true and concluinte=true and status_final=0 and tempo_total < (select limite_elite from tb_resultados_resumo_limites where percurso = res.percurso and (id_evento = res.id_evento or id_evento is null))  ) as limite_elite_concluintes,
            percentile_cont(0.5) within group (order by pace asc) FILTER (WHERE homologado = true and concluinte=true and status_final=0 and pace is not null) as percentil,
            ( select percentile_cont(0.5) within group (order by pace asc)
              from tb_resultados ris
              where ris.id_evento = res.id_evento and
              ris.percurso = res.percurso and
              ris.modalidade = res.modalidade and
              ris.pace >= ( select percentile_cont(0.1) within group (order by pace asc) from tb_resultados r1 where r1.id_evento = res.id_evento and r1.percurso = res.percurso and r1.modalidade = res.modalidade) and
              ris.pace <= ( select percentile_cont(0.7) within group (order by pace asc) from tb_resultados r1 where r1.id_evento = res.id_evento and r1.percurso = res.percurso and r1.modalidade = res.modalidade)
            ) as percentil_sem_desvio
        from tb_resultados res
            inner join tot on tot.id_evento = res.id_evento and tot.percurso = res.percurso and tot.modalidade = res.modalidade
            where res.id_evento  = p_cod_evento
            group by res.id_evento,res.percurso,res.modalidade;

    UPDATE tb_resultados_resumo_2025
    SET tipo_corrida=subquery.tipo_corrida
    FROM (SELECT id_evento,percurso_evento,tipo_corrida from tb_evento_corridas_percursos
    ) AS subquery
    WHERE
    tb_resultados_resumo_2025.id_evento  = p_cod_evento
    and tb_resultados_resumo_2025.id_evento = subquery.id_evento
    and tb_resultados_resumo_2025.percurso = subquery.percurso_evento;

    UPDATE tb_resultados_resumo_2025
    SET tipo_corrida=subquery.tipo_corrida
    FROM (SELECT id_evento,percurso_evento,tipo_corrida from tb_evento_corridas_percursos
    ) AS subquery
    WHERE
    tb_resultados_resumo_2025.tipo_corrida is null
    and tb_resultados_resumo_2025.id_evento = subquery.id_evento
    and tb_resultados_resumo_2025.percurso = subquery.percurso_evento;

END
$$;

alter procedure atualiza_resultados_resumo_2025(unknown) owner to runner_dba;

create function bi_cria_filtro(filtro jsonb) returns character varying
    language plpgsql
as
$$
declare
    p_where  boolean := false;
    p_virgula varchar := '';
    p_estado varchar;
    i_estado varchar;
    p_cidade varchar;
    i_cidade varchar;
    p_categoria varchar;
    i_categoria varchar;
    p_percurso varchar;
    i_percurso varchar;
    p_sql    varchar;
    i varchar;

begin

   p_estado := filtro->'estado';

    if p_estado is not null then
       FOREACH i IN ARRAY string_to_array(trim(p_estado,'"'),',') LOOP
            i_estado := concat(i_estado,p_virgula,quote_literal(i));
            p_virgula := ',';
       END LOOP;
        if p_where = false then
           p_sql    := concat(p_sql,' where ');
           p_where  := true;
        else
           p_sql := concat(p_sql,' and ');
        end if;
        p_sql := concat(p_sql,' estado in (', i_estado,')');
    end if;

    p_cidade := filtro->'cidade';
    p_virgula := '';
    if p_cidade is not null then
       FOREACH i IN ARRAY string_to_array(trim(p_cidade,'"'),',') LOOP
            i_cidade := concat(i_cidade,p_virgula,quote_literal(i));
            p_virgula := ',';
       END LOOP;
        if p_where = false then
           p_sql    := concat(p_sql,' where ');
           p_where  := true;
        else
           p_sql := concat(p_sql,' and ');
        end if;
        p_sql := concat(p_sql,' cidade in (', i_cidade,')');
    end if;

   p_categoria := filtro->'categoria';
   p_virgula := '';
   if p_categoria is not null then
       FOREACH i IN ARRAY string_to_array(trim(p_categoria,'"'),',') LOOP
            i_categoria := concat(i_categoria,p_virgula,quote_literal(i));
            p_virgula := ',';
       END LOOP;
        if p_where = false then
           p_sql    := concat(p_sql,' where ');
           p_where  := true;
        else
           p_sql := concat(p_sql,' and ');
        end if;
        p_sql := concat(p_sql,' nome_categoria in (', i_categoria,')');
    end if;

    p_percurso := filtro->'percurso';
    p_virgula := '';
    if p_percurso is not null then
       FOREACH i IN ARRAY string_to_array(trim(p_percurso,'"'),',') LOOP
            i_percurso := concat(i_percurso,p_virgula,i);
            p_percurso := ',';
       END LOOP;
        if p_where = false then
           p_sql    := concat(p_sql,' where ');
           p_where  := true;
        else
           p_sql := concat(p_sql,' and ');
        end if;
        p_sql := concat(p_sql,' percurso in (', i_percurso,')');
    end if;

    return p_sql;

end;
$$;

alter function bi_cria_filtro(unknown) owner to runner_dba;

create function bi_filtro_categoria() returns json
    language plpgsql
as
$$
declare
    ret_json json;
    p_sql varchar;
begin

   p_sql := 'select json_agg(row_to_json(linha)) from (select distinct nome_categoria as categoria from tb_resultados where length(nome_categoria) > 3 order by 1) linha';

   EXECUTE p_sql into ret_json;

   return ret_json;
end;
$$;

alter function bi_filtro_categoria() owner to runner_dba;

create function bi_filtro_cidade(p_estado character varying DEFAULT NULL::character varying, OUT uf character varying, OUT nome_cidade character varying) returns SETOF record
    language plpgsql
as
$$
declare
    p_sql varchar;
    rec_return record;
begin
   p_sql := 'select uf,nome_cidade from tb_cidades ';
   if p_estado is not null then
      p_sql := p_sql || ' where uf = ' || quote_literal(p_estado);
   end if;
   p_sql := p_sql || 'order by uf,nome_cidade';

   --EXECUTE p_sql into rec_return;

   --return rec_return;

    return query execute p_sql;

end;
$$;

alter function bi_filtro_cidade(unknown, out unknown, out unknown) owner to runner_dba;

create function bi_filtro_data(p_data_ini date DEFAULT NULL::date, p_data_fim date DEFAULT NULL::date, OUT tipo_filtro text, OUT vlr_filtro character varying, OUT seq integer, OUT ordem integer) returns SETOF record
    language plpgsql
as
$$
declare
    p_sql varchar;
    rec_return record;
begin
   if p_data_ini is null then
      p_data_ini := '2010-01-01'::date;
   end if;
   if p_data_fim is null then
      p_data_fim := '2029-12-31'::date;
   end if;
   p_sql := 'select distinct ' || '''Ano''' || ' as tipo_filtro, ano::varchar as vlr_filtro, ano::integer as seq, 1 as ordem from tbbi_dim_data ';
   p_sql := p_sql || ' where data_referencia between ' || quote_literal(p_data_ini) || '::date and ' || quote_literal(p_data_fim) ||'::date';
   p_sql := p_sql || ' union all ';
   p_sql := p_sql || 'select distinct ' ||'''Trimestre''' || ' as tipo_filtro, trimestre::varchar as vlr_filtro, replace(trimestre,' || '''T''' || ',' || '''' || '''' || ')::integer as seq, 2 as ordem from tbbi_dim_data  ';
   p_sql := p_sql || ' where data_referencia between ' || quote_literal(p_data_ini) || '::date and ' || quote_literal(p_data_fim) ||'::date';
   p_sql := p_sql || ' union all ';
   p_sql := p_sql || 'select distinct ' ||'''Mês''' || ' as tipo_filtro, mes_extenso::varchar as vlr_filtro, mes as seq, 3 as ordem from tbbi_dim_data ';
   p_sql := p_sql || ' where data_referencia between ' || quote_literal(p_data_ini) || '::date and ' || quote_literal(p_data_fim) ||'::date';
   p_sql := p_sql || ' union all ';
   p_sql := p_sql || 'select distinct ' ||'''Semana''' || ' as tipo_filtro, semana_calendario::varchar as vlr_filtro, semana_calendario as seq, 4 as ordem from tbbi_dim_data ';
   p_sql := p_sql || ' where data_referencia between ' || quote_literal(p_data_ini) || '::date and ' || quote_literal(p_data_fim) ||'::date';
   p_sql := p_sql || ' union all ';
   p_sql := p_sql || 'select distinct ' ||'''Dia Semana''' || ' as tipo_filtro, dia_da_semana as vlr_filtro, date_part(' || '''' || 'dow'|| '''' ||',data_referencia)::integer as seq, 5 as ordem from tbbi_dim_data ';
   p_sql := p_sql || ' where data_referencia between ' || quote_literal(p_data_ini) || '::date and ' || quote_literal(p_data_fim) ||'::date';
   p_sql := p_sql || ' union all ';
   p_sql := p_sql || 'select distinct ' ||'''Tipo Dia Semana''' || ' as tipo_filtro, tipo_dia_semana as vlr_filtro, 1 as seq, 6 as ordem from tbbi_dim_data ';
   p_sql := p_sql || ' where data_referencia between ' || quote_literal(p_data_ini) || '::date and ' || quote_literal(p_data_fim) ||'::date';
   p_sql := p_sql || ' union all ';
   p_sql := p_sql || 'select distinct ' || '''Feriado''' || ' as tipo_filtro, feriado_nacional as vlr_filtro, 1 as seq, 7 as ordem from tbbi_dim_data ';
   p_sql := p_sql || ' where data_referencia between ' || quote_literal(p_data_ini) || '::date and ' || quote_literal(p_data_fim) ||'::date';
    p_sql := p_sql || ' order by 4,3';

    return query execute p_sql;

end;
$$;

alter function bi_filtro_data(unknown, unknown, out unknown, out unknown, out unknown, out unknown) owner to runner_dba;

create function bi_filtro_estado(OUT uf text, OUT nome_uf text) returns SETOF record
    language sql
as
$$
   select uf,nome_uf from tb_uf order by uf;
$$;

alter function bi_filtro_estado(out unknown, out unknown) owner to runner_dba;

create function bi_filtro_percurso() returns json
    language plpgsql
as
$$
declare
    ret_json json;
    p_sql varchar;
begin

   p_sql := 'select json_agg(row_to_json(linha)) from (select distinct percurso from tb_resultados order by 1) linha';

   EXECUTE p_sql into ret_json;

   return ret_json;
end;
$$;

alter function bi_filtro_percurso() owner to runner_dba;

create function bi_kpi_conta_concluintes(filtro jsonb) returns integer
    language plpgsql
as
$$
declare
    contador integer;
    p_where  varchar;
    p_query  varchar := 'select count(*) ' ||
                        'from tb_evento_corridas eve inner join tb_resultados res on ' ||
                        'res.id_evento = eve.id_evento';
begin

   p_where  := bi_cria_filtro(filtro);
   p_query  := concat(p_query,p_where,' and eve.homologado = true and res.homologado = true and res.concluinte = true ');

   --RAISE exception 'Value: %', p_sql;

    EXECUTE p_query  INTO contador;

    return contador;
end;
$$;

alter function bi_kpi_conta_concluintes(unknown) owner to runner_dba;

create function bi_kpi_conta_eventos(filtro jsonb) returns integer
    language plpgsql
as
$$
declare
    contador integer;
    p_where  varchar;
    p_query  varchar := 'select count(distinct eve.id_evento) ' ||
                        'from tb_evento_corridas eve inner join tb_resultados res on ' ||
                        'res.id_evento = eve.id_evento';
begin

   p_where  := bi_cria_filtro(filtro);
   p_query  := concat(p_query,p_where);

   --RAISE exception 'Value: %', p_sql;

    EXECUTE p_query  INTO contador;

    return contador;
end;
$$;

alter function bi_kpi_conta_eventos(unknown) owner to runner_dba;

create function bi_tab_lista_topnpace(filtro jsonb, p_top integer) returns json
    language plpgsql
as
$$
declare
    ret_json json;
    p_query  varchar := 'select nome, pace ' ||
                    'from tb_evento_corridas eve inner join tb_resultados res on ' ||
                    'res.id_evento = eve.id_evento ';
begin
   p_query := concat(p_query, bi_cria_filtro(filtro), ' order by pace limit ', p_top);
   p_query := concat('select json_agg(row_to_json(linha)) from (', p_query,') linha');

   EXECUTE p_query into ret_json;

   return ret_json;
end;
$$;

alter function bi_tab_lista_topnpace(unknown, unknown) owner to runner_dba;

create function compara_filtro_caract_dominio(p_caracteristica text DEFAULT NULL::text) returns json
    language plpgsql
as
$$
declare
    ret_json json;
    p_sql varchar;
begin
   if p_caracteristica is null then
       return ret_json;
   end if;
   p_sql := concat('select json_agg(row_to_json(linha)) from (select distinct caracteristica_dominio as dominio from comparador.tb_caracteristica_dominio where tag_caracteristica = ',quote_literal(p_caracteristica), 'order by 1) linha');
   EXECUTE p_sql into ret_json;
   return ret_json;
end;
$$;

alter function compara_filtro_caract_dominio(unknown) owner to runner_dba;

create function compara_filtro_caract_produto(p_tipo_produto text DEFAULT NULL::text) returns json
    language plpgsql
as
$$
declare
    ret_json json;
    p_sql varchar;
begin
   if p_tipo_produto is null then
       return ret_json;
   end if;
   p_sql := concat('select json_agg(row_to_json(linha)) from (select distinct tag_caracteristica as caracteristica from comparador.tb_caracteristica_compara where tag_tipo_produto = ',quote_literal(p_tipo_produto), 'order by 1) linha');
   EXECUTE p_sql into ret_json;
   return ret_json;
end;
$$;

alter function compara_filtro_caract_produto(unknown) owner to runner_dba;

create procedure gera_resultados(IN p_cod_evento character varying)
    language plpgsql
as
$$
DECLARE

var_gera_resultado_ini          timestamp;
var_id_evento                   integer;
var_nome                        varchar;
var_tempo_valido                boolean;
var_total_registros             integer;
var_total_registros_processados integer;
var_erros_ocorridos             boolean;
var_chave_processamento         varchar;
var_chave_verificacao           varchar;
var_pace                        varchar;
var_tempo_bruto                 varchar;
var_tempo_total                 varchar;
var_hora_largada                varchar;
var_modalidade                  varchar;
var_percurso                    varchar;
var_homologado                  boolean;
var_concluinte                  boolean;
var_msg_erro                    varchar;
var_retorno                     integer;
var_status_final                integer;
var_np                          integer;
var_pcd                         boolean;
rec_resultados                  record;


cur_resultados cursor for
select distinct
    num_peito,
    nome,
    categoria               ,
    id_evento               ,
    modalidade,
    pace,
    regexp_replace(percurso, '[^0-9.]','','g') as percurso,
    substring(upper(sexo),1,1) as sexo,
    trim(tempo_bruto) as tempo_bruto,
    trim(tempo_total) as tempo_total,
    classificacao_categoria,
    classificacao_sexo,
    classificacao_total,
    velocidade_media,
    upper(trim(REPLACE(equipe,' ',' '))) as equipe,
    data_nascimento,
    substring(trim(nacionalidade),1,8) as nacionalidade,
    chave_processamento,
    hora_largada,
    regexp_replace(np, '\D','','g') as np
from
    tb_resultados_temp where id_evento = p_cod_evento
    and modalidade not in('KIDS')
    and chave_processamento is null
order by
    tempo_total desc, tempo_bruto desc;


BEGIN
    var_gera_resultado_ini          := current_timestamp;
    var_id_evento                   := null;
    var_erros_ocorridos             := false;
    var_total_registros             := 0;
    var_total_registros_processados := 0;
    var_chave_processamento         := md5(concat(var_gera_resultado_ini::varchar,p_cod_evento))::varchar;

    -- verifica se evento foi cadastrado
    select
        id_evento
    into
        var_id_evento
    from
         tb_evento_corridas
    where
         id_evento = p_cod_evento::integer;

    if var_id_evento is null then
        insert into tb_resultados_processa_logs
            ( cod_evento, data_processamento, erro_execucao, log_execucao )
        values
            ( p_cod_evento, current_timestamp, true,'Código do evento não encontrado na lista de corridas cadastradas');
        return;
    end if;

    open cur_resultados;
    loop
        fetch cur_resultados into rec_resultados;
        exit when not found;
        var_total_registros := var_total_registros + 1;
    end loop;
    close cur_resultados;

    if var_total_registros = 0 then
        insert into tb_resultados_processa_logs
            ( cod_evento, data_processamento, erro_execucao, log_execucao )
        values
            ( p_cod_evento, current_timestamp, true,'Não existem registros do evento para processamento');
        return;
    end if;

    insert into
        tb_resultados_processa
    values
        (
        p_cod_evento,
        var_id_evento,
        var_gera_resultado_ini,
        null,
        var_chave_processamento::uuid,
        false,
        null
        );

    open cur_resultados;
    loop
        fetch cur_resultados into rec_resultados;
        exit when not found;

        var_homologado  := true;
        var_concluinte  := true;
        var_status_final:= 0;

        if length(rec_resultados.np) > 0  and rec_resultados.np::integer = 1 then
            var_np := 1;
        else
            var_np := 0;
        end if;

        -- verifica nome
        var_nome := upper(trim(REPLACE(rec_resultados.nome,' ',' ')));
        if length(var_nome) < 1 or var_nome is null then
            var_msg_erro := concat('Nome do atleta não foi informado para o atleta número - ',rec_resultados.num_peito);
            var_retorno := grava_logs_resultados(
                        rec_resultados.id_evento,
                        rec_resultados.num_peito::integer,
                        rec_resultados.nome,
                        rec_resultados.categoria,
                        var_id_evento::integer,
                        var_chave_processamento,
                        var_msg_erro);
            var_erros_ocorridos := true;
            continue;
        end if;
        if var_nome = 'NAO ENCONTRADO' then
            var_msg_erro := concat('Registro ignorado devido à regra de exclusão - ',rec_resultados.num_peito, ' - ', var_nome);
            var_retorno := grava_logs_resultados(
                        rec_resultados.id_evento,
                        rec_resultados.num_peito::integer,
                        rec_resultados.nome,
                        rec_resultados.categoria,
                        var_id_evento::integer,
                        var_chave_processamento,
                        var_msg_erro);
            continue;
        end if;

        -- Padroniza nome de atleta desconhecido
        if position('NÃO CADASTRADO' in var_nome) > 0 or
           position('COMPETIDOR DESCONHECIDO' in var_nome) > 0 or
           position('SEM CADASTRO' in var_nome) > 0 then
           var_nome := 'ATLETA DESCONHECIDO';
        end if;

        -- verifica pace
        var_pace := rec_resultados.pace;
        if var_np = 1 then
            var_concluinte := false;
            var_pace := null;
        end if;

        if var_pace is not null then
            if length(var_pace) < 8 then
                var_pace := right(concat('00:',rec_resultados.pace),8);
            end if;
            var_tempo_valido := tempo_valido(var_pace::varchar);
            if  var_tempo_valido = false then
                var_msg_erro := concat('Pace incorreto para o atleta ',rec_resultados.num_peito,' - ',rec_resultados.nome,' - ',var_pace);
                var_retorno := grava_logs_resultados(
                            rec_resultados.id_evento,
                            rec_resultados.num_peito::integer,
                            rec_resultados.nome,
                            rec_resultados.categoria,
                            var_id_evento::integer,
                            var_chave_processamento,
                            var_msg_erro);
                var_erros_ocorridos := true;
                continue;
            end if;
        end if;

        -- valida tempo total
        var_tempo_total := rec_resultados.tempo_total;
        if var_np = 1 then
            var_tempo_total := null;
        end if;
        -- verifica se existem tempos de conclusão de prova
        if var_tempo_total is null then
           var_concluinte   := false;
           var_status_final := 4;
        end if;

        -- testa desclassificados
        if upper(trim(rec_resultados.modalidade)) = 'DESCLASSIFICADO'   or
           upper(trim(rec_resultados.modalidade)) = 'DSQ'   or
           -- upper(trim(rec_resultados.percurso))   = 'DESCLASSIFICADO'   or
           -- upper(trim(rec_resultados.percurso))   = 'DSQ'   or
           upper(replace(REGEXP_REPLACE(var_tempo_total,'[[:digit:]]','','g' ),':','')) = 'DESCLASSIFICADO' then
           var_status_final := 2;
           var_concluinte   := false;
           var_tempo_total  := null;
        end if;

        -- não processa percurso incorreto
        -- var_percurso := trim(LEADING '0' from regexp_replace(rec_resultados.percurso, '[^0-9.]','','g'));
        if rec_resultados.percurso ~ '^([0-9]+[.]?[0-9]*|[.][0-9]+)$' = false then
            var_msg_erro := concat('Percurso não reconhecido para o atleta - ',rec_resultados.num_peito, ' - ', var_nome);
            var_retorno := grava_logs_resultados(
                        rec_resultados.id_evento,
                        rec_resultados.num_peito::integer,
                        rec_resultados.nome,
                        rec_resultados.categoria,
                        var_id_evento::integer,
                        var_chave_processamento,
                        var_msg_erro);
            continue;
         end if;


        -- não processa modalidade incorreta
        var_modalidade := rec_resultados.modalidade;
        --var_modalidade := concat(trim(LEADING '0' from regexp_replace(rec_resultados.modalidade, '[^0-9.]','','g')),'K');

        --if var_modalidade = 'K' then
        --    var_msg_erro := concat('Modalidade não reconhecida para o atleta - ',rec_resultados.num_peito, ' - ', var_nome);
        --    var_retorno := grava_logs_resultados(
        --                rec_resultados.id_evento,
        --                rec_resultados.num_peito::integer,
        --                rec_resultados.nome,
        --                rec_resultados.categoria,
        --                var_id_evento::integer,
        --                var_chave_processamento,
        --                var_msg_erro);
        --    continue;
        --end if;

        if upper(replace(REGEXP_REPLACE(var_tempo_total,'[[:digit:]]','','g' ),':','')) = 'RETIRADA' then
           var_status_final := 1;
           var_concluinte   := false;
           var_tempo_total  := null;
        end if;

        if upper(replace(REGEXP_REPLACE(var_tempo_total,'[[:digit:]]','','g' ),':','')) = 'NÃO TERMINOU' then
           var_concluinte  := false;
           var_tempo_total := null;
        end if;

        if var_np = 1 then
           var_status_final := 3;
        end if;


        if  var_tempo_total is not null then
            var_tempo_total := replace(replace(replace(REGEXP_REPLACE(REGEXP_REPLACE(rec_resultados.tempo_total,'^0\:','00:'),'^1\:','01:'),'h',':'),'''',':'),',','.');
            var_tempo_valido := tempo_valido(var_tempo_total::varchar);
            if var_tempo_valido = false then
                var_msg_erro := concat('Tempo Total incorreto para atleta ',rec_resultados.num_peito,' - ',rec_resultados.nome,' - ',var_tempo_total);
                var_retorno := grava_logs_resultados(
                            rec_resultados.id_evento,
                            rec_resultados.num_peito::integer,
                            rec_resultados.nome,
                            rec_resultados.categoria,
                            var_id_evento::integer,
                            var_chave_processamento,
                            var_msg_erro);
                var_erros_ocorridos := true;
                continue;
            else
                -- calcula o pace caso pace seja nulo
                if var_pace is null and var_tempo_total is not null then
                    var_pace := (var_tempo_total::time / rec_resultados.percurso::numeric)::time;
                else
                    if var_pace::time < ((var_tempo_total::time / rec_resultados.percurso::numeric)::time - '00:00:05'::interval)::time or
                       var_pace::time > ((var_tempo_total::time / rec_resultados.percurso::numeric)::time + '00:00:05'::interval)::time then
                        --var_msg_erro := concat('Pace informado não pode ser homologado para o atleta - ',rec_resultados.num_peito,' - ',rec_resultados.nome,' - ',rec_resultados.pace);
                        var_msg_erro := concat('Pace inconsistente. Foi recalculado para o atleta - ',rec_resultados.num_peito,' - ',rec_resultados.nome,' - ',rec_resultados.pace);
                        var_retorno := grava_logs_resultados(
                            rec_resultados.id_evento,
                            rec_resultados.num_peito::integer,
                            rec_resultados.nome,
                            rec_resultados.categoria,
                            var_id_evento::integer,
                            var_chave_processamento,
                            var_msg_erro);
                            var_pace := (var_tempo_total::time / rec_resultados.percurso::numeric)::time;
                            -- nesse caso vai ser recalculado o pace e considerar o resultado como homologado
                            --var_homologado := false;
                    end if;
                end if;
            end if;
        end if;

        -- valida tempo bruto
        var_tempo_bruto := rec_resultados.tempo_bruto;
        if var_np = 1 then
            var_tempo_bruto := null;
        end if;
        if  var_tempo_bruto is not null then
            var_tempo_bruto := replace(replace(replace(REGEXP_REPLACE(REGEXP_REPLACE(rec_resultados.tempo_bruto,'^0\:','00:'),'^1\:','01:'),'h',':'),'''',':'),',','.');
            var_tempo_valido := tempo_valido(var_tempo_bruto::varchar);

            if var_tempo_valido = false then
                var_msg_erro := concat('Tempo Bruto incorreto para atleta ',rec_resultados.num_peito,' - ',rec_resultados.nome,' - ',var_tempo_bruto);
                var_retorno := grava_logs_resultados(
                            rec_resultados.id_evento,
                            rec_resultados.num_peito::integer,
                            rec_resultados.nome,
                            rec_resultados.categoria,
                            var_id_evento::integer,
                            var_chave_processamento,
                            var_msg_erro);
                var_erros_ocorridos := true;
                continue;
            end if;
        end if;

        -- valida hora_largada
        var_hora_largada := trim(rec_resultados.hora_largada);
        if var_np = 1 or length(var_hora_largada) < 1 then
            var_hora_largada := null;
        end if;
        if  var_hora_largada is not null  then
            var_hora_largada := replace(replace(replace(REGEXP_REPLACE(REGEXP_REPLACE(rec_resultados.hora_largada,'^0\:','00:'),'^1\:','01:'),'h',':'),'''',':'),',','.');
            var_tempo_valido := tempo_valido(var_hora_largada::varchar);

            if var_tempo_valido = false then
                var_msg_erro := concat('Hora da largada incorreta para atleta ',rec_resultados.num_peito,' - ',rec_resultados.nome,' - ',var_hora_largada);
                var_retorno := grava_logs_resultados(
                            rec_resultados.id_evento,
                            rec_resultados.num_peito::integer,
                            rec_resultados.nome,
                            rec_resultados.categoria,
                            var_id_evento::integer,
                            var_chave_processamento,
                            var_msg_erro);
                var_erros_ocorridos := true;
                continue;
            end if;
        end if;

        -- valida sexo
        if rec_resultados.sexo <> 'M' and rec_resultados.sexo <> 'F' and rec_resultados.sexo <> 'X' and rec_resultados.sexo <> 'N' then
            var_msg_erro := concat('Gênero informado incorretamente para atleta ',rec_resultados.num_peito,' - ',rec_resultados.nome);
            var_retorno := grava_logs_resultados(
                        rec_resultados.id_evento,
                        rec_resultados.num_peito::integer,
                        rec_resultados.nome,
                        rec_resultados.categoria,
                        var_id_evento::integer,
                        var_chave_processamento,
                        var_msg_erro);
            var_erros_ocorridos := true;
            continue;
        end if;

        if strpos(upper(concat(rec_resultados.nome,' ',rec_resultados.categoria,' ',rec_resultados.percurso,' ', rec_resultados.modalidade,' ', rec_resultados.equipe)),'PCD') > 0 then
           var_pcd := true;
        else
           var_pcd := false;
        end if;

        insert into tb_resultados
        (   num_peito               ,
            nome                    ,
            id_evento               ,
            modalidade              ,
            pace                    ,
            percurso                ,
            sexo                    ,
            tempo_bruto             ,
            tempo_total             ,
            classificacao_categoria ,
            classificacao_sexo      ,
            classificacao_total     ,
            velocidade_media        ,
            equipe,
            nome_categoria,
            homologado,
            concluinte,
            data_nascimento,
            nacionalidade,
            chave_processamento,
            chave_verificacao,
            status_final,
            hora_largada,
            pcd,
            idade_range
        ) values (
            rec_resultados.num_peito::integer,
            var_nome,
            var_id_evento,
            var_modalidade,
            var_pace::time,
            rec_resultados.percurso::numeric,
            rec_resultados.sexo,
            var_tempo_bruto::time,
            var_tempo_total::time,
            rec_resultados.classificacao_categoria::integer,
            rec_resultados.classificacao_sexo::integer,
            rec_resultados.classificacao_total::integer,
            rec_resultados.velocidade_media::numeric,
            rec_resultados.equipe,
            rec_resultados.categoria,
            var_homologado,
            var_concluinte,
            rec_resultados.data_nascimento::date,
            rec_resultados.nacionalidade,
            var_chave_processamento::uuid,
            md5(concat(rec_resultados.num_peito::varchar,var_nome,var_tempo_bruto::varchar,var_pace::varchar))::uuid,
            var_status_final,
            var_hora_largada::time,
            var_pcd,
            extrair_faixa_etaria(rec_resultados.categoria)::int4range
        )
        ON CONFLICT (id_evento,percurso,num_peito) DO UPDATE
        SET
            nome            = excluded.nome,
            modalidade      = excluded.modalidade,
            pace            = excluded.pace,
            percurso        = excluded.percurso,
            sexo            = excluded.sexo,
            tempo_bruto     = excluded.tempo_bruto,
            tempo_total     = excluded.tempo_total,
            classificacao_categoria = excluded.classificacao_categoria,
            classificacao_sexo      = excluded.classificacao_sexo,
            classificacao_total     = excluded.classificacao_total,
            velocidade_media        = excluded.velocidade_media,
            equipe                  = excluded.equipe,
            nome_categoria          = excluded.nome_categoria,
            data_nascimento         = excluded.data_nascimento,
            nacionalidade           = excluded.nacionalidade,
            homologado              = excluded.homologado,
            concluinte              = excluded.concluinte,
            chave_processamento     = excluded.chave_processamento,
            chave_verificacao       = excluded.chave_verificacao,
            status_final            = excluded.status_final,
            hora_largada            = excluded.hora_largada,
            pcd                     = excluded.pcd,
            idade_range             = excluded.idade_range;

        update
            tb_resultados_temp
        set
            chave_processamento = var_chave_processamento::uuid
        where
            id_evento   =   rec_resultados.id_evento and
            num_peito   =   rec_resultados.num_peito and
            nome        =   rec_resultados.nome      and
            categoria   =   rec_resultados.categoria;

    end loop;
    close cur_resultados;

    call atualiza_resultados_resumo_2025(var_id_evento);

    delete from tb_resultados_resumo where id_evento = var_id_evento;

    insert into tb_resultados_resumo
    ( id_evento, percurso, modalidade, concluintes,inscritos,pace_medio,pace_medio_top_10,pace_medio_top_100,concluintes_sub3 )
      select
        id_evento,
        percurso,
        modalidade,
        count(*) FILTER (WHERE homologado = true and concluinte=true and status_final=0) as concluintes,
        count(*) as inscritos,
        avg(pace) FILTER (WHERE homologado = true and concluinte=true and status_final=0 and pace is not null) as pace_medio,
        avg(pace) FILTER (WHERE homologado = true and concluinte=true and status_final=0 and pace is not null and ( classificacao_total <= 10 or classificacao_sexo <= 10) ) as pace_medio_top_10,
        avg(pace) FILTER (WHERE homologado = true and concluinte=true and status_final=0 and pace is not null and ( classificacao_total <= 100 or classificacao_sexo <= 100)) as pace_medio_top_100,
        count(*)  FILTER (WHERE homologado = true and concluinte=true and status_final=0 and tempo_total < '03:00:00'::time and percurso >= 42) as concluintes_sub3    from tb_resultados
    where id_evento  = var_id_evento
    group by id_evento,percurso,modalidade;

    UPDATE tb_resultados_resumo
    SET tipo_corrida=subquery.tipo_corrida
    FROM (SELECT id_evento,percurso_evento,tipo_corrida from tb_evento_corridas_percursos
    ) AS subquery
    WHERE
    tb_resultados_resumo.id_evento  = var_id_evento
    and tb_resultados_resumo.id_evento = subquery.id_evento
    and tb_resultados_resumo.percurso = subquery.percurso_evento;

    UPDATE tb_resultados_resumo
    SET tipo_corrida=subquery.tipo_corrida
    FROM (SELECT id_evento,percurso_evento,tipo_corrida from tb_evento_corridas_percursos
    ) AS subquery
    WHERE
    tb_resultados_resumo.tipo_corrida is null
    and tb_resultados_resumo.id_evento = subquery.id_evento
    and tb_resultados_resumo.percurso = subquery.percurso_evento;

    select
        md5(concat(sum(num_peito)::varchar,sum(tempo_bruto)::varchar))::varchar
    into
        var_chave_verificacao
    from
        tb_resultados where id_evento = var_id_evento;

    update
        tb_resultados_processa
    set
        data_processamento_final    = now(),
        erro_execucao               = var_erros_ocorridos,
        chave_verificacao           = var_chave_verificacao::uuid
    where
        cod_evento      = p_cod_evento  and
        id_evento       = var_id_evento and
        chave_processamento = var_chave_processamento::uuid;

END
$$;

alter procedure gera_resultados(unknown) owner to runner_dba;

create procedure gera_resultados_v2(IN p_cod_evento character varying)
    language plpgsql
as
$$
DECLARE

var_classificacao_total         boolean;
var_classificacao_sexo          boolean;
var_classificacao_categoria     boolean;

var_gera_resultado_ini          timestamp;
var_id_evento                   integer;
var_nome                        varchar;
var_tempo_valido                boolean;
var_total_registros             integer;
var_total_registros_processados integer;
var_erros_ocorridos             boolean;
var_chave_processamento         varchar;
var_chave_verificacao           varchar;
var_pace                        varchar;
var_tempo_bruto                 varchar;
var_tempo_total                 varchar;
var_hora_largada                varchar;
var_modalidade                  varchar;
var_homologado                  boolean;
var_concluinte                  boolean;
var_msg_erro                    varchar;
var_retorno                     integer;
var_status_final                integer;
var_np                          integer;
rec_resultados                  record;


cur_resultados cursor for
select distinct
    num_peito,
    nome,
    categoria               ,
    id_evento               ,
    modalidade,
    pace,
    regexp_replace(percurso, '\D','','g') as percurso,
    substring(upper(sexo),1,1) as sexo,
    trim(tempo_bruto) as tempo_bruto,
    trim(tempo_total) as tempo_total,
    classificacao_categoria,
    classificacao_sexo,
    classificacao_total,
    velocidade_media,
    upper(trim(REPLACE(equipe,' ',' '))) as equipe,
    data_nascimento,
    substring(trim(nacionalidade),1,8) as nacionalidade,
    chave_processamento,
    hora_largada,
    regexp_replace(np, '\D','','g') as np
from
    tb_resultados_temp where id_evento = p_cod_evento
    and modalidade not in('KIDS','PCD')
    and chave_processamento is null
order by
    tempo_total desc, tempo_bruto desc;


BEGIN
    var_gera_resultado_ini          := current_timestamp;
    var_id_evento                   := null;
    var_erros_ocorridos             := false;
    var_total_registros             := 0;
    var_total_registros_processados := 0;
    var_chave_processamento         := md5(concat(var_gera_resultado_ini::varchar,p_cod_evento))::varchar;

    -- verifica se evento foi cadastrado
    select
        id_evento
    into
        var_id_evento
    from
         tb_evento_corridas
    where
         id_evento = p_cod_evento::integer;

    if var_id_evento is null then
        insert into tb_resultados_processa_logs
            ( cod_evento, data_processamento, erro_execucao, log_execucao )
        values
            ( p_cod_evento, current_timestamp, true,'Código do evento não encontrado na lista de corridas cadastradas');
        return;
    end if;

    open cur_resultados;
    loop
        fetch cur_resultados into rec_resultados;
        exit when not found;
        var_total_registros := var_total_registros + 1;
    end loop;
    close cur_resultados;

    if var_total_registros = 0 then
        insert into tb_resultados_processa_logs
            ( cod_evento, data_processamento, erro_execucao, log_execucao )
        values
            ( p_cod_evento, current_timestamp, true,'Não existem registros do evento para processamento');
        return;
    end if;

    insert into
        tb_resultados_processa
    values
        (
        p_cod_evento,
        var_id_evento,
        var_gera_resultado_ini,
        null,
        var_chave_processamento::uuid,
        false,
        null
        );

    var_classificacao_total := false;
    var_classificacao_sexo  := false;
    var_classificacao_categoria := false;

    open cur_resultados;
    loop
        fetch cur_resultados into rec_resultados;
        exit when not found;

        var_homologado  := true;
        var_concluinte  := true;
        var_status_final:= 0;

        if length(rec_resultados.np) > 0  and rec_resultados.np::integer = 1 then
            var_np := 1;
        else
            var_np := 0;
        end if;

        -- verifica nome
        var_nome := upper(trim(REPLACE(rec_resultados.nome,' ',' ')));
        if length(var_nome) < 1 or var_nome is null then
            var_msg_erro := concat('Nome do atleta não foi informado para o atleta número - ',rec_resultados.num_peito);
            var_retorno := grava_logs_resultados(
                        rec_resultados.id_evento,
                        rec_resultados.num_peito::integer,
                        rec_resultados.nome,
                        rec_resultados.categoria,
                        var_id_evento::integer,
                        var_chave_processamento,
                        var_msg_erro);
            var_erros_ocorridos := true;
            continue;
        end if;
        if var_nome = 'NAO ENCONTRADO' then
            var_msg_erro := concat('Registro ignorado devido à regra de exclusão - ',rec_resultados.num_peito, ' - ', var_nome);
            var_retorno := grava_logs_resultados(
                        rec_resultados.id_evento,
                        rec_resultados.num_peito::integer,
                        rec_resultados.nome,
                        rec_resultados.categoria,
                        var_id_evento::integer,
                        var_chave_processamento,
                        var_msg_erro);
            continue;
        end if;

        -- Padroniza nome de atleta desconhecido
        if position('NÃO CADASTRADO' in var_nome) > 0 or
           position('COMPETIDOR DESCONHECIDO' in var_nome) > 0 or
           position('SEM CADASTRO' in var_nome) > 0 then
           var_nome := 'ATLETA DESCONHECIDO';
        end if;

        -- verifica pace
        var_pace := rec_resultados.pace;
        if var_np = 1 then
            var_concluinte := false;
            var_pace := null;
        end if;

        if var_pace is not null then
            if length(var_pace) < 8 then
                var_pace := right(concat('00:',rec_resultados.pace),8);
            end if;
            var_tempo_valido := tempo_valido(var_pace::varchar);
            if  var_tempo_valido = false then
                var_msg_erro := concat('Pace incorreto para o atleta ',rec_resultados.num_peito,' - ',rec_resultados.nome,' - ',var_pace);
                var_retorno := grava_logs_resultados(
                            rec_resultados.id_evento,
                            rec_resultados.num_peito::integer,
                            rec_resultados.nome,
                            rec_resultados.categoria,
                            var_id_evento::integer,
                            var_chave_processamento,
                            var_msg_erro);
                var_erros_ocorridos := true;
                continue;
            end if;
        end if;

        -- valida tempo total
        var_tempo_total := rec_resultados.tempo_total;
        if var_np = 1 then
            var_tempo_total := null;
        end if;
        -- verifica se existem tempos de conclusão de prova
        if var_tempo_total is null then
           var_concluinte   := false;
           var_status_final := 4;
        end if;

        -- testa desclassificados
        if upper(trim(rec_resultados.modalidade)) = 'DESCLASSIFICADO'   or
           upper(trim(rec_resultados.percurso))   = 'DESCLASSIFICADO'   or
           upper(trim(rec_resultados.categoria))   = 'DESCLASSIFICADO'   or
           upper(replace(REGEXP_REPLACE(var_tempo_total,'[[:digit:]]','','g' ),':','')) = 'DESCLASSIFICADO' then
           var_status_final := 2;
           var_concluinte   := false;
           var_tempo_total  := null;
        end if;

        -- não processa modalidade incorreta
        var_modalidade := concat(trim(LEADING '0' from regexp_replace(rec_resultados.modalidade, '\D','','g')),'K');
        if var_modalidade = 'K' then
            var_msg_erro := concat('Modalidade não reconhecida para o atleta - ',rec_resultados.num_peito, ' - ', var_nome);
            var_retorno := grava_logs_resultados(
                        rec_resultados.id_evento,
                        rec_resultados.num_peito::integer,
                        rec_resultados.nome,
                        rec_resultados.categoria,
                        var_id_evento::integer,
                        var_chave_processamento,
                        var_msg_erro);
            continue;
        end if;

        if upper(replace(REGEXP_REPLACE(var_tempo_total,'[[:digit:]]','','g' ),':','')) = 'RETIRADA' then
           var_status_final := 1;
           var_concluinte   := false;
           var_tempo_total  := null;
        end if;

        if upper(replace(REGEXP_REPLACE(var_tempo_total,'[[:digit:]]','','g' ),':','')) = 'NÃO TERMINOU' then
           var_concluinte  := false;
           var_tempo_total := null;
        end if;

        if var_np = 1 then
           var_status_final := 3;
        end if;


        if  var_tempo_total is not null then
            var_tempo_total := replace(replace(replace(REGEXP_REPLACE(REGEXP_REPLACE(rec_resultados.tempo_total,'^0\:','00:'),'^1\:','01:'),'h',':'),'''',':'),',','.');
            var_tempo_valido := tempo_valido(var_tempo_total::varchar);
            if var_tempo_valido = false then
                var_msg_erro := concat('Tempo Total incorreto para atleta ',rec_resultados.num_peito,' - ',rec_resultados.nome,' - ',var_tempo_total);
                var_retorno := grava_logs_resultados(
                            rec_resultados.id_evento,
                            rec_resultados.num_peito::integer,
                            rec_resultados.nome,
                            rec_resultados.categoria,
                            var_id_evento::integer,
                            var_chave_processamento,
                            var_msg_erro);
                var_erros_ocorridos := true;
                continue;
            else
                -- calcula o pace caso pace seja nulo
                if var_pace is null and var_tempo_total is not null then
                    var_pace := (var_tempo_total::time / rec_resultados.percurso::numeric)::time;
                else
                    if var_pace::time < ((var_tempo_total::time / rec_resultados.percurso::numeric)::time - '00:00:05'::interval)::time or
                       var_pace::time > ((var_tempo_total::time / rec_resultados.percurso::numeric)::time + '00:00:05'::interval)::time then
                        var_msg_erro := concat('Pace informado não pode ser homologado para o atleta - ',rec_resultados.num_peito,' - ',rec_resultados.nome,' - ',rec_resultados.pace);
                        var_retorno := grava_logs_resultados(
                            rec_resultados.id_evento,
                            rec_resultados.num_peito::integer,
                            rec_resultados.nome,
                            rec_resultados.categoria,
                            var_id_evento::integer,
                            var_chave_processamento,
                            var_msg_erro);
                            var_homologado := false;
                    end if;
                end if;
            end if;
        end if;

        -- valida tempo bruto
        var_tempo_bruto := rec_resultados.tempo_bruto;
        if var_np = 1 then
            var_tempo_bruto := null;
        end if;
        if  var_tempo_bruto is not null then
            var_tempo_bruto := replace(replace(replace(REGEXP_REPLACE(REGEXP_REPLACE(rec_resultados.tempo_bruto,'^0\:','00:'),'^1\:','01:'),'h',':'),'''',':'),',','.');
            var_tempo_valido := tempo_valido(var_tempo_bruto::varchar);

            if var_tempo_valido = false then
                var_msg_erro := concat('Tempo Bruto incorreto para atleta ',rec_resultados.num_peito,' - ',rec_resultados.nome,' - ',var_tempo_bruto);
                var_retorno := grava_logs_resultados(
                            rec_resultados.id_evento,
                            rec_resultados.num_peito::integer,
                            rec_resultados.nome,
                            rec_resultados.categoria,
                            var_id_evento::integer,
                            var_chave_processamento,
                            var_msg_erro);
                var_erros_ocorridos := true;
                continue;
            end if;
        end if;

        -- valida hora_largada
        var_hora_largada := trim(rec_resultados.hora_largada);
        if var_np = 1 or length(var_hora_largada) < 1 then
            var_hora_largada := null;
        end if;
        if  var_hora_largada is not null  then
            var_hora_largada := replace(replace(replace(REGEXP_REPLACE(REGEXP_REPLACE(rec_resultados.hora_largada,'^0\:','00:'),'^1\:','01:'),'h',':'),'''',':'),',','.');
            var_tempo_valido := tempo_valido(var_hora_largada::varchar);

            if var_tempo_valido = false then
                var_msg_erro := concat('Hora da largada incorreta para atleta ',rec_resultados.num_peito,' - ',rec_resultados.nome,' - ',var_hora_largada);
                var_retorno := grava_logs_resultados(
                            rec_resultados.id_evento,
                            rec_resultados.num_peito::integer,
                            rec_resultados.nome,
                            rec_resultados.categoria,
                            var_id_evento::integer,
                            var_chave_processamento,
                            var_msg_erro);
                var_erros_ocorridos := true;
                continue;
            end if;
        end if;

        -- valida sexo
        if rec_resultados.sexo <> 'M' and rec_resultados.sexo <> 'F' then
            var_msg_erro := concat('Gênero informado incorretamente para atleta ',rec_resultados.num_peito,' - ',rec_resultados.nome);
            var_retorno := grava_logs_resultados(
                        rec_resultados.id_evento,
                        rec_resultados.num_peito::integer,
                        rec_resultados.nome,
                        rec_resultados.categoria,
                        var_id_evento::integer,
                        var_chave_processamento,
                        var_msg_erro);
            var_erros_ocorridos := true;
            continue;
        end if;

        -- valida classificacao_total
        if rec_resultados.classificacao_total is not null then
            if var_homologado = true and var_concluinte = true and numero_valido(rec_resultados.classificacao_total) = false then
                var_msg_erro := concat('Classificacao_total não numérica ',rec_resultados.num_peito,' - ',rec_resultados.nome);
                var_retorno := grava_logs_resultados(
                            rec_resultados.id_evento,
                            rec_resultados.num_peito::integer,
                            rec_resultados.nome,
                            rec_resultados.categoria,
                            var_id_evento::integer,
                            var_chave_processamento,
                            var_msg_erro);
                var_erros_ocorridos := true;
                continue;
            end if;
        else
            var_classificacao_total := true;
        end if;

        -- valida classificacao_sexo
        if rec_resultados.classificacao_sexo is not null then
            if var_homologado = true and var_concluinte = true and numero_valido(rec_resultados.classificacao_sexo) = false then
                var_msg_erro := concat('Classificacao_sexo não numérica ',rec_resultados.num_peito,' - ',rec_resultados.nome);
                var_retorno := grava_logs_resultados(
                            rec_resultados.id_evento,
                            rec_resultados.num_peito::integer,
                            rec_resultados.nome,
                            rec_resultados.categoria,
                            var_id_evento::integer,
                            var_chave_processamento,
                            var_msg_erro);
                var_erros_ocorridos := true;
                continue;
            end if;
        else
            var_classificacao_sexo := true;
        end if;

        -- valida classificacao_categoria
        if rec_resultados.classificacao_categoria is not null then
            if var_homologado = true and var_concluinte = true and numero_valido(rec_resultados.classificacao_categoria) = false then
                var_msg_erro := concat('Classificacao_categoria não numérica ',rec_resultados.num_peito,' - ',rec_resultados.nome);
                var_retorno := grava_logs_resultados(
                            rec_resultados.id_evento,
                            rec_resultados.num_peito::integer,
                            rec_resultados.nome,
                            rec_resultados.categoria,
                            var_id_evento::integer,
                            var_chave_processamento,
                            var_msg_erro);
                var_erros_ocorridos := true;
                continue;
            end if;
        else
            var_classificacao_categoria := true;
        end if;

        insert into tb_resultados
        (   num_peito               ,
            nome                    ,
            id_evento               ,
            modalidade              ,
            pace                    ,
            percurso                ,
            sexo                    ,
            tempo_bruto             ,
            tempo_total             ,
            classificacao_categoria ,
            classificacao_sexo      ,
            classificacao_total     ,
            velocidade_media        ,
            equipe,
            nome_categoria,
            homologado,
            concluinte,
            data_nascimento,
            nacionalidade,
            chave_processamento,
            chave_verificacao,
            status_final,
            hora_largada
        ) values (
            rec_resultados.num_peito::integer,
            var_nome,
            var_id_evento,
            var_modalidade,
            var_pace::time,
            rec_resultados.percurso::numeric,
            rec_resultados.sexo,
            var_tempo_bruto::time,
            var_tempo_total::time,
            rec_resultados.classificacao_categoria::integer,
            rec_resultados.classificacao_sexo::integer,
            rec_resultados.classificacao_total::integer,
            rec_resultados.velocidade_media::numeric,
            rec_resultados.equipe,
            rec_resultados.categoria,
            var_homologado,
            var_concluinte,
            rec_resultados.data_nascimento::date,
            rec_resultados.nacionalidade,
            var_chave_processamento::uuid,
            md5(concat(rec_resultados.num_peito::varchar,var_nome,var_tempo_bruto::varchar,var_pace::varchar))::uuid,
            var_status_final,
            var_hora_largada::time
        )
        ON CONFLICT (id_evento,percurso,num_peito) DO UPDATE
        SET
            nome            = excluded.nome,
            modalidade      = excluded.modalidade,
            pace            = excluded.pace,
            percurso        = excluded.percurso,
            sexo            = excluded.sexo,
            tempo_bruto     = excluded.tempo_bruto,
            tempo_total     = excluded.tempo_total,
            classificacao_categoria = excluded.classificacao_categoria,
            classificacao_sexo      = excluded.classificacao_sexo,
            classificacao_total     = excluded.classificacao_total,
            velocidade_media        = excluded.velocidade_media,
            equipe                  = excluded.equipe,
            nome_categoria          = excluded.nome_categoria,
            data_nascimento         = excluded.data_nascimento,
            nacionalidade           = excluded.nacionalidade,
            homologado              = excluded.homologado,
            concluinte              = excluded.concluinte,
            chave_processamento     = excluded.chave_processamento,
            chave_verificacao       = excluded.chave_verificacao,
            status_final            = excluded.status_final,
            hora_largada            = excluded.hora_largada;

        update
            tb_resultados_temp
        set
            chave_processamento = var_chave_processamento::uuid
        where
            id_evento   =   rec_resultados.id_evento and
            num_peito   =   rec_resultados.num_peito and
            nome        =   rec_resultados.nome      and
            categoria   =   rec_resultados.categoria;

    end loop;
    close cur_resultados;

    if var_classificacao_total = true or var_classificacao_sexo = true or var_classificacao_categoria = true then
       var_msg_erro := concat('Atualização de classificação foi executada total/Sexo/Categoria',var_classificacao_total,'/',var_classificacao_sexo,'/',var_classificacao_categoria);
       var_retorno := grava_logs_resultados(
                            var_id_evento::text,
                            0::integer,
                            'nome'::text,
                            'categoria'::text,
                            var_id_evento::integer,
                            var_chave_processamento,
                            var_msg_erro);
       call atualiza_classific_f1_v2(var_id_evento,var_classificacao_total,var_classificacao_sexo,var_classificacao_categoria);
    end if;

    select
        md5(concat(sum(num_peito)::varchar,sum(tempo_bruto)::varchar))::varchar
    into
        var_chave_verificacao
    from
        tb_resultados where id_evento = var_id_evento;

    update
        tb_resultados_processa
    set
        data_processamento_final    = now(),
        erro_execucao               = var_erros_ocorridos,
        chave_verificacao           = var_chave_verificacao::uuid
    where
        cod_evento      = p_cod_evento  and
        id_evento       = var_id_evento and
        chave_processamento = var_chave_processamento::uuid;

END
$$;

alter procedure gera_resultados_v2(unknown) owner to runner_dba;

create function get_clima(p_cod_cidade integer, p_dia date, p_hora time without time zone) returns json
    language plpgsql
as
$$
DECLARE

var_registro_tempo       record;
BEGIN
select
 data_tempo,
 concat(hora_tempo)::time at time zone 'posix/Brazil/East',
 avg(precipitacao_total) as precipitacao_total,
 avg(radiacao) as radiacao,
 avg(temperatura) as temperatura,
 avg(umidade) as umidade,
 avg(vento_velocidade) as vento_velocidade
into
 var_registro_tempo
from
 tb_clima_historico his
inner join tb_clima_estacoes est on est.cod_estacao = his.cod_estacao
where
 est.cod_cidade = p_cod_cidade and
 his.data_tempo = p_dia  and
 extract( hour from hora_tempo::time at time zone 'posix/Brazil/East') = extract(hour from p_hora::time)
group by
  data_tempo,
  concat(hora_tempo)::time;

  return row_to_json(var_registro_tempo);

END
$$;

alter function get_clima(unknown, unknown, unknown) owner to runner_dba;

grant execute on function get_clima(unknown, unknown, unknown) to runner;

create function get_eventos_relacionados(p_id_evento integer, OUT id_evento integer, OUT nome_evento character varying, OUT data_inicial character varying, OUT cidade character varying, OUT endereco character varying) returns SETOF record
    language plpgsql
as
$$declare
    rec_evento_ref record;
    p_sql varchar;
    result integer;
begin
   select
    evt.nome_evento,
    (evt.data_inicial - 15)::text as data_inicial,
    (evt.data_final + 15)::text as data_final,
    evt.cidade,
    evt.estado,
    array_to_string(array_agg(percurso_evento),',') as percursos
   into
    rec_evento_ref
   from
    tb_evento_corridas evt
    inner join tb_evento_corridas_percursos prc on prc.id_evento = evt.id_evento
   where
    evt.id_evento = p_id_evento
   group by
    evt.nome_evento,
    evt.data_inicial,
    evt.data_final,
    evt.cidade,
    evt.estado;

    GET DIAGNOSTICS result = ROW_COUNT;

  if result > 0 then
    p_sql := 'select id_evento, nome_evento, data_inicial::varchar, cidade, endereco from tb_evento_corridas';
    p_sql := p_sql || ' where data_inicial::date between ' || quote_literal(rec_evento_ref.data_inicial) || '::date and ' || quote_literal(rec_evento_ref.data_final) || '::date';
    p_sql := p_sql || ' and  cidade = ' || quote_literal(rec_evento_ref.cidade);
    p_sql := p_sql || ' and  id_evento  != ' || p_id_evento;
    p_sql := p_sql || ' union ';
    p_sql := p_sql || 'select evt.id_evento, evt.nome_evento, evt.data_inicial::varchar, evt.cidade, evt.endereco from tb_evento_corridas evt ';
    p_sql := p_sql || 'inner join tb_evento_corridas_percursos pcr on pcr.id_evento = evt.id_evento';
    p_sql := p_sql || ' where evt.data_inicial::date between ' || quote_literal(rec_evento_ref.data_inicial) || '::date and ' || quote_literal(rec_evento_ref.data_final) || '::date';
    p_sql := p_sql || ' and  evt.id_evento   != ' || p_id_evento;
    p_sql := p_sql || ' and  pcr.percurso_evento in (' || rec_evento_ref.percursos || ')';
    p_sql := p_sql || ' limit 10';

    return query execute p_sql;
   end if;

end;
$$;

alter function get_eventos_relacionados(unknown, out unknown, out unknown, out unknown, out unknown, out unknown) owner to runner_dba;

create function get_id_evento_parceiro(p_id_parceiro integer, p_id_evento integer, p_percurso integer DEFAULT NULL::integer) returns integer
    language plpgsql
as
$$
DECLARE

var_id_evento_parceiro       integer;
BEGIN
    var_id_evento_parceiro := null;

    select min(id_evento_parceiro)
    FROM tb_evento_corridas_relaciona
    WHERE
    id_parceiro = p_id_parceiro and
    id_evento   = p_id_evento   and
    percurso    = p_percurso
    into var_id_evento_parceiro;

    if var_id_evento_parceiro is null then
        select min(id_evento_parceiro)
        FROM tb_evento_corridas_relaciona
        WHERE
        id_parceiro = p_id_parceiro and
        id_evento   = p_id_evento
        into var_id_evento_parceiro;
    end if;

    return var_id_evento_parceiro;

END
$$;

alter function get_id_evento_parceiro(unknown, unknown, unknown) owner to runner_dba;

grant execute on function get_id_evento_parceiro(unknown, unknown, unknown) to runner;

create function get_id_evento_parceiro_v1(p_id_parceiro integer, p_id_evento integer, p_percurso integer DEFAULT NULL::integer) returns character varying
    language plpgsql
as
$$
DECLARE

var_id_evento_parceiro       varchar;
BEGIN
    var_id_evento_parceiro := null;

    select concat(nome_variavel,'|',min(id_evento_parceiro))
    FROM tb_evento_corridas_relaciona
    WHERE
    id_parceiro = p_id_parceiro and
    id_evento   = p_id_evento   and
    percurso    = p_percurso
    group by nome_variavel,id_evento_parceiro
    into var_id_evento_parceiro;

    if var_id_evento_parceiro is null then
        select concat(nome_variavel,'|',min(id_evento_parceiro))
        FROM tb_evento_corridas_relaciona
        WHERE
        id_parceiro = p_id_parceiro and
        id_evento   = p_id_evento
        group by nome_variavel,id_evento_parceiro
        into var_id_evento_parceiro;
    end if;

    return var_id_evento_parceiro;

END
$$;

alter function get_id_evento_parceiro_v1(unknown, unknown, unknown) owner to runner_dba;

grant execute on function get_id_evento_parceiro_v1(unknown, unknown, unknown) to runner;

create function get_id_permit_parceiro(p_id_parceiro integer, p_id_evento integer, p_percurso integer DEFAULT NULL::integer) returns integer
    language plpgsql
as
$$
DECLARE

var_id_evento_parceiro       integer;
BEGIN
    var_id_evento_parceiro := null;

    select min(id_evento_parceiro)
    FROM tb_evento_corridas_relaciona
    WHERE
    id_parceiro = p_id_parceiro and
    id_evento   = p_id_evento   and
    percurso    = p_percurso
    into var_id_evento_parceiro;

    return var_id_evento_parceiro;

END
$$;

alter function get_id_permit_parceiro(unknown, unknown, unknown) owner to runner_dba;

grant execute on function get_id_permit_parceiro(unknown, unknown, unknown) to runner;

create function get_id_permit_parceiro_v1(p_id_evento integer, p_percurso integer DEFAULT NULL::integer) returns integer
    language plpgsql
as
$$
DECLARE

var_id_evento_parceiro       integer;
BEGIN
    var_id_evento_parceiro := null;

    select id_permit
    FROM tb_evento_corridas_percursos
    WHERE
    id_evento       = p_id_evento   and
    percurso_evento = p_percurso
    into var_id_evento_parceiro;

    return var_id_evento_parceiro;

END
$$;

alter function get_id_permit_parceiro_v1(unknown, unknown) owner to runner_dba;

grant execute on function get_id_permit_parceiro_v1(unknown, unknown) to runner;

create function get_media(p_id_evento integer, p_limit integer DEFAULT 5) returns json
    language plpgsql
as
$$
DECLARE

var_resultado            json;
var_nome_evento          varchar;

BEGIN

var_nome_evento := null;

select nome_evento into var_nome_evento
from tb_evento_corridas
where id_evento = p_id_evento;

if var_nome_evento is null then
   return null;
end if;

SELECT json_agg(qrf) into var_resultado from (
                              select *
                              from (
                                       select ts_rank(
                                                      to_tsvector(concat(unaccent(media_titulo), unaccent(media_descricao)))
                                                  ,
                                                      to_tsquery(unaccent(replace(var_nome_evento, ' ', '|')))) as ranking,
                                              id_media,
                                              media_url,
                                              media_tipo,
                                              media_titulo,
                                              media_descricao,
                                              media_metatags
                                       from tb_media
                                       where media_titulo is not null
                                         and concat(to_tsvector(unaccent(media_titulo)),
                                                    to_tsvector(unaccent(media_titulo)))
                                           @@
                                             to_tsquery(unaccent(replace(var_nome_evento, ' ', '|')))
                                       order by 1 desc
                                       limit p_limit
                                   ) as qry
                          ) as qrf;


return var_resultado;

END
$$;

alter function get_media(unknown, unknown) owner to runner_dba;

grant execute on function get_media(unknown, unknown) to runner;

create function get_paginas_vinculos(p_id_paginas integer) returns SETOF record
    language plpgsql
as
$$
declare
    p_sql varchar;
begin

   p_sql := 'select
    vin.id_pagina_origem,
    vin.id_pagina_destino,
    pag.id_pagina,
    pag.id_usuario_cadastro,
    pag.nome,
    pag.apelido
from
    tb_paginas_vinculos vin
inner join tb_paginas pag on pag.id_pagina = vin.id_pagina_destino
where vin.id_pagina_origem = ' || p_id_paginas ||
' union all
select
    vin.id_pagina_origem,
    vin.id_pagina_destino,
    pag.id_pagina,
    pag.id_usuario_cadastro,
    pag.nome,
    pag.apelido
from
    tb_paginas_vinculos vin
inner join tb_paginas pag on pag.id_pagina = vin.id_pagina_origem
where vin.id_pagina_destino = ' || p_id_paginas;

   return query execute p_sql;
end;
$$;

alter function get_paginas_vinculos(unknown) owner to runner_dba;

create function get_pais_padrao(p_cod_pais character varying) returns character varying
    language plpgsql
as
$$
DECLARE

var_pais_padrao  varchar;
BEGIN

var_pais_padrao := null;

if length(p_cod_pais) = 3 then
  select
  cod_alpha2
  into
  var_pais_padrao
  from
  tb_paises_iso3166
  where
  cod_alpha3 = p_cod_pais;
else
  select
  cod_alpha2
  into
  var_pais_padrao
  from
  tb_paises_iso3166
  where
  cod_alpha2 = p_cod_pais;
end if;

  return var_pais_padrao;

END
$$;

alter function get_pais_padrao(unknown) owner to runner_dba;

grant execute on function get_pais_padrao(unknown) to runner;

create function get_tag(p_desc character varying) returns character varying
    language plpgsql
as
$$
BEGIN
    RETURN translate(REGEXP_REPLACE(replace(REGEXP_REPLACE(unaccent(lower(translate(p_desc,'ª&!?:\',''))),'[^\w]+',' ','g'),'-',''),'(( ){2,}|\t+)', ' ', 'g'),' ','-');
END;
$$;

alter function get_tag(unknown) owner to runner_dba;

grant execute on function get_tag(unknown) to runner;

create function get_tempof1(p_id_evento integer, p_percurso integer, p_sexo character varying, p_categoria character varying, p_tempo_total time without time zone) returns time without time zone
    language plpgsql
as
$$
DECLARE

var_query   varchar;
var_tempof1 time;
BEGIN

if p_categoria is not null then
   select min(tempo_total)
   into var_tempof1
   from tb_resultados
   where id_evento = p_id_evento
   and sexo = p_sexo
   and nome_categoria = p_categoria
   and percurso = p_percurso
   and homologado = true and concluinte = true and status_final = 0;
else
    select min(tempo_total)
   into var_tempof1
   from tb_resultados
   where id_evento = p_id_evento
   and percurso = p_percurso
   and sexo = p_sexo
   and homologado = true and concluinte = true and status_final = 0;
end if;

if var_tempof1 is not null then
   return p_tempo_total - var_tempof1;
  else
   return null;
end if;

END
$$;

alter function get_tempof1(unknown, unknown, unknown, unknown, unknown) owner to runner_dba;

grant execute on function get_tempof1(unknown, unknown, unknown, unknown, unknown) to runner;

create function grava_evento_corridas_percursos() returns trigger
    language plpgsql
as
$$
DECLARE

var_data_percurso   date;
var_num_dias        integer;
var_arr_percursos   numeric[];
var_unidade         varchar;
prc                 numeric;


BEGIN

    if NEW.categorias is distinct from  OLD.categorias then
        delete from  tb_evento_corridas_percursos where id_evento = NEW.id_evento and percurso_bloqueado = false;

        if NEW.categorias is null then
            return NEW;
        end if;

        if position('km' in lower(NEW.categorias)) > 0 then
            var_unidade := 'km';
        else
            if position('milha' in lower(NEW.categorias)) > 0 or position('milha' in lower(NEW.nome_evento)) > 0  then
                var_unidade := 'mi';
            else
                var_unidade := '--';
            end if;
        end if;

        var_arr_percursos := array_remove(string_to_array(regexp_replace(NEW.categorias, '[^0-9.,]','','g'),','),'');
        var_num_dias := (NEW.data_final - NEW.data_inicial) + 1;

        foreach prc in array var_arr_percursos loop
            if prc < 21 then
            var_data_percurso := NEW.data_inicial;
            else
                if prc < 42 then
                    if var_num_dias = 1 then
                    var_data_percurso := NEW.data_inicial;
                    else
                    var_data_percurso := NEW.data_inicial + 1;
                    end if;
                else
                    if var_num_dias = 1 then
                    var_data_percurso := NEW.data_inicial;
                    else
                    var_data_percurso := NEW.data_final;
                    end if;
                end if;
            end if;

            insert into tb_evento_corridas_percursos
            ( percurso_evento, unidade_de_medida, id_evento, data_percurso, tipo_corrida )
            values
            ( prc, var_unidade, NEW.id_evento, var_data_percurso, NEW.tipo_corrida )
            on CONFLICT (percurso_evento, id_evento) DO UPDATE
            SET
                percurso_evento   = excluded.percurso_evento,
                unidade_de_medida = excluded.unidade_de_medida,
                id_evento         = excluded.id_evento,
                data_percurso     = excluded.data_percurso;
        end loop;
    end if;

    if NEW.organizador is distinct from OLD.organizador then
        insert into tb_evento_corridas_fornecedores
            ( id_evento, id_fornecedor_tipo, id_fornecedor )
        select
            NEW.id_evento,
            1,
            fo.id_fornecedor
        from  tb_fornecedores fo
            where to_tsvector(unaccent(fo.nome_fornecedor)) @@ plainto_tsquery('portuguese',unaccent(trim(NEW.organizador)))
        on CONFLICT (id_evento, id_fornecedor_tipo, id_fornecedor) DO UPDATE
        SET
            id_fornecedor   = excluded.id_fornecedor;
    end if;

RETURN NEW;
END
$$;

alter function grava_evento_corridas_percursos() owner to runner_dba;

create procedure grava_evento_corridas_percursos(IN p_id_evento integer, IN p_nome_evento character varying, IN p_data_ini date, IN p_data_fim date, IN p_categorias character varying)
    language plpgsql
as
$$
DECLARE

var_percurso        integer;
var_data_percurso   date;
var_num_dias        integer;
var_arr_percursos   numeric[];
var_unidade         varchar;
prc                 integer;

BEGIN
    if p_categorias is null then
        return;
    end if;
    if position('km' in lower(p_categorias)) > 0 then
        var_unidade := 'km';
    else
        if position('milha' in lower(p_categorias)) > 0 or position('milha' in lower(p_nome_evento)) > 0  then
            var_unidade := 'mi';
        else
            var_unidade := '--';
        end if;
    end if;

    var_arr_percursos := array_remove(string_to_array(regexp_replace(p_categorias, '[^0-9.,]','','g'),','),'');
    var_num_dias := (p_data_fim - p_data_ini) + 1;

    foreach prc in array var_arr_percursos loop
        if prc < 21 then
           var_data_percurso := p_data_ini;
        else
            if prc < 42 then
                if var_num_dias = 1 then
                   var_data_percurso := p_data_ini;
                 else
                   var_data_percurso := p_data_ini + 1;
                end if;
            else
                if var_num_dias = 1 then
                   var_data_percurso := p_data_ini;
                 else
                   var_data_percurso := p_data_fim;
                end if;
            end if;
        end if;

        insert into tb_evento_corridas_percursos
          ( percurso_evento, unidade_de_medida, id_evento, data_percurso )
        values
          ( prc, var_unidade, p_id_evento, var_data_percurso )
        on CONFLICT (percurso_evento, id_evento) DO UPDATE
        SET
            percurso_evento   = excluded.percurso_evento,
            unidade_de_medida = excluded.unidade_de_medida,
            id_evento         = excluded.id_evento,
            data_percurso     = excluded.data_percurso;
    end loop;

END
$$;

alter procedure grava_evento_corridas_percursos(unknown, unknown, unknown, unknown, unknown) owner to runner_dba;

grant execute on procedure grava_evento_corridas_percursos(unknown, unknown, unknown, unknown, unknown) to runner;

create function grava_logs_resultados(p_cod_evento text, p_num_peito integer, p_nome text, p_categoria text, p_id_evento integer, p_chave_proc text, p_msg text) returns integer
    language plpgsql
as
$$
DECLARE

BEGIN
    insert into tb_resultados_processa_logs
        ( cod_evento, id_evento, data_processamento, chave_processamento, erro_execucao, log_execucao )
            values
        ( p_cod_evento, p_id_evento, current_timestamp, p_chave_proc::uuid, true,p_msg);
    --update
    --    new_tb_resultados_temp
    --set
    --    chave_processamento = p_chave_proc::uuid
    --where
    --    id_evento   =   p_cod_evento and
    --    num_peito   =   p_num_peito  and
    --    nome        =   p_nome       and
    --    categoria   =   p_categoria;

    return 0;
END;
$$;

alter function grava_logs_resultados(unknown, unknown, unknown, unknown, unknown, unknown, unknown) owner to runner_dba;

grant execute on function grava_logs_resultados(unknown, unknown, unknown, unknown, unknown, unknown, unknown) to runner;

create function nome_dia(integer) returns character varying
    language sql
as
$$
SELECT Case $1
when 0 then 'Domingo'
when 1 then 'Segunda-feira'
when 2 then 'Terça-feira'
when 3 then 'Quarta-feira'
when 4 then 'Quinta-feira'
when 5 then 'Sexta-feira'
when 6 then 'Sábado'
else NULL
end
$$;

alter function nome_dia(unknown) owner to runner_dba;

create function nome_mes(integer) returns character varying
    language sql
as
$$
SELECT Case $1
when 1 then 'Janeiro'
when 2 then 'Fevereiro'
when 3 then 'Março'
when 4 then 'Abril'
when 5 then 'Maio'
when 6 then 'Junho'
when 7 then 'Julho'
when 8 then 'Agosto'
when 9 then 'Setembro'
when 10 then 'Outubro'
when 11 then 'Novembro'
when 12 then 'Dezembro'
else NULL
end
$$;

alter function nome_mes(unknown) owner to runner_dba;

create function numero_valido(p_numero character varying) returns boolean
    language plpgsql
as
$$
DECLARE
    numero_valido boolean := p_numero ~ '^([0-9]{0,10})\.?([0-9]{0,10})$';
BEGIN
    if p_numero is null then
        RETURN true;
    end if;
    RETURN numero_valido;
END;
$$;

alter function numero_valido(unknown) owner to postgres;

grant execute on function numero_valido(unknown) to runner;

create function percursos_corrida(p_id_evento integer) returns character varying
    language plpgsql
as
$$
DECLARE

var_percursos       varchar;
BEGIN
    select array(SELECT distinct percurso
    FROM tb_resultados res
    WHERE
    res.id_evento = p_id_evento and
    percurso is not null) into var_percursos;

    return var_percursos;

END
$$;

alter function percursos_corrida(unknown) owner to runner_dba;

grant execute on function percursos_corrida(unknown) to runner;

create procedure processa_desafio()
    language plpgsql
as
$$
DECLARE

rec_resultados                  record;


cur_resultados cursor for
select distinct
    classificacao,
    num_peito,
    nome,
    sexo,
    idade,
    categoria,
    tempo_bruto,
    tempo_total,
    percurso,
    modalidade,
    modalidade2
from
    desafio_temp
order by
    percurso,classificacao,nome,sexo,idade,categoria;

BEGIN
    open cur_resultados;
    loop
        fetch cur_resultados into rec_resultados;
        exit when not found;

        insert into desafio_final
        (   classificacao,
            num_peito,
            nome,
            sexo,
            idade,
            categoria,
            tempo_bruto,
            tempo_total,
            percurso,
            modalidade,
            modalidade2
        ) values (
            rec_resultados.classificacao,
            rec_resultados.num_peito,
            rec_resultados.nome,
            rec_resultados.sexo,
            rec_resultados.idade,
            rec_resultados.categoria,
            rec_resultados.tempo_bruto,
            rec_resultados.tempo_total,
            rec_resultados.percurso,
            rec_resultados.modalidade,
            rec_resultados.modalidade2
        )
        ON CONFLICT (nome,sexo,idade,categoria,percurso) DO NOTHING;
    end loop;
    close cur_resultados;


END
$$;

alter procedure processa_desafio() owner to runner_dba;

create function tempo_valido(p_tempo character varying) returns boolean
    language plpgsql
as
$$
DECLARE
    --tempo_valido boolean := p_tempo ~ '^([0-1]{1}[0-9]{1}|[2-2]{1}[0-3]{1}):([0-5]{1}[0-9]{1}|[2-2]{1}[0-4]{1}):([0-5]{1}[0-9]{1}|[2-2]{1}[0-4]{1})$';
    tempo_valido boolean := p_tempo ~ '^(([01]?[0-9])|([2][0-3])):([0-5][0-9])(:[0-5][0-9](?:[.]\d{1,3})?)?$';
BEGIN
    RETURN tempo_valido;
END;
$$;

alter function tempo_valido(unknown) owner to postgres;

grant execute on function tempo_valido(unknown) to runner;

create function teste_filtro(filtro jsonb) returns integer
    language plpgsql
as
$$
declare
    contador integer;
    p_filtro text;
    p_where  boolean := false;
    p_sql text := 'SELECT count(*)::integer as contador FROM tb_evento_corridas';
    p_estado varchar;
    p_cidade varchar;
    i jsonb;
begin

   p_estado := filtro->'estado';

    if p_estado is not null then
        if p_where = false then
            p_sql := concat(p_sql,' where estado = ', quote_literal (TRIM(p_estado, '"')));
            p_where := true;
        else
            p_sql := concat(p_sql,' and estado = ',quote_literal (TRIM(p_estado, '"')));
        end if;
    end if;

      --RAISE exception 'Value: %', p_sql;

   p_cidade := filtro->'cidade';

    if p_cidade is not null then
        if p_where = false then
            p_sql := concat(p_sql,' where cidade = ',quote_literal (TRIM(p_cidade, '"')));
            p_where := true;
        else
            p_sql := concat(p_sql,' and cidade = ',quote_literal (TRIM(p_cidade, '"')));
        end if;
    end if;

   --RAISE exception 'Value: %', p_sql;

    EXECUTE p_sql  INTO contador;

    return contador;
end;
$$;

alter function teste_filtro(unknown) owner to runner_dba;

create function teste_filtro_lista(filtro jsonb) returns json
    language plpgsql
as
$$
declare
    ret_json json;
    contador integer;
    p_filtro text;
    p_where  boolean := false;
    p_sql text := 'SELECT nome_evento, estado, cidade, data_inicial FROM tb_evento_corridas';
    p_estado varchar;
    p_cidade varchar;
    i jsonb;
begin

   p_estado := filtro->'estado';

    if p_estado is not null then
        if p_where = false then
            p_sql := concat(p_sql,' where estado = ', quote_literal (TRIM(p_estado, '"')));
            p_where := true;
        else
            p_sql := concat(p_sql,' and estado = ',quote_literal (TRIM(p_estado, '"')));
        end if;
    end if;

      --RAISE exception 'Value: %', p_sql;

   p_cidade := filtro->'cidade';

    if p_cidade is not null then
        if p_where = false then
            p_sql := concat(p_sql,' where cidade = ',quote_literal (TRIM(p_cidade, '"')));
            p_where := true;
        else
            p_sql := concat(p_sql,' and cidade = ',quote_literal (TRIM(p_cidade, '"')));
        end if;
    end if;

   p_sql := concat('select json_agg(row_to_json(linha)) from (', p_sql,') linha');

   --RAISE exception 'Value: %', p_sql;

   EXECUTE p_sql into ret_json;

   return ret_json;
end;
$$;

alter function teste_filtro_lista(unknown) owner to runner_dba;

create function teste_get_recordset(OUT uf text, OUT nome_cidade text) returns SETOF record
    language sql
as
$$ SELECT uf,nome_cidade FROM tb_cidades $$;

alter function teste_get_recordset(out unknown, out unknown) owner to runner_dba;

create function teste_get_recordset_json() returns json
    language sql
as
$$

select json_agg(row_to_json(linha)) from (select uf,nome_cidade from tb_cidades) linha
$$;

alter function teste_get_recordset_json() owner to runner_dba;

create function trg_atualiza_nome_evento_full_text() returns trigger
    language plpgsql
as
$$
DECLARE

BEGIN

    if NEW.nome_evento is distinct from  OLD.nome_evento then
        NEW.nome_evento_full_text := to_tsvector('portuguese',NEW.nome_evento);
    end if;

RETURN NEW;
END
$$;

alter function trg_atualiza_nome_evento_full_text() owner to runner_dba;

create function trg_atualiza_nome_full_text() returns trigger
    language plpgsql
as
$$
DECLARE

BEGIN

    if  coalesce(NEW.nome,'NULO') <>  coalesce(OLD.nome,'NULO')  then
        NEW.nome_full_text := to_tsvector('portuguese',NEW.nome);
    end if;

RETURN NEW;
END
$$;

alter function trg_atualiza_nome_full_text() owner to runner_dba;

create function padrao_nomes(p_nome character varying) returns character varying
    language plpgsql
as
$$
DECLARE

BEGIN
    p_nome = initcap(p_nome);
    p_nome = replace(p_nome,' De ',' de ');
    p_nome = replace(p_nome,' A ',' a ');
    p_nome = replace(p_nome,' E ',' e ');
    p_nome = replace(p_nome,' Com ',' com ');
    p_nome = replace(p_nome,' De ',' de ');
    p_nome = replace(p_nome,' Da ',' da ');
    p_nome = replace(p_nome,' Do ',' do ');
    p_nome = replace(p_nome,' Dos ',' dos ');
    p_nome = replace(p_nome,' Das ',' das ');
    p_nome = replace(p_nome,' Em ',' em ');
    p_nome = replace(p_nome,' Xp ',' XP ');
    p_nome = replace(p_nome,' Na ',' na ');
    p_nome = replace(p_nome,' No ',' no ');
    p_nome = replace(p_nome,' Nas ',' nas ');
    p_nome = replace(p_nome,' Nos ',' nos ');
    p_nome = replace(p_nome,' ','');
    p_nome = replace(p_nome,'Xxvi','XXVI');
    p_nome = replace(p_nome,'Xxv','XXV');
    p_nome = replace(p_nome,'Ii','II');
    p_nome = replace(p_nome,'Iii','III');
    p_nome = replace(p_nome,'Iv ','IV ');
    p_nome = replace(p_nome,'Vi ','VI ');
    p_nome = replace(p_nome,'Ttt ','TTT ');
    p_nome = replace(p_nome,'Sp','SP');
    p_nome = replace(p_nome,'Rj','RJ');
    p_nome = replace(p_nome,'Mg','MG');
    p_nome = replace(p_nome,'Pb','PB');

   return p_nome;
END;
$$;

alter function padrao_nomes(unknown) owner to postgres;

grant execute on function padrao_nomes(unknown) to runner;

create function limpar_assessoria(p_nome character varying) returns character varying
    language plpgsql
as
$$
DECLARE

BEGIN
    p_nome = upper(p_nome);
    p_nome = replace(p_nome,' ','');
    p_nome = replace(p_nome,'ASSESSORIA','');
    p_nome = replace(p_nome,'ACESSORIA','');
    p_nome = replace(p_nome,'ESPORTIVA','');
    p_nome = replace(p_nome,'NÃO POSSUO','');
    p_nome = replace(p_nome,'NÃO POSSUO','');
    p_nome = replace(p_nome,'INDIVIDUAL','');
    --p_nome = replace(p_nome,'NA','');
    p_nome = replace(p_nome,'SIM','');
    p_nome = replace(p_nome,'N/A','');
    p_nome = replace(p_nome,'NAO TENHO','');
    p_nome = replace(p_nome,'NÃO','');
    p_nome = replace(p_nome,'NAO','');
    p_nome = replace(p_nome,'-','');
    p_nome = replace(p_nome,'.','');
    p_nome = replace(p_nome,'NÃO TEM','');
    p_nome = replace(p_nome,'NENHUMA','');
    p_nome = replace(p_nome,'SEM','');
    p_nome = replace(p_nome,'NAO TEM','');
    p_nome = replace(p_nome,'NENHUM','');
    p_nome = replace(p_nome,'AVULSO','');
    p_nome = replace(p_nome,'NÃO TENHO','');
    p_nome = trim(p_nome);

   return p_nome;
END;
$$;

alter function limpar_assessoria(unknown) owner to postgres;

grant execute on function limpar_assessoria(unknown) to runner;

create procedure atualiza_resumo_geral()
    language plpgsql
as
$$
DECLARE

rec_evento        record;

cur_evento cursor for
select
    distinct id_evento as id_evento
from
    tb_resultados res
order by id_evento;

BEGIN
    open cur_evento;
    loop
        fetch cur_evento into rec_evento;
        exit when not found;

        call atualiza_resultados_resumo_2025(rec_evento.id_evento);

    end loop;

    close cur_evento;

END
$$;

alter procedure atualiza_resumo_geral() owner to runner_dba;

grant execute on procedure atualiza_resumo_geral() to runner;

create procedure atualiza_todosantodia()
    language plpgsql
as
$$
DECLARE

var_maior_sequencia integer;
var_sequencia_atual integer;
rec_participantes   record;
rec_atividades      record;
cur_participantes cursor for

SELECT
    distinct
    usr.id as usuario_id,
    usr.strava_id,
    pag.id_pagina, des.desafio
FROM desafios des
inner join tb_usuarios usr on usr.id = des.id_usuario
inner join tb_paginas pag on pag.id_usuario_cadastro = usr.id
WHERE des.status = 'C' and desafio = 'todosantodia'
ORDER BY usr.id;


BEGIN
    var_maior_sequencia  := 0;
    var_sequencia_atual  := 0;

    open cur_participantes;
    loop
        fetch cur_participantes into rec_participantes;
        exit when not found;

        WITH registros AS (
        select distinct dat_atividade from
            (
                SELECT DISTINCT activity_date::date AS dat_atividade
                FROM tb_strava_activities
                WHERE athlete_id = rec_participantes.strava_id
                    AND type IN ('Run', 'VirtualRun', 'TrailRun')
                    AND distance >= 990
                union all
                SELECT DISTINCT activity_date::date AS dat_atividade
                FROM tb_strava_activities
                WHERE id_athlete_donation = rec_participantes.strava_id
                    AND type IN ('Run', 'VirtualRun', 'TrailRun')
                    AND distance >= 990
            ) as qry_atividades
        ),
        base AS (
        SELECT
            dat_atividade,
            ROW_NUMBER() OVER (ORDER BY dat_atividade) AS rn
        FROM registros
        ),
        grupos AS (
        SELECT
            dat_atividade,
            dat_atividade - rn::int AS grp
        FROM base
        ),
        sequencias AS (
        SELECT
            MIN(dat_atividade) AS dt_inicio,
            MAX(dat_atividade) AS dt_fim,
            COUNT(*)           AS qtd_dias
        FROM grupos
        GROUP BY grp
        ),
        ultima AS (
        SELECT *
        FROM sequencias
        ORDER BY dt_fim DESC
        LIMIT 1
        )
        SELECT distinct
        (SELECT MIN(dt_inicio) FROM sequencias) AS correndo_desde,
        (SELECT MAX(qtd_dias)  FROM sequencias) AS maior_sequencia,
        CASE
            WHEN (SELECT dt_fim FROM ultima) >= current_date - 1
            THEN (SELECT dt_inicio FROM ultima)
            ELSE NULL
        END AS correndo_atualmente,
        CASE
            WHEN (SELECT dt_fim FROM ultima) >= current_date - 1
            THEN (SELECT qtd_dias FROM ultima)
            ELSE NULL
        END AS sequencia_atual
        FROM grupos
        into
        rec_atividades;

if rec_atividades.maior_sequencia >= 30 then
        insert into
            tb_paginas_badges
            ( id_pagina, badge, valor, contador, meta )
        values
            ( rec_participantes.id_pagina, 'todosantodia_30', rec_atividades.maior_sequencia, 1, 30 )
        ON CONFLICT (id_pagina,badge) DO NOTHING;
        end if;

        if rec_atividades.maior_sequencia >= 100 then
        insert into
            tb_paginas_badges
            ( id_pagina, badge, valor, contador, meta )
        values
            ( rec_participantes.id_pagina, 'todosantodia_100', rec_atividades.maior_sequencia, 1, 100 )
        ON CONFLICT (id_pagina,badge) DO NOTHING;
        end if;

        if rec_atividades.maior_sequencia >= 365 then
        insert into
            tb_paginas_badges
            ( id_pagina, badge, valor, contador, meta )
        values
            ( rec_participantes.id_pagina, 'todosantodia_365', rec_atividades.maior_sequencia, 1, 365 )
        ON CONFLICT (id_pagina,badge) DO NOTHING;
        end if;

        if rec_atividades.maior_sequencia >= 500 then
        insert into
            tb_paginas_badges
            ( id_pagina, badge, valor, contador, meta )
        values
            ( rec_participantes.id_pagina, 'todosantodia_500', rec_atividades.maior_sequencia, 1, 500 )
        ON CONFLICT (id_pagina,badge) DO NOTHING;
        end if;

        if rec_atividades.maior_sequencia >= 750 then
        insert into
            tb_paginas_badges
            ( id_pagina, badge, valor, contador, meta )
        values
            ( rec_participantes.id_pagina, 'todosantodia_750', rec_atividades.maior_sequencia, 1, 750 )
        ON CONFLICT (id_pagina,badge) DO NOTHING;
        end if;

        if rec_atividades.maior_sequencia >= 1000 then
        insert into
            tb_paginas_badges
            ( id_pagina, badge, valor, contador, meta )
        values
            ( rec_participantes.id_pagina, 'todosantodia_1000', rec_atividades.maior_sequencia, 1, 1000 )
        ON CONFLICT (id_pagina,badge) DO NOTHING;
        end if;

        if rec_atividades.maior_sequencia >= 1500 then
        insert into
            tb_paginas_badges
            ( id_pagina, badge, valor, contador, meta )
        values
            ( rec_participantes.id_pagina, 'todosantodia_1500', rec_atividades.maior_sequencia, 1, 1500 )
        ON CONFLICT (id_pagina,badge) DO NOTHING;
        end if;

        if rec_atividades.maior_sequencia >= 2000 then
        insert into
            tb_paginas_badges
            ( id_pagina, badge, valor, contador, meta )
        values
            ( rec_participantes.id_pagina, 'todosantodia_2000', rec_atividades.maior_sequencia, 1, 2000 )
        ON CONFLICT (id_pagina,badge) DO NOTHING;
        end if;

    end loop;

    close cur_participantes;
END
$$;

alter procedure atualiza_todosantodia() owner to runner_dba;

grant execute on procedure atualiza_todosantodia() to runner;

create function extrair_faixa_etaria(texto text) returns text
    immutable
    language plpgsql
as
$$
DECLARE
    v_min TEXT;
    v_max TEXT;
    v_lim_f TEXT;
BEGIN
    -- 1) Faixas explícitas: 10-17, 10/17, 10 a 17, 10A17
    SELECT
        m[1], m[2]
    INTO
        v_min, v_max
    FROM regexp_matches(
        texto,
        '(?<!\d)(\d{2})\s*(?:-|/|A|a|\s+a\s+)\s*(\d{2})(?!\d)'
    ) AS m
    LIMIT 1;

    IF v_min > v_max THEN
        RETURN null;
    end if;

    if v_max = '99' THEN
        v_lim_f := ']';
    else
        if substring(v_max,2,1) = '9' or substring(v_max,2,1) = '4' then
            v_max = (cast(v_max as integer) + 1)::text;
        end if;
        v_lim_f := ')';
    end if;

    IF v_min IS NOT NULL THEN
        RETURN '[' || v_min || ',' || v_max || v_lim_f;
    END IF;

    -- 2) Faixa concatenada: 1019, 1629, 5559
    SELECT
        m[1], m[2]
    INTO
        v_min, v_max
    FROM regexp_matches(
        texto,
        '(?<!\d)(\d{2})(\d{2})(?!\d)'
    ) AS m
    LIMIT 1;

    IF v_min > v_max THEN
        RETURN null;
    end if;

    if v_max = '99' THEN
        v_lim_f := ']';
    else
        if substring(v_max,2,1) = '9' or substring(v_max,2,1) = '4' then
            v_max = (cast(v_max as integer) + 1)::text;
        end if;
        v_lim_f := ')';
    end if;

    IF v_min IS NOT NULL THEN
        RETURN '[' || v_min || ',' || v_max || v_lim_f;
    END IF;

    -- 3) Faixa aberta: 60+, 70 +
    SELECT
        m[1]
    INTO
        v_min
    FROM regexp_matches(
        texto,
        '(?<!\d)(\d{2})\s*\+(?!\d)'
    ) AS m
    LIMIT 1;

    IF v_min IS NOT NULL THEN
        RETURN '[' || v_min || ',99]';
    END IF;

    -- Nenhuma faixa encontrada
    RETURN NULL;
END;
$$;

alter function extrair_faixa_etaria(unknown) owner to runner_dba;

create function get_id_dim_faixa(p_percurso numeric, p_tempo_total time without time zone) returns integer
    language plpgsql
as
$$
DECLARE

var_id_dim_faixa       integer;
BEGIN
    var_id_dim_faixa := 0;

    if p_tempo_total is null then
        return var_id_dim_faixa;
    end if;

    if p_percurso >= 5 and p_percurso < 6 then
        CASE
            WHEN p_tempo_total < TIME '00:15:00' THEN var_id_dim_faixa := 1; -- Faixa Preta < 15 min
            WHEN p_tempo_total < TIME '00:17:00' THEN var_id_dim_faixa := 2; -- Faixa Marrom < 17 min
            WHEN p_tempo_total < TIME '00:20:00' THEN var_id_dim_faixa := 3; -- Faixa Vermelha < 20 min
            WHEN p_tempo_total < TIME '00:22:00' THEN var_id_dim_faixa := 4; -- Faixa Azul < 22 min
            WHEN p_tempo_total < TIME '00:25:00' THEN var_id_dim_faixa := 5; -- Faixa Amarela < 25 min
            WHEN p_tempo_total < TIME '00:27:00' THEN var_id_dim_faixa := 6; -- Faixa Laranja < 27 min
            WHEN p_tempo_total < TIME '00:30:00' THEN var_id_dim_faixa := 7; -- Faixa Branca < 30 min
            ELSE var_id_dim_faixa := 8;
        END CASE;
        RETURN var_id_dim_faixa;
    end if;

    if p_percurso >= 10 and p_percurso < 11 then
        CASE
            WHEN p_tempo_total < TIME '00:35:00' THEN var_id_dim_faixa := 9; -- Faixa Preta < 35 min
            WHEN p_tempo_total < TIME '00:40:00' THEN var_id_dim_faixa := 10; -- Faixa Marrom < 37 min
            WHEN p_tempo_total < TIME '00:42:00' THEN var_id_dim_faixa := 11; -- Faixa Vermelha < 40 min
            WHEN p_tempo_total < TIME '00:45:00' THEN var_id_dim_faixa := 12; -- Faixa Azul < 45 min
            WHEN p_tempo_total < TIME '00:50:00' THEN var_id_dim_faixa := 13; -- Faixa Amarela < 50 min
            WHEN p_tempo_total < TIME '00:55:00' THEN var_id_dim_faixa := 14; -- Faixa Laranja < 55 min
            WHEN p_tempo_total < TIME '01:00:00' THEN var_id_dim_faixa := 15; -- Faixa Branca < 60 min
            ELSE var_id_dim_faixa := 16;
        END CASE;
        RETURN var_id_dim_faixa;
    end if;

    if p_percurso >= 21 and p_percurso < 22 then
        CASE
            WHEN p_tempo_total < TIME '01:20:00' THEN var_id_dim_faixa := 17; -- Faixa Preta < 1h20
            WHEN p_tempo_total < TIME '01:25:00' THEN var_id_dim_faixa := 18; -- Faixa Marrom < 1h25
            WHEN p_tempo_total < TIME '01:30:00' THEN var_id_dim_faixa := 19; -- Faixa Vermelha < 1h30
            WHEN p_tempo_total < TIME '01:40:00' THEN var_id_dim_faixa := 20; -- Faixa Azul < 1h35
            WHEN p_tempo_total < TIME '01:45:00' THEN var_id_dim_faixa := 21;-- Faixa Amarela < 1h40
            WHEN p_tempo_total < TIME '01:50:00' THEN var_id_dim_faixa := 22; -- Faixa Laranja < 1h45
            WHEN p_tempo_total < TIME '02:00:00' THEN var_id_dim_faixa := 23; -- Faixa Branca < 1h50
            ELSE var_id_dim_faixa := 24;
        END CASE;
        RETURN var_id_dim_faixa;
    end if;

    if p_percurso >= 42 and p_percurso < 43 then
        CASE
            WHEN p_tempo_total < TIME '02:30:00' THEN var_id_dim_faixa := 25; -- Faixa Preta < 2h30
            WHEN p_tempo_total < TIME '02:45:00' THEN var_id_dim_faixa := 26;
            WHEN p_tempo_total < TIME '03:00:00' THEN var_id_dim_faixa := 27;
            WHEN p_tempo_total < TIME '03:15:00' THEN var_id_dim_faixa := 28;
            WHEN p_tempo_total < TIME '03:30:00' THEN var_id_dim_faixa := 29;
            WHEN p_tempo_total < TIME '03:45:00' THEN var_id_dim_faixa := 30;
            WHEN p_tempo_total < TIME '04:00:00' THEN var_id_dim_faixa := 31;
            ELSE var_id_dim_faixa := 32;
        END CASE;
        RETURN var_id_dim_faixa;
    end if;

    return var_id_dim_faixa;

END
$$;

alter function get_id_dim_faixa(unknown, unknown) owner to runner_dba;

grant execute on function get_id_dim_faixa(unknown, unknown) to runner;

create function get_id_geracao(p_faixa_idade int4range, p_ano_referencia integer) returns integer
    immutable
    language sql
as
$$
SELECT
    CASE

        WHEN p_faixa_idade IS NULL OR p_ano_referencia IS NULL THEN 0
        WHEN int4range(
                 p_ano_referencia - upper(p_faixa_idade),
                 p_ano_referencia - lower(p_faixa_idade),
                 '[)'
             ) && int4range(1946, 1965, '[)') THEN 1
        WHEN int4range(
                 p_ano_referencia - upper(p_faixa_idade),
                 p_ano_referencia - lower(p_faixa_idade),
                 '[)'
             ) && int4range(1965, 1981, '[)') THEN 2
        WHEN int4range(
                 p_ano_referencia - upper(p_faixa_idade),
                 p_ano_referencia - lower(p_faixa_idade),
                 '[)'
             ) && int4range(1981, 1996, '[)') THEN 3
        WHEN int4range(
                 p_ano_referencia - upper(p_faixa_idade),
                 p_ano_referencia - lower(p_faixa_idade),
                 '[)'
             ) && int4range(1996, 2011, '[)') THEN 4
        WHEN int4range(
                 p_ano_referencia - upper(p_faixa_idade),
                 p_ano_referencia - lower(p_faixa_idade),
                 '[)'
             ) && int4range(2010, NULL, '[)') THEN 0
        ELSE 0
    END;
$$;

alter function get_id_geracao(unknown, unknown) owner to runner_dba;

create function get_id_categoria_cbat(p_faixa_atleta int4range) returns integer
    immutable
    language sql
as
$$
SELECT
    CASE
        WHEN p_faixa_atleta IS NULL THEN 0
        WHEN p_faixa_atleta && int4range(13, 20, '[)') THEN 1
        WHEN p_faixa_atleta && int4range(20, 25, '[)') THEN 2
        WHEN p_faixa_atleta && int4range(25, 30, '[)') THEN 3
        WHEN p_faixa_atleta && int4range(30, 35, '[)') THEN 4
        WHEN p_faixa_atleta && int4range(35, 40, '[)') THEN 5
        WHEN p_faixa_atleta && int4range(40, 45, '[)') THEN 6
        WHEN p_faixa_atleta && int4range(45, 50, '[)') THEN 7
        WHEN p_faixa_atleta && int4range(50, 55, '[)') THEN 8
        WHEN p_faixa_atleta && int4range(55, 60, '[)') THEN 9
        WHEN p_faixa_atleta && int4range(60, 65, '[)') THEN 10
        WHEN p_faixa_atleta && int4range(65, 70, '[)') THEN 11
        WHEN p_faixa_atleta && int4range(70, null, '[)') THEN 12
        ELSE 0
    END;
$$;

alter function get_id_categoria_cbat(unknown) owner to runner_dba;

create function set_limit(unknown) returns real
    strict
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function set_limit(unknown) owner to runner_dba;

create function show_limit() returns real
    stable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function show_limit() owner to runner_dba;

create function show_trgm(unknown) returns text[]
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function show_trgm(unknown) owner to runner_dba;

create function similarity(unknown, unknown) returns real
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function similarity(unknown, unknown) owner to runner_dba;

create function similarity_op(unknown, unknown) returns boolean
    stable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function similarity_op(unknown, unknown) owner to runner_dba;

create function word_similarity(unknown, unknown) returns real
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function word_similarity(unknown, unknown) owner to runner_dba;

create function word_similarity_op(unknown, unknown) returns boolean
    stable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function word_similarity_op(unknown, unknown) owner to runner_dba;

create function word_similarity_commutator_op(unknown, unknown) returns boolean
    stable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function word_similarity_commutator_op(unknown, unknown) owner to runner_dba;

create function similarity_dist(unknown, unknown) returns real
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function similarity_dist(unknown, unknown) owner to runner_dba;

create function word_similarity_dist_op(unknown, unknown) returns real
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function word_similarity_dist_op(unknown, unknown) owner to runner_dba;

create function word_similarity_dist_commutator_op(unknown, unknown) returns real
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function word_similarity_dist_commutator_op(unknown, unknown) owner to runner_dba;

create function gtrgm_in(unknown) returns gtrgm
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gtrgm_in(unknown) owner to runner_dba;

create function gtrgm_out(unknown) returns cstring
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gtrgm_out(unknown) owner to runner_dba;

create function gtrgm_consistent(unknown, unknown, unknown, unknown, unknown) returns boolean
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gtrgm_consistent(unknown, unknown, unknown, unknown, unknown) owner to runner_dba;

create function gtrgm_distance(unknown, unknown, unknown, unknown, unknown) returns double precision
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gtrgm_distance(unknown, unknown, unknown, unknown, unknown) owner to runner_dba;

create function gtrgm_compress(unknown) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gtrgm_compress(unknown) owner to runner_dba;

create function gtrgm_decompress(unknown) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gtrgm_decompress(unknown) owner to runner_dba;

create function gtrgm_penalty(unknown, unknown, unknown) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gtrgm_penalty(unknown, unknown, unknown) owner to runner_dba;

create function gtrgm_picksplit(unknown, unknown) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gtrgm_picksplit(unknown, unknown) owner to runner_dba;

create function gtrgm_union(unknown, unknown) returns gtrgm
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gtrgm_union(unknown, unknown) owner to runner_dba;

create function gtrgm_same(unknown, unknown, unknown) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gtrgm_same(unknown, unknown, unknown) owner to runner_dba;

create function gin_extract_value_trgm(unknown, unknown) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gin_extract_value_trgm(unknown, unknown) owner to runner_dba;

create function gin_extract_query_trgm(unknown, unknown, unknown, unknown, unknown, unknown, unknown) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gin_extract_query_trgm(unknown, unknown, unknown, unknown, unknown, unknown, unknown) owner to runner_dba;

create function gin_trgm_consistent(unknown, unknown, unknown, unknown, unknown, unknown, unknown, unknown) returns boolean
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gin_trgm_consistent(unknown, unknown, unknown, unknown, unknown, unknown, unknown, unknown) owner to runner_dba;

create function gin_trgm_triconsistent(unknown, unknown, unknown, unknown, unknown, unknown, unknown) returns "char"
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gin_trgm_triconsistent(unknown, unknown, unknown, unknown, unknown, unknown, unknown) owner to runner_dba;

create function strict_word_similarity(unknown, unknown) returns real
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function strict_word_similarity(unknown, unknown) owner to runner_dba;

create function strict_word_similarity_op(unknown, unknown) returns boolean
    stable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function strict_word_similarity_op(unknown, unknown) owner to runner_dba;

create function strict_word_similarity_commutator_op(unknown, unknown) returns boolean
    stable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function strict_word_similarity_commutator_op(unknown, unknown) owner to runner_dba;

create function strict_word_similarity_dist_op(unknown, unknown) returns real
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function strict_word_similarity_dist_op(unknown, unknown) owner to runner_dba;

create function strict_word_similarity_dist_commutator_op(unknown, unknown) returns real
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function strict_word_similarity_dist_commutator_op(unknown, unknown) owner to runner_dba;

create function gtrgm_options(unknown) returns void
    immutable
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gtrgm_options(unknown) owner to runner_dba;

create function grava_logs_results(p_trace_id uuid, p_run_id uuid, p_cod_evento text, p_percurso character varying, p_num_peito character varying, p_severity character varying, p_processing_stage character varying, p_error_code character varying, p_payload jsonb) returns integer
    language plpgsql
as
$$
DECLARE

BEGIN

    INSERT INTO tb_resultados_logs (
        trace_id,
        run_id,
        cod_evento,
        percurso,
        num_peito,
        severity,
        processing_stage,
        error_code,
        payload
    )
    VALUES (
        p_trace_id::uuid,
        p_run_id::uuid,
        p_cod_evento,
        p_percurso,
        p_num_peito,
        p_severity,
        p_processing_stage,
        p_error_code,
        p_payload
        )
    ON CONFLICT (cod_evento, percurso, num_peito, severity, processing_stage)
    DO UPDATE SET
        payload            = EXCLUDED.payload,
        trace_id           = EXCLUDED.trace_id,
        run_id             = EXCLUDED.run_id,
        event_timestamp    = CURRENT_TIMESTAMP;

    return 0;
END;
$$;

alter function grava_logs_results(unknown, unknown, unknown, unknown, unknown, unknown, unknown, unknown, unknown) owner to runner_dba;

create function sanitize_pace(p_input text) returns time without time zone
    language plpgsql
as
$$
DECLARE
    v_clean   text;
    v_match   text[];
    v_h int;
    v_m int;
    v_s numeric;
    v_frac numeric := 0;
BEGIN

    IF p_input IS NULL OR btrim(p_input) = '' THEN
        RETURN NULL;
    END IF;

    v_clean := btrim(p_input);

    /*
    ============================================================
    1️⃣ FORMATO: HHhMM'SS[,MS]
       Ex:
       01h11'44,07
       01h18'09
    ============================================================
    */
    v_match := regexp_match(
        v_clean,
        '^(\d{1,2})h(\d{2})''(\d{2})(?:,(\d+))?$'
    );

    IF v_match IS NOT NULL THEN

        v_h := v_match[1]::int;
        v_m := v_match[2]::int;
        v_s := v_match[3]::int;

        -- Se houver milissegundo
        IF v_match[4] IS NOT NULL THEN
            v_frac := v_match[4]::numeric / power(10, length(v_match[4]));
        ELSE
            v_frac := 0;
        END IF;

        IF v_h BETWEEN 0 AND 23
           AND v_m BETWEEN 0 AND 59
           AND v_s BETWEEN 0 AND 59 THEN
            RETURN make_time(v_h, v_m, v_s + v_frac);
        ELSE
            RETURN NULL;
        END IF;
    END IF;

    -- Padronização vírgula → dois pontos
    v_clean := replace(v_clean, ',', ':');

    /*
    ============================================================
    2️⃣ FORMATO COM ":" (MM:SS ou HH:MI:SS)
    ============================================================
    */
    v_match := regexp_match(
        v_clean,
        '^\D*(\d{1,2}):(\d{2})(?::(\d{2}))?\D*$'
    );

    IF v_match IS NOT NULL THEN

        IF v_match[3] IS NULL THEN
            v_h := 0;
            v_m := v_match[1]::int;
            v_s := v_match[2]::int;
        ELSE
            v_h := v_match[1]::int;
            v_m := v_match[2]::int;
            v_s := v_match[3]::int;
        END IF;

        IF v_h BETWEEN 0 AND 23
           AND v_m BETWEEN 0 AND 59
           AND v_s BETWEEN 0 AND 59 THEN
            RETURN make_time(v_h, v_m, v_s);
        ELSE
            RETURN NULL;
        END IF;
    END IF;

    /*
    ============================================================
    3️⃣ DECIMAL EXCEL (fração de dia)
    ============================================================
    */
    v_match := regexp_match(
        v_clean,
        '^\D*(\d+\.\d+)\D*$'
    );

    IF v_match IS NOT NULL THEN
        RETURN (v_match[1]::numeric * interval '1 day')::time;
    END IF;

    RETURN NULL;

END;
$$;

alter function sanitize_pace(unknown) owner to runner_dba;

create function sanitize_percurso(p_input text) returns numeric
    immutable
    language plpgsql
as
$$
declare
    v_match text;
    v_value numeric;
begin

    -- Extrai primeiro número inteiro ou decimal
    v_match := substring(p_input from '(\d+(?:\.\d+)?)');

    -- Se não encontrou número
    if v_match is null then
        return null;
    end if;

    -- Converte para numeric (remove zeros à esquerda automaticamente)
    v_value := v_match::numeric;

    -- Ignora valores maiores que 999
    if v_value > 999 or v_value = 0 then
        return null;
    end if;

    return v_value;

end;
$$;

alter function sanitize_percurso(unknown) owner to runner_dba;

create procedure nova_gera_resultados(IN p_cod_evento character varying, IN p_tipo_processamento integer DEFAULT 0)
    language plpgsql
as
$$
DECLARE
-- tipo de processamento = 0 - Insere ou atualiza registros na tabela pimenta_tb_rs e gera resumo
-- tipo de processamento = 1 - Apaga todos os registros do evento e insere os registros novamente ( utilizado para reprocessamento completo do evento em caso de falhas ou inconsistências graves identificadas após o processamento inicial )
-- tipo de processamento = 2 - Somente verifica registros sem atualizar a base de dados e gera logs de erros encontrados durante a validação dos dados (utilizado para homologação do processo de geração de resultados)

var_classificacao_total         boolean;
var_classificacao_sexo          boolean;
var_classificacao_categoria     boolean;

var_gera_resultado_ini          timestamp;
var_id_evento                   integer;
var_nome                        varchar;
var_tempo_valido                boolean;
var_total_registros             integer;
var_total_registros_processados integer;
var_total_erros_encontrados     integer;
var_erros_ocorridos             boolean;
var_chave_processamento         varchar;
var_chave_verificacao           varchar;
var_pace                        varchar;
var_tempo_bruto                 varchar;
var_tempo_total                 varchar;
var_hora_largada                varchar;
var_modalidade                  varchar;
var_percurso                    varchar;
var_homologado                  boolean;
var_concluinte                  boolean;
var_msg_erro                    varchar;
var_retorno                     integer;
var_status_final                integer;
var_np                          integer;
var_pcd                         boolean;
rec_resultados                  record;


cur_resultados cursor for
select distinct
    num_peito,
    nome,
    categoria,
    id_evento,
    modalidade,
    pace,
    percurso,
    substring(upper(sexo),1,1) as sexo,
    trim(tempo_bruto) as tempo_bruto,
    trim(tempo_total) as tempo_total,
    classificacao_categoria,
    classificacao_sexo,
    classificacao_total,
    velocidade_media,
    upper(trim(REPLACE(equipe,' ',' '))) as equipe,
    data_nascimento,
    substring(trim(nacionalidade),1,8) as nacionalidade,
    chave_processamento,
    hora_largada,
    regexp_replace(np, '\D','','g') as np
from
    pimenta_tb_rs_temp where
    id_evento::integer = p_cod_evento::integer
    and modalidade not in('KIDS')
    and chave_processamento is null
order by
    tempo_total desc, tempo_bruto desc;


BEGIN
    var_classificacao_total         := false;
    var_classificacao_sexo          := false;
    var_classificacao_categoria     := false;

    var_gera_resultado_ini          := current_timestamp;
    var_id_evento                   := null;
    var_erros_ocorridos             := false;
    var_total_registros             := 0;
    var_total_registros_processados := 0;
    var_total_erros_encontrados     := 0;
    var_chave_processamento         := md5(concat(var_gera_resultado_ini::varchar,p_cod_evento))::varchar;

    -- verifica se evento foi cadastrado
    select
        id_evento
    into
        var_id_evento
    from
         tb_evento_corridas
    where
         id_evento = p_cod_evento::integer;

    if var_id_evento is null then
        var_retorno :=  grava_logs_results(
                        var_chave_processamento::uuid,  -- trace_id
                        gen_random_uuid(),              -- run_id
                        p_cod_evento,                   -- cod_evento
                        '0',                            -- percurso
                        '0',                            -- num_peito
                        'ERROR',                        -- severity
                        'INICIALIZACAO',                -- processing_stage
                        '0001',                         -- error_code
                        jsonb_build_object(
                            'evento', p_cod_evento,
                            'percurso', '0',
                            'num_peito', '0',
                            'codigo_erro', '0001',
                            'motivo', 'Código do evento não encontrado na lista de corridas cadastradas'
                            )                           -- payload
                        );
        return;
    end if;

    var_retorno :=  grava_logs_results(
                    var_chave_processamento::uuid,  -- trace_id
                    gen_random_uuid(),              -- run_id
                    p_cod_evento,                   -- cod_evento
                    '0',                            -- percurso
                    '0',                            -- num_peito
                    'INFO',                         -- severity
                    'INICIALIZACAO',                -- processing_stage
                    '0000',                         -- error_code
                    jsonb_build_object(
                        'evento', p_cod_evento,
                        'percurso', '0',
                        'num_peito', '0',
                        'codigo_erro', '0000',
                        'motivo', 'Iniciando processamento de resultados do evento'
                        )                           -- payload
                    );

    -- Remove registros da tabela de resultados para reprocessamento completo
    if p_tipo_processamento = 1 then
        delete from pimenta_tb_rs where id_evento = p_cod_evento::integer;
        delete from pimenta_tb_rs_versao where id_evento = p_cod_evento::integer;
    end if;

    -- Gera versões para resultados já capturados pelos usuários
     if p_tipo_processamento < 2 then
        insert into pimenta_tb_rs_versao
        (       id_resultado,
                id_resultado_versao,
                num_peito,
                nome,
                data_nascimento,
                id_evento,
                modalidade,
                pace,
                percurso,
                sexo,
                tempo_bruto,
                tempo_total,
                classificacao_categoria,
                classificacao_sexo,
                classificacao_total,
                velocidade_media,
                equipe,
                nome_categoria,
                id_usuario,
                id_categoria,
                homologado,
                concluinte,
                chave_processamento,
                chave_verificacao,
                nacionalidade,
                status_final,
                hora_largada,
                tempo_f1_categoria,
                tempo_f1_sexo,
                tempo_f1_total,
                posicao_ranking,
                classificacao_pais,
                pcd,
                nome_full_text,
                idade_range
                )
        ( select
                id_resultado,
                1,
                num_peito,
                nome,
                data_nascimento,
                id_evento,
                modalidade,
                pace,
                percurso,
                sexo,
                tempo_bruto,
                tempo_total,
                classificacao_categoria,
                classificacao_sexo,
                classificacao_total,
                velocidade_media,
                equipe,
                nome_categoria,
                id_usuario,
                id_categoria,
                homologado,
                concluinte,
                chave_processamento,
                chave_verificacao,
                nacionalidade,
                status_final,
                hora_largada,
                tempo_f1_categoria,
                tempo_f1_sexo,
                tempo_f1_total,
                posicao_ranking,
                classificacao_pais,
                pcd,
                nome_full_text,
                idade_range
          from pimenta_tb_rs
          where
          id_evento = p_cod_evento::integer and
          id_usuario  is not null
        )
        ON CONFLICT (id_evento,percurso,num_peito) DO UPDATE
        SET
                id_resultado_versao  = pimenta_tb_rs_versao.id_resultado_versao::integer + 1,
                id_resultado_versao_atual = null;
    end if;

    -- Quando do reprocessamento, elimina registros que não constam do novo processamento
    if p_tipo_processamento = 0 then
        delete from pimenta_tb_rs res
        where id_evento::integer = p_cod_evento::integer and
        not exists
        ( select id_evento
          from pimenta_tb_rs_temp tmp
          where
          tmp.id_evento = res.id_evento::varchar and
          tmp.num_peito = res.num_peito::varchar and
          sanitize_percurso(tmp.percurso)::numeric  = res.percurso::numeric  and
          tmp.chave_processamento is null
        );
    end if;


    open cur_resultados;
    loop
        fetch cur_resultados into rec_resultados;
        exit when not found;

        var_total_registros := var_total_registros + 1;
        var_homologado  := true;
        var_concluinte  := true;
        var_status_final:= 0;

        -- não processa percurso incorreto
        -- var_percurso := trim(LEADING '0' from regexp_replace(rec_resultados.percurso, '[^0-9.]','','g'));
        var_percurso := sanitize_percurso(rec_resultados.percurso);
        if var_percurso is null then
                    var_retorno :=  grava_logs_results(
                    var_chave_processamento::uuid,  -- trace_id
                    gen_random_uuid(),              -- run_id
                    p_cod_evento,                   -- cod_evento
                    rec_resultados.percurso,        -- percurso
                    rec_resultados.num_peito,       -- num_peito
                    'ERROR',                        -- severity
                    'VALIDACAO',                    -- processing_stage
                    '0002',                         -- error_code
                    jsonb_build_object(
                        'evento', p_cod_evento,
                        'percurso', rec_resultados.percurso,
                        'num_peito', rec_resultados.num_peito,
                        'codigo_erro', '0002',
                        'motivo', concat('Informação de percurso incorreta para o atleta número - ',rec_resultados.num_peito, ' - Percurso : ', rec_resultados.percurso)
                        )                           -- payload
                 );
            var_erros_ocorridos := true;
            var_total_erros_encontrados := var_total_erros_encontrados + 1;
            continue;
         end if;

        -- verifica sexo
        if rec_resultados.sexo <> 'M' and rec_resultados.sexo <> 'F' and rec_resultados.sexo <> 'X' and rec_resultados.sexo <> 'N' then
            var_retorno :=  grava_logs_results(
                    var_chave_processamento::uuid,  -- trace_id
                    gen_random_uuid(),              -- run_id
                    p_cod_evento,                   -- cod_evento
                    rec_resultados.percurso,        -- percurso
                    rec_resultados.num_peito,       -- num_peito
                    'ERROR',                         -- severity
                    'VALIDACAO',                    -- processing_stage
                    '0003',                         -- error_code
                    jsonb_build_object(
                        'evento', p_cod_evento,
                        'percurso', rec_resultados.percurso,
                        'num_peito', rec_resultados.num_peito,
                        'codigo_erro', '0003',
                        'motivo', concat('Gênero informado incorretamente para atleta número - ',rec_resultados.num_peito,' - ', rec_resultados.nome,' - Sexo : ', rec_resultados.sexo)
                        )                           -- payload
                 );
            var_erros_ocorridos := true;
            var_total_erros_encontrados := var_total_erros_encontrados + 1;
            continue;
        end if;

        -- verifica nome
        var_nome := upper(trim(REPLACE(rec_resultados.nome,' ',' ')));
        if length(var_nome) < 1 or var_nome is null then
            var_retorno :=  grava_logs_results(
                    var_chave_processamento::uuid,  -- trace_id
                    gen_random_uuid(),              -- run_id
                    p_cod_evento,                   -- cod_evento
                    rec_resultados.percurso,        -- percurso
                    rec_resultados.num_peito,       -- num_peito
                    'ERROR',                         -- severity
                    'VALIDACAO',                    -- processing_stage
                    '0004',                         -- error_code
                    jsonb_build_object(
                        'evento', p_cod_evento,
                        'percurso', rec_resultados.percurso,
                        'num_peito', rec_resultados.num_peito,
                        'codigo_erro', '0004',
                        'motivo', concat('Nome do atleta não foi informado para o atleta número - ',rec_resultados.num_peito)
                        )                           -- payload
                 );
            var_erros_ocorridos := true;
            var_total_erros_encontrados := var_total_erros_encontrados + 1;
            continue;
        end if;

        if var_nome ~* 'N[ÃA]O\s+ENCONTRADO' THEN
           var_retorno :=  grava_logs_results(
                    var_chave_processamento::uuid,  -- trace_id
                    gen_random_uuid(),              -- run_id
                    p_cod_evento,                   -- cod_evento
                    rec_resultados.percurso,        -- percurso
                    rec_resultados.num_peito,       -- num_peito
                    'ERROR',                         -- severity
                    'VALIDACAO',                    -- processing_stage
                    '0005',                         -- error_code
                    jsonb_build_object(
                        'evento', p_cod_evento,
                        'percurso', rec_resultados.percurso,
                        'num_peito', rec_resultados.num_peito,
                        'codigo_erro', '0005',
                        'motivo', concat('Registro ignorado devido à regra de exclusão para o atleta número - ',rec_resultados.num_peito, ' - Nome : ', var_nome)
                        )                           -- payload
                 );
            var_erros_ocorridos := true;
            var_total_erros_encontrados := var_total_erros_encontrados + 1;
            continue;
        end if;

        -- Padroniza nome de atleta desconhecido
        IF unaccent(var_nome) ~*  '(NAO\s+CADASTRADO|DESCONHECIDO|SEM\s+CADASTRO)'
            THEN
                var_nome := 'ATLETA DESCONHECIDO';
        END IF;

        -- 1 = Não Participou do evento
        -- 0 = Participou do evento
        if length(rec_resultados.np) > 0  and rec_resultados.np::integer = 1 then
            var_np := 1;
        else
            var_np := 0;
        end if;

        var_pace            := rec_resultados.pace;
        var_tempo_total     := rec_resultados.tempo_total;
        var_tempo_bruto     := rec_resultados.tempo_bruto;
        var_hora_largada    := trim(rec_resultados.hora_largada);

        -- verifica pace e considera nulo para não participantes ( np = 1 )

        if var_np = 1 then
            var_concluinte := false;
            var_pace := null;
            var_tempo_total := null;
        end if;

        -- status final do resultado
        -- 0 = concluinte
        -- 1 = retirada
        -- 2 = desclassificado
        -- 3 = não participou
        -- 4 = Sem tempo de conclusão

        -- testa desclassificados ( geralmente informado na coluna modalidade ou no tempo total )
        if upper(trim(rec_resultados.modalidade)) = 'DESCLASSIFICADO'   or
           upper(trim(rec_resultados.modalidade)) = 'DSQ'   or
           upper(replace(REGEXP_REPLACE(var_tempo_total,'[[:digit:]]','','g' ),':','')) = 'DESCLASSIFICADO' then
           var_status_final := 2;
           var_concluinte   := false;
           var_tempo_total  := null;
        end if;

        -- Se não existir tempo total, considerar como não concluinte e status final = 4
        if var_tempo_total is null then
           var_concluinte   := false;
           var_status_final := 4;
        end if;

        -- Verifica tempo total para atletas retirados das provas ou que não terminaram a prova

        if upper(replace(REGEXP_REPLACE(var_tempo_total,'[[:digit:]]','','g' ),':','')) = 'RETIRAD' then
           var_status_final := 1;
           var_concluinte   := false;
           var_tempo_total  := null;
        end if;

        if upper(replace(REGEXP_REPLACE(var_tempo_total,'[[:digit:]]','','g' ),':','')) = 'NÃO TERMINOU' then
           var_concluinte  := false;
           var_tempo_total := null;
        end if;

        if var_np = 1 then
           var_status_final := 3;
           var_tempo_bruto  := null;
           var_hora_largada := null;
        end if;

        var_modalidade := rec_resultados.modalidade;

        -- valida classificacao_total
        if rec_resultados.classificacao_total is not null then
            if var_concluinte = true and numero_valido(rec_resultados.classificacao_total) = false then
                var_retorno :=  grava_logs_results(
                            var_chave_processamento::uuid,  -- trace_id
                            gen_random_uuid(),              -- run_id
                            p_cod_evento,                   -- cod_evento
                            rec_resultados.percurso,        -- percurso
                            rec_resultados.num_peito,       -- num_peito
                            'ERROR',                        -- severity
                            'VALIDACAO',                    -- processing_stage
                            '0020',                         -- error_code
                            jsonb_build_object(
                                'evento', p_cod_evento,
                                'percurso', rec_resultados.percurso,
                                'num_peito', rec_resultados.num_peito,
                                'codigo_erro', '0020',
                                'motivo', concat('Classificacao total não numérica para atleta número - ',rec_resultados.num_peito, ' - ', var_nome, ' - ', rec_resultados.classificacao_total)
                                )                           -- payload
                     );
                    var_erros_ocorridos := true;
                    var_total_erros_encontrados := var_total_erros_encontrados + 1;
                    continue;
                var_erros_ocorridos := true;
                continue;
            end if;
        else
            var_classificacao_total := true;
        end if;

        -- valida classificacao_sexo
        if rec_resultados.classificacao_sexo is not null then
            if var_concluinte = true and numero_valido(rec_resultados.classificacao_sexo) = false then
                var_retorno :=  grava_logs_results(
                            var_chave_processamento::uuid,  -- trace_id
                            gen_random_uuid(),              -- run_id
                            p_cod_evento,                   -- cod_evento
                            rec_resultados.percurso,        -- percurso
                            rec_resultados.num_peito,       -- num_peito
                            'ERROR',                        -- severity
                            'VALIDACAO',                    -- processing_stage
                            '0021',                         -- error_code
                            jsonb_build_object(
                                'evento', p_cod_evento,
                                'percurso', rec_resultados.percurso,
                                'num_peito', rec_resultados.num_peito,
                                'codigo_erro', '0021',
                                'motivo', concat('Classificacao sexo não numérica para atleta número - ',rec_resultados.num_peito, ' - ', var_nome, ' - ', rec_resultados.classificacao_sexo)
                                )                           -- payload
                     );
                    var_erros_ocorridos := true;
                    var_total_erros_encontrados := var_total_erros_encontrados + 1;
                    continue;
                var_erros_ocorridos := true;
                continue;
            end if;
        else
            var_classificacao_sexo := true;
        end if;

        -- valida classificacao_categoria
        if rec_resultados.classificacao_categoria is not null then
            if var_concluinte = true and numero_valido(rec_resultados.classificacao_categoria) = false then
                var_retorno :=  grava_logs_results(
                            var_chave_processamento::uuid,  -- trace_id
                            gen_random_uuid(),              -- run_id
                            p_cod_evento,                   -- cod_evento
                            rec_resultados.percurso,        -- percurso
                            rec_resultados.num_peito,       -- num_peito
                            'ERROR',                        -- severity
                            'VALIDACAO',                    -- processing_stage
                            '0021',                         -- error_code
                            jsonb_build_object(
                                'evento', p_cod_evento,
                                'percurso', rec_resultados.percurso,
                                'num_peito', rec_resultados.num_peito,
                                'codigo_erro', '0021',
                                'motivo', concat('Classificacao categoria não numérica para atleta número - ',rec_resultados.num_peito, ' - ', var_nome, ' - ', rec_resultados.classificacao_categoria)
                                )                           -- payload
                     );
                    var_erros_ocorridos := true;
                    var_total_erros_encontrados := var_total_erros_encontrados + 1;
                    continue;
                var_erros_ocorridos := true;
                continue;
            end if;
        else
            var_classificacao_categoria := true;
        end if;


        -- Verifica se o tempo total é válido
        if var_np = 0 and var_tempo_total is not null then
                if sanitize_pace(var_tempo_total) is null then
                   var_retorno :=  grava_logs_results(
                            var_chave_processamento::uuid,  -- trace_id
                            gen_random_uuid(),              -- run_id
                            p_cod_evento,                   -- cod_evento
                            rec_resultados.percurso,        -- percurso
                            rec_resultados.num_peito,       -- num_peito
                            'ERROR',                        -- severity
                            'VALIDACAO',                    -- processing_stage
                            '0006',                         -- error_code
                            jsonb_build_object(
                                'evento', p_cod_evento,
                                'percurso', rec_resultados.percurso,
                                'num_peito', rec_resultados.num_peito,
                                'codigo_erro', '0006',
                                'motivo', concat('Tempo Total incorreto para atleta número - ',rec_resultados.num_peito, ' - ', var_nome, ' - Tempo Total : ', rec_resultados.tempo_total)
                                )                           -- payload
                     );
                    var_erros_ocorridos := true;
                    var_total_erros_encontrados := var_total_erros_encontrados + 1;
                    continue;
                -- calcula pace caso tempo total seja válido e pace seja nulo
                end if;
         end if;

        if rec_resultados.pace is not null and sanitize_pace(rec_resultados.pace) is null and var_np = 0 then
           var_retorno :=  grava_logs_results(
                    var_chave_processamento::uuid,  -- trace_id
                    gen_random_uuid(),              -- run_id
                    p_cod_evento,                   -- cod_evento
                    rec_resultados.percurso,        -- percurso
                    rec_resultados.num_peito,       -- num_peito
                    'ERROR',                         -- severity
                    'VALIDACAO',                    -- processing_stage
                    '0007',                         -- error_code
                    jsonb_build_object(
                        'evento', p_cod_evento,
                        'percurso', rec_resultados.percurso,
                        'num_peito', rec_resultados.num_peito,
                        'codigo_erro', '0007',
                        'motivo', concat('Pace incorreto para o atleta número - ',rec_resultados.num_peito, ' - ', var_nome, ' - ', rec_resultados.pace)
                        )                           -- payload
                 );
                var_erros_ocorridos := true;
                var_total_erros_encontrados := var_total_erros_encontrados + 1;
                continue;
        end if;

        var_pace            := sanitize_pace(var_pace);
        var_tempo_total     := sanitize_pace(var_tempo_total);
        var_hora_largada    := sanitize_pace(rec_resultados.hora_largada);

        -- calcula pace caso tempo total seja válido e pace seja nulo para participantes ( np = 0 )
        if  rec_resultados.pace is null and var_np = 0 then
            var_pace := (var_tempo_total::time / var_percurso::numeric)::time;
        end if;

        -- Valida tempo bruto

        if  var_tempo_bruto is not null and var_status_final = 0 then
            if sanitize_pace(var_tempo_bruto) is null then
                   var_retorno :=  grava_logs_results(
                            var_chave_processamento::uuid,  -- trace_id
                            gen_random_uuid(),              -- run_id
                            p_cod_evento,                   -- cod_evento
                            rec_resultados.percurso,        -- percurso
                            rec_resultados.num_peito,       -- num_peito
                            'ERROR',                        -- severity
                            'VALIDACAO',                    -- processing_stage
                            '0008',                         -- error_code
                            jsonb_build_object(
                                'evento', p_cod_evento,
                                'percurso', rec_resultados.percurso,
                                'num_peito', rec_resultados.num_peito,
                                'codigo_erro', '0008',
                                'motivo', concat('Tempo Bruto incorreto para atleta número - ',rec_resultados.num_peito, ' - ', var_nome, ' - ', rec_resultados.tempo_bruto)
                                )                           -- payload
                     );
                    var_erros_ocorridos := true;
                    var_total_erros_encontrados := var_total_erros_encontrados + 1;
                    continue;
            end if;
        end if;

        -- valida hora_largada

        if rec_resultados.hora_largada is not null and var_hora_largada is null and var_status_final = 0 then
                var_retorno :=  grava_logs_results(
                        var_chave_processamento::uuid,  -- trace_id
                        gen_random_uuid(),              -- run_id
                        p_cod_evento,                   -- cod_evento
                        rec_resultados.percurso,        -- percurso
                        rec_resultados.num_peito,       -- num_peito
                        'ERROR',                        -- severity
                        'VALIDACAO',                    -- processing_stage
                        '0009',                         -- error_code
                        jsonb_build_object(
                            'evento', p_cod_evento,
                            'percurso', rec_resultados.percurso,
                            'num_peito', rec_resultados.num_peito,
                            'codigo_erro', '0009',
                            'motivo', concat('Hora da largada incorreta para atleta número - ',rec_resultados.num_peito, ' - ', var_nome, ' - ', rec_resultados.hora_largada)
                            )                           -- payload
                    );
                var_erros_ocorridos := true;
                var_total_erros_encontrados := var_total_erros_encontrados + 1;
                continue;
        end if;

        -- Valida número de peito
        if rec_resultados.num_peito ~ '^[+-]?[0-9]+$' = false then
                var_retorno :=  grava_logs_results(
                        var_chave_processamento::uuid,  -- trace_id
                        gen_random_uuid(),              -- run_id
                        p_cod_evento,                   -- cod_evento
                        rec_resultados.percurso,        -- percurso
                        rec_resultados.num_peito,       -- num_peito
                        'ERROR',                        -- severity
                        'VALIDACAO',                    -- processing_stage
                        '0010',                         -- error_code
                        jsonb_build_object(
                            'evento', p_cod_evento,
                            'percurso', rec_resultados.percurso,
                            'num_peito', rec_resultados.num_peito,
                            'codigo_erro', '0010',
                            'motivo', concat('Número de peito inválido - ',rec_resultados.num_peito, ' - ', var_nome)
                            )                           -- payload
                    );
                var_erros_ocorridos := true;
                var_total_erros_encontrados := var_total_erros_encontrados + 1;
                continue;
        end if;

        if strpos(upper(concat(rec_resultados.nome,' ',rec_resultados.categoria,' ',rec_resultados.percurso,' ', rec_resultados.modalidade,' ', rec_resultados.equipe)),'PCD') > 0 then
           var_pcd := true;
        else
           var_pcd := false;
        end if;

        if p_tipo_processamento < 2 then
            insert into pimenta_tb_rs
            (   num_peito               ,
                nome                    ,
                id_evento               ,
                modalidade              ,
                pace                    ,
                percurso                ,
                sexo                    ,
                tempo_bruto             ,
                tempo_total             ,
                classificacao_categoria ,
                classificacao_sexo      ,
                classificacao_total     ,
                velocidade_media        ,
                equipe,
                nome_categoria,
                homologado,
                concluinte,
                data_nascimento,
                nacionalidade,
                chave_processamento,
                chave_verificacao,
                status_final,
                hora_largada,
                pcd,
                idade_range
            ) values (
                rec_resultados.num_peito::integer,
                var_nome,
                var_id_evento,
                var_modalidade,
                var_pace::time,
                var_percurso::numeric,
                rec_resultados.sexo,
                var_tempo_bruto::time,
                var_tempo_total::time,
                rec_resultados.classificacao_categoria::integer,
                rec_resultados.classificacao_sexo::integer,
                rec_resultados.classificacao_total::integer,
                rec_resultados.velocidade_media::numeric,
                rec_resultados.equipe,
                rec_resultados.categoria,
                var_homologado,
                var_concluinte,
                rec_resultados.data_nascimento::date,
                rec_resultados.nacionalidade,
                var_chave_processamento::uuid,
                md5(concat(rec_resultados.num_peito::varchar,var_nome,var_tempo_bruto::varchar,var_pace::varchar))::uuid,
                var_status_final,
                var_hora_largada::time,
                var_pcd,
                extrair_faixa_etaria(rec_resultados.categoria)::int4range
            )
            ON CONFLICT (id_evento,percurso,num_peito) DO UPDATE
            SET
                nome            = excluded.nome,
                modalidade      = excluded.modalidade,
                pace            = excluded.pace,
                percurso        = excluded.percurso,
                sexo            = excluded.sexo,
                tempo_bruto     = excluded.tempo_bruto,
                tempo_total     = excluded.tempo_total,
                classificacao_categoria = excluded.classificacao_categoria,
                classificacao_sexo      = excluded.classificacao_sexo,
                classificacao_total     = excluded.classificacao_total,
                velocidade_media        = excluded.velocidade_media,
                equipe                  = excluded.equipe,
                nome_categoria          = excluded.nome_categoria,
                data_nascimento         = excluded.data_nascimento,
                nacionalidade           = excluded.nacionalidade,
                homologado              = excluded.homologado,
                concluinte              = excluded.concluinte,
                chave_processamento     = excluded.chave_processamento,
                chave_verificacao       = excluded.chave_verificacao,
                status_final            = excluded.status_final,
                hora_largada            = excluded.hora_largada,
                pcd                     = excluded.pcd,
                idade_range             = excluded.idade_range;

            update
                pimenta_tb_rs_temp
            set
                chave_processamento = var_chave_processamento::uuid
            where
                id_evento   =   p_cod_evento             and
                percurso    =   rec_resultados.percurso  and
                num_peito   =   rec_resultados.num_peito and
                nome        =   rec_resultados.nome      and
                categoria   =   rec_resultados.categoria and
                chave_processamento is null;

        end if;

    end loop;

-- verifica se existem registros para processamento
    if var_total_registros = 0 then
       var_retorno :=  grava_logs_results(
                        var_chave_processamento::uuid,  -- trace_id
                        gen_random_uuid(),              -- run_id
                        p_cod_evento,                   -- cod_evento
                        '0',                            -- percurso
                        '0',                            -- num_peito
                        'WARN',                         -- severity
                        'INICIALIZACAO',                -- processing_stage
                        '0002',                         -- error_code
                        jsonb_build_object(
                            'evento', p_cod_evento,
                            'percurso', '0',
                            'num_peito', '0',
                            'codigo_erro', '0002',
                            'motivo', 'Não existem registros do evento para processamento'
                            )                           -- payload
                        );
        return;
    end if;

    close cur_resultados;

    if p_tipo_processamento = 0  then
        UPDATE pimenta_tb_rs_versao AS t1
            SET id_resultado_versao_atual = t2.id_resultado::integer
            FROM pimenta_tb_rs AS t2
        WHERE
            t1.id_evento = p_cod_evento::integer and
            t1.id_evento = t2.id_evento::integer and
            t1.num_peito = t2.num_peito::integer and
            t1.percurso  = t2.percurso::numeric  and
            t1.id_resultado_versao_atual is null;
    end if;

    if p_tipo_processamento < 2  then
       if var_classificacao_total = true or var_classificacao_sexo = true or var_classificacao_categoria = true then
            var_retorno :=  grava_logs_results(
                    var_chave_processamento::uuid,  -- trace_id
                    gen_random_uuid(),              -- run_id
                    p_cod_evento,                   -- cod_evento
                    '0',                            -- percurso
                    '0',                            -- num_peito
                    'WARN',                         -- severity
                    'FINALIZACAO',                  -- processing_stage
                    '0',                            -- error_code
                    jsonb_build_object(
                        'evento', p_cod_evento,
                        'percurso', '0',
                        'num_peito', '0',
                        'codigo_erro', '0',
                        'motivo', concat('Atualização de classificação foi executada total/Sexo/Categoria',var_classificacao_total,'/',var_classificacao_sexo,'/',var_classificacao_categoria)
                        )                           -- payload
                    );
            -- call atualiza_classific_f1_v2(var_id_evento,var_classificacao_total,var_classificacao_sexo,var_classificacao_categoria);
        end if;
    end if;

/*
    call atualiza_resultados_resumo_2025(var_id_evento);

    delete from pimenta_tb_rs_resumo where id_evento = var_id_evento;

    insert into pimenta_tb_rs_resumo
    ( id_evento, percurso, modalidade, concluintes,inscritos,pace_medio,pace_medio_top_10,pace_medio_top_100,concluintes_sub3 )
      select
        id_evento,
        percurso,
        modalidade,
        count(*) FILTER (WHERE homologado = true and concluinte=true and status_final=0) as concluintes,
        count(*) as inscritos,
        avg(pace) FILTER (WHERE homologado = true and concluinte=true and status_final=0 and pace is not null) as pace_medio,
        avg(pace) FILTER (WHERE homologado = true and concluinte=true and status_final=0 and pace is not null and ( classificacao_total <= 10 or classificacao_sexo <= 10) ) as pace_medio_top_10,
        avg(pace) FILTER (WHERE homologado = true and concluinte=true and status_final=0 and pace is not null and ( classificacao_total <= 100 or classificacao_sexo <= 100)) as pace_medio_top_100,
        count(*)  FILTER (WHERE homologado = true and concluinte=true and status_final=0 and tempo_total < '03:00:00'::time and percurso >= 42) as concluintes_sub3    from pimenta_tb_rs
    where id_evento  = var_id_evento
    group by id_evento,percurso,modalidade;

    UPDATE pimenta_tb_rs_resumo
    SET tipo_corrida=subquery.tipo_corrida
    FROM (SELECT id_evento,percurso_evento,tipo_corrida from tb_evento_corridas_percursos
    ) AS subquery
    WHERE
    pimenta_tb_rs_resumo.id_evento  = var_id_evento
    and pimenta_tb_rs_resumo.id_evento = subquery.id_evento
    and pimenta_tb_rs_resumo.percurso = subquery.percurso_evento;

    UPDATE pimenta_tb_rs_resumo
    SET tipo_corrida=subquery.tipo_corrida
    FROM (SELECT id_evento,percurso_evento,tipo_corrida from tb_evento_corridas_percursos
    ) AS subquery
    WHERE
    pimenta_tb_rs_resumo.tipo_corrida is null
    and pimenta_tb_rs_resumo.id_evento = subquery.id_evento
    and pimenta_tb_rs_resumo.percurso = subquery.percurso_evento;

    select
        md5(concat(sum(num_peito)::varchar,sum(tempo_bruto)::varchar))::varchar
    into
        var_chave_verificacao
    from
        pimenta_tb_rs where id_evento = var_id_evento;

    update
        pimenta_tb_rs_processa
    set
        data_processamento_final    = now(),
        erro_execucao               = var_erros_ocorridos,
        chave_verificacao           = var_chave_verificacao::uuid
    where
        cod_evento      = p_cod_evento  and
        id_evento       = var_id_evento and
        chave_processamento = var_chave_processamento::uuid;
*/

    var_retorno :=  grava_logs_results(
                    var_chave_processamento::uuid,  -- trace_id
                    gen_random_uuid(),              -- run_id
                    p_cod_evento,                   -- cod_evento
                    '0',                            -- percurso
                    '0',                            -- num_peito
                    'INFO',                         -- severity
                    'FINALIZACAO',                  -- processing_stage
                    LPAD(var_total_erros_encontrados::varchar,4,'0'),                         -- error_code
                    jsonb_build_object(
                        'evento', p_cod_evento,
                        'percurso', '0',
                        'num_peito', '0',
                        'codigo_erro', LPAD(var_total_erros_encontrados::varchar,4,'0'),
                        'motivo', concat('Final de processamento de resultados do evento', ' - Total de registros processados : ', var_total_registros, ' - Total de erros encontrados : ', var_total_erros_encontrados)
                        )                           -- payload
                    );

END
$$;

alter procedure nova_gera_resultados(unknown, unknown) owner to runner_dba;

create function extrair_dominio(p_url text) returns text
    immutable
    strict
    language sql
as
$$
WITH host AS (
    SELECT substring(p_url FROM '(?:https?://)?([^/?#:]+)') AS h
),
sem_tld AS (
    SELECT regexp_replace(h, '\.(com\.br|com|net\.br|net|org\.br|org)$', '', 'i') AS h
    FROM host
)
SELECT substring(h FROM '([^\.]+)$')
FROM sem_tld;
$$;

alter function extrair_dominio(unknown) owner to runner_dba;

create function normaliza_nome(p_nome text) returns text
    language sql
as
$$
    select case
        when p_nome is null then null
        else regexp_replace(
            unaccent(lower(trim(p_nome))),
            '\s+',
            ' ',
            'g'
        )
    end
$$;

alter function normaliza_nome(unknown) owner to runner_dba;

create function fu_processa_lote_backfill_nome()
    returns TABLE(id_lote bigint, id_inicial bigint, id_final bigint, linhas_atualizadas bigint, status character varying)
    language plpgsql
as
$$
declare
    v_lote    controle_backfill_nome%rowtype;
    v_linhas  bigint;
begin
    select c.*
      into v_lote
      from controle_backfill_nome c
     where c.status in ('pending', 'error')
     order by c.id_lote
     for update skip locked
     limit 1;

    if not found then
        return;
    end if;

    update controle_backfill_nome c
       set status     = 'running',
           dt_inicio  = now(),
           tentativas = c.tentativas + 1,
           pid_worker = pg_backend_pid(),
           erro       = null
     where c.id_lote = v_lote.id_lote;

    begin
        update tb_resultados r
           set nome_normalizado = normaliza_nome(r.nome)
         where r.id_resultado between v_lote.id_inicial and v_lote.id_final
           and r.nome_normalizado is null;

        get diagnostics v_linhas = row_count;

        update controle_backfill_nome c
           set status             = 'done',
               dt_fim             = now(),
               linhas_atualizadas = v_linhas
         where c.id_lote = v_lote.id_lote;

        return query
        select
            v_lote.id_lote,
            v_lote.id_inicial,
            v_lote.id_final,
            v_linhas,
            'done'::varchar;

    exception
        when others then
            update controle_backfill_nome c
               set status = 'error',
                   dt_fim = now(),
                   erro   = sqlerrm
             where c.id_lote = v_lote.id_lote;

            return query
            select
                v_lote.id_lote,
                v_lote.id_inicial,
                v_lote.id_final,
                0::bigint,
                'error'::varchar;
    end;
end;
$$;

alter function fu_processa_lote_backfill_nome() owner to runner_dba;

create function fn_result_normaliza_nome() returns trigger
    language plpgsql
as
$$
begin
    new.nome_normalizado :=
        regexp_replace(
            unaccent(lower(trim(new.nome))),
            '\s+',
            ' ',
            'g'
        );
    return new;
end;
$$;

alter function fn_result_normaliza_nome() owner to runner_dba;

create function fu_tb_log_ai_desvincularcorrida() returns trigger
    language plpgsql
as
$$
declare
    v_id_usuario_txt   text;
    v_id_resultado_txt text;
    v_id_usuario       bigint;
    v_id_resultado     bigint;
begin
    -- processa somente o item esperado
    if new.log_item <> 'desvincularcorrida' then
        return new;
    end if;

    -- valida presença
    if new.log_item_id is null or btrim(new.log_item_id) = '' then
        return new;
    end if;

    -- valida formato mínimo (precisa de vírgula)
    if position(',' in new.log_item_id) = 0 then
        return new;
    end if;

    -- extrai partes
    v_id_usuario_txt   := btrim(split_part(new.log_item_id, ',', 1));
    v_id_resultado_txt := btrim(split_part(new.log_item_id, ',', 2));

    -- valida conteúdo
    if v_id_usuario_txt = '' or v_id_resultado_txt = '' then
        return new;
    end if;

    -- tentativa segura de cast
    begin
        v_id_usuario := v_id_usuario_txt::bigint;
        v_id_resultado := v_id_resultado_txt::bigint;
    exception
        when others then
            -- ignora registro malformado
            return new;
    end;

    -- UPSERT
    insert into tb_resultados_desvincular
    (
        id_resultado,
        id_usuario
    )
    values
    (
        v_id_resultado,
        v_id_usuario
    )
    on conflict (id_resultado, id_usuario)
    do update
       set data_registro = current_timestamp;

    return new;
end;
$$;

alter function fu_tb_log_ai_desvincularcorrida() owner to runner_dba;

create operator % (procedure = similarity_op, leftarg = text, rightarg = text, commutator = %, join = matchingjoinsel, restrict = matchingsel);

alter operator %(text, text) owner to runner_dba;

create operator <-> (procedure = similarity_dist, leftarg = text, rightarg = text, commutator = <->);

alter operator <->(text, text) owner to runner_dba;

create operator family gist_trgm_ops using gist;

alter operator family gist_trgm_ops using gist add
    operator 1 %(text, text),
    operator 2 <->(text, text) for order by float_ops,
    operator 3 ~~(text,text),
    operator 4 ~~*(text,text),
    operator 5 ~(text,text),
    operator 6 ~*(text,text),
    operator 7 %>(text, text),
    operator 8 <->>(text, text) for order by float_ops,
    operator 9 %>>(text, text),
    operator 10 <->>>(text, text) for order by float_ops,
    operator 11 =(text,text),
    function 6(text, text) gtrgm_picksplit(unknown, unknown),
    function 7(text, text) gtrgm_same(unknown, unknown, unknown),
    function 8(text, text) gtrgm_distance(unknown, unknown, unknown, unknown, unknown),
    function 10(text, text) gtrgm_options(unknown),
    function 2(text, text) gtrgm_union(unknown, unknown),
    function 3(text, text) gtrgm_compress(unknown),
    function 4(text, text) gtrgm_decompress(unknown),
    function 5(text, text) gtrgm_penalty(unknown, unknown, unknown),
    function 1(text, text) gtrgm_consistent(unknown, unknown, unknown, unknown, unknown);

alter operator family gist_trgm_ops using gist owner to runner_dba;

create operator class gist_trgm_ops for type text using gist as storage gtrgm function 6(text, text) gtrgm_picksplit(unknown, unknown),
	function 1(text, text) gtrgm_consistent(unknown, unknown, unknown, unknown, unknown),
	function 7(text, text) gtrgm_same(unknown, unknown, unknown),
	function 5(text, text) gtrgm_penalty(unknown, unknown, unknown),
	function 2(text, text) gtrgm_union(unknown, unknown);

alter operator class gist_trgm_ops using gist owner to runner_dba;

create operator family gin_trgm_ops using gin;

alter operator family gin_trgm_ops using gin add
    operator 6 ~*(text,text),
    operator 7 %>(text, text),
    operator 11 =(text,text),
    operator 9 %>>(text, text),
    operator 1 %(text, text),
    operator 3 ~~(text,text),
    operator 4 ~~*(text,text),
    operator 5 ~(text,text),
    function 1(text, text) btint4cmp(integer,integer),
    function 4(text, text) gin_trgm_consistent(unknown, unknown, unknown, unknown, unknown, unknown, unknown, unknown),
    function 6(text, text) gin_trgm_triconsistent(unknown, unknown, unknown, unknown, unknown, unknown, unknown),
    function 2(text, text) gin_extract_value_trgm(unknown, unknown),
    function 3(text, text) gin_extract_query_trgm(unknown, unknown, unknown, unknown, unknown, unknown, unknown);

alter operator family gin_trgm_ops using gin owner to runner_dba;

create operator class gin_trgm_ops for type text using gin as storage integer function 3(text, text) gin_extract_query_trgm(unknown, unknown, unknown, unknown, unknown, unknown, unknown),
	function 2(text, text) gin_extract_value_trgm(unknown, unknown);

alter operator class gin_trgm_ops using gin owner to runner_dba;

-- Cyclic dependencies found

create operator %> (procedure = word_similarity_commutator_op, leftarg = text, rightarg = text, commutator = <%, join = matchingjoinsel, restrict = matchingsel);

alter operator %>(text, text) owner to runner_dba;

create operator <% (procedure = word_similarity_op, leftarg = text, rightarg = text, commutator = %>, join = matchingjoinsel, restrict = matchingsel);

alter operator <%(text, text) owner to runner_dba;

-- Cyclic dependencies found

create operator %>> (procedure = strict_word_similarity_commutator_op, leftarg = text, rightarg = text, commutator = <<%, join = matchingjoinsel, restrict = matchingsel);

alter operator %>>(text, text) owner to runner_dba;

create operator <<% (procedure = strict_word_similarity_op, leftarg = text, rightarg = text, commutator = %>>, join = matchingjoinsel, restrict = matchingsel);

alter operator <<%(text, text) owner to runner_dba;

-- Cyclic dependencies found

create operator <->> (procedure = word_similarity_dist_commutator_op, leftarg = text, rightarg = text, commutator = <<->);

alter operator <->>(text, text) owner to runner_dba;

create operator <<-> (procedure = word_similarity_dist_op, leftarg = text, rightarg = text, commutator = <->>);

alter operator <<->(text, text) owner to runner_dba;

-- Cyclic dependencies found

create operator <->>> (procedure = strict_word_similarity_dist_commutator_op, leftarg = text, rightarg = text, commutator = <<<->);

alter operator <->>>(text, text) owner to runner_dba;

create operator <<<-> (procedure = strict_word_similarity_dist_op, leftarg = text, rightarg = text, commutator = <->>>);

alter operator <<<->(text, text) owner to runner_dba;
