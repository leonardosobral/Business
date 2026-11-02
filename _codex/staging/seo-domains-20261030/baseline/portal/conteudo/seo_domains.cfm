<cfprocessingdirective pageencoding="utf-8"/>
<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfif compareNoCase(getBaseTemplatePath(),getCurrentTemplatePath()) EQ 0><cfheader statuscode="403"/><cfabort/></cfif>
<cfif structKeyExists(CGI,"request_method") AND compareNoCase(CGI.request_method,"GET") NEQ 0><cfheader statuscode="405"/><cfheader name="Allow" value="GET"/><cfabort/></cfif>
<cfinclude template="../includes/seo_domains_data.cfm"/>
<cfscript>
VARIABLES.sdColumns=[{key="traffic",label="Tráfego orgânico"},{key="keywords",label="Palavras-chave orgânicas"},{key="refDomains",label="Domínios de referência"},{key="authority",label="Authority Score"},{key="paidKeywords",label="Palavras-chave pagas"},{key="paidTraffic",label="Tráfego pago"}];
VARIABLES.sdRoad={}; VARIABLES.sdOpen={}; VARIABLES.sdRising=0; VARIABLES.sdFalling=0; VARIABLES.sdStable=0;
VARIABLES.sdCards=[{key="traffic",label="tráfego",unit="estimados"},{key="keywords",label="palavras-chave",unit="palavras-chave"}];
for(VARIABLES.sdEntry in VARIABLES.seoDomains.domains){
  if(VARIABLES.sdEntry.domain EQ "roadrunners.run") VARIABLES.sdRoad=VARIABLES.sdEntry;
  if(VARIABLES.sdEntry.domain EQ "openresults.run") VARIABLES.sdOpen=VARIABLES.sdEntry;
  if(VARIABLES.sdEntry.metrics.traffic.changeAvailable){
    if(VARIABLES.sdEntry.metrics.traffic.change GT 0) VARIABLES.sdRising++;
    else if(VARIABLES.sdEntry.metrics.traffic.change LT 0) VARIABLES.sdFalling++;
    else VARIABLES.sdStable++;
  }
}
</cfscript>
<link rel="stylesheet" href="/portal/seo/assets/domains.css?v=20261025-1"/>
<section class="seo-domains" aria-labelledby="sd-title" data-domains-dashboard>
<cfoutput>
  <div class="seo-section-head">
    <div><h2 class="h5 mb-1" id="sd-title">Domínios monitorados</h2><p class="seo-note mb-0">Sua lista do Semrush · Brasil · janela “Mês”</p></div>
    <a class="small" href="#encodeForHtmlAttribute(VARIABLES.seoDomains.sourceUrl)#" target="_blank" rel="noopener noreferrer">Ver lista no Semrush ↗</a>
  </div>
  <p class="seo-note">Importado em <strong>#encodeForHtml(VARIABLES.seoDomains.collectedLabel)#</strong>. Estimativas de busca orgânica; não representam todo o acesso do site, tráfego direto ou referências de IA. Para audiência medida, use <a href="/portal/seo/?aba=ga4">Audiência Google</a>. A importação não atualiza ao recarregar esta página.</p>
  <div class="sd-summary">
    <cfloop array="#VARIABLES.sdCards#" index="sdCard">
    <cfset VARIABLES.sdMetric=VARIABLES.sdRoad.metrics[sdCard.key]/>
    <cfset VARIABLES.sdTone=NOT VARIABLES.sdMetric.changeAvailable ? 'unknown' : (VARIABLES.sdMetric.change GT 0 ? 'up' : (VARIABLES.sdMetric.change LT 0 ? 'down' : 'flat'))/>
    <article class="sd-card sd-own"><h3>Road Runners · #encodeForHtml(sdCard.label)#</h3><div class="sd-rank"><cfif VARIABLES.sdRoad.ranks[sdCard.key] GT 0>#VARIABLES.sdRoad.ranks[sdCard.key]#º <span>de #VARIABLES.seoDomains.count#</span><cfelse>Não medido</cfif></div><p><strong><cfif VARIABLES.sdMetric.available>#LSNumberFormat(VARIABLES.sdMetric.value,"9,999")#<cfelse>Não medido</cfif></strong> #encodeForHtml(sdCard.unit)# <span class="sd-change sd-#VARIABLES.sdTone#"><cfif VARIABLES.sdTone EQ "up">↑<cfelseif VARIABLES.sdTone EQ "down">↓<cfelseif VARIABLES.sdTone EQ "flat">→<cfelse>—</cfif> <cfif VARIABLES.sdMetric.changeAvailable>#encodeForHtml(replace(VARIABLES.sdMetric.changeDisplay,".",",","all"))#<cfelse>Não medido</cfif></span></p></article>
    </cfloop>
    <article class="sd-card"><h3>Movimento do tráfego no grupo</h3><div class="sd-movement"><span class="sd-up">↑ #VARIABLES.sdRising# em alta</span><span class="sd-down">↓ #VARIABLES.sdFalling# em queda</span><span>→ #VARIABLES.sdStable# estável</span></div><p>Variações da janela “Mês” exibidas pelo Semrush.</p></article>
  </div>
  <p class="seo-note">Posições somente entre os <strong>#VARIABLES.seoDomains.count# domínios desta lista</strong>. Valores abreviados na fonte são aproximados; empates compartilham posição. O Open Results está em <strong>#VARIABLES.sdOpen.ranks.traffic#º em tráfego</strong> nessa base Brasil.</p>
