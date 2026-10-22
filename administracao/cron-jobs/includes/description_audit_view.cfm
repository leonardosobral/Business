<cfif NOT structKeyExists(VARIABLES,"descriptionAuditCanAdmin") OR NOT VARIABLES.descriptionAuditCanAdmin><cfheader statuscode="403"><cfabort></cfif>
<style>
.description-audit-text{white-space:pre-wrap;overflow-wrap:anywhere;font-family:inherit;font-size:.9rem;line-height:1.65;margin:0;max-height:65vh;overflow:auto;padding:1rem}
.description-audit-values{overflow-wrap:anywhere;max-width:40rem}.description-audit-values code{white-space:pre-wrap;color:inherit}
.description-audit-table td{vertical-align:top}.description-audit-nav a[aria-current=page]{background:var(--mdb-primary);color:white}
</style>
<cfoutput>
<div class="d-flex flex-wrap align-items-start justify-content-between gap-3 mb-4">
  <div><h1 class="h3 mb-2">Auditoria de descrições</h1><p class="text-body-secondary mb-0">Respostas rejeitadas · acesso privado dos administradores globais.</p></div>
  <a class="btn btn-sm btn-outline-secondary" href="descricoes.cfm">Fila de descrições</a>
</div>
<div class="alert alert-info small" role="note">As versões rejeitadas não são publicadas nem reaproveitadas automaticamente. Esta tela não faz novas chamadas à IA.</div>
<cfif len(VARIABLES.auditError)><div class="alert alert-warning" role="alert">#encodeForHTML(VARIABLES.auditError)#</div></cfif>
<cfif NOT structIsEmpty(VARIABLES.auditSelected)>
  <section id="comparacao" class="card mb-4" aria-labelledby="audit-detail-title">
    <div class="card-body">
      <div class="d-flex flex-wrap justify-content-between gap-3 mb-3">
        <div><h2 class="h5 mb-2" id="audit-detail-title">#encodeForHTML(VARIABLES.auditSelected.nome_evento)#</h2><div class="small text-body-secondary">Evento #VARIABLES.auditSelected.id_evento# · #encodeForHTML(VARIABLES.auditSelected.language)# · #encodeForHTML(VARIABLES.auditSelected.occurred_at)# (Brasília)</div></div>
        <a class="btn btn-sm btn-outline-secondary align-self-start" href="/eventos/?id_evento=#VARIABLES.auditSelected.id_evento#&amp;sessao=conteudo">Abrir evento</a>
      </div>
      <div class="small mb-3"><span class="badge text-bg-danger">Rejeitado</span> <code>#encodeForHTML(VARIABLES.auditSelected.error_code ?: 'validation_rejected')#</code></div>
      <cfif structIsEmpty(VARIABLES.auditEvidence)>
        <div class="alert alert-warning mb-0">A resposta rejeitada não foi guardada neste registro. Registros antigos não podem ser reconstruídos sem uma nova geração; nenhuma reanálise foi acionada.</div>
      <cfelse>
        <nav class="nav nav-pills gap-2 mb-3 description-audit-nav" aria-label="Visualização da comparação">
          <a class="nav-link" <cfif VARIABLES.auditView EQ "facts">aria-current="page"</cfif> href="?audit_id=#VARIABLES.auditId#&amp;language=#encodeForURL(VARIABLES.auditSelected.language)#&amp;event_id=#VARIABLES.auditEventId GT 0 ? VARIABLES.auditEventId : ''#&amp;pagina=#VARIABLES.auditPage#&amp;view=facts##comparacao">Dados divergentes</a>
          <a class="nav-link" <cfif VARIABLES.auditView EQ "texts">aria-current="page"</cfif> href="?audit_id=#VARIABLES.auditId#&amp;language=#encodeForURL(VARIABLES.auditSelected.language)#&amp;event_id=#VARIABLES.auditEventId GT 0 ? VARIABLES.auditEventId : ''#&amp;pagina=#VARIABLES.auditPage#&amp;view=texts##comparacao">Textos completos</a>
        </nav>
        <cfif len(VARIABLES.auditEvidence.reviewReason)><div class="border rounded p-3 mb-3 small"><strong>Parecer da revisão independente:</strong> #encodeForHTML(VARIABLES.auditEvidence.reviewReason)#</div></cfif>
        <cfif VARIABLES.auditView EQ "facts">
          <p class="small text-body-secondary">Valores presentes só na fonte ou só na resposta. A comparação usa as mesmas normalizações da validação; listas não atribuem automaticamente uma substituição a outra.</p>
          <cfset VARIABLES.auditHasDifferences=false>
          <div class="table-responsive"><table class="table description-audit-table"><thead><tr><th>Tipo de dado</th><th>Na fonte, ausente na resposta</th><th>Na resposta, ausente na fonte</th></tr></thead><tbody>
          <cfloop list="numbers,distances,times,durations,units,dates,currencies,urls,emails" index="VARIABLES.auditKind">
            <cfif NOT structKeyExists(VARIABLES.auditDifferences,VARIABLES.auditKind)><cfcontinue></cfif>
            <cfset VARIABLES.auditDelta=VARIABLES.auditDifferences[VARIABLES.auditKind]>
            <cfif NOT VARIABLES.auditDelta.missingTotal AND NOT VARIABLES.auditDelta.addedTotal><cfcontinue></cfif>
            <cfset VARIABLES.auditHasDifferences=true>
            <tr><th scope="row">#encodeForHTML(VARIABLES.auditDelta.label)#</th>
              <cfloop list="missing,added" index="VARIABLES.auditSide"><td class="description-audit-values">
                <cfif NOT arrayLen(VARIABLES.auditDelta[VARIABLES.auditSide])><span class="text-body-secondary">—</span><cfelse><ul class="mb-0 ps-3"><cfloop array="#VARIABLES.auditDelta[VARIABLES.auditSide]#" index="VARIABLES.auditValue"><li><code>#encodeForHTML(VARIABLES.auditValue)#</code></li></cfloop></ul></cfif>
                <cfif VARIABLES.auditDelta[VARIABLES.auditSide & 'Total'] GT 100><small class="text-body-secondary">Exibindo 100 de #VARIABLES.auditDelta[VARIABLES.auditSide & 'Total']# valores; consulte os textos completos.</small></cfif>
              </td></cfloop>
            </tr>
          </cfloop>
          </tbody></table></div>
          <cfif NOT VARIABLES.auditHasDifferences><p class="small mb-0">Não há diferenças nos valores extraídos automaticamente. A rejeição pode envolver formato, idioma, nomes, omissões ou relações entre os fatos. Consulte o parecer e os textos completos.</p></cfif>
        <cfelse>
          <div class="row g-3"><div class="col-12 col-xl-6"><div class="border rounded h-100"><h3 class="h6 border-bottom p-3 mb-0">Fonte utilizada pela IA</h3><pre class="description-audit-text">#encodeForHTML(VARIABLES.auditEvidence.source)#</pre></div></div>
          <div class="col-12 col-xl-6"><div class="border rounded h-100"><h3 class="h6 border-bottom p-3 mb-0">Resposta rejeitada — não publicada</h3><pre class="description-audit-text">#encodeForHTML(VARIABLES.auditEvidence.candidate)#</pre></div></div></div>
        </cfif>
      </cfif>
    </div>
  </section>
