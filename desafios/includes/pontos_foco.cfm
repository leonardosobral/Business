<cfprocessingdirective pageencoding="utf-8"/>
<cfif NOT isDefined("VARIABLES.requireAdminAllowed") OR NOT VARIABLES.requireAdminAllowed>
    <cfheader statuscode="403"/>
    <cfabort/>
</cfif>

<cfparam name="URL.motivo" default=""/>
<cfparam name="URL.atleta" default="0"/>
<cfparam name="URL.busca_pontos" default=""/>
<cfparam name="URL.pagina_pontos" default="1"/>

<cfset VARIABLES.focoPointLabels = {
    fila = "Em fila",
    revisao_408 = "Em revisão · HTTP 408",
    revisao_outros = "Outras revisões",
    rejeitado_404 = "Rejeitado · HTTP 404",
    rejeitado_outros = "Outras rejeições",
    sem_envio = "Sem envio registrado",
    confirmado = "Confirmado"
}/>
<cfset VARIABLES.focoPendingReasons = ["fila", "revisao_408", "revisao_outros", "rejeitado_404", "rejeitado_outros", "sem_envio"]/>
<cfset URL.motivo = lcase(trim(URL.motivo))/>
<cfif NOT arrayFind(VARIABLES.focoPendingReasons, URL.motivo)><cfset URL.motivo = ""/></cfif>
<cfset URL.atleta = reFind("^[0-9]{1,10}$", URL.atleta) AND val(URL.atleta) LTE 2147483647 ? val(URL.atleta) : 0/>
<cfset URL.busca_pontos = left(trim(URL.busca_pontos), 100)/>
<cfset URL.pagina_pontos = reFind("^[0-9]{1,6}$", URL.pagina_pontos) ? max(1, val(URL.pagina_pontos)) : 1/>
<cfinclude template="pontos_foco_backend.cfm"/>

<cfset VARIABLES.focoPendingCounts = {}/>
<cfset VARIABLES.focoPendingTotal = 0/>
<cfloop query="qFocoPendenciasTotais">
    <cfset VARIABLES.focoPendingCounts[qFocoPendenciasTotais.motivo] = qFocoPendenciasTotais.total/>
    <cfset VARIABLES.focoPendingTotal += qFocoPendenciasTotais.total/>
</cfloop>
<cfset VARIABLES.focoPendingMatching = len(URL.motivo) ? (VARIABLES.focoPendingCounts[URL.motivo] ?: 0) : VARIABLES.focoPendingTotal/>
<cfset VARIABLES.focoPendingLastPage = max(1, ceiling(VARIABLES.focoPendingMatching / VARIABLES.focoPointPageSize))/>
<cfset VARIABLES.focoPointUrl = "/desafios/foco/?tela=pontos"/>
<cfset VARIABLES.focoPendingUrl = VARIABLES.focoPointUrl & (len(URL.motivo) ? "&amp;motivo=" & URL.motivo : "")/>

<cfquery name="qFocoPointStatus" timeout="8">
    SELECT count(*) FILTER (WHERE status = 'sent' AND delivered_at IS NOT NULL AND last_http_status BETWEEN 200 AND 299) AS confirmados,
           coalesce(to_char(max(delivered_at) FILTER (WHERE status = 'sent' AND last_http_status BETWEEN 200 AND 299)
               AT TIME ZONE 'America/Sao_Paulo', 'DD/MM/YYYY "às" HH24:MI'), '') AS ultima_confirmacao
    FROM public.tb_strava_foco_points
</cfquery>

<cfquery name="qFocoPointsByDay" timeout="8">
    WITH calendario AS (
        SELECT (now() AT TIME ZONE 'America/Sao_Paulo')::date AS hoje
    ), entregas AS (
        SELECT (ponto.delivered_at AT TIME ZONE 'America/Sao_Paulo')::date AS dia, count(*) AS total
        FROM public.tb_strava_foco_points ponto
        CROSS JOIN calendario
        WHERE ponto.status = 'sent' AND ponto.last_http_status BETWEEN 200 AND 299
          AND ponto.delivered_at >= ((calendario.hoje - 29)::timestamp AT TIME ZONE 'America/Sao_Paulo')
          AND ponto.delivered_at < ((calendario.hoje + 1)::timestamp AT TIME ZONE 'America/Sao_Paulo')
        GROUP BY (ponto.delivered_at AT TIME ZONE 'America/Sao_Paulo')::date
    )
    SELECT to_char(calendario.hoje - dias.indice, 'DD/MM/YYYY') AS dia,
           coalesce(entregas.total, 0) AS confirmados,
           greatest(max(coalesce(entregas.total, 0)) OVER (), 1) AS maior_total
    FROM calendario
    CROSS JOIN generate_series(0, 29) AS dias(indice)
    LEFT JOIN entregas ON entregas.dia = calendario.hoje - dias.indice
    ORDER BY dias.indice
