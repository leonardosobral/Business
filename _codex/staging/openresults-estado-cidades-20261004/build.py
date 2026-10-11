from pathlib import Path
import json,hashlib,subprocess
stage=Path(__file__).resolve().parent
root=Path('/Users/Shared/Projects/RunnerHub/OpenResults')
out=stage/'candidate'
def put(name,text):
 p=out/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text)
backend=(root/'includes/backend.cfm').read_text()
assert backend.count('<cfif isDefined("URL.cidade")>')==1
put('includes/backend.cfm',backend.replace('<cfif isDefined("URL.cidade")>','<cfif isDefined("URL.cidade") AND VARIABLES.template NEQ "/estado/">'))
put('includes/backend_estado_cidades.cfm','''<cfif NOT structKeyExists(VARIABLES,"qEventosBase") OR NOT structKeyExists(VARIABLES,"qEventos") OR NOT isQuery(VARIABLES.qEventosBase) OR NOT isQuery(VARIABLES.qEventos)>
    <cfheader statuscode="403" statustext="Forbidden"/><cfabort/>
</cfif>
<cfparam name="URL.cidade" default=""/>
<cfscript>
// Resultados históricos usam as mesmas facetas da lista, sem restringir a cidade.
if (!listFindNoCase("maiores,maratonas", URL.filtro)) URL.filtro = "";
VARIABLES.estadoCidadeSlug = lCase(trim(URL.cidade));
VARIABLES.estadoCidadeNome = "Cidade não encontrada";
VARIABLES.estadoCityCounts = {};
REQUEST.estadoCityUrl = function(required string slug, string mode=URL.filtro) {
    var parts = [];
    if (len(arguments.slug)) arrayAppend(parts, "cidade=" & urlEncodedFormat(arguments.slug));
    if (len(arguments.mode)) arrayAppend(parts, "filtro=" & urlEncodedFormat(arguments.mode));
    for (var key in listToArray("distancia,tempo,rua,trail,nacional,internacional,cupom,badges,ano")) {
        if (structKeyExists(URL, key) && len(trim(toString(URL[key])))) arrayAppend(parts, key & "=" & urlEncodedFormat(URL[key]));
    }
    return "/estado/" & lCase(URL.tag) & "/" & (arrayLen(parts) ? "?" & arrayToList(parts,"&") : "");
};
</cfscript>
<!--- Nomes independem dos badges ativos: a seleção válida permanece visível mesmo com zero resultados. --->
<cfquery name="qEstadoCidadesNomes" cachedwithin="#CreateTimeSpan(0,0,5,0)#">
    WITH cidades AS (
        SELECT evt.cidade,
            translate(lower(evt.cidade), ' ''àáâãäéèëêíìïîóòõöôúùüûçÇ%.+!&ªº°', '--aaaaaeeeeiiiiooooouuuucc') AS tag_cidade
        FROM tb_evento_corridas evt
        WHERE evt.estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(URL.tag)#"/>
            AND evt.ativo = true AND nullif(trim(evt.cidade),'') IS NOT NULL
            AND evt.data_inicial <= <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now(),'yyyy-mm-dd')#"/>
            AND (EXISTS (SELECT 1 FROM tb_resultados_resumo res WHERE res.id_evento=evt.id_evento)
                OR EXISTS (SELECT 1 FROM tb_resultados res WHERE res.id_evento=evt.id_evento AND res.origem_resultado <> 'validacao_documental')
                OR (evt.url_resultado IS NOT NULL AND evt.url_resultado <> ''))
    )
    SELECT tag_cidade, min(cidade) AS cidade FROM cidades
    GROUP BY tag_cidade ORDER BY cidade ASC
</cfquery>
<cfscript>
for (VARIABLES.cityRow in qEstadoCidadesNomes) {
    if (len(VARIABLES.estadoCidadeSlug) && (VARIABLES.estadoCidadeSlug == VARIABLES.cityRow.tag_cidade || compareNoCase(trim(URL.cidade),trim(VARIABLES.cityRow.cidade)) == 0)) {
        VARIABLES.estadoCidadeSlug = VARIABLES.cityRow.tag_cidade;
        break;
    }
}
</cfscript>
<cfquery name="qEstadoEventosSemCidade" dbtype="query">
    SELECT * FROM qEventos WHERE 1=1
    <cfif URL.filtro EQ "maratonas">
        AND is_maratona = 42 AND tipo_corrida = 'rua'
        AND upper(nome_evento) NOT LIKE '%REVEZAMENTO%'
    </cfif>
    ORDER BY data_final DESC, concluintes DESC
</cfquery>
<cfquery name="qEstadoCidadeContagens" dbtype="query">
    SELECT tag_cidade, count(*) AS total_eventos
    FROM qEstadoEventosSemCidade
    WHERE tag_cidade IS NOT NULL
    GROUP BY tag_cidade
</cfquery>
<cfscript>
VARIABLES.estadoCitiesTotal = URL.filtro == "maiores" ? min(20,qEstadoEventosSemCidade.recordCount) : qEstadoEventosSemCidade.recordCount;
for (VARIABLES.cityRow in qEstadoCidadeContagens) {
    VARIABLES.estadoCityCounts[VARIABLES.cityRow.tag_cidade] = URL.filtro == "maiores" ? min(20,VARIABLES.cityRow.total_eventos) : VARIABLES.cityRow.total_eventos;
}
qEstadoCidades = queryNew("cidade,tag_cidade,total_eventos", "varchar,varchar,integer");
for (VARIABLES.cityRow in qEstadoCidadesNomes) {
    if (!len(trim(VARIABLES.cityRow.cidade)) || !len(trim(VARIABLES.cityRow.tag_cidade)) || reFind("[^a-z0-9-]",VARIABLES.cityRow.tag_cidade)) continue;
    VARIABLES.cityWords = listToArray(lCase(trim(VARIABLES.cityRow.cidade)), " ");
    for (VARIABLES.wordIndex=1;VARIABLES.wordIndex<=arrayLen(VARIABLES.cityWords);VARIABLES.wordIndex++) {
        if (VARIABLES.wordIndex==1 || !listFindNoCase("a,ao,aos,as,com,da,das,de,del,do,dos,e,em,na,nas,no,nos,para,por,sem,sob",VARIABLES.cityWords[VARIABLES.wordIndex])) {
            VARIABLES.cityWords[VARIABLES.wordIndex] = uCase(left(VARIABLES.cityWords[VARIABLES.wordIndex],1)) & mid(VARIABLES.cityWords[VARIABLES.wordIndex],2,len(VARIABLES.cityWords[VARIABLES.wordIndex]));
        }
    }
    VARIABLES.cityName = arrayToList(VARIABLES.cityWords," ");
    VARIABLES.cityCount = structKeyExists(VARIABLES.estadoCityCounts,VARIABLES.cityRow.tag_cidade) ? VARIABLES.estadoCityCounts[VARIABLES.cityRow.tag_cidade] : 0;
    queryAddRow(qEstadoCidades, {cidade=VARIABLES.cityName,tag_cidade=VARIABLES.cityRow.tag_cidade,total_eventos=VARIABLES.cityCount});
    if (VARIABLES.estadoCidadeSlug == VARIABLES.cityRow.tag_cidade) VARIABLES.estadoCidadeNome = VARIABLES.cityName;
}
</cfscript>
<cfquery name="qEstadoEventosCidade" dbtype="query">
    SELECT * FROM qEstadoEventosSemCidade WHERE 1=1
    <cfif len(VARIABLES.estadoCidadeSlug)>
        AND tag_cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.estadoCidadeSlug#"/>
    </cfif>
    <cfif URL.filtro EQ "maiores">ORDER BY concluintes DESC<cfelse>ORDER BY data_final DESC, concluintes DESC</cfif>
</cfquery>
<cfif URL.filtro EQ "maiores">
    <cfquery name="qEventos" dbtype="query" maxrows="20">SELECT * FROM qEstadoEventosCidade ORDER BY concluintes DESC</cfquery>
<cfelse>
    <cfset qEventos = qEstadoEventosCidade/>
</cfif>
''')
api=(root/'api/eventos_por_estado.cfm').read_text().replace('<cfinclude template="../includes/backend.cfm"/>','<cfinclude template="../includes/backend.cfm"/>\n<cfinclude template="../includes/backend_estado_cidades.cfm"/>')
state_guard = '<cfif NOT listFindNoCase("AC,AL,AM,AP,BA,CE,DF,ES,GO,MA,MG,MS,MT,PA,PB,PE,PI,PR,RJ,RN,RO,RR,RS,SC,SE,SP,TO",URL.tag)>\n    <cfheader statuscode="404" statustext="Not Found"/><cfcontent type="text/plain; charset=utf-8" reset="true"/>Estado não encontrado.<cfabort/>\n</cfif>\n'
api=api.replace('<!--- BACKEND --->',state_guard+'\n<!--- BACKEND --->',1)
put('api/eventos_por_estado.cfm',api)
p=(root/'estado/index.cfm').read_text().replace('<cfinclude template="../includes/backend.cfm"/>','<cfinclude template="../includes/backend.cfm"/>\n<cfinclude template="../includes/backend_estado_cidades.cfm"/>')
p=p.replace('<cfset VARIABLES.description = "Resultados de eventos de corrida por estado"/>','<cfset VARIABLES.description = "Resultados de eventos de corrida por estado"/>\n<cfif len(VARIABLES.estadoCidadeSlug)>\n    <cfset VARIABLES.title = encodeForHTML("Resultados de corridas em " & VARIABLES.estadoCidadeNome & " (" & URL.tag & ") - " & APPLICATION.nomeSite)/>\n</cfif>')
p=p.replace('<!doctype html>\n<html lang="pt-br">\n\n','',1)
p=p.replace('<!--- BACKEND --->',state_guard+'\n<!--- BACKEND --->',1)
p=p.replace('<!--- HEAD --->','<!doctype html>\n<html lang="pt-br">\n\n<!--- HEAD --->',1)
p=p.replace('<cfset VARIABLES.title = "Eventos por estado: #ucase(tag)# - #APPLICATION.nomeSite#"/>','<cfset VARIABLES.title = encodeForHTML("Eventos por estado: " & URL.tag & " - " & APPLICATION.nomeSite)/>')
p=p.replace('<body>','<body>\n\n    <link rel="stylesheet" href="/assets/css/openresults-estado-cidades.css?v=20261004-1"/>',1)
p=p.replace('<div class="or-ranking-year-row mb-3">','<div class="or-ranking-year-row or-state-city-row mb-3">',1)
start=p.index('                                    onchange="if (this.value)')
end=p.index('">',start)+2
p=p[:start]+'                                    data-estado-state-select>'+p[end:]
needle='''                    </div>
                </cfif>

                <!--- CIDADE SELECIONADA --->'''
