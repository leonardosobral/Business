<!--- QUERIES ESTRUTURAIS --->

<cfquery name="qBi" dbtype="query">
    SELECT * FROM qPermissoes
    WHERE tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.tag#"/>
</cfquery>

<cfquery name="qAgrega">
    SELECT * FROM tb_agrega_eventos
    WHERE tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qBi.tag#"/>
</cfquery>

<cfquery name="qAgregadores">
    SELECT * FROM tb_agregadores
    WHERE agregador_tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qBi.tag#"/>
</cfquery>

<cfquery name="qTema">
    SELECT * FROM tb_temas
    WHERE id_tema = <cfqueryparam cfsqltype="cf_sql_integer" value="#qBi.id_tema#"/>
</cfquery>


<!--- QUERY BASE DE EVENTOS --->

<cfif URL.tag EQ "brasil" OR qBi.tipo EQ "empresa">

    <cfquery name="qBase" cachedwithin="#CreateTimeSpan(0, 0, 10, 0)#">
        SELECT
        extract(year from evt.data_final) as ano,
        evt.id_evento, evt.estado, evt.cidade, evt.nome_evento, evt.tag, evt.tipo_corrida,
        evt.data_final, evt.url_resultado, evt.url_inscricao, evt.url_hotsite, evt.obs_resultado,
        '' as nome_evento_agregado, '' as tipo_agregacao, '' as id_agrega_evento,
        replace(replace(replace(substring(coalesce(evt.url_inscricao,evt.url_hotsite) from '(?:.*://)?(?:www\.)?([^/?]*)'), '.com.br', ''), '.com', ''), 'site.', '') as url_inscricao_domain,
        CASE
            WHEN ((select COALESCE(sum(res.concluintes),0)
                    FROM tb_resultados_resumo res
                    WHERE res.id_evento = evt.id_evento) > 0) THEN 1
            ELSE 0
        END as tem_resultado,
        CASE
            WHEN (evt.url_resultado is null OR evt.url_resultado = '') THEN 0
            ELSE 1
        END as tem_url_resultado,
        CASE
            WHEN ((evt.url_inscricao ilike <cfqueryparam cfsqltype="cf_sql_varchar" value="%#qBi.tag#%"/> OR url_hotsite ilike <cfqueryparam cfsqltype="cf_sql_varchar" value="%#qBi.tag#%"/>)
                    AND (select COALESCE(sum(res.concluintes),0)
                        FROM tb_resultados_resumo res
                        WHERE res.id_evento = evt.id_evento) > 0) THEN 1
            ELSE 0
        END as tt_resultado,
        CASE
            WHEN (evt.url_inscricao ilike <cfqueryparam cfsqltype="cf_sql_varchar" value="%#qBi.tag#%"/> OR evt.url_hotsite ilike <cfqueryparam cfsqltype="cf_sql_varchar" value="%#qBi.tag#%"/>) THEN 1
            ELSE 0
        END as tt,
        uf.regiao, uf.nome_regiao, uf.nome_uf,
        COALESCE((select sum(res.concluintes)
            FROM tb_resultados_resumo res
            WHERE res.id_evento = evt.id_evento),0) as concluintes,
        COALESCE((select sum(res.concluintes)
            FROM tb_resultados_resumo res
            WHERE res.id_evento = evt.id_evento and (evt.url_inscricao ilike <cfqueryparam cfsqltype="cf_sql_varchar" value="%#qBi.tag#%"/> OR url_hotsite ilike <cfqueryparam cfsqltype="cf_sql_varchar" value="%#qBi.tag#%"/>)),0) as tt_concluintes
        FROM tb_evento_corridas evt
        LEFT join tb_uf uf ON evt.estado = uf.uf
        WHERE ativo = true
        AND evt.pais = 'BR'
        AND evt.data_inicial >= '2023-01-01'
    </cfquery>

