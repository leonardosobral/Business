set search_path to crm, public;

drop function if exists crm.crm_match_resultados(bigint, integer);

create or replace function crm.crm_match_resultados(
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

alter function crm.crm_match_resultados(bigint, integer)
    owner to runner_dba;

comment on function crm.crm_match_resultados(bigint, integer) is
    'Vincula participacoes CRM a resultados Road Runners e usa resultado reconhecido para preencher id_usuario.';

grant execute on function crm.crm_match_resultados(bigint, integer) to runner;

drop function if exists crm.crm_link_ticketsports_evento(integer, integer, bigint);

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
declare
    v_match record;
begin
    if p_cod_evento is null then
        raise exception 'p_cod_evento e obrigatorio';
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

    perform 1
    from crm.crm_sync_ticketsports(p_cod_evento)
    limit 1;

    if not exists (
        select 1
        from crm.tb_crm_evento_versoes vers
        where vers.fonte = 'ticketsports'
          and vers.cod_evento_externo = p_cod_evento::varchar
    ) then
        raise exception 'Codigo TicketSports % nao encontrado no CRM. Sincronize/importe os dados antes do vinculo.', p_cod_evento;
    end if;

    update crm.tb_crm_evento_versoes vers
    set id_evento = p_id_evento,
        payload = coalesce(vers.payload, '{}'::jsonb)
            || jsonb_build_object(
                'id_evento_origem', 'manual',
                'id_evento_usuario_cadastro', p_usuario_cadastro
            ),
        data_atualizacao = current_timestamp
    where vers.fonte = 'ticketsports'
      and vers.cod_evento_externo = p_cod_evento::varchar;

    update crm.tb_crm_importacoes imp
    set id_evento = p_id_evento,
        data_atualizacao = current_timestamp
    where imp.fonte = 'ticketsports'
      and imp.api_parametros ->> 'cod_evento' = p_cod_evento::varchar;

    update crm.tb_crm_participacoes part
    set id_evento = p_id_evento,
        data_atualizacao = current_timestamp
    where part.fonte = 'ticketsports'
      and part.cod_evento_externo = p_cod_evento::varchar;

    insert into crm.tb_crm_conta_evento_versoes (
        id_conta,
        id_crm_evento_versao,
        status,
        usuario_cadastro,
        origem
    )
    select
        cev.id_conta,
        vers.id_crm_evento_versao,
        cev.status,
        p_usuario_cadastro,
        'tb_conta_eventos'
    from crm.tb_crm_evento_versoes vers
    inner join public.tb_conta_eventos cev
        on cev.id_evento = p_id_evento
    where vers.fonte = 'ticketsports'
      and vers.cod_evento_externo = p_cod_evento::varchar
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
        vers.cod_evento_externo,
        evt.id_evento,
        evt.nome_evento,
        vers.id_crm_evento_versao,
        (
            select count(*)::integer
            from crm.tb_crm_participacoes part
            where part.fonte = 'ticketsports'
              and part.cod_evento_externo = p_cod_evento::varchar
        ) as total_participacoes,
        coalesce(v_match.participacoes_vinculadas, 0)::integer as total_resultados_vinculados,
        coalesce(v_match.pessoas_vinculadas, 0)::integer as total_usuarios_vinculados
    from crm.tb_crm_evento_versoes vers
    inner join public.tb_evento_corridas evt
        on evt.id_evento = p_id_evento
    where vers.fonte = 'ticketsports'
      and vers.cod_evento_externo = p_cod_evento::varchar;
end;
$$;

alter function crm.crm_link_ticketsports_evento(integer, integer, bigint)
    owner to runner_dba;

comment on function crm.crm_link_ticketsports_evento(integer, integer, bigint) is
    'Vincula um cod_evento TicketSports a um id_evento Road Runners e processa resultados reconhecidos.';

grant execute on function crm.crm_link_ticketsports_evento(integer, integer, bigint) to runner;
