<div class="table-wrapper-lg">

    <table id="tblEventos" class="table table-stripped table-condensed table-sm mb-0">
        <tr>
            <td>ID</td>
            <cfif URL.periodo NEQ "pendentes"><td>UF</td></cfif>
            <td>Nome</td>
            <cfif URL.periodo EQ "pendentes"><td>Email</td></cfif>
            <td>Tel</td>
            <cfif URL.periodo NEQ "pendentes"><td class="text-end">KM</td></cfif>
            <!---td class="text-end">Última</td--->
            <td class="text-end">Dias</td>
            <td class="text-start">Atualizar</td>
        </tr>
        <tbody>
        <cfoutput query="qStatsEvento">
        <tr style="font-size: small;">
            <td nowrap>#id#</td>
            <!---td nowrap>#lsDateFormat(qStatsEvento.data_criacao, "yyyy-mm-dd")# #lsTimeFormat(qStatsEvento.data_criacao, "HH:mm")#</td--->
            <cfif URL.periodo NEQ "pendentes"><td>#qStatsEvento.estado#</td></cfif>
            <!--- EVENTO --->
            <td>
                <a target="_blank" href="https://roadrunners.run/atleta/#qStatsEvento.tag#/?filtro=desafios"><img src="../../assets/rr_icon.jpg" width="24" class="shadow-5 px-1"></a>
                <a target="_blank" href="https://roadrunners.run/carteira/visualizar.cfm?id_usuario=#qStatsEvento.id#&debug=true"><div class="badge <cfif qStatsEvento.status_transacao EQ 1>bg-success<cfelseif qStatsEvento.status_transacao GT 1>bg-danger<cfelse>bg-secondary</cfif> me-1"><i class="fa fa-wallet"></i></div></a>
                <cfif len(trim(qStatsEvento.strava_code))><a target="_blank" href="https://www.strava.com/athletes/#strava_id#/"><div class="badge bg-strava me-1"><i class="fa-brands fa-strava"></i></div></a></cfif>
                <cfif qStatsEvento.produto CONTAINS "vip"><div class="badge bg-black me-1">V</div><cfelse><div class="badge badge-secondary me-1">N</div></cfif>
                #qStatsEvento.nome#
            </td>
            <cfif URL.periodo EQ "pendentes"><td>#qStatsEvento.email#</td></cfif>
            <td nowrap>
                #qStatsEvento.ddi_usuario# #qStatsEvento.ddd_usuario# #qStatsEvento.telefone_usuario#
            </td>
            <cfif URL.periodo NEQ "pendentes"><td class="text-end"><cfif len(trim(distancia_percorrida))>#numberFormat(distancia_percorrida/1000, "9")#k</cfif></td></cfif>
            <!---td class="text-end">#ultimo_dia#</td--->
            <td class="text-end"><cfif len(trim(distancia_percorrida))>#dias_correndo#/#dias_do_ano#</cfif></td>
            <td class="text-start" nowrap>
                <cfif isDefined("strava_code") AND len(trim(qStatsEvento.strava_code))>
                    <a target="_blank" href="https://roadrunners.run/api/strava/atualizar/?desafio=#URL.desafio#&id_usuario=#id#&token=jf8w3ynr73840rync848udq07yrc89q2h4nr08ync743c9r8h328f42fc8n23&debug=true"><div class="badge bg-strava"><i class="fa fa-refresh"></i></div></a>
                    <a target="_blank" href="https://roadrunners.run/api/strava/atualizar/?desafio=#URL.desafio#&id_usuario=#id#&token=jf8w3ynr73840rync848udq07yrc89q2h4nr08ync743c9r8h328f42fc8n23&debug=true&full=true"><div class="badge bg-black me-1"><i class="fa fa-refresh"></i></div></a>
                    <a target="_blank" href="https://roadrunners.run/api/strava/atualizar/?desafio=#URL.desafio#&id_usuario=#id#&token=jf8w3ynr73840rync848udq07yrc89q2h4nr08ync743c9r8h328f42fc8n23&debug=true&full=promax"><div class="badge bg-black me-1"><i class="fa fa-mobile"></i></div></a>
                    <cfif isDefined("ultima_atividade") AND len(trim(ultima_atividade))> há <cfif DateDiff("n",ultima_atividade, now()) LT 120>#DateDiff("n",ultima_atividade, now())# min<cfelse>#DateDiff("h",ultima_atividade, now())# horas</cfif> | </cfif>
                    <cfif isDefined("strava_expires_at") AND len(trim(strava_expires_at))> <cfif DateDiff("n",strava_expires_at, now()) LT 0>#DateDiff("n",strava_expires_at, now()) * -1# min válido<cfelse><span class="text-danger">token expirado</span></cfif></cfif>
                </cfif>
            </td>
        </tr>
        </cfoutput>
        </tbody>
    </table>

</div>
