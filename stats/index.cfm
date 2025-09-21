<!doctype html>
<html lang="pt-br">

<!--- Define the page request properties. --->
<cfsetting requesttimeout="180" showdebugoutput="false" enablecfoutputonly="false" />

<cfprocessingdirective pageencoding="utf-8"/>

<!--- BACKEND --->
<cfinclude template="../includes/backend/backend_login.cfm"/>

<!--- HEAD --->
<head>

    <!--- REQUIRED META TAGS --->
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1"/>

    <title>Runner Hub - Estatísticas</title>
    <cfinclude template="../includes/seo-web-tools-head.cfm"/>

    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.5.0/css/font-awesome.min.css">

</head>

<body class="bg-body-secondary">

    <cfif NOT isDefined("COOKIE.id")>

        <div class="g-signin2 ms-2" data-onsuccess="onSignIn"></div>

    <cfelse>

        <div class="container-fluid mt-3">


            <!--- HEADER --->

            <cfinclude template="../includes/header_parceiro.cfm"/>


            <!--- CONTEUDO --->

            <div class="row g-3">

                <div class="col-sm-12 col-md-4 mb-1">

                    <div class="card">

                        <div class="card-header h5 p-3">Números de Gerais <cfif isDefined("URL.estado") AND Len(trim(URL.estado))> de <cfoutput>#URL.estado#</cfoutput></cfif></div>

                        <div class="card-body p-3">

                            <cfquery name="qProvas" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(evt.id_evento) as total
                                FROM tb_evento_corridas evt
                                where evt.ativo = true
                                <cfif isDefined("URL.estado") AND Len(trim(URL.estado))>
                                    AND evt.estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.estado#"/>
                                </cfif>
                            </cfquery>
                            <p>Provas catalogadas <cfif isDefined("URL.estado") AND Len(trim(URL.estado))><cfoutput> - #URL.estado#</cfoutput><cfelse>no Mundo</cfif>: <cfoutput><b>#lsNumberFormat(qProvas.total)#</b></cfoutput></p>

                            <cfquery name="qProvas" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(evt.id_evento) as total
                                FROM tb_evento_corridas evt
                                where evt.ativo = true AND evt.pais = 'BR'
                            </cfquery>
                            <p>Provas catalogadas no Brasil: <cfoutput><b>#lsNumberFormat(qProvas.total)#</b></cfoutput></p>

                            <cfquery name="qProvasResultados" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(distinct res.id_evento) as total
                                    from tb_resultados_resumo res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND evt.pais = 'BR'
                                <cfif isDefined("URL.estado") AND Len(trim(URL.estado))>
                                    AND evt.estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.estado#"/>
                                </cfif>
                            </cfquery>
                            <p>Provas com resultado coletado <cfif isDefined("URL.estado") AND Len(trim(URL.estado))><cfoutput> - #URL.estado#</cfoutput><cfelse>no Brasil</cfif>: <cfoutput><b>#lsNumberFormat(qProvasResultados.total)#</b></cfoutput></p>

                            <cfquery name="qProvasResultados" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(distinct res.id_evento) as total
                                    from tb_resultados_resumo res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND evt.pais = 'BR'
                            </cfquery>
                            <p>Provas com resultado coletado no Brasil: <cfoutput><b>#lsNumberFormat(qProvasResultados.total)#</b></cfoutput></p>

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select sum(res.concluintes) as total
                                    from tb_resultados_resumo res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true
                                <cfif isDefined("URL.estado") AND Len(trim(URL.estado))>
                                    AND evt.estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.estado#"/>
                                </cfif>
                            </cfquery>
                            <p>Resultados coletados <cfif isDefined("URL.estado") AND Len(trim(URL.estado))><cfoutput> - #URL.estado#</cfoutput><cfelse>no Brasil</cfif>: <cfoutput><b>#lsNumberFormat(qRetorno.total)#</b></cfoutput></p>

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select sum(res.concluintes) as total
                                    from tb_resultados_resumo res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND evt.pais = 'BR'
                            </cfquery>
                            <p>Resultados coletados no Brasil: <cfoutput><b>#lsNumberFormat(qRetorno.total)#</b></cfoutput></p>

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(DISTINCT res.nome) as total
                                    from tb_resultados res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND evt.pais = 'BR'
                                <cfif isDefined("URL.estado") AND Len(trim(URL.estado))>
                                    AND evt.estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.estado#"/>
                                </cfif>
                            </cfquery>
                            <p>Corredores <cfif isDefined("URL.estado") AND Len(trim(URL.estado))><cfoutput> - #URL.estado#</cfoutput><cfelse>no Brasil</cfif>: <cfoutput><b>#lsNumberFormat(qRetorno.total)#</b></cfoutput></p>

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(DISTINCT res.nome) as total
                                    from tb_resultados res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND evt.pais = 'BR'
                            </cfquery>
                            <p>Corredores no Brasil: <cfoutput><b>#lsNumberFormat(qRetorno.total)#</b></cfoutput></p>

                            <hr/>

                            <h5>2024</h5>

                            <cfquery name="qProvas" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(evt.id_evento) as total
                                FROM tb_evento_corridas evt
                                where evt.ativo = true AND evt.data_final BETWEEN '2024-01-01' and '2024-12-31'
                                <cfif isDefined("URL.estado") AND Len(trim(URL.estado))>
                                    AND evt.estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.estado#"/>
                                </cfif>
                            </cfquery>
                            <p>Provas catalogadas <cfif isDefined("URL.estado") AND Len(trim(URL.estado))><cfoutput> - #URL.estado#</cfoutput><cfelse>no Brasil</cfif>: <cfoutput><b>#lsNumberFormat(qProvas.total)#</b></cfoutput></p>

                            <cfquery name="qProvas" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(evt.id_evento) as total
                                    FROM tb_evento_corridas evt
                                where evt.ativo = true AND evt.pais = 'BR' AND evt.data_final BETWEEN '2024-01-01' and '2024-12-31'
                            </cfquery>
                            <p>Provas catalogadas no Brasil: <cfoutput><b>#lsNumberFormat(qProvas.total)#</b></cfoutput></p>

                            <cfquery name="qProvasResultados" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(distinct res.id_evento) as total
                                    from tb_resultados_resumo res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND evt.pais = 'BR' AND evt.data_final BETWEEN '2024-01-01' and '2024-12-31'
                                <cfif isDefined("URL.estado") AND Len(trim(URL.estado))>
                                    AND evt.estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.estado#"/>
                                </cfif>
                            </cfquery>
                            <p>Provas com resultado coletado <cfif isDefined("URL.estado") AND Len(trim(URL.estado))><cfoutput> - #URL.estado#</cfoutput><cfelse>no Brasil</cfif>: <cfoutput><b>#lsNumberFormat(qProvasResultados.total)#</b></cfoutput></p>

                            <cfquery name="qProvasResultados" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(distinct res.id_evento) as total
                                    from tb_resultados_resumo res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND evt.pais = 'BR' AND evt.data_final BETWEEN '2024-01-01' and '2024-12-31'
                            </cfquery>
                            <p>Provas com resultado coletado no Brasil: <cfoutput><b>#lsNumberFormat(qProvasResultados.total)#</b></cfoutput></p>

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select sum(res.concluintes) as total
                                    from tb_resultados_resumo res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND evt.data_final BETWEEN '2024-01-01' and '2024-12-31'
                                <cfif isDefined("URL.estado") AND Len(trim(URL.estado))>
                                    AND evt.estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.estado#"/>
                                </cfif>
                            </cfquery>
                            <p>Resultados coletados <cfif isDefined("URL.estado") AND Len(trim(URL.estado))><cfoutput> - #URL.estado#</cfoutput><cfelse>no Brasil</cfif>: <cfoutput><b>#lsNumberFormat(qRetorno.total)#</b></cfoutput></p>

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select sum(res.concluintes) as total
                                    from tb_resultados_resumo res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND evt.pais = 'BR' AND evt.data_final BETWEEN '2024-01-01' and '2024-12-31'
                            </cfquery>
                            <p>Resultados coletados no Brasil: <cfoutput><b>#lsNumberFormat(qRetorno.total)#</b></cfoutput></p>

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(DISTINCT res.nome) as total
                                    from tb_resultados res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND evt.pais = 'BR' AND evt.data_final BETWEEN '2024-01-01' and '2024-12-31'
                                <cfif isDefined("URL.estado") AND Len(trim(URL.estado))>
                                    AND evt.estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.estado#"/>
                                </cfif>
                            </cfquery>
                            <p>Corredores <cfif isDefined("URL.estado") AND Len(trim(URL.estado))><cfoutput> - #URL.estado#</cfoutput><cfelse>no Brasil</cfif>: <cfoutput><b>#lsNumberFormat(qRetorno.total)#</b></cfoutput></p>

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(DISTINCT res.nome) as total
                                    from tb_resultados res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND evt.pais = 'BR' AND evt.data_final BETWEEN '2024-01-01' and '2024-12-31'
                            </cfquery>
                            <p>Corredores no Brasil: <cfoutput><b>#lsNumberFormat(qRetorno.total)#</b></cfoutput></p>

                            <hr/>



                            <h5>2023</h5>

                            <cfquery name="qProvas" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(evt.id_evento) as total
                                FROM tb_evento_corridas evt
                                where evt.ativo = true AND evt.data_final BETWEEN '2023-01-01' and '2023-12-31'
                                <cfif isDefined("URL.estado") AND Len(trim(URL.estado))>
                                    AND evt.estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.estado#"/>
                                </cfif>
                            </cfquery>
                            <p>Provas catalogadas <cfif isDefined("URL.estado") AND Len(trim(URL.estado))><cfoutput> - #URL.estado#</cfoutput><cfelse>no Brasil</cfif>: <cfoutput><b>#lsNumberFormat(qProvas.total)#</b></cfoutput></p>

                            <cfquery name="qProvas" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(evt.id_evento) as total
                                    FROM tb_evento_corridas evt
                                where evt.ativo = true AND evt.pais = 'BR' AND evt.data_final BETWEEN '2023-01-01' and '2023-12-31'
                            </cfquery>
                            <p>Provas catalogadas no Brasil: <cfoutput><b>#lsNumberFormat(qProvas.total)#</b></cfoutput></p>

                            <cfquery name="qProvasResultados" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(distinct res.id_evento) as total
                                    from tb_resultados_resumo res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND evt.pais = 'BR' AND evt.data_final BETWEEN '2023-01-01' and '2023-12-31'
                                <cfif isDefined("URL.estado") AND Len(trim(URL.estado))>
                                    AND evt.estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.estado#"/>
                                </cfif>
                            </cfquery>
                            <p>Provas com resultado coletado <cfif isDefined("URL.estado") AND Len(trim(URL.estado))><cfoutput> - #URL.estado#</cfoutput><cfelse>no Brasil</cfif>: <cfoutput><b>#lsNumberFormat(qProvasResultados.total)#</b></cfoutput></p>

                            <cfquery name="qProvasResultados" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(distinct res.id_evento) as total
                                    from tb_resultados_resumo res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND evt.pais = 'BR' AND evt.data_final BETWEEN '2023-01-01' and '2023-12-31'
                            </cfquery>
                            <p>Provas com resultado coletado no Brasil: <cfoutput><b>#lsNumberFormat(qProvasResultados.total)#</b></cfoutput></p>

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select sum(res.concluintes) as total
                                    from tb_resultados_resumo res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND evt.data_final BETWEEN '2023-01-01' and '2023-12-31'
                                <cfif isDefined("URL.estado") AND Len(trim(URL.estado))>
                                    AND evt.estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.estado#"/>
                                </cfif>
                            </cfquery>
                            <p>Resultados coletados <cfif isDefined("URL.estado") AND Len(trim(URL.estado))><cfoutput> - #URL.estado#</cfoutput><cfelse>no Brasil</cfif>: <cfoutput><b>#lsNumberFormat(qRetorno.total)#</b></cfoutput></p>

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select sum(res.concluintes) as total
                                    from tb_resultados_resumo res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND evt.pais = 'BR' AND evt.data_final BETWEEN '2023-01-01' and '2023-12-31'
                            </cfquery>
                            <p>Resultados coletados no Brasil: <cfoutput><b>#lsNumberFormat(qRetorno.total)#</b></cfoutput></p>

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(DISTINCT res.nome) as total
                                    from tb_resultados res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND evt.pais = 'BR' AND evt.data_final BETWEEN '2023-01-01' and '2023-12-31'
                                <cfif isDefined("URL.estado") AND Len(trim(URL.estado))>
                                    AND evt.estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.estado#"/>
                                </cfif>
                            </cfquery>
                            <p>Corredores <cfif isDefined("URL.estado") AND Len(trim(URL.estado))><cfoutput> - #URL.estado#</cfoutput><cfelse>no Brasil</cfif>: <cfoutput><b>#lsNumberFormat(qRetorno.total)#</b></cfoutput></p>

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(DISTINCT res.nome) as total
                                    from tb_resultados res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND evt.pais = 'BR' AND evt.data_final BETWEEN '2023-01-01' and '2023-12-31'
                            </cfquery>
                            <p>Corredores no Brasil: <cfoutput><b>#lsNumberFormat(qRetorno.total)#</b></cfoutput></p>

                            <hr/>



                            <h5>2022</h5>

                            <cfquery name="qProvas" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(evt.id_evento) as total
                                FROM tb_evento_corridas evt
                                where evt.ativo = true AND evt.data_final BETWEEN '2022-01-01' and '2022-12-31'
                                <cfif isDefined("URL.estado") AND Len(trim(URL.estado))>
                                    AND evt.estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.estado#"/>
                                </cfif>
                            </cfquery>
                            <p>Provas catalogadas <cfif isDefined("URL.estado") AND Len(trim(URL.estado))><cfoutput> - #URL.estado#</cfoutput><cfelse>no Brasil</cfif>: <cfoutput><b>#lsNumberFormat(qProvas.total)#</b></cfoutput></p>

                            <cfquery name="qProvas" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(evt.id_evento) as total
                                    FROM tb_evento_corridas evt
                                where evt.ativo = true AND evt.pais = 'BR' AND evt.data_final BETWEEN '2022-01-01' and '2022-12-31'
                            </cfquery>
                            <p>Provas catalogadas no Brasil: <cfoutput><b>#lsNumberFormat(qProvas.total)#</b></cfoutput></p>

                            <cfquery name="qProvasResultados" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(distinct res.id_evento) as total
                                    from tb_resultados_resumo res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND evt.pais = 'BR' AND evt.data_final BETWEEN '2022-01-01' and '2022-12-31'
                                <cfif isDefined("URL.estado") AND Len(trim(URL.estado))>
                                    AND evt.estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.estado#"/>
                                </cfif>
                            </cfquery>
                            <p>Provas com resultado coletado <cfif isDefined("URL.estado") AND Len(trim(URL.estado))><cfoutput> - #URL.estado#</cfoutput><cfelse>no Brasil</cfif>: <cfoutput><b>#lsNumberFormat(qProvasResultados.total)#</b></cfoutput></p>

                            <cfquery name="qProvasResultados" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(distinct res.id_evento) as total
                                    from tb_resultados_resumo res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND evt.pais = 'BR' AND evt.data_final BETWEEN '2022-01-01' and '2022-12-31'
                            </cfquery>
                            <p>Provas com resultado coletado no Brasil: <cfoutput><b>#lsNumberFormat(qProvasResultados.total)#</b></cfoutput></p>

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select sum(res.concluintes) as total
                                    from tb_resultados_resumo res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND evt.data_final BETWEEN '2022-01-01' and '2022-12-31'
                                <cfif isDefined("URL.estado") AND Len(trim(URL.estado))>
                                    AND evt.estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.estado#"/>
                                </cfif>
                            </cfquery>
                            <p>Resultados coletados <cfif isDefined("URL.estado") AND Len(trim(URL.estado))><cfoutput> - #URL.estado#</cfoutput><cfelse>no Brasil</cfif>: <cfoutput><b>#lsNumberFormat(qRetorno.total)#</b></cfoutput></p>

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select sum(res.concluintes) as total
                                    from tb_resultados_resumo res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND evt.pais = 'BR' AND evt.data_final BETWEEN '2022-01-01' and '2022-12-31'
                            </cfquery>
                            <p>Resultados coletados no Brasil: <cfoutput><b>#lsNumberFormat(qRetorno.total)#</b></cfoutput></p>

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(DISTINCT res.nome) as total
                                    from tb_resultados res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND evt.pais = 'BR' AND evt.data_final BETWEEN '2022-01-01' and '2022-12-31'
                                <cfif isDefined("URL.estado") AND Len(trim(URL.estado))>
                                    AND evt.estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.estado#"/>
                                </cfif>
                            </cfquery>
                            <p>Corredores <cfif isDefined("URL.estado") AND Len(trim(URL.estado))><cfoutput> - #URL.estado#</cfoutput><cfelse>no Brasil</cfif>: <cfoutput><b>#lsNumberFormat(qRetorno.total)#</b></cfoutput></p>

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(DISTINCT res.nome) as total
                                    from tb_resultados res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND evt.pais = 'BR' AND evt.data_final BETWEEN '2022-01-01' and '2022-12-31'
                            </cfquery>
                            <p>Corredores no Brasil: <cfoutput><b>#lsNumberFormat(qRetorno.total)#</b></cfoutput></p>

                        </div>

                    </div>

                </div>

                <div class="col-sm-12 col-md-4 mb-1">

                    <div class="card">

                        <div class="card-header h5 p-3">Números de Maratona</div>

                        <div class="card-body p-3">

                            <cfquery name="qMaratonas" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(evt.id_evento) as total
                                    FROM tb_evento_corridas evt
                                where evt.ativo = true AND evt.categorias ilike '%42%' and evt.tipo_corrida = 'rua'
                                <cfif isDefined("URL.estado") AND Len(trim(URL.estado))>
                                    AND evt.estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.estado#"/>
                                </cfif>
                            </cfquery>
                            <p>Maratonas catalogadas: <cfoutput><b>#lsNumberFormat(qMaratonas.total)#</b></cfoutput></p>

                            <cfquery name="qMaratonas" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(evt.id_evento) as total
                                    FROM tb_evento_corridas evt
                                where evt.ativo = true AND evt.categorias ilike '%42%' and evt.pais = 'BR' and evt.tipo_corrida = 'rua'
                            </cfquery>
                            <p>Maratonas catalogadas no Brasil: <cfoutput><b>#lsNumberFormat(qMaratonas.total)#</b></cfoutput></p>

                            <cfquery name="qMaratonasResultados" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(res.*) as total
                                    from tb_resultados_resumo res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND res.percurso = 42 and evt.pais = 'BR' and evt.tipo_corrida = 'rua'
                            </cfquery>
                            <p>Maratonas com resultado coletado no Brasil: <cfoutput><b>#lsNumberFormat(qMaratonasResultados.total)#</b></cfoutput></p>

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select sum(res.concluintes) as total
                                    from tb_resultados_resumo res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND res.percurso = 42 and evt.pais = 'BR'
                            </cfquery>
                            <p>Resultados de Maratona no Brasil: <cfoutput><b>#lsNumberFormat(qRetorno.total)#</b></cfoutput></p>

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(DISTINCT res.nome) as total
                                    from tb_resultados res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND res.percurso = 42 and evt.pais = 'BR'
                            </cfquery>
                            <p>Maratonistas no Brasil: <cfoutput><b>#lsNumberFormat(qRetorno.total)#</b></cfoutput></p>

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select AVG(tempo_total)::time as total
                                    from tb_resultados res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND percurso = 42 and evt.pais = 'BR'
                            </cfquery>
                            <p>Tempo médio de maratona no Brasil: <cfoutput><b>#lsTimeFormat(qRetorno.total, "hh:mm:ss")#</b></cfoutput></p>

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(res.id_resultado) as total
                                    from tb_resultados res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND percurso = 42 and tempo_total < '03:00:00' and evt.pais = 'BR'
                            </cfquery>
                            <p>Resutados de Maratona Sub3 no Brasil: <cfoutput><b>#lsNumberFormat(qRetorno.total)#</b></cfoutput></p>

                            <hr/>

                            <h5>2024</h5>

                            <cfquery name="qMaratonas" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(evt.id_evento) as total
                                    FROM tb_evento_corridas evt
                                where evt.ativo = true AND evt.categorias ilike '%42%' and evt.data_final BETWEEN '2024-01-01' and '2024-12-31' and evt.tipo_corrida = 'rua'
                            </cfquery>
                            <p>Maratonas catalogadas: <cfoutput><b>#lsNumberFormat(qMaratonas.total)#</b></cfoutput></p>

                            <cfquery name="qMaratonas" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(evt.id_evento) as total
                                    FROM tb_evento_corridas evt
                                where evt.ativo = true AND evt.categorias ilike '%42%' and evt.data_final BETWEEN '2024-01-01' and '2024-12-31' and evt.pais = 'BR' and evt.tipo_corrida = 'rua'
                            </cfquery>
                            <p>Maratonas catalogadas no Brasil: <cfoutput><b>#lsNumberFormat(qMaratonas.total)#</b></cfoutput></p>

                            <cfquery name="qMaratonasResultados" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(res.*) as total
                                    from tb_resultados_resumo res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND res.percurso = 42 and evt.data_final BETWEEN '2024-01-01' and '2024-12-31' and evt.pais = 'BR' and evt.tipo_corrida = 'rua'
                            </cfquery>
                            <p>Maratonas com resultado coletado no Brasil: <cfoutput><b>#lsNumberFormat(qMaratonasResultados.total)#</b></cfoutput></p>

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(res.id_resultado) as total
                                    from tb_resultados res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND res.percurso = 42 and evt.data_final BETWEEN '2024-01-01' and '2024-12-31' and evt.pais = 'BR'
                            </cfquery>
                            <p>Resultados de Maratona no Brasil: <cfoutput><b>#lsNumberFormat(qRetorno.total)#</b></cfoutput></p>

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(DISTINCT res.nome) as total
                                    from tb_resultados res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND res.percurso = 42 and evt.data_final BETWEEN '2024-01-01' and '2024-12-31' and evt.pais = 'BR'
                            </cfquery>
                            <p>Maratonistas no Brasil: <cfoutput><b>#lsNumberFormat(qRetorno.total)#</b></cfoutput></p>

                            <hr/>

                            <h5>2023</h5>

                            <cfquery name="qMaratonas" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(evt.id_evento) as total
                                    FROM tb_evento_corridas evt
                                where evt.ativo = true AND evt.categorias ilike '%42%' and evt.data_final BETWEEN '2023-01-01' and '2023-12-31' and evt.tipo_corrida = 'rua'
                            </cfquery>
                            <p>Maratonas catalogadas: <cfoutput><b>#lsNumberFormat(qMaratonas.total)#</b></cfoutput></p>

                            <cfquery name="qMaratonas" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(evt.id_evento) as total
                                    FROM tb_evento_corridas evt
                                where evt.ativo = true AND evt.categorias ilike '%42%' and evt.data_final BETWEEN '2023-01-01' and '2023-12-31' and evt.pais = 'BR' and evt.tipo_corrida = 'rua'
                            </cfquery>
                            <p>Maratonas catalogadas no Brasil: <cfoutput><b>#lsNumberFormat(qMaratonas.total)#</b></cfoutput></p>

                            <cfquery name="qMaratonasResultados" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(res.*) as total
                                    from tb_resultados_resumo res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND res.percurso = 42 and evt.data_final BETWEEN '2023-01-01' and '2023-12-31' and evt.pais = 'BR' and evt.tipo_corrida = 'rua'
                            </cfquery>
                            <p>Maratonas com resultado coletado no Brasil: <cfoutput><b>#lsNumberFormat(qMaratonasResultados.total)#</b></cfoutput></p>

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(res.id_resultado) as total
                                    from tb_resultados res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND res.percurso = 42 and evt.data_final BETWEEN '2023-01-01' and '2023-12-31' and evt.pais = 'BR'
                            </cfquery>
                            <p>Resultados de Maratona no Brasil: <cfoutput><b>#lsNumberFormat(qRetorno.total)#</b></cfoutput></p>

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(DISTINCT res.nome) as total
                                    from tb_resultados res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND res.percurso = 42 and evt.data_final BETWEEN '2023-01-01' and '2023-12-31' and evt.pais = 'BR'
                            </cfquery>
                            <p>Maratonistas no Brasil: <cfoutput><b>#lsNumberFormat(qRetorno.total)#</b></cfoutput></p>

                            <hr/>

                            <h5>2022</h5>

                            <cfquery name="qMaratonas" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(evt.id_evento) as total
                                    FROM tb_evento_corridas evt
                                where evt.ativo = true AND evt.categorias ilike '%42%' and evt.data_final BETWEEN '2022-01-01' and '2022-12-31' and evt.tipo_corrida = 'rua'
                            </cfquery>
                            <p>Maratonas catalogadas no Brasil: <cfoutput><b>#lsNumberFormat(qMaratonas.total)#</b></cfoutput></p>

                            <cfquery name="qMaratonas" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(evt.id_evento) as total
                                    FROM tb_evento_corridas evt
                                where evt.ativo = true AND evt.categorias ilike '%42%' and evt.data_final BETWEEN '2022-01-01' and '2022-12-31' and evt.pais = 'BR' and evt.tipo_corrida = 'rua'
                            </cfquery>
                            <p>Maratonas catalogadas no Brasil: <cfoutput><b>#lsNumberFormat(qMaratonas.total)#</b></cfoutput></p>

                            <cfquery name="qMaratonasResultados" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(res.*) as total
                                    from tb_resultados_resumo res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND res.percurso = 42 and evt.data_final BETWEEN '2022-01-01' and '2022-12-31' and evt.pais = 'BR' and evt.tipo_corrida = 'rua'
                            </cfquery>
                            <p>Maratonas com resultado coletado no Brasil: <cfoutput><b>#lsNumberFormat(qMaratonasResultados.total)#</b></cfoutput></p>

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(res.id_resultado) as total
                                    from tb_resultados res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND res.percurso = 42 and evt.data_final BETWEEN '2022-01-01' and '2022-12-31' and evt.pais = 'BR'
                            </cfquery>
                            <p>Resultados de Maratona no Brasil: <cfoutput><b>#lsNumberFormat(qRetorno.total)#</b></cfoutput></p>

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(DISTINCT res.nome) as total
                                    from tb_resultados res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where evt.ativo = true AND res.percurso = 42 and evt.data_final BETWEEN '2022-01-01' and '2022-12-31' and evt.pais = 'BR'
                            </cfquery>
                            <p>Maratonistas no Brasil: <cfoutput><b>#lsNumberFormat(qRetorno.total)#</b></cfoutput></p>

                        </div>

                    </div>

                </div>

                <!---div class="col-sm-12 col-md-4 mb-1">

                    <div class="card">

                        <div class="card-header h5 p-3">Números de 21K</div>

                        <div class="card-body p-3">

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select sum(res.concluintes) as total
                                    from tb_resultados_resumo res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where res.percurso = 21 and evt.pais = 'BR'
                            </cfquery>
                            <p>Resultados de 21k no Brasil: <cfoutput><b>#lsNumberFormat(qRetorno.total)#</b></cfoutput></p>

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(DISTINCT res.nome) as total
                                    from tb_resultados res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where res.percurso = 21 and evt.pais = 'BR'
                            </cfquery>
                            <p>Meio-Maratonistas no Brasil: <cfoutput><b>#lsNumberFormat(qRetorno.total)#</b></cfoutput></p>

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select AVG(tempo_total)::time as total
                                    from tb_resultados res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where percurso = 21 and evt.pais = 'BR'
                            </cfquery>
                            <p>Tempo médio de 21k no Brasil: <cfoutput><b>#lsTimeFormat(qRetorno.total, "hh:mm:ss")#</b></cfoutput></p>

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(res.id_resultado) as total
                                    from tb_resultados res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where percurso = 21 and tempo_total < '01:30:00' and evt.pais = 'BR'
                            </cfquery>
                            <p>Resutados de 21k Sub1.5 no Brasil: <cfoutput><b>#lsNumberFormat(qRetorno.total)#</b></cfoutput></p>

                            <hr/>

                            <h5>2024</h5>

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(res.id_resultado) as total
                                    from tb_resultados res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where res.percurso = 21 and evt.data_final BETWEEN '2024-01-01' and '2024-12-31' and evt.pais = 'BR'
                            </cfquery>
                            <p>Resultados de 21k no Brasil: <cfoutput><b>#lsNumberFormat(qRetorno.total)#</b></cfoutput></p>

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(DISTINCT res.nome) as total
                                    from tb_resultados res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where res.percurso = 21 and evt.data_final BETWEEN '2024-01-01' and '2024-12-31' and evt.pais = 'BR'
                            </cfquery>
                            <p>Meio-Maratonistas no Brasil: <cfoutput><b>#lsNumberFormat(qRetorno.total)#</b></cfoutput></p>

                            <hr/>

                            <h5>2023</h5>

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(res.id_resultado) as total
                                    from tb_resultados res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where res.percurso = 21 and evt.data_final BETWEEN '2023-01-01' and '2023-12-31' and evt.pais = 'BR'
                            </cfquery>
                            <p>Resultados de 21k no Brasil: <cfoutput><b>#lsNumberFormat(qRetorno.total)#</b></cfoutput></p>

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(DISTINCT res.nome) as total
                                    from tb_resultados res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where res.percurso = 21 and evt.data_final BETWEEN '2023-01-01' and '2023-12-31' and evt.pais = 'BR'
                            </cfquery>
                            <p>Meio-Maratonistas no Brasil: <cfoutput><b>#lsNumberFormat(qRetorno.total)#</b></cfoutput></p>

                            <hr/>

                            <h5>2022</h5>

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(res.id_resultado) as total
                                    from tb_resultados res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where res.percurso = 21 and evt.data_final BETWEEN '2022-01-01' and '2022-12-31' and evt.pais = 'BR'
                            </cfquery>
                            <p>Resultados de 21k no Brasil: <cfoutput><b>#lsNumberFormat(qRetorno.total)#</b></cfoutput></p>

                            <cfquery name="qRetorno" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                                select count(DISTINCT res.nome) as total
                                    from tb_resultados res inner join public.tb_evento_corridas evt on evt.id_evento = res.id_evento
                                where res.percurso = 21 and evt.data_final BETWEEN '2022-01-01' and '2022-12-31' and evt.pais = 'BR'
                            </cfquery>
                            <p>Meio-Maratonistas no Brasil: <cfoutput><b>#lsNumberFormat(qRetorno.total)#</b></cfoutput></p>

                        </div>

                    </div>

                </div--->

            </div>

        </div>

    </cfif>

    <cfinclude template="../includes/footer_parceiro.cfm"/>

    <cfinclude template="../includes/seo-web-tools-body-end.cfm"/>

</body>

</html>
