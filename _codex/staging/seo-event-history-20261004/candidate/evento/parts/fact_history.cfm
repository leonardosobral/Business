<cfprocessingdirective pageencoding="utf-8"/>
<cfif compareNoCase(getBaseTemplatePath(), getCurrentTemplatePath()) EQ 0><cfheader statuscode="403"/><cfabort/></cfif>
<cfif NOT structKeyExists(VARIABLES,"eventFactHistory")><cfinclude template="fact_history_data.cfm"/></cfif>
<cfscript>
VARIABLES.eventHistoryRows=[];
VARIABLES.eventHistoryKey=qEvento.id_evento[1] & "";
VARIABLES.eventHistoryLang=structKeyExists(REQUEST,"lang") ? lCase(REQUEST.lang) : "pt-br";
VARIABLES.eventHistoryLabels={
 "pt-br"={title="Histórico de correções do cadastro",scope="Valores corrigidos no RoadRunners após consulta à fonte. Este histórico não é uma confirmação atual de todos os dados nem indica, por si só, adiamento da prova.",recorded="Correção registrada em",before="Antes no cadastro",after="Corrigido para",source="Fonte consultada",routeDate="Data dos percursos",descriptionDate="Data na descrição"},
 en={title="Listing correction history",scope="Values corrected on RoadRunners after checking the source. This history does not confirm all current details or, by itself, indicate that the race was postponed.",recorded="Correction recorded on",before="Previously listed",after="Corrected to",source="Source consulted",routeDate="Course dates",descriptionDate="Date in the description"},
 es={title="Historial de correcciones del registro",scope="Valores corregidos en RoadRunners tras consultar la fuente. Este historial no confirma todos los datos actuales ni indica, por sí solo, que la carrera fue aplazada.",recorded="Corrección registrada el",before="Antes en el registro",after="Corregido a",source="Fuente consultada",routeDate="Fechas de los recorridos",descriptionDate="Fecha en la descripción"}
};
if (!structKeyExists(VARIABLES.eventHistoryLabels,VARIABLES.eventHistoryLang)) VARIABLES.eventHistoryLang="pt-br";
if (isStruct(VARIABLES.eventFactHistory) && structKeyExists(VARIABLES.eventFactHistory,VARIABLES.eventHistoryKey) && isArray(VARIABLES.eventFactHistory[VARIABLES.eventHistoryKey])) {
 for (VARIABLES.eventHistoryCandidate in VARIABLES.eventFactHistory[VARIABLES.eventHistoryKey]) {
  VARIABLES.eventHistoryValid=isStruct(VARIABLES.eventHistoryCandidate);
  if (VARIABLES.eventHistoryValid) {
   for (VARIABLES.eventHistoryField in listToArray("recordedAt,field,detail,before,after,sourceUrl,sourceLabel")) {
    if (!structKeyExists(VARIABLES.eventHistoryCandidate,VARIABLES.eventHistoryField) || !isSimpleValue(VARIABLES.eventHistoryCandidate[VARIABLES.eventHistoryField])) VARIABLES.eventHistoryValid=false;
   }
  }
  if (VARIABLES.eventHistoryValid) {
   for (VARIABLES.eventHistoryField in listToArray("recordedAt,before,after")) {
    VARIABLES.eventHistoryDate=VARIABLES.eventHistoryCandidate[VARIABLES.eventHistoryField] & "";
    if (!reFind("^[0-9]{4}-[0-9]{2}-[0-9]{2}$",VARIABLES.eventHistoryDate) || !isDate(VARIABLES.eventHistoryDate)) {
     VARIABLES.eventHistoryValid=false;
    } else if (dateFormat(parseDateTime(VARIABLES.eventHistoryDate),"yyyy-mm-dd") != VARIABLES.eventHistoryDate) {
     VARIABLES.eventHistoryValid=false;
    }
   }
  }
  if (VARIABLES.eventHistoryValid) {
   VARIABLES.eventHistoryUrl=trim(VARIABLES.eventHistoryCandidate.sourceUrl & "");
   VARIABLES.eventHistoryValid=listFind("routeDate,descriptionDate",VARIABLES.eventHistoryCandidate.field) > 0
    && VARIABLES.eventHistoryCandidate.before != VARIABLES.eventHistoryCandidate.after
    && dateCompare(parseDateTime(VARIABLES.eventHistoryCandidate.recordedAt),now(),"d") <= 0
    && len(trim(VARIABLES.eventHistoryCandidate.sourceLabel)) > 0
    && (VARIABLES.eventHistoryCandidate.field != "routeDate" || len(trim(VARIABLES.eventHistoryCandidate.detail)) > 0)
    && isValid("url",VARIABLES.eventHistoryUrl) && reFindNoCase("^https?://",VARIABLES.eventHistoryUrl)
    && !reFindNoCase("^https?://[^/?##]*@",VARIABLES.eventHistoryUrl)
    && !find(chr(92),VARIABLES.eventHistoryUrl) && !reFind("[\r\n]",VARIABLES.eventHistoryUrl);
   if (VARIABLES.eventHistoryValid) arrayAppend(VARIABLES.eventHistoryRows,VARIABLES.eventHistoryCandidate);
  }
 }
}
VARIABLES.eventHistoryText=VARIABLES.eventHistoryLabels[VARIABLES.eventHistoryLang];
</cfscript>
<cfif arrayLen(VARIABLES.eventHistoryRows)>
 <div class="event-page-card-body pt-0 small" data-event-source="correction-history">
  <details>
   <summary class="mb-2"><cfoutput>#encodeForHTML(VARIABLES.eventHistoryText.title)#</cfoutput></summary>
   <p class="text-muted"><cfoutput>#encodeForHTML(VARIABLES.eventHistoryText.scope)#</cfoutput></p>
   <ul class="mb-0 ps-3">
    <cfloop array="#VARIABLES.eventHistoryRows#" item="VARIABLES.eventHistoryRow">
     <li class="mb-3"><cfoutput>
      <strong>#encodeForHTML(VARIABLES.eventHistoryText[VARIABLES.eventHistoryRow.field])#<cfif len(trim(VARIABLES.eventHistoryRow.detail))>: #encodeForHTML(VARIABLES.eventHistoryRow.detail)#</cfif></strong><br>
      #encodeForHTML(VARIABLES.eventHistoryText.recorded)# <time datetime="#encodeForHTMLAttribute(VARIABLES.eventHistoryRow.recordedAt)#">#dateFormat(parseDateTime(VARIABLES.eventHistoryRow.recordedAt),"dd/mm/yyyy")#</time>.<br>
      #encodeForHTML(VARIABLES.eventHistoryText.before)#: <time datetime="#encodeForHTMLAttribute(VARIABLES.eventHistoryRow.before)#">#dateFormat(parseDateTime(VARIABLES.eventHistoryRow.before),"dd/mm/yyyy")#</time>.
      #encodeForHTML(VARIABLES.eventHistoryText.after)#: <time datetime="#encodeForHTMLAttribute(VARIABLES.eventHistoryRow.after)#">#dateFormat(parseDateTime(VARIABLES.eventHistoryRow.after),"dd/mm/yyyy")#</time>.<br>
      <a href="#encodeForHTMLAttribute(trim(VARIABLES.eventHistoryRow.sourceUrl))#" target="_blank" rel="noopener noreferrer">#encodeForHTML(VARIABLES.eventHistoryText.source)#: #encodeForHTML(VARIABLES.eventHistoryRow.sourceLabel)#</a>
     </cfoutput></li>
    </cfloop>
   </ul>
  </details>
 </div>
</cfif>
