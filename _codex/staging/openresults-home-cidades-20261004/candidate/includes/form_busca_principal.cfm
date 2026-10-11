<cfif NOT isDefined("VARIABLES.buscaFormTerm")>
    <cfset VARIABLES.buscaFormTerm = isDefined("URL.termo") ? URL.termo : ""/>
</cfif>

<form action="/busca/" method="get" class="or-main-search-form">
    <div class="or-main-search-box card flex-row">
        <input name="termo"
               class="form-control-lg flex-fill border-0 shadow-0"
               type="search"
               value="<cfoutput>#htmlEditFormat(VARIABLES.buscaFormTerm)#</cfoutput>"
               placeholder="Nome do atleta ou evento"
               aria-label="Busca"
               required>
        <button class="visually-hidden" type="submit" tabindex="-1" aria-hidden="true"></button>
        <div class="or-main-search-actions">
            <button class="btn btn-primary shadow-0" type="submit" name="aba" value="atletas" aria-label="Buscar atletas" title="Atletas" data-mdb-tooltip-init data-mdb-placement="bottom">
                <i class="fa-solid fa-user"></i>
            </button>
            <button class="btn btn-secondary shadow-0" type="submit" name="aba" value="eventos" aria-label="Buscar eventos" title="Eventos" data-mdb-tooltip-init data-mdb-placement="bottom">
                <i class="fas fa-calendar-days"></i>
            </button>
        </div>
    </div>
</form>

<div class="or-search-chip-row mt-3<cfif VARIABLES.template EQ "/"> or-home-city-row</cfif>">
    <div class="or-search-chip-select-wrap">
        <i class="fa-solid fa-location-dot or-search-chip-select-icon"></i>
        <select id="buscaEstado"
                class="or-search-chip or-search-chip-select"
                onchange="if (this.value) window.location.href = this.value;"
                aria-label="Selecionar estado">
            <option value="">Eventos por estado</option>
            <option value="/estado/ac/">Acre</option>
            <option value="/estado/al/">Alagoas</option>
            <option value="/estado/am/">Amazonas</option>
            <option value="/estado/ap/">Amapá</option>
            <option value="/estado/ba/">Bahia</option>
            <option value="/estado/ce/">Ceará</option>
            <option value="/estado/df/">Distrito Federal</option>
            <option value="/estado/es/">Espírito Santo</option>
            <option value="/estado/go/">Goiás</option>
            <option value="/estado/ma/">Maranhão</option>
            <option value="/estado/mg/">Minas Gerais</option>
            <option value="/estado/ms/">Mato Grosso do Sul</option>
            <option value="/estado/mt/">Mato Grosso</option>
            <option value="/estado/pa/">Pará</option>
            <option value="/estado/pb/">Paraíba</option>
            <option value="/estado/pe/">Pernambuco</option>
            <option value="/estado/pi/">Piauí</option>
            <option value="/estado/pr/">Paraná</option>
            <option value="/estado/rj/">Rio de Janeiro</option>
            <option value="/estado/rn/">Rio Grande do Norte</option>
            <option value="/estado/ro/">Rondônia</option>
            <option value="/estado/rr/">Roraima</option>
            <option value="/estado/rs/">Rio Grande do Sul</option>
            <option value="/estado/sc/">Santa Catarina</option>
            <option value="/estado/se/">Sergipe</option>
            <option value="/estado/sp/">São Paulo</option>
            <option value="/estado/to/">Tocantins</option>
        </select>
        <i class="fa-solid fa-chevron-down or-search-chip-select-caret"></i>
    </div>
    <cfif VARIABLES.template EQ "/" AND structKeyExists(VARIABLES,"homeCityCatalog")>
        <details class="estado-city-picker" data-home-city-picker>
            <summary><i class="fa-solid fa-city" aria-hidden="true"></i><span>Eventos por cidade</span><i class="fa-solid fa-chevron-down" aria-hidden="true"></i></summary>
            <div class="estado-city-picker-panel">
                <label class="estado-city-picker-label" for="home-city-search">Buscar cidade</label>
                <input type="search" id="home-city-search" placeholder="Carregando busca de cidades" disabled autocomplete="off">
                <p class="estado-city-picker-hint">Provas com resultados disponíveis. Busque também cidades com eventos antigos.</p>
                <div class="estado-city-picker-list" data-home-city-suggestions>
                    <cfif arrayLen(VARIABLES.homeCityCatalog.recent)>
                        <h3 class="home-city-group-title">Provas nos últimos 30 dias</h3>
                        <cfloop array="#VARIABLES.homeCityCatalog.recent#" index="VARIABLES.homeCityOption"><cfoutput>
                            <a class="estado-city-picker-item" href="/estado/#lCase(VARIABLES.homeCityOption.uf)#/?cidade=#encodeForHTMLAttribute(urlEncodedFormat(VARIABLES.homeCityOption.slug))#&amp;rua=true&amp;trail=true" data-home-city-slug="#encodeForHTMLAttribute(VARIABLES.homeCityOption.slug)#" data-home-city-uf="#VARIABLES.homeCityOption.uf#">
                                <span>#encodeForHTML(VARIABLES.homeCityOption.name)# - #VARIABLES.homeCityOption.uf#</span><span data-city-count>#VARIABLES.homeCityOption.recent# <cfif VARIABLES.homeCityOption.recent EQ 1>prova recente<cfelse>provas recentes</cfif></span>
                            </a>
                        </cfoutput></cfloop>
                    </cfif>
                    <cfif arrayLen(VARIABLES.homeCityCatalog.popular)>
                        <h3 class="home-city-group-title">Mais provas nos últimos 12 meses</h3>
                        <cfloop array="#VARIABLES.homeCityCatalog.popular#" index="VARIABLES.homeCityOption"><cfoutput>
                            <a class="estado-city-picker-item" href="/estado/#lCase(VARIABLES.homeCityOption.uf)#/?cidade=#encodeForHTMLAttribute(urlEncodedFormat(VARIABLES.homeCityOption.slug))#&amp;rua=true&amp;trail=true" data-home-city-slug="#encodeForHTMLAttribute(VARIABLES.homeCityOption.slug)#" data-home-city-uf="#VARIABLES.homeCityOption.uf#">
                                <span>#encodeForHTML(VARIABLES.homeCityOption.name)# - #VARIABLES.homeCityOption.uf#</span><span data-city-count>#VARIABLES.homeCityOption.annual# <cfif VARIABLES.homeCityOption.annual EQ 1>prova no ano<cfelse>provas no ano</cfif></span>
                            </a>
                        </cfoutput></cfloop>
                    </cfif>
                    <cfif NOT arrayLen(VARIABLES.homeCityCatalog.recent) AND NOT arrayLen(VARIABLES.homeCityCatalog.popular)><p class="estado-city-picker-hint">Busque uma cidade pelo nome.</p></cfif>
                </div>
                <div class="estado-city-picker-list" data-home-city-results hidden></div>
                <p class="estado-city-picker-status" data-home-city-status aria-live="polite"></p>
                <noscript><p class="estado-city-picker-hint">A busca por nome precisa de JavaScript. Você pode abrir as sugestões acima ou escolher um estado.</p></noscript>
            </div>
        </details>
        <script type="application/json" id="home-city-data"><cfoutput>#VARIABLES.homeCityJson#</cfoutput></script>
    </cfif>
</div>
