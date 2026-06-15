
<cfparam name="FORM.url_resultado" default=""/>
<cfparam name="FORM.url_racetag" default=""/>
<cfparam name="FORM.cod_evento" default=""/>
<cfparam name="FORM.path_evento" default=""/>
<cfparam name="FORM.id_evento" default=""/>
<cfparam name="URL.auto" default="false"/>

<cfif Len(trim(FORM.url_resultado))>

    <cfif FORM.url_resultado CONTAINS "##">
        <cfset FORM.url_racetag = listtoarray(FORM.url_resultado, "##")[1]>
        <cfset FORM.path_evento = replace(listtoarray(FORM.url_resultado, "##")[2], "/", "")>
    </cfif>

</cfif>

<form id="formWiclax" action="./" method="post">

    <div class="mb-3">
        <label for="inputURL" class="form-label">Endereço de Publicação do Resultado</label>
        <input type="text" class="form-control" id="inputURL" name="url_resultado" <cfif len(trim(FORM.url_resultado))>value="<cfoutput>#FORM.url_resultado#</cfoutput>"</cfif> >
        <p class="mt-2 text-secondary"><small>URL onde o Racetag Pro publica o arquivo event.json</small></p>
    </div>

    <cfif Len(trim(FORM.url_racetag))>

        <p><icon class="fa fa-circle-check text-success"></icon> Passo 1: O caminho é do Racetag Pro.</p>

        <p>
            Base Racetag Pro: <cfoutput>#FORM.url_racetag#</cfoutput>
            <br>
            Evento: <cfoutput>#FORM.path_evento#</cfoutput>
        </p>

        <cfhttp result="httpEventos" url="#FORM.url_racetag#data/events.json"></cfhttp>

        <cfif isJSON(httpEventos.filecontent)>

            <cfset eventosJSON = deserializeJSON(httpEventos.filecontent)>

            <div class="mb-3">
                <label for="inputEvento" class="form-label">Evento <cfoutput>#eventosJSON[1].organizer#</cfoutput>:</label>
                <select class="form-select" id="inputEvento" name="cod_evento" onchange="window.location.href='<cfoutput>./?cod_evento=</cfoutput>' + this.value">>
                    <cfloop array="#eventosJSON#" item="item">
                        <cfif item.link EQ FORM.path_evento>
                            <cfset VARIABLES.evento = item/>
                        </cfif>
                        <cfoutput>
                            <option value="#item.id#" <cfif item.link EQ FORM.path_evento>selected</cfif> >#item.startDate#-#item.endDate# - #item.name# - #item.place#</option>
                        </cfoutput>
                    </cfloop>
                </select>
            </div>

            <!---cfdump var="#VARIABLES.evento#"/--->

            <cfhttp result="httpEvento" url="#FORM.url_racetag#data/#VARIABLES.evento.id#/event.json"></cfhttp>

            <p><icon class="fa fa-circle-check text-success"></icon> Passo 2: Conseguimos ler o evento.</p>

            <cfset eventoJSON = deserializeJSON(httpEvento.filecontent)>

            <cfif isDefined("eventoJSON.routes")>
                <p><icon class="fa fa-circle-check text-success"></icon> Passo 3: O JSON é um arquivo RaceTag Pro válido.</p>
            <cfelse>
                <p>Passo 2: O JSON não é um arquivo RaceTag Pro válido.</p>
            </cfif>

            <cfoutput>
                <cfif isDefined("eventoJSON.id")><p class="m-0">ID: #eventoJSON.id#</p></cfif>
                <cfif isDefined("eventoJSON.name")><p class="m-0">Evento: #eventoJSON.name#</p></cfif>
                <cfif isDefined("eventoJSON.endDate")><p class="m-0">Data: #eventoJSON.endDate#</p></cfif>
                <cfif isDefined("eventoJSON.organizer")><p class="m-0">Organizador: #eventoJSON.organizer#</p></cfif>
                <cfif isDefined("eventoJSON.place")><p class="m-0">Local: #eventoJSON.place#</p></cfif>
                <cfif isDefined("eventoJSON.federation")><p class="m-0 mb-3">Federação: #eventoJSON.federation#</p></cfif>
                <cfif isDefined("eventoJSON.videoUrl")><p class="m-0 mb-3">Video: #eventoJSON.videoUrl#</p></cfif>
                <cfif isDefined("eventoJSON.extraoficialResults")><p class="m-0 mb-3">Extra oficial: #eventoJSON.extraoficialResults#</p></cfif>
            </cfoutput>

            <cfquery name="qEventos">
                SELECT * FROM tb_evento_corridas
                <!---WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_evento#"/>--->
                WHERE lower(unaccent(cidade)) = lower(unaccent(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.evento.place#"/>))
                AND data_inicial between <cfqueryparam cfsqltype="cf_sql_date" value="#VARIABLES.evento.startDate#"/> and <cfqueryparam cfsqltype="cf_sql_date" value="#VARIABLES.evento.endDate#"/>
                AND data_final between <cfqueryparam cfsqltype="cf_sql_date" value="#VARIABLES.evento.startDate#"/> and <cfqueryparam cfsqltype="cf_sql_date" value="#VARIABLES.evento.endDate#"/>
            </cfquery>

            <div class="mb-3">
                <label for="inputEvento" class="form-label">Evento Road Runners:</label>
                <select class="form-select" id="inputEvento" name="id_evento" onchange="window.location.href='<cfoutput>./?id_evento=</cfoutput>' + this.value">>
                    <cfoutput query="qEventos">
                        <option value="#qEventos.id_evento#" <cfif FORM.id_evento EQ qEventos.id_evento>selected</cfif> >#data_final# - #nome_evento#</option>
                    </cfoutput>
                </select>
            </div>

            <button type="submit" class="btn btn-primary">Processar Resultado</button>

        <cfelse>

            <p>Passo 1: O JSON é inválido</p>

            <button type="submit" class="btn btn-primary">Ler Resultado</button>

        </cfif>

        <cfif len(trim(FORM.id_evento))>

            <cfinclude template="parse.cfm"/>

        </cfif>

    <cfelse>

        <button type="submit" class="btn btn-primary">Ler Resultado</button>

    </cfif>

</form>


<cfif URL.auto>
    <script>
        document.getElementById("formWiclax").submit();
    </script>
</cfif>
