<cfscript>
teamReviewDecision='APPROVE';teamReviewNote='';teamReviewEvidence='';teamReviewVersion=tt.version;
if(CGI.request_method=='POST'&&teamPostOperation=='review'&&len(teamError)){
 if(structKeyExists(FORM,'decision')&&isSimpleValue(FORM.decision))teamReviewDecision=FORM.decision;
 if(structKeyExists(FORM,'note')&&isSimpleValue(FORM.note))teamReviewNote=left(FORM.note,1600);
 if(structKeyExists(FORM,'evidence')&&isSimpleValue(FORM.evidence))teamReviewEvidence=left(FORM.evidence,1600);
 if(structKeyExists(FORM,'version')&&isSimpleValue(FORM.version)&&reFind('^[0-9]{1,14}$',FORM.version))teamReviewVersion=val(FORM.version);
}
</cfscript>
<section class="teams-panel"><h2>Revisão global RR</h2><p>Confira a identidade, o CREF ativo e a representatividade do Team. Registre a fonte consultada e a data da conferência.</p>
<cfif len(tt.review_note)><p class="teams-alert"><strong>Última orientação:</strong> <cfoutput>#encodeForHTML(tt.review_note)#</cfoutput></p></cfif>
<form class="teams-form" method="post" data-confirm="Registrar esta decisão sobre o Team? Suspender ou encerrar também encerra os vínculos dos atletas, que poderão escolher outro Team.">
<input type="hidden" name="csrf" value="<cfoutput>#teamCsrf#</cfoutput>"><input type="hidden" name="operation" value="review"><input type="hidden" name="version" value="<cfoutput>#teamReviewVersion#</cfoutput>"><input type="hidden" name="team" value="<cfoutput>#teamId#</cfoutput>">
<label class="teams-field full">Decisão<select name="decision"><cfoutput><cfloop array="#[{value='APPROVE',label='Aprovar / reativar'},{value='CHANGES',label='Solicitar ajustes'},{value='REJECT',label='Recusar'},{value='SUSPEND',label='Suspender'},{value='ARCHIVE',label='Encerrar'}]#" index="reviewOption"><option value="#reviewOption.value#" <cfif teamReviewDecision EQ reviewOption.value>selected</cfif>>#encodeForHTML(reviewOption.label)#</option></cfloop></cfoutput></select></label>
<label class="teams-field full">Evidência da consulta do CREF<textarea name="evidence" maxlength="1600" placeholder="Fonte consultada, situação ativa e data de conferência"><cfoutput>#encodeForHTML(teamReviewEvidence)#</cfoutput></textarea></label>
<label class="teams-consent full"><input type="checkbox" name="cref_active" value="yes"><span>Conferi a identidade do responsável técnico e confirmei que seu CREF está ativo. Obrigatório para aprovar ou reativar.</span></label>
<label class="teams-field full">Justificativa ou orientação ao responsável<textarea name="note" maxlength="1600"><cfoutput>#encodeForHTML(teamReviewNote)#</cfoutput></textarea><span class="teams-small teams-muted">Obrigatória para solicitar ajustes, recusar, suspender ou encerrar.</span></label>
<div class="full"><button>Registrar decisão</button></div></form></section>
<cfif len(tt.cref_evidence)><section class="teams-panel"><h2>Última conferência do CREF</h2><p><cfoutput>#encodeForHTML(tt.cref_evidence)#</cfoutput></p><cfif isDate(tt.cref_verified_at)><p class="teams-muted"><cfoutput>#dateTimeFormat(tt.cref_verified_at,'dd/mm/yyyy HH:nn')#</cfoutput></p></cfif></section></cfif>
