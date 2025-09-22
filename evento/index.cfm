<!doctype html>
<html lang="pt-br">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- TAG PARAM TREAT --->
<cfparam name="URL.tag" default=""/>
<cfset URL.tag = trim(replace(URL.tag, '/', ''))/>

<!--- VARIAVEIS --->
<cfparam name="URL.periodo" default=""/>
<cfif URL.tag NEQ "maratona-internacional-de-floripa">
    <cfparam name="URL.preset" default="2025"/>
<cfelse>
    <cfparam name="URL.preset" default="treino5"/>
</cfif>
<cfparam name="URL.busca" default=""/>
<cfparam name="URL.regiao" default=""/>
<cfparam name="URL.estado" default=""/>
<cfparam name="URL.cidade" default=""/>
<cfparam name="URL.inscricao" default=""/>
<cfparam name="URL.id_evento" default=""/>
<cfparam name="URL.percurso" default=""/>
<cfparam name="URL.assessoria" default=""/>

<!--- BACKEND --->
<cfinclude template="../includes/backend/backend_login.cfm"/>
<cfinclude template="../includes/backend/backend_parceiros.cfm"/>

<!--- HEAD --->
<head>

    <!--- REQUIRED META TAGS --->
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1"/>

    <title>Runner Hub - <cfoutput>#qAgrega.nome_evento_agregado#</cfoutput></title>
    <cfinclude template="../includes/seo-web-tools-head.cfm"/>

    <style>
        /*.table-active {
            background-color: #F4B120; !important;
        }*/
        .table-ts {
            background-color: rgba(50,150,255,0.1)!important;
        }
        .table-wrapper {
            max-height: 240px;
            min-height: 240px;
            width: 100%;
            overflow: auto;
            display:inline-block;
        }
        .table-wrapper-lg {
            max-height: 360px;
            min-height: 360px;
            width: 100%;
            overflow: auto;
            display:inline-block;
        }
        .table-wrapper-sm {
            max-height: 160px;
            min-height: 160px;
            width: 100%;
            overflow: auto;
            display:inline-block;
        }
        .table-wrapper-3 {
            max-height: 121px;
            min-height: 121px;
            width: 100%;
            overflow: auto;
            display:inline-block;
        }
        .table-wrapper-5 {
            max-height: 200px;
            min-height: 200px;
            width: 100%;
            overflow: auto;
            display:inline-block;
        }
        .table-wrapper-6 {
            max-height: 232px;
            min-height: 232px;
            width: 100%;
            overflow: auto;
            display:inline-block;
        }
        a {
            color:initial;
            text-decoration: none;
        }

        a:hover {
            color:initial;
        }
    </style>

</head>

