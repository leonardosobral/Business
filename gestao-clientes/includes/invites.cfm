<h2 class="h4">Convites</h2><p class="small text-muted">Links de titularidade são mostrados somente no momento da emissão ou renovação.</p>
<cfif arrayLen(VARIABLES.wsInvitesPage.items) EQ 0><p>Nenhum convite neste filtro.</p></cfif>
<div class="table-responsive"><table class="table table-sm"><thead><tr><th>Cliente</th><th>Tipo</th><th>Destinatário</th><th>Estado</th><th>Prazo</th></tr></thead><tbody>
<cfloop array="#VARIABLES.wsInvitesPage.items#" index="wsInvite"><cfoutput><tr><td>#encodeForHTML(wsInvite.clientName)#</td><td>#encodeForHTML(VARIABLES.wsView.label(wsInvite.type))#</td><td>#encodeForHTML(wsInvite.recipient)#</td><td>#encodeForHTML(VARIABLES.wsView.label(wsInvite.status))#</td><td>#dateTimeFormat(wsInvite.expiresAt,'dd/mm/yyyy HH:nn')#</td></tr></cfoutput></cfloop>
</tbody></table></div>
