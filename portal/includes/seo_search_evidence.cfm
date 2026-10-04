<cfprocessingdirective pageencoding="utf-8"/>
<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfif compareNoCase(getBaseTemplatePath(), getCurrentTemplatePath()) EQ 0>
  <cfheader statuscode="403" statustext="Forbidden"/>
  <cfabort/>
</cfif>
<cfif structKeyExists(CGI, "request_method") AND compareNoCase(CGI.request_method, "GET") NEQ 0>
  <cfheader statuscode="405" statustext="Method Not Allowed"/>
  <cfheader name="Allow" value="GET"/>
  <cfabort/>
</cfif>

<!--- Evidências externas curadas. Não são dados ao vivo nem alteram a auditoria técnica. --->
<cfscript>
VARIABLES.seoSearchEvidence = {
 roadrunners = {
  status="warning", label="Indexação com pendências",
  source="Consulta direta ao Search Console em 04/10/2026. Sitemaps e indexação têm datas de atualização próprias; relatório de indexação atualizado em 20/09/2026.",
  sitemapStatus="pass", sitemapLabel="Índice do sitemap processado pelo Google",
  sitemapDetail="103.030 URLs descobertas na consulta de 04/10. Índice lido em 26/09; sete lotes processados. O lote static.xml ainda mostra 49 URLs e leitura de 30/09, anterior à ampliação de estados e cidades. Descoberta não comprova indexação.",
  indexStatus="warning", indexLabel="14,1 mil páginas indexadas em 20/09/2026",
  indexDetail="Todas as páginas conhecidas: cerca de 109 mil não indexadas. Entre os motivos: 167 soft 404, 52 não encontradas, 23 erros 5xx e 5 bloqueios 403. Os totais são os valores arredondados exibidos pelo Google e não representam a situação de hoje.",
  nextAction="Estatísticas de 2025 corrigidas e verificadas em 04/10/2026: cinco URLs públicas responderam 200, incluindo filtros de cidade e estado. A primeira carga levou 5,2 s; filtros com cache, cerca de 0,2 s. Isso não confirma reprocessamento pelo Google. Em 04/10 também foi corrigido o redirect genérico de evento inexistente: nove URLs agora respondem 404 e onze controles válidos continuam 200. Demais soft 404 seguem em revisão (RR-16); nenhum reprocessamento pelo Google foi confirmado. Canonical, redirects e bloqueios intencionais exigem contexto."
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