city='''                        <details class="estado-city-picker" data-estado-city-picker>
                            <summary><i class="fa-solid fa-city" aria-hidden="true"></i><span><cfoutput>Cidade: <cfif len(VARIABLES.estadoCidadeSlug)>#encodeForHTML(VARIABLES.estadoCidadeNome)#<cfelse>Todas as cidades</cfif></cfoutput></span><i class="fa-solid fa-chevron-down" aria-hidden="true"></i></summary>
                            <div class="estado-city-picker-panel">
                                <label class="estado-city-picker-label" for="estado-city-search">Buscar cidade</label>
                                <input type="search" id="estado-city-search" placeholder="Digite o nome da cidade" autocomplete="off"/>
                                <p class="estado-city-picker-hint">Contagens conforme os filtros da lista. Em Maiores, até 20 eventos por seleção.</p>
                                <div class="estado-city-picker-list">
                                    <a class="estado-city-picker-item" data-estado-city-slug="" data-estado-city-name="Todas as cidades" href="<cfoutput>#encodeForHTMLAttribute(REQUEST.estadoCityUrl(""))#</cfoutput>"<cfif NOT len(VARIABLES.estadoCidadeSlug)> aria-current="page"</cfif>><span>Todas as cidades</span><span data-city-count><cfoutput>#VARIABLES.estadoCitiesTotal#</cfoutput> eventos</span></a>
                                    <cfoutput query="qEstadoCidades">
                                        <a class="estado-city-picker-item" data-estado-city-slug="#encodeForHTMLAttribute(tag_cidade)#" data-estado-city-name="#encodeForHTMLAttribute(cidade)#"<cfif total_eventos GT 0 OR VARIABLES.estadoCidadeSlug EQ tag_cidade> href="#encodeForHTMLAttribute(REQUEST.estadoCityUrl(tag_cidade))#" aria-disabled="false"<cfelse> aria-disabled="true" tabindex="-1"</cfif><cfif VARIABLES.estadoCidadeSlug EQ tag_cidade> aria-current="page"</cfif>><span>#encodeForHTML(cidade)#</span><span data-city-count>#total_eventos# <cfif total_eventos EQ 1>evento<cfelse>eventos</cfif></span></a>
                                    </cfoutput>
                                </div>
                                <p class="estado-city-picker-status" data-estado-city-status role="status" aria-live="polite"></p>
                            </div>
                        </details>
                    </div>
                </cfif>

                <!--- CIDADE SELECIONADA --->'''
