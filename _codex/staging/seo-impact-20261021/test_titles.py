from pathlib import Path
import hashlib, html, json, re, shlex, subprocess, sys
S=Path(__file__).resolve().parent
mode=sys.argv[1];assert mode in ('red','green','review-red')
src=S/('origin' if mode=='red' else 'candidate')/'rr/includes/estrutura/event_title_date.cfm'
event=(S/'origin/rr/evento/index.cfm').read_text()
title='<cfset VARIABLES.eventTitleTypeLabel = ""/>'+event.split('<cfset VARIABLES.eventTitleTypeLabel = ""/>')[1].split('<cfset VARIABLES.keywords')[0]
fixture='''<cfsetting showdebugoutput="false"/><cfcontent type="application/json" reset="true"/><cftry>
<cfset APPLICATION.nomeSite="Road Runners"/><cfset resultRows=[]/>
<cftransaction>
<cfquery>SET TRANSACTION READ ONLY</cfquery>
<cfquery name="qRaces">SELECT id_evento,nome_evento,cidade,estado,data_inicial,tipo_corrida FROM tb_evento_corridas WHERE id_evento IN(46741,46742,40288,41907,44892,37531,37568,40833,23725,25734,37918,45372) ORDER BY id_evento</cfquery>
<cfloop array="#[{code="pt-BR",label="corrida de rua"},{code="en",label="Road race"},{code="es",label="Carrera de ruta"}]#" item="language">
 <cfloop query="qRaces">
  <cfset qEvento=queryNew(qRaces.columnList)/><cfset queryAddRow(qEvento)/>
  <cfloop list="#qRaces.columnList#" item="col"><cfset querySetCell(qEvento,col,qRaces[col][qRaces.currentRow])/></cfloop>
  <cfset eventMetaCatalog={roadRaceTitle=language.label,freeTrainingTitle="Treino"}/>
  <cfinclude template="title_base.cfm"/><cfinclude template="title.cfm"/>
  <cfset arrayAppend(resultRows,{id=qEvento.id_evento[1],name=qEvento.nome_evento[1],lang=language.code,city=qEvento.cidade[1],state=qEvento.estado[1],date=dateFormat(qEvento.data_inicial[1],"dd/mm/yyyy"),title=VARIABLES.title})/>
 </cfloop>
</cfloop>
</cftransaction>
<cfoutput>#serializeJSON(resultRows)#</cfoutput><cfcatch><cfcontent type="application/json" reset="true"/><cfoutput>#serializeJSON({error=cfcatch.message,detail=cfcatch.detail})#</cfoutput></cfcatch></cftry>'''
files={'title.cfm':re.sub(r' cachedwithin="[^"]+"','',src.read_text()),'title_base.cfm':title,'run.cfm':fixture}
remote='''
from pathlib import Path
import json, os, secrets, shutil, subprocess, sys, tempfile
p=json.load(sys.stdin);root=Path('/var/www/business.roadrunners.run');work=Path(tempfile.mkdtemp(prefix='seo-title-impact-',dir=root/'_codex'));os.chmod(work,0o755);key=secrets.token_hex(24)
try:
 (work/'.htaccess').write_text('Require local\\n')
 (work/'Application.cfc').write_text('component{this.name="'+work.name+'";this.datasource="runner_dba";boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||compare(cgi.http_x_seo_verify ?: "","'+key+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
 for n,v in p.items():(work/n).write_text(v)
 cp=subprocess.run(['curl','-sS','--fail-with-body','--max-time','50','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-SEO-Verify: '+key,'https://business.roadrunners.run/_codex/'+work.name+'/run.cfm'],capture_output=True,text=True,timeout=55)
 if cp.returncode:raise RuntimeError(cp.stdout[:2000]+cp.stderr)
 print(cp.stdout)
finally:shutil.rmtree(work)
'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps(files),capture_output=True,text=True,timeout=75)
assert cp.returncode==0,cp.stderr[-2500:]
rows=json.loads(cp.stdout);assert isinstance(rows,list),rows
rows=[{k.lower():v for k,v in row.items()} for row in rows]
checks=[]
newids=[46741,46742,40288,41907,44892]
for row in rows:
    value=html.unescape(row['title'])
    checks.append({'name':f"{row['lang']} date {row['id']}",'passed':row['date'] in value})
    if row['id'] in newids:
        checks.append({'name':f"{row['lang']} full race identity {row['id']}",'passed':value.startswith(row['name']+' ')})
        checks.append({'name':f"{row['lang']} bounded title {row['id']}",'passed':len(value)<=90})
        checks.append({'name':f"{row['lang']} city {row['id']}",'passed':row['city'] in value and row['state'] in value})
for lang in ['pt-BR','en','es']:
    group=[html.unescape(r['title']).lower() for r in rows if r['lang']==lang and r['id'] in newids]
    checks.append({'name':lang+' five distinct titles','passed':len(group)==5 and len(set(group))==5})
if mode=='green':
    old=json.loads((S/'title-tests-red.json').read_text())['rows']
    for row in rows:
        if row['id'] not in newids:
            previous=next(r for r in old if (r['id'],r['lang'])==(row['id'],row['lang']))
            checks.append({'name':f"{row['lang']} control unchanged {row['id']}",'passed':row['title']==previous['title']})
failed=[x['name'] for x in checks if not x['passed']]
(S/f'title-tests-{mode}.json').write_text(json.dumps({'checks':checks,'rows':rows,'failed':failed,'source_hash':hashlib.sha256(src.read_bytes()).hexdigest()},ensure_ascii=False,indent=2))
print(json.dumps({'checks':len(checks),'failed':failed},ensure_ascii=False))
assert bool(failed)==(mode in ('red','review-red'))
