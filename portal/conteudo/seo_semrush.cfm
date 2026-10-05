<cfprocessingdirective pageencoding="utf-8"/>
<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfif compareNoCase(getBaseTemplatePath(), getCurrentTemplatePath()) EQ 0>
  <cfheader statuscode="403" statustext="Forbidden"/><cfabort/>
</cfif>
<cfif structKeyExists(CGI,"request_method") AND compareNoCase(CGI.request_method,"GET") NEQ 0>
  <cfheader statuscode="405" statustext="Method Not Allowed"/><cfheader name="Allow" value="GET"/><cfabort/>
</cfif>
<cfinclude template="../includes/seo_semrush_data.cfm"/>
<cfscript>
VARIABLES.srView = "oportunidades";
if (structKeyExists(URL,"secao") AND isSimpleValue(URL.secao) AND listFind("oportunidades,palavras,concorrentes",URL.secao)) VARIABLES.srView=URL.secao;
VARIABLES.srTabs=[{id="oportunidades",label="Oportunidades"},{id="palavras",label="Palavras-chave"},{id="concorrentes",label="Concorrentes"}];
VARIABLES.srSearch="";
if(structKeyExists(URL,"busca") AND isSimpleValue(URL.busca)) VARIABLES.srSearch=left(trim(URL.busca),100);
VARIABLES.srSearchSuffix=len(VARIABLES.srSearch) ? "&busca=" & encodeForURL(VARIABLES.srSearch) : "";
VARIABLES.srRows=[];
for(VARIABLES.srKeyword in VARIABLES.seoSemrush.keywords){
  if(!len(VARIABLES.srSearch) OR findNoCase(VARIABLES.srSearch,VARIABLES.srKeyword.keyword) OR findNoCase(VARIABLES.srSearch,VARIABLES.srKeyword.url)) arrayAppend(VARIABLES.srRows,VARIABLES.srKeyword);
}
</cfscript>
<style>
.seo-semrush { min-width:0; }
.seo-semrush .sr-metrics { display:grid; grid-template-columns:repeat(3,minmax(0,1fr)); gap:.75rem; margin:1rem 0; }
.seo-semrush .sr-metric { border:1px solid var(--seo-border); border-radius:8px; padding:1rem; }
.seo-semrush .sr-metric dt { font-size:.8rem; color:var(--mdb-secondary-color); font-weight:400; }
.seo-semrush .sr-metric dd { margin:.3rem 0 0; font-size:1.8rem; font-weight:650; }
.seo-semrush .sr-nav { display:flex; flex-wrap:wrap; gap:.5rem; margin:1.2rem 0; }
.seo-semrush .sr-nav a { border:1px solid var(--seo-border); padding:.5rem .8rem; border-radius:5px; color:inherit; }
.seo-semrush .sr-nav a[aria-current="page"] { color:#ffda86; background:rgba(255,193,7,.1); }
.seo-semrush .sr-table-wrap { overflow-x:auto; max-width:100%; }
.seo-semrush table { width:100%; border-collapse:collapse; font-size:.85rem; }
.seo-semrush th,.seo-semrush td { text-align:left; padding:.8rem .6rem; border-bottom:1px solid var(--seo-border); vertical-align:top; }
.seo-semrush th { color:var(--mdb-secondary-color); font-weight:500; }
.seo-semrush td a { color:#b9d8ff; overflow-wrap:anywhere; }
.seo-semrush .sr-measure { white-space:nowrap; }
.seo-semrush .sr-keyword { min-width:155px; }
.seo-semrush .sr-url { max-width:330px; min-width:180px; }
.seo-semrush .sr-card-grid { display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:.8rem; }
.seo-semrush .sr-card-grid .seo-issue { margin:0; min-width:0; }
.seo-semrush .sr-card-grid h3 { font-size:1rem; line-height:1.5; margin:.6rem 0; }
.seo-semrush .sr-card-grid p { font-size:.85rem; }
.seo-semrush .sr-form { display:flex; flex-wrap:wrap; align-items:end; gap:.5rem; margin:1rem 0; }
.seo-semrush .sr-form label { font-size:.85rem; }
.seo-semrush .sr-form input { max-width:100%; }
@media(max-width:767px){.seo-semrush .sr-metrics,.seo-semrush .sr-card-grid{grid-template-columns:1fr}.seo-semrush .sr-metric dd{font-size:1.5rem}.seo-semrush .sr-metric{padding:.75rem}}
</style>
<section class="seo-semrush" aria-labelledby="sr-title">
<cfif VARIABLES.seoQueueSiteFilter EQ "openresults">
  <h2 class="h5" id="sr-title">Semrush · Open Results</h2>
  <p>Nenhuma coleta do Open Results foi importada nesta etapa.</p>
  <a href="/portal/seo/?aba=semrush&amp;site=roadrunners">Ver dados do Road Runners</a>
<cfelse>
<cfoutput>
  <div class="seo-section-head">
    <h2 class="h5 mb-0" id="sr-title">Semrush · Road Runners</h2>
    <a class="small" href="https://www.semrush.com/analytics/organic/positions/?q=roadrunners.run&amp;db=br" target="_blank" rel="noopener noreferrer">Abrir no Semrush ↗</a>
  </div>
  <p class="seo-note">Brasil · desktop · coleta de #encodeForHtml(VARIABLES.seoSemrush.collectedLabel)#. As posições têm datas próprias. Dados do Semrush; não são cliques do Search Console.</p>
  <dl class="sr-metrics">
    <div class="sr-metric"><dt>Palavras-chave na base Semrush</dt><dd>#LSNumberFormat(VARIABLES.seoSemrush.overview.keywords,"9,999")#</dd></div>
    <div class="sr-metric"><dt>Palavras-chave nas posições 1–10</dt><dd>#VARIABLES.seoSemrush.overview.top10#</dd></div>
    <div class="sr-metric"><dt>Tráfego orgânico mensal estimado</dt><dd>#LSNumberFormat(VARIABLES.seoSemrush.overview.trafficEstimate,"9,999")#</dd></div>
  </dl>
  <div class="seo-search-health seo-status-warning" data-semrush-audit="#encodeForHtmlAttribute(VARIABLES.seoSemrush.audit.status)#">
    <cfif VARIABLES.seoSemrush.audit.status EQ "running">
      <h3 class="h6">! Nova auditoria em andamento na última consulta</h3>
      <p class="small mb-1"><cfif structKeyExists(VARIABLES.seoSemrush.audit,"crawled")>#VARIABLES.seoSemrush.audit.crawled# páginas rastreadas<cfelse>Progresso indisponível</cfif><cfif structKeyExists(VARIABLES.seoSemrush.audit,"limit")> · limite de #VARIABLES.seoSemrush.audit.limit# páginas</cfif>. Contadores da auditoria anterior não representam esta execução.</p>
    <cfelseif VARIABLES.seoSemrush.audit.status EQ "complete">
      <h3 class="h6">Auditoria concluída · resultados da amostra</h3>
      <p class="small mb-1"><cfif structKeyExists(VARIABLES.seoSemrush.audit,"crawled")>#VARIABLES.seoSemrush.audit.crawled# páginas rastreadas.</cfif> <cfif structKeyExists(VARIABLES.seoSemrush.audit,"errors")>#LSNumberFormat(VARIABLES.seoSemrush.audit.errors,"9,999")# ocorrências de erro.</cfif> <cfif structKeyExists(VARIABLES.seoSemrush.audit,"warnings")>#LSNumberFormat(VARIABLES.seoSemrush.audit.warnings,"9,999")# avisos.</cfif> <cfif structKeyExists(VARIABLES.seoSemrush.audit,"notices")>#LSNumberFormat(VARIABLES.seoSemrush.audit.notices,"9,999")# observações.</cfif> Uma mesma página pode gerar várias ocorrências; os totais não são páginas únicas. Os achados precisam de revisão por URL.</p>
    <cfelse>
      <h3 class="h6">! Auditoria atual ainda não confirmada</h3>
      <p class="small mb-1">O resultado disponível não confirma uma auditoria recente concluída.</p>
    </cfif>
    <p class="seo-note mb-0">Estado consultado em #encodeForHtml(VARIABLES.seoSemrush.audit.checkedLabel)#. Última conclusão informada: #encodeForHtml(VARIABLES.seoSemrush.audit.lastFinishedLabel)#. Este registro não atualiza ao recarregar a página.</p>
  </div>
  <p class="seo-note"><strong>Comparação das auditorias de 04/10/2026, 14:39 e 15:40:</strong> Site Health Semrush de 68 para 76 (+8 pontos); erros de 114 para 9 (−92,1%); avisos de 6.293 para 6.356; observações de 60 para 126. Ambas rastrearam 500 páginas, com os mesmos limites e configurações observáveis. A composição das URLs e o número de verificações variam; esta comparação não comprova indexação no Google.</p>
  <p class="seo-note">Na nova amostra, hreflang passou de 42 para 0, descrições duplicadas de 27 para 0, problemas de sitemap de 4 para 0 e imagens quebradas de 1 para 0. Evidências: <a href="/portal/seo/?aba=fila&amp;site=roadrunners##RR-17">RR-17 — editorial</a>, <a href="/portal/seo/?aba=fila&amp;site=roadrunners##RR-18">RR-18 — buscas</a> e <a href="/portal/seo/?aba=fila&amp;site=roadrunners##RR-19">RR-19 — imagens</a>.</p>
  <p class="seo-note">Os nove erros restantes foram detalhados no <a href="/portal/seo/?aba=fila&amp;site=roadrunners##RR-20">RR-20</a>: dois títulos iguais de eventos, uma página não rastreada, uma busca lenta e cinco ocorrências da proteção de e-mail. A maior parte dos avisos concentra-se em recursos sem minificação (2.809) e redirecionamentos temporários (2.786); são ocorrências, não páginas únicas nem correções independentes.</p>
  <p class="seo-note">Melhoria posterior à auditoria: o ranking catarinense de corrida de rua passou de 8,06 s para 0,30–0,31 s nas verificações públicas, com as tabelas preservadas. Entrega em <a href="/portal/seo/?aba=fila&amp;site=roadrunners##RR-21">RR-21</a>. A baixa do alerta de rastreamento ainda depende de nova auditoria; os números acima continuam sendo os da coleta de 04/10 às 15:40.</p>
  <p class="seo-note">Entregas posteriores à coleta: ranking <a href="/portal/seo/?aba=fila&amp;site=roadrunners##RR-21">RR-21</a>, metadados e unidade dos circuitos <a href="/portal/seo/?aba=fila&amp;site=roadrunners##RR-22">RR-22</a>, recursos compactados <a href="/portal/seo/?aba=fila&amp;site=roadrunners##RR-23">RR-23</a>, reconciliação ABAVSE <a href="/portal/seo/?aba=fila&amp;site=roadrunners##RR-25">RR-25</a>, diretório llms.txt experimental <a href="/portal/seo/?aba=fila&amp;site=roadrunners##RR-26">RR-26</a>, ALT e H1 <a href="/portal/seo/?aba=fila&amp;site=roadrunners##RR-27">RR-27</a>. Em <a href="/portal/seo/?aba=fila&amp;site=roadrunners##SH-02">SH-02</a>, restam 31 percursos em 18 eventos para revisão com fonte. Disponibilidade permanece pendente em <a href="/portal/seo/?aba=fila&amp;site=roadrunners##RR-24">RR-24</a>: acesso recuperado não comprova estabilidade. Os totais do Semrush acima mantêm a data da coleta.</p>
  <nav class="sr-nav" aria-label="Dados do Semrush">
    <cfloop array="#VARIABLES.srTabs#" index="srTab"><a href="/portal/seo/?aba=semrush&amp;secao=#srTab.id##encodeForHtmlAttribute(VARIABLES.seoTabFilters & VARIABLES.srSearchSuffix)#"<cfif VARIABLES.srView EQ srTab.id> aria-current="page"</cfif>>#encodeForHtml(srTab.label)#</a></cfloop>
  </nav>
  <cfif VARIABLES.srView EQ "oportunidades">
    <h3 class="h6">Primeiras oportunidades de melhoria</h3>
    <p class="seo-note">Seleção revisada da amostra. Prioridade considera intenção da busca e página de destino; volume alto sozinho não define valor comercial. SR-03 recebeu a melhoria de intenção dos circuitos em RR-22. Calendários SP/ES/SC têm filtro de cidades e páginas locais publicadas; Aracaju recebeu resumo factual PT/EN/ES. Traduções de LIVE Porto Alegre e SP City conferidas sem reescrever fatos históricos. Efeitos em posições, aquisição e receita ainda não medidos; estes números são os da coleta.</p>
    <div class="sr-card-grid">
      <cfloop array="#VARIABLES.seoSemrush.opportunities#" index="srItem">
        <article class="seo-issue" id="#encodeForHtmlAttribute(srItem.id)#">
          <div class="seo-meta"><span class="seo-label seo-priority-p2">#encodeForHtml(srItem.id)#</span><span class="seo-label seo-status-warning seo-status-badge">! #encodeForHtml(srItem.status)#</span></div>
          <h3>#encodeForHtml(srItem.title)#</h3>
          <p><strong>#encodeForHtml(srItem.keyword)#</strong> · posição #srItem.position# · #LSNumberFormat(srItem.volume,"9,999")# buscas/mês estimadas</p>
          <p>#encodeForHtml(srItem.action)#</p>
          <p class="seo-note">Posição observada em #encodeForHtml(srItem.observedLabel)#</p>
          <ul class="seo-urls"><li><a href="#encodeForHtmlAttribute(srItem.url)#" target="_blank" rel="noopener noreferrer">#encodeForHtml(srItem.url)# ↗</a></li></ul>
        </article>
      </cfloop>
    </div>
  <cfelseif VARIABLES.srView EQ "palavras">
    <form class="sr-form" action="/portal/seo/" method="get">
      <input type="hidden" name="aba" value="semrush"/><input type="hidden" name="secao" value="palavras"/>
      <input type="hidden" name="site" value="#encodeForHtmlAttribute(VARIABLES.seoQueueSiteFilter)#"/>
      <input type="hidden" name="prioridade" value="#encodeForHtmlAttribute(VARIABLES.seoQueuePriorityFilter)#"/>
      <input type="hidden" name="verificacao" value="#encodeForHtmlAttribute(VARIABLES.seoScoreFilter)#"/>
      <div><label for="sr-search" class="form-label">Buscar palavra-chave ou URL</label><input class="form-control" id="sr-search" name="busca" maxlength="100" value="#encodeForHtmlAttribute(VARIABLES.srSearch)#"/></div>
      <button class="btn btn-warning" type="submit">Buscar</button>
      <a class="btn btn-link text-reset" href="/portal/seo/?aba=semrush&amp;secao=palavras#encodeForHtmlAttribute(VARIABLES.seoTabFilters)#">Limpar busca</a>
    </form>
    <p class="seo-note" role="status">#arrayLen(VARIABLES.srRows)# de #arrayLen(VARIABLES.seoSemrush.keywords)# pares palavra-chave/URL da amostra. #VARIABLES.seoSemrush.uniqueKeywords# termos distintos após remover sobreposição de duas consultas de 30 linhas. Não é a lista completa das #VARIABLES.seoSemrush.overview.keywords# palavras-chave.</p>
    <cfif NOT arrayLen(VARIABLES.srRows)><p>Nenhum resultado nesta amostra para a busca informada.</p><cfelse>
    <div class="sr-table-wrap" tabindex="0" role="region" aria-label="Tabela de palavras-chave"><table>
      <caption class="visually-hidden">Amostra Semrush Brasil desktop, ordenada por volume estimado de buscas.</caption>
      <thead><tr><th scope="col">Palavra-chave</th><th scope="col">Posição</th><th scope="col">Buscas/mês estimadas</th><th scope="col">Dificuldade /100</th><th scope="col">URL</th><th scope="col">Observação</th></tr></thead><tbody>
      <cfloop array="#VARIABLES.srRows#" index="srRow"><tr>
        <td class="sr-keyword">#encodeForHtml(srRow.keyword)#</td><td>#srRow.position#</td><td class="sr-measure">#LSNumberFormat(srRow.volume,"9,999")#</td><td>#srRow.difficulty#</td>
        <td class="sr-url"><a href="#encodeForHtmlAttribute(srRow.url)#" target="_blank" rel="noopener noreferrer">#encodeForHtml(replace(srRow.url,"https://roadrunners.run",""))#</a></td><td class="sr-measure">#encodeForHtml(srRow.observedLabel)#</td>
      </tr></cfloop></tbody></table></div></cfif>
  <cfelse>
    <h3 class="h6">Domínios com palavras-chave em comum</h3>
    <p class="seo-note">Os dez domínios retornados pelo Semrush não são necessariamente concorrentes comerciais. Semelhanças com o nome da marca podem trazer resultados pouco relevantes. Tráfego estimado de cada domínio inteiro.</p>
    <div class="sr-table-wrap" tabindex="0" role="region" aria-label="Tabela de concorrentes"><table>
      <caption class="visually-hidden">Domínios retornados na pesquisa de concorrentes orgânicos, Brasil desktop.</caption>
      <thead><tr><th scope="col">Domínio</th><th scope="col">Termos em comum</th><th scope="col">Palavras-chave</th><th scope="col">Tráfego mensal estimado</th></tr></thead><tbody>
      <cfloop array="#VARIABLES.seoSemrush.competitors#" index="srCompetitor"><tr><td>#encodeForHtml(srCompetitor.domain)#</td><td>#srCompetitor.common#</td><td>#LSNumberFormat(srCompetitor.keywords,"9,999")#</td><td>#LSNumberFormat(srCompetitor.trafficEstimate,"9,999")#</td></tr></cfloop>
      </tbody></table></div>
  </cfif>
  <details class="seo-method"><summary>Fonte, limites e acompanhamento</summary><div class="seo-method-body">
    <p>Fonte: Semrush MCP, consultas de domínio, palavras-chave e concorrentes na base Brasil desktop. Tráfego e volume são estimativas do fornecedor. Posições são observações datadas; coleta recente não significa que todas as palavras foram medidas hoje.</p>
    <p>Campanha diária: <cfif VARIABLES.seoSemrush.tracking EQ "not_configured">nenhum alvo retornado na consulta inicial. Configurar palavras-chave, Brasil e dispositivo no Position Tracking.<cfelseif VARIABLES.seoSemrush.tracking EQ "configured">alvos encontrados; resultados ainda não importados.<cfelse>configuração não confirmada.</cfif></p>
    <p>Primeira referência, sem série histórica comparável. O histórico técnico e as evidências do Search Console continuam nas outras abas. A auditoria Semrush tem limite próprio e não comprova indexação de todas as páginas.</p>
    <p>Atualização por importação de uma nova coleta validada e publicação do painel. Abrir esta tela não consulta o fornecedor nem consome unidades.</p>
  </div></details>
</cfoutput>
</cfif>
</section>
