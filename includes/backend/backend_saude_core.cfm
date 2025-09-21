<cfquery name="qBaseTreinoes" cachedwithin="#CreateTimeSpan(0, 0, 10, 0)#">
    SELECT insc.id_evento, evt.nome_evento, COALESCE(uf.regiao, 'Exterior') as regiao,
        pag.tag as tag_usuario, usr.id as id_usuario,
        insc.data_pedido, insc.num_pedido, insc.data_checkin, COALESCE(insc.flag_sorteio::int, 0) as flag_sorteio, insc.observacoes,
        upper(COALESCE(pag.nome, usr.name)) as name, usr.email,
        insc.body,
        trim(limpar_assessoria(unaccent(upper(insc.body ->> 'assessoria')))) as assessoria,
        trim(upper(insc.body ->> 'pace')) as pace,
        trim(upper(insc.body ->> 'celular')) as celular,
        trim(upper(insc.body ->> 'documento')) as documento,
        trim(upper(insc.body ->> 'nascimento')) as nascimento,
        trim(upper(unaccent(COALESCE(pag.cidade, usr.cidade)))) as cidade,
        COALESCE(pag.uf, usr.estado) as estado,
        usr.id, usr.is_email_verified, usr.strava_code, usr.strava_id, usr.assessoria,
        usr.strava_premium, usr.strava_weight, usr.strava_full_follower_count, usr.strava_full_friend_count,
        usr.strava_full_shoes, usr.strava_full_clubs,
    (select count(*) from tb_resultados where id_usuario = usr.id) as resultados,
    (select trim(upper(tsparticipantes.body ->> 'modalidade')) from tb_ticketsports_participantes tsparticipantes where documento = insc.body ->>'documento' AND cod_evento = 70020 order by tsparticipantes.body ->> 'valor' desc limit 1) as mif,
    (select count(*) from tb_evento_corridas_checkin where id_usuario = usr.id) as checkin
    from tb_inscricoes insc
    left join tb_evento_corridas evt on evt.id_evento = insc.id_evento
    left join tb_usuarios usr on usr.id = insc.id_usuario
    left join tb_paginas pag ON usr.id = pag.id_usuario_cadastro
    left join tb_uf uf ON coalesce(pag.uf, usr.estado) = uf.uf
    WHERE insc.id_evento IN (22792)
    ORDER BY random()
</cfquery>

<cfquery name="qBaseInscritos" dbtype="query">
    <cfif URL.preset EQ "treinos">
        select id_usuario, tag_usuario, name, mif, regiao, cidade, estado, email,
        '' as celular, '' as assessoria,
        '' as nome_evento, '' as data_pedido, '' as num_pedido, '' as data_checkin, '' as observacoes,
        1 as is_email_verified, id, '' as checkin, '{}' as body, resultados, strava_code,
        count(DISTINCT data_checkin) as presencas, sum(flag_sorteio) as flag_sorteio, count(num_pedido) as total
        from qBaseTreinoes
        group by id_usuario, tag_usuario, name, mif, regiao, cidade, estado, assessoria, email, celular,
        nome_evento, data_pedido, num_pedido, data_checkin, observacoes,
        is_email_verified, id, checkin, body, resultados, strava_code
    <cfelse>
        select *
        from qBaseTreinoes
        <cfif URL.preset EQ "treino1">
            where id_evento = 29146
        <cfelseif URL.preset EQ "treino2">
            where id_evento = 29147
        <cfelseif URL.preset EQ "treino3">
            where id_evento = 29148
        <cfelseif URL.preset EQ "treino4">
            where id_evento = 29149
        <cfelseif URL.preset EQ "treino5">
            where id_evento = 29150
        </cfif>
    </cfif>
</cfquery>

<cfquery name="qCountTreino1" dbtype="query">
    select count(*) as total
    from qBaseTreinoes
    where id_evento = 29146
</cfquery>

<cfquery name="qCountTreino2" dbtype="query">
    select count(*) as total
    from qBaseTreinoes
    where id_evento = 29147
</cfquery>

<cfquery name="qCountTreino3" dbtype="query">
    select count(*) as total
    from qBaseTreinoes
    where id_evento = 29148
</cfquery>

<cfquery name="qCountTreino4" dbtype="query">
    select count(*) as total
    from qBaseTreinoes
    where id_evento = 29149
</cfquery>

<cfquery name="qCountTreino5" dbtype="query">
    select count(*) as total
    from qBaseTreinoes
    where id_evento = 29150
</cfquery>
