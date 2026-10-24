from pathlib import Path
import hashlib,html,json,re,shlex,subprocess,sys
S=Path(__file__).resolve().parent;mode=sys.argv[1];assert mode in ('red','green')
src=S/('baseline' if mode=='red' else 'candidate')/'includes/estrutura/event_title_date.cfm'
event=(S/'baseline/evento/index.cfm').read_text()
base='<cfset VARIABLES.eventTitleTypeLabel = ""/>'+event.split('<cfset VARIABLES.eventTitleTypeLabel = ""/>')[1].split('<cfset VARIABLES.keywords')[0]
tags=['2026-trackfield-run-series-2025-sao-jose-do-rio-preto','2026-trackfield-run-series-2025-shopping-vitoria-ii','2026-corrida-e-caminhada-outubro-rosa-aspec','2026-corrida-e-caminhada-outubro-rosa-ba']
sql="SELECT id_evento,tag,nome_evento,cidade,estado,data_inicial,tipo_corrida FROM tb_evento_corridas WHERE tag IN ("+','.join("'"+x+"'" for x in tags)+") OR id_evento IN(46741,46742,40288,41907,44892,37531,37568,40833,23725,25734,37918,45372) ORDER BY id_evento"
fixture='''<cfsetting showdebugoutput="false"/><cfcontent type="application/json" reset="true"/><cftry>
<cfset APPLICATION.nomeSite="Road Runners"/><cfset resultRows=[]/>
<cftransaction><cfquery>SET TRANSACTION READ ONLY</cfquery>
<cfquery name="qRaces">'''+sql+'''</cfquery>
<cfloop array="#[{code="pt-BR",label="corrida de rua"},{code="en",label="Road race"},{code="es",label="Carrera de ruta"}]#" item="language">
 <cfloop query="qRaces">
  <cfset qEvento=queryNew(qRaces.columnList)/><cfset queryAddRow(qEvento)/>
  <cfloop list="#qRaces.columnList#" item="col"><cfset querySetCell(qEvento,col,qRaces[col][qRaces.currentRow])/></cfloop>
  <cfset eventMetaCatalog={roadRaceTitle=language.label,freeTrainingTitle="Treino"}/>
  <cfinclude template="base.cfm"/><cfinclude template="title.cfm"/>
  <cfset arrayAppend(resultRows,{id=qEvento.id_evento[1],tag=qEvento.tag[1],name=qEvento.nome_evento[1],lang=language.code,city=qEvento.cidade[1],state=qEvento.estado[1],date=dateFormat(qEvento.data_inicial[1],"dd/mm/yyyy"),title=VARIABLES.title})/>
 </cfloop>
</cfloop></cftransaction>
<cfoutput>#serializeJSON(resultRows)#</cfoutput><cfcatch><cfheader statuscode="500"/><cfoutput>#serializeJSON({error=cfcatch.message,detail=cfcatch.detail})#</cfoutput></cfcatch></cftry>'''
files={'title.cfm':re.sub(r' cachedwithin="[^"]+"','',src.read_text()),'base.cfm':base,'run.cfm':fixture}
remote='''from pathlib import Path
import json,os,secrets,shutil,subprocess,sys,tempfile
p=json.load(sys.stdin);root=Path('/var/www/business.roadrunners.run');work=Path(tempfile.mkdtemp(prefix='seo-title-full-name-',dir=root/'_codex'));os.chmod(work,0o755);key=secrets.token_hex(24)
try:
 (work/'.htaccess').write_text('Require local\\n')
 (work/'Application.cfc').write_text('component{this.name="'+work.name+'";this.datasource="runnerhub";boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||compare(cgi.http_x_seo_verify ?: "","'+key+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
 for n,v in p.items():(work/n).write_text(v)
 cp=subprocess.run(['curl','-sS','--fail-with-body','--max-time','50','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-SEO-Verify: '+key,'https://business.roadrunners.run/_codex/'+work.name+'/run.cfm'],capture_output=True,text=True,timeout=55)
 if cp.returncode:raise RuntimeError(cp.stdout[:1600]+cp.stderr)
 print(cp.stdout)
finally:shutil.rmtree(work)
'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps(files),capture_output=True,text=True,timeout=80)
assert cp.returncode==0,cp.stderr[-2500:]
rows=json.loads(cp.stdout);assert isinstance(rows,list),rows
rows=[{k.lower():v for k,v in x.items()} for x in rows];checks=[]
for row in rows:
 v=html.unescape(row['title'])
 checks.append(dict(name=f"date {row['lang']} {row['id']}",passed=row['date'] in v))
 if row['tag'] in tags:
  checks.append(dict(name=f"full identity {row['lang']} {row['id']}",passed=v.startswith(row['name']+' ')))
  checks.append(dict(name=f"escaped identity {row['lang']} {row['id']}",passed=('&' not in row['name'] or '&amp;' in row['title'])))
 if row['id'] in [46741,46742,40288,41907,44892]:
  checks.append(dict(name=f"prior city identity {row['lang']} {row['id']}",passed=v.startswith(row['name']+' ') and row['city'] in v and row['state'] in v))
for lang in ['pt-BR','en','es']:
 values=[html.unescape(r['title']).lower() for r in rows if r['lang']==lang and r['tag'] in tags]
 checks.append(dict(name=lang+' four distinct titles',passed=len(values)==4 and len(set(values))==4))
failed=[c['name'] for c in checks if not c['passed']]
r=dict(checks=checks,failed=failed,rows=rows,hashes={'includes/estrutura/event_title_date.cfm':hashlib.sha256(src.read_bytes()).hexdigest()})
(S/('tests-'+mode+'.json')).write_text(json.dumps(r,ensure_ascii=False,indent=2))
print(json.dumps(dict(checks=len(checks),failed=failed),ensure_ascii=False))
assert bool(failed)==(mode=='red')
