from pathlib import Path
P=Path(__file__).parent/'candidate'
def edit(n,a,b):
 p=P/n;s=p.read_text();assert s.count(a)==1,(n,s.count(a));p.write_text(s.replace(a,b))
p=P/'includes/backend/backend.cfm';s=p.read_text();a=s.index('<cfquery name="qEventosBase"');b=s.index('\n\n<!--- LISTA DE BADGES --->',a);s=s[:a]+'<cfif VARIABLES.template EQ "/estado/">\n    <cfinclude template="backend_regional_calendar.cfm"/>\n<cfelse>\n'+s[a:b]+'\n</cfif>'+s[b:];p.write_text(s)
p=P/'includes/backend/backend_estado_cidades.cfm';s=p.read_text();a=s.index('<cfquery');b=s.index('</cfquery>',a)+len('</cfquery>');s=s[:a]+'<cfif NOT isDefined("qEstadoCidadesContagens")>\n'+s[a:b]+'\n</cfif>'+s[b:];s=s.replace('"badges"=URL.badges};','"badges"=URL.badges,"periodo_inicio"=URL.periodo_inicio,"periodo_fim"=URL.periodo_fim};');p.write_text(s)
edit('includes/lista_de_eventos_simple.cfm','totalEventos = <cfoutput>#qEventos.recordcount#</cfoutput>;','totalEventos = <cfoutput>#isDefined("VARIABLES.eventListTotal") ? VARIABLES.eventListTotal : qEventos.recordcount#</cfoutput>;')
p=P/'estado/index.cfm';s=p.read_text();s=s.replace('<!--- BACKEND --->','''<!--- Public page numbers are one-based; the API remains zero-based. --->
<cfparam name="URL.pagina" default="1"/>
<cfif NOT reFind("^[1-9][0-9]{0,5}$",URL.pagina)><cfheader statuscode="400"/><cfheader name="X-Robots-Tag" value="noindex"/><p>Página inválida.</p><cfabort/></cfif>
<cfset URL.page = val(URL.pagina)-1/>
<!--- BACKEND --->''',1)
s=s.replace('<cfinclude template="../includes/backend/backend_login.cfm"/>','''<cfif VARIABLES.regionalPage GTE VARIABLES.regionalPages><cfheader statuscode="404"/><cfheader name="X-Robots-Tag" value="noindex"/><cfcontent type="text/html; charset=utf-8" reset="true"/><cfoutput><h1>Página não encontrada no calendário</h1><p>Esta seleção tem #VARIABLES.regionalPages# página(s).</p><a href="#encodeForHTMLAttribute(VARIABLES.regionalPageUrl(1))#">Voltar à primeira página</a></cfoutput><cfabort/></cfif>
<cfinclude template="../includes/backend/backend_login.cfm"/>''',1)
a=s.index('VARIABLES.estadoFilterParts = [];');b=s.index('</cfscript>',a);s=s[:a]+'''VARIABLES.estadoFilterParts = duplicate(VARIABLES.regionalFilterParts);
VARIABLES.estadoFilterSuffix = arrayLen(VARIABLES.estadoFilterParts) ? "?" & arrayToList(VARIABLES.estadoFilterParts,"&") : "";
'''+s[b:]
s=s.replace('// Shared head emits', '''// Page continuations have their own canonical; filter combinations stay out of the index.
VARIABLES.canonical = APPLICATION.baseCanonica & VARIABLES.regionalPageUrl(VARIABLES.regionalPage+1);
if (arrayLen(VARIABLES.regionalFilterParts)) VARIABLES.metaRobots="noindex,follow";
// Shared head emits''')
s=s.replace('" | " & APPLICATION.nomeSite','" | " & APPLICATION.nomeSite') # Keep existing title, adding page below.
s=s.replace('VARIABLES.description = encodeForHTMLAttribute(', 'if (VARIABLES.regionalPage GT 0) VARIABLES.title &= " — Página " & (VARIABLES.regionalPage+1);\nVARIABLES.description = encodeForHTMLAttribute(',1)
s=s.replace('<cfinclude template="../includes/filtros.cfm"/>','<cfinclude template="../includes/regional_period.cfm"/>\n                <cfinclude template="../includes/filtros.cfm"/>',1)
s=s.replace('<cfinclude template="../includes/lista_de_eventos_simple.cfm"/>','<cfinclude template="../includes/lista_de_eventos_simple.cfm"/>\n                        <cfinclude template="../includes/regional_pagination.cfm"/>',1)
s=s.replace('runnerhub-regionais.min.css?v=20261025a','runnerhub-regionais.min.css?v=20261025b').replace('runnerhub-event-filters.min.js?v=20261008seo','runnerhub-event-filters.min.js?v=20261025pages').replace('runnerhub-estado-cidades.min.js?v=20261008seo2','runnerhub-estado-cidades.min.js?v=20261025pages')
s=s.replace('totalEventos: <cfoutput>#qEventos.recordcount#</cfoutput>','totalEventos: <cfoutput>#VARIABLES.regionalTotal#</cfoutput>').replace('window.totalEventos = <cfoutput>#qEventos.recordcount#</cfoutput>','window.totalEventos = <cfoutput>#VARIABLES.regionalTotal#</cfoutput>')
s=s.replace("eventosEndpoint: '/api/eventos.cfm',",'''eventosEndpoint: '/api/eventos.cfm',
            disableInfiniteScroll: true,
            regionalPagination: true,
            extraParams: {periodo_inicio:'<cfoutput>#encodeForJavaScript(URL.periodo_inicio)#</cfoutput>',periodo_fim:'<cfoutput>#encodeForJavaScript(URL.periodo_fim)#</cfoutput>'},''')
