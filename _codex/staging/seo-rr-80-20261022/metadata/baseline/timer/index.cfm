<!doctype html>
<html lang="pt-br">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- TEMPLATE --->
<cfset VARIABLES.template = "/timer/"/>

<!--- TAG PARAM TREAT --->
<cfparam name="URL.tag" default=""/>
<cfset URL.tag = lcase(trim(replace(URL.tag, '/', '')))/>

<!--- A supplier page needs a registered tag; missing input is a normal 404. --->
<cfif NOT len(URL.tag)>
    <cfset URL.tag = listFirst(CGI.REQUEST_URI ?: "/timer/", "?")/>
    <cfinclude template="../includes/errors/notfound.cfm"/>
    <cfabort/>
</cfif>


<!--- BACKEND --->
<cfinclude template="../includes/estrutura/variaveis.cfm"/>
<cfinclude template="../includes/backend/backend.cfm"/>
<cfinclude template="../includes/backend/backend_login.cfm"/>
<cfinclude template="../includes/backend/backend_feed.cfm"/>

<cfquery name="qAgrega" result="qAgregaMeta">
    SELECT * FROM tb_agrega_eventos
    WHERE tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.tag#"/>
</cfquery>
<cfset logQueryDebug("qAgrega", qAgregaMeta, "timer/agrega", "sem cache", qAgrega)/>

<cfquery name="qFornecedor" result="qFornecedorMeta">
    SELECT fr.*, tag_fornecedor as tag, 'timer' as tipo_agregacao
    FROM tb_fornecedores fr
    WHERE tag_fornecedor = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.tag#"/>
</cfquery>
<cfset logQueryDebug("qFornecedor", qFornecedorMeta, "timer/fornecedor", "sem cache", qFornecedor)/>

<cfif NOT qFornecedor.recordCount>
    <cfset URL.tag = listFirst(CGI.REQUEST_URI ?: "/timer/", "?")/>
    <cfinclude template="../includes/errors/notfound.cfm"/>
    <cfabort/>
</cfif>

<cfquery name="qTema" result="qTemaMeta">
    SELECT * FROM tb_temas
    WHERE id_tema = <cfqueryparam cfsqltype="cf_sql_integer" value="#qFornecedor.id_tema#"/>
</cfquery>
<cfset logQueryDebug("qTema", qTemaMeta, "timer/tema", "sem cache", qTema)/>

<cfquery name="qEventosFornecedor" cachedwithin="#CreateTimeSpan(0, 0, 5, 0)#" result="qEventosResult">
    SELECT
        evt.id_evento, evt.nome_evento, evt.cidade, evt.estado, evt.pais, evt.categorias, evt.coordenadas,
        evt.data_inicial, evt.data_final, evt.tag, evt.destaque, evt.tipo_corrida,
        evt.url_inscricao, evt.url_resultado,
        '' as id_foco_radical, evt.status_evento,
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
        (SELECT condicoes FROM vw_evento_corridas_cupom
            WHERE ((id_evento_agrega = evt.id_evento
            AND tipo_evento = 1)
            OR (id_evento_agrega = evt.id_agrega_evento
            AND tipo_evento = 2))
            AND current_date between data_validade_inicio and data_validade_fim
        ) as cupom,
        (SELECT
            json_agg(json_build_object('percurso',percurso,'modalidade',modalidade,'concluintes',concluintes) order by percurso)
            from
            tb_resultados_resumo pcr
            where pcr.id_evento = evt.id_evento
        ) as lista_percursos_resultado,
        (SELECT percurso_evento from tb_evento_corridas_percursos pcr
            where pcr.id_evento = evt.id_evento AND percurso_evento = 42
            limit 1
        ) as is_maratona
    FROM tb_evento_corridas evt
    WHERE evt.ativo = true
    AND
        (
                ( Exists (SELECT distinct id_evento FROM tb_resultados_resumo res WHERE evt.id_evento = res.id_evento )
                 OR (evt.url_resultado is not null AND evt.url_resultado <> '') )

        OR
            evt.data_inicial >= <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now(), 'yyyy-mm-dd')#"/>
        )
    <cfif isDefined("URL.cidade")>
        AND evt.cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.cidade#"/>
    </cfif>
    <cfif VARIABLES.template EQ "/estado/">
        and evt.estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(URL.tag)#"/>
    </cfif>
    <cfif VARIABLES.template EQ "/timer/">
        AND evt.id_evento IN ( select id_evento from tb_evento_corridas_fornecedores where id_fornecedor = <cfqueryparam cfsqltype="cf_sql_integer" value="#qFornecedor.id_fornecedor#"/>)
    </cfif>
    <cfif VARIABLES.template EQ "/org/">
        AND evt.id_evento IN ( select id_evento from tb_evento_corridas_fornecedores where id_fornecedor = <cfqueryparam cfsqltype="cf_sql_integer" value="#qFornecedor.id_fornecedor#"/>)
    </cfif>
    ORDER BY evt.data_final desc, concluintes desc NULLS LAST;
