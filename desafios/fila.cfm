<!doctype html>
<html lang="pt-br">

<cfprocessingdirective pageencoding="utf-8"/>

<cfset VARIABLES.template = "fila"/>

<!--- VARIAVEIS --->
<cfparam name="URL.full" default="false"/>
<cfparam name="URL.auto" default="false"/>
<cfparam name="URL.order" default="desc"/>
<cfparam name="URL.desafio" default="foco"/>

<!--- BACKEND --->
<cfinclude template="../includes/backend/backend_login.cfm"/>
<cfinclude template="backend_fila.cfm"/>

<!--- HEAD --->
<head>

    <!--- REQUIRED META TAGS --->
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1"/>

    <title>Runner Hub - BI</title>
    <cfinclude template="../includes/seo-web-tools-head.cfm"/>

    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.5.0/css/font-awesome.min.css">

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

<body data-mdb-theme="dark">

    <div class="container-fluid mt-3">


        <!--- HEADER --->

        <cfinclude template="header_desafio.cfm"/>


        <!--- ESTATISTICAS --->

        <div class="row g-3">

            <div class="col-md-12">

                <div class="row g-3">

                    <!--- LISTAGEM --->

                    <div class="col-md-12">

                        <div class="card">

                            <div class="card-header px-3 py-2">
                                Atletas (<cfoutput>#qStatsEvento.recordcount#</cfoutput>)
                                <a href="fila.cfm?reprocessar" class="btn btn-danger btn-sm float-end">Reprocessar</a>
                            </div>

                            <div class="card-body p-2">

                                <table id="tblEventos" class="table table-stripped table-condensed table-sm mb-0">
                                    <tr>
                                        <td>ID</td>
                                        <td>Athlete ID</td>
                                        <td>Activity ID</td>
                                        <td>UF</td>
                                        <td>Atleta</td>
                                        <td>Atualizar</td>
                                    </tr>
                                    <tbody>
                                    <cfoutput query="qStatsEvento">
                                    <tr style="font-size: small;">
                                        <td nowrap>#qStatsEvento.id#</td>
                                        <td nowrap>#qStatsEvento.athlete_id#</td>
                                        <td nowrap>#qStatsEvento.activity_id#</td>
                                        <!---td nowrap>#lsDateFormat(qStatsEvento.data_criacao, "yyyy-mm-dd")# #lsTimeFormat(qStatsEvento.data_criacao, "HH:mm")#</td--->
                                        <td>#qStatsEvento.estado#</td>
                                        <!--- EVENTO --->
                                        <td>
                                            <!---<a target="_blank" href="https://roadrunners.run/atleta/#qStatsEvento.tag#/?filtro=desafios">--->
                                                <img src="../../assets/rr_icon.jpg" width="24" class="shadow-5 px-1">
                                            <!---</a>--->
                                            <cfif len(trim(qStatsEvento.strava_code))>
                                                <!---<a target="_blank" href="https://www.strava.com/athletes/#strava_id#/">--->
                                                    <div class="badge bg-strava me-1"><i class="fa-brands fa-strava"></i></div>
                                                <!---</a>--->
                                            </cfif>
                                            #qStatsEvento.name#
                                        </td>
                                        <td class="text-start">
                                            <cfif len(trim(qStatsEvento.strava_code))>
                                                <a href="https://roadrunners.run/api/strava/atualizar/?desafio=#URL.desafio#&id_usuario=#id#&token=jf8w3ynr73840rync848udq07yrc89q2h4nr08ync743c9r8h328f42fc8n23&debug=true">
                                                    <div class="badge bg-strava"><i class="fa fa-refresh"></i></div>
                                                </a>
                                                <!---<a href="https://roadrunners.run/api/strava/atualizar/?desafio=#URL.desafio#&id_usuario=#id#&token=jf8w3ynr73840rync848udq07yrc89q2h4nr08ync743c9r8h328f42fc8n23&debug=true&full=true">--->
                                                    <div class="badge bg-black me-1"><i class="fa fa-refresh"></i></div>
                                                <!---</a>--->
                                            <cfif len(trim(qStatsEvento.start_date))> há <cfif DateDiff("n",start_date, now()) LT 120>#DateDiff("n",start_date, now())# min<cfelse>#DateDiff("h",start_date, now())# horas</cfif> | </cfif>
                                            <cfif len(trim(qStatsEvento.strava_expires_at))> <cfif DateDiff("n",strava_expires_at, now()) LT 0>#DateDiff("n",strava_expires_at, now()) * -1# min válido<cfelse><span class="text-danger">token expirado</span></cfif></cfif></cfif>
                                        </td>
                                    </tr>
                                    </cfoutput>
                                    </tbody>
                                </table>

                                <cfif qStatsEvento.recordcount and URL.auto>
                                    <meta http-equiv="refresh" content="0;URL='<cfoutput>https://roadrunners.run/api/strava/atualizar/?desafio=#URL.desafio#&id_usuario=#qStatsEvento.id#&token=jf8w3ynr73840rync848udq07yrc89q2h4nr08ync743c9r8h328f42fc8n23&debug=true&#URL.auto#=true&order=#URL.order#</cfoutput>'" />
                                <cfelse>
                                    <meta http-equiv="refresh" content="15">
                                </cfif>

                            </div>

                        </div>

                    </div>

                </div>

            </div>

        </div>

    </div>

    <cfinclude template="../includes/footer_parceiro.cfm"/>

    <cfinclude template="../includes/seo-web-tools-body-end.cfm"/>

</body>

</html>
