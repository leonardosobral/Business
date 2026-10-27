<cfset VARIABLES.searchHeroCatalog = REQUEST.i18n.search.hero />
<cfset VARIABLES.searchFiltersCatalog = REQUEST.i18n.search.filters />
<cfset VARIABLES.stateFilterNames = structNew() />
<cfset VARIABLES.stateFilterCurrentStateName = VARIABLES.estado />
<cfset VARIABLES.stateFilterHomePath = structKeyExists(REQUEST, "i18nBuildPath") ? REQUEST.i18nBuildPath("home") : "/" />
<cfset VARIABLES.stateFilterSearchPath = structKeyExists(REQUEST, "i18nBuildPath") ? REQUEST.i18nBuildPath("search") : "/busca/" />

<cfset structInsert(VARIABLES.stateFilterNames, "AC", "Acre", true) />
<cfset structInsert(VARIABLES.stateFilterNames, "AL", "Alagoas", true) />
<cfset structInsert(VARIABLES.stateFilterNames, "AP", "Amapá", true) />
<cfset structInsert(VARIABLES.stateFilterNames, "AM", "Amazonas", true) />
<cfset structInsert(VARIABLES.stateFilterNames, "BA", "Bahia", true) />
<cfset structInsert(VARIABLES.stateFilterNames, "CE", "Ceará", true) />
<cfset structInsert(VARIABLES.stateFilterNames, "DF", "Distrito Federal", true) />
<cfset structInsert(VARIABLES.stateFilterNames, "ES", "Espírito Santo", true) />
<cfset structInsert(VARIABLES.stateFilterNames, "GO", "Goiás", true) />
<cfset structInsert(VARIABLES.stateFilterNames, "MA", "Maranhão", true) />
<cfset structInsert(VARIABLES.stateFilterNames, "MT", "Mato Grosso", true) />
<cfset structInsert(VARIABLES.stateFilterNames, "MS", "Mato Grosso do Sul", true) />
<cfset structInsert(VARIABLES.stateFilterNames, "MG", "Minas Gerais", true) />
<cfset structInsert(VARIABLES.stateFilterNames, "PA", "Pará", true) />
<cfset structInsert(VARIABLES.stateFilterNames, "PB", "Paraíba", true) />
<cfset structInsert(VARIABLES.stateFilterNames, "PR", "Paraná", true) />
<cfset structInsert(VARIABLES.stateFilterNames, "PE", "Pernambuco", true) />
<cfset structInsert(VARIABLES.stateFilterNames, "PI", "Piauí", true) />
<cfset structInsert(VARIABLES.stateFilterNames, "RJ", "Rio de Janeiro", true) />
<cfset structInsert(VARIABLES.stateFilterNames, "RN", "Rio Grande do Norte", true) />
<cfset structInsert(VARIABLES.stateFilterNames, "RS", "Rio Grande do Sul", true) />
<cfset structInsert(VARIABLES.stateFilterNames, "RO", "Rondônia", true) />
<cfset structInsert(VARIABLES.stateFilterNames, "RR", "Roraima", true) />
<cfset structInsert(VARIABLES.stateFilterNames, "SC", "Santa Catarina", true) />
<cfset structInsert(VARIABLES.stateFilterNames, "SP", "São Paulo", true) />
<cfset structInsert(VARIABLES.stateFilterNames, "SE", "Sergipe", true) />
<cfset structInsert(VARIABLES.stateFilterNames, "TO", "Tocantins", true) />

<cfif REQUEST.lang EQ "en">
    <cfset structInsert(VARIABLES.stateFilterNames, "DF", "Federal District", true) />
<cfelseif REQUEST.lang EQ "es">
    <cfset structInsert(VARIABLES.stateFilterNames, "BA", "Bahía", true) />
    <cfset structInsert(VARIABLES.stateFilterNames, "RJ", "Río de Janeiro", true) />
    <cfset structInsert(VARIABLES.stateFilterNames, "RN", "Río Grande do Norte", true) />
    <cfset structInsert(VARIABLES.stateFilterNames, "RS", "Río Grande do Sul", true) />
</cfif>

<cfif len(trim(VARIABLES.uf)) AND structKeyExists(VARIABLES.stateFilterNames, VARIABLES.uf)>
    <cfset VARIABLES.stateFilterCurrentStateName = VARIABLES.stateFilterNames[VARIABLES.uf] />
</cfif>