</cfoutput>
  <form class="sd-controls" data-domain-controls method="get" action="/portal/seo/">
    <input type="hidden" name="aba" value="dominios"/>
    <div class="sd-search"><label for="sd-search">Buscar domínio</label><input id="sd-search" type="search" class="form-control" name="dominio_busca" placeholder="Ex.: roadrunners, corridas…" maxlength="100" autocomplete="off"/></div>
    <div><label for="sd-group">Grupo</label><select id="sd-group" class="form-select" name="dominio_grupo"><option value="all">Todos os domínios</option><option value="own">Road Runners e Open Results</option><option value="reference">Demais referências</option></select></div>
    <div><label for="sd-trend">Movimento do tráfego</label><select id="sd-trend" class="form-select" name="dominio_sinal"><option value="all">Todos</option><option value="up">Em alta</option><option value="down">Em queda</option><option value="flat">Estável</option><option value="unknown">Sem variação medida</option></select></div>
    <div><label for="sd-order">Ordenar por</label><select id="sd-order" class="form-select" name="dominio_ordem"><option value="traffic">Tráfego orgânico</option><option value="trafficChange">Variação do tráfego (%)</option><option value="keywords">Palavras-chave orgânicas</option><option value="keywordsChange">Variação de palavras-chave (%)</option><option value="refDomains">Domínios de referência</option><option value="refDomainsChange">Variação de referências (%)</option><option value="authority">Authority Score</option><option value="authorityChange">Variação do Authority Score (pontos)</option><option value="paidKeywords">Palavras-chave pagas</option><option value="paidKeywordsChange">Variação de palavras-chave pagas (%)</option><option value="paidTraffic">Tráfego pago</option><option value="paidTrafficChange">Variação do tráfego pago (%)</option><option value="domain">Domínio</option></select></div>
    <button class="btn btn-outline-light sd-direction" type="button" id="sd-direction" aria-label="Inverter direção da ordenação">Maior → menor</button>
    <button class="btn btn-link text-reset" type="reset">Limpar</button>
  </form>
  <noscript><p class="seo-note">A tabela completa está ordenada por tráfego. Ative JavaScript para ordenar as colunas e aplicar filtros sem recarregar.</p></noscript>
  <p id="sd-status" class="seo-note" role="status" aria-live="polite"><cfoutput>#VARIABLES.seoDomains.count# domínios · tráfego orgânico, do maior para o menor.</cfoutput></p>
  <div class="sd-table-wrap" tabindex="0" role="region" aria-label="Comparação dos domínios; role horizontalmente para ver todas as colunas">
    <table class="sd-table">
      <caption class="visually-hidden">Domínios monitorados no Semrush, base Brasil, janela Mês. Clique em um cabeçalho para ordenar; as variações podem ser ordenadas pelo seletor acima.</caption>
      <thead><tr><th scope="col" class="sd-position">Rank<br>tráfego</th><th scope="col" data-domain-column="domain"><button type="button" data-domain-sort="domain">Domínio <span aria-hidden="true">↕</span></button></th>
      <cfloop array="#VARIABLES.sdColumns#" index="sdColumn"><cfoutput><th scope="col" data-domain-column="#sdColumn.key#"<cfif sdColumn.key EQ "traffic"> aria-sort="descending"</cfif>><button type="button" data-domain-sort="#sdColumn.key#">#encodeForHtml(sdColumn.label)# <span aria-hidden="true"><cfif sdColumn.key EQ "traffic">↓<cfelse>↕</cfif></span></button></th></cfoutput></cfloop>
      </tr></thead>
      <tbody>
      <cfloop array="#VARIABLES.seoDomains.domains#" index="sdRow"><cfoutput>
        <tr data-domain-row data-domain="#encodeForHtmlAttribute(sdRow.domain)#" data-own="#sdRow.own ? 'true' : 'false'#"<cfif sdRow.own> class="sd-row-own"</cfif>>
          <td class="sd-position"><cfif sdRow.ranks.traffic GT 0>#sdRow.ranks.traffic#º<cfelse>—</cfif></td>
          <th scope="row" class="sd-domain"><a href="https://pt.semrush.com/analytics/overview/?q=#encodeForURL(sdRow.domain)#&amp;db=br&amp;searchType=domain&amp;chartPeriod=1m" target="_blank" rel="noopener noreferrer">#encodeForHtml(sdRow.domain)# ↗</a><cfif sdRow.own><span class="sd-badge">Nosso site</span></cfif><span class="sd-country">BR · <a href="https://#encodeForHtmlAttribute(sdRow.domain)#/" target="_blank" rel="noopener noreferrer">visitar site ↗</a></span></th>
          <cfloop array="#VARIABLES.sdColumns#" index="sdColumn">
          <cfset VARIABLES.sdMetric=sdRow.metrics[sdColumn.key]/>
          <cfset VARIABLES.sdTone=NOT VARIABLES.sdMetric.changeAvailable ? 'unknown' : (VARIABLES.sdMetric.change GT 0 ? 'up' : (VARIABLES.sdMetric.change LT 0 ? 'down' : 'flat'))/>
          <td class="sd-value" data-metric="#sdColumn.key#" data-value="<cfif VARIABLES.sdMetric.available>#encodeForHtmlAttribute(toString(VARIABLES.sdMetric.value))#</cfif>" data-change="<cfif VARIABLES.sdMetric.changeAvailable>#encodeForHtmlAttribute(toString(VARIABLES.sdMetric.change))#</cfif>">
            <strong title="Exibido na fonte: #encodeForHtmlAttribute(VARIABLES.sdMetric.display)#"><cfif VARIABLES.sdMetric.available>#LSNumberFormat(VARIABLES.sdMetric.value,"9,999")#<cfelse>Não medido</cfif></strong>
            <span class="sd-change sd-#VARIABLES.sdTone#"><cfif VARIABLES.sdTone EQ "up">↑<cfelseif VARIABLES.sdTone EQ "down">↓<cfelseif VARIABLES.sdTone EQ "flat">→<cfelse>—</cfif> <cfif VARIABLES.sdMetric.changeAvailable>#encodeForHtml(replace(VARIABLES.sdMetric.changeDisplay,".",",","all"))#<cfif VARIABLES.sdMetric.changeUnit EQ "points"> pt.</cfif><cfelse>Não medido</cfif></span>
          </td>
          </cfloop>
        </tr>
      </cfoutput></cfloop>
      </tbody>
    </table>
  </div>
  <p class="sd-empty" id="sd-empty" hidden>Nenhum domínio corresponde aos filtros. Use “Limpar” para voltar à lista completa.</p>
  <details class="seo-method sd-method"><summary>Como comparar e escolher os próximos sites para análise</summary><div class="seo-method-body">
    <p>O rank de tráfego permanece o mesmo quando você ordena outra coluna ou filtra o grupo. É a posição na lista completa, em ordem decrescente de tráfego orgânico estimado.</p>
    <p>As porcentagens são as variações do recorte “Mês” exibidas pela fonte. Authority Score varia em pontos. A classificação “em alta” ou “em queda” considera apenas o tráfego orgânico; não comprova causa, conversão nem tendência sustentada.</p>
    <p>Comece pelas referências próximas ao Road Runners e pelas que crescem em tráfego e palavras-chave. Abra o domínio no Semrush para comparar as páginas e consultas responsáveis. Sites de inscrições, fotos e notícias podem atender buscas diferentes das de um calendário.</p>
    <p>Este é o primeiro registro desta lista no Business. Novas importações devem preservar cada coleta para construir o histórico. Os gráficos da fonte não foram reconstruídos com valores inferidos. Ausência de medição não equivale a zero.</p>
  </div></details>
</section>
<script src="/portal/seo/assets/domains.js?v=20261025-1" defer></script>