assert needle in p;p=p.replace(needle,city,1)
start=p.index('                <!--- CIDADE SELECIONADA --->')
end=p.index('                <!--- ABAS --->',start)
p=p[:start]+p[end:]
for suffix,mode in [('UL',''),('MA','maiores'),('MR','maratonas')]:
 import re
 pattern=r'(id="nav-tab-'+suffix+r'" href=")[^"]*(" role="tab")'
 p,n=re.subn(pattern,lambda m:m[1]+'<cfoutput>#encodeForHTMLAttribute(REQUEST.estadoCityUrl(VARIABLES.estadoCidadeSlug,"'+mode+'"))#</cfoutput>'+m[2],p)
 assert n==1,(suffix,n)
 p=p.replace('id="nav-tab-'+suffix+'"','data-estado-tab="'+mode+'" id="nav-tab-'+suffix+'"',1)
 p=p.replace('role="tab" aria-selected="false"','role="tab" aria-selected="<cfif URL.filtro EQ "'+mode+'">true<cfelse>false</cfif>"',1)
start=p.index('                        <cfif URL.filtro EQ "">')
end=p.index('                        <cfset VARIABLES.originalEventCardColumnClass',start)
p=p[:start]+'                        <cfset qEventosAba = qEventos/>\n\n'+p[end:]
p=p.replace('<div id="scroll-container-proximas">','<div id="scroll-container-proximas">\n                        <cfif NOT qEventos.recordCount><p class="text-muted py-3" role="status">Nenhum evento encontrado para esta seleção. Experimente outra cidade ou aba.</p></cfif>',1)
start=p.index('    <!--- INFINITE SCROLL --->')
p=p[:start]+'''    <script src="/assets/js/openresults-estado-cidades.js?v=20261004-1"></script>
    <script>
        const estadoUf = <cfoutput>#serializeJSON(URL.tag)#</cfoutput>;
        const estadoCidade = <cfoutput>#serializeJSON(VARIABLES.estadoCidadeSlug)#</cfoutput>;
        OpenResultsEstadoCities.init(document, estadoUf, estadoCidade);
        let totalEventos = <cfoutput>#qEventos.recordCount#</cfoutput>;
        let lastMonth = 0;
        let lastMonthKey = '<cfoutput>#JSStringFormat(URL.lastMonthKey)#</cfoutput>';
        let page = 0;
        let loading = false;
        const pageSize = <cfoutput>#VARIABLES.pageSize#</cfoutput>;
        const spinner = document.getElementById('spinner-proximas');
        const eventListContainer = document.getElementById('listaEvento');
        async function loadImages() {
            if (loading || totalEventos <= (page + 1) * pageSize) return;
            loading = true;
            spinner.style.display = 'block';
            try {
                const response = await fetch(OpenResultsEstadoCities.buildApiUrl(window.location.href, estadoUf, page + 1, lastMonthKey, estadoCidade));
                if (!response.ok) throw new Error('Falha ao carregar eventos: ' + response.status);
                const html = await response.text();
                eventListContainer.insertAdjacentHTML('beforeend',html);
                const fragment = document.createElement('div');
                fragment.innerHTML = html;
                fragment.querySelectorAll('script').forEach(function (script) { eval(script.textContent); });
                page++;
                colorirDistancias();
            } catch (error) {
                console.warn(error.message);
            } finally {
                loading = false;
                spinner.style.display = 'none';
            }
        }
        window.addEventListener('completed.mdb.infiniteScroll', loadImages);
        new mdb.InfiniteScroll(window);
    </script>
</body>
</html>
'''
# Server strings embedded in script cannot terminate a script element.
p=p.replace('#serializeJSON(URL.tag)#','#replace(serializeJSON(URL.tag), "<", "\\u003c", "all")#').replace('#serializeJSON(VARIABLES.estadoCidadeSlug)#','#replace(serializeJSON(VARIABLES.estadoCidadeSlug), "<", "\\u003c", "all")#')
put('estado/index.cfm',p)
js=(Path('/Users/Shared/Projects/RunnerHub/RoadRunners/assets/js/runnerhub-estado-cidades.js')).read_text()
start=js.index('    function normalizeFilter(');end=js.index('    function normalize(value)',start)
js=js[:start]+'''    function buildUrl(href, uf, slug) {
        uf = String(uf || '').toUpperCase();
        slug = String(slug || '').toLowerCase();
        if (validStates.indexOf(uf) < 0 || (slug && !/^[a-z0-9-]+$/.test(slug))) return '';
        var source = new URL(href);
        var target = new URL('/estado/' + uf.toLowerCase() + '/', source.origin);
        filterKeys.forEach(function (key) {
            var value = source.searchParams.get(key);
            if (value !== null && value !== '') target.searchParams.set(key, value);
        });
        if (slug) target.searchParams.set('cidade', slug);
        return target.pathname + target.search;
    }
    function buildTabUrl(href, mode, selected) {
        var source = new URL(href);
        var state = source.pathname.split('/')[2];
        var slug = selected === undefined ? source.searchParams.get('cidade') : selected;
        var targetPath = buildUrl(href,state,slug);
        if (!targetPath || ['','maiores','maratonas'].indexOf(mode) < 0) return '';
        var target = new URL(targetPath,source.origin);
        if (mode) target.searchParams.set('filtro',mode);
        else target.searchParams.delete('filtro');
        return target.pathname + target.search;
    }
    function buildApiUrl(href, uf, page, monthKey, selected) {
        var source = new URL(href);
        var slug = selected === undefined ? source.searchParams.get('cidade') : selected;
        var targetPath = buildUrl(href,uf,slug);
        if (!targetPath) return '';
        var target = new URL(targetPath,source.origin);
        target.pathname = '/api/eventos_por_estado.cfm';
        target.searchParams.set('tag',String(uf).toUpperCase());
        target.searchParams.set('page',String(page));
        target.searchParams.set('lastMonthKey',String(monthKey || ''));
        return target.pathname + target.search;
    }

'''+js[end:]
js=js.replace("var filterKeys = ['distancia'", "var filterKeys = ['filtro', 'ano', 'distancia'")
js=js.replace("    var defaults = {distancia:'1,42', tempo:'0,12', rua:'true', trail:'true', nacional:'true', internacional:'false', cupom:'false', badges:''};\n",'')
js=js.replace("        var sidebar = document.querySelector('[data-estado-city-sidebar]');\n",'')
start=js.index('        window.RunnerHubEstadoCities.update = function (data)');end=js.index('        syncLinks();\n    }',start)
js=js[:start]+'''        document.querySelectorAll('[data-estado-tab]').forEach(function (link) {
            var target = buildTabUrl(window.location.href,link.dataset.estadoTab,selected);
            if (target) link.href = target;
        });
'''+js[end:]
js=js.replace('window.RunnerHubEstadoCities = {buildUrl:buildUrl, matches:matches, acceptsFilters:acceptsFilters, init:init};','window.OpenResultsEstadoCities = {buildUrl:buildUrl, buildTabUrl:buildTabUrl, buildApiUrl:buildApiUrl, matches:matches, init:init};')
put('assets/js/openresults-estado-cidades.js',js)
css=Path('/Users/Shared/Projects/RunnerHub/RoadRunners/assets/css/runnerhub-estado-cidades.css').read_text().split('.estado-breadcrumb')[0]
# Keep state and city adjacent even on narrow screens, with the heading on its own row.
css+='''
.or-state-city-row { flex-wrap:wrap; }
.or-state-city-row .estado-city-picker { width:260px; }
.or-state-city-row .estado-city-picker summary { min-height:44px; }
@media (max-width:767.98px) {
 .or-state-city-row .or-ranking-year-title { flex-basis:100%; }
 .or-state-city-row .or-search-chip-select-wrap { flex:0 1 40%; min-width:0; }
 .or-state-city-row .or-search-chip-select { width:100%; min-width:0; max-width:100%; }
 .or-state-city-row .estado-city-picker { flex:1 1 0; width:auto; min-width:0; }
 .or-state-city-row .estado-city-picker-panel { left:auto; right:0; width:calc(100vw - 32px); max-width:calc(100vw - 32px); }
}
'''
put('assets/css/openresults-estado-cidades.css',css)
files=['includes/backend.cfm','includes/backend_estado_cidades.cfm','assets/js/openresults-estado-cidades.js','assets/css/openresults-estado-cidades.css','api/eventos_por_estado.cfm','estado/index.cfm']
m={'git_ref':subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip(),'before':{},'after':{},'order':files}
for f in files:
 if (root/f).exists():
  g=subprocess.check_output(['git','show','HEAD:'+f],cwd=root)
  assert g==(root/f).read_bytes(),f
  m['before'][f]=hashlib.sha256(g).hexdigest()
 m['after'][f]=hashlib.sha256((out/f).read_bytes()).hexdigest()
(stage/'manifest.json').write_text(json.dumps(m,indent=2))
print('Candidato preparado: 6 arquivos; recuperação dos 3 existentes pelo Git, sem backups avulsos.')
