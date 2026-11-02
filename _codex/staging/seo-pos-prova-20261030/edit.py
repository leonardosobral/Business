from pathlib import Path
S=Path(__file__).resolve().parent;C=S/'candidate'
p=C/'evento/index.cfm';s=p.read_text();needle='<!--- NOME --->';assert s.count(needle)==1;s=s.replace(needle,'<cfinclude template="parts/post_race_data.cfm"/>\n\n'+needle)
needle='<cfset VARIABLES.keywords = eventCatalog.meta.keywords />';assert s.count(needle)==1;s=s.replace(needle,'<cfif VARIABLES.postRace.enabled>\n    <cfset VARIABLES.description = qEvento.nome_evento & ": " & VARIABLES.postRace.dateLabel & " · " & qEvento.cidade & ". " & VARIABLES.postRaceText.meta/>\n</cfif>\n'+needle)
needle='<link rel="stylesheet" href="/assets/css/runnerhub-event-chat-share.css?v=2"/>';assert s.count(needle)==1;s=s.replace(needle,needle+'\n<cfif VARIABLES.postRace.enabled><link rel="stylesheet" href="/assets/css/runnerhub-race-guides.css?v=20261030b"/></cfif>')
needle='                <!---DADOS DO EVENTO--->';assert s.count(needle)==1;s=s.replace(needle,'                <cfinclude template="parts/post_race.cfm"/>\n\n'+needle)
needle='                                    <cfif qEvento.data_final LT now() AND arrayLen(VARIABLES.eventFocoGalleries)>';assert s.count(needle)==1;s=s.replace(needle,'                                    <cfif NOT VARIABLES.postRace.enabled>\n'+needle)
needle='                                    <!--- SUGERE O RESULTADO DO USUARIO';assert s.count(needle)==1;s=s.replace(needle,'                                    </cfif>\n\n'+needle)
p.write_text(s)
p=C/'includes/backend/backend_permanent_race.cfm';s=p.read_text().replace('VARIABLES.permanentLast = {};','VARIABLES.permanentLast = {};\nVARIABLES.permanentRecent = [];')
needle='        if (arrayLen(VARIABLES.permanentItems) LT 25)';assert s.count(needle)==1
s=s.replace(needle,'''        if (dateCompare(VARIABLES.permanentEnd,now(),"d") LT 0 && arrayLen(VARIABLES.permanentRecent) LT 3
            && !listFindNoCase("cancelado,adiado",trim(VARIABLES.permanentSource.status_evento[VARIABLES.permanentRow] & "")))
            arrayAppend(VARIABLES.permanentRecent,duplicate(VARIABLES.permanentEvent));
'''+needle);p.write_text(s)
p=C/'includes/permanent_race_overview.cfm';s=p.read_text();needle='    <details class="rr-race-details">\n        <summary>Inscrições, resultados e planejamento</summary>'
assert s.count(needle)==1;s=s.replace(needle,'''    <cfif arrayLen(VARIABLES.permanentRecent)>
        <details class="rr-race-details" data-permanent-post-race>
            <summary>Pós-prova: resultados e fotos das últimas <cfif VARIABLES.permanentCircuitMode>etapas<cfelse>edições</cfif></summary>
            <p>Abra a ficha da prova para consultar os resultados e as galerias já vinculados. O material disponível varia em cada edição.</p>
            <ul class="rr-race-links"><cfloop array="#VARIABLES.permanentRecent#" index="permanentRecentEvent">
                <li><a href="#encodeForHTMLAttribute(permanentRecentEvent.path & '##pos-prova')#">#encodeForHTML(permanentRecentEvent.dateLabel)# — #encodeForHTML(permanentRecentEvent.name)#</a></li>
            </cfloop></ul>
        </details>
    </cfif>
'''+needle);p.write_text(s)
p=C/'assets/css/runnerhub-race-guides.css';s=p.read_text();s+='\n.rr-post-race-actions{display:flex;flex-wrap:wrap;align-items:center;gap:.6rem 1rem;margin:.5rem 0}.rr-post-race-actions .rr-race-cta{margin:0}.rr-post-race{scroll-margin-top:85px}.rr-post-race button:focus-visible{outline:3px solid #946600;outline-offset:3px}\n';p.write_text(s)
for n in ['maratona/index.cfm','circuito/index.cfm']:
 p=C/n;s=p.read_text();assert 'runnerhub-race-guides.css?v=20261030a' in s;p.write_text(s.replace('runnerhub-race-guides.css?v=20261030a','runnerhub-race-guides.css?v=20261030b'))
print('Updated 6 existing files and 2 new includes')
