<cfprocessingdirective pageencoding="utf-8"/>

<!--- TEMPLATE --->
<cfset VARIABLES.template = "/estado/"/>

<!--- TAG PARAM TREAT --->
<cfparam name="URL.tag" default=""/>
<cfset URL.tag = ucase(trim(replace(URL.tag, '/', '')))/>

<cfif NOT listFindNoCase("AC,AL,AM,AP,BA,CE,DF,ES,GO,MA,MG,MS,MT,PA,PB,PE,PI,PR,RJ,RN,RO,RR,RS,SC,SE,SP,TO",URL.tag)>
    <cfheader statuscode="404" statustext="Not Found"/><cfcontent type="text/plain; charset=utf-8" reset="true"/>Estado não encontrado.<cfabort/>
</cfif>

<!--- BACKEND --->
<cfinclude template="../includes/variaveis.cfm"/>
<cfinclude template="../includes/backend.cfm"/>
<cfinclude template="../includes/backend_estado_cidades.cfm"/>

<!--- META INFO --->
<cfset VARIABLES.canonical = "#APPLICATION.baseCanonica##VARIABLES.template##URL.tag##Len(trim(URL.tag)) ? '/' : ''##VARIABLES.queryString#"/>
<cfset VARIABLES.title = encodeForHTML("Eventos por estado: " & URL.tag & " - " & APPLICATION.nomeSite)/>
<cfset VARIABLES.description = "Resultados de eventos de corrida por estado"/>
<cfif len(VARIABLES.estadoCidadeSlug)>
    <cfset VARIABLES.title = encodeForHTML("Resultados de corridas em " & VARIABLES.estadoCidadeNome & " (" & URL.tag & ") - " & APPLICATION.nomeSite)/>
</cfif>
<cfset VARIABLES.keywords = "resultados, corrida, competição, pódio, atletas, corredores"/>

<!doctype html>
<html lang="pt-br">

<!--- HEAD --->
<cfinclude template="../includes/head.cfm"/>