</cfquery>

<section aria-labelledby="foco-points-heading">
    <h2 class="h5 mb-2" id="foco-points-heading">Pontos na Foco Radical</h2>
    <div class="row g-2 mb-2">
        <cfoutput>
            <div class="col-6">
                <div class="card h-100 px-3 py-2">
                    <p class="small mb-1">Pontos confirmados</p>
                    <p class="h4 mb-0">#lsNumberFormat(qFocoPointStatus.confirmados, '9,999', 'Portuguese (Brazilian)')#</p>
                </div>
            </div>
            <div class="col-6">
                <div class="card h-100 px-3 py-2">
                    <p class="small mb-1">Última confirmação</p>
                    <cfif len(qFocoPointStatus.ultima_confirmacao)>
                        <p class="fw-semibold mb-0">#encodeForHTML(qFocoPointStatus.ultima_confirmacao)#</p>
                        <p class="small text-body-secondary mb-0">Horário de Brasília</p>
                    <cfelse>
                        <p class="small text-body-secondary mb-0">Aguardando a primeira confirmação</p>
                    </cfif>
                </div>
            </div>
        </cfoutput>
    </div>

    <cfinclude template="pontos_foco_historico.cfm"/>

    <cfif NOT URL.atleta AND NOT len(URL.busca_pontos)>
        <section class="card mb-2" id="foco-point-pending" aria-labelledby="foco-pending-heading" style="scroll-margin-top: 6rem">
            <div class="card-header px-3 py-2 d-flex flex-wrap align-items-center justify-content-between gap-2">
                <h3 class="fs-6 mb-0" id="foco-pending-heading">Pendências por motivo</h3>
                <cfif len(URL.motivo)>
                    <a class="btn btn-sm btn-outline-secondary" href="/desafios/foco/?tela=pontos#foco-point-pending">Ver todas as pendências</a>
                </cfif>
            </div>
            <div class="card-body p-3">
                <nav class="row g-2 mb-3" aria-label="Filtrar pendências por motivo">
                    <cfoutput>
                        <cfloop array="#VARIABLES.focoPendingReasons#" item="reason">
                            <div class="col-6 col-md-4 col-xl-2">
                                <cfif reason EQ "sem_envio" AND NOT VARIABLES.focoGapEnabled>
                                    <div class="border rounded h-100 p-2">
                                        <span class="d-block small fw-semibold">#VARIABLES.focoPointLabels[reason]#</span>
                                        <span class="small text-body-secondary">Data de início indisponível</span>
                                    </div>
                                <cfelse>
                                    <a class="d-block text-reset rounded border p-2 h-100<cfif URL.motivo EQ reason> border-warning</cfif>"
                                        href="#VARIABLES.focoPointUrl#&amp;motivo=#reason###foco-point-pending"<cfif URL.motivo EQ reason> aria-current="page"</cfif>>
                                        <span class="d-block small fw-semibold">#VARIABLES.focoPointLabels[reason]#</span>
                                        <span class="h5 d-block mb-0">#lsNumberFormat(VARIABLES.focoPendingCounts[reason] ?: 0, '9,999', 'Portuguese (Brazilian)')#</span>
                                    </a>
                                </cfif>
                            </div>
                        </cfloop>
                    </cfoutput>
                </nav>

                <p class="small text-body-secondary mb-2">Cada linha corresponde a um dia de atividade. A verificação de dias sem envio cobre os últimos 30 dias.</p>

                <cfif qFocoPendenciasLista.recordCount>
                    <div class="table-responsive" role="region" tabindex="0" aria-labelledby="foco-pending-heading">
                        <table class="table table-sm align-middle mb-0">
                            <thead>
                                <tr>
                                    <th scope="col">Atleta</th>
                                    <th scope="col">Data da atividade</th>
                                    <th scope="col">Motivo</th>
                                    <th scope="col">Última tentativa</th>
                                    <th scope="col">Retorno</th>
                                    <th scope="col" class="text-end">Tentativas</th>
                                </tr>
                            </thead>
                            <tbody>
                                <cfoutput query="qFocoPendenciasLista">
                                    <tr>
                                        <th scope="row">
                                            <a href="#VARIABLES.focoPendingUrl#&amp;atleta=#val(qFocoPendenciasLista.id_usuario)###foco-point-history" class="text-reset text-decoration-underline">#encodeForHTML(qFocoPendenciasLista.nome ?: ('Atleta ' & qFocoPendenciasLista.id_usuario))#</a>
                                            <span class="d-block small text-body-secondary">ID #val(qFocoPendenciasLista.id_usuario)#</span>
                                        </th>
                                        <td class="text-nowrap">#encodeForHTML(qFocoPendenciasLista.data_atividade)#</td>
                                        <td>#encodeForHTML(VARIABLES.focoPointLabels[qFocoPendenciasLista.motivo])#</td>
                                        <td>#encodeForHTML(qFocoPendenciasLista.ultima_tentativa ?: '—')#</td>
                                        <td class="text-nowrap">
                                            <cfif val(qFocoPendenciasLista.retorno_http ?: 0) GT 0>
                                                HTTP #val(qFocoPendenciasLista.retorno_http)#
                                            <cfelseif val(qFocoPendenciasLista.tentativas) GT 0>
                                                Sem resposta
                                            <cfelse>
                                                —
                                            </cfif>
                                        </td>
                                        <td class="text-end">#val(qFocoPendenciasLista.tentativas)#</td>
                                    </tr>
                                </cfoutput>
                            </tbody>
                        </table>
                    </div>
                <cfelseif NOT VARIABLES.focoPendingMatching>
                    <p class="mb-0">Nenhuma pendência neste filtro.</p>
                <cfelse>
                    <p class="mb-0">Nenhuma pendência nesta página.</p>
                </cfif>

                <cfif VARIABLES.focoPendingLastPage GT 1 OR URL.pagina_pontos GT 1>
                    <nav class="d-flex flex-wrap gap-2 align-items-center mt-3" aria-label="Paginação das pendências">
                        <cfoutput>
                            <cfif URL.pagina_pontos GT 1>
                                <a class="btn btn-sm btn-outline-secondary" href="#VARIABLES.focoPendingUrl#&amp;pagina_pontos=#min(URL.pagina_pontos - 1, VARIABLES.focoPendingLastPage)###foco-point-pending">Anterior</a>
                            </cfif>
                            <span class="small">Página #URL.pagina_pontos# de #VARIABLES.focoPendingLastPage#</span>
                            <cfif URL.pagina_pontos LT VARIABLES.focoPendingLastPage>
                                <a class="btn btn-sm btn-outline-secondary" href="#VARIABLES.focoPendingUrl#&amp;pagina_pontos=#URL.pagina_pontos + 1###foco-point-pending">Próxima</a>
                            </cfif>
                        </cfoutput>
                    </nav>
                </cfif>
            </div>
        </section>
    </cfif>

    <section class="card mb-2" aria-labelledby="foco-point-deliveries-heading">
        <h3 class="card-header px-3 py-2 fs-6 mb-0" id="foco-point-deliveries-heading">Pontos confirmados por dia</h3>
        <div class="card-body p-3">
            <p class="small mb-2">Últimos 30 dias pelo horário da confirmação em Brasília.</p>
            <div class="table-responsive" style="max-height: 22rem" role="region" tabindex="0" aria-labelledby="foco-point-deliveries-heading">
                <table class="table table-sm align-middle mb-0">
                    <thead class="sticky-top bg-body-tertiary">
                        <tr>
                            <th scope="col" class="text-nowrap">Data</th>
                            <td aria-hidden="true"></td>
                            <th scope="col" class="text-end">Pontos confirmados</th>
                        </tr>
                    </thead>
                    <tbody>
                        <cfoutput query="qFocoPointsByDay">
                            <tr>
                                <th scope="row" class="text-nowrap">#encodeForHTML(qFocoPointsByDay.dia)#</th>
                                <td class="w-100" aria-hidden="true">
                                    <div class="rounded bg-body-secondary" style="height: .5rem">
                                        <div class="h-100 rounded" style="width: #int(100 * qFocoPointsByDay.confirmados / qFocoPointsByDay.maior_total)#%; background-color: var(--business-accent, ##f4b120)"></div>
                                    </div>
                                </td>
                                <td class="text-end">#lsNumberFormat(qFocoPointsByDay.confirmados, '9,999', 'Portuguese (Brazilian)')#</td>
                            </tr>
                        </cfoutput>
                    </tbody>
                </table>
            </div>
        </div>
    </section>

</section>
