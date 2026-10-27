from pathlib import Path
p=Path(__file__).parent/'candidate'
def edit(n,a,b):
 f=p/n;s=f.read_text();assert s.count(a)==1,(n,s.count(a));f.write_text(s.replace(a,b))
edit('includes/regional_summary.cfm',"URL.distancia EQ regionalOption.km & ',' & regionalOption.km","URL.distancia EQ (regionalOption.km & ',' & regionalOption.km)")
f=p/'estado/index.cfm';s=f.read_text();start=s.index('                   <div class="home-side-block p-3 estado-city-list-card"');end=s.index('\n\n               <cfinclude',start);old=s[start:end];city=old[old.index('                       <div data-estado-city-sidebar>'):old.rindex('                   </div>')]
block='''                <details class="rr-regional-cities"<cfif NOT qEstadoCidadesSidebar.recordCount> hidden</cfif>>
                    <summary><cfoutput>Cidades #VARIABLES.estadoHeroStatePrepositions[VARIABLES.estadoHeroUfSelecionada]# #getEstadoNome(VARIABLES.estadoHeroUfSelecionada)#</cfoutput></summary>
'''+city+'''                </details>
'''
s=s.replace(old,'');s=s.replace('                <!--- DESTAQUE --->',block+'\n                <!--- DESTAQUE --->',1);s=s.replace('                        <cfinclude template="../includes/eventos_ads.cfm"/>','                        <cfinclude template="../includes/regional_summary.cfm"/>\n\n                        <cfinclude template="../includes/eventos_ads.cfm"/>',1);s=s.replace('    <style>','    <link rel="stylesheet" href="/assets/css/runnerhub-regionais.min.css?v=20261025a"/>\n    <style>',1);f.write_text(s)
edit('api/eventos.cfm','<cfinclude template="../includes/lista_de_eventos_simple.cfm"/>','<cfif VARIABLES.template EQ "/estado/"><cfinclude template="../includes/regional_summary.cfm"/></cfif>\n<cfinclude template="../includes/lista_de_eventos_simple.cfm"/>')
# Reuse the existing tag_cidade column, aligning its whitespace normalization with regional routes.
edit('includes/backend/backend_evento.cfm','translate(lower( cidade ),','translate(lower(trim(evt.cidade)),')
edit('evento/parts/breadcrumb.cfm','        item=REQUEST.currentBaseUrl & "/estado/" & lCase(VARIABLES.eventBreadcrumbUf) & "/"});','''        item=REQUEST.currentBaseUrl & "/estado/" & lCase(VARIABLES.eventBreadcrumbUf) & "/"});
    if (listFindNoCase(qEvento.columnList,"tag_cidade") && reFind("^[a-z0-9-]+$",qEvento.tag_cidade[1] & "") && len(trim(qEvento.cidade[1] & ""))) {
        arrayAppend(VARIABLES.eventBreadcrumbs, {"@type"="ListItem", position=arrayLen(VARIABLES.eventBreadcrumbs)+1,
            name=trim(qEvento.cidade[1]), item=REQUEST.currentBaseUrl & "/estado/" & lCase(VARIABLES.eventBreadcrumbUf) & "/" & qEvento.tag_cidade[1] & "/"});
    }''')
edit('evento/parts/breadcrumb.cfm','eventBreadcrumb.position EQ 2> hreflang','eventBreadcrumb.position GT 1> hreflang')
f=p/'includes/estrutura/footer.cfm';s=f.read_text();labels=['Calculadora de pace','Pace calculator (PT)','Calculadora de ritmo (PT)'];lines=s.splitlines(True);out=[];i=0
for line in lines:
 out.append(line)
 if '"radar" = ' in line:out.append('        "pace" = "'+labels[i]+'",\n');i+=1
assert i==3
s=''.join(out).replace('        { label = "radar", href = REQUEST.i18nBuildPath("radar") },','        { label = "radar", href = REQUEST.i18nBuildPath("radar") },\n        { label = "pace", href = "/calculadora-de-pace/" },');f.write_text(s)
edit('sitemaps/index.cfm','    for (stateCode in stateCodes) {','    addUrl(baseUrl & "/calculadora-de-pace/", "2026-10-25");\n    for (stateCode in stateCodes) {')
