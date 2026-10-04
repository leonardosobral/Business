<cfquery name="qEvento" cachedwithin="#CreateTimeSpan(0, 0, 3, 0)#">
    SELECT
        evt.id_evento, evt.nome_evento, evt.cidade, evt.estado, evt.pais, evt.categorias, evt.coordenadas,
        evt.data_inicial, evt.data_final, evt.tag, evt.destaque, evt.tipo_corrida,
        evt.url_inscricao, evt.url_resultado, evt.resultado_completo, evt.obs_resultado,
        coalesce(lower(trim(evt.status_evento)), '') as status_evento,
        (EXISTS (SELECT 1 FROM tb_resultados raw_res
            WHERE raw_res.id_evento = evt.id_evento
            AND raw_res.origem_resultado <> 'validacao_documental'
            AND raw_res.status_final < 3)) as tem_resultados,
        DATE_PART('week', evt.data_inicial) AS week,
        DATE_PART('month', evt.data_inicial) AS month,
        translate(lower( cidade ), ' ''àáâãäéèëêíìïîóòõöôúùüûçÇ%.+!&ªº°', '--aaaaaeeeeiiiiooooouuuucc') as tag_cidade,
        (SELECT sum(res.concluintes)
            FROM tb_resultados_resumo res
            WHERE res.id_evento = evt.id_evento) as concluintes,
        (SELECT
            json_agg(json_build_object('percurso',percurso_evento,'unidade',unidade_de_medida,'tipo_corrida',tipo_corrida,'mapa',mapa) order by percurso_evento)
            from
            tb_evento_corridas_percursos pcr
            where pcr.id_evento = evt.id_evento
        ) as lista_percursos,
        (SELECT
            max(percurso_evento)
            from
            tb_evento_corridas_percursos pcr
            where pcr.id_evento = evt.id_evento
        ) as max_percurso,
        (SELECT cupom FROM vw_evento_corridas_cupom
            WHERE id_evento_agrega = evt.id_evento
            AND tipo_evento = 1
            OR (id_evento_agrega = evt.id_agrega_evento
            AND tipo_evento = 2)
        ) as cupom,
        (WITH vw as (
                SELECT percurso, sum(concluintes) as concluintes
                from
                tb_resultados_resumo pcr
                where pcr.id_evento = evt.id_evento
                group by percurso)
            SELECT
            json_agg(json_build_object('percurso',percurso,'concluintes',concluintes) order by percurso)
            from vw
        ) as lista_percursos_resultado,
        (SELECT valor_badge from tb_badges bd
            where bd.id_evento = evt.id_evento AND badge = 'certificado'
            limit 1
        ) as certificado,
        (SELECT percurso_evento from tb_evento_corridas_percursos pcr
            where pcr.id_evento = evt.id_evento AND percurso_evento = 42
            limit 1
        ) as is_maratona
    FROM tb_evento_corridas evt
    WHERE evt.tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.tag#"/>
    AND evt.ativo = true
</cfquery>


<!--- REDIRECIONA PARA BUSCA --->

<cfif NOT qEvento.recordcount>
    <cflocation statuscode="301" addtoken="false" url="/busca/?termo=#replace(URL.tag, '-', ' ', 'ALL')#"/>
</cfif>

<cfquery name="qModalidades" cachedwithin="#CreateTimeSpan(0, 0, 1, 0)#">
    select
    id_evento,
    modalidade,
    cast(res.percurso as integer) as percurso,
    count(distinct num_peito) as concluintes,
    ( select concat(nome_parceiro,',',nome_permit,',',descricao_permit)
        from tb_parceiros pa
        inner join tb_permits pe on pa.id_parceiro = pe.id_parceiro
        inner join tb_tipos_permit tp on pe.id_tipo_permit = tp.id_tipo_permit
        where
        pe.id_permit = get_id_permit_parceiro(3,res.id_evento,res.percurso::integer)
        ) as permit_cbat,
    ( select concat(nome_parceiro,',',nome_permit,',',descricao_permit)
        from tb_parceiros pa
        inner join tb_permits pe on pa.id_parceiro = pe.id_parceiro
        inner join tb_tipos_permit tp on pe.id_tipo_permit = tp.id_tipo_permit
        where
        pe.id_permit = get_id_permit_parceiro(4,res.id_evento,res.percurso::integer)
        ) as permit_wa
    from tb_resultados res
    WHERE res.modalidade is not null
    and res.origem_resultado <> 'validacao_documental'
    and res.concluinte = true
    and res.status_final = 0
    and id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>
    group by id_evento, res.percurso, modalidade
    order by res.percurso, modalidade
