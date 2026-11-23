<cfprocessingdirective pageencoding="utf-8"/>
<cfinclude template="../includes/seo_semrush_archive_backend.cfm"/>
<cfif compareNoCase(getBaseTemplatePath(),getCurrentTemplatePath()) EQ 0><cfheader statuscode="403"/><cfabort/></cfif>
<style>
.sma-cards{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:1rem;margin:1rem 0}.sma-card{border:1px solid var(--seo-border);border-radius:8px;padding:1rem}.sma-score{font-size:2rem;font-weight:650}.sma-stats{display:flex;flex-wrap:wrap;gap:1rem;margin:.8rem 0}.sma-stats dt{font-size:.8rem;font-weight:400}.sma-stats dd{margin:0;font-size:1.2rem}.sma-error{color:#ffabab}.sma-warning{color:#ffda86}.sma-pass{color:#a0dfd4}.sma-neutral{color:var(--mdb-secondary-color)}.sma-nav{display:flex;flex-wrap:wrap;gap:.5rem;margin:1rem 0}.sma-nav a{padding:.5rem .7rem;border:1px solid var(--seo-border);border-radius:5px;color:inherit}.sma-nav [aria-current=page]{color:#ffda86;background:rgba(255,193,7,.1)}.sma-url{overflow-wrap:anywhere;min-width:220px;max-width:620px;white-space:pre-wrap}.sma-small{font-size:.8rem}.sma-findings{max-width:430px}.sma-findings a{display:inline-block;margin:.15rem .4rem .15rem 0}.sma-sort{background:transparent;border:0;color:inherit;padding:0;text-align:left;cursor:pointer}.sma-meta{display:grid;grid-template-columns:minmax(100px,1fr) minmax(150px,3fr);gap:.3rem .8rem;max-width:620px;margin:.6rem 0}.sma-meta dt,.sma-meta dd{margin:0;overflow-wrap:anywhere}.sma-page-nav{display:flex;gap:1rem;align-items:center;margin:1rem 0;flex-wrap:wrap}@media(max-width:767px){.sma-cards{grid-template-columns:1fr}.sma-meta{grid-template-columns:1fr}}
</style>
<h2 class="h5" id="sr-title">Auditorias Semrush preservadas</h2>
<cfif NOT VARIABLES.smaAvailable>
  <p>Os arquivos desta coleta estão indisponíveis. Nenhuma contagem foi substituída por zero.</p>
<cfelse>
<cfscript>
VARIABLES.smaSite=VARIABLES.seoQueueSiteFilter EQ "openresults" ? "openresults" : "roadrunners";
VARIABLES.smaAudit=VARIABLES.smaManifest.sites[VARIABLES.smaSite];
VARIABLES.smaView="resumo";
if(structKeyExists(URL,"arquivo_visao") AND isSimpleValue(URL.arquivo_visao) AND listFind("resumo,paginas,palavras,arquivos",URL.arquivo_visao)) VARIABLES.smaView=URL.arquivo_visao;
VARIABLES.smaSeverity="all";
if(structKeyExists(URL,"gravidade") AND isSimpleValue(URL.gravidade) AND listFind("all,error,warning,notice,pass,unmeasured",URL.gravidade)) VARIABLES.smaSeverity=URL.gravidade;
VARIABLES.smaSearch="";
if(structKeyExists(URL,"busca") AND isSimpleValue(URL.busca)) VARIABLES.smaSearch=left(trim(URL.busca),200);
VARIABLES.smaIssue="";VARIABLES.smaIssueById={};
for(VARIABLES.smaIt in VARIABLES.smaAudit.issues) VARIABLES.smaIssueById[VARIABLES.smaIt.id & ""]=VARIABLES.smaIt;
if(structKeyExists(URL,"problema") AND isSimpleValue(URL.problema) AND structKeyExists(VARIABLES.smaIssueById,URL.problema)) VARIABLES.smaIssue=URL.problema;
VARIABLES.smaBase="/portal/seo/?aba=semrush&secao=auditorias&site=" & VARIABLES.smaSite;
VARIABLES.smaFilterSuffix="&gravidade=" & VARIABLES.smaSeverity & "&busca=" & encodeForURL(VARIABLES.smaSearch) & "&problema=" & encodeForURL(VARIABLES.smaIssue);
VARIABLES.smaStatusLabels={error="Erro",warning="Atenção",notice="Observação",pass="Certo",unmeasured="Não medido"};
VARIABLES.smaRows=[];VARIABLES.smaDataAvailable=true;
VARIABLES.smaPage=1;VARIABLES.smaPerPage=50;
if(structKeyExists(URL,"pagina") AND isSimpleValue(URL.pagina) AND reFind("^[1-9][0-9]{0,4}$",URL.pagina)) VARIABLES.smaPage=val(URL.pagina);
if(VARIABLES.smaView EQ "paginas"){
  try{
    VARIABLES.smaPageData=deserializeJSON(fileRead(VARIABLES.smaRoot & "/" & VARIABLES.smaSite & "-pages.json","utf-8"));
    if(VARIABLES.smaPageData.schemaVersion NEQ 1 OR VARIABLES.smaPageData.site NEQ VARIABLES.smaSite OR arrayLen(VARIABLES.smaPageData.rows) NEQ VARIABLES.smaAudit.pages) throw(message="Arquivo incompatível");
    for(VARIABLES.smaRow in VARIABLES.smaPageData.rows){
      if(len(VARIABLES.smaIssue) AND NOT structKeyExists(VARIABLES.smaRow.findings,VARIABLES.smaIssue)) continue;
      if(len(VARIABLES.smaSearch) AND NOT findNoCase(VARIABLES.smaSearch,VARIABLES.smaRow.url) AND NOT (structKeyExists(VARIABLES.smaRow.metadata,"Page Title") AND findNoCase(VARIABLES.smaSearch,VARIABLES.smaRow.metadata["Page Title"]))) continue;
      if(VARIABLES.smaSeverity EQ "error" AND VARIABLES.smaRow.errors EQ 0) continue;
      if(VARIABLES.smaSeverity EQ "warning" AND VARIABLES.smaRow.warnings EQ 0) continue;
      if(VARIABLES.smaSeverity EQ "notice" AND VARIABLES.smaRow.notices EQ 0) continue;
      if(VARIABLES.smaSeverity EQ "pass" AND structCount(VARIABLES.smaRow.findings) GT 0) continue;
      if(VARIABLES.smaSeverity EQ "unmeasured") continue;
      arrayAppend(VARIABLES.smaRows,VARIABLES.smaRow);
    }
  } catch(any smaPagesError){VARIABLES.smaDataAvailable=false;}
}
if(VARIABLES.smaView EQ "palavras"){
  try{
    VARIABLES.smaKeywordData=deserializeJSON(fileRead(VARIABLES.smaRoot & "/" & VARIABLES.smaSite & "-keywords.json","utf-8"));
    if(VARIABLES.smaKeywordData.schemaVersion NEQ 1 OR VARIABLES.smaKeywordData.site NEQ VARIABLES.smaSite OR arrayLen(VARIABLES.smaKeywordData.rows) NEQ VARIABLES.smaAudit.organic.rows) throw(message="Arquivo de palavras incompatível");
    for(VARIABLES.smaKeyword in VARIABLES.smaKeywordData.rows){
      if(len(VARIABLES.smaSearch) AND NOT findNoCase(VARIABLES.smaSearch,VARIABLES.smaKeyword.Keyword) AND NOT findNoCase(VARIABLES.smaSearch,VARIABLES.smaKeyword.URL)) continue;
      arrayAppend(VARIABLES.smaRows,VARIABLES.smaKeyword);
    }
  } catch(any smaKeywordsError){VARIABLES.smaDataAvailable=false;}
}
VARIABLES.smaTotalPages=max(1,ceiling(arrayLen(VARIABLES.smaRows)/VARIABLES.smaPerPage));
VARIABLES.smaPage=min(VARIABLES.smaPage,VARIABLES.smaTotalPages);
VARIABLES.smaStart=(VARIABLES.smaPage-1)*VARIABLES.smaPerPage+1;
VARIABLES.smaEnd=min(arrayLen(VARIABLES.smaRows),VARIABLES.smaPage*VARIABLES.smaPerPage);
</cfscript>
<cfoutput>
<p class="seo-note">Exportações preservadas em 04/11/2026. A consulta e os downloads funcionam sem consultar o Semrush. As notas são da amostra técnica e não comprovam indexação no Google ou tráfego.</p>
<div class="sma-cards">
<cfloop list="roadrunners,openresults" index="smaKey">
<cfset smaCard=VARIABLES.smaManifest.sites[smaKey]/>
<article class="sma-card" data-semrush-site="#smaKey#">
  <h3 class="h6">#encodeForHtml(smaCard.label)#</h3>
  <p class="seo-note">Auditoria: #dateFormat(smaCard.auditDate,"dd/mm/yyyy")# · #encodeForHtml(smaCard.device)# · JavaScript desativado · #LSNumberFormat(smaCard.pages,"9,999")# de #LSNumberFormat(smaCard.limit,"9,999")# páginas</p>
  <div class="sma-score">#smaCard.siteHealth#% <span class="sma-small sma-neutral">Site Health</span></div>
  <p class="sma-small">Indicador de pesquisa IA: #smaCard.aiHealth#%</p>
  <dl class="sma-stats"><div class="sma-error"><dt>Erros</dt><dd>#LSNumberFormat(smaCard.totals.error,"9,999")#</dd></div><div class="sma-warning"><dt>Atenção</dt><dd>#LSNumberFormat(smaCard.totals.warning,"9,999")#</dd></div><div><dt>Observações</dt><dd>#LSNumberFormat(smaCard.totals.notice,"9,999")#</dd></div></dl>
  <a href="/portal/seo/?aba=semrush&amp;secao=auditorias&amp;site=#smaKey#">Consultar #encodeForHtml(smaCard.label)#</a>
</article>
</cfloop>
</div>
<p class="seo-note">Ocorrências não são páginas únicas. O limite e as configurações mudaram desde coletas anteriores; os totais e as notas não permitem atribuir toda a diferença a correções ou regressões. Os achados abaixo continuam <strong>a revisar</strong>. Bloqueios podem incluir filtros com noindex intencional.</p>
<h3 class="h6">#encodeForHtml(VARIABLES.smaAudit.label)#</h3>
<nav class="sma-nav" aria-label="Consulta do arquivo Semrush">
<cfloop array="#['resumo','paginas','palavras','arquivos']#" index="smaTab"><a href="#encodeForHtmlAttribute(VARIABLES.smaBase & '&arquivo_visao=' & smaTab & VARIABLES.smaFilterSuffix)#"<cfif VARIABLES.smaView EQ smaTab> aria-current="page"</cfif>><cfif smaTab EQ "resumo">Verificações<cfelseif smaTab EQ "paginas">URLs auditadas<cfelseif smaTab EQ "palavras">Palavras-chave<cfelse>Arquivos originais</cfif></a></cfloop>
</nav>
<form method="get" action="/portal/seo/" class="sr-form">
<input type="hidden" name="aba" value="semrush"/><input type="hidden" name="secao" value="auditorias"/><input type="hidden" name="site" value="#VARIABLES.smaSite#"/><input type="hidden" name="arquivo_visao" value="#VARIABLES.smaView#"/>
<cfif VARIABLES.smaView NEQ "palavras"><div><label for="sma-severity">Situação</label><select id="sma-severity" name="gravidade" class="form-select"><option value="all">Todas</option><cfloop list="error,warning,notice,pass,unmeasured" index="smaStatus"><option value="#smaStatus#"<cfif VARIABLES.smaSeverity EQ smaStatus> selected</cfif>>#VARIABLES.smaStatusLabels[smaStatus]#</option></cfloop></select></div></cfif>
<div><label for="sma-search"><cfif VARIABLES.smaView EQ "palavras">Palavra-chave ou URL<cfelse>URL, título ou verificação</cfif></label><input id="sma-search" name="busca" type="search" value="#encodeForHtmlAttribute(VARIABLES.smaSearch)#" class="form-control" maxlength="200"/></div>
<cfif VARIABLES.smaView EQ "paginas"><div><label for="sma-issue">Problema</label><select id="sma-issue" name="problema" class="form-select"><option value="">Todos os problemas</option><cfloop array="#VARIABLES.smaAudit.issues#" index="smaOption"><cfif smaOption.count GT 0><option value="#smaOption.id#"<cfif VARIABLES.smaIssue EQ (smaOption.id & '')> selected</cfif>>#encodeForHtml(smaOption.label)#</option></cfif></cfloop></select></div></cfif>
<button type="submit" class="btn btn-warning">Filtrar</button><a href="#encodeForHtmlAttribute(VARIABLES.smaBase & '&arquivo_visao=' & VARIABLES.smaView)#">Limpar</a>
</form>
<cfif VARIABLES.smaView EQ "resumo">
<p class="seo-note">101 tipos de verificação preservados. ✓ Certo indica zero falhas entre as verificações executadas. — Não medido indica nenhum teste daquele tipo. Ordene pelos títulos das colunas.</p>
<div class="sr-table-wrap"><table id="sma-checks"><thead><tr><th><button class="sma-sort" type="button" data-column="0">Situação ↕</button></th><th><button class="sma-sort" type="button" data-column="1">Verificação ↕</button></th><th><button class="sma-sort" type="button" data-column="2" data-numeric="true">Ocorrências ↕</button></th><th>URLs no inventário</th><th>Revisar</th></tr></thead><tbody>
<cfloop array="#VARIABLES.smaAudit.issues#" index="smaCheck">
<cfset smaCheckStatus=smaCheck.count GT 0 ? smaCheck.severity : (smaCheck.checks GT 0 ? 'pass' : 'unmeasured')/>
<cfif VARIABLES.smaSeverity NEQ "all" AND VARIABLES.smaSeverity NEQ smaCheckStatus><cfcontinue/></cfif>
<cfif len(VARIABLES.smaSearch) AND NOT findNoCase(VARIABLES.smaSearch,smaCheck.label) AND NOT findNoCase(VARIABLES.smaSearch,smaCheck.name)><cfcontinue/></cfif>
<tr><td class="sma-#smaCheckStatus EQ 'unmeasured' ? 'neutral' : smaCheckStatus#"><cfif smaCheckStatus EQ 'pass'>✓<cfelseif smaCheckStatus EQ 'error'>×<cfelseif smaCheckStatus EQ 'unmeasured'>—<cfelse>!</cfif> #VARIABLES.smaStatusLabels[smaCheckStatus]#</td><td>#encodeForHtml(smaCheck.label)#<details class="sma-small"><summary>Identificação</summary>#encodeForHtml(smaCheck.name)# · ID #smaCheck.id# · #LSNumberFormat(smaCheck.checks,"9,999")# testes</details></td><td data-sort-value="#smaCheck.count#">#LSNumberFormat(smaCheck.count,"9,999")#</td><td>#LSNumberFormat(smaCheck.affectedPages,"9,999")#</td><td><cfif smaCheck.count GT 0><a href="#encodeForHtmlAttribute(VARIABLES.smaBase & '&arquivo_visao=paginas&problema=' & smaCheck.id)#">Ver URLs</a><cfelse>—</cfif></td></tr>
</cfloop>
</tbody></table></div>
<cfelseif VARIABLES.smaView EQ "paginas">
<cfif NOT VARIABLES.smaDataAvailable><p>O inventário está indisponível. Os resultados não foram substituídos por uma lista vazia.</p><cfelse>
<p class="seo-note">#LSNumberFormat(arrayLen(VARIABLES.smaRows),"9,999")# URLs encontradas · página #VARIABLES.smaPage# de #VARIABLES.smaTotalPages#. Erros primeiro. As informações são as observadas pelo Semrush naquela coleta.</p>
<div class="sr-table-wrap"><table><thead><tr><th>URL e metadados</th><th>Achados na coleta</th></tr></thead><tbody>
<cfloop from="#VARIABLES.smaStart#" to="#VARIABLES.smaEnd#" index="smaIndex"><cfset smaPageRow=VARIABLES.smaRows[smaIndex]/>
<tr><td class="sma-url"><cfif smaPageRow.linkAllowed><a href="#encodeForHtmlAttribute(smaPageRow.url)#" target="_blank" rel="noopener noreferrer">#encodeForHtml(smaPageRow.url)# ↗</a><cfelse>#encodeForHtml(smaPageRow.url)#<p class="sma-error">URL malformada na exportação. Texto original preservado.</p></cfif>
<cfif structCount(smaPageRow.metadata)><details class="sma-small"><summary>Ver metadados e links</summary><dl class="sma-meta"><cfloop collection="#smaPageRow.metadata#" item="smaMetaKey"><dt>#encodeForHtml(smaMetaKey)#</dt><dd>#encodeForHtml(smaPageRow.metadata[smaMetaKey] & '')#</dd></cfloop></dl></details></cfif></td>
<td class="sma-findings"><cfif structCount(smaPageRow.findings) EQ 0><span class="sma-neutral">Sem achados nas colunas exportadas</span><cfelse><cfloop array="#VARIABLES.smaAudit.issues#" index="smaFinding"><cfif structKeyExists(smaPageRow.findings,smaFinding.id & '')><a class="sma-#smaFinding.severity#" href="#encodeForHtmlAttribute(VARIABLES.smaBase & '&arquivo_visao=paginas&problema=' & smaFinding.id)#">#encodeForHtml(smaFinding.label)# (#smaPageRow.findings[smaFinding.id & '']#)</a></cfif></cfloop></cfif></td></tr>
</cfloop>
<cfif arrayLen(VARIABLES.smaRows) EQ 0><tr><td colspan="2">Nenhuma URL corresponde aos filtros.</td></tr></cfif>
</tbody></table></div>
<nav class="sma-page-nav" aria-label="Páginas do inventário"><cfif VARIABLES.smaPage GT 1><a href="#encodeForHtmlAttribute(VARIABLES.smaBase & '&arquivo_visao=paginas&pagina=' & (VARIABLES.smaPage-1) & VARIABLES.smaFilterSuffix)#">← Anterior</a></cfif><span>#VARIABLES.smaPage# / #VARIABLES.smaTotalPages#</span><cfif VARIABLES.smaPage LT VARIABLES.smaTotalPages><a href="#encodeForHtmlAttribute(VARIABLES.smaBase & '&arquivo_visao=paginas&pagina=' & (VARIABLES.smaPage+1) & VARIABLES.smaFilterSuffix)#">Próxima →</a></cfif></nav>
</cfif>
<cfelseif VARIABLES.smaView EQ "palavras">
<p class="seo-note">Brasil · desktop · base de 03/11/2026, exportada em 04/11. #LSNumberFormat(VARIABLES.smaAudit.organic.rows,"9,999")# linhas de posições e #LSNumberFormat(VARIABLES.smaAudit.organic.uniqueKeywords,"9,999")# termos distintos. As palavras têm datas próprias. Volume e tráfego são estimativas Semrush. Não são cliques nem sessões.</p>
<cfif NOT VARIABLES.smaDataAvailable><p>Os dados de palavras-chave estão indisponíveis.</p><cfelse>
<p>#LSNumberFormat(arrayLen(VARIABLES.smaRows),"9,999")# linhas encontradas · maiores volumes primeiro.</p>
<div class="sr-table-wrap"><table><thead><tr><th>Palavra-chave</th><th>Posição</th><th>Anterior</th><th>Volume</th><th>Dificuldade</th><th>Tráfego estimado</th><th>URL e data</th></tr></thead><tbody>
<cfloop from="#VARIABLES.smaStart#" to="#VARIABLES.smaEnd#" index="smaIndex"><cfset smaWord=VARIABLES.smaRows[smaIndex]/><tr><td>#encodeForHtml(smaWord.Keyword)#</td><td>#encodeForHtml(smaWord.Position)#</td><td>#encodeForHtml(smaWord['Previous position'])#</td><td>#encodeForHtml(smaWord['Search Volume'])#</td><td>#encodeForHtml(smaWord['Keyword Difficulty'])#</td><td>#encodeForHtml(smaWord.Traffic)#</td><td class="sma-url"><cfif smaWord.linkAllowed><a href="#encodeForHtmlAttribute(smaWord.URL)#" target="_blank" rel="noopener noreferrer">#encodeForHtml(smaWord.URL)# ↗</a><cfelse>#encodeForHtml(smaWord.URL)#</cfif><div class="sma-small">#encodeForHtml(smaWord.Timestamp)#</div></td></tr></cfloop>
<cfif arrayLen(VARIABLES.smaRows) EQ 0><tr><td colspan="7">Nenhuma palavra corresponde à busca.</td></tr></cfif>
</tbody></table></div>
<nav class="sma-page-nav" aria-label="Páginas das palavras-chave"><cfif VARIABLES.smaPage GT 1><a href="#encodeForHtmlAttribute(VARIABLES.smaBase & '&arquivo_visao=palavras&pagina=' & (VARIABLES.smaPage-1) & '&busca=' & encodeForURL(VARIABLES.smaSearch))#">← Anterior</a></cfif><span>#VARIABLES.smaPage# / #VARIABLES.smaTotalPages#</span><cfif VARIABLES.smaPage LT VARIABLES.smaTotalPages><a href="#encodeForHtmlAttribute(VARIABLES.smaBase & '&arquivo_visao=palavras&pagina=' & (VARIABLES.smaPage+1) & '&busca=' & encodeForURL(VARIABLES.smaSearch))#">Próxima →</a></cfif></nav>
<a href="/portal/seo/arquivo.cfm?arquivo=#encodeForURL(VARIABLES.smaAudit.organic.fileId)#">Baixar todas as posições em CSV</a>
</cfif>
<cfelse>
<p class="seo-note">CSVs originais preservados sem alterar as células. O inventário geral relaciona URLs e verificações; os relatórios detalhados acrescentam destinos, duplicidades e recursos envolvidos. Nem toda contagem representa páginas únicas.</p>
<cfloop array="#VARIABLES.smaAudit.detailLimitations#" index="smaLimitation"><p class="seo-note">#encodeForHtml(smaLimitation.reason)# (verificação #smaLimitation.issueId#).</p></cfloop>
<div class="sr-table-wrap"><table><thead><tr><th>Arquivo</th><th>Linhas</th><th>Tamanho</th><th>Download</th></tr></thead><tbody>
<cfloop array="#VARIABLES.smaAudit.files#" index="smaFileKey"><cfset smaFile=VARIABLES.smaManifest.files[smaFileKey]/><tr><td>#encodeForHtml(smaFile.name)#<details class="sma-small"><summary>Colunas e integridade</summary><p>#encodeForHtml(arrayToList(smaFile.columns,', '))#</p><p class="sma-url">SHA-256: #encodeForHtml(smaFile.sha256)#</p></details></td><td>#LSNumberFormat(smaFile.rows,"9,999")#</td><td>#LSNumberFormat(smaFile.bytes/1024,"9,999.0")# KB</td><td><a href="/portal/seo/arquivo.cfm?arquivo=#encodeForURL(smaFile.id)#">Baixar CSV</a></td></tr></cfloop>
</tbody></table></div>
</cfif>
<p class="seo-note">Preservado para revisão após o encerramento da assinatura. Nenhuma correção automática é feita por esta tela. Dados acessíveis somente a administradores.</p>
</cfoutput>
</cfif>
<script>
(()=>{const table=document.getElementById('sma-checks');if(!table)return;table.querySelectorAll('[data-column]').forEach(button=>button.addEventListener('click',()=>{const col=Number(button.dataset.column),numeric=button.dataset.numeric==='true',ascending=button.dataset.direction!=='asc';table.querySelectorAll('th').forEach(th=>th.removeAttribute('aria-sort'));button.closest('th').setAttribute('aria-sort',ascending?'ascending':'descending');button.dataset.direction=ascending?'asc':'desc';const rows=Array.from(table.tBodies[0].rows);rows.sort((a,b)=>{const x=a.cells[col].dataset.sortValue??a.cells[col].textContent.trim(),y=b.cells[col].dataset.sortValue??b.cells[col].textContent.trim();return (numeric?Number(x)-Number(y):x.localeCompare(y,'pt-BR'))*(ascending?1:-1)});rows.forEach(row=>table.tBodies[0].appendChild(row));}));})();
</script>
