<cfset VARIABLES.challengeIsCircuitPanel = false/>
<cfif isDefined("VARIABLES.challengeIsRaceParticipation") AND isBoolean(VARIABLES.challengeIsRaceParticipation)>
    <cfset VARIABLES.challengeIsCircuitPanel = VARIABLES.challengeIsRaceParticipation/>
</cfif>
<cfset VARIABLES.challengeShowsScoreColumn = false/>
<cfif isDefined("VARIABLES.challengeHasScore") AND isBoolean(VARIABLES.challengeHasScore)>
    <cfset VARIABLES.challengeShowsScoreColumn = VARIABLES.challengeHasScore/>
</cfif>
<cfset VARIABLES.challengeEventoApiToken = ""/>
<cfif structKeyExists(APPLICATION, "eventoApiToken")>
    <cfset VARIABLES.challengeEventoApiToken = trim(APPLICATION.eventoApiToken)/>
</cfif>

<div class="table-wrapper-l">

    <table id="tblEventos" class="table table-stripped table-condensed table-sm mb-0">
        <tr>
            <td>ID</td>
            <cfif URL.periodo NEQ "pendentes"><td>UF</td></cfif>
            <td>Nome</td>
            <cfif URL.periodo EQ "pendentes"><td>Email</td></cfif>
            <td>Tel</td>
            <cfif URL.periodo NEQ "pendentes" AND (NOT VARIABLES.challengeIsCircuitPanel OR VARIABLES.challengeShowsScoreColumn)><td class="text-end"><cfif VARIABLES.challengeShowsScoreColumn>Pontos<cfelse>KM</cfif></td></cfif>
            <!---td class="text-end">Última</td--->
            <td class="text-end"><cfif VARIABLES.challengeIsCircuitPanel><cfif isDefined("VARIABLES.challengeIsBrasilGigante") AND VARIABLES.challengeIsBrasilGigante>Provas<cfelse>Etapas</cfif><cfelse>Dias</cfif></td>
            <cfif URL.periodo NEQ "pendentes" AND NOT VARIABLES.challengeIsCircuitPanel><td class="text-start">Atualizar</td></cfif>
        </tr>
        <tbody>
        <cfoutput query="qStatsEvento">
        <cfset VARIABLES.rowEstado = ""/>
        <cfset VARIABLES.rowEmail = ""/>
        <cfset VARIABLES.rowTag = ""/>
        <cfset VARIABLES.rowStatusTransacao = ""/>
        <cfset VARIABLES.rowStravaCode = ""/>
        <cfset VARIABLES.rowStravaId = ""/>
        <cfset VARIABLES.rowProduto = ""/>
        <cfset VARIABLES.rowNome = ""/>
        <cfset VARIABLES.rowDdi = ""/>
        <cfset VARIABLES.rowDdd = ""/>
        <cfset VARIABLES.rowTelefone = ""/>
        <cfset VARIABLES.rowDistancia = ""/>
        <cfset VARIABLES.rowDiasCorrendo = ""/>
        <cfset VARIABLES.rowDiasDoAno = ""/>
        <cfset VARIABLES.rowDataEstatisticas = ""/>
        <cfset VARIABLES.rowDataInicial = ""/>
        <cfset VARIABLES.rowDataFinal = ""/>
        <cfset VARIABLES.rowStravaExpiresAt = ""/>
        <cfif isDefined("qStatsEvento.estado") AND NOT isNull(qStatsEvento.estado)><cfset VARIABLES.rowEstado = qStatsEvento.estado/></cfif>
        <cfif isDefined("qStatsEvento.email") AND NOT isNull(qStatsEvento.email)><cfset VARIABLES.rowEmail = qStatsEvento.email/></cfif>
        <cfif isDefined("qStatsEvento.tag") AND NOT isNull(qStatsEvento.tag)><cfset VARIABLES.rowTag = qStatsEvento.tag/></cfif>
        <cfif isDefined("qStatsEvento.status_transacao") AND NOT isNull(qStatsEvento.status_transacao)><cfset VARIABLES.rowStatusTransacao = qStatsEvento.status_transacao/></cfif>
        <cfif isDefined("qStatsEvento.strava_code") AND NOT isNull(qStatsEvento.strava_code)><cfset VARIABLES.rowStravaCode = qStatsEvento.strava_code/></cfif>
        <cfif isDefined("qStatsEvento.strava_id") AND NOT isNull(qStatsEvento.strava_id)><cfset VARIABLES.rowStravaId = qStatsEvento.strava_id/></cfif>
        <cfif isDefined("qStatsEvento.produto") AND NOT isNull(qStatsEvento.produto)><cfset VARIABLES.rowProduto = qStatsEvento.produto/></cfif>
        <cfif isDefined("qStatsEvento.nome") AND NOT isNull(qStatsEvento.nome)><cfset VARIABLES.rowNome = qStatsEvento.nome/></cfif>
        <cfif isDefined("qStatsEvento.ddi_usuario") AND NOT isNull(qStatsEvento.ddi_usuario)><cfset VARIABLES.rowDdi = qStatsEvento.ddi_usuario/></cfif>
        <cfif isDefined("qStatsEvento.ddd_usuario") AND NOT isNull(qStatsEvento.ddd_usuario)><cfset VARIABLES.rowDdd = qStatsEvento.ddd_usuario/></cfif>
        <cfif isDefined("qStatsEvento.telefone_usuario") AND NOT isNull(qStatsEvento.telefone_usuario)><cfset VARIABLES.rowTelefone = qStatsEvento.telefone_usuario/></cfif>
        <cfif isDefined("qStatsEvento.distancia_percorrida") AND NOT isNull(qStatsEvento.distancia_percorrida)><cfset VARIABLES.rowDistancia = qStatsEvento.distancia_percorrida/></cfif>
        <cfif isDefined("qStatsEvento.dias_correndo") AND NOT isNull(qStatsEvento.dias_correndo)><cfset VARIABLES.rowDiasCorrendo = qStatsEvento.dias_correndo/></cfif>
        <cfif isDefined("qStatsEvento.dias_do_ano") AND NOT isNull(qStatsEvento.dias_do_ano)><cfset VARIABLES.rowDiasDoAno = qStatsEvento.dias_do_ano/></cfif>
        <cfif isDefined("qStatsEvento.data_statisticas") AND NOT isNull(qStatsEvento.data_statisticas)><cfset VARIABLES.rowDataEstatisticas = qStatsEvento.data_statisticas/></cfif>
        <cfif isDefined("qStatsEvento.data_inicial") AND NOT isNull(qStatsEvento.data_inicial)><cfset VARIABLES.rowDataInicial = qStatsEvento.data_inicial/></cfif>
        <cfif isDefined("qStatsEvento.data_final") AND NOT isNull(qStatsEvento.data_final)><cfset VARIABLES.rowDataFinal = qStatsEvento.data_final/></cfif>
        <cfif isDefined("qStatsEvento.strava_expires_at") AND NOT isNull(qStatsEvento.strava_expires_at)><cfset VARIABLES.rowStravaExpiresAt = qStatsEvento.strava_expires_at/></cfif>
        <tr style="font-size: small;">
            <td nowrap>#id#</td>
            <!---td nowrap>#lsDateFormat(qStatsEvento.data_criacao, "yyyy-mm-dd")# #lsTimeFormat(qStatsEvento.data_criacao, "HH:mm")#</td--->
            <cfif URL.periodo NEQ "pendentes"><td>#VARIABLES.rowEstado#</td></cfif>
            <!--- EVENTO --->
            <td>
                <a target="_blank" href="https://dev.roadrunners.run/?action=dev_auth&dev_auth=#VARIABLES.rowEmail#"><i class="fa fa-user px-1 text-white"></i></a>
                <a target="_blank" href="https://roadrunners.run/atleta/#VARIABLES.rowTag#/?filtro=desafios"><img src="../../assets/rr_icon.jpg" width="24" class="shadow-5 px-1"></a>
                <a target="_blank" href="https://roadrunners.run/carteira/visualizar.cfm?id_usuario=#qStatsEvento.id#&debug=true"><div class="badge <cfif VARIABLES.rowStatusTransacao EQ 'pago'>bg-success<cfelseif VARIABLES.rowStatusTransacao EQ 'duplicado'>bg-danger<cfelseif VARIABLES.rowStatusTransacao EQ 'pendente'>bg-warning<cfelse>bg-secondary</cfif> me-1"><i class="fa fa-wallet"></i></div></a>
                <cfif len(trim(VARIABLES.rowStravaCode)) AND len(trim(VARIABLES.rowStravaId))><a target="_blank" href="https://www.strava.com/athletes/#VARIABLES.rowStravaId#/"><div class="badge bg-strava me-1"><i class="fa-brands fa-strava"></i></div></a></cfif>
                <cfif VARIABLES.rowProduto CONTAINS "vip"><div class="badge bg-black me-1">V</div><cfelse><div class="badge badge-secondary me-1">N</div></cfif>
                #VARIABLES.rowNome#
            </td>
            <cfif URL.periodo EQ "pendentes"><td>#VARIABLES.rowEmail#</td></cfif>
            <td nowrap>
                #VARIABLES.rowDdi# #VARIABLES.rowDdd# #VARIABLES.rowTelefone#
            </td>
            <cfif URL.periodo NEQ "pendentes" AND (NOT VARIABLES.challengeIsCircuitPanel OR VARIABLES.challengeShowsScoreColumn)>
                <td class="text-end">
                    <cfif len(trim(VARIABLES.rowDistancia))>
                        <cfif VARIABLES.challengeIsCircuitPanel>
                            #numberFormat(VARIABLES.rowDistancia, "9")#
                        <cfelse>
                            #numberFormat(VARIABLES.rowDistancia/1000, "9")#k
                        </cfif>
                    </cfif>
                </td>
            </cfif>
            <!---td class="text-end">#ultimo_dia#</td--->
            <td class="text-end"><cfif len(trim(VARIABLES.rowDiasCorrendo))>#VARIABLES.rowDiasCorrendo#<cfif len(trim(VARIABLES.rowDiasDoAno))>/#VARIABLES.rowDiasDoAno#</cfif></cfif></td>
            <cfif URL.periodo NEQ "pendentes" AND NOT VARIABLES.challengeIsCircuitPanel>
                <td class="text-start" nowrap>
                    <cfif len(trim(VARIABLES.rowStravaCode)) AND len(trim(VARIABLES.challengeEventoApiToken))>
                        <a target="_blank" href="https://roadrunners.run/api/strava/atualizar/?desafio=#URL.desafio#&id_usuario=#id#&token=#urlEncodedFormat(VARIABLES.challengeEventoApiToken)#&debug=true"><div class="badge bg-strava"><i class="fa fa-refresh"></i></div></a>
                        <a target="_blank" href="https://roadrunners.run/api/strava/atualizar/?desafio=#URL.desafio#&id_usuario=#id#&token=#urlEncodedFormat(VARIABLES.challengeEventoApiToken)#&debug=true&full=true"><div class="badge bg-black me-1"><i class="fa fa-refresh"></i></div></a>
                        <a target="_blank" href="https://roadrunners.run/api/strava/atualizar/?desafio=#URL.desafio#&id_usuario=#id#&token=#urlEncodedFormat(VARIABLES.challengeEventoApiToken)#&debug=true&full=promax"><div class="badge <cfif len(trim(VARIABLES.rowDataEstatisticas))>bg-secondary<cfelse>bg-black</cfif> me-1"><i class="fa fa-mobile"></i></div></a>
                        <cfif len(trim(VARIABLES.rowDataInicial))>#lsDateFormat(VARIABLES.rowDataInicial,'mm/yyyy')# | </cfif>
                        <cfif len(trim(VARIABLES.rowDataFinal))> há <cfif DateDiff("n",VARIABLES.rowDataFinal, now()) LT 120>#DateDiff("n",VARIABLES.rowDataFinal, now())# min<cfelse>#DateDiff("h",VARIABLES.rowDataFinal, now())# horas</cfif> | </cfif>
                        <cfif len(trim(VARIABLES.rowStravaExpiresAt))> <cfif DateDiff("n",VARIABLES.rowStravaExpiresAt, now()) LT 0>#DateDiff("n",VARIABLES.rowStravaExpiresAt, now()) * -1# min válido<cfelse><span class="text-danger">token expirado</span></cfif></cfif>
                    </cfif>
                </td>
            </cfif>
        </tr>
        </cfoutput>
        </tbody>
    </table>

</div>
