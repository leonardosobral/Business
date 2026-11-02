from pathlib import Path
S=Path(__file__).resolve().parent
def replace(project,name,old,new):
 p=S/'candidate'/project/name;s=p.read_text();assert s.count(old)==1,(name,old[:80]);p.write_text(s.replace(old,new))
replace('rr','estado/index.cfm','                        <cfinclude template="../includes/regional_summary.cfm"/>','''                        <cfif URL.tag EQ "SE" AND (NOT len(VARIABLES.estadoCidadeSlug) OR VARIABLES.estadoCidadeSlug EQ "aracaju") AND VARIABLES.regionalPage EQ 0 AND NOT arrayLen(VARIABLES.regionalFilterParts)>
                            <cfset VARIABLES.aracaju2026Context="regional"/>
                            <cfinclude template="../includes/aracaju_2026.cfm"/>
                        </cfif>
                        <cfinclude template="../includes/regional_summary.cfm"/>''')
replace('rr','evento/index.cfm','                <cfinclude template="parts/post_race.cfm"/>','''                <cfif qEvento.id_evento EQ 39399 AND VARIABLES.postRaceLang EQ "pt-br">
                    <cfset VARIABLES.aracaju2026Context="edition"/>
                    <cfinclude template="../includes/aracaju_2026.cfm"/>
                </cfif>
                <cfinclude template="parts/post_race.cfm"/>''')
replace('rr','includes/permanent_race_editorial.cfm','<cfscript>','''<cfif qAgrega.tag EQ "maratona-de-aracaju">
    <cfset VARIABLES.aracaju2026Context="history"/>
    <cfinclude template="aracaju_2026.cfm"/>
</cfif>
<cfscript>''')
replace('or','estado/index.cfm','<cfset VARIABLES.keywords = "resultados, corrida, competição, pódio, atletas, corredores"/>','''<!--- Aracaju is a distinct city landing page; other filters canonicalize to its unfiltered city. --->
<cfif URL.tag EQ "SE" AND (NOT len(VARIABLES.estadoCidadeSlug) OR VARIABLES.estadoCidadeSlug EQ "aracaju")>
    <cfset VARIABLES.canonical=APPLICATION.baseCanonica & "/estado/se/" & (VARIABLES.estadoCidadeSlug EQ "aracaju" ? "?cidade=aracaju" : "")/>
    <cfset VARIABLES.title=VARIABLES.estadoCidadeSlug EQ "aracaju" ? "Resultados de corridas em Aracaju (SE) | Open Results" : "Resultados de corridas em Sergipe | Open Results"/>
    <cfset VARIABLES.description=VARIABLES.estadoCidadeSlug EQ "aracaju" ? "Consulte resultados de corridas em Aracaju, Sergipe: tempos, classificação e edições da Maratona de Aracaju. Escolha o evento e a distância." : "Resultados de corridas em Sergipe. Consulte provas de Aracaju e outras cidades, filtre por distância e encontre tempos e classificações por evento."/>
</cfif>
<cfset VARIABLES.keywords = "resultados, corrida, competição, pódio, atletas, corredores"/>''')
replace('or','estado/index.cfm','<h1 class="or-ranking-year-title mb-0">Eventos em</h1>','''<h1 class="or-ranking-year-title mb-0"><cfif URL.tag EQ "SE" AND (NOT len(VARIABLES.estadoCidadeSlug) OR VARIABLES.estadoCidadeSlug EQ "aracaju")>Resultados em <cfoutput><cfif VARIABLES.estadoCidadeSlug EQ "aracaju">Aracaju (SE)<cfelse>Sergipe</cfif></cfoutput><cfelse>Eventos em</cfif></h1>''')
replace('or','estado/index.cfm','                <!--- ABAS --->','''                <cfif URL.tag EQ "SE" AND (NOT len(VARIABLES.estadoCidadeSlug) OR VARIABLES.estadoCidadeSlug EQ "aracaju")>
                    <cfset VARIABLES.aracaju2026Context="regional"/>
                    <cfinclude template="../includes/aracaju_2026.cfm"/>
                </cfif>

                <!--- ABAS --->''')
replace('or','evento/index.cfm','                    <hr/>','''                    <cfif qEvento.id_evento EQ 39399>
                        <cfset VARIABLES.aracaju2026Context="edition"/>
                        <cfinclude template="../includes/aracaju_2026.cfm"/>
                    </cfif>

                    <hr/>''')
for project in ['rr','or']:
 p=S/'candidate'/project/'includes/aracaju_2026.cfm'
 s=p.read_text().replace('&lt;&gt;','<>').replace('&lt; 3','< 3').replace('/##maratona-aracaju-2026','/#maratona-aracaju-2026');p.write_text(s)
print('Scoped candidates built from current production; existing PNC notice preserved.')