</cfquery>

<cfquery name="qFornecedores" cachedwithin="#CreateTimeSpan(0, 0, 5, 0)#">
    select descricao_tipo, cfo.id_fornecedor, cfo.id_fornecedor_tipo, forn.nome_fornecedor, forn.site_fornecedor, forn.tag_fornecedor, forn.tag_tipo
    from tb_evento_corridas_fornecedores cfo
    inner join tb_fornecedores_tipos tip on cfo.id_fornecedor_tipo = tip.id_fornecedor_tipo
    inner join tb_fornecedores forn on cfo.id_fornecedor = forn.id_fornecedor and cfo.id_fornecedor_tipo = tip.id_fornecedor_tipo
    where cfo.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>
    ORDER BY tip.id_fornecedor_tipo
</cfquery>

<cfquery name="qProcessamentoResultado" cachedwithin="#CreateTimeSpan(0, 0, 5, 0)#">
    select max(data_processamento_final) as data_processamento_final
    from tb_resultados_processa
    where id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>
</cfquery>


<!--- A página existe antes dos resultados; disponibilidade é um estado do conteúdo. --->
<cfset VARIABLES.eventoTemResultados = qEvento.tem_resultados/>
<cfset VARIABLES.eventoResultadoEstado = "aguardando"/>
<cfset VARIABLES.eventoStatusTitulo = "Resultados ainda não publicados"/>
<cfset VARIABLES.eventoStatusDescricao = "Os resultados desta prova ainda não estão disponíveis no Open Results."/>

<cfif qEvento.status_evento EQ "cancelado">
    <cfset VARIABLES.eventoResultadoEstado = "cancelado"/>
    <cfset VARIABLES.eventoStatusTitulo = "Evento cancelado"/>
    <cfset VARIABLES.eventoStatusDescricao = "Esta prova consta como cancelada. Consulte os detalhes do evento para mais informações."/>
<cfelseif qEvento.obs_resultado EQ "PNC">
    <cfset VARIABLES.eventoResultadoEstado = "indisponivel"/>
    <cfset VARIABLES.eventoStatusTitulo = "Acesso aos resultados não disponibilizado pelo organizador"/>
    <cfset VARIABLES.eventoStatusDescricao = "Os resultados deste evento não estão disponíveis para consulta e inclusão no histórico pelo Open Results."/>
<cfelseif qEvento.obs_resultado EQ "REP">
    <cfset VARIABLES.eventoResultadoEstado = "processamento"/>
    <cfset VARIABLES.eventoStatusTitulo = "Resultados em processamento"/>
    <cfset VARIABLES.eventoStatusDescricao = "Os resultados ainda poderão sofrer ajustes ou atualizações."/>
<cfelseif VARIABLES.eventoTemResultados>
    <cfset VARIABLES.eventoResultadoEstado = "disponivel"/>
    <cfset VARIABLES.eventoStatusTitulo = "Resultados disponíveis"/>
    <cfset VARIABLES.eventoStatusDescricao = "Consulte tempos, classificação e resultados por atleta e modalidade."/>
<cfelseif isDate(qEvento.data_inicial) AND dateCompare(qEvento.data_inicial, now(), "d") GT 0>
    <cfset VARIABLES.eventoResultadoEstado = "agendado"/>
    <cfset VARIABLES.eventoStatusTitulo = "Prova prevista para #lsDateFormat(qEvento.data_inicial, 'dd/mm/yyyy')#"/>
    <cfset VARIABLES.eventoStatusDescricao = "O evento ainda não aconteceu. Consulte a data, o local e as distâncias; os resultados ainda não foram publicados."/>
</cfif>


<!--- LOG --->

<cfquery>
    INSERT INTO tb_log
    (log_item, log_item_id, log_user, log_user_agent, site)
    VALUES
    ('evento',<cfqueryparam cfsqltype="cf_sql_varchar" value="#qEvento.id_evento#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.HTTP_USER_AGENT#"/>, <cfqueryparam cfsqltype="cf_sql_varchar" value="#APPLICATION.codSite#"/>)
</cfquery>
