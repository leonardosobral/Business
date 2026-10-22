<cfif NOT isDefined("qEvento") OR NOT qEvento.recordCount><cfabort></cfif>
<cfif listFindNoCase(qEvento.columnList,"localizacoes") AND isJSON(qEvento.localizacoes & "")>
<cfset VARIABLES.eventLocations=deserializeJSON(qEvento.localizacoes & "")>
<cfif isStruct(VARIABLES.eventLocations) AND NOT structIsEmpty(VARIABLES.eventLocations)>
<details class="border rounded p-3 mb-3"><summary class="fw-bold">Locais confirmados · prova e retirada de kit</summary><div class="row g-3 mt-1">
<cfloop list="evento,kit" index="VARIABLES.eventLocationRole"><cfif structKeyExists(VARIABLES.eventLocations,VARIABLES.eventLocationRole)>
<cfset VARIABLES.eventLocationItems=isArray(VARIABLES.eventLocations[VARIABLES.eventLocationRole]) ? VARIABLES.eventLocations[VARIABLES.eventLocationRole] : [VARIABLES.eventLocations[VARIABLES.eventLocationRole]]>
<cfloop array="#VARIABLES.eventLocationItems#" index="VARIABLES.eventLocationItem"><cfoutput>
<div class="col-md-6"><h3 class="h6">#VARIABLES.eventLocationRole EQ 'kit' ? 'Retirada de kit' : 'Local da prova'#</h3><p class="mb-1"><strong>#encodeForHTML(VARIABLES.eventLocationItem.nome_local ?: '')#</strong></p><p class="small mb-1">#encodeForHTML(VARIABLES.eventLocationItem.endereco ?: '')#<br>#encodeForHTML(VARIABLES.eventLocationItem.cidade ?: '')# / #encodeForHTML(VARIABLES.eventLocationItem.uf ?: '')# · #encodeForHTML(VARIABLES.eventLocationItem.pais ?: '')#</p><div class="small">#encodeForHTML(VARIABLES.eventLocationItem.coordenadas ?: '')#</div>
<cfif structKeyExists(VARIABLES.eventLocationItem,'fonte') AND isStruct(VARIABLES.eventLocationItem.fonte) AND reFindNoCase('^https://',VARIABLES.eventLocationItem.fonte.url ?: '')><a class="small" target="_blank" rel="noopener noreferrer" href="#encodeForHTMLAttribute(VARIABLES.eventLocationItem.fonte.url)#">Fonte da confirmação</a></cfif></div>
</cfoutput></cfloop></cfif></cfloop></div><p class="small text-body-secondary mb-0 mt-2">Proveniência preservada pela automação. A coordenada principal continua representando somente a prova.</p></details>
</cfif></cfif>
<cfinclude template="enriquecimento_confirmado.cfm">