<body>

    <link rel="stylesheet" href="/assets/css/openresults-estado-cidades.css?v=20261004-1"/>

    <!--- SEO WEB TOOLS --->

    <cfinclude template="../includes/seo-web-tools-body-start.cfm"/>


    <!--- CONTAINER DE CONTEUDO --->

    <div class="container">


        <!--- HEADER --->

        <cfinclude template="../includes/header.cfm"/>

        <!--- STATS --->

        <!---<cfinclude template="../includes/estatisticas_quadro.cfm"/>--->
        <div class="d-block d-md-none col-12 mb-3">
        <div class="card bg-transparent">
        <div class="card-header pt-1 pb-0 fw-bold text-center"><span class="h5">2024 - Dados consolidados<cfif VARIABLES.template EQ "/estado/"> - <cfoutput>#URL.tag#</cfoutput></cfif></span></div>
        <table class="table table-sm table-striped mb-0 bg-transparent">
            <tr>
                <td class="px-2 pt-1 pb-0"></td>
                <td class="px-2 pt-1 pb-0 text-center"><img src="/assets/rh_icon_fem.png" width="14" style="margin-top: -4px"/></td>
                <td class="px-2 pt-1 pb-0 text-center"><img src="/assets/rh_icon_masc.png" width="14" style="margin-top: -4px"/></td>
                <td class="px-2 pt-1 pb-0 text-end"><img src="/assets/eventos.png" width="14" style="margin-top: -4px"/></td>
                <td class="px-2 pt-1 pb-0 text-center"><img src="/assets/runners.png" width="14" style="margin-top: -4px"/></td>
            </tr>
        <cfoutput>
            <cfif qStats5.recordcount>
                    <tr class="kms k5" data-color="5" style="font-size: small !important;">
                        <td class="px-1 pt-1 pb-0 bg-transparent text-end">5K</td>
                    <td class="mono pt-1 pb-0 bg-transparent text-end">#lsNumberFormat(qStats5.concluintes[1])#</td>
                <td class="mono pt-1 pb-0 bg-transparent text-end">#lsNumberFormat(qStats5.concluintes[2])#</td>
                <td class="mono pt-1 pb-0 bg-transparent text-end">#qStats5.eventos[1]#</td>
                <td class="mono pt-1 pb-0 bg-transparent text-end pe-3">#lsNumberFormat(qStats5.concluintes[1]+qStats5.concluintes[2])#</td>
                </tr>
            </cfif>
            <cfif qStats10.recordcount>
                    <tr class="kms k10" data-color="10" style="font-size: small !important;">
                        <td class="px-1 pt-1 pb-0 bg-transparent text-end">10K</td>
                    <td class="mono pt-1 pb-0 bg-transparent text-end">#lsNumberFormat(qStats10.concluintes[1])#</td>
                <td class="mono pt-1 pb-0 bg-transparent text-end">#lsNumberFormat(qStats10.concluintes[2])#</td>
                <td class="mono pt-1 pb-0 bg-transparent text-end">#qStats10.eventos[1]#</td>
                <td class="mono pt-1 pb-0 bg-transparent text-end pe-3">#lsNumberFormat(qStats10.concluintes[1]+qStats10.concluintes[2])#</td>
                </tr>
            </cfif>
            <cfif qStats21.recordcount>
                    <tr class="kms k21" data-color="21" style="font-size: small !important;">
                        <td class="px-1 pt-1 pb-0 bg-transparent text-end">21K</td>
                    <td class="mono pt-1 pb-0 bg-transparent text-end">#lsNumberFormat(qStats21.concluintes[1])#</td>
                <td class="mono pt-1 pb-0 bg-transparent text-end">#lsNumberFormat(qStats21.concluintes[2])#</td>
                <td class="mono pt-1 pb-0 bg-transparent text-end">#qStats21.eventos[1]#</td>
                <td class="mono pt-1 pb-0 bg-transparent text-end pe-3">#lsNumberFormat(qStats21.concluintes[1]+qStats21.concluintes[2])#</td>
                </tr>
            </cfif>
            <cfif qStats42.recordcount>
                    <tr class="kms k42" data-color="42" style="font-size: small !important;">
                        <td class="px-1 pt-1 pb-0 bg-transparent text-end">42K</td>
                    <td class="mono pt-1 pb-0 bg-transparent text-end">#lsNumberFormat(qStats42.concluintes[1])#</td>
                <td class="mono pt-1 pb-0 bg-transparent text-end">#lsNumberFormat(qStats42.concluintes[2])#</td>
                <td class="mono pt-1 pb-0 bg-transparent text-end">#qStats42.eventos[1]#</td>
                <td class="mono pt-1 pb-0 bg-transparent text-end pe-3">#lsNumberFormat(qStats42.concluintes[1]+qStats42.concluintes[2])#</td>
                </tr>
            </cfif>
        </cfoutput>
        </table>
        </div>
        </div>

        <!--- CONTEUDO --->

        <div class="row g-3 pt-4">

            <!--- LISTA DE EVENTOS DE CORRIDA --->

            <div class="col-lg-9">

                <!--- ESTADO SELECIONADO --->

                <cfif isDefined("URL.tag")>
                    <cfset VARIABLES.estadoFiltroQueryString = len(trim(URL.filtro)) ? "?filtro=#urlEncodedFormat(URL.filtro)#" : ""/>
                    <div class="or-ranking-year-row or-state-city-row mb-3">
                        <h1 class="or-ranking-year-title mb-0">Eventos em</h1>
                        <div class="or-search-chip-select-wrap">
                            <i class="fa-solid fa-location-dot or-search-chip-select-icon"></i>
                            <select class="or-search-chip or-search-chip-select or-ranking-year-select"
                                    aria-label="Selecionar estado"
                                    data-estado-state-select>
                                <option value="ac" <cfif URL.tag EQ "AC">selected</cfif>>Acre</option>
                                <option value="al" <cfif URL.tag EQ "AL">selected</cfif>>Alagoas</option>
                                <option value="am" <cfif URL.tag EQ "AM">selected</cfif>>Amazonas</option>
                                <option value="ap" <cfif URL.tag EQ "AP">selected</cfif>>Amapá</option>
                                <option value="ba" <cfif URL.tag EQ "BA">selected</cfif>>Bahia</option>
                                <option value="ce" <cfif URL.tag EQ "CE">selected</cfif>>Ceará</option>
                                <option value="df" <cfif URL.tag EQ "DF">selected</cfif>>Distrito Federal</option>
                                <option value="es" <cfif URL.tag EQ "ES">selected</cfif>>Espírito Santo</option>
                                <option value="go" <cfif URL.tag EQ "GO">selected</cfif>>Goiás</option>
                                <option value="ma" <cfif URL.tag EQ "MA">selected</cfif>>Maranhão</option>
                                <option value="mg" <cfif URL.tag EQ "MG">selected</cfif>>Minas Gerais</option>
                                <option value="ms" <cfif URL.tag EQ "MS">selected</cfif>>Mato Grosso do Sul</option>
                                <option value="mt" <cfif URL.tag EQ "MT">selected</cfif>>Mato Grosso</option>
                                <option value="pa" <cfif URL.tag EQ "PA">selected</cfif>>Pará</option>
                                <option value="pb" <cfif URL.tag EQ "PB">selected</cfif>>Paraíba</option>
                                <option value="pe" <cfif URL.tag EQ "PE">selected</cfif>>Pernambuco</option>
                                <option value="pi" <cfif URL.tag EQ "PI">selected</cfif>>Piauí</option>
                                <option value="pr" <cfif URL.tag EQ "PR">selected</cfif>>Paraná</option>
                                <option value="rj" <cfif URL.tag EQ "RJ">selected</cfif>>Rio de Janeiro</option>
                                <option value="rn" <cfif URL.tag EQ "RN">selected</cfif>>Rio Grande do Norte</option>
                                <option value="ro" <cfif URL.tag EQ "RO">selected</cfif>>Rondônia</option>
                                <option value="rr" <cfif URL.tag EQ "RR">selected</cfif>>Roraima</option>
                                <option value="rs" <cfif URL.tag EQ "RS">selected</cfif>>Rio Grande do Sul</option>
                                <option value="sc" <cfif URL.tag EQ "SC">selected</cfif>>Santa Catarina</option>
                                <option value="se" <cfif URL.tag EQ "SE">selected</cfif>>Sergipe</option>
                                <option value="sp" <cfif URL.tag EQ "SP">selected</cfif>>São Paulo</option>
                                <option value="to" <cfif URL.tag EQ "TO">selected</cfif>>Tocantins</option>
                            </select>
                            <i class="fa-solid fa-chevron-down or-search-chip-select-caret"></i>
                        </div>
                        <details class="estado-city-picker" data-estado-city-picker>
                            <summary><i class="fa-solid fa-city" aria-hidden="true"></i><span><cfoutput>Cidade: <cfif len(VARIABLES.estadoCidadeSlug)>#encodeForHTML(VARIABLES.estadoCidadeNome)#<cfelse>Todas as cidades</cfif></cfoutput></span><i class="fa-solid fa-chevron-down" aria-hidden="true"></i></summary>
                            <div class="estado-city-picker-panel">
                                <label class="estado-city-picker-label" for="estado-city-search">Buscar cidade</label>
                                <input type="search" id="estado-city-search" placeholder="Digite o nome da cidade" autocomplete="off"/>
                                <p class="estado-city-picker-hint">Contagens conforme os filtros da lista. Em Maiores, até 20 eventos por seleção.</p>
                                <div class="estado-city-picker-list">
                                    <a class="estado-city-picker-item" data-estado-city-slug="" data-estado-city-name="Todas as cidades" href="<cfoutput>#encodeForHTMLAttribute(REQUEST.estadoCityUrl(""))#</cfoutput>"<cfif NOT len(VARIABLES.estadoCidadeSlug)> aria-current="page"</cfif>><span>Todas as cidades</span><span data-city-count><cfoutput>#VARIABLES.estadoCitiesTotal#</cfoutput> eventos</span></a>
                                    <cfoutput query="qEstadoCidades">
                                        <a class="estado-city-picker-item" data-estado-city-slug="#encodeForHTMLAttribute(tag_cidade)#" data-estado-city-name="#encodeForHTMLAttribute(cidade)#"<cfif total_eventos GT 0 OR VARIABLES.estadoCidadeSlug EQ tag_cidade> href="#encodeForHTMLAttribute(REQUEST.estadoCityUrl(tag_cidade))#" aria-disabled="false"<cfelse> aria-disabled="true" tabindex="-1"</cfif><cfif VARIABLES.estadoCidadeSlug EQ tag_cidade> aria-current="page"</cfif>><span>#encodeForHTML(cidade)#</span><span data-city-count>#total_eventos# <cfif total_eventos EQ 1>evento<cfelse>eventos</cfif></span></a>
                                    </cfoutput>
                                </div>
                                <p class="estado-city-picker-status" data-estado-city-status role="status" aria-live="polite"></p>
                            </div>
                        </details>
                    </div>
                </cfif>

                <!--- ABAS --->

                <nav class="mt-0">
                    <div class="nav nav-tabs" id="nav-tab" role="tablist">
                        <a class="nav-link <cfif URL.filtro EQ "">active</cfif> px-4" data-estado-tab="" id="nav-tab-UL" href="<cfoutput>#encodeForHTMLAttribute(REQUEST.estadoCityUrl(VARIABLES.estadoCidadeSlug,""))#</cfoutput>" role="tab" aria-selected="<cfif URL.filtro EQ "">true<cfelse>false</cfif>">Últimos</a>
                        <a class="nav-link <cfif URL.filtro EQ "maiores">active</cfif> px-4" data-estado-tab="maiores" id="nav-tab-MA" href="<cfoutput>#encodeForHTMLAttribute(REQUEST.estadoCityUrl(VARIABLES.estadoCidadeSlug,"maiores"))#</cfoutput>" role="tab" aria-selected="<cfif URL.filtro EQ "maiores">true<cfelse>false</cfif>">Maiores</a>
                        <a class="nav-link <cfif URL.filtro EQ "maratonas">active</cfif> px-4" data-estado-tab="maratonas" id="nav-tab-MR" href="<cfoutput>#encodeForHTMLAttribute(REQUEST.estadoCityUrl(VARIABLES.estadoCidadeSlug,"maratonas"))#</cfoutput>" role="tab" aria-selected="<cfif URL.filtro EQ "maratonas">true<cfelse>false</cfif>">Maratonas</a>
                    </div>
                </nav>


                <!--- LISTAGEM DE EVENTOS --->

                <div id="container-proximas" class="col-lg-12">

                    <div id="scroll-container-proximas">
                        <cfif NOT qEventos.recordCount><p class="text-muted py-3" role="status">Nenhum evento encontrado para esta seleção. Experimente outra cidade ou aba.</p></cfif>

                        <cfset qEventosAba = qEventos/>

                        <cfset VARIABLES.originalEventCardColumnClass = isDefined("VARIABLES.eventCardColumnClass") ? VARIABLES.eventCardColumnClass : ""/>
                        <cfset VARIABLES.originalEventMonthDividerFormat = isDefined("VARIABLES.eventMonthDividerFormat") ? VARIABLES.eventMonthDividerFormat : ""/>
                        <cfset VARIABLES.eventCardColumnClass = "col-12 mb-1"/>
                        <cfset VARIABLES.eventMonthDividerFormat = "mmmm yyyy"/>
                        <cfinclude template="../includes/lista_de_eventos_simple.cfm"/>
                        <cfif len(VARIABLES.originalEventCardColumnClass)>
                            <cfset VARIABLES.eventCardColumnClass = VARIABLES.originalEventCardColumnClass/>
                        <cfelse>
                            <cfset structDelete(VARIABLES, "eventCardColumnClass")/>
                        </cfif>
                        <cfif len(VARIABLES.originalEventMonthDividerFormat)>
                            <cfset VARIABLES.eventMonthDividerFormat = VARIABLES.originalEventMonthDividerFormat/>
                        <cfelse>
                            <cfset structDelete(VARIABLES, "eventMonthDividerFormat")/>
                        </cfif>


                    </div>

                    <div id="spinner-proximas" class="spinner-border mx-auto" style="display: none"></div>

                </div>

            </div>

            <!--- BARRA LATERAL --->

            <div class="col-lg-3">

                <cfinclude template="../includes/barra_lateral.cfm"/>

            </div>

        </div>

    </div>


    <!--- FOOTER --->

    <cfinclude template="../includes/footer.cfm"/>


    <!--- SEO WEB TOOLS --->

    <cfinclude template="../includes/seo-web-tools-body-end.cfm"/>


    <script src="/assets/js/openresults-estado-cidades.js?v=20261004-1"></script>
    <script>
        const estadoUf = <cfoutput>#replace(serializeJSON(URL.tag), "<", "\u003c", "all")#</cfoutput>;
        const estadoCidade = <cfoutput>#replace(serializeJSON(VARIABLES.estadoCidadeSlug), "<", "\u003c", "all")#</cfoutput>;
        OpenResultsEstadoCities.init(document, estadoUf, estadoCidade);
        let totalEventos = <cfoutput>#qEventos.recordCount#</cfoutput>;
        let lastMonth = 0;
        let lastMonthKey = '<cfoutput>#JSStringFormat(URL.lastMonthKey)#</cfoutput>';
        let page = 0;
        let loading = false;
        const pageSize = <cfoutput>#VARIABLES.pageSize#</cfoutput>;
        const spinner = document.getElementById('spinner-proximas');
        const eventListContainer = document.getElementById('listaEvento');
        async function loadImages() {
            if (loading || totalEventos <= (page + 1) * pageSize) return;
            loading = true;
            spinner.style.display = 'block';
            try {
                const response = await fetch(OpenResultsEstadoCities.buildApiUrl(window.location.href, estadoUf, page + 1, lastMonthKey, estadoCidade));
                if (!response.ok) throw new Error('Falha ao carregar eventos: ' + response.status);
                const html = await response.text();
                eventListContainer.insertAdjacentHTML('beforeend',html);
                const fragment = document.createElement('div');
                fragment.innerHTML = html;
                fragment.querySelectorAll('script').forEach(function (script) { eval(script.textContent); });
                page++;
                colorirDistancias();
            } catch (error) {
                console.warn(error.message);
            } finally {
                loading = false;
                spinner.style.display = 'none';
            }
        }
        window.addEventListener('completed.mdb.infiniteScroll', loadImages);
        new mdb.InfiniteScroll(window);
    </script>
</body>
</html>
