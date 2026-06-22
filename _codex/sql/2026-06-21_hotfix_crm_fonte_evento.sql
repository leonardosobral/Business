xset search_path to crm, public;

alter table crm.tb_crm_evento_versoes
    add column if not exists id_parceiro integer
        references public.tb_parceiros on update restrict on delete set null;

alter table crm.tb_crm_evento_versoes
    alter column cod_evento_externo drop not null;

create unique index if not exists tb_crm_evento_versoes_fonte_cod_uidx
    on crm.tb_crm_evento_versoes (fonte, cod_evento_externo);

create unique index if not exists tb_crm_evento_versoes_fonte_evento_sem_cod_uidx
    on crm.tb_crm_evento_versoes (fonte, id_evento, coalesce(id_parceiro, -1))
    where (cod_evento_externo is null or cod_evento_externo = '') and id_evento is not null;

alter table crm.tb_crm_importacoes
    add column if not exists id_parceiro integer
        references public.tb_parceiros on update restrict on delete set null;

alter table crm.tb_crm_importacoes
    add column if not exists cod_evento_externo varchar;

update crm.tb_crm_importacoes imp
set cod_evento_externo = imp.api_parametros ->> 'cod_evento'
where imp.cod_evento_externo is null
  and imp.api_parametros ? 'cod_evento';

alter table crm.tb_crm_pedidos
    add column if not exists id_parceiro integer
        references public.tb_parceiros on update restrict on delete set null;

alter table crm.tb_crm_pedidos
    alter column cod_evento_externo drop not null;

alter table crm.tb_crm_participacoes
    add column if not exists id_parceiro integer
        references public.tb_parceiros on update restrict on delete set null;

drop function if exists crm.crm_link_fonte_evento(varchar, integer, varchar, integer, bigint, varchar, jsonb);

create or replace function crm.crm_link_fonte_evento(
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

alter function crm.crm_link_fonte_evento(varchar, integer, varchar, integer, bigint, varchar, jsonb)
    owner to runner_dba;

comment on function crm.crm_link_fonte_evento(varchar, integer, varchar, integer, bigint, varchar, jsonb) is
    'Vincula qualquer fonte externa de inscricoes a um evento Road Runners canonico.';

grant execute on function crm.crm_link_fonte_evento(varchar, integer, varchar, integer, bigint, varchar, jsonb) to runner;

create or replace function crm.crm_link_ticketsports_evento(
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

alter function crm.crm_link_ticketsports_evento(integer, integer, bigint)
    owner to runner_dba;

comment on function crm.crm_link_ticketsports_evento(integer, integer, bigint) is
    'Compatibilidade: vincula TicketSports a evento RR usando crm_link_fonte_evento.';

grant execute on function crm.crm_link_ticketsports_evento(integer, integer, bigint) to runner;

drop function if exists crm.crm_criar_importacao_arquivo(integer, varchar, varchar, varchar, varchar, integer, varchar, integer, varchar, bigint, jsonb);

create or replace function crm.crm_criar_importacao_arquivo(
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
    returning
        tb_crm_importacoes.id_crm_importacao,
        tb_crm_importacoes.id_crm_evento_versao,
        tb_crm_importacoes.id_evento,
        tb_crm_importacoes.fonte,
        tb_crm_importacoes.cod_evento_externo,
        tb_crm_importacoes.status_processamento;
end;
$$;

alter function crm.crm_criar_importacao_arquivo(integer, varchar, varchar, varchar, varchar, integer, varchar, integer, varchar, bigint, jsonb)
    owner to runner_dba;

comment on function crm.crm_criar_importacao_arquivo(integer, varchar, varchar, varchar, varchar, integer, varchar, integer, varchar, bigint, jsonb) is
    'Cria cabecalho de importacao de arquivo ja vinculado a fonte e evento Road Runners.';

grant execute on function crm.crm_criar_importacao_arquivo(integer, varchar, varchar, varchar, varchar, integer, varchar, integer, varchar, bigint, jsonb) to runner;
