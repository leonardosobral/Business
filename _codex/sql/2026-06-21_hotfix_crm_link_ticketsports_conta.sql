set search_path to crm, public;

drop function if exists crm.crm_link_ticketsports_conta(integer, bigint, bigint);

create or replace function crm.crm_link_ticketsports_conta(
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

alter function crm.crm_link_ticketsports_conta(integer, bigint, bigint)
    owner to runner_dba;

comment on function crm.crm_link_ticketsports_conta(integer, bigint, bigint) is
    'Sincroniza um cod_evento TicketSports e vincula sua versao CRM a uma conta Business.';

grant execute on function crm.crm_link_ticketsports_conta(integer, bigint, bigint) to runner;
