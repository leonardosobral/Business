<cfquery name="qEventosBase" cachedwithin="#CreateTimeSpan(0, 0, 0, 5)#">
    SELECT evt.*,
    <cfif URL.preset NEQ "futuros">
        (select sum(concluintes) from tb_resultados_resumo where id_evento = evt.id_evento) as total,
    </cfif>
    (select
        json_agg(json_build_object('percurso',percurso_evento,'unidade',unidade_de_medida,'tipo_corrida',tipo_corrida) order by percurso_evento)
        from
        tb_evento_corridas_percursos pcr
        where pcr.id_evento = evt.id_evento
    ) as lista_percursos,
    (SELECT percurso_evento from tb_evento_corridas_percursos pcr
        where pcr.id_evento = evt.id_evento AND percurso_evento = 42
        limit 1
    ) as is_maratona,
    (select
        max(percurso_evento)
        from
        tb_evento_corridas_percursos pcr
        where pcr.id_evento = evt.id_evento
    ) as max_percurso,
    (SELECT count(id_fornecedor)
                FROM tb_evento_corridas_fornecedores
                WHERE id_evento = evt.id_evento
                AND id_fornecedor_tipo = 1
    ) as has_organizador,
    (SELECT count(id_fornecedor)
                FROM tb_evento_corridas_fornecedores
                WHERE id_evento = evt.id_evento
                AND id_fornecedor_tipo = 2
    ) as has_cronometrador
    FROM tb_evento_corridas evt
    <cfif URL.preset EQ "inativos">
        WHERE ativo = false
        <cfelse>
        WHERE ativo = true
    </cfif>
    <cfif len(trim(URL.busca))>
        AND nome_evento ilike <cfqueryparam cfsqltype="cf_sql_varchar" value="%#trim(URL.busca)#%"/>
        OR tag ilike <cfqueryparam cfsqltype="cf_sql_varchar" value="%#trim(URL.busca)#%"/>
    </cfif>
    <cfif URL.preset EQ "duplicados">
        AND evt.tag IN (
            SELECT tag FROM tb_evento_corridas
            GROUP BY tag
            HAVING count(*) > 1
        )
        OR evt.info_duplicado IS NOT NULL
    </cfif>
    <cfif len(trim(URL.id_agrega_evento)) >
        AND evt.id_agrega_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_agrega_evento#"/>
    </cfif>
    <cfif len(trim(URL.agregador_tag))>
        <cfif URL.agregador_tag EQ 'correria-campinas'>
            AND evt.cidade IN (SELECT cidade FROM tb_agregadores_cidades WHERE agregador_tag = 'correria-campinas')
            AND evt.estado = 'SP'
        <cfelse>
            AND evt.id_evento IN (
                select id_evento from tb_agregadores_eventos where agregador_tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.agregador_tag#"/>
            )
        </cfif>
    </cfif>
</cfquery>


<cfquery name="qEventos" dbtype="query" maxrows="3000">
    SELECT *
    FROM qEventosBase
    WHERE data_final is not null
    <cfif len(trim(URL.estado))>
        and estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(URL.estado)#"/>
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "semana">
        AND data_final >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()-7#"/>
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "mes">
        AND data_final >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()-30#"/>
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "2025">
        AND data_final between '2025-01-01' and '2025-12-31'
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "2024">
        AND data_final between '2024-01-01' and '2024-12-31'
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "2023">
        AND data_final between '2023-01-01' and '2023-12-31'
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "2022">
        AND data_final <= '2022-12-31'
    </cfif>
    <cfif URL.preset EQ "inscricao_incompleta">
        and url_inscricao = ''
    </cfif>
    <cfif URL.preset EQ "obs">
        and status_evento is not null
    </cfif>
    <cfif URL.preset EQ "principais">
        AND tipo_corrida = 'rua'
        AND (max_percurso >= 21 OR id_agrega_evento is not null)
    </cfif>
    <cfif URL.preset EQ "maratonas">
        and is_maratona = 42
        and pais IN ('BR','AR','CL','PE','PY','UR')
        and tipo_corrida = 'rua'
    </cfif>
    <cfif URL.preset EQ "destaques">
        and destaque is not null
    </cfif>
    <cfif URL.periodo EQ "2022" OR URL.periodo EQ "2023" OR URL.periodo EQ "2024">
        ORDER BY data_inicial desc
    <cfelseif URL.preset EQ "duplicados" OR URL.preset EQ "obs">
        ORDER BY nome_evento, data_inicial asc
    <cfelse>
        ORDER BY data_final asc
    </cfif>
</cfquery>


<cfquery name="qEstados">
    SELECT DISTINCT estado FROM tb_evento_corridas WHERE estado is not null AND estado <> '' ORDER BY estado
</cfquery>

<cfquery name="qAgregaCircuito" cachedwithin="#CreateTimeSpan(0, 0, 5, 0)#">
    SELECT * FROM tb_agrega_eventos
    WHERE tipo_agregacao IN ('circuito')
    ORDER by tipo_agregacao, nome_evento_agregado
</cfquery>

<cfquery name="qAgregaMaratonas" cachedwithin="#CreateTimeSpan(0, 0, 5, 0)#">
    SELECT * FROM tb_agrega_eventos
    WHERE tipo_agregacao IN ('maratona')
    ORDER by tipo_agregacao, nome_evento_agregado
</cfquery>

<cfquery name="qAgregaCorridas" cachedwithin="#CreateTimeSpan(0, 0, 5, 0)#">
    SELECT * FROM tb_agrega_eventos
    WHERE tipo_agregacao IN ('corrida')
    ORDER by tipo_agregacao, nome_evento_agregado
</cfquery>

<cfquery name="qAgrega" cachedwithin="#CreateTimeSpan(0, 0, 5, 0)#">
    SELECT * FROM tb_agrega_eventos
    ORDER by tipo_agregacao, nome_evento_agregado
</cfquery>

<cfquery name="qAgregadores" cachedwithin="#CreateTimeSpan(0, 0, 5, 0)#">
    SELECT * FROM tb_agregadores
    ORDER by agregador_nome
</cfquery>

<cfquery name="qTema" cachedwithin="#CreateTimeSpan(0, 0, 5, 0)#">
    SELECT * FROM tb_temas
    ORDER by logo
</cfquery>


<cfquery name="qStatsInsc" dbtype="query">
    select id_evento from qEventos where url_inscricao is not null and url_inscricao <> ''
</cfquery>

<cfquery name="qStatsEnd" dbtype="query">
    select id_evento from qEventos where endereco is not null and endereco <> ''
</cfquery>

<cfquery name="qStatsConteudo" dbtype="query">
    select id_evento from qEventos where descricao is not null and descricao <> ''
</cfquery>

<cfif URL.preset EQ "futuros">
    <cfquery name="qStatsDistancias" dbtype="query">
        select id_evento from qEventos where categorias is not null and categorias <> ''
    </cfquery>
<cfelse>
    <cfquery name="qStatsResultados" dbtype="query">
        select id_evento from qEventos where total > 0
    </cfquery>
</cfif>
