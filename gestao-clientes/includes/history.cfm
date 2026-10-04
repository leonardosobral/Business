<h2 class="h4">Histórico</h2>
<cfif arrayLen(VARIABLES.wsAuditPage.items) EQ 0><p>Nenhum registro neste filtro.</p></cfif>
<div class="table-responsive"><table class="table table-sm"><thead><tr><th>Data</th><th>Cliente</th><th>Responsável</th><th>Ação</th><th>Resultado</th></tr></thead><tbody>
<cfloop array="#VARIABLES.wsAuditPage.items#" index="wsAudit"><cfoutput><tr><td>#dateTimeFormat(wsAudit.happenedAt,'dd/mm/yyyy HH:nn')#</td><td>#encodeForHTML(wsAudit.clientName)#</td><td>#encodeForHTML(wsAudit.actorName)#</td><td>#encodeForHTML(VARIABLES.wsView.label(wsAudit.action))#</td><td>#encodeForHTML(VARIABLES.wsView.label(wsAudit.status))#</td></tr></cfoutput></cfloop>
</tbody></table></div>
