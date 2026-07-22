<cfsetting showdebugoutput="false" requesttimeout="180"/>
<cfprocessingdirective pageencoding="utf-8"/>
<cfinclude template="../includes/backend/backend_login.cfm"/>

<cfscript>
function stravaMapBoolean(required any value) {
    if (isBoolean(arguments.value)) return arguments.value;
    return listFindNoCase("1,true,t,yes,sim,on", trim(arguments.value & "")) GT 0;
}
</cfscript>

<cfset VARIABLES.stravaMapCanExport = isDefined("qPerfil")
    AND qPerfil.recordcount
    AND (
        stravaMapBoolean(qPerfil.is_admin)
        OR stravaMapBoolean(qPerfil.is_dev)
    )/>

<cfif NOT VARIABLES.stravaMapCanExport>
    <cfcontent reset="true" type="text/plain; charset=utf-8"/>
    <cfheader statuscode="403" statustext="Forbidden"/>
    <cfoutput>Acesso restrito a ADMINs e DEVs do sistema.</cfoutput>
    <cfabort/>
</cfif>

<cfquery name="qStravaMaps">
    WITH mapas AS (
        SELECT percurso.id_evento_percurso,
               percurso.id_evento,
               coalesce(evento.nome_evento, 'Evento sem nome') AS nome_evento,
               evento.data_inicial,
               evento.data_final,
               coalesce(evento.cidade, '') AS cidade,
               coalesce(evento.estado, '') AS estado,
               percurso.percurso_evento,
               percurso.unidade_de_medida,
               trim(percurso.mapa) AS mapa
        FROM tb_evento_corridas_percursos percurso
        INNER JOIN tb_evento_corridas evento
            ON evento.id_evento = percurso.id_evento
        WHERE nullif(trim(percurso.mapa), '') IS NOT NULL
    )
    SELECT mapas.*,
           (SELECT count(DISTINCT id_evento) FROM mapas) AS total_eventos,
           (SELECT count(DISTINCT mapa) FROM mapas) AS total_rotas
    FROM mapas
    ORDER BY lower(nome_evento),
             data_final DESC NULLS LAST,
             percurso_evento,
             id_evento_percurso
</cfquery>

<cfset VARIABLES.stravaMapTotalEvents = qStravaMaps.recordcount ? val(qStravaMaps.total_eventos) : 0/>
<cfset VARIABLES.stravaMapTotalRoutes = qStravaMaps.recordcount ? val(qStravaMaps.total_rotas) : 0/>
<cfset VARIABLES.stravaMapGeneratedAt = now()/>

