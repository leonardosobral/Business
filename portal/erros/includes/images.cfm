<cfif NOT structKeyExists(VARIABLES,"requireAdminAllowed") OR NOT VARIABLES.requireAdminAllowed><cfheader statuscode="403"/><cfabort/></cfif>
<div class="card shadow-0 mb-4"><div class="card-body"><section class="triage-workspace" aria-labelledby="images-heading">
  <h2 id="images-heading" class="h4">Imagens e ícones com 404</h2>
  <p class="text-muted">Caminhos solicitados que retornaram 404, agrupados por site e arquivo. Use esta lista para criar os arquivos necessários ou corrigir os links que apontam para eles.</p>
  <cfif NOT etReady>
    <div class="alert alert-info">A consulta estará disponível após a instalação do acompanhamento.</div>
  <cfelse>
    <cfset etImageSite=left(trim(URL.image_site ?: ""),32)/>
    <cfset etImageSort=(URL.image_sort ?: "recent") EQ "frequency" ? "frequency" : "recent"/>
    <cfset etImages=etService.missingImages({site=etImageSite,sort=etImageSort,page=URL.image_page ?: 1})/>
    <cfoutput>
      <div class="row g-3 mb-3">
        <div class="col-sm-6"><div class="border rounded p-3"><div class="small text-muted">Caminhos de imagens / ícones</div><strong class="fs-4">#etImages.total#</strong></div></div>
        <div class="col-sm-6"><div class="border rounded p-3"><div class="small text-muted">Ocorrências 404 desses arquivos</div><strong class="fs-4">#etImages.occurrences#</strong></div></div>
      </div>
      <p class="small text-muted">Desde #etDate(etImages.window.started_at)# (#etHtml(etImages.window.timezone)#), incluindo logs ainda não coletados. Parâmetros da URL são agrupados no mesmo caminho; o log original mantém a URL completa. A lista é histórica: criar um arquivo não apaga suas ocorrências anteriores.</p>
      <form method="get" action="./" class="row g-3 align-items-end mb-4">
        <input type="hidden" name="aba" value="imagens"/>
        <div class="col-sm-4"><label class="form-label" for="image-site">Site</label><input class="form-control" id="image-site" name="image_site" maxlength="32" placeholder="Todos (ex.: RR)" value="#etHtml(etImageSite)#"/></div>
        <div class="col-sm-5"><label class="form-label" for="image-sort">Ordenar por</label><select class="form-select" id="image-sort" name="image_sort"><option value="recent"<cfif etImageSort EQ "recent"> selected</cfif>>Mais recentes primeiro</option><option value="frequency"<cfif etImageSort EQ "frequency"> selected</cfif>>Mais ocorrências primeiro</option></select></div>
        <div class="col-sm-3"><button type="submit" class="btn btn-outline-light">Aplicar</button></div>
      </form>
      <cfif NOT etImages.total><p class="text-muted">Nenhum 404 de imagem ou ícone neste recorte.</p><cfelse>
        <div class="table-responsive"><table class="table table-sm triage-table"><caption class="visually-hidden">Imagens e ícones que retornaram 404</caption><thead><tr><th scope="col">Arquivo solicitado</th><th scope="col">Site</th><th scope="col">Ocorrências</th><th scope="col">Última ocorrência</th><th scope="col">Evidência</th></tr></thead><tbody>
          <cfloop query="etImages.items"><cfset etImage=etImages.items/>
            <tr><td class="triage-title"><code>#etHtml(etImage.path)#</code><div class="small text-muted">Primeira: #etDate(etImage.first_seen)#</div></td><td>#etHtml(etImage.site)#</td><td>#etImage.occurrences#</td><td>#etDate(etImage.last_seen)#</td><td><a href="./?aba=logs&amp;log_id=#etImage.sample_id#">Log ###etImage.sample_id#</a><cfif val(etImage.problem_id) GT 0><br/><a href="./?problem_id=#etImage.problem_id#">Problema ###etImage.problem_id#</a></cfif></td></tr>
          </cfloop>
        </tbody></table></div>
        <cfset etImageQuery="aba=imagens&amp;image_site=" & urlEncodedFormat(etImageSite) & "&amp;image_sort=" & etImageSort/>
        <nav aria-label="Páginas de imagens ausentes" class="d-flex flex-wrap align-items-center gap-3">
          <cfif etImages.page GT 1><a class="btn btn-sm btn-outline-light" href="./?#etImageQuery#&amp;image_page=#etImages.page-1#">Anterior</a></cfif>
          <span class="small text-muted">Página #etImages.page# de #ceiling(etImages.total/25)#</span>
          <cfif etImages.page*25 LT etImages.total><a class="btn btn-sm btn-outline-light" href="./?#etImageQuery#&amp;image_page=#etImages.page+1#">Próxima</a></cfif>
        </nav>
      </cfif>
    </cfoutput>
  </cfif>
</section></div></div>
