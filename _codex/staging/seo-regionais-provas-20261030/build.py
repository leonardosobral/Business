from pathlib import Path
S=Path(__file__).resolve().parent; C=S/'candidate'
def write(n,s):
 p=C/n;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s)
s=(S/'baseline/maratona/index.cfm').read_text()
a=s.index('                <cfquery name="qEventosMaratona"');b=s.index('                <!--- ABAS --->',a)
queries=s[a:b]
queries=queries.replace('ORDER BY evt.data_inicial','ORDER BY evt.data_inicial, evt.id_evento').replace('WHERE data_inicial >=','WHERE data_final >=').replace('WHERE data_inicial <','WHERE data_final <')
# Include null-end events without excluding their known start date.
queries=queries.replace('WHERE data_final >= <cfqueryparam cfsqltype="cf_sql_date" value="#now()#"/>','WHERE data_final >= <cfqueryparam cfsqltype="cf_sql_date" value="#now()#"/> OR (data_final IS NULL AND data_inicial >= <cfqueryparam cfsqltype="cf_sql_date" value="#now()#"/>)')
queries=queries.replace('WHERE data_final < <cfqueryparam cfsqltype="cf_sql_date" value="#now()#"/>','WHERE data_final < <cfqueryparam cfsqltype="cf_sql_date" value="#now()#"/> OR (data_final IS NULL AND data_inicial < <cfqueryparam cfsqltype="cf_sql_date" value="#now()#"/>)')
s=s[:a]+'                <cfinclude template="../includes/permanent_race_overview.cfm"/>\n\n'+s[b:]
s=s.replace('<!--- META INFO --->',queries+'\n<cfinclude template="../includes/backend/backend_permanent_race.cfm"/>\n\n<!--- META INFO --->')
a=s.index('<cfset VARIABLES.canonical =');b=s.index('<cfset VARIABLES.keywords',a)
s=s[:a]+'''<cfset VARIABLES.canonical = APPLICATION.baseCanonica & "/maratona/" & URL.tag & "/"/>
<cfset VARIABLES.title = encodeForHTML(qAgrega.nome_evento_agregado & ": edições e resultados | " & APPLICATION.nomeSite)/>
<cfset VARIABLES.description = encodeForHTMLAttribute(VARIABLES.permanentDescription)/>
<cfset VARIABLES.structuredDataJsonLd = VARIABLES.permanentJson/>
'''+s[b:]
s=s.replace('    <!--- SEO WEB TOOLS --->','    <link rel="stylesheet" href="/assets/css/runnerhub-race-guides.min.css?v=20261030a"/>\n\n    <!--- SEO WEB TOOLS --->',1)
s=s.replace('aria-selected="false">Próximos','aria-selected="<cfif qEventosAba2.recordcount>true<cfelse>false</cfif>">Próximos').replace('aria-selected="false">Realizados','aria-selected="<cfif NOT qEventosAba2.recordcount>true<cfelse>false</cfif>">Realizados').replace('tabindex="1"','tabindex="0"').replace('tabindex="6"','tabindex="0"')
s=s.replace('<cfset VARIABLES.agrupamento = "mes"/>','<cfif NOT qEventosAba2.recordcount><p class="rr-race-empty">Não há próxima edição neste histórico. Consulte os calendários locais abaixo e as informações do organizador.</p></cfif>\n                        <cfset VARIABLES.agrupamento = "mes"/>',1)
write('maratona/index.cfm',s)
s=(S/'baseline/estado/index.cfm').read_text().replace('    <style>','    <link rel="stylesheet" href="/assets/css/runnerhub-race-guides.min.css?v=20261030a"/>\n    <style>',1)
anchor='                        <cfinclude template="../includes/regional_pagination.cfm"/>'
# Separate from the AJAX calendar: this is historical navigation, not a filtered count.
a=s.index(anchor)+len(anchor); end=s.index('</div>',a)+len('</div>')
s=s[:end]+'\n                    <cfinclude template="../includes/regional_races.cfm"/>\n'+s[end:]
write('estado/index.cfm',s)
