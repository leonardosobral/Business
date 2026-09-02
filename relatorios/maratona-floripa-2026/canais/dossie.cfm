<cfset VARIABLES.mifRequestedChannel = structKeyExists(URL, "canal") ? lCase(trim(URL.canal & "")) : ""/>
<cfif reFind("^[a-z0-9-]+$", VARIABLES.mifRequestedChannel)>
    <cfset VARIABLES.mifReportRequestedReturnPath = "/relatorios/maratona-floripa-2026/canais/dossie.cfm?canal="
        & urlEncodedFormat(VARIABLES.mifRequestedChannel)/>
</cfif>
<cfinclude template="../includes/auth.cfm"/>
<cfinclude template="../includes/data.cfm"/>

<cfset VARIABLES.mifChannelSlug = VARIABLES.mifRequestedChannel/>
<cfset VARIABLES.mifChannelDatasetPath = "channels/" & VARIABLES.mifChannelSlug & ".json"/>
<cfif NOT reFind("^[a-z0-9-]+$", VARIABLES.mifChannelSlug)
    OR NOT structKeyExists(VARIABLES.mifReportManifest.artifacts, VARIABLES.mifChannelDatasetPath)>
    <cfheader statuscode="404" statustext="Not Found"/>
    <cfcontent type="text/html; charset=utf-8"/>
    <!doctype html>
    <html lang="pt-BR"><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/><title>Canal não encontrado</title><link rel="stylesheet" href="../assets/report.css"/></head>
    <body><main class="report-content"><section class="report-section"><h1>Canal não encontrado</h1><p>O dossiê solicitado não existe neste fechamento.</p><p><a href="./">Voltar à lista de canais</a></p></section></main></body></html>
    <cfabort/>
</cfif>

<cfset VARIABLES.mifChannelPayload = mifReadDataset(VARIABLES.mifChannelDatasetPath)/>
<cfset VARIABLES.mifChannelPayloadJson = serializeJson(VARIABLES.mifChannelPayload)/>
<cfset VARIABLES.mifChannelPayloadJson = replace(VARIABLES.mifChannelPayloadJson, "</", "<\/", "all")/>

<cfheader name="Cache-Control" value="private, no-store, max-age=0"/>
<cfcontent type="text/html; charset=utf-8"/>
<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <meta name="robots" content="noindex,nofollow,noarchive"/>
  <title>Dossiê de canal — Maratona de Floripa 2026</title>
  <link rel="stylesheet" href="../assets/report.css"/>
</head>
<body>
  <div class="report-shell">
    <header class="report-topbar no-print">
      <a href="./">← Todos os canais</a>
      <span>Dossiê comercial · Evento 72611</span>
      <div class="report-actions">
        <a class="button" href="../">Análise geral</a>
        <button class="button button-primary" type="button" onclick="window.print()">Gerar PDF deste canal</button>
      </div>
    </header>
    <section class="report-hero">
      <span class="eyebrow">Dossiê individual de canal</span>
      <h1 id="mif-channel-name">Perfil comercial</h1>
      <p id="mif-channel-hero-summary">Escala, ciclo, distâncias, lotes, territórios, produtos e códigos de cupom consolidados.</p>
    </section>
    <nav class="chapter-nav no-print" aria-label="Seções do dossiê">
      <a href="#canal-resumo">Resumo</a>
      <a href="#canal-ciclo">Ciclo</a>
      <a href="#canal-distancias-lotes">Distâncias e lotes</a>
      <a href="#canal-territorios">Territórios</a>
      <a href="#canal-produtos">Produtos</a>
      <a href="#canal-cupons">Cupons</a>
      <a href="#canal-recomendacao">Recomendação</a>
    </nav>
    <main class="report-content" id="mif-report-root" aria-live="polite"></main>
  </div>

  <script type="application/json" id="mif-report-data"><cfoutput>#VARIABLES.mifChannelPayloadJson#</cfoutput></script>
  <script src="../assets/report.js"></script>
  <script>
    (function renderMifChannelPage() {
      'use strict';
      var payload = JSON.parse(document.getElementById('mif-report-data').textContent);
      var channel = payload.channel || {};
      document.getElementById('mif-channel-name').textContent = channel.channel_name || 'Perfil comercial';
      document.getElementById('mif-channel-hero-summary').textContent = channel.executive_summary || channel.executive_highlight || 'Perfil consolidado do canal.';
      document.title = (channel.channel_name || 'Dossiê de canal') + ' — Maratona de Floripa 2026';
      MifReport.renderChannel(document.getElementById('mif-report-root'), payload);
    })();
  </script>
</body>
</html>
