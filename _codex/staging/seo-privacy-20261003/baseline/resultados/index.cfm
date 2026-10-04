<!doctype html>
<html lang="pt-br">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- TEMPLATE --->
<cfset VARIABLES.template = "/resultados/"/>

<!--- TAG PARAM TREAT --->
<cfparam name="URL.tag" default=""/>
<cfset URL.tag = trim(replace(URL.tag, '/', ''))/>

<!--- BACKEND --->
<cfinclude template="../includes/variaveis.cfm"/>
<cfinclude template="../includes/backend.cfm"/>

<!--- META INFO --->
<cfset VARIABLES.canonical = "#APPLICATION.baseCanonica##VARIABLES.template##URL.tag##Len(trim(URL.tag)) ? '/' : ''##VARIABLES.queryString#"/>
<cfset VARIABLES.title = "Resultados do Participante - #APPLICATION.nomeSite#"/>
<cfset VARIABLES.description = "Power Ups"/>
<cfset VARIABLES.keywords = "resultados, corrida, competição, pódio, atletas, corredores"/>

<!--- HEAD --->
<cfinclude template="../includes/head.cfm"/>

<cfquery name="qCorridasAtleta">
    select id_resultado, id_usuario, num_peito, UPPER(nome) as nome, nome_categoria, res.id_evento, evt.nome_evento, evt.cidade, evt.estado, evt.tag, evt.data_final, modalidade, pace, percurso, equipe,
    sexo, tempo_bruto, tempo_total, classificacao_categoria, classificacao_sexo, status_final
    from tb_resultados res
    INNER JOIN tb_evento_corridas evt ON evt.id_evento = res.id_evento
    WHERE nome = <cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(replace(URL.tag, '-', ' ', 'ALL'))#"/>
    AND concluinte = true
    AND res.origem_resultado <> 'validacao_documental'
    ORDER BY evt.data_final DESC
    LIMIT 200
</cfquery>

<cfif qCorridasAtleta.recordcount>
    <cfset VARIABLES.nomeAtleta = qCorridasAtleta.nome/>
<cfelse>
    <cfset VARIABLES.nomeAtleta = uCase(replace(URL.tag, '-', ' ', 'ALL'))/>
</cfif>

