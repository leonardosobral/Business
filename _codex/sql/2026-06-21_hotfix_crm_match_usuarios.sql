set search_path to crm, public;

drop function if exists crm.crm_match_usuarios(bigint);

create or replace function crm.crm_match_usuarios(p_id_conta bigint default null)
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

alter function crm.crm_match_usuarios(bigint)
    owner to runner_dba;

comment on function crm.crm_match_usuarios(bigint) is
    'Vincula pessoas CRM a usuarios Road Runners com matching conservador por email, nome e data de nascimento.';

grant execute on function crm.crm_match_usuarios(bigint) to runner;
