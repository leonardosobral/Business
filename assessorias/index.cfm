<!doctype html>
<html lang="pt-br">

<cfprocessingdirective pageencoding="utf-8"/>

<cfset VARIABLES.template = "365"/>

<!--- VARIAVEIS --->
<cfparam name="URL.equipe" default=""/>
<cfparam name="URL.preset" default=""/>
<cfparam name="URL.busca" default=""/>
<cfparam name="URL.regiao" default=""/>
<cfparam name="URL.estado" default=""/>
<cfparam name="URL.cidade" default=""/>

<!--- BACKEND --->
<cfinclude template="../backend_login.cfm"/>
<cfinclude template="backend.cfm"/>

<!--- HEAD --->
<head>

    <!--- REQUIRED META TAGS --->
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1"/>

    <title>Runner Hub - BI</title>
    <cfinclude template="../includes/seo-web-tools-head.cfm"/>

    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.5.0/css/font-awesome.min.css">

    <style>
        a {
            color: #333333;
        }
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

<body class="bg-body-secondary">

    <cfif NOT isDefined("COOKIE.id")>

        <cflocation addtoken="false" url="/bi/"/>

    <cfelse>

        <div class="container-fluid mt-3">


            <!--- HEADER --->

            <cfinclude template="../includes/header_parceiro.cfm"/>


            <!--- WIDGETS --->



            <!--- ESTATISTICAS --->

            <div class="row g-3">


                <!--- LISTAGEM DE EQUIPES --->

                <div class="col-md-6">

                    <div class="card">

                        <div class="card-header bg-black text-white fw-bold px-3 py-2">
                            <table class="m-0" width="98%">
                                <tr>
                                    <td width="10%"></td>
                                    <td>Equipes</td>
                                    <td width="15%" class="text-end">Corredores</td>
                                    <td width="15%" class="text-end">Eventos</td>
                                    <td width="15%" class="text-end">Média</td>
                                </tr>
                            </table>
                        </div>

                        <div class="card-body p-2">

                            <div class="table-wrapper-lg">
                                <table class="table table-stripped table-condensed table-sm mb-0">
                                    <tbody>
                                        <cfoutput query="qBase">
                                        <tr style="cursor: pointer;" <cfif qBase.equipe EQ URL.equipe>class="table-active"  onclick="location.href = './?preset=#URL.preset#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#'"<cfelse>onclick="location.href = './?preset=#URL.preset#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#&equipe=#urlEncodedFormat(qBase.equipe)#'"</cfif> >
                                            <td width="10%" nowrap>#qBase.currentrow#º</td>
                                            <td>#qBase.equipe#</td>
                                            <td width="15%" class="text-end">#qBase.corredores#</td>
                                            <td width="15%" class="text-end">#qBase.eventos#</td>
                                            <td width="15%" class="text-end">#lsNumberFormat((qBase.corredores)/qBase.eventos, 9.9)#</td>
                                        </tr>
                                        </cfoutput>
                                    </tbody>
                                </table>

                            </div>

                        </div>

                    </div>


                </div>


                <!--- LISTAGEM DE EVENTOS --->

                <cfif len(trim(URL.equipe))>

                <div class="col-md-6">

                    <div class="card">

                        <div class="card-header <cfif URL.preset EQ "2024">bg-warning<cfelseif URL.preset EQ "2023">bg-secondary<cfelse>bg-black</cfif> text-white fw-bold px-3 py-2">
                            <table class="m-0" width="98%">
                                <tr>
                                    <td width="15%">Data</td>
                                    <td width="10%">UF</td>
                                    <td>Eventos (<cfoutput>#qStatsEvento.recordCount#</cfoutput>)</td>
                                    <td width="15%" class="text-end"><icon class="fa fa-users"></icon></td>
                                    <td width="10%" class="text-end"><icon class="fa fa-users"></icon></td>
                                </tr>
                            </table>
                        </div>

                        <div class="card-body p-2">

                            <div class="table-wrapper-lg">

                                <table class="table table-stripped table-condensed table-sm mb-0">
                                    <tbody>
                                    <cfoutput query="qStatsEvento">
                                        <tr>
                                            <td width="15%" nowrap>#qStatsEvento.data_final#</td>
                                            <td width="10%">#qStatsEvento.estado#</td>
                                            <td width="60%">
                                                <a target="_blank" href="https://openresults.run/evento/#qStatsEvento.tag#/"><img src="/assets/icons/rh_or_favicon.png" width="16" class="me-2"/></a>
                                                <a target="_blank" href="https://roadrunners.run/evento/#qStatsEvento.tag#/"><img src="/assets/icons/rh_rr_favicon.png" width="16" class="me-2"/></a>
                                                #replace(replace(qStatsEvento.nome_evento, 'Live! Run XP 2024 - ', '<span class="badge bg-warning">2024</span>&nbsp;&nbsp;'), 'Live! Run XP 2023 - ', '<span class="badge bg-secondary">2023</span>&nbsp;&nbsp;')#
                                            </td>
                                            <td width="15%" class="text-end">#lsNumberFormat(qStatsEvento.concluintes)#</td>
                                            <td width="1%" class="text-end">#lsNumberFormat(qStatsEvento.corredores)#</td>
                                        </tr>
                                    </cfoutput>
                                    </tbody>
                                </table>

                            </div>

                        </div>

                    </div>

                </div>

                </cfif>

            </div>

        </div>

    </cfif>

    <cfinclude template="../includes/footer_parceiro.cfm"/>

    <cfinclude template="../includes/seo-web-tools-body-end.cfm"/>

</body>

</html>