<body>

    <!--- SEO WEB TOOLS --->

    <cfinclude template="../includes/seo-web-tools-body-start.cfm"/>


    <div class="container">


            <!--- HEADER --->

            <cfinclude template="../includes/header.cfm"/>


            <!--- ATLETA --->

            <section class="pt-3">
                <article class="or-event-card or-athlete-profile-card">
                    <div class="or-event-card-body">
                        <div class="d-flex flex-column flex-lg-row justify-content-between gap-3">
                            <div>
                                <small class="text-gray-light d-inline-flex align-items-center gap-2 mb-1">
                                    <i class="fa-solid fa-person-running"></i>
                                    Atleta
                                </small>
                                <h1 class="h3 fw-bold mb-1"><cfoutput>#htmlEditFormat(VARIABLES.nomeAtleta)#</cfoutput></h1>
                                <p class="text-gray-light mb-0">
                                    <cfoutput>#lsNumberFormat(qCorridasAtleta.recordcount)# participações em eventos de corrida</cfoutput>
                                </p>
                            </div>
                            <div class="or-athlete-profile-actions">
                                <cfoutput>
                                    <a href="/busca/?termo=#urlEncodedFormat(VARIABLES.nomeAtleta)#&aba=atletas" class="or-event-distance or-athlete-profile-action">
                                        <i class="fa-solid fa-magnifying-glass"></i>
                                        Buscar mais resultados
                                    </a>
                                </cfoutput>
                                <cfif qCorridasAtleta.recordcount>
                                    <div class="or-history-prompt">
                                        <cfmodule template="../includes/salvar_historico.cfm" nome="#VARIABLES.nomeAtleta#" destaque="true" origem="salvar_pagina_atleta"/>
                                        <small class="or-history-help">Seu histórico no Road Runners.</small>
                                    </div>
                                </cfif>
                            </div>
                        </div>
                    </div>
                </article>
            </section>


            <!--- INDICES

            <div class="row g-3">

                <cfquery name="qPace" dbtype="query">
                    SELECT MIN(pace) as pace FROM qCorridasAtleta
                </cfquery>

                <div class="col-6 col-md-3 col-lg-2Melhor">
                    <div class="card text-center">
                        <div class="card-header">MELHOR PACE</div>
                        <div class="card-body"><cfoutput>#timeFormat(qPace.pace,"mm:ss")#</cfoutput></div>
                    </div>
                </div>

                <cfquery name="q42k" dbtype="query">
                    SELECT MIN(tempo_total) as tempo_total FROM qCorridasAtleta
                    WHERE cast(percurso as integer) = 42
                </cfquery>

                <cfif q42k.recordcount>
                <div class="col-6 col-md-3 col-lg-2Melhor">
                    <div class="card text-center">
                        <div class="card-header bg-42k">TEMPO 42K</div>
                        <div class="card-body"><cfoutput>#timeFormat(q42k.tempo_total,"HH:mm:ss")#</cfoutput></div>
                    </div>
                </div>
                </cfif>

                <cfquery name="q21k" dbtype="query">
                    SELECT MIN(tempo_total) as tempo_total FROM qCorridasAtleta
                    WHERE cast(percurso as integer) = 21
                </cfquery>

                <cfif q21k.recordcount>
                    <div class="col-6 col-md-3 col-lg-2Melhor">
                        <div class="card text-center">
                            <div class="card-header bg-21k">TEMPO 21K</div>
                            <div class="card-body"><cfoutput>#timeFormat(q21k.tempo_total,"HH:mm:ss")#</cfoutput></div>
                        </div>
                    </div>
                </cfif>

                <cfquery name="q10k" dbtype="query">
                        SELECT MIN(tempo_total) as tempo_total FROM qCorridasAtleta
                        WHERE cast(percurso as integer) = 10
                </cfquery>

                <cfif q10k.recordcount>
                    <div class="col-6 col-md-3 col-lg-2Melhor">
                        <div class="card text-center">
                            <div class="card-header bg-10k">TEMPO 10K</div>
                            <div class="card-body"><cfoutput>#timeFormat(q10k.tempo_total,"HH:mm:ss")#</cfoutput></div>
                        </div>
                    </div>
                </cfif>

                <cfquery name="q5k" dbtype="query">
                    SELECT MIN(tempo_total) as tempo_total FROM qCorridasAtleta
                    WHERE cast(percurso as integer) = 5
                </cfquery>

                <cfif q5k.recordcount>
                    <div class="col-6 col-md-3 col-lg-2Melhor">
                        <div class="card text-center">
                            <div class="card-header bg-5k">TEMPO 5K</div>
                            <div class="card-body"><cfoutput>#timeFormat(q5k.tempo_total,"HH:mm:ss")#</cfoutput></div>
                        </div>
                    </div>
                </cfif>

                <cfquery name="qPosGeral" dbtype="query">
                    SELECT MIN(classificacao_sexo) as classificacao_sexo FROM qCorridasAtleta
                </cfquery>

                <cfif qPosGeral.recordcount>
                    <div class="col-6 col-md-3 col-lg-2Melhor">
                        <div class="card text-center">
                            <div class="card-header">NO GERAL</div>
                            <div class="card-body"><cfoutput>#qPosGeral.classificacao_sexo#º</cfoutput></div>
                        </div>
                    </div>
                </cfif>

                <cfquery name="qPosCat" dbtype="query">
                    SELECT MIN(classificacao_categoria) as classificacao_categoria FROM qCorridasAtleta
                </cfquery>

                <cfif qPosCat.recordcount>
                    <div class="col-6 col-md-3 col-lg-2Melhor">
                        <div class="card text-center">
                            <div class="card-header">NA CATEGORIA</div>
                            <div class="card-body"><cfoutput>#qPosCat.classificacao_categoria#º</cfoutput></div>
                        </div>
                    </div>
                </cfif>

            </div>

             --->


            <!--- RESULTADOS --->

            <div class="d-flex justify-content-between align-items-center flex-wrap gap-2 mt-4 mb-2">
                <h2 class="h5 fw-bold mb-0">Participações em eventos</h2>
            </div>

            <cfif qCorridasAtleta.recordcount>

            <cfloop query="qCorridasAtleta">

                <cfoutput>
                    <article class="or-athlete-result-card mb-2">
                        <div class="or-event-card-top">
                            <div class="or-event-card-date">
                                <span class="day">#lsDateFormat(qCorridasAtleta.data_final,"dd")#</span>
                                <span class="month">#lsDateFormat(qCorridasAtleta.data_final,"mmm")#</span>
                                <span class="year">#lsDateFormat(qCorridasAtleta.data_final,"yyyy")#</span>
                            </div>

                            <div class="w-100">
                                <div class="d-flex flex-column flex-lg-row justify-content-between gap-2">
                                    <div>
                                        <h3 class="or-event-card-title mb-1">
                                            <a href="/evento/#qCorridasAtleta.tag#/">#qCorridasAtleta.nome_evento#</a>
                                        </h3>
                                        <div class="or-event-card-meta">
                                            <span><i class="fa-solid fa-calendar-day me-1"></i>#lsDateFormat(qCorridasAtleta.data_final, "dd/mm/yyyy")#</span>
                                            <span class="d-inline-block ms-sm-2"><i class="fa-solid fa-location-dot me-1"></i>#qCorridasAtleta.cidade#<cfif Len(trim(qCorridasAtleta.estado))>/#qCorridasAtleta.estado#</cfif></span>
                                        </div>
                                    </div>
                                    <div class="d-flex flex-wrap align-items-center justify-content-lg-end gap-2">
                                        <a href="https://roadrunners.run/evento/#qCorridasAtleta.tag#?utm_source=openresults&amp;utm_medium=referral&amp;utm_campaign=openresults_to_roadrunners&amp;utm_content=detalhes_evento_perfil_atleta" target="_blank" class="or-athlete-event-link" data-rr-placement="detalhes_evento_perfil_atleta">
                                            <img title="Ver detalhes do evento" src="/assets/rr_logo_square.jpg" class="rounded" alt="Road Runners">
                                            <small>Sobre o evento</small>
                                        </a>
                                        <cfmodule template="../includes/salvar_historico.cfm" nome="#qCorridasAtleta.nome#" id_resultado="#qCorridasAtleta.id_resultado#" origem="salvar_card_participacao" rotulo="Salvar resultado" evento="#qCorridasAtleta.nome_evento#"/>
                                    </div>
                                </div>

                                <div class="or-event-card-distances">
                                    <a class="or-event-distance" href="/evento/#qCorridasAtleta.tag#/?modalidade=#qCorridasAtleta.modalidade#&genero=#qCorridasAtleta.sexo####lcase(replace(qCorridasAtleta.nome, ' ', '-', 'ALL'))#">
                                        <i class="fa-solid fa-person-running"></i>
                                        #qCorridasAtleta.modalidade# #(qCorridasAtleta.sexo EQ "M") ? "Masculino" : "Feminino"#
                                    </a>
                                    <a class="or-event-distance" href="/evento/#qCorridasAtleta.tag#/?modalidade=#qCorridasAtleta.modalidade#&genero=#qCorridasAtleta.sexo#&categoria=#qCorridasAtleta.nome_categoria####lcase(replace(qCorridasAtleta.nome, ' ', '-', 'ALL'))#">
                                        <i class="fa-solid fa-layer-group"></i>
                                        #qCorridasAtleta.nome_categoria#
                                    </a>
                                    <span class="or-event-distance">
                                        <i class="fa-solid fa-route"></i>
                                        #qCorridasAtleta.percurso#k
                                    </span>
                                    <span class="or-event-distance">
                                        <i class="fa-solid fa-shirt"></i>
                                        BIB #qCorridasAtleta.num_peito#
                                    </span>
                                </div>

                                <div class="or-athlete-result-stats">
                                    <div class="or-athlete-result-stat">
                                        <small>Pos. categoria</small>
                                        <strong class="mono">#qCorridasAtleta.classificacao_categoria#º</strong>
                                    </div>
                                    <div class="or-athlete-result-stat">
                                        <small>Pos. geral</small>
                                        <strong class="mono">#qCorridasAtleta.classificacao_sexo#º</strong>
                                    </div>
                                    <div class="or-athlete-result-stat">
                                        <small>Pace</small>
                                        <strong class="mono">#timeFormat(qCorridasAtleta.pace,"mm:ss")#</strong>
                                    </div>
                                    <div class="or-athlete-result-stat">
                                        <small>Líquido</small>
                                        <strong class="mono">
                                            <cfif qCorridasAtleta.status_final EQ 2>
                                                DESCLASSIFICADO
                                            <cfelseif qCorridasAtleta.status_final EQ 1>
                                                DNF
                                            <cfelse>
                                                #timeFormat(qCorridasAtleta.tempo_total,"HH:mm:ss")#
                                            </cfif>
                                        </strong>
                                    </div>
                                    <div class="or-athlete-result-stat or-athlete-result-stat-wide">
                                        <small>Equipe</small>
                                        <strong class="mono">
                                            <cfif len(trim(qCorridasAtleta.equipe))>
                                                <a href="/evento/#qCorridasAtleta.tag#/?modalidade=#qCorridasAtleta.modalidade#&genero=#qCorridasAtleta.sexo#&equipe=#qCorridasAtleta.equipe#">#qCorridasAtleta.equipe#</a>
                                            <cfelse>
                                                ---
                                            </cfif>
                                        </strong>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </article>
                </cfoutput>

            </cfloop>

            <cfelse>
                <article class="or-event-card mb-3">
                    <div class="or-event-card-body">
                        <p class="text-gray-light mb-0">Nenhuma participação encontrada para este atleta.</p>
                    </div>
                </article>
            </cfif>

            <cfif qCorridasAtleta.recordcount>
                <article class="or-event-card my-4">
                    <div class="or-event-card-body">
                        <h2 class="h5 fw-bold mb-3">Gráfico de pace</h2>
                        <div class="or-athlete-chart">
                            <canvas id="myChart"></canvas>
                        </div>
                    </div>
                </article>
            </cfif>

            <cfif qCorridasAtleta.recordcount>
            <script>
            const ctx = document.getElementById('myChart');

            new Chart(ctx, {
                type: 'line',
                data: {
                labels: [<cfloop query="qCorridasAtleta">'<cfoutput>#timeFormat(qCorridasAtleta.pace,"mm:ss")#',</cfoutput></cfloop>],
                    datasets: [{
                        label: 'PACE',
                        data: [<cfloop query="qCorridasAtleta"><cfoutput>#timeFormat(qCorridasAtleta.pace,"m.ss")#,</cfoutput></cfloop>],
                        borderColor: '#FAB120',
                        backgroundColor: 'rgba(250, 177, 32, 0.12)',
                        pointBackgroundColor: '#FAB120',
                        pointBorderColor: '#FAB120',
                        borderWidth: 2
                    }]
                },
                options: {
                    responsive: true,
                    legend: false,
                    maintainAspectRatio: false,
                    resizeDelay: 150,
                    scales: {
                        y: {
                            beginAtZero: true
                        }
                    }
                }
            });
        </script>
        </cfif>

        </div>


    <!--- FOOTER --->

    <cfinclude template="../includes/footer.cfm"/>


    <!--- SEO WEB TOOLS --->

    <cfinclude template="../includes/seo-web-tools-body-end.cfm"/>

</body>

</html>
