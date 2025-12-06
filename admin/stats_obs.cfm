<!doctype html>
<html lang="pt-br" data-mdb-theme="dark">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- TEMPLATE --->
<cfset VARIABLES.template = "/admin/stats_obs.cfm"/>

<!--- VARIAVEIS --->
<cfinclude template="includes/variaveis.cfm"/>
<cfset URL.sessao = "or"/>

<!--- BACKEND --->
<cfinclude template="includes/backend/backend_login.cfm"/>
<cfinclude template="includes/backend/backend_evento_edicao.cfm"/>
<cfinclude template="includes/backend/backend_resultados.cfm"/>
<cfinclude template="includes/backend/backend_stats_obs.cfm"/>


<!--- HEAD --->
<head>

    <!--- REQUIRED META TAGS --->
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1"/>

    <title>Runner Hub - Admin</title>
    <cfinclude template="includes/seo-web-tools-head.cfm"/>

    <style>
        .table-active {
            background-color: #F4B120; !important;
        }
        .table-wrapper {
            max-height: 200px;
            min-height: 200px;
            width: 100%;
            overflow: auto;
            display:inline-block;
        }
        .table-wrapper-lg {
            max-height: 404px;
            min-height: 404px;
            width: 100%;
            overflow: auto;
            display:inline-block;
        }
        .table-wrapper-sm {
            max-height: 120px;
            min-height: 120px;
            width: 100%;
            overflow: auto;
            display:inline-block;
        }
    </style>

</head>

