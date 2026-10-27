<cfscript>
teamForm={name='',type='ASSESSORIA',document='',ownerName='',technicalName='',cref='',crefUf='',email='',phone='',whatsapp='',city='',uf='',attendance='AMBOS',description='',website=''};
if(CGI.request_method=='POST'&&teamPostOperation=='create'){
 for(teamFormKey in teamForm)if(structKeyExists(FORM,teamFormKey)&&isSimpleValue(FORM[teamFormKey]))teamForm[teamFormKey]=left(FORM[teamFormKey],1600);
}
</cfscript>
<a class="d-inline-block mb-3" href="<cfoutput>#encodeForHTMLAttribute(teamAdminUrl())#</cfoutput>">← Voltar à lista de Teams</a>
<section class="teams-panel"><div class="d-flex flex-wrap justify-content-between align-items-start gap-3 mb-3"><div style="flex:1 1 260px"><h2>Novo Team</h2><p class="teams-muted mb-0">O Team será criado aguardando análise. Depois de salvar, confira o CREF na aba Revisão e convide os responsáveis em Equipe administrativa.</p></div><a href="<cfoutput>#encodeForHTMLAttribute(teamAdminUrl())#</cfoutput>" aria-label="Cancelar novo cadastro">Cancelar</a></div>
<form class="teams-form" method="post" action="<cfoutput>#encodeForHTMLAttribute(teamAdminUrl() & '&novo=1')#</cfoutput>">
<input type="hidden" name="csrf" value="<cfoutput>#teamCsrf#</cfoutput>"><input type="hidden" name="operation" value="create">
<cfinclude template="../../../teams/includes/fields.cfm">
<div class="full d-flex flex-wrap gap-3 align-items-center"><button type="submit">Salvar e revisar</button><a href="<cfoutput>#encodeForHTMLAttribute(teamAdminUrl())#</cfoutput>">Cancelar</a></div>
</form></section>
