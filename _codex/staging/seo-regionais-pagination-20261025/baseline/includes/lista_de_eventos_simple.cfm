<!--- GARANTE O USUARIO DA REQUISICAO PARA ACOES DE AGENDA E RESULTADO --->

<cfif structKeyExists(REQUEST, "Usuario")>
    <cfset Usuario = REQUEST.Usuario/>
<cfelse>
    <cfset Usuario = createObject("component", "includes.models.Usuario").init()/>
    <cfset REQUEST.Usuario = Usuario/>
</cfif>

<cfparam name="URL.page" default="0"/>
<cfparam name="URL.lastMonth" default="0"/>
<cfparam name="VARIABLES.eventListRenderAllRows" type="boolean" default="false"/>

<!--- MONTA O CAMINHO DE RETORNO PARA A AGENDA DO ATLETA --->
<cfset VARIABLES.eventListAgendaRedirectPath = "/agenda/" />

<cfif isDefined("qPagina.tag") AND len(trim(qPagina.tag)) AND structKeyExists(REQUEST, "i18nBuildPath")>
    <cfset VARIABLES.eventListCurrentRouteParams = structKeyExists(REQUEST, "currentRouteParams") AND isStruct(REQUEST.currentRouteParams) ? duplicate(REQUEST.currentRouteParams) : structNew() />
    <cfset VARIABLES.eventListRouteParams = duplicate(VARIABLES.eventListCurrentRouteParams) />
    <cfset VARIABLES.eventListRouteParams["tag"] = trim(qPagina.tag) />
    <cfset REQUEST.currentRouteParams = VARIABLES.eventListRouteParams />
    <cfset VARIABLES.eventListAgendaRedirectPath = REQUEST.i18nBuildPath("athlete") & "?filtro=agenda" />
    <cfset REQUEST.currentRouteParams = VARIABLES.eventListCurrentRouteParams />
<cfelseif isDefined("qPagina.tag_prefix") AND isDefined("qPagina.tag")>
    <cfset VARIABLES.eventListAgendaRedirectPath = "/#qPagina.tag_prefix#/#qPagina.tag#/?filtro=agenda" />
</cfif>


<!--- CALCULA A PAGINACAO DO BLOCO CARREGADO VIA AJAX --->

<cfset VARIABLES.eventListPageSize = VARIABLES.eventListRenderAllRows ? qEventosAba.recordcount : VARIABLES.pageSize/>
<cfset VARIABLES.startRow = VARIABLES.eventListRenderAllRows ? 1 : ((URL.page GT 0) ? (URL.page * VARIABLES.pageSize)+1 : 1)/>

<div class="row g-2" id="listaEvento">

<!--- LISTA OS EVENTOS OU RESULTADOS JA FILTRADOS PELO BACKEND --->