s=s.replace('</body>','<script src="/assets/js/runnerhub-regional-period.min.js?v=20261025a"></script>\n</body>');p.write_text(s)
edit('api/eventos.cfm','<cfinclude template="../includes/lista_de_eventos_simple.cfm"/>','<cfinclude template="../includes/lista_de_eventos_simple.cfm"/>\n<cfif VARIABLES.template EQ "/estado/"><cfinclude template="../includes/regional_pagination.cfm"/></cfif>')
# Hide the obsolete 30-day control on regional pages; it remains in the DOM for the shared legacy slider initializer.
edit('includes/filtros.cfm','<!--- PERIODO --->\n            <div class="col-12 p-1">','<!--- PERIODO --->\n            <div class="col-12 p-1"<cfif VARIABLES.template EQ "/estado/"> hidden</cfif>>')
p=P/'assets/js/runnerhub-event-filters.js';s=p.read_text().replace('function callAPI() {','function callAPI() {\n            if (config.regionalPagination) updateUrl(\'pagina\', \'\');',1).replace('function initInfiniteScroll() {','function initInfiniteScroll() {\n            if (config.disableInfiniteScroll) return;',1);p.write_text(s)
p=P/'assets/js/runnerhub-estado-cidades.js';s=p.read_text().replace("'cupom', 'badges'];","'cupom', 'badges', 'periodo_inicio', 'periodo_fim'];").replace("cupom:'false', badges:''}","cupom:'false', badges:'', periodo_inicio:'', periodo_fim:''}");p.write_text(s)
p=P/'includes/regional_summary.cfm';s=p.read_text().replace('val(URL.page) EQ 0 AND','(val(URL.page) EQ 0 OR findNoCase("/estado/",getBaseTemplatePath())) AND',1)
a=s.index('VARIABLES.regionalTotal = qEventos.recordCount;');b=s.index('VARIABLES.regionalFilterParts = [];',a);s=s[:a]+'''VARIABLES.regionalOptions = [{km=5,label="5 km"},{km=10,label="10 km"},{km=21,label="21 km"},{km=42,label="42 km"}];
'''+s[b:]
# Do not overwrite the canonical filter list prepared by the backend.
s=s.replace('regionalFilterParts','regionalShortcutParts').replace('"tempo,rua,trail,nacional,internacional,cupom,badges"','"tempo,rua,trail,nacional,internacional,cupom,badges,periodo_inicio,periodo_fim"')
a=s.index('VARIABLES.regionalPeriod = "";');b=s.index('</cfscript>',a);s=s[:a]+'''VARIABLES.regionalPeriod = dateFormat(VARIABLES.regionalFrom,"dd/mm/yyyy") & " a " & dateFormat(VARIABLES.regionalTo,"dd/mm/yyyy");
'''+s[b:]
s=s.replace('O período considera a data final cadastrada de cada prova.', '<cfif VARIABLES.regionalExactPeriod>O período inclui provas que acontecem em qualquer dia entre as datas escolhidas, inclusive eventos de mais de um dia.<cfelse>O período padrão considera a data final cadastrada de cada prova.</cfif>')
p.write_text(s)
