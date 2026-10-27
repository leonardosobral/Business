<cfprocessingdirective pageencoding="utf-8"/>
<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfif compareNoCase(getBaseTemplatePath(),getCurrentTemplatePath()) EQ 0><cfheader statuscode="403"/><cfabort/></cfif>
<cfif CGI.request_method NEQ "GET"><cfheader statuscode="405"/><cfheader name="Allow" value="GET"/><cfabort/></cfif>
<cfif NOT structKeyExists(session,"seoGa4Csrf")><cfset session.seoGa4Csrf=lCase(hash(generateSecretKey("AES",256),"SHA-256"))/></cfif>
<link rel="stylesheet" href="/portal/seo/assets/ga4.css?v=20261005a"/>
<section class="ga4" aria-labelledby="ga4-title">
<h2 class="h5" id="ga4-title">Audiência Google · Road Runners</h2>
<cfif VARIABLES.seoQueueSiteFilter EQ "openresults">
<p>Esta integração está disponível para o Road Runners.</p><a href="/portal/seo/?aba=ga4&amp;site=roadrunners">Ver Road Runners</a>
<cfelse>
<p class="seo-note">Dados medidos pelo GA4. Incluem os canais identificados pelo Google; não são a estimativa orgânica do Semrush nem os contadores próprios.</p>
<cfif structKeyExists(session,"seoGa4Message")><p class="ga4-notice"><cfoutput>#encodeForHtml(session.seoGa4Message)#</cfoutput></p><cfset structDelete(session,"seoGa4Message")/></cfif>
<cfoutput><div id="ga4-app" data-csrf="#encodeForHtmlAttribute(session.seoGa4Csrf)#"></cfoutput>
<p id="ga4-status" role="status" aria-live="polite">Verificando conexão Google…</p>
<div id="ga4-connect-panel" hidden>
<p>Autorize a leitura do Analytics com <strong>contato@runnerhub.run</strong>. A autorização acontece no Google; as outras integrações do Business continuam usando a mesma conexão.</p>
<button type="button" id="ga4-connect" class="btn btn-warning">Autorizar Google Analytics</button>
</div>
<form id="ga4-filters" class="ga4-filters" hidden>
<label>Propriedade GA4<select id="ga4-property" required class="form-select"></select></label>
<label>Período<select id="ga4-days" class="form-select"><option value="7">7 dias completos</option><option value="28" selected>28 dias completos</option><option value="90">90 dias completos</option></select></label>
<button class="btn btn-warning" type="submit">Carregar dados</button>
<button class="btn btn-outline-secondary" type="button" id="ga4-reconnect">Reconectar Google</button>
</form>
<details class="ga4-help"><summary>Configuração e limites da medição</summary>
<p>Se o Google informar que a API está desabilitada, habilite a <a href="https://console.cloud.google.com/apis/library/analyticsdata.googleapis.com" target="_blank" rel="noopener noreferrer">Google Analytics Data API</a> e a <a href="https://console.cloud.google.com/apis/library/analyticsadmin.googleapis.com" target="_blank" rel="noopener noreferrer">Google Analytics Admin API</a> no mesmo projeto Google Cloud usado pela Agenda. O consentimento deve permitir o escopo de leitura do Analytics.</p>
<p>A propriedade precisa conter o fluxo G-7MYGVTEDZV. As consultas incluem somente roadrunners.run e www.roadrunners.run. Cache de até 15 minutos; atualização ao consultar esta tela, sem sincronização agendada.</p>
<p>Hoje fica fora da comparação. Os últimos dias ainda podem ser revisados pelo Google. Bloqueadores, consentimento, configuração das tags e automações podem afetar a medição; usuários não equivalem necessariamente a pessoas.</p>
</details>
<div id="ga4-result" hidden>
<p id="ga4-period" class="seo-note"></p><p id="ga4-warnings" class="ga4-notice" hidden></p>
<dl id="ga4-metrics" class="ga4-metrics"></dl>
<nav class="ga4-tabs" aria-label="Relatórios de audiência">
<a href="#evolucao" data-ga4-tab="evolucao">Evolução</a><a href="#canais" data-ga4-tab="canais">Canais</a><a href="#paginas" data-ga4-tab="paginas">Páginas de entrada</a><a href="#ia" data-ga4-tab="ia">Referências de IA</a>
</nav>
<section id="ga4-evolucao"><h3 class="h6">Evolução diária</h3><p class="seo-note">Usuários diários não devem ser somados para calcular usuários únicos do período. Datas sem linha retornada pelo Google não aparecem nesta tabela.</p><div class="ga4-table" id="ga4-daily"></div></section>
<section id="ga4-canais" hidden><h3 class="h6">Canais de aquisição</h3><p class="seo-note">Direct significa origem não identificada; não comprova que o endereço foi digitado. Uma pessoa pode aparecer em mais de um canal.</p><div class="ga4-table" id="ga4-channels"></div></section>
<section id="ga4-paginas" hidden><h3 class="h6">20 principais páginas de entrada</h3><div class="ga4-table" id="ga4-pages"></div></section>
<section id="ga4-ia" hidden><h3 class="h6">Origens identificadas como IA</h3><p class="seo-note">ChatGPT, Perplexity, Claude, Gemini e Copilot identificados pela origem da sessão. Acessos sem referência ou marcação podem aparecer em Direct. Ausência de linhas não comprova ausência de acessos por IA.</p><div class="ga4-table" id="ga4-ai"></div></section>
</div></div>
<script src="/portal/seo/assets/ga4.js?v=20261005a" defer></script>
</cfif></section>