<cfoutput query="qEventosAba" startrow="#VARIABLES.startRow#" maxrows="#VARIABLES.eventListPageSize#">

    <!--- DEFINE O LINK DO CARD COM A TAG DO EVENTO QUANDO ELA EXISTE --->
    <cfset VARIABLES.eventListEventTag = isDefined("tag") ? trim(tag) : "" />
    <cfif len(VARIABLES.eventListEventTag) AND structKeyExists(REQUEST, "i18nBuildPath")>
        <cfset VARIABLES.eventListCurrentRouteParams = structKeyExists(REQUEST, "currentRouteParams") AND isStruct(REQUEST.currentRouteParams) ? duplicate(REQUEST.currentRouteParams) : structNew() />
        <cfset VARIABLES.eventListRouteParams = duplicate(VARIABLES.eventListCurrentRouteParams) />
        <cfset VARIABLES.eventListRouteParams["tag"] = VARIABLES.eventListEventTag />
        <cfset REQUEST.currentRouteParams = VARIABLES.eventListRouteParams />
        <cfset VARIABLES.eventListDetailPath = REQUEST.i18nBuildPath("event") />
        <cfset REQUEST.currentRouteParams = VARIABLES.eventListCurrentRouteParams />
    <cfelseif len(VARIABLES.eventListEventTag)>
        <cfset VARIABLES.eventListDetailPath = "/evento/#VARIABLES.eventListEventTag#/" />
    <cfelse>
        <cfset VARIABLES.eventListDetailPath = "/evento/" />
    </cfif>

    <cfset VARIABLES.eventListDetailAbsoluteUrl = REQUEST.currentBaseUrl & VARIABLES.eventListDetailPath />

    <cfif VARIABLES.template NEQ "/atleta/" AND VARIABLES.template NEQ "/agenda/" AND VARIABLES.template NEQ "/resultados/">

        <!--- CALCULA O MES USADO COMO DIVISOR VISUAL DA LISTA --->

        <cfset mes = lsdateFormat(data_final, "mmmm")/>

        <!--- EXIBE O DIVISOR DE MES APENAS QUANDO O MES MUDA --->

        <cfif URL.lastMonth NEQ month>
            <!---<h4 class="mb-0">#mes#</h4>--->
            <div class="text-divider fw-bold mt-2">#mes#</div>
        </cfif>

    </cfif>


    <!--- RENDERIZA O CARD UNICO DO EVENTO OU RESULTADO --->

        <cfset VARIABLES.eventListIsAthleteResult = (VARIABLES.template EQ "/atleta/" OR VARIABLES.template EQ "/resultados/")
            AND isDefined("VARIABLES.tipoListagem")
            AND VARIABLES.tipoListagem EQ "resultado"/>
        <cfif VARIABLES.eventListIsAthleteResult>
            <div class="athlete-result-list-item" data-result-distance="#encodeForHTMLAttribute(trim(percurso & ""))#">
        </cfif>

        <cfinclude template="card_evento_individual.cfm"/>

        <cfif VARIABLES.eventListIsAthleteResult>
            </div>
        </cfif>


    <!--- RENDERIZA A BARRA DE ACOES USADA EM AGENDA, ATLETA E RESULTADOS --->

    <cfif VARIABLES.template EQ "/atleta/" OR VARIABLES.template EQ "/agenda/" OR VARIABLES.template EQ "/resultados/">

        <div class="row g-2 m-0 mt-1 p-0 d-none">

            <!--- DIRECIONA PARA O RESULTADO OFICIAL QUANDO O EVENTO JA TEM CRONOMETRAGEM --->

            <cfif isDefined("lista_percursos_resultado")>

                <div class="col-6 <cfif Usuario.logado AND qPagina.id_usuario_cadastro EQ Usuario.id>col-sm-4<cfelse>col-sm-6</cfif> mb-2 mt-0">
                    <button type="button" onclick="location.href='https://openresults.run/evento/#tag#/'" class="btn btn-light w-100 shadow-0" data-mdb-ripple-init><i class="fa-solid fa-list"></i> <cfoutput>#REQUEST.t("search.eventList.results")#</cfoutput></button>
                </div>


            <!--- MOSTRA ACOES DE AGENDA QUANDO AINDA NAO HA RESULTADO OFICIAL --->

            <cfelse>

                <div class="col-12 col-sm-6 mb-2 mt-0">

                    <!--- ACOES QUE SERIAM EXIBIDAS NA PAGINA DO PROPRIO ATLETA --->

                    <!---<cfif Usuario.logado AND qPagina.id_usuario_cadastro EQ Usuario.id>--->

                        <!---<div class="dropdown">
                            <button class="btn btn-secondary dropdown-toggle w-100 shadow-0"
                                    type="button"
                                    id="dropdownMenuButton"
                                    data-mdb-dropdown-init
                                    data-mdb-ripple-init
                                    aria-expanded="false">
                                <cfif qEventosAba.tipo_checkin EQ "inscricao">PRESENÇA CONFIRMADA</cfif>&nbsp;|&nbsp;
                                Ações
                            </button>
                            <ul class="dropdown-menu" aria-labelledby="dropdownMenuButton">
                                <cfif qEventosAba.tipo_checkin EQ "inscricao">
                                    <li><a class="dropdown-item" href="/evento/#tag#/?acao=calendario&redirecionar=/#qPagina.tag_prefix#/#qPagina.tag#/?filtro=agenda">Remover Presença (Agenda Pública)</a></li>
                                <cfelse>
                                    <li><a class="dropdown-item" href="/evento/#tag#/?acao=inscricao&redirecionar=/#qPagina.tag_prefix#/#qPagina.tag#/?filtro=agenda">Marcar Presença (Agenda Pública)</a></li>
                                </cfif>
                                <li><hr class="dropdown-divider m-0" /></li>
                                <li><a class="dropdown-item" href="/evento/#tag#/?acao=remover&redirecionar=/#qPagina.tag_prefix#/#qPagina.tag#/?filtro=agenda">Remover da Agenda</a></li>
                                <li><a class="dropdown-item" href="http://www.google.com/calendar/render?action=TEMPLATE&text=#nome_evento#&dates=#DateFormat(data_inicial,"yyyymmdd")#/#DateFormat(data_final,"yyyymmdd")#&details=Acesse:+https://roadrunners.run/evento/#tag#/&location=#cidade#,+#estado#,+#pais#&trp=false&sprop=&sprop=https://roadrunners.run/name:Road+Runners" target="_blank">Adicionar ao Google Agenda</a></li>
                                <li><span class="dropdown-item opacity-50">Adicionar Cupom</span></li>
                            </ul>
                        </div>--->

                    <!--- ACOES QUE SERIAM EXIBIDAS AO VISITAR OUTRO ATLETA --->

                    <!---<cfelse>--->

                        <!---<div class="dropdown">
                            <button class="btn <cfif qEventosAba.tipo_checkin EQ "inscricao">btn-primary<cfelse>btn-secondary</cfif> dropdown-toggle w-100 shadow-0"
                                    type="button"
                                    id="dropdownMenuButton"
                                    data-mdb-dropdown-init
                                    data-mdb-ripple-init
                                    aria-expanded="false">
                                Ações
                            </button>
                            <ul class="dropdown-menu" aria-labelledby="dropdownMenuButton">
                                <li><a class="dropdown-item" href="/evento/#tag#/?acao=calendario&redirecionar=/#qPagina.tag_prefix#/#qPagina.tag#/?filtro=agenda">Adicionar à minha agenda</a></li>
                                <li><hr class="dropdown-divider m-0" /></li>
                                <li><span class="dropdown-item opacity-50"><i class="fa-solid fa-hand-fist"></i> Desafiar</span></li>
                            </ul>
                        </div>--->

                    <!---</cfif>--->

                    <div class="d-flex btn-group shadow-0 d-none">
                        <cfif Usuario.logado AND qPagina.id_usuario_cadastro EQ Usuario.id>
                            <!--- ACOES DO DONO DO PERFIL --->
                            <button type="button" onclick="location.href='#VARIABLES.eventListDetailPath#?acao=calendario&<cfif VARIABLES.template EQ "/perfil/">perfil<cfelse>team</cfif>'" style="width: 40%" class="btn btn-light <cfif qEventosAba.tipo_checkin EQ "calendario">active</cfif>" data-mdb-ripple-init>
                                <cfif qEventosAba.tipo_checkin EQ "calendario"><icon class="fa-solid fa-bookmark"></icon><cfelse><i class="fa-regular fa-bookmark"></i></cfif> <cfoutput>#REQUEST.t("search.eventList.wantToGo")#</cfoutput>
                            </button>
                            <button type="button" onclick="location.href='#VARIABLES.eventListDetailPath#?acao=inscricao&<cfif VARIABLES.template EQ "/perfil/">perfil<cfelse>team</cfif>'" style="width: 40%" class="btn btn-light <cfif qEventosAba.tipo_checkin EQ "inscricao">active</cfif>" data-mdb-ripple-init>
                                <cfif qEventosAba.tipo_checkin EQ "inscricao"><i class="fa-solid fa-square-check"></i><cfelse><i class="fa-regular fa-square-check"></i></cfif> <cfoutput>#REQUEST.t("search.eventList.registered")#</cfoutput>
                            </button>
                            <button type="button" onclick="location.href='#VARIABLES.eventListDetailPath#?acao=remover&<cfif VARIABLES.template EQ "/perfil/">perfil<cfelse>team</cfif>'" style="width: 16%" class="btn btn-light" data-mdb-ripple-init>
                                <icon class="fa fa-trash"></icon>
                            </button>
                        <cfelse>
                            <!--- ACOES DE DESAFIO PARA OUTROS PERFIS --->
                            <button type="button" onclick="location.href='#VARIABLES.eventListDetailPath#?acao=calendario&<cfif VARIABLES.template EQ "/perfil/">perfil<cfelse>team</cfif>'" style="width: 40%" class="btn btn-light <cfif qEventosAba.tipo_checkin EQ "calendario">active</cfif>" data-mdb-ripple-init>
                                <i class="fa-solid fa-hand-fist"></i> <cfoutput>#REQUEST.t("search.eventList.challenge")#</cfoutput>
                            </button>
                            <button type="button" onclick="location.href='#VARIABLES.eventListDetailPath#?acao=inscricao&<cfif VARIABLES.template EQ "/perfil/">perfil<cfelse>team</cfif>'" style="width: 40%" class="btn btn-light <cfif qEventosAba.tipo_checkin EQ "inscricao">active</cfif>" data-mdb-ripple-init>
                                <i class="fa-regular fa-hand"></i> <cfoutput>#REQUEST.t("search.eventList.leaveChallenge")#</cfoutput>
                            </button>
                        </cfif>
                    </div>

                </div>

            </cfif>

            <cfif isDefined("lista_percursos_resultado") AND isDefined("qEventosAba.badges") AND Len(trim(qEventosAba.badges)) AND (Usuario.logado AND qPagina.id_usuario_cadastro EQ Usuario.id)>

                <div class="col-6 mb-2 mt-0">

                    <cfset VARIABLES.badgeFoco = ""/>

                    <cfloop array="#deserializeJSON(qEventosAba.badges)#" item="badge">
                        <cfif badge.badge EQ "foco">
                            <cfset VARIABLES.badgeFoco = badge/>
                        </cfif>
                    </cfloop>

                    <cfif isStruct(VARIABLES.badgeFoco)>
                        <button type="button" class="btn btn-light w-100 shadow-0"
                                data-mdb-ripple-init
                                data-mdb-valor-badge="#VARIABLES.badgeFoco.valor_badge#"
                                data-mdb-numero-peito="#qCorridasAtleta.num_peito#"
                                data-mdb-complemento-badge="#isDefined("VARIABLES.badgeFoco.complemento_badge") ? VARIABLES.badgeFoco.complemento_badge : 'numero'#"
                                data-mdb-modal-init
                                data-mdb-target="##modal_cupom_foco"
                                title="#VARIABLES.badgeFoco.valor_badge# | #isDefined("VARIABLES.badgeFoco.complemento_badge") ? VARIABLES.badgeFoco.complemento_badge : 'numero'# #qCorridasAtleta.num_peito#">
                                <i class="fa-solid fa-camera"></i> <cfoutput>#REQUEST.t("search.eventList.photos")#</cfoutput>
                        </button>

                    <cfelse>

                        <button type="button" class="btn w-100 shadow-0 disabled">
                            <i class="fa-solid fa-camera"></i> <cfoutput>#REQUEST.t("search.eventList.photos")#</cfoutput>
                        </button>

                    </cfif>

                </div>

            </cfif>


        </div>

        <!---<hr class="my-2">--->

    </cfif>


    <!--- ATUALIZA O MES DA ULTIMA LINHA PARA EVITAR DIVISORES REPETIDOS --->

    <cfset URL.lastMonth = month/>

