<!--- FILTROS ADMIN EVENTOS --->

<cfif VARIABLES.template EQ "/admin/">

    <div class="row g-3">

        <!--- PERIODO --->

        <div class="col-md-3 mb-3">

            <select data-mdb-select-init data-mdb-visible-options="12" class="form-select" onchange="window.location.href='<cfoutput>#VARIABLES.template#?preset=#URL.preset#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#&id_agrega_evento=#URL.id_agrega_evento#&agregador_tag=#URL.agregador_tag#&periodo=</cfoutput>' + this.value">>
                <option value="" <cfif URL.periodo EQ "">selected</cfif> >Todo o Período</option>
                <option value="semana" <cfif URL.periodo EQ "semana">selected</cfif> >Esta Semana</option>
                <option value="mes" <cfif URL.periodo EQ "mes">selected</cfif> >Este Mês</option>
                <option value="futuros" disabled <cfif URL.periodo EQ "futuros">selected</cfif> >Futuros</option>
                <option value="2025" <cfif URL.periodo EQ "2025">selected</cfif> >Em 2025</option>
                <option value="passados" disabled <cfif URL.periodo EQ "passados">selected</cfif> >Passados (este ano)</option>
                <option value="2024" <cfif URL.periodo EQ "2024">selected</cfif> >Em 2024</option>
                <option value="2023" <cfif URL.periodo EQ "2023">selected</cfif> >Em 2023</option>
                <option value="antigos" disabled <cfif URL.periodo EQ "antigos">selected</cfif> >Até 2022</option>
            </select>

        </div>

        <div class="col-md-3 mb-3">

            <select data-mdb-select-init class="form-select" onchange="window.location.href='<cfoutput>./?estado=</cfoutput>' + this.value">>
                <option value="" <cfif URL.estado EQ "">selected</cfif> >Estado</option>
                <cfoutput query="qEstados">
                    <option value="#qEstados.estado#" <cfif URL.estado EQ qEstados.estado>selected</cfif> >#qEstados.estado#</option>
                </cfoutput>
            </select>

        </div>

        <div class="col-md-4 mb-3">

            <form action="" method="get">
                <input type="text" class="form-control" name="busca" placeholder="busca" value="<cfoutput>#URL.busca#</cfoutput>"/>
                <input type="hidden" name="preset" value=""/>
                <input type="hidden" name="periodo" value=""/>
                <input type="hidden" name="sessao" value=""/>
                <input type="hidden" name="regiao" value=""/>
                <input type="hidden" name="estado" value=""/>
                <input type="hidden" name="cidade" value=""/>
                <input type="hidden" name="agregador_tag" value=""/>
                <input type="hidden" name="id_agrega_evento" value=""/>
            </form>

        </div>

        <div class="col-md-2 mb-3">
            <a href="/admin/?id_evento=0" class="btn btn-primary w-100">Novo Evento</a>
        </div>

    </div>

</cfif>
