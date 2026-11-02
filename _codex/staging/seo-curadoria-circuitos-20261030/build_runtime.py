from pathlib import Path
S=Path(__file__).resolve().parent;C=S/'candidate'
p=C/'includes/backend/backend_permanent_race.cfm';s=p.read_text().replace('<cfscript>','''<cfparam name="VARIABLES.permanentCircuitMode" default="false"/>
<cfparam name="VARIABLES.permanentCanonical" default="#APPLICATION.baseCanonica#/maratona/#URL.tag#/"/>
<cfscript>''',1)
s=s.replace('url=APPLICATION.baseCanonica & "/maratona/" & URL.tag & "/"','url=VARIABLES.permanentCanonical')
s=s.replace('VARIABLES.permanentDescription=qAgrega.nome_evento_agregado', '''if (VARIABLES.permanentCircuitMode) {
    VARIABLES.permanentDescription=qAgrega.nome_evento_agregado & ": consulte as próximas etapas cadastradas, cidades, informações de inscrição e etapas realizadas.";
} else VARIABLES.permanentDescription=qAgrega.nome_evento_agregado''',1)
s=s.replace('if (!structIsEmpty(VARIABLES.permanentNext)) VARIABLES.permanentDescription=', 'if (!VARIABLES.permanentCircuitMode && !structIsEmpty(VARIABLES.permanentNext)) VARIABLES.permanentDescription=')
p.write_text(s)
p=C/'includes/permanent_race_overview.cfm';s=p.read_text().replace('Acompanhe as edições de <strong>','Acompanhe <cfif VARIABLES.permanentCircuitMode>as etapas<cfelse>as edições</cfif> de <strong>')
s=s.replace('Próxima edição cadastrada','<cfif VARIABLES.permanentCircuitMode>Próxima etapa cadastrada<cfelse>Próxima edição cadastrada</cfif>')
s=s.replace('Ver detalhes da edição','Ver detalhes <cfif VARIABLES.permanentCircuitMode>da etapa<cfelse>da edição</cfif>')
s=s.replace('Última edição neste histórico:', '<cfif VARIABLES.permanentCircuitMode>Última etapa neste histórico:<cfelse>Última edição neste histórico:</cfif>')
s=s.replace('Mais corridas nas cidades desta prova','<cfif VARIABLES.permanentCircuitMode>Calendários das cidades do circuito<cfelse>Mais corridas nas cidades desta prova</cfif>')
s=s.replace('    <details class="rr-race-details">\n        <summary>Inscrições, resultados e planejamento</summary>','    <cfif NOT VARIABLES.permanentCircuitMode><cfinclude template="permanent_race_editorial.cfm"/></cfif>\n    <details class="rr-race-details">\n        <summary>Inscrições, resultados e planejamento</summary>')
p.write_text(s)
p=C/'circuito/index.cfm';s=p.read_text();a=s.index('                <cfquery name="qEventosCircuito"');b=s.index('                <!--- ABAS --->',a);queries=s[a:b]
s=s[:a]+'''                <cfif VARIABLES.permanentCircuitMode><cfinclude template="../includes/permanent_race_overview.cfm"/></cfif>

'''+s[b:]
# Share the same proven classification as permanent marathons.
queries=queries.replace('ORDER BY evt.data_inicial','ORDER BY evt.data_inicial, evt.id_evento')
queries=queries.replace('WHERE data_inicial >= <cfqueryparam cfsqltype="cf_sql_date" value="#now()#"/>','WHERE (data_final IS NOT NULL AND data_final >= <cfqueryparam cfsqltype="cf_sql_date" value="#now()#"/>) OR (data_final IS NULL AND data_inicial >= <cfqueryparam cfsqltype="cf_sql_date" value="#now()#"/>)')
queries=queries.replace('WHERE data_inicial < <cfqueryparam cfsqltype="cf_sql_date" value="#now()#"/>','WHERE (data_final IS NOT NULL AND data_final < <cfqueryparam cfsqltype="cf_sql_date" value="#now()#"/>) OR (data_final IS NULL AND data_inicial < <cfqueryparam cfsqltype="cf_sql_date" value="#now()#"/>)')
s=s.replace('<!--- META INFO --->',queries+'''
<cfset VARIABLES.permanentCircuitMode = listFindNoCase("live-run-xp,estacoes",qAgrega.agregador_tag) GT 0/>
<cfif VARIABLES.permanentCircuitMode>
    <cfset VARIABLES.permanentCanonical = APPLICATION.baseCanonica & "/circuito/" & VARIABLES.circuitCanonicalTag & "/"/>
    <cfset qEventosAba2=qEventosProximos/>
    <cfset qEventosAba7=qEventosPassados/>
    <cfinclude template="../includes/backend/backend_permanent_race.cfm"/>
</cfif>
<!--- META INFO --->''')
s=s.replace('<!--- HEAD --->','''<cfif VARIABLES.permanentCircuitMode>
    <cfset VARIABLES.canonical=VARIABLES.permanentCanonical/>
    <cfset VARIABLES.title=encodeForHTML(qAgrega.nome_evento_agregado & ": etapas e calendário | " & APPLICATION.nomeSite)/>
    <cfset VARIABLES.description=encodeForHTMLAttribute(VARIABLES.permanentDescription)/>
    <cfset VARIABLES.structuredDataJsonLd=VARIABLES.permanentJson/>
</cfif>
<!--- HEAD --->''')
s=s.replace('    <!--- SEO WEB TOOLS --->','    <cfif VARIABLES.permanentCircuitMode><link rel="stylesheet" href="/assets/css/runnerhub-race-guides.css?v=20261030a"/></cfif>\n    <!--- SEO WEB TOOLS --->',1)
s=s.replace('aria-selected="false">Próximos','aria-selected="<cfif qEventosProximos.recordcount>true<cfelse>false</cfif>">Próximos').replace('aria-selected="false">Realizados','aria-selected="<cfif NOT qEventosProximos.recordcount>true<cfelse>false</cfif>">Realizados').replace('tabindex="1"','tabindex="0"').replace('tabindex="6"','tabindex="0"')
p.write_text(s)