<body>

    <cfif NOT isDefined("COOKIE.id")>

        <div class="g-signin2 ms-2" data-onsuccess="onSignIn"></div>

    <cfelse>

        <div class="container-fluid mt-3">


            <!--- HEADER --->

            <cfinclude template="includes/header.cfm"/>


            <!--- WIDGETS --->

            <cfinclude template="widgets_resultados.cfm"/>


            <!--- FILTROS --->

            <cfinclude template="filtro_resultados.cfm"/>


            <!--- PROGRESSO --->

            <div class="progress mb-3" style="height: 18px;">
              <div class="progress-bar bg-success" role="progressbar" style="padding-top: 2px; width: <cfoutput>#VARIABLES.totalProvasResultado#</cfoutput>%" aria-valuenow="<cfoutput>#VARIABLES.totalProvasResultado#</cfoutput>" aria-valuemin="0" aria-valuemax="100"><cfoutput>#numberFormat(VARIABLES.totalProvasResultado, 9.9)#</cfoutput>%</div>
              <div class="progress-bar bg-info" role="progressbar" style="padding-top: 2px; width: <cfoutput>#VARIABLES.totalProvasLink#</cfoutput>%" aria-valuenow="<cfoutput>#VARIABLES.totalProvasLink#</cfoutput>" aria-valuemin="0" aria-valuemax="100"><cfoutput>#numberFormat(VARIABLES.totalProvasLink, 9.9)#</cfoutput>% TEM LINK</div>
              <div class="progress-bar bg-danger" role="progressbar" style="padding-top: 2px; width: <cfoutput>#VARIABLES.totalProvasSemResultado#</cfoutput>%" aria-valuenow="<cfoutput>#VARIABLES.totalProvasSemResultado#</cfoutput>" aria-valuemin="0" aria-valuemax="100"><cfoutput>#numberFormat(VARIABLES.totalProvasSemResultado, 9.9)#</cfoutput>%</div>
              <div class="progress-bar bg-secondary" role="progressbar" style="padding-top: 2px; width: <cfoutput>#VARIABLES.totalProvasPendentes#</cfoutput>%" aria-valuenow="<cfoutput>#VARIABLES.totalProvasPendentes#</cfoutput>" aria-valuemin="0" aria-valuemax="100"><cfoutput>#numberFormat(VARIABLES.totalProvasPendentes, 9.9)#</cfoutput>%</div>
            </div>


            <!--- ESTATISTICAS --->

            <div class="row g-3">


                <!--- LISTAGEM ERROR IMPORT --->

                <cfif NOT Len(trim(URL.id_evento))>

                    <div class="col-md-3">

                        <div class="card">

                            <div class="card-header px-3 py-2">Observações (<cfoutput>#qPeriodoObs.recordcount#</cfoutput>)</div>

                            <div class="card-body p-2">

                                <div class="table-wrapper-lg">

                                    <table id="tblEventos" class="table table-stripped table-condensed table-sm mb-0">

                                        <cfoutput query="qEventos_obs">
                                            <tbody>
                                                <tr style="cursor: pointer;" <cfif qEventos_obs.obs_resultado EQ URL.busca>class="table-active"</cfif>  onclick="location.href = './stats_obs.cfm?periodo=#URL.periodo#&id_agrega_evento=#URL.id_agrega_evento#&agregador_tag=#URL.agregador_tag#&busca=#qEventos_obs.obs_resultado#'">
                                                    <td class="text-start">#Len(trim(qEventos_obs.obs_resultado)) ? qEventos_obs.obs_resultado : 'Sem OBS'#</td>
                                                    <td class="text-end">#qEventos_obs.total#</td>
                                                </tr>
                                            </tbody>
                                        </cfoutput>

                                    </table>

                                </div>

                            </div>

                        </div>

                    </div>

                </cfif>


                <!--- Evento + error Import --->

                <div class="col-md-<cfif Len(trim(URL.id_evento))>6<cfelse>9</cfif>">

                    <div class="card">

                        <div class="card-header px-3 py-2">Eventos (<cfoutput>#qEventos_statsobs.recordcount#</cfoutput>)</div>

                        <div class="card-body p-2">

                            <div class="table-wrapper-lg">

                                <table id="tblEventos" class="table table-stripped table-condensed table-sm mb-0">

                                    <tbody>

                                        <cfoutput query="qEventos_statsobs">
                                            <tr>
                                                <td nowrap>#lsDateFormat(qEventos_statsobs.data_final, "dd/mm")#</td>

                                                <!--- EVENTO --->
                                                <td>
                                                    <a target="processar" href="https://roadrunners.run/evento/#qEventos_statsobs.tag#/"><img src="../assets/rr_icon.jpg" class="w-24px rounded-5 shadow-5 me-2"/></a>
                                                    <a target="processar" href="https://google.com.br/search?q=#urlEncodedFormat(qEventos_statsobs.nome_evento)#"><i class="fa-brands fa-google me-2"></i></a>
                                                    <a target="processar" href="#qEventos_statsobs.url_resultado#"><icon class="fa fa-link me-2"></icon></a>
                                                    <a href="#VARIABLES.template#?id_evento=#qEventos_statsobs.id_evento#&busca=#URL.busca#&periodo=#URL.periodo#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#&id_agrega_evento=#URL.id_agrega_evento#&agregador_tag=#URL.agregador_tag#">#qEventos_statsobs.nome_evento#</a>
                                                </td>

                                                <td class="text-end">
                                                    <cfif Len(trim(qEventos_statsobs.url_resultado))>
                                                        <cfif qEventos_statsobs.url_resultado contains ".clax">
                                                            <a target="processar" href="/api/wiclax/?id_evento=#qEventos_statsobs.id_evento#&auto=true"><cfif qEventos_statsobs.url_resultado CONTAINS "chronomax">Chrono<cfelse>Wiclax</cfif></a>

                                                        <cfelseif Len(trim(qEventos_statsobs.url_resultado)) and qEventos_statsobs.url_resultado contains "chiptiming">
                                                            <a target="processar" href="/api/excel/?id_evento=#qEventos_statsobs.id_evento#">Chipt</a>
                                                        <cfelseif Len(trim(qEventos_statsobs.url_resultado)) and qEventos_statsobs.url_resultado contains "esportecorrida">
                                                            <a target="processar" href="/api/excel/?id_evento=#qEventos_statsobs.id_evento#">Esportecorrida</a>
                                                        <cfelseif Len(trim(qEventos_statsobs.url_resultado)) and (qEventos_statsobs.url_resultado contains "ativo" OR qEventos_statsobs.url_resultado contains "o2corre")>
                                                            <a target="_blank" href="/api/o2/?id_evento=#qEventos_statsobs.id_evento#&cod_evento=">API O2</a>
                                                        <cfelseif Len(trim(qEventos_statsobs.url_resultado)) and qEventos_statsobs.url_resultado contains "tfsports">
                                                            <a target="_blank" href="/api/tf/?id_evento=#qEventos_statsobs.id_evento#&cod_evento=">API TF</a>
                                                        <cfelseif Len(trim(qEventos_statsobs.url_resultado)) and qEventos_statsobs.url_resultado contains "resultados.runking">
                                                            <a target="processar" href="/api/excel/?id_evento=#qEventos_statsobs.id_evento#">runking</a>
                                                        <cfelseif Len(trim(qEventos_statsobs.url_resultado)) and qEventos_statsobs.url_resultado contains "morro-mt">
                                                            <a target="processar" href="/api/excel/?id_evento=#qEventos_statsobs.id_evento#">MorroMT</a>
                                                        <cfelseif Len(trim(qEventos_statsobs.url_resultado)) and qEventos_statsobs.url_resultado contains "cronotag">
                                                            <a target="processar" href="/api/excel/?id_evento=#qEventos_statsobs.id_evento#">Cronotag</a>
                                                        <cfelseif Len(trim(qEventos_statsobs.url_resultado)) and qEventos_statsobs.url_resultado contains "chiprun">
                                                            <a target="processar" href="/api/excel/?id_evento=#qEventos_statsobs.id_evento#">>Chiprun</a>
                                                        <cfelseif Len(trim(qEventos_statsobs.url_resultado)) and qEventos_statsobs.url_resultado contains "newtimecronometragem">
                                                            <a target="processar" href="/api/excel/?id_evento=#qEventos_statsobs.id_evento#">newtimecronometragem</a>
                                                        <cfelseif Len(trim(qEventos_statsobs.url_resultado)) and qEventos_statsobs.url_resultado contains "worldathletics">
                                                            <a target="processar" href="/api/excel/?id_evento=#qEventos_statsobs.id_evento#">worldathletics</a>
                                                        <cfelseif Len(trim(qEventos_statsobs.url_resultado)) and qEventos_statsobs.url_resultado contains "globalcronometragem">
                                                            <a target="processar" href="/api/excel/?id_evento=#qEventos_statsobs.id_evento#">global</a>
                                                        <cfelseif Len(trim(qEventos_statsobs.url_resultado)) and qEventos_statsobs.url_resultado contains "cronoserv">
                                                            <a target="processar" href="/api/excel/?id_evento=#qEventos_statsobs.id_evento#">cronoserv</a>
                                                        <cfelseif Len(trim(qEventos_statsobs.url_resultado)) and qEventos_statsobs.url_resultado contains "centralderesultados">
                                                            <a target="processar" href="/api/excel/?id_evento=#qEventos_statsobs.id_evento#">centralderesultados</a>
                                                        <cfelseif Len(trim(qEventos_statsobs.url_resultado)) and qEventos_statsobs.url_resultado contains "rodrigocirilo">
                                                            <a target="processar" href="/api/excel/?id_evento=#qEventos_statsobs.id_evento#">rodrigocirilo</a>
                                                        <cfelseif Len(trim(qEventos_statsobs.url_resultado)) and qEventos_statsobs.url_resultado contains "estounessa">
                                                            <a target="processar" href="/api/excel/?id_evento=#qEventos_statsobs.id_evento#">estounessa</a>
                                                        <cfelseif Len(trim(qEventos_statsobs.url_resultado)) and qEventos_statsobs.url_resultado contains "assessocor">
                                                            <a target="processar" href="/api/excel/?id_evento=#qEventos_statsobs.id_evento#">assessocor</a>
                                                        <cfelseif Len(trim(qEventos_statsobs.url_resultado)) and qEventos_statsobs.url_resultado contains "kmaisclube">
                                                            <a target="processar" href="/api/excel/?id_evento=#qEventos_statsobs.id_evento#">kmaisclube</a>
                                                        <cfelseif Len(trim(qEventos_statsobs.url_resultado)) and qEventos_statsobs.url_resultado contains "zeniteesportes">
                                                            <a target="processar" href="/api/excel/?id_evento=#qEventos_statsobs.id_evento#">zeniteesportes</a>
                                                        <cfelseif Len(trim(qEventos_statsobs.url_resultado)) and qEventos_statsobs.url_resultado contains "km.esp">
                                                            <a target="processar" href="/api/excel/?id_evento=#qEventos_statsobs.id_evento#">km.esp</a>
                                                        <cfelseif Len(trim(qEventos_statsobs.url_resultado)) and qEventos_statsobs.url_resultado contains "timeaction">
                                                            <a target="processar" href="/api/excel/?id_evento=#qEventos_statsobs.id_evento#">timeaction</a>
                                                        <cfelseif Len(trim(qEventos_statsobs.url_resultado)) and qEventos_statsobs.url_resultado contains "circuitosantanderdecorrida">
                                                            <a target="processar" href="/api/excel/?id_evento=#qEventos_statsobs.id_evento#">circuitosantanderdecorrida</a>
                                                        <cfelseif Len(trim(qEventos_statsobs.url_resultado)) and qEventos_statsobs.url_resultado contains "apcrono">
                                                            <a target="processar" href="/api/excel/?id_evento=#qEventos_statsobs.id_evento#">apcrono</a>
                                                        <cfelseif Len(trim(qEventos_statsobs.url_resultado)) and qEventos_statsobs.url_resultado contains "onsport">
                                                            <a target="processar" href="/api/excel/?id_evento=#qEventos_statsobs.id_evento#">onsport</a>
                                                        <cfelseif Len(trim(qEventos_statsobs.url_resultado)) and qEventos_statsobs.url_resultado contains "resultadonoar">
                                                            <a target="processar" href="/api/excel/?id_evento=#qEventos_statsobs.id_evento#">resultadonoar</a>
                                                            <cfelseif Len(trim(qEventos_statsobs.url_resultado)) and qEventos_statsobs.url_resultado contains "inscricoes.corridaeaventura">
                                                                <a target="processar" href="/api/excel/?id_evento=#qEventos_statsobs.id_evento#">corrida&Aventura</a>
                                                        <cfelseif Len(trim(qEventos_statsobs.url_resultado)) and qEventos_statsobs.url_resultado contains "oestechip">
                                                            <a target="processar" href="/api/excel/?id_evento=#qEventos_statsobs.id_evento#">oestechip</a>
                                                        <cfelseif Len(trim(qEventos_statsobs.url_resultado)) and qEventos_statsobs.url_resultado contains "inscricao.cronoteam">
                                                            <a target="processar" href="/api/excel/?id_evento=#qEventos_statsobs.id_evento#">inscricao.cronoteam</a>
                                                        <cfelseif Len(trim(qEventos_statsobs.url_resultado)) and qEventos_statsobs.url_resultado contains "oestechip">
                                                            <a target="processar" href="/api/excel/?id_evento=#qEventos_statsobs.id_evento#">oestechip</a>

                                                        <cfelse>
                                                            <a target="processar" href="/api/wiclax/?id_evento=#qEventos_statsobs.id_evento#">Import</a>
                                                        </cfif>
                                                    </cfif>
                                                </td>
                                            </tr>
                                        </cfoutput>

                                    </tbody>

                                </table>

                            </div>

                        </div>

                    </div>

                </div>


                <cfif Len(trim(URL.id_evento))>

                    <cfinclude template="form_edicao.cfm"/>

                </cfif>


            </div>

        </div>

    </cfif>

    <cfinclude template="includes/seo-web-tools-body-end.cfm"/>

</body>

</html>