<style>
    .state-filter-card {
        border: 1px solid rgba(51, 51, 51, 0.08);
        border-radius: 10px;
        background-color: #efefef;
    }

    .state-filter-select {
        min-height: 44px;
        border: 1px solid rgba(51, 51, 51, 0.12);
        border-radius: 8px;
        background-color: #ffffff;
        color: #333333;
        font-weight: 600;
        font-size: 0.92rem;
    }

    .state-filter-chip {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        padding: 0.42rem 0.7rem;
        border-radius: 8px;
        border: 1px solid rgba(51, 51, 51, 0.1);
        background-color: #ffffff;
        color: #333333;
        text-decoration: none;
        font-weight: 600;
        font-size: 0.8rem;
        line-height: 1;
        transition: border-color .18s ease, background-color .18s ease;
    }

    .state-filter-chip:hover {
        border-color: #fab120;
        color: #333333;
    }

    .state-filter-chip.is-active {
        background-color: #fab120;
        border-color: #fab120;
        color: #333333;
    }

    .state-filter-muted {
        color: rgba(51, 51, 51, 0.72);
    }

    .state-filter-chip-row {
        display: flex;
        flex-wrap: wrap;
        gap: 0.5rem;
    }

    @media (max-width: 767.98px) {
        .state-filter-card {
            border-radius: 10px;
        }

        .state-filter-select {
            min-height: 42px;
            font-size: 0.88rem;
        }

        .state-filter-chip {
            padding: 0.38rem 0.62rem;
            font-size: 0.76rem;
            flex: 0 0 auto;
        }

        .state-filter-chip-row {
            flex-wrap: nowrap;
            overflow-x: auto;
            padding-bottom: 0.25rem;
            scrollbar-width: none;
            -ms-overflow-style: none;
        }

        .state-filter-chip-row::-webkit-scrollbar {
            display: none;
        }
    }
</style>

<script src="/assets/js/runnerhub-state-filter.min.js?v=20261008seo2"></script>