<cfcontent reset="true" type="text/html; charset=utf-8"/>
<cfheader name="Content-Disposition" value="attachment; filename=mapas-strava-eventos.html"/>
<cfheader name="Cache-Control" value="private, no-store"/>
<cfheader name="X-Content-Type-Options" value="nosniff"/>
<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>Mapas do Strava associados a eventos</title>
  <style>
    :root {
      --bg: #101312;
      --panel: #171b19;
      --panel-soft: #1d221f;
      --line: #303733;
      --text: #f4f2ec;
      --muted: #a8b0aa;
      --accent: #f4b120;
      --strava: #fc4c02;
    }
    * { box-sizing: border-box; }
    body { margin: 0; background: radial-gradient(circle at 80% 0, rgba(244,177,32,.13), transparent 32rem), var(--bg); color: var(--text); font-family: "Avenir Next", Avenir, "Trebuchet MS", sans-serif; }
    main { width: min(1180px, calc(100% - 32px)); margin: 0 auto; padding: 48px 0 64px; }
    .eyebrow { color: var(--accent); font-size: .72rem; font-weight: 800; letter-spacing: .16em; text-transform: uppercase; }
    h1 { margin: .45rem 0 .6rem; font-family: Georgia, "Times New Roman", serif; font-size: clamp(2rem, 5vw, 3.8rem); font-weight: 500; letter-spacing: -.035em; line-height: .98; }
    .intro { max-width: 760px; margin: 0; color: var(--muted); line-height: 1.6; }
    .stats { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 12px; margin: 30px 0 18px; }
    .stat { padding: 16px 18px; border: 1px solid var(--line); border-radius: 14px; background: rgba(23,27,25,.88); }
    .stat strong { display: block; color: var(--accent); font-size: 1.45rem; }
    .stat span { color: var(--muted); font-size: .78rem; }
    .toolbar { display: flex; gap: 12px; align-items: center; margin: 0 0 14px; }
    .search { width: 100%; padding: 13px 15px; border: 1px solid var(--line); border-radius: 12px; outline: none; background: var(--panel); color: var(--text); font: inherit; }
    .search:focus { border-color: var(--accent); box-shadow: 0 0 0 3px rgba(244,177,32,.12); }
    .result-count { flex: 0 0 auto; color: var(--muted); font-size: .82rem; white-space: nowrap; }
    .table-shell { overflow: hidden; border: 1px solid var(--line); border-radius: 16px; background: var(--panel); }
    .table-scroll { overflow-x: auto; }
    table { width: 100%; border-collapse: collapse; }
    th { padding: 13px 16px; background: var(--panel-soft); color: var(--muted); font-size: .72rem; letter-spacing: .08em; text-align: left; text-transform: uppercase; white-space: nowrap; }
    td { padding: 15px 16px; border-top: 1px solid var(--line); vertical-align: middle; }
    tbody tr:hover { background: rgba(244,177,32,.045); }
    .event-name { min-width: 280px; font-weight: 700; }
    .meta { margin-top: 4px; color: var(--muted); font-size: .76rem; }
    .distance { white-space: nowrap; }
    .route-id { color: var(--muted); font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: .78rem; }
    .strava-link { display: inline-flex; align-items: center; gap: 7px; padding: 8px 11px; border: 1px solid rgba(252,76,2,.55); border-radius: 9px; color: #ff8250; font-size: .8rem; font-weight: 800; text-decoration: none; white-space: nowrap; }
    .strava-link:hover { background: var(--strava); border-color: var(--strava); color: white; }
    .empty { padding: 42px 18px; color: var(--muted); text-align: center; }
    footer { padding: 18px 4px 0; color: var(--muted); font-size: .72rem; text-align: center; }
    @media (max-width: 700px) { main { width: min(100% - 20px, 1180px); padding-top: 28px; } .stats { grid-template-columns: 1fr; } .toolbar { align-items: stretch; flex-direction: column; } .result-count { align-self: flex-end; } th, td { padding: 12px; } }
    @media print { body { background: white; color: black; } main { width: 100%; padding: 0; } .toolbar { display: none; } .table-shell, .stat { border-color: #bbb; background: white; } th { background: #eee; color: #333; } td { border-color: #ddd; } .strava-link { color: black; border-color: #777; } }
  </style>
</head>
<body>
<main>
  <header>
    <div class="eyebrow">Road Runners Business</div>
    <h1>Mapas do Strava</h1>
    <p class="intro">Inventário estático das rotas registradas nas modalidades dos eventos, preparado para apoiar a migração ao novo repositório de percursos.</p>
  </header>

  <section class="stats" aria-label="Resumo do inventário">
    <div class="stat"><strong><cfoutput>#numberFormat(qStravaMaps.recordcount, '0')#</cfoutput></strong><span>modalidades com mapa</span></div>
    <div class="stat"><strong><cfoutput>#numberFormat(VARIABLES.stravaMapTotalEvents, '0')#</cfoutput></strong><span>eventos encontrados</span></div>
    <div class="stat"><strong><cfoutput>#numberFormat(VARIABLES.stravaMapTotalRoutes, '0')#</cfoutput></strong><span>rotas distintas do Strava</span></div>
  </section>

  <div class="toolbar">
    <input id="map-search" class="search" type="search" placeholder="Buscar por evento, ID, local, distância ou rota..." autocomplete="off"/>
    <div id="result-count" class="result-count"><cfoutput>#numberFormat(qStravaMaps.recordcount, '0')#</cfoutput> itens</div>
  </div>

  <div class="table-shell">
    <div class="table-scroll">
      <table id="maps-table">
        <thead><tr><th>Evento</th><th>Distância</th><th>Rota</th><th>Mapa no Strava</th></tr></thead>
        <tbody>
          <cfoutput query="qStravaMaps">
            <cfset VARIABLES.stravaMapUrl = "https://www.strava.com/routes/" & trim(qStravaMaps.mapa & "") & "/export_gpx"/>
            <tr data-search="#htmlEditFormat(lCase(qStravaMaps.nome_evento & ' ' & qStravaMaps.id_evento & ' ' & qStravaMaps.cidade & ' ' & qStravaMaps.estado & ' ' & qStravaMaps.percurso_evento & ' ' & qStravaMaps.unidade_de_medida & ' ' & qStravaMaps.mapa))#">
              <td>
                <div class="event-name">#htmlEditFormat(qStravaMaps.nome_evento)#</div>
                <div class="meta">Evento ###qStravaMaps.id_evento# · modalidade ###qStravaMaps.id_evento_percurso#<cfif isDate(qStravaMaps.data_inicial)> · #dateFormat(qStravaMaps.data_inicial, 'dd/mm/yyyy')#</cfif><cfif len(trim(qStravaMaps.cidade & ''))> · #htmlEditFormat(qStravaMaps.cidade)#<cfif len(trim(qStravaMaps.estado & ''))>/#htmlEditFormat(qStravaMaps.estado)#</cfif></cfif></div>
              </td>
              <td class="distance">#htmlEditFormat(qStravaMaps.percurso_evento)# #htmlEditFormat(qStravaMaps.unidade_de_medida)#</td>
              <td class="route-id">#htmlEditFormat(qStravaMaps.mapa)#</td>
              <td><a class="strava-link" href="#htmlEditFormat(VARIABLES.stravaMapUrl)#" target="_blank" rel="noopener noreferrer">Abrir rota ↗</a></td>
            </tr>
          </cfoutput>
          <cfif NOT qStravaMaps.recordcount><tr><td class="empty" colspan="4">Nenhum mapa do Strava foi encontrado.</td></tr></cfif>
        </tbody>
      </table>
    </div>
  </div>

  <footer>Gerado em <cfoutput>#dateTimeFormat(VARIABLES.stravaMapGeneratedAt, 'dd/mm/yyyy HH:nn')#</cfoutput>. Os dados deste arquivo não são atualizados automaticamente.</footer>
</main>
<script>
  (() => {
    const input = document.getElementById('map-search');
    const rows = Array.from(document.querySelectorAll('#maps-table tbody tr[data-search]'));
    const counter = document.getElementById('result-count');
    const normalize = value => value.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().trim();
    const filterRows = () => {
      const terms = normalize(input.value).split(/\s+/).filter(Boolean);
      let visible = 0;
      rows.forEach(row => {
        const haystack = normalize(row.dataset.search || '');
        const show = terms.every(term => haystack.includes(term));
        row.hidden = !show;
        if (show) visible += 1;
      });
      counter.textContent = `${visible.toLocaleString('pt-BR')} ${visible === 1 ? 'item' : 'itens'}`;
    };
    input.addEventListener('input', filterRows);
  })();
</script>
</body>
</html>
