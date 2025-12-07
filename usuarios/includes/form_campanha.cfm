<form method="post">

    <cfif NOT isDefined("VARIABLES.campanha")>

        <div data-mdb-input-init class="form-outline mb-3">
            <input type="text" name="evento" id="form1Example1" class="form-control"
                   placeholder="https://roadrunners.run/evento/seu-evento/"
                   required/>
            <label class="form-label" for="form1Example1">URL do Evento no Road Runners</label>
        </div>

   </cfif>

    <div class="row mb-3 g-3">

        <div class="col">
            <div data-mdb-input-init class="form-outline">
                <input type="number" name="cpc_max" id="form3Example1" class="form-control"
                       <cfif isDefined("VARIABLES.campanha")>value="<cfoutput>#VARIABLES.campanha.cpc_max#</cfoutput>"<cfelse>value="1.00"</cfif>
                       required/>
                <label class="form-label" for="form3Example1">CPC max</label>
            </div>
        </div>

        <div class="col">
            <div data-mdb-input-init class="form-outline">
                <input type="number" name="limite_diario" id="form3Example2" class="form-control"
                       placeholder="20.00"
                        <cfif isDefined("VARIABLES.campanha")>value="<cfoutput>#VARIABLES.campanha.limite_diario#</cfoutput>"</cfif>
                        />
                <label class="form-label" for="form3Example2">Valor max diário</label>
            </div>
        </div>

        <div class="col">
            <div data-mdb-input-init class="form-outline">
                <input type="number" name="limite_ad" id="form3Example2" class="form-control"
                       placeholder="500.00"
                        <cfif isDefined("VARIABLES.campanha")>value="<cfoutput>#VARIABLES.campanha.limite_ad#</cfoutput>"</cfif>/>
                <label class="form-label" for="form3Example2">Valor max da Campanha</label>
            </div>
        </div>

    </div>

    <div class="row mb-3 g-3">

        <div class="col">
            <select name="escopo" data-mdb-select-init data-mdb-placeholder="Locais" multiple required>
                <option value="home" <cfif isDefined("VARIABLES.campanha") and VARIABLES.campanha.escopo CONTAINS "home">selected</cfif>>Capa/Home</option>
                <option value="busca" <cfif isDefined("VARIABLES.campanha") and VARIABLES.campanha.escopo CONTAINS "busca">selected</cfif>>Página de Busca</option>
                <option value="feed" <cfif isDefined("VARIABLES.campanha") and VARIABLES.campanha.escopo CONTAINS "feed">selected</cfif>>Feed de Usuários</option>
            </select>
        </div>

        <div class="col">

            <!--- QUERY UFs --->

            <cfquery name="qAdUFs">
                SELECT uf, nome_uf,
                    <cfif isDefined("VARIABLES.campanha") AND deserializeJSON(VARIABLES.campanha.locais).nacional>
                        true as selecionado
                    <cfelseif isDefined("VARIABLES.campanha") AND NOT deserializeJSON(VARIABLES.campanha.locais).nacional>
                        CASE
                            <cfloop array="#deserializeJSON(VARIABLES.campanha.locais).estados#" item="estado">
                                WHEN (uf = '#estado#') THEN true
                            </cfloop>
                            ELSE false
                        END as selecionado
                    <cfelse>
                        false as selecionado
                    </cfif>
                from tb_uf
                ORDER BY uf
            </cfquery>

            <select name="locais" data-mdb-select-init data-mdb-placeholder="Público" multiple required>
                <cfoutput query="qAdUFs">
                    <option value="#qAdUFs.uf#" <cfif qAdUFs.selecionado>selected</cfif> >#qAdUFs.uf# - #qAdUFs.nome_uf#</option>
                </cfoutput>
            </select>

        </div>

        <div class="col">
            <div class="form-outline" data-mdb-datepicker-init data-mdb-input-init data-mdb-date-range="true" data-mdb-inline="true">
                <input type="text" name="datas" class="form-control" id="date-range-inline"
                    <cfif isDefined("VARIABLES.campanha")>value="<cfoutput>#lsdateformat(VARIABLES.campanha.inicio_ad, 'dd/mm/yyyy')# - #lsdateformat(VARIABLES.campanha.final_ad, 'dd/mm/yyyy')#</cfoutput>"</cfif>
                />
                <label for="date-range-inline" class="form-label">Período da Campanha</label>
            </div>
        </div>

    </div>

    <cfif isDefined("URL.campanha")>
        <input type="hidden" name="acao" value="editar_campanha">
        <input type="hidden" name="id_ad_evento" value="<cfoutput>#URL.campanha#</cfoutput>">
    <cfelse>
        <input type="hidden" name="acao" value="incluir_campanha">
    </cfif>

    <button data-mdb-ripple-init type="submit" class="btn btn-primary btn-block">Salvar Campanha</button>

</form>
