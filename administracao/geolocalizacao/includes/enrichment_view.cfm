<cfif NOT structKeyExists(VARIABLES,"geoCanAdmin") OR NOT VARIABLES.geoCanAdmin><cfheader statuscode="403"><cfabort></cfif>
<cfset VARIABLES.geoFieldLabels={fill="Aguardando gravação",auto_applied="Preenchido automaticamente",approved="Aprovado pelo operador",equivalent="Equivalente · sem ação",needs_review="Divergência para revisão",unconfirmed="Não confirmado · não publicado",rejected="Cadastro mantido"}>
<cfoutput>
<p class="small text-body-secondary">A mesma análise do Astra extrai os dados abaixo. Campos vazios só são preenchidos com evidência da edição correta; siglas e nomes equivalentes não geram revisão. Aceitar uma divergência exige confirmação explícita.</p>
<cfif structKeyExists(VARIABLES.geoDecision,'enrichment') AND arrayLen(VARIABLES.geoDecision.enrichment.fields)>
<div class="table-responsive"><table class="table align-middle"><thead><tr><th>Informação</th><th>Cadastro atual</th><th>Informação da fonte</th><th>Revisão</th></tr></thead><tbody>
<cfloop from="1" to="#arrayLen(VARIABLES.geoDecision.enrichment.fields)#" index="VARIABLES.geoFieldIndex"><cfset VARIABLES.geoField=VARIABLES.geoDecision.enrichment.fields[VARIABLES.geoFieldIndex]>
<tr><td class="small"><strong>#encodeForHTML(VARIABLES.geoField.label)#</strong><div class="mt-1"><span class="badge #VARIABLES.geoField.status EQ 'needs_review' ? 'text-bg-warning' : 'text-bg-secondary'#">#encodeForHTML(VARIABLES.geoFieldLabels[VARIABLES.geoField.status] ?: VARIABLES.geoField.status)#</span></div></td>
<td class="small geo-value" style="white-space:pre-line">#encodeForHTML(VARIABLES.geoField.current ?: 'Não preenchido')#</td><td class="small geo-value" style="white-space:pre-line">#encodeForHTML(VARIABLES.geoField.value)#
<cfif structKeyExists(VARIABLES.geoField.evidence,'excerpt')><details class="mt-2"><summary>Ver evidência</summary><blockquote class="border-start ps-2 mt-2">#encodeForHTML(VARIABLES.geoField.evidence.excerpt)#</blockquote><cfif reFindNoCase('^https://',VARIABLES.geoField.evidence.url ?: '')><a target="_blank" rel="noopener noreferrer" href="#encodeForHTMLAttribute(VARIABLES.geoField.evidence.url)#">Abrir fonte</a></cfif></details></cfif></td>
<td class="small"><cfif VARIABLES.geoField.status EQ 'needs_review' AND listFind('needs_review,city_suggestion,insufficient_data,auto_applied,approved,pending,error',VARIABLES.geoSelected.status)>
<form method="post" data-geo-confirm="Confirmar a revisão deste campo? Aceitar a fonte substituirá explicitamente o valor atual; manter cadastro não o altera.">
<input type="hidden" name="csrf" value="#encodeForHTMLAttribute(csrfGenerateToken('event-geocoding'))#"><input type="hidden" name="id" value="#VARIABLES.geoSelected.id#"><input type="hidden" name="attribute" value="#VARIABLES.geoFieldIndex#"><input type="hidden" name="revision" value="#VARIABLES.geoSelected.proposal_revision#"><input type="hidden" name="confirmed" value="1">
<div class="d-flex flex-wrap gap-2"><cfif VARIABLES.geoField.trusted><button class="btn btn-success btn-sm" name="action" value="approve_field">Aceitar fonte</button></cfif><button class="btn btn-outline-secondary btn-sm" name="action" value="reject_field">Manter cadastro</button></div></form>
<cfif NOT VARIABLES.geoField.trusted><p class="text-warning mt-2">As fontes divergem. Confira e ajuste no cadastro; não há substituição automática.</p></cfif>
<cfelseif VARIABLES.geoField.status EQ 'unconfirmed'><span class="text-body-secondary">Sem evidência suficiente; nada foi presumido.</span>
<cfelse><span class="text-body-secondary">Nenhuma ação necessária.</span></cfif></td></tr>
</cfloop></tbody></table></div>
<p class="small text-body-secondary">Preços e lotes são registros da fonte, com sua validade; não substituem automaticamente a tabela comercial vigente. Nenhuma justificativa digitada é obrigatória para revisar.</p>
<cfelse><p class="text-body-secondary">Esta análise ainda não trouxe dados complementares confirmados. Trabalhos anteriores são atualizados pela fila automática; nenhum valor é inventado.</p></cfif>
</cfoutput>