<cfif VARIABLES.template NEQ "/busca/" AND VARIABLES.template NEQ "/estado/">
<div class="card state-filter-card p-3 mb-2 shadow-0" id="home-state-filter">

        <div class="d-flex flex-wrap justify-content-between align-items-start gap-2 mb-3">
        <div>
            <div class="small text-uppercase fw-bold state-filter-muted mb-1"><cfoutput>#VARIABLES.searchFiltersCatalog.stateTitle#</cfoutput></div>
        </div>
        <cfif len(trim(VARIABLES.uf)) AND VARIABLES.uf NEQ "BR">
            <a href="<cfoutput>#VARIABLES.stateFilterHomePath#</cfoutput>" class="state-filter-chip is-active" id="state-filter-geo-chip">
                <i class="fa-solid fa-location-dot me-2" style="color:#333333;"></i>
                <cfoutput>#REQUEST.t("search.filters.currentState", { "uf" = VARIABLES.uf })#</cfoutput>
            </a>
        </cfif>
    </div>

    <div class="row g-2 align-items-center mb-3">
        <div class="col-12 col-lg-7">
            <select class="form-select state-filter-select shadow-0" id="state-filter-select" data-search-path="<cfoutput>#encodeForHTMLAttribute(VARIABLES.stateFilterSearchPath)#</cfoutput>" onchange="goToEstadoHome(this)" aria-label="<cfoutput>#VARIABLES.searchHeroCatalog.stateSelectAria#</cfoutput>">
                <option value=""><cfoutput>#VARIABLES.searchFiltersCatalog.statePlaceholder#</cfoutput></option>
                <option value="AC"><cfoutput>#VARIABLES.stateFilterNames["AC"]#</cfoutput></option>
                <option value="AL"><cfoutput>#VARIABLES.stateFilterNames["AL"]#</cfoutput></option>
                <option value="AP"><cfoutput>#VARIABLES.stateFilterNames["AP"]#</cfoutput></option>
                <option value="AM"><cfoutput>#VARIABLES.stateFilterNames["AM"]#</cfoutput></option>
                <option value="BA"><cfoutput>#VARIABLES.stateFilterNames["BA"]#</cfoutput></option>
                <option value="CE"><cfoutput>#VARIABLES.stateFilterNames["CE"]#</cfoutput></option>
                <option value="DF"><cfoutput>#VARIABLES.stateFilterNames["DF"]#</cfoutput></option>
                <option value="ES"><cfoutput>#VARIABLES.stateFilterNames["ES"]#</cfoutput></option>
                <option value="GO"><cfoutput>#VARIABLES.stateFilterNames["GO"]#</cfoutput></option>
                <option value="MA"><cfoutput>#VARIABLES.stateFilterNames["MA"]#</cfoutput></option>
                <option value="MT"><cfoutput>#VARIABLES.stateFilterNames["MT"]#</cfoutput></option>
                <option value="MS"><cfoutput>#VARIABLES.stateFilterNames["MS"]#</cfoutput></option>
                <option value="MG"><cfoutput>#VARIABLES.stateFilterNames["MG"]#</cfoutput></option>
                <option value="PA"><cfoutput>#VARIABLES.stateFilterNames["PA"]#</cfoutput></option>
                <option value="PB"><cfoutput>#VARIABLES.stateFilterNames["PB"]#</cfoutput></option>
                <option value="PR"><cfoutput>#VARIABLES.stateFilterNames["PR"]#</cfoutput></option>
                <option value="PE"><cfoutput>#VARIABLES.stateFilterNames["PE"]#</cfoutput></option>
                <option value="PI"><cfoutput>#VARIABLES.stateFilterNames["PI"]#</cfoutput></option>
                <option value="RJ"><cfoutput>#VARIABLES.stateFilterNames["RJ"]#</cfoutput></option>
                <option value="RN"><cfoutput>#VARIABLES.stateFilterNames["RN"]#</cfoutput></option>
                <option value="RS"><cfoutput>#VARIABLES.stateFilterNames["RS"]#</cfoutput></option>
                <option value="RO"><cfoutput>#VARIABLES.stateFilterNames["RO"]#</cfoutput></option>
                <option value="RR"><cfoutput>#VARIABLES.stateFilterNames["RR"]#</cfoutput></option>
                <option value="SC"><cfoutput>#VARIABLES.stateFilterNames["SC"]#</cfoutput></option>
                <option value="SP"><cfoutput>#VARIABLES.stateFilterNames["SP"]#</cfoutput></option>
                <option value="SE"><cfoutput>#VARIABLES.stateFilterNames["SE"]#</cfoutput></option>
                <option value="TO"><cfoutput>#VARIABLES.stateFilterNames["TO"]#</cfoutput></option>
            </select>
        </div>
        <div class="col-12 col-lg-5">
            <div class="small state-filter-muted">
                <cfif len(trim(VARIABLES.uf)) AND VARIABLES.uf NEQ "BR">
                    <i class="fa-solid fa-location-dot me-1" style="color:#FAB120;"></i><cfoutput>#REQUEST.t("search.filters.stateShowing", { "state" = VARIABLES.stateFilterCurrentStateName })#</cfoutput>
                <cfelse>
                    <i class="fa-solid fa-compass me-1" style="color:#FAB120;"></i><cfoutput>#VARIABLES.searchFiltersCatalog.statePrompt#</cfoutput>
                </cfif>
            </div>
        </div>
    </div>

    <div class="state-filter-chip-row" id="state-filter-chip-row">
        <a href="<cfoutput>#VARIABLES.stateFilterSearchPath#</cfoutput>?estados=sp" data-state-chip="SP" class="state-filter-chip<cfif VARIABLES.uf EQ 'SP'> is-active</cfif>">SP</a>
        <a href="<cfoutput>#VARIABLES.stateFilterSearchPath#</cfoutput>?estados=sc" data-state-chip="SC" class="state-filter-chip<cfif VARIABLES.uf EQ 'SC'> is-active</cfif>">SC</a>
        <a href="<cfoutput>#VARIABLES.stateFilterSearchPath#</cfoutput>?estados=rj" data-state-chip="RJ" class="state-filter-chip<cfif VARIABLES.uf EQ 'RJ'> is-active</cfif>">RJ</a>
        <a href="<cfoutput>#VARIABLES.stateFilterSearchPath#</cfoutput>?estados=mg" data-state-chip="MG" class="state-filter-chip<cfif VARIABLES.uf EQ 'MG'> is-active</cfif>">MG</a>
        <a href="<cfoutput>#VARIABLES.stateFilterSearchPath#</cfoutput>?estados=pr" data-state-chip="PR" class="state-filter-chip<cfif VARIABLES.uf EQ 'PR'> is-active</cfif>">PR</a>
        <a href="<cfoutput>#VARIABLES.stateFilterSearchPath#</cfoutput>?estados=rs" data-state-chip="RS" class="state-filter-chip<cfif VARIABLES.uf EQ 'RS'> is-active</cfif>">RS</a>
        <a href="<cfoutput>#VARIABLES.stateFilterSearchPath#</cfoutput>?estados=ba" data-state-chip="BA" class="state-filter-chip<cfif VARIABLES.uf EQ 'BA'> is-active</cfif>">BA</a>
        <a href="<cfoutput>#VARIABLES.stateFilterSearchPath#</cfoutput>?estados=df" data-state-chip="DF" class="state-filter-chip<cfif VARIABLES.uf EQ 'DF'> is-active</cfif>">DF</a>
    </div>