</cfoutput>

<cfif qEventosAba.recordcount EQ 0 AND isDefined("VARIABLES.template") AND VARIABLES.template EQ "/busca/">
    <cfscript>
        // MONTA A MENSAGEM SEM RESULTADOS USANDO O TERMO REAL DA BUSCA
        VARIABLES.buscaListaTermoVazio = "";
        VARIABLES.buscaListaTermoDisplay = "";
        VARIABLES.buscaListaTermoPalavras = [];
        buscaListaPalavra = "";

        if (isDefined("URL.busca") && len(trim(URL.busca))) {
            VARIABLES.buscaListaTermoVazio = trim(URL.busca);
        } else if (isDefined("URL.termo") && len(trim(URL.termo))) {
            VARIABLES.buscaListaTermoVazio = trim(URL.termo);
        }

        for (buscaListaPalavra in listToArray(lCase(VARIABLES.buscaListaTermoVazio), " ")) {
            if (len(trim(buscaListaPalavra))) {
                arrayAppend(
                    VARIABLES.buscaListaTermoPalavras,
                    uCase(left(buscaListaPalavra, 1)) & mid(buscaListaPalavra, 2, len(buscaListaPalavra))
                );
            }
        }

        VARIABLES.buscaListaTermoDisplay = arrayToList(VARIABLES.buscaListaTermoPalavras, " ");
        if (lCase(trim(URL.busca_tipo)) EQ "resultados") {
            VARIABLES.buscaListaMensagemVazia = len(VARIABLES.buscaListaTermoDisplay)
                ? REQUEST.t("search.sections.noResultsForTerm", { "term" = VARIABLES.buscaListaTermoDisplay })
                : REQUEST.t("search.sections.noResults");
        } else {
            VARIABLES.buscaListaMensagemVazia = len(VARIABLES.buscaListaTermoDisplay)
                ? REQUEST.t("search.sections.noEventsForTerm", { "term" = VARIABLES.buscaListaTermoDisplay })
                : REQUEST.t("search.sections.noEvents");
        }
    </cfscript>
    <div class="col-12">
        <div class="home-feedback-card p-3" data-busca-total="0"><cfoutput>#encodeForHTML(VARIABLES.buscaListaMensagemVazia)#</cfoutput></div>
    </div>
</cfif>

</div>

<!--- EXPÕE TOTAIS PARA A PAGINACAO E OS BADGES DA INTERFACE --->

<script>
    totalEventos = <cfoutput>#qEventos.recordcount#</cfoutput>;
    lastMonth = <cfoutput>#URL.lastMonth#</cfoutput>;
</script>