</cfif>
<section class="card"><div class="card-body">
  <h2 class="h5 mb-3">Histórico de rejeições</h2>
  <form method="get" class="d-flex flex-wrap align-items-end gap-3 mb-3">
    <div><label class="form-label" for="audit-event">ID do evento</label><input class="form-control" id="audit-event" name="event_id" inputmode="numeric" value="#VARIABLES.auditEventId GT 0 ? VARIABLES.auditEventId : ''#"></div>
    <div><label class="form-label" for="audit-language">Idioma</label><select class="form-select" id="audit-language" name="language"><option value="">Todos</option><cfloop list="pt-BR,en,es" index="VARIABLES.auditLocale"><option value="#VARIABLES.auditLocale#" <cfif VARIABLES.auditLanguage EQ VARIABLES.auditLocale>selected</cfif>>#VARIABLES.auditLocale#</option></cfloop></select></div>
    <button class="btn btn-primary" type="submit">Filtrar</button><a class="btn btn-outline-secondary" href="descricoes-auditoria.cfm">Limpar</a>
  </form>
  <div class="table-responsive"><table class="table align-middle"><thead><tr><th>Data (Brasília)</th><th>Evento</th><th>Idioma</th><th>Motivo</th><th>Resposta</th><th><span class="visually-hidden">Ação</span></th></tr></thead><tbody>
  <cfif NOT VARIABLES.auditRows.recordCount><tr><td colspan="6" class="text-body-secondary">Nenhuma rejeição encontrada para estes filtros.</td></tr></cfif>
  <cfloop query="VARIABLES.auditRows" endrow="20"><tr>
    <td class="text-nowrap">#encodeForHTML(VARIABLES.auditRows.occurred_at)#</td><td>#encodeForHTML(VARIABLES.auditRows.nome_evento)#<div class="small text-body-secondary">ID #VARIABLES.auditRows.id_evento#</div></td>
    <td>#encodeForHTML(VARIABLES.auditRows.language)#</td><td class="small"><code>#encodeForHTML(VARIABLES.auditRows.error_code ?: 'validation_rejected')#</code></td><td class="small">#VARIABLES.auditRows.has_output ? 'Guardada' : 'Indisponível'#</td>
    <td><a class="btn btn-sm btn-outline-secondary" href="?audit_id=#VARIABLES.auditRows.id#&amp;language=#encodeForURL(VARIABLES.auditRows.language)#&amp;event_id=#VARIABLES.auditEventId GT 0 ? VARIABLES.auditEventId : ''#&amp;pagina=#VARIABLES.auditPage###comparacao">Comparar</a></td>
  </tr></cfloop></tbody></table></div>
  <nav class="d-flex gap-3 align-items-center" aria-label="Paginação das rejeições">
    <cfif VARIABLES.auditPage GT 1><a href="?event_id=#VARIABLES.auditEventId GT 0 ? VARIABLES.auditEventId : ''#&amp;language=#encodeForURL(VARIABLES.auditLanguage)#&amp;pagina=#VARIABLES.auditPage-1#">Anterior</a></cfif><span class="small">Página #VARIABLES.auditPage#</span>
    <cfif VARIABLES.auditHasNext><a href="?event_id=#VARIABLES.auditEventId GT 0 ? VARIABLES.auditEventId : ''#&amp;language=#encodeForURL(VARIABLES.auditLanguage)#&amp;pagina=#VARIABLES.auditPage+1#">Próxima</a></cfif>
  </nav>
</div></section>
</cfoutput>
