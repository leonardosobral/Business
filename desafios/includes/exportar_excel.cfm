<cfif isdefined("URL.tipo")>

    <cfquery name="qBaseExcel">
        WITH atv as (
        with atividades as
        (
            select
            athlete_id,
            count(distinct frequencia_fechamento) as frequencia_fechamento
            from
                (
                    select
                    athlete_id,
                    activity_date as frequencia_fechamento
                    from tb_strava_activities act
                    where activity_date between '2025-10-01'::date and now()::date
                ) as atv
            group by
            athlete_id
        )
        SELECT
        athlete_id,
        sum(distance) as distancia_percorrida,
        sum(total_elevation_gain) as altimetria,
        count(activity_id) as atividades,
        count(distinct activity_date::date) as dias_correndo,
        max(frequencia_fechamento) as frequencia_fechamento,
        max(dias_do_ano) as dias_do_ano
        FROM
        (
            SELECT
            at1.athlete_id,
            distance,
            total_elevation_gain,
            activity_id,
            activity_date::date,
            frequencia_fechamento,
            EXTRACT('doy' FROM current_date) as dias_do_ano
            FROM tb_strava_activities at1
            inner join atividades on atividades.athlete_id = at1.athlete_id
            WHERE activity_date >= '2025-01-01'
            -- AND distance >= 990
            -- AND type in ('Run','VirtualRun','TrailRun')
            AND extract(year from start_date) = extract(year from current_date)
        ) as qry1
         GROUP BY athlete_id
        )
        SELECT COALESCE(uf.nome_regiao, 'Exterior') as regiao,
        des.status,
        des.produto,
        des.data_inscricao,
        usr.id,
         coalesce(usr.ddi_usuario,'') as ddi_usuario,
         coalesce(usr.ddd_usuario,'') as ddd_usuario,
         coalesce(usr.telefone_usuario,'') as telefone_usuario,
        usr.email,
        usr.strava_id,
        usr.strava_code,
        usr.ddi_usuario,
        usr.ddd_usuario,
        COALESCE(upper(trim(unaccent(usr.cidade))), upper(trim(unaccent(pag.cidade)))) as cidade,
        COALESCE(usr.estado, pag.uf) as estado,
        upper(COALESCE(pag.nome, usr.name)) as nome,
        COALESCE(usr.genero, usr.strava_sex) as genero,
        usr.tag_usuario,
        usr.pais,
        (select status from tb_crm where id_usuario = usr.id order by id_interacao desc limit 1) as status_crm,
        CASE
            WHEN (select count(*) from tb_transacoes where id_usuario = usr.id and status_atual = 'order.paid') > 1 THEN 'duplicado'
            WHEN (select count(*) from tb_transacoes where id_usuario = usr.id and status_atual = 'order.paid') = 1 THEN 'pago'
            WHEN (select count(*) from tb_transacoes where id_usuario = usr.id) > 0 THEN 'pendente'
            ELSE null
        END as status_transacao,
        atv.distancia_percorrida,
        atv.dias_correndo,
        atv.atividades,
        atv.altimetria,
        atv.frequencia_fechamento as frequencia_fechamento,
        atv.frequencia_fechamento as nodesafio,
        CASE WHEN atv.frequencia_fechamento > 1 THEN 1 ELSE 0 END as ativo,
        atv.dias_do_ano,
        pag.tag,
        pag.verificado,
        coalesce('https://roadrunners.run/assets/paginas/' || pag.path_imagem, usr.strava_profile, usr.imagem_usuario, '/assets/user.png?') as imagem_usuario
        FROM desafios des
        INNER JOIN tb_usuarios usr ON (des.id_usuario = usr.id)
        LEFT JOIN tb_paginas pag ON pag.id_usuario_cadastro = usr.id and pag.tag_prefix = 'atleta'
        LEFT JOIN atv on atv.athlete_id = usr.strava_id
        LEFT JOIN tb_uf uf ON usr.estado = uf.uf
        where desafio = <cfqueryparam cfsqltype="cf_sql_varchar" value="#lcase(trim(URL.desafio))#"/>
    </cfquery>

    <cfif URL.tipo EQ "semstrava">

        <cfquery name="qExportExcel" dbtype="query">
            select distinct nome, email, ddi_usuario || ddd_usuario || telefone_usuario as telefone
            from qBaseExcel
            where strava_code is null
        </cfquery>

    <cfelseif URL.tipo EQ "sempedido">

        <cfquery name="qExportExcel" dbtype="query">
            select distinct nome, email, ddi_usuario || ddd_usuario || telefone_usuario as telefone
            from qBaseExcel
            where status_transacao is null and strava_code is not null
        </cfquery>

    <cfelseif URL.tipo EQ "pendente">

        <cfquery name="qExportExcel" dbtype="query">
            select distinct nome, email, ddi_usuario || ddd_usuario || telefone_usuario as telefone
            from qBaseExcel
            where status_transacao = 'pendente'
        </cfquery>

    <cfelse>

        <cfquery name="qExportExcel" dbtype="query">
            select distinct nome, email, ddi_usuario || ddd_usuario || telefone_usuario as telefone
            from qBaseExcel
            where status_transacao <> 'duplicado' AND status_transacao <> 'pago'
        </cfquery>

    </cfif>

    <cfset relatorioName = "exportacao_" & URL.tipo & "_" & LSDateFormat(Now(), "yyyy-mm-dd") & "_" & LSTimeFormat(Now(), "HH-MM") & "_u_ip" & CGI.REMOTE_ADDR/>

    <cfspreadsheet action="write"
        filename="/tmp/#relatorioName#.xlsx"
        overwrite="true"
        query="qExportExcel"
        sheetname="exportacao">

    <cfheader name="Content-Disposition" value="inline; filename=#relatorioName#.xlsx">
    <cfset a = spreadsheetRead("/tmp/#relatorioName#.xlsx", "exportacao")>

    <cfset bin = spreadsheetReadBinary(a)>
    <cfcontent type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" variable="#bin#" reset="true">

</cfif>