<cfelseif qBi.tipo EQ "bi">

    <cfquery name="qBase" cachedwithin="#CreateTimeSpan(0, 0, 10, 0)#">
        SELECT
        extract(year from evt.data_final) as ano,
        evt.id_evento, evt.estado, evt.cidade, evt.nome_evento, evt.tag, evt.tipo_corrida,
        evt.data_final, evt.url_resultado, evt.url_inscricao, evt.url_hotsite, evt.obs_resultado,
        agr.nome_evento_agregado, agr.tipo_agregacao, evt.id_agrega_evento,
        substring(evt.url_inscricao from '(?:.*://)?(?:www\.)?([^/?]*)') as url_inscricao_domain,
        CASE
            WHEN ((select COALESCE(sum(res.concluintes),0)
                    FROM tb_resultados_resumo res
                    WHERE res.id_evento = evt.id_evento) > 0) THEN 1
            ELSE 0
        END as tem_resultado,
        CASE
            WHEN (evt.url_resultado is null OR evt.url_resultado = '') THEN 0
            ELSE 1
        END as tem_url_resultado,
        0 as tt,
        0 as tt_resultado,
        0 as tt_concluintes,
        uf.regiao, uf.nome_regiao, uf.nome_uf,
        (select sum(res.concluintes)
            FROM tb_resultados_resumo res
            WHERE res.id_evento = evt.id_evento
            <cfif qBi.tag EQ "supra" OR qBi.tag EQ "contra-relogio">
                AND res.percurso IN (42)
            <cfelseif qBi.tag EQ "mega-finisher">
                AND res.percurso IN (21,42)
            </cfif>
        ) as concluintes
        FROM tb_evento_corridas evt
        left join tb_uf uf ON evt.estado = uf.uf
        left join tb_agrega_eventos agr ON evt.id_agrega_evento = agr.id_agrega_evento
        WHERE ativo = true
        <cfif len(trim(qBi.tag))>
            <cfif qBi.tag EQ 'correria-campinas' OR qBi.tag EQ 'fpa'>
                AND evt.cidade IN (SELECT cidade FROM tb_agregadores_cidades WHERE agregador_tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qBi.tag#"/>)
                AND evt.estado = 'SP'
            <cfelse>
                AND evt.id_evento IN (select id_evento FROM tb_agregadores_eventos WHERE agregador_tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qBi.tag#"/>)
            </cfif>
        </cfif>
    </cfquery>

<cfelse>

    <cfquery name="qBase" cachedwithin="#CreateTimeSpan(0, 0, 10, 0)#">
        SELECT
        extract(year from evt.data_final) as ano,
        evt.id_evento, evt.estado, evt.cidade, evt.nome_evento, evt.tag, evt.tipo_corrida,
        evt.data_final, evt.url_resultado, evt.url_inscricao, evt.url_hotsite, evt.obs_resultado,
        agr.nome_evento_agregado, agr.tipo_agregacao, evt.id_agrega_evento,
        substring(evt.url_inscricao from '(?:.*://)?(?:www\.)?([^/?]*)') as url_inscricao_domain,
        CASE
            WHEN ((select COALESCE(sum(res.concluintes),0)
                    FROM tb_resultados_resumo res
                    WHERE res.id_evento = evt.id_evento) > 0) THEN 1
            ELSE 0
        END as tem_resultado,
        CASE
            WHEN (evt.url_resultado is null OR evt.url_resultado = '') THEN 0
            ELSE 1
        END as tem_url_resultado,
        0 as tt,
        0 as tt_resultado,
        0 as tt_concluintes,
        uf.regiao, uf.nome_regiao, uf.nome_uf,
        (select COALESCE(sum(res.concluintes),0)
            FROM tb_resultados_resumo res
            WHERE res.id_evento = evt.id_evento) as concluintes
        FROM tb_evento_corridas evt
        inner join tb_uf uf ON evt.estado = uf.uf
        left join tb_agrega_eventos agr ON evt.id_agrega_evento = agr.id_agrega_evento
        WHERE ativo = true AND tipo_corrida <> 'treino'
        AND evt.id_agrega_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qAgrega.id_agrega_evento#"/>
    </cfquery>

</cfif>


<cfquery name="qPeriodo" dbtype="query">
    select *
    from qBase
    <!---WHERE concluintes > 0--->
    WHERE estado is not null AND estado <> ''
    <cfif len(trim(URL.preset)) AND (URL.preset EQ "2025" OR URL.preset CONTAINS "treino" OR URL.preset CONTAINS "saude")>
        AND data_final between '2025-01-01' and '2025-12-31'
    </cfif>
    <cfif len(trim(URL.preset)) AND URL.preset EQ "2024">
        AND data_final between '2024-01-01' and '2024-12-31'
    </cfif>
    <cfif len(trim(URL.preset)) AND URL.preset EQ "2023">
        AND data_final between '2023-01-01' and '2023-12-31'
    </cfif>
</cfquery>

<cfquery name="qCountPeriodo" dbtype="query">
    select sum(concluintes) as concluintes
    from qPeriodo
</cfquery>



<cfquery name="qCountAtual" dbtype="query">
    select count(*) as total, sum(concluintes) as concluintes
    from qBase
    where data_final between '2025-01-01' and '2025-12-31' and concluintes > 0
</cfquery>

<cfquery name="qCountAnterior" dbtype="query">
    select count(*) as total, sum(concluintes) as concluintes
    from qBase
    where data_final between '2024-01-01' and '2024-12-31' and concluintes > 0
</cfquery>

<cfquery name="qCountTotal" dbtype="query">
    select count(*) as total, sum(concluintes) as concluintes
    from qBase
    where concluintes > 0
</cfquery>

<cfquery name="qCountEvAtual" dbtype="query">
    select count(*) as total
    from qBase
    where data_final between '2025-01-01' and '2025-12-31'
</cfquery>

<cfquery name="qCountEvAnterior" dbtype="query">
    select count(*) as total
    from qBase
    where data_final between '2024-01-01' and '2024-12-31'
</cfquery>

<cfquery name="qCountEvTotal" dbtype="query">
    select count(*) as total
    from qBase
</cfquery>


<cfquery name="qStatsRegiao" dbtype="query">
    select regiao,
    count(id_evento) as eventos,
    sum(concluintes) as concluintes,
    sum(tt_concluintes) as tt_concluintes,
    sum(tem_url_resultado) as tem_url_resultado,
    sum(tem_resultado) as tem_resultado,
    sum(tt) as tt,
    sum(tt_resultado) as tt_resultado,
    (sum(concluintes)/sum(tem_resultado)) as media,
    (sum(tt_concluintes)/sum(tt_resultado)) as tt_media
    from qPeriodo
    group by regiao
    order by concluintes desc
</cfquery>

<cfset qTotalRegiao = {concluintes:0, eventos:0, media:0, minimo:(len(trim(qStatsRegiao.concluintes)) AND len(trim(qStatsRegiao.tem_resultado)) AND qStatsRegiao.tem_resultado GT 0 ? (qStatsRegiao.concluintes/qStatsRegiao.tem_resultado) : 0), maximo:0}/>
<cfloop query="qStatsRegiao">
    <cfif qStatsRegiao.concluintes GT 0>
        <cfset qTotalRegiao.concluintes = qTotalRegiao.concluintes + qStatsRegiao.concluintes/>
        <cfset qTotalRegiao.eventos = qTotalRegiao.eventos + qStatsRegiao.eventos/>
        <cfset qTotalRegiao.minimo = min(qTotalRegiao.minimo, (qStatsRegiao.concluintes/qStatsRegiao.tem_resultado))/>
        <cfset qTotalRegiao.maximo = max(qTotalRegiao.maximo, (qStatsRegiao.concluintes/qStatsRegiao.tem_resultado))/>
    </cfif>
</cfloop>
<cfset qTotalRegiao.media = (len(trim(qStatsRegiao.concluintes)) AND len(trim(qStatsRegiao.tem_resultado)) AND qStatsRegiao.tem_resultado GT 0 ? (qStatsRegiao.concluintes/qStatsRegiao.tem_resultado) : 0)/>

<cfset qTotalRegiaoEmpresa = {concluintes:0, eventos:0, media:0, minimo:(len(trim(qStatsRegiao.concluintes)) AND len(trim(qStatsRegiao.tem_resultado)) AND qStatsRegiao.tem_resultado GT 0 ? (qStatsRegiao.concluintes/qStatsRegiao.tem_resultado) : 0), maximo:0}/>
<cfloop query="qStatsRegiao">
    <cfif qStatsRegiao.tt_concluintes GT 0>
        <cfset qTotalRegiaoEmpresa.concluintes = qTotalRegiaoEmpresa.concluintes + qStatsRegiao.tt_concluintes/>
        <cfset qTotalRegiaoEmpresa.eventos = qTotalRegiaoEmpresa.eventos + qStatsRegiao.tt/>
        <cfset qTotalRegiaoEmpresa.minimo = min(qTotalRegiaoEmpresa.minimo, (qStatsRegiao.tt_concluintes/qStatsRegiao.tt_resultado))/>
        <cfset qTotalRegiaoEmpresa.maximo = max(qTotalRegiaoEmpresa.maximo, (qStatsRegiao.tt_concluintes/qStatsRegiao.tt_resultado))/>
    </cfif>
</cfloop>
<cfset qTotalRegiaoEmpresa.media = (len(trim(qStatsRegiao.tt_concluintes)) AND len(trim(qStatsRegiao.tt_resultado)) AND qStatsRegiao.tt_resultado GT 0 ? (qStatsRegiao.tt_concluintes/qStatsRegiao.tt_resultado) : 0)/>

<cfquery name="qStatsEstado" dbtype="query">
    select estado, nome_uf,
    sum(tt) as tt,
    sum(tt_resultado) as tt_resultado,
    count(id_evento) as eventos,
    sum(concluintes) as concluintes,
    sum(tt_concluintes) as tt_concluintes,
    sum(tem_url_resultado) as tem_url_resultado,
    sum(tem_resultado) as tem_resultado,
    (sum(concluintes)/sum(tem_resultado)) as media,
    (sum(tt_concluintes)/sum(tt_resultado)) as tt_media
    from qPeriodo
    where estado is not null
    <cfif len(trim(URL.regiao))>
        and regiao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.regiao#"/>
    </cfif>
    group by estado, nome_uf
    order by concluintes desc
</cfquery>

<cfset qTotalEstado = {concluintes:0, eventos:0, media:0, minimo:(len(trim(qStatsEstado.concluintes)) AND len(trim(qStatsEstado.tem_resultado)) AND qStatsEstado.tem_resultado GT 0 ? (qStatsEstado.concluintes/qStatsEstado.tem_resultado) : 0), maximo:0}/>
<cfloop query="qStatsEstado">
    <cfif qStatsEstado.concluintes GT 0>
        <cfset qTotalEstado.concluintes = qTotalEstado.concluintes + qStatsEstado.concluintes/>
        <cfset qTotalEstado.eventos = qTotalEstado.eventos + qStatsEstado.eventos/>
        <cfset qTotalEstado.minimo = min(qTotalEstado.minimo, (qStatsEstado.concluintes/qStatsEstado.tem_resultado))/>
        <cfset qTotalEstado.maximo = max(qTotalEstado.maximo, (qStatsEstado.concluintes/qStatsEstado.tem_resultado))/>
    </cfif>
</cfloop>
<cfset qTotalEstado.media = (len(trim(qStatsEstado.concluintes)) AND len(trim(qStatsEstado.tem_resultado)) AND qStatsEstado.tem_resultado GT 0 ? (qStatsEstado.concluintes/qStatsEstado.tem_resultado) : 0)/>

<cfset qTotalEstadoEmpresa = {concluintes:0, eventos:0, media:0, minimo:(len(trim(qStatsEstado.concluintes)) AND len(trim(qStatsEstado.tem_resultado)) AND qStatsEstado.tem_resultado GT 0 ? (qStatsEstado.concluintes/qStatsEstado.tem_resultado) : 0), maximo:0}/>
<cfloop query="qStatsEstado">
    <cfif qStatsEstado.tt_concluintes GT 0>
        <cfset qTotalEstadoEmpresa.concluintes = qTotalEstadoEmpresa.concluintes + qStatsEstado.tt_concluintes/>
        <cfset qTotalEstadoEmpresa.eventos = qTotalEstadoEmpresa.eventos + qStatsEstado.tt/>
        <cfset qTotalEstadoEmpresa.minimo = min(qTotalEstadoEmpresa.minimo, (qStatsEstado.tt_concluintes/qStatsEstado.tt_resultado))/>
        <cfset qTotalEstadoEmpresa.maximo = max(qTotalEstadoEmpresa.maximo, (qStatsEstado.tt_concluintes/qStatsEstado.tt_resultado))/>
    </cfif>
</cfloop>
<cfset qTotalEstadoEmpresa.media = (len(trim(qStatsEstado.tt_concluintes)) AND len(trim(qStatsEstado.tt_resultado)) AND qStatsEstado.tt_resultado GT 0 ? (qStatsEstado.tt_concluintes/qStatsEstado.tt_resultado) : 0)/>

<cfquery name="qStatsCidade" dbtype="query">
    select estado, cidade,
    sum(tt) as tt,
    sum(tt_resultado) as tt_resultado,
    count(id_evento) as eventos,
    sum(concluintes) as concluintes,
    sum(tt_concluintes) as tt_concluintes,
    sum(tem_url_resultado) as tem_url_resultado,
    sum(tem_resultado) as tem_resultado,
    (sum(concluintes)/sum(tem_resultado)) as media,
    (sum(tt_concluintes)/sum(tt_resultado)) as tt_media
    from qPeriodo
    where cidade is not null
    <cfif len(trim(URL.regiao))>
        and regiao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.regiao#"/>
    </cfif>
    <cfif len(trim(URL.estado))>
        and estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.estado#"/>
    </cfif>
    group by estado, cidade
    order by concluintes desc
</cfquery>

<cfset qTotalCidade = {concluintes:0, eventos:0, media:0, minimo:(len(trim(qStatsCidade.concluintes)) AND len(trim(qStatsCidade.tem_resultado)) AND qStatsCidade.tem_resultado GT 0 ? (qStatsCidade.concluintes/qStatsCidade.tem_resultado) : 0), maximo:0}/>
<cfloop query="qStatsCidade">
    <cfif qStatsCidade.concluintes GT 0>
        <cfset qTotalCidade.concluintes = qTotalCidade.concluintes + qStatsCidade.concluintes/>
        <cfset qTotalCidade.eventos = qTotalCidade.eventos + qStatsCidade.eventos/>
        <cfset qTotalCidade.minimo = min(qTotalCidade.minimo, (qStatsCidade.concluintes/qStatsCidade.tem_resultado))/>
        <cfset qTotalCidade.maximo = max(qTotalCidade.maximo, (qStatsCidade.concluintes/qStatsCidade.tem_resultado))/>
    </cfif>
</cfloop>
<cfset qTotalCidade.media = (len(trim(qStatsCidade.concluintes)) AND len(trim(qStatsCidade.tem_resultado)) AND qStatsCidade.tem_resultado GT 0 ? (qStatsCidade.concluintes/qStatsCidade.tem_resultado) : 0)/>

<cfset qTotalCidadeEmpresa = {concluintes:0, eventos:0, media:0, minimo:(len(trim(qStatsCidade.concluintes)) AND len(trim(qStatsCidade.tem_resultado)) AND qStatsCidade.tem_resultado GT 0 ? (qStatsCidade.concluintes/qStatsCidade.tem_resultado) : 0), maximo:0}/>
<cfloop query="qStatsCidade">
    <cfif qStatsCidade.tt_concluintes GT 0>
        <cfset qTotalCidadeEmpresa.concluintes = qTotalCidadeEmpresa.concluintes + qStatsCidade.tt_concluintes/>
        <cfset qTotalCidadeEmpresa.eventos = qTotalCidadeEmpresa.eventos + qStatsCidade.tt/>
        <cfset qTotalCidadeEmpresa.minimo = min(qTotalCidadeEmpresa.minimo, (qStatsCidade.tt_concluintes/qStatsCidade.tt_resultado))/>
        <cfset qTotalCidadeEmpresa.maximo = max(qTotalCidadeEmpresa.maximo, (qStatsCidade.tt_concluintes/qStatsCidade.tt_resultado))/>
    </cfif>
</cfloop>
<cfset qTotalCidadeEmpresa.media = (len(trim(qStatsCidade.tt_concluintes)) AND len(trim(qStatsCidade.tt_resultado)) AND qStatsCidade.tt_resultado GT 0 ? (qStatsCidade.tt_concluintes/qStatsCidade.tt_resultado) : 0)/>


<!--- TICKETEIRAS --->

<cfquery name="qShareInscricao" dbtype="query">
    select count(*) as eventos, 
    sum(concluintes) as concluintes, 
    sum(tem_resultado) as tem_resultado,
    (sum(concluintes)/sum(tem_resultado)) as media,
    url_inscricao_domain
    from qPeriodo
    where nome_evento is not null
    <cfif len(trim(URL.regiao))>
        and regiao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.regiao#"/>
    </cfif>
    <cfif len(trim(URL.estado))>
        and estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.estado#"/>
    </cfif>
    <cfif len(trim(URL.cidade))>
        and cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.cidade#"/>
    </cfif>
    AND  url_inscricao_domain <> '' AND url_inscricao_domain is not null
    group by url_inscricao_domain
    order by eventos desc;
</cfquery>


<!--- EVENTOS --->

<cfquery name="qStatsEvento" dbtype="query">
    select id_evento, estado, cidade, nome_evento, url_inscricao, url_hotsite, url_inscricao_domain, tt, tt_resultado, tt_concluintes, tag, data_final, sum(concluintes) concluintes
    from qPeriodo
    where nome_evento is not null
    <cfif len(trim(URL.regiao))>
        and regiao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.regiao#"/>
    </cfif>
    <cfif len(trim(URL.estado))>
        and estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.estado#"/>
    </cfif>
    <cfif len(trim(URL.cidade))>
        and cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.cidade#"/>
    </cfif>
    <cfif len(trim(URL.inscricao))>
        and url_inscricao_domain = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.inscricao#"/>
    </cfif>
    group by id_evento, estado, cidade, nome_evento, url_inscricao, url_hotsite, url_inscricao_domain, tt, tt_resultado, tt_concluintes, tag, data_final
    order by concluintes desc, data_final asc
</cfquery>



<!--- EVENTOS COM INTEGRACAO DE INSCICAO --->

<cfif URL.tag EQ "maratona-internacional-de-floripa">

    <cfquery name="qCountInscritos">
        select count(*) as total
        from tb_ticketsports_participantes tsparticipantes
        WHERE cod_evento = '70020'
    </cfquery>

    <cfquery name="qCountInscritosTreino">
        select count(*) as total
        from tb_inscricoes
        WHERE id_evento IN (29146, 29147, 29148, 29149, 29150)
    </cfquery>

    <cfquery name="qCountFichasMedicas">
        select count(*) as total
        from tb_inscricoes
        WHERE id_evento IN (22792)
    </cfquery>

</cfif>

<cfquery name="qKilometragem">
    select
    res.percurso || 'km' as modalidade,
    res.percurso,
    to_char(AVG(res.pace_medio),'mi:ss') as pace_medio,
    to_char(AVG(res.pace_medio_top_10),'mi:ss') as pace_medio_top_10,
    COUNT(DISTINCT res.id_evento) as eventos,
    SUM(res.concluintes) as concluintes,
    (sum(res.concluintes)/count(DISTINCT res.id_evento)) as media
    from tb_resultados_resumo res
    INNER JOIN tb_evento_corridas evt on res.id_evento = evt.id_evento
    INNER JOIN tb_uf uf ON evt.estado = uf.uf
    WHERE res.concluintes > 0
    AND modalidade NOT ilike '%PCD%'
    AND modalidade NOT ilike '%CAD%'
    <cfif qBi.tag EQ "supra" OR qBi.tag EQ "contra-relogio">
        AND res.percurso IN (42)
    <cfelseif qBi.tag EQ "mega-finisher">
        AND res.percurso IN (21,42)
    </cfif>
    <cfif qBi.tipo EQ "bi" and qBi.tag NEQ 'brasil'>
        AND evt.id_evento IN (select id_evento FROM tb_agregadores_eventos WHERE agregador_tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qBi.tag#"/>)
    <cfelseif qBi.tipo EQ "eventos">
        AND evt.id_evento IN (select id_evento from tb_evento_corridas where id_agrega_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qAgrega.id_agrega_evento#"/>)
    </cfif>
    <cfif len(trim(URL.regiao))>
        and regiao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.regiao#"/>
    </cfif>
    <cfif len(trim(URL.estado))>
        and evt.estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.estado#"/>
    </cfif>
    <cfif len(trim(URL.cidade))>
        and evt.cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.cidade#"/>
    </cfif>
    <cfif len(trim(URL.id_evento))>
        and evt.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_evento#"/>
    </cfif>
    <cfif len(trim(URL.preset)) AND (URL.preset EQ "2025" OR URL.preset CONTAINS "treino")>
        AND evt.data_final between '2025-01-01' and '2025-12-31'
    </cfif>
    <cfif len(trim(URL.preset)) AND URL.preset EQ "2024">
        AND evt.data_final between '2024-01-01' and '2024-12-31'
    </cfif>
    <cfif len(trim(URL.preset)) AND URL.preset EQ "2023">
        AND evt.data_final between '2023-01-01' and '2023-12-31'
    </cfif>
    <!---and evt.data_inicial >= '2024-01-01'--->
    GROUP by res.percurso
    ORDER by res.percurso
</cfquery>

<cfquery name="qTotalKilometragem" dbtype="query">
    select sum(concluintes) as concluintes, sum(eventos) as eventos, avg(media) as media, min(media) as minimo, max(media) as maximo
    from qKilometragem
</cfquery>


<!--- EVENTOS SELECIONADO --->

<cfif len(trim(URL.id_evento))>

    <cfquery name="qEvento">
        select evt.* from tb_evento_corridas evt
        where evt.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_evento#"/>
    </cfquery>

    <cfquery name="qPerfilF">
        select to_char(AVG(ires.pace),'mi:ss') as pace_medio, ires.sexo, ires.nome_categoria, count(num_peito) as concluintes
        from tb_resultados ires
        INNER JOIN tb_evento_corridas evt on ires.id_evento = evt.id_evento
        inner join tb_uf uf ON evt.estado = uf.uf
        where evt.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_evento#"/>
        <cfif len(trim(URL.percurso))>
            and ires.percurso = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.percurso#"/>
        </cfif>
        and ires.homologado = true
        and ires.concluinte = true
        and ires.status_final = 0
        and ires.sexo = 'F'
        and ires.nome_categoria <> ''
        and ires.nome_categoria NOT ilike '%PCD%'
        GROUP by ires.nome_categoria, ires.sexo
        order by ires.nome_categoria
    </cfquery>

    <cfquery name="qTotalPerfilF" dbtype="query">
        select sum(concluintes) as concluintes, avg(concluintes) as media, min(concluintes) as minimo, max(concluintes) as maximo
        from qPerfilF
    </cfquery>

    <cfquery name="qPerfilM">
        select to_char(AVG(ires.pace),'mi:ss') as pace_medio, ires.sexo, ires.nome_categoria, count(num_peito) as concluintes
        from tb_resultados ires
        INNER JOIN tb_evento_corridas evt on ires.id_evento = evt.id_evento
        inner join tb_uf uf ON evt.estado = uf.uf
        where evt.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_evento#"/>
        <cfif len(trim(URL.percurso))>
            and ires.percurso = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.percurso#"/>
        </cfif>
        and ires.homologado = true
        and ires.concluinte = true
        and ires.status_final = 0
        and ires.sexo = 'M'
        and ires.nome_categoria <> ''
        and ires.nome_categoria NOT ilike '%PCD%'
        GROUP by ires.nome_categoria, ires.sexo
        order by ires.nome_categoria
    </cfquery>

    <cfquery name="qTotalPerfilM" dbtype="query">
        select sum(concluintes) as concluintes, avg(concluintes) as media, min(concluintes) as minimo, max(concluintes) as maximo
        from qPerfilM
    </cfquery>

    <cfquery name="qPerfilPCD">
        select to_char(AVG(ires.pace),'mi:ss') as pace_medio, ires.sexo, ires.nome_categoria, count(num_peito) as concluintes
        from tb_resultados ires
        INNER JOIN tb_evento_corridas evt on ires.id_evento = evt.id_evento
        inner join tb_uf uf ON evt.estado = uf.uf
        where evt.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_evento#"/>
        <cfif len(trim(URL.percurso))>
            and ires.percurso = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.percurso#"/>
        </cfif>
        and ires.homologado = true
        and ires.concluinte = true
        and ires.status_final = 0
        and ires.nome_categoria ilike '%PCD%'
        GROUP by ires.nome_categoria, ires.sexo
        order by ires.nome_categoria
    </cfquery>

    <cfquery name="qAcessosRR" cachedwithin="#CreateTimeSpan(0, 0, 1, 0)#">
        select
        count(log.id_log),
        DATE_PART('month', log.log_timestamp) AS month,
        DATE_PART('year', log.log_timestamp) AS year
        from tb_log log
        inner join tb_evento_corridas evt ON evt.id_evento = log.log_item_id::integer
        left join tb_uf uf ON evt.estado = uf.uf
        left join tb_agrega_eventos agr ON evt.id_agrega_evento = agr.id_agrega_evento
        where log.log_item = 'evento'
        and evt.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_evento#"/>
        and log.site = 'RR'
        group by month, year
    </cfquery>

</cfif>
