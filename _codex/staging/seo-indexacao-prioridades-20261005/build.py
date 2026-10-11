from pathlib import Path
import shutil,json
P=Path(__file__).resolve().parent
names=['circuito/index.cfm','desafiosupra/2024/index.cfm','desafiosupra/2025/index.cfm']
for n in names:
 f=P/'candidate/rr'/n;f.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(P/'baseline/rr'/n,f)
f=P/'candidate/rr/circuito/index.cfm';s=f.read_text()
guard='''<!--- Inspect incoming parameters before shared includes add URL filter defaults. --->
<cfscript>
VARIABLES.circuitReadRequest = listFindNoCase("GET,HEAD", CGI.REQUEST_METHOD) && structIsEmpty(FORM);
for (VARIABLES.circuitParam in URL) {
    if (!listFindNoCase("tag,i18n_lang,i18n_route", VARIABLES.circuitParam)) {
        VARIABLES.circuitReadRequest = false;
    }
}
</cfscript>

'''
assert s.count('<!--- BACKEND --->')==1;s=s.replace('<!--- BACKEND --->','<!--- BACKEND --->\n'+guard,1)
anchor='<cfif qAgrega.tag EQ "live-run-xp">'
insert='''<!--- Both aggregator identifiers may resolve the same circuit. Prefer the tag used by its links. --->
<cfscript>
VARIABLES.circuitCanonicalTag = URL.tag;
if (qAgrega.recordCount == 1 && reFind("^[a-z0-9][a-z0-9-]{1,255}$", qAgrega.tag & "")) {
    VARIABLES.circuitCanonicalTag = qAgrega.tag & "";
    if (VARIABLES.circuitReadRequest && compare(URL.tag, VARIABLES.circuitCanonicalTag) != 0) {
        location(url=VARIABLES.template & VARIABLES.circuitCanonicalTag & "/", addtoken=false, statuscode=301);
    }
}
</cfscript>

'''
assert s.count(anchor)==2;s=s.replace(anchor,insert+anchor,1)
old='<cfset VARIABLES.canonical = "#APPLICATION.baseCanonica##VARIABLES.template##URL.tag##Len(trim(URL.tag)) ? \'/\' : \'\'##VARIABLES.queryString#"/>'
new='<cfset VARIABLES.canonical = "#APPLICATION.baseCanonica##VARIABLES.template##VARIABLES.circuitCanonicalTag##Len(trim(VARIABLES.circuitCanonicalTag)) ? \'/\' : \'\'##VARIABLES.queryString#"/>'
assert s.count(old)==1;s=s.replace(old,new,1);f.write_text(s)
for year,verb in [('2024','Corre'),('2025','Corra')]:
 f=P/('candidate/rr/desafiosupra/'+year+'/index.cfm');s=f.read_text()
 old='<cfset VARIABLES.title = "Ranking de Desafio Supra - #APPLICATION.nomeSite#"/>'
 new='<cfset VARIABLES.title = "Ranking Desafio '+verb+' Supra '+year+' | #APPLICATION.nomeSite#"/>'
 assert s.count(old)==1;s=s.replace(old,new,1)
 old='<cfset VARIABLES.description = "Ranking de Atletas"/>'
 new='<cfset VARIABLES.description = "Ranking do Desafio '+verb+' Supra '+year+', com classificações masculina e feminina e links para os resultados das provas."/>'
 assert s.count(old)==1;s=s.replace(old,new,1);f.write_text(s)
print(json.dumps({'candidate_files':len(names),'database_changes':False}))