</cfquery>
<cfset logQueryDebug("qEventosFornecedor", qEventosResult, "timer/eventos_fornecedor", "5min", qEventosFornecedor)/>


<!--- META INFO --->
<cfset VARIABLES.canonical = "#APPLICATION.baseCanonica##VARIABLES.template##URL.tag##Len(trim(URL.tag)) ? '/' : ''##VARIABLES.queryString#"/>
<cfset VARIABLES.title = "#qFornecedor.nome_fornecedor# - #APPLICATION.nomeSite#"/>
<cfset VARIABLES.description = "Timers - #qFornecedor.nome_fornecedor# - #APPLICATION.nomeSite#"/>
<cfset VARIABLES.keywords = "resultados, corrida, competição, pódio, atletas, corredores"/>

<!--- HEAD --->
<cfinclude template="../includes/estrutura/head.cfm"/>

<body <cfif qTema.recordcount>style="background-color:<cfoutput>#qTema.cor_fundo#</cfoutput>"</cfif>>

    <!--- SEO WEB TOOLS --->

    <cfinclude template="../includes/estrutura/seo-web-tools-body-start.cfm"/>

    <style>
        @media (max-width: 991.98px) {
            .home-mobile-section {
                margin-top: 0.75rem;
            }
        }
    </style>


    <!--- CONTAINER DE CONTEUDO --->

    <div class="container">


        <!--- HEADER --->

        <cfinclude template="../includes/estrutura/header.cfm"/>
        <cfinclude template="../includes/estrutura/home_hero_busca.cfm"/>

        <main id="rr-page-content" class="rr-page-content" data-rr-page-content>

        <div class="row g-2">

            <div class="d-none d-lg-block col-lg-3 col-xl-3 order-lg-1 home-mobile-section">

                <cfinclude template="../includes/estrutura/home_sidebar_async_slot.cfm"/>

            </div>

            <!--- LISTA DE EVENTOS DE CORRIDA --->

            <div class="col-12 col-md-8 col-lg-6 col-xl-6 px-lg-3 order-1 order-md-2">

                <!--- HEADER DO TEMA--->

                <cfinclude template="../includes/estrutura/header_tema.cfm"/>

                <!--- LISTA DE EVENTOS DE CORRIDA --->

                <cfquery name="qEventosProximos" result="qEventosProximosMeta">
                    SELECT
                        evt.id_evento, evt.nome_evento, evt.cidade, evt.estado, evt.pais, evt.categorias, evt.coordenadas,
                        evt.data_inicial, evt.data_final, evt.tag, evt.destaque, evt.tipo_corrida,
                        evt.url_inscricao, evt.url_resultado,
                        '' as id_foco_radical, evt.status_evento,
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
                        (SELECT condicoes FROM vw_evento_corridas_cupom
                            WHERE ((id_evento_agrega = evt.id_evento
                            AND tipo_evento = 1)
                            OR (id_evento_agrega = evt.id_agrega_evento
                            AND tipo_evento = 2))
                            AND current_date between data_validade_inicio and data_validade_fim
                        ) as cupom,
                        (SELECT
                            json_agg(json_build_object('percurso',percurso,'modalidade',modalidade,'concluintes',concluintes) order by percurso)
                            from
                            tb_resultados_resumo pcr
                            where pcr.id_evento = evt.id_evento
                        ) as lista_percursos_resultado,
                        (SELECT percurso_evento from tb_evento_corridas_percursos pcr
                            where pcr.id_evento = evt.id_evento AND percurso_evento = 42
                            limit 1
                        ) as is_maratona
                    FROM tb_evento_corridas evt
                    WHERE evt.ativo = true
                    <cfif VARIABLES.template EQ "/timer/">
                        AND evt.id_evento IN ( select id_evento from tb_evento_corridas_fornecedores where id_fornecedor = <cfqueryparam cfsqltype="cf_sql_integer" value="#qFornecedor.id_fornecedor#"/>)
                        AND evt.data_inicial >= <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now(), 'yyyy-mm-dd')#"/>
                    </cfif>
                    <cfif VARIABLES.template EQ "/org/">
                        AND evt.id_evento IN ( select id_evento from tb_evento_corridas_fornecedores where id_fornecedor = <cfqueryparam cfsqltype="cf_sql_integer" value="#qFornecedor.id_fornecedor#"/>)
                        AND evt.data_inicial >= <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now(), 'yyyy-mm-dd')#"/>
                    </cfif>
                    ORDER BY evt.data_inicial, evt.destaque NULLS LAST, evt.id_tema desc, evt.id_agrega_evento desc, max_percurso desc NULLS LAST, id_foco_radical NULLS LAST, evt.tipo_corrida
                </cfquery>
                <cfset logQueryDebug("qEventosProximos", qEventosProximosMeta, "timer/eventos_proximos", "sem cache", qEventosProximos)/>

                <cfquery name="qEventosPassados" result="qEventosPassadosMeta">
                    SELECT
                        evt.id_evento, evt.nome_evento, evt.cidade, evt.estado, evt.pais, evt.categorias, evt.coordenadas,
                        evt.data_inicial, evt.data_final, evt.tag, evt.destaque, evt.tipo_corrida,
                        evt.url_inscricao, evt.url_resultado,
                        '' as id_foco_radical, evt.status_evento,
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
                        (SELECT condicoes FROM vw_evento_corridas_cupom
                            WHERE ((id_evento_agrega = evt.id_evento
                            AND tipo_evento = 1)
                            OR (id_evento_agrega = evt.id_agrega_evento
                            AND tipo_evento = 2))
                            AND current_date between data_validade_inicio and data_validade_fim
                        ) as cupom,
                        (SELECT
                            json_agg(json_build_object('percurso',percurso,'modalidade',modalidade,'concluintes',concluintes) order by percurso)
                            from
                            tb_resultados_resumo pcr
                            where pcr.id_evento = evt.id_evento
                        ) as lista_percursos_resultado,
                        (SELECT percurso_evento from tb_evento_corridas_percursos pcr
                            where pcr.id_evento = evt.id_evento AND percurso_evento = 42
                            limit 1
                        ) as is_maratona
                    FROM tb_evento_corridas evt
                    WHERE evt.data_inicial <= <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now(), 'yyyy-mm-dd')#"/>
                    AND evt.ativo = true
                    AND ( Exists (SELECT distinct id_evento FROM tb_resultados_resumo res WHERE evt.id_evento = res.id_evento )
                        OR (evt.url_resultado is not null AND evt.url_resultado <> '') )
                    <cfif VARIABLES.template EQ "/timer/">
                        AND evt.id_evento IN ( select id_evento from tb_evento_corridas_fornecedores where id_fornecedor = <cfqueryparam cfsqltype="cf_sql_integer" value="#qFornecedor.id_fornecedor#"/>)
                    </cfif>
                    <cfif VARIABLES.template EQ "/org/">
                        AND evt.id_evento IN ( select id_evento from tb_evento_corridas_fornecedores where id_fornecedor = <cfqueryparam cfsqltype="cf_sql_integer" value="#qFornecedor.id_fornecedor#"/>)
                    </cfif>
                    ORDER BY evt.data_final desc, concluintes desc NULLS LAST;
                </cfquery>
                <cfset logQueryDebug("qEventosPassados", qEventosPassadosMeta, "timer/eventos_passados", "sem cache", qEventosPassados)/>

                <!--- ABAS --->

                <nav class="card mt-0 mb-3">
                    <div class="nav nav-tabs justify-content-center" id="nav-tab" role="tablist">
                        <button class="nav-link <cfif qEventosProximos.recordcount>active</cfif>" id="nav-tab-2" data-bs-toggle="tab" data-bs-target="#nav-home-2" type="button" role="tab" aria-controls="nav-home-2" aria-selected="false">Próximos<span class="badge badge-warning ms-2"><cfoutput>#qEventosProximos.recordcount#</cfoutput></span></button>
                        <button class="nav-link <cfif NOT qEventosProximos.recordcount>active</cfif>" id="nav-tab-7" data-bs-toggle="tab" data-bs-target="#nav-home-7" type="button" role="tab" aria-controls="nav-home-7" aria-selected="false">Realizados<span class="badge badge-warning ms-2"><cfoutput>#qEventosPassados.recordcount#</cfoutput></span></button>
                    </div>
                </nav>

                <div class="tab-content" id="nav-tabContent">

                    <div class="tab-pane fade <cfif qEventosProximos.recordcount>show active</cfif> p-0" id="nav-home-2" role="tabpanel" aria-labelledby="nav-tab-2" tabindex="1">

                        <cfset VARIABLES.agrupamento = "mes"/>
                        <cfset VARIABLES.qEventosAba = qEventosProximos/>
                        <cfinclude template="../includes/lista_de_eventos_simple.cfm"/>

                    </div>

                    <div class="tab-pane fade <cfif NOT qEventosProximos.recordcount>show active</cfif> p-0" id="nav-home-7" role="tabpanel" aria-labelledby="nav-tab-7" tabindex="6">

                        <cfset VARIABLES.agrupamento = "mes"/>
                        <cfset VARIABLES.qEventosAba = qEventosPassados/>
                        <cfinclude template="../includes/lista_de_eventos_simple.cfm"/>

                    </div>

                </div>

            </div>

            <!--- BARRA LATERAL --->

            <div class="col-12 col-lg-3 order-3 home-mobile-section">

                <cfinclude template="../includes/estrutura/conteudo_lateral_api.cfm"/>

            </div>

        </div>

        </main>

    </div>


    <!--- FOOTER --->

    <cfinclude template="../includes/estrutura/footer.cfm"/>


    <!--- MODAL CADASTRO EVENTO --->

    <cfinclude template="../includes/modal/modal_cadastro_evento.cfm"/>


    <!--- MODAL LOGIN --->

    <cfinclude template="../includes/modal/modal_login.cfm"/>


    <!--- SEO WEB TOOLS --->

    <cfinclude template="../includes/estrutura/seo-web-tools-body-end.cfm"/>

</body>

</html>
