<cfprocessingdirective pageencoding="utf-8"/>
<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfif compareNoCase(getBaseTemplatePath(), getCurrentTemplatePath()) EQ 0>
  <cfheader statuscode="403"/>
  <cfabort/>
</cfif>
<cfif structKeyExists(CGI, "request_method") AND compareNoCase(CGI.request_method, "GET") NEQ 0>
  <cfheader statuscode="405"/>
  <cfheader name="Allow" value="GET"/>
  <cfabort/>
</cfif>

<!--- Evidências externas curadas. Não são dados ao vivo nem alteram a auditoria técnica. --->
<cfscript>
VARIABLES.seoSearchEvidence = {
 roadrunners = {
  status="warning", label="Indexação com pendências",
  source="Consulta direta ao Search Console em 30/10/2026. Indexação atualizada em 22/10; propriedade de domínio roadrunners.run, incluindo subdomínios. Esse relatório antecede as melhorias de 25 e 30/10.",
  sitemapStatus="pass", sitemapLabel="Índice do sitemap processado pelo Google",
  sitemapDetail="107.352 URLs descobertas no sitemap do site principal. Índice lido em 26/10; sete lotes processados com leituras de 28 a 30/10. O lote static.xml mostra 990 URLs e leitura de 28/10. Descoberta não comprova indexação.",
  indexStatus="warning", indexLabel="21.335 páginas indexadas em 22/10/2026",
  indexDetail="116.687 não indexadas na propriedade de domínio: 87.026 detectadas e 5.025 rastreadas sem indexação; 225 soft 404, 80 não encontradas, 34 erros 5xx e 5 bloqueios 403. Também há exclusões por canonical, redirects, robots e noindex; nem toda exclusão é um erro. O relatório não comprova o estado de cada URL hoje.",
  nextAction="Revisar exemplos dos erros de indexação e das páginas detectadas/rastreadas sem indexação, preservando exclusões intencionais. Experiência móvel atualizada em 28/10: grupo de INP com 926 URLs e grupo de LCP com 391 URLs precisam de melhorias. Detalhes e comparação de buscas na aba Audiência Google. Acompanhar nova leitura do Google após as publicações; respostas HTTP 200 não comprovam reprocessamento nem ganho de ranking."
 },
 openresults = {
  status="warning", label="Sitemap recuperado; indexação a confirmar",
  source="Consulta direta ao Search Console em 04/10/2026: sitemap processado; relatório de indexação ainda atualizado em 20/09/2026.",
  sitemapStatus="pass", sitemapLabel="Índice e quatro lotes processados pelo Google",
  sitemapDetail="34.319 URLs descobertas em /sitemap.xml. Quatro lotes processados em 04/10/2026: 10.000, 10.000, 10.000 e 4.319 URLs. Índice com última leitura em 03/10. A falha anterior de busca foi superada; descoberta não comprova indexação.",
  indexStatus="warning", indexLabel="0 páginas indexadas em 20/09/2026",
  indexDetail="O relatório de indexação mostra 135.791 URLs bloqueadas por 403 e cerca de 139 mil não indexadas. Esta é uma evidência do relatório de páginas, distinta do zero do sitemap; ainda não reflete as mudanças de acesso de 03/10.",
  nextAction="Indexação atual ainda não confirmada. Acompanhar novo relatório de páginas e exemplos de /evento após as mudanças de acesso de 03/10. Preservar noindex em /resultados e bloqueio de /perfil; processamento do sitemap não autoriza indexar páginas pessoais."
 }
};
</cfscript>