<body <cfif qTema.recordcount>style="background-color:<cfoutput>#qTema.cor_fundo#</cfoutput>"</cfif>>

    <cfif NOT isDefined("COOKIE.id")>

        <cflocation addtoken="false" url="/"/>

    <cfelse>

        <div class="container-fluid mt-3">


            <!--- HEADER --->

            <cfinclude template="../includes/header_parceiro.cfm"/>

            <!---cfdump var="#qPeriodo#"/--->


            <!--- WIDGETS --->

            <div class="row g-2 mb-3">

                <cfif URL.tag NEQ "maratona-internacional-de-floripa">

                    <!--- ATUAL --->

                    <div class="col-md-4">
                        <div class="row g-2">
                            <div class="col-md-8">
                                <a href="./?regiao=&estado=&cidade=&preset=2025">
                                    <div class="card bg-warning text-white py-2 px-3" >
                                        <p class="h5 m-0"><cfoutput>#lsnumberFormat(qCountAtual.total)# / #lsnumberFormat(qCountEvAtual.total)# em 2025</cfoutput></p>
                                        <p class="m-0"><cfoutput>#lsnumberFormat(qCountAtual.concluintes)# concluintes</cfoutput></p>
                                    </div>
                                </a>
                            </div>
                            <div class="col-md-4 d-none d-md-block">
                                <a href="./?regiao=&estado=&cidade=&preset=2025">
                                    <div class="card bg-warning text-white py-2 px-3">
                                        <p class="h5 m-0"><cfoutput>#Len(qCountAtual.total) AND Len(qCountAtual.concluintes) ? lsnumberFormat(qCountAtual.concluintes/qCountAtual.total) : 0#</cfoutput></p>
                                        <p class="m-0"><cfoutput>Média</cfoutput></p>
                                    </div>
                                </a>
                            </div>
                        </div>
                    </div>

                    <!--- ANTERIOR --->

                    <div class="col-md-4 d-none d-md-block">
                        <div class="row g-2">
                            <div class="col-md-8">
                                <a href="./?regiao=&estado=&cidade=&preset=2024">
                                <div class="card bg-secondary text-white py-2 px-3">
                                    <p class="h5 m-0"><cfoutput>#lsnumberFormat(qCountAnterior.total)# / #lsnumberFormat(qCountEvAnterior.total)# em 2024</cfoutput></p>
                                    <p class="m-0"><cfoutput>#lsnumberFormat(qCountAnterior.concluintes)# concluintes</cfoutput></p>
                                </div>
                                </a>
                            </div>
                            <div class="col-md-4 d-none d-md-block">
                                <a href="./?regiao=&estado=&cidade=&preset=2024">
                                    <div class="card bg-secondary text-white py-2 px-3">
                                        <p class="h5 m-0"><cfoutput>#Len(qCountAnterior.total) AND Len(qCountAnterior.concluintes)  ? lsnumberFormat(qCountAnterior.concluintes/qCountAnterior.total) : 0#</cfoutput></p>
                                        <p class="m-0"><cfoutput>Média</cfoutput></p>
                                    </div>
                                </a>
                            </div>
                        </div>
                    </div>

                <cfelse>

                    <!--- ATUAL --->

                    <div class="col-md-4">
                        <div class="row g-2">
                            <div class="col-4">
                                <a href="./?regiao=&estado=&cidade=&preset=2025">
                                    <div class="card <cfif preset EQ "2025">bg-warning<cfelse>bg-secondary</cfif> text-white py-2 px-3" >
                                        <p class="h5 m-0"><cfoutput>#lsnumberFormat(qCountInscritos.total)#</cfoutput></p>
                                        <p class="m-0"><cfoutput>MIF</cfoutput></p>
                                    </div>
                                </a>
                            </div>
                            <div class="col-4">
                                <a href="./?regiao=&estado=&cidade=&preset=saude">
                                    <div class="card <cfif preset EQ "saude">bg-danger<cfelse>bg-secondary</cfif> text-white py-2 px-3" >
                                        <p class="h5 m-0"><cfoutput>#lsnumberFormat(qCountFichasMedicas.total)#</cfoutput></p>
                                        <p class="m-0">Saúde</p>
                                    </div>
                                </a>
                            </div>
                            <div class="col-4">
                                <a href="./?regiao=&estado=&cidade=&preset=treinos">
                                    <div class="card <cfif preset EQ "treinos">bg-warning<cfelse>bg-secondary</cfif> text-white py-2 px-3" >
                                        <p class="h5 m-0"><cfoutput>#lsnumberFormat(qCountInscritosTreino.total)#</cfoutput></p>
                                        <p class="m-0">Treinos</p>
                                    </div>
                                </a>
                            </div>
                        </div>
                    </div>

                    <!--- TREINOS --->

                    <cfinclude template="../includes/backend/backend_treinao_core.cfm"/>

                    <div class="col-md-6">
                        <div class="row g-2">
                            <div class="col d-md-block d-none">
                                <a href="./?regiao=&estado=&cidade=&preset=treino1">
                                    <div class="card <cfif preset EQ "treino1">bg-warning<cfelse>bg-secondary</cfif> text-white py-2 px-3" >
                                        <p class="h5 m-0"><cfoutput>#lsnumberFormat(qCountTreino1.total)#</cfoutput></p>
                                        <p class="m-0"><cfoutput>Treino 1</cfoutput></p>
                                    </div>
                                </a>
                            </div>
                            <div class="col d-md-block d-none">
                                <a href="./?regiao=&estado=&cidade=&preset=treino2">
                                    <div class="card <cfif preset EQ "treino2">bg-warning<cfelse>bg-secondary</cfif> text-white py-2 px-3" >
                                        <p class="h5 m-0"><cfoutput>#lsnumberFormat(qCountTreino2.total)#</cfoutput></p>
                                        <p class="m-0"><cfoutput>Treino 2</cfoutput></p>
                                    </div>
                                </a>
                            </div>
                            <div class="col d-md-block d-none">
                                <a href="./?regiao=&estado=&cidade=&preset=treino3">
                                    <div class="card <cfif preset EQ "treino3">bg-warning<cfelse>bg-secondary</cfif> text-white py-2 px-3" >
                                        <p class="h5 m-0"><cfoutput>#lsnumberFormat(qCountTreino3.total)#</cfoutput></p>
                                        <p class="m-0"><cfoutput>Treino 3</cfoutput></p>
                                    </div>
                                </a>
                            </div>
                            <div class="col d-md-block d-none">
                                <a href="./?regiao=&estado=&cidade=&preset=treino4">
                                    <div class="card <cfif preset EQ "treino4">bg-warning<cfelse>bg-secondary</cfif> text-white py-2 px-3" >
                                        <p class="h5 m-0"><cfoutput>#lsnumberFormat(qCountTreino4.total)#</cfoutput></p>
                                        <p class="m-0"><cfoutput>Treino 4</cfoutput></p>
                                    </div>
                                </a>
                            </div>
                            <div class="col d-md-block d-none">
                                <a href="./?regiao=&estado=&cidade=&preset=treino5">
                                    <div class="card <cfif preset EQ "treino5">bg-warning<cfelse>bg-secondary</cfif> text-white py-2 px-3" >
                                        <p class="h5 m-0"><cfoutput>#lsnumberFormat(qCountTreino5.total)#</cfoutput></p>
                                        <p class="m-0"><cfoutput>Treino 5</cfoutput></p>
                                    </div>
                                </a>
                            </div>
                        </div>
                    </div>

                </cfif>

                <!--- HISTORICO --->

                <div class="<cfif URL.tag NEQ "maratona-internacional-de-floripa">col-md-4<cfelse>col-md-2</cfif> d-none d-md-block">
                    <a href="./?regiao=&estado=&cidade=&preset=">
                                <div class="card bg-black text-white py-2 px-3">
                                    <p class="h5 m-0"><cfoutput>#lsnumberFormat(qCountTotal.total)# / #lsnumberFormat(qCountEvTotal.total)# no total</cfoutput></p>
                                    <p class="m-0"><cfoutput>#lsnumberFormat(qCountTotal.concluintes)# concluintes</cfoutput></p>
                                </div>
                            </a>
                </div>

            </div>


            <!--- ABAS --->

            <!---ul class="nav nav-tabs nav-justified mb-3" id="ex1" role="tablist">
                <li class="nav-item" role="presentation">
                    <a
                            class="nav-link <cfif URL.preset EQ "2025">active</cfif> px-2"
                            href="./?regiao=&estado=&cidade=&preset=2025"
                            role="tab"
                            aria-selected="true"
                    >Inscrições</a>
                </li>
                <li class="nav-item" role="presentation">
                    <a
                            class="nav-link px-2 <cfif URL.preset EQ "treinos">active</cfif>"
                            href="./?regiao=&estado=&cidade=&preset=treinos"
                            role="tab"
                            aria-selected="false"
                    >Treinos</a>
                </li>
                <li class="nav-item" role="presentation" disabled="">
                    <a
                            class="nav-link px-2"
                            href="./?regiao=&estado=&cidade=&preset=resultados"
                            role="tab"
                            aria-selected="false"
                    >Resultados</a>
                </li>
                <li class="nav-item" role="presentation" disabled="">
                    <a
                            class="nav-link px-2"
                            href="./?regiao=&estado=&cidade=&preset=financeiro"
                            role="tab"
                            aria-selected="false"
                    >Financeiro</a>
                </li>
            </ul--->

                    <cfif qCountPeriodo.concluintes GT 0>

                        <!--- ESTATISTICAS DE RESULTADO --->

                        <div class="row g-2">


                            <!--- LISTAGEM DE REGIAO --->

                            <cfinclude template="../includes/parts/listagem_regioes.cfm"/>


                            <!--- LISTAGEM DE UF --->

                            <cfinclude template="../includes/parts/listagem_estados.cfm"/>


                            <!--- LISTAGEM DE CIDADE --->

                            <cfinclude template="../includes/parts/listagem_cidades.cfm"/>


                            <!--- LISTAGEM DE PERCURSOS --->

                            <div class="col-md-5">

                                <cfif qBi.tipo EQ "empresa">

                                    <cfinclude template="../includes/parts/listagem_ticketeiras.cfm"/>

                                <cfelse>

                                    <div class="card">

                                        <div class="card-header <cfif URL.preset EQ "2025">bg-warning<cfelseif URL.preset EQ "2024">bg-secondary<cfelse>bg-black</cfif> text-white fw-bold px-3 pt-2 pb-0">
                                            <h6 class="m0 p0">Percursos</h6>
                                        </div>

                                        <div class="card-body p-2">

                                            <div class="<cfif len(trim(URL.id_evento))>table-wrapper-sm<cfelse>table-wrapper-lg</cfif>">
                                                <table class="table table-stripped table-condensed table-sm mb-0">
                                                    <tbody>
                                                        <cfoutput query="qKilometragem">
                                                        <tr style="cursor: pointer;" <cfif qKilometragem.percurso EQ URL.percurso>class="table-active"  onclick="location.href = './?preset=#URL.preset#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#&id_evento=#URL.id_evento#'"<cfelse>onclick="location.href = './?preset=#URL.preset#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#&id_evento=#URL.id_evento#&percurso=#urlEncodedFormat(qKilometragem.percurso)#'"</cfif> >
                                                            <td width="10%" nowrap>#qKilometragem.modalidade#</td>
                                                            <cfif URL.id_evento EQ ""><td class="text-end">#qKilometragem.eventos#</td></cfif>
                                                            <td class="text-end">#qKilometragem.pace_medio#</td>
                                                            <td class="text-end">#qKilometragem.pace_medio_top_10#</td>
                                                            <cfif URL.id_evento EQ ""><td class="text-end">#lsNumberFormat(qKilometragem.concluintes)#</td></cfif>
                                                            <cfset VARIABLES.heat = 0/>
                                                            <cfif qTotalKilometragem.maximo - qTotalKilometragem.minimo GT 0>
                                                                <cfset VARIABLES.heat = (qKilometragem.media - qTotalKilometragem.minimo) / (qTotalKilometragem.maximo - qTotalKilometragem.minimo)/>
                                                                <cfset VARIABLES.heat = 0.2 + (VARIABLES.heat * 0.8)/>
                                                            </cfif>
                                                            <td class="text-end" style="background-color: rgba(255,200,0,#VARIABLES.heat#);">
                                                                #lsNumberFormat(qKilometragem.media)#
                                                            </td>
                                                            <td class="text-end">#lsNumberFormat((qKilometragem.concluintes*100)/qTotalKilometragem.concluintes, 9.9)#%</td>
                                                        </tr>
                                                        </cfoutput>
                                                    </tbody>
                                                </table>

                                            </div>

                                        </div>

                                    </div>

                                </cfif>

                            </div>


                            <!--- LISTAGEM DE EVENTOS --->

                            <div class="col-md-7">

                                <div class="card">

                                    <div class="card-header <cfif URL.preset EQ "2025">bg-warning<cfelseif URL.preset EQ "2024">bg-secondary<cfelse>bg-black</cfif> text-white fw-bold px-3 pt-2 pb-0">
                                        <h6 class="m0 p0">Eventos</h6>
                                    </div>

                                    <div class="card-body p-2">

                                        <div class="<cfif len(trim(URL.id_evento))>table-wrapper-sm<cfelse>table-wrapper-lg</cfif>">

                                            <cfinclude template="../includes/parts/listagem_eventos.cfm"/>

                                        </div>

                                    </div>

                                </div>

                            </div>


                            <!--- LISTAGEM DE CATEGORIAS --->

                            <cfif len(trim(URL.id_evento))>

                                <div class="col-md-12">
                                    <h3><cfoutput>#qEvento.nome_evento#</cfoutput> <cfif len(trim(URL.percurso))><img src="/assets/separador.png" height="32" class="me-2"/> <cfoutput>#URL.percurso#km</cfoutput></cfif></h3>
                                </div>

                                <div class="col-md-4">

                                    <div class="card">

                                        <div class="card-header <cfif URL.preset EQ "2025">bg-warning<cfelseif URL.preset EQ "2024">bg-secondary<cfelse>bg-black</cfif> text-white fw-bold px-3 py-2">
                                            <table class="m-0" width="98%">
                                                <tr>
                                                    <td width="40%">Feminino</td>
                                                    <td class="text-end">Pace</td>
                                                    <td class="text-end"><icon class="fa fa-users"></icon></td>
                                                    <td class="text-end">%</td>
                                                </tr>
                                            </table>
                                        </div>

                                        <div class="card-body p-2">

                                            <div class="table-wrapper">
                                                <table class="table table-stripped table-condensed table-sm mb-0">
                                                    <tbody>
                                                        <cfoutput query="qPerfilF">
                                                        <tr>
                                                            <td width="40%" nowrap>#qPerfilF.nome_categoria#</td>
                                                            <td class="text-end">#qPerfilF.pace_medio#</td>
                                                            <cfset VARIABLES.heat = 0/>
                                                            <cfif qTotalPerfilF.maximo - qTotalPerfilF.minimo GT 0>
                                                                <cfset VARIABLES.heat = (qPerfilF.concluintes - qTotalPerfilF.minimo) / (qTotalPerfilF.maximo - qTotalPerfilF.minimo)/>
                                                                <cfset VARIABLES.heat = 0.2 + (VARIABLES.heat * 0.8)/>
                                                            </cfif>
                                                            <td class="text-end" style="background-color: rgba(255,200,0,#VARIABLES.heat#);">
                                                                #lsNumberFormat(qPerfilF.concluintes)#
                                                            </td>
                                                            <td class="text-end">#lsNumberFormat((qPerfilF.concluintes*100)/qTotalPerfilF.concluintes, 9.9)#%</td>
                                                        </tr>
                                                        </cfoutput>
                                                    </tbody>
                                                </table>

                                            </div>

                                        </div>

                                    </div>


                                </div>

                                <div class="col-md-4">

                                    <div class="card">

                                        <div class="card-header <cfif URL.preset EQ "2025">bg-warning<cfelseif URL.preset EQ "2024">bg-secondary<cfelse>bg-black</cfif> text-white fw-bold px-3 py-2">
                                            <table class="m-0" width="98%">
                                                <tr>
                                                    <td width="40%">Masculino</td>
                                                    <td class="text-end">Pace</td>
                                                    <td class="text-end"><icon class="fa fa-users"></icon></td>
                                                    <td class="text-end">%</td>
                                                </tr>
                                            </table>
                                        </div>

                                        <div class="card-body p-2">

                                            <div class="table-wrapper">
                                                <table class="table table-stripped table-condensed table-sm mb-0">
                                                    <tbody>
                                                        <cfoutput query="qPerfilM">
                                                        <tr>
                                                            <td width="40%" nowrap>#qPerfilM.nome_categoria#</td>
                                                            <td class="text-end">#qPerfilM.pace_medio#</td>
                                                            <cfset VARIABLES.heat = 0/>
                                                            <cfif qTotalPerfilM.maximo - qTotalPerfilM.minimo GT 0>
                                                                <cfset VARIABLES.heat = (qPerfilM.concluintes - qTotalPerfilM.minimo) / (qTotalPerfilM.maximo - qTotalPerfilM.minimo)/>
                                                                <cfset VARIABLES.heat = 0.2 + (VARIABLES.heat * 0.8)/>
                                                            </cfif>
                                                            <td class="text-end" style="background-color: rgba(255,200,0,#VARIABLES.heat#);">
                                                                #lsNumberFormat(qPerfilM.concluintes)#
                                                            </td>
                                                            <td class="text-end">#lsNumberFormat((qPerfilM.concluintes*100)/qTotalPerfilM.concluintes, 9.9)#%</td>
                                                        </tr>
                                                        </cfoutput>
                                                    </tbody>
                                                </table>

                                            </div>

                                        </div>

                                    </div>


                                </div>

                                <div class="col-md-4">

                                    <div class="card">

                                        <div class="card-header <cfif URL.preset EQ "2025">bg-warning<cfelseif URL.preset EQ "2024">bg-secondary<cfelse>bg-black</cfif> text-white fw-bold px-3 py-2">
                                            <table class="m-0" width="98%">
                                                <tr>
                                                    <td width="40%">PCD</td>
                                                    <td class="text-end">Gênero</td>
                                                    <td class="text-end">Pace</td>
                                                    <td class="text-end"><icon class="fa fa-users"></icon></td>
                                                </tr>
                                            </table>
                                        </div>

                                        <div class="card-body p-2">

                                            <div class="table-wrapper">
                                                <table class="table table-stripped table-condensed table-sm mb-0">
                                                    <tbody>
                                                        <cfoutput query="qPerfilPCD">
                                                        <tr>
                                                            <td width="40%" nowrap>#qPerfilPCD.nome_categoria#</td>
                                                            <td class="text-end">#qPerfilPCD.sexo#</td>
                                                            <td class="text-end">#qPerfilPCD.pace_medio#</td>
                                                            <td class="text-end">#lsNumberFormat(qPerfilPCD.concluintes)#</td>
                                                        </tr>
                                                        </cfoutput>
                                                    </tbody>
                                                </table>
                                            </div>

                                        </div>

                                    </div>

                                </div>

                                <!---div class="col-md-4">

                                    <div class="card">

                                        <div class="card-header <cfif URL.preset EQ "2025">bg-warning<cfelseif URL.preset EQ "2024">bg-secondary<cfelse>bg-black</cfif> text-white fw-bold px-3 py-2">
                                            <table class="m-0" width="98%">
                                                <tr>
                                                    <td width="40%">PCD</td>
                                                    <td class="text-end">Gênero</td>
                                                    <td class="text-end">Pace</td>
                                                    <td class="text-end"><icon class="fa fa-users"></icon></td>
                                                </tr>
                                            </table>
                                        </div>

                                        <div class="card-body p-2">

                                            <cfdump var="#qAcessosRR#"/>

                                            <div class="table-wrapper">
                                                <table class="table table-stripped table-condensed table-sm mb-0">
                                                    <tbody>
                                                        <cfoutput query="qPerfilPCD">
                                                        <tr>
                                                            <td width="40%" nowrap>#qPerfilPCD.nome_categoria#</td>
                                                            <td class="text-end">#qPerfilPCD.sexo#</td>
                                                            <td class="text-end">#qPerfilPCD.pace_medio#</td>
                                                            <td class="text-end">#lsNumberFormat(qPerfilPCD.concluintes)#</td>
                                                        </tr>
                                                        </cfoutput>
                                                    </tbody>
                                                </table>

                                            </div>

                                        </div>

                                    </div--->

                            </cfif>

                        </div>

                    <cfelseif URL.tag EQ "maratona-internacional-de-floripa">

                            <!--- DADOS PRINCIPAIS --->

                            <cfif URL.preset EQ "2025">

                                <!--- ESTATISTICAS DE INSCRICOES --->

                                <cfinclude template="../includes/backend/backend_inscritos.cfm"/>
                                <cfinclude template="inscritos.cfm"/>

                            </cfif>

                            <!--- TREINAO --->

                            <cfif URL.preset CONTAINS "treino">

                                <!--- ESTATISTICAS DE TREINOS --->

                                <cfinclude template="../includes/backend/backend_treinao.cfm"/>
                                <cfinclude template="treinao.cfm"/>

                            </cfif>

                            <!--- SAUDE --->

                            <cfif URL.preset CONTAINS "saude">

                                <!--- ESTATISTICAS DE SAUDE --->

                                <cfinclude template="../includes/backend/backend_saude.cfm"/>
                                <cfinclude template="saude.cfm"/>

                            </cfif>


                    <cfelse>

                        <p>Sem resultados para o período.</p>

                    </cfif>

                </div>

        </div>

    </cfif>

    <cfinclude template="../includes/footer_parceiro.cfm"/>

    <cfinclude template="../includes/seo-web-tools-body-end.cfm"/>

</body>

</html>
