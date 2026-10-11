<cfprocessingdirective pageencoding="utf-8"/>
<cfif compareNoCase(getBaseTemplatePath(), getCurrentTemplatePath()) EQ 0><cfheader statuscode="403"/><cfabort/></cfif>
<cfif NOT structKeyExists(VARIABLES, "eventFactReviews")><cfinclude template="fact_review_data.cfm"/></cfif>
<cfscript>
VARIABLES.eventFactReview = {};
VARIABLES.eventFactReviewKey = qEvento.id_evento[1] & "";
VARIABLES.eventFactReviewLang = structKeyExists(REQUEST, "lang") ? lCase(REQUEST.lang) : "pt-br";
VARIABLES.eventFactReviewLabels = {
 "pt-br"={title="Fonte das datas do evento", checked="Datas conferidas em", scope="Conferência das datas de início e término. Local, horários e inscrições não foram verificados nesta conferência.", source="Consultar fonte", period="Datas conferidas"},
 en={title="Source for the event dates", checked="Dates checked on", scope="This review covers the start and end dates. Venue, times and registration were not verified in this review.", source="View source", period="Dates reviewed"},
 es={title="Fuente de las fechas del evento", checked="Fechas comprobadas el", scope="Esta revisión cubre las fechas de inicio y fin. El lugar, los horarios y las inscripciones no se verificaron en esta revisión.", source="Consultar fuente", period="Fechas revisadas"}
};
if (!structKeyExists(VARIABLES.eventFactReviewLabels, VARIABLES.eventFactReviewLang)) VARIABLES.eventFactReviewLang="pt-br";
// Once Business manages a public receipt, never fall back to an older manual receipt.
// A withdrawn or malformed value hides the date review while keeping correction history.
if (structKeyExists(qEvento,"conferencia_datas_publica") && len(trim(qEvento.conferencia_datas_publica[1] & ""))) {
 structDelete(VARIABLES.eventFactReviews,VARIABLES.eventFactReviewKey);
 try {
  VARIABLES.publicDateReceipt=deserializeJSON(qEvento.conferencia_datas_publica[1]);
  VARIABLES.publicDateReceiptValid=isStruct(VARIABLES.publicDateReceipt);
  for (VARIABLES.publicDateField in ["version","state","reviewId","startDate","endDate","checkedAt","sourceUrl"]) {
   if (!VARIABLES.publicDateReceiptValid || !structKeyExists(VARIABLES.publicDateReceipt,VARIABLES.publicDateField) || !isSimpleValue(VARIABLES.publicDateReceipt[VARIABLES.publicDateField])) VARIABLES.publicDateReceiptValid=false;
  }
  if (VARIABLES.publicDateReceiptValid && VARIABLES.publicDateReceipt.version == 1 && VARIABLES.publicDateReceipt.state == "published"
      && reFind("^[1-9][0-9]*$",VARIABLES.publicDateReceipt.reviewId)
      && reFind("^[0-9]{4}-[0-9]{2}-[0-9]{2}$",VARIABLES.publicDateReceipt.startDate)
      && reFind("^[0-9]{4}-[0-9]{2}-[0-9]{2}$",VARIABLES.publicDateReceipt.endDate)
      && new services.EventRegistrationAvailability().isSourceUrl(VARIABLES.publicDateReceipt.sourceUrl)) {
   VARIABLES.publicDateReceipt.sourceLabel=createObject("java","java.net.URI").init(VARIABLES.publicDateReceipt.sourceUrl).getHost();
   VARIABLES.eventFactReviews[VARIABLES.eventFactReviewKey]=VARIABLES.publicDateReceipt;
  }
 } catch (any invalidPublicReceipt) { /* Optional receipt must not break the event page. */ }
}
if (structKeyExists(VARIABLES.eventFactReviews, VARIABLES.eventFactReviewKey)) {
 VARIABLES.eventFactReviewCandidate=VARIABLES.eventFactReviews[VARIABLES.eventFactReviewKey];
 if (isStruct(VARIABLES.eventFactReviewCandidate)
     && structKeyExists(VARIABLES.eventFactReviewCandidate,"startDate")
     && structKeyExists(VARIABLES.eventFactReviewCandidate,"endDate")
     && structKeyExists(VARIABLES.eventFactReviewCandidate,"checkedAt")
     && structKeyExists(VARIABLES.eventFactReviewCandidate,"sourceUrl")
     && structKeyExists(VARIABLES.eventFactReviewCandidate,"sourceLabel")) {
  VARIABLES.eventFactReviewCandidateUrl=trim(VARIABLES.eventFactReviewCandidate.sourceUrl & "");
  if (isDate(qEvento.data_inicial[1]) && isDate(qEvento.data_final[1])
      && dateFormat(qEvento.data_inicial[1],"yyyy-mm-dd") == VARIABLES.eventFactReviewCandidate.startDate
      && dateFormat(qEvento.data_final[1],"yyyy-mm-dd") == VARIABLES.eventFactReviewCandidate.endDate
      && reFind("^[0-9]{4}-[0-9]{2}-[0-9]{2}$",VARIABLES.eventFactReviewCandidate.checkedAt)
      && isDate(VARIABLES.eventFactReviewCandidate.checkedAt)
      && dateCompare(parseDateTime(VARIABLES.eventFactReviewCandidate.checkedAt),now(),"d") <= 0
      && isValid("url",VARIABLES.eventFactReviewCandidateUrl)
      && reFindNoCase("^https?://",VARIABLES.eventFactReviewCandidateUrl)
      && !reFindNoCase("^https?://[^/?##]*@",VARIABLES.eventFactReviewCandidateUrl)
      && !find(chr(92),VARIABLES.eventFactReviewCandidateUrl)) {
    VARIABLES.eventFactReview=VARIABLES.eventFactReviewCandidate;
  }
 }
}
</cfscript>
<cfif NOT structIsEmpty(VARIABLES.eventFactReview)>
 <cfset VARIABLES.eventFactReviewText=VARIABLES.eventFactReviewLabels[VARIABLES.eventFactReviewLang]/>
 <aside class="event-page-card-body pt-0 small" data-event-source="date-review" aria-label="<cfoutput>#encodeForHTMLAttribute(VARIABLES.eventFactReviewText.title)#</cfoutput>">
  <cfoutput>
   <p class="mb-1"><strong>#encodeForHTML(VARIABLES.eventFactReviewText.title)#</strong></p>
   <p class="mb-1">#encodeForHTML(VARIABLES.eventFactReviewText.period)#: <time datetime="#encodeForHTMLAttribute(VARIABLES.eventFactReview.startDate)#">#dateFormat(qEvento.data_inicial[1],"dd/mm/yyyy")#</time><cfif VARIABLES.eventFactReview.startDate NEQ VARIABLES.eventFactReview.endDate> – <time datetime="#encodeForHTMLAttribute(VARIABLES.eventFactReview.endDate)#">#dateFormat(qEvento.data_final[1],"dd/mm/yyyy")#</time></cfif>.</p>
   <p class="mb-1">#encodeForHTML(VARIABLES.eventFactReviewText.checked)# <time datetime="#encodeForHTMLAttribute(VARIABLES.eventFactReview.checkedAt)#">#dateFormat(parseDateTime(VARIABLES.eventFactReview.checkedAt),"dd/mm/yyyy")#</time> · <a href="#encodeForHTMLAttribute(VARIABLES.eventFactReview.sourceUrl)#" target="_blank" rel="noopener noreferrer">#encodeForHTML(VARIABLES.eventFactReviewText.source)#: #encodeForHTML(VARIABLES.eventFactReview.sourceLabel)#</a></p>
   <p class="mb-0 text-muted">#encodeForHTML(VARIABLES.eventFactReviewText.scope)#</p>
  </cfoutput>
 </aside>
</cfif>

<cfinclude template="fact_history.cfm"/>
