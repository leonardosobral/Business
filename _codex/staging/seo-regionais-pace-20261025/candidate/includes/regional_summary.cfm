<cfprocessingdirective pageencoding="utf-8"/>
<cfif compareNoCase(getBaseTemplatePath(), getCurrentTemplatePath()) EQ 0><cfheader statuscode="403"/><cfabort/></cfif>
<cfparam name="URL.page" default="0"/>
<!--- Render alongside the list so every filter refresh replaces the same summary. --->
<cfif val(URL.page) EQ 0 AND listFindNoCase("AC,AL,AM,AP,BA,CE,DF,ES,GO,MA,MG,MS,MT,PA,PB,PE,PI,PR,RJ,RN,RO,RR,RS,SC,SE,SP,TO", URL.tag)>
<cfscript>
VARIABLES.regionalRoot = "/estado/" & lCase(URL.tag) & "/";
VARIABLES.regionalCity = structKeyExists(URL,"cidade") && reFind("^[a-z0-9-]+$",URL.cidade) ? URL.cidade : "";
VARIABLES.regionalPath = VARIABLES.regionalRoot & (len(VARIABLES.regionalCity) ? VARIABLES.regionalCity & "/" : "");
VARIABLES.regionalTotal = qEventos.recordCount;
VARIABLES.regionalDistances = {};
VARIABLES.regionalOptions = [{km=5,label="5 km"},{km=10,label="10 km"},{km=21,label="21 km"},{km=42,label="42 km"}];
if (listFindNoCase(qEventos.columnList,"lista_percursos")) {
    for (VARIABLES.regionalEvent in qEventos) {
        if (len(VARIABLES.regionalEvent.lista_percursos & "") && isJSON(VARIABLES.regionalEvent.lista_percursos)) {
            VARIABLES.regionalCourses = deserializeJSON(VARIABLES.regionalEvent.lista_percursos);
            if (isArray(VARIABLES.regionalCourses)) for (VARIABLES.regionalCourse in VARIABLES.regionalCourses) {
                if (isStruct(VARIABLES.regionalCourse) && structKeyExists(VARIABLES.regionalCourse,"percurso") && isNumeric(VARIABLES.regionalCourse.percurso)
                    && structKeyExists(VARIABLES.regionalCourse,"unidade") && compareNoCase(trim(VARIABLES.regionalCourse.unidade),"km") EQ 0
                    && listFind("5,10,21,42", toString(VARIABLES.regionalCourse.percurso))) {
                    VARIABLES.regionalDistances[toString(VARIABLES.regionalCourse.percurso)] = true;
                }
            }
        }
    }
}
VARIABLES.regionalFilterParts = [];
for (VARIABLES.regionalKey in listToArray("tempo,rua,trail,nacional,internacional,cupom,badges")) {
    if (structKeyExists(URL,VARIABLES.regionalKey) && len(trim(URL[VARIABLES.regionalKey] & ""))) arrayAppend(VARIABLES.regionalFilterParts,VARIABLES.regionalKey & "=" & urlEncodedFormat(URL[VARIABLES.regionalKey]));
}
VARIABLES.regionalOtherFilters = arrayLen(VARIABLES.regionalFilterParts) ? "&" & arrayToList(VARIABLES.regionalFilterParts,"&") : "";
VARIABLES.regionalPeriod = "";
if (listLen(URL.tempo) EQ 2 && isNumeric(listFirst(URL.tempo)) && isNumeric(listLast(URL.tempo))) {
    VARIABLES.regionalPeriod = dateFormat(dateAdd("d",val(listFirst(URL.tempo))*30,now()),"dd/mm/yyyy") & " a " & dateFormat(dateAdd("d",val(listLast(URL.tempo))*30,now()),"dd/mm/yyyy");
}
</cfscript>
<cfoutput>
<section class="rr-regional-summary" aria-label="Resumo do calendário" data-regional-summary data-regional-total="#VARIABLES.regionalTotal#">
    <p class="rr-regional-summary-count"><strong>#lsNumberFormat(VARIABLES.regionalTotal)# <cfif VARIABLES.regionalTotal EQ 1>prova cadastrada<cfelse>provas cadastradas</cfif></strong> para os filtros selecionados.</p>
    <cfif len(VARIABLES.regionalPeriod)><p class="rr-regional-period">Período: #encodeForHTML(VARIABLES.regionalPeriod)#.</p></cfif>
    <cfif VARIABLES.regionalTotal GT 0>
        <nav class="rr-regional-shortcuts" aria-label="Filtrar provas por distância">
            <cfloop array="#VARIABLES.regionalOptions#" index="regionalOption"><cfif structKeyExists(VARIABLES.regionalDistances,toString(regionalOption.km))>
                <a href="#encodeForHTMLAttribute(VARIABLES.regionalPath & '?distancia=' & regionalOption.km & '%2C' & regionalOption.km & VARIABLES.regionalOtherFilters)#"<cfif URL.distancia EQ (regionalOption.km & ',' & regionalOption.km)> aria-current="true"</cfif>>#regionalOption.label#</a>
            </cfif></cfloop>
            <a href="#encodeForHTMLAttribute(VARIABLES.regionalPath)#">Limpar filtros</a>
        </nav>
    <cfelse>
        <div class="rr-regional-empty" role="status">
            <p>Não encontramos provas cadastradas nesta seleção. Amplie o período ou remova filtros para consultar outras opções.</p>
            <a href="#encodeForHTMLAttribute(VARIABLES.regionalPath)#">Limpar filtros nesta localidade</a>
            <cfif len(VARIABLES.regionalCity)> · <a href="#encodeForHTMLAttribute(VARIABLES.regionalRoot)#">Ver calendário do estado</a></cfif>
        </div>
    </cfif>
    <details class="rr-regional-help"><summary>Como consultar este calendário</summary>
        <p>O período considera a data final cadastrada de cada prova. Abra o evento para conferir datas, distâncias, regulamento e informações de inscrição. Consulte as condições de qualquer cupom antes de utilizá-lo.</p>
        <p>Para planejar o tempo de prova, use a <a href="/calculadora-de-pace/?estado=#lCase(URL.tag)#">calculadora de pace</a>.</p>
    </details>
</section>
</cfoutput>
</cfif>
