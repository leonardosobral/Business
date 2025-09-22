<cfquery name="qBase" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
    select unaccent(upper(res.equipe)) as equipe, count(res.id_resultado) as corredores, count(distinct res.id_evento) as eventos
    from tb_resultados res
    inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
    where unaccent(upper(res.equipe)) NOT IN ('','GRUPOS E ASSESSORIAS','PUBLICO GERAL','SYMPLA','','AVULSO','N/A','AVILSO','SUA','EU','NA','SEM','NÃO TEM','NAO TEM','---','.','AVULSA','INDIVIDUAL','SEM EQUIPE','OUTRA','EQUIPE','NENHUMA','--','X','NÃO','-','NENHUM','NULL','NAO','NÃO TENHO','NAO TENHO','NAO PARTICIPO','NAO INFORMADO','SITE','TICKET SPORTS','0')
    and equipe is not null
    AND evt.pais = 'BR'
    group by res.equipe
    having count(res.id_resultado) > 10
    order by corredores desc;
</cfquery>

<cfif len(trim(URL.equipe))>
    <cfquery name="qBaseEvento" cachedwithin="#CreateTimeSpan(0, 0, 3, 0)#">
        SELECT
        extract(year from evt.data_final) as ano,
        evt.id_evento, evt.estado, evt.cidade, evt.nome_evento, evt.tag, evt.data_final, evt.url_resultado, evt.url_inscricao, evt.obs_resultado,
        '' as nome_evento_agregado, '' as tipo_agregacao, '' as id_agrega_evento,
        uf.regiao, uf.nome_regiao, uf.nome_uf,
        COALESCE((select sum(res.concluintes)
            FROM tb_resultados_resumo res
            WHERE res.id_evento = evt.id_evento),0) as concluintes,
        (
            select count(*)
            from tb_resultados res
            where unaccent(upper(res.equipe)) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.equipe#"/>
            and res.id_evento = evt.id_evento
        ) as corredores
        from tb_evento_corridas evt
        LEFT join tb_uf uf ON evt.estado = uf.uf
        WHERE ativo = true
        AND evt.pais = 'BR'
        AND id_evento IN
        (
            select distinct res.id_evento
            from tb_resultados res
            where unaccent(upper(res.equipe)) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.equipe#"/>
        )
    </cfquery>
    <cfquery name="qStatsEvento" dbtype="query">
        select * from qBaseEvento order by corredores desc
    </cfquery>
</cfif>