</div>
</cfif>


<div class="card p-1 mb-2">

    <cfif VARIABLES.template NEQ "/">

        <!--- TOGGLE FILTRO AVANCADO --->

        <a class="p-1 w-100 text-center small rounded btn btn-secondary filtoogle"
                data-mdb-collapse-init
                data-mdb-ripple-init
                data-mdb-target=".multi-collapse"
                role="button"
                aria-expanded="false"
                aria-controls="filtroCompacto filtroFull"
                style="font-size: 12px; text-transform: none"><cfoutput>#REQUEST.t("search.filters.toggle")#</cfoutput></a>


        <!--- FILTRO AVANCADO FULL --->

        <div class="collapse multi-collapse" id="filtroFull">

            <!--- DISTANCIAS --->
            <div class="col-12 p-1">
                <table class="small text-center text-gray w-100">
            <tr style="line-height: 20px; font-size: 12px;">
                        <td colspan="11"><cfoutput>#REQUEST.t("search.filters.distanceKm")#</cfoutput></td>
            </tr>
                <tr style="line-height: 12px; font-size: 12px;">
                    <td width=2%>1</td>
                    <td width=7%></td>
                    <td width=2%>5</td>
                    <td width=7%></td>
                    <td width=2%>10</td>
                    <td></td>
                    <td width=2%>21</td>
                    <td width=40%></td>
                    <td width=2%>42</td>
                    <td width=11%></td>
                    <td width=2%><span class="position-absolute" style="margin-left:-8px"><cfoutput>#VARIABLES.searchFiltersCatalog.ultra#</cfoutput></span>&nbsp;&nbsp;&nbsp;&nbsp;</td>
                </tr>
                <tr style="line-height: 4px; font-size: 10px;">
                    <td width=2%>|</td>
                    <td width=7% class="k5"></td>
                    <td width=2%>|</td>
                    <td width=7% class="k10"></td>
                    <td width=2%>|</td>
                    <td class="k21"></td>
                    <td width=2%>|</td>
                    <td width=40% class="k42"></td>
                    <td width=2%>|</td>
                    <td width=11% class="ultra"></td>
                    <td width=2%>|</td>
                </tr>
            </table>
                <div class="mx-1 my-3">
                    <div id="multi-ranges-distancia" class="multi-range-slider" data-mdb-min="1" data-mdb-max="50" data-mdb-step="1" data-mdb-tooltip="true"></div>
                </div>
            </div>

            <!--- PERIODO --->
            <div class="col-12 p-1"<cfif VARIABLES.template EQ "/estado/"> hidden</cfif>>
                <table class="small text-center text-gray mx-1 w-100">
                    <tr style="line-height: 20px; font-size: 12px;">
                        <td colspan="9"><cfoutput>#REQUEST.t("search.filters.periodMonths")#</cfoutput></td>
                    </tr>
                    <tr style="line-height: 12px; font-size: 12px;">
                        <td width=2%>0</td>
                        <td width=22.5%></td>
                        <td width=2%>3</td>
                        <td width=22.5%></td>
                        <td width=2%>6</td>
                        <td width=22.5%></td>
                        <td width=2%>9</td>
                        <td width=22.5%></td>
                        <td width=2%>12</td>
                    </tr>
                    <tr style="line-height: 4px; font-size: 10px;">
                        <td width=2%>|</td>
                        <td width=22.5% style="background-color: #efefef"></td>
                        <td width=2%>|</td>
                        <td width=22.5% style="background-color: #efefef"></td>
                        <td width=2%>|</td>
                        <td width=22.5% style="background-color: #efefef"></td>
                        <td width=2%>|</td>
                        <td width=22.5% style="background-color: #efefef"></td>
                        <td width=2%>|</td>
                    </tr>
                </table>
                <div class="mx-1 my-3">
                    <div id="multi-ranges-tempo" class="multi-range-slider" data-mdb-min="0" data-mdb-max="12" data-mdb-step="1" data-mdb-tooltip="true"></div>
                </div>
            </div>

            <div class="row small">

                <div class="col-7">

                    <!--- BADGES --->

                    <cfoutput query="qBadges">
                        <div class="col mt-1" onclick="setBadge('#qBadges.badge#')">
                            <img id="badge_#qBadges.badge#" src="/assets/badges/badge_#qBadges.badge#.jpg"
                                class="d-inline badges <cfif URL.badges DOES NOT CONTAIN qBadges.badge>opacity-50</cfif> rounded" height="24px"
                                alt="#qBadges.badge_tooltip#" title="#qBadges.badge_tooltip#" style="padding-right: 2px;cursor: pointer"
                                />
                            <label class="form-check-label" for="badge_#qBadges.badge#">#qBadges.badge_descricao#</label>
                        </div>
                    </cfoutput>

                </div>

                <div class="col-5">

                    <p class="fw-bold mt-0 mb-1"><cfoutput>#REQUEST.t("search.filters.modality")#</cfoutput></p>

                    <div class="form-check form-check-inline" style="font-size: 12px">
                      <input class="form-check-input" type="checkbox" role="switch" id="flexSwitchRuaChecked" onclick="setRua(this.checked)" <cfif URL.rua>checked</cfif> />
                      <label class="form-check-label" for="flexSwitchCheckChecked"><cfoutput>#REQUEST.t("search.filters.street")#</cfoutput></label>
                    </div>

                    <div class="form-check form-check-inline" style="font-size: 12px">
                      <input class="form-check-input" type="checkbox" role="switch" id="flexSwitchTrailChecked" onclick="setTrail(this.checked)" <cfif URL.trail>checked</cfif> />
                      <label class="form-check-label" for="flexSwitchCheckChecked"><cfoutput>#REQUEST.t("search.filters.trail")#</cfoutput></label>
                    </div>

                    <p class="fw-bold mt-3 mb-1"><cfoutput>#REQUEST.t("search.filters.territory")#</cfoutput></p>

                    <div class="form-check form-check-inline" style="font-size: 12px">
                      <input class="form-check-input" type="checkbox" role="switch" id="flexSwitchNacionalChecked" onclick="setNacional(this.checked)" <cfif URL.nacional>checked</cfif> <cfif VARIABLES.template EQ "/estado/">disabled</cfif> />
                      <label class="form-check-label" for="flexSwitchCheckChecked"><cfoutput>#REQUEST.t("search.filters.brazil")#</cfoutput></label>
                    </div>

                    <div class="form-check form-check-inline" style="font-size: 12px">
                      <input class="form-check-input" type="checkbox" role="switch" id="flexSwitchInternacionalChecked" onclick="setInternacional(this.checked)" <cfif URL.internacional>checked</cfif> <cfif VARIABLES.template EQ "/estado/">disabled</cfif> />
                      <label class="form-check-label" for="flexSwitchCheckChecked"><cfoutput>#REQUEST.t("search.filters.international")#</cfoutput></label>
                    </div>

                    <cfif APPLICATION.codSite EQ 'RR'>

                        <p class="fw-bold mt-3 mb-1"><cfoutput>#REQUEST.t("search.filters.extras")#</cfoutput></p>

                        <div class="form-check form-check-inline" style="font-size: 12px">
                            <input class="form-check-input" type="checkbox" role="switch" id="flexSwitchCupomChecked" onclick="setCupom(this.checked)" <cfif URL.cupom>checked</cfif> />
                            <label class="form-check-label" for="flexSwitchCupomChecked"><cfoutput>#REQUEST.t("search.filters.couponOnly")#</cfoutput></label>
                        </div>

                    </cfif>

                </div>

            </div>

        </div>

    </cfif>

</div>

<style>
    a.filtoogle[aria-expanded="false"]::before {
        content: "<cfoutput>▾ #JSStringFormat(VARIABLES.searchFiltersCatalog.toggleExpanded)# </cfoutput>";
    }
    a.filtoogle[aria-expanded="false"]::after {
        content: " ▾";
    }
    a.filtoogle[aria-expanded="true"]::before {
        content: "<cfoutput>▴ #JSStringFormat(VARIABLES.searchFiltersCatalog.toggleCollapsed)# </cfoutput>";
    }
    a.filtoogle[aria-expanded="true"]::after {
        content: " ▴";
    }
</style>
