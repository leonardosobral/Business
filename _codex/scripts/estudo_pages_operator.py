from pathlib import Path
import json,subprocess,shlex,sys
B=Path(__file__).resolve().parents[2]
source=(B/'_codex/scripts/deploy_estudo.py').read_text().split("if __name__=='__main__':main()",1)[0].replace("ROOT=Path(__file__).resolve().parents[2]","ROOT=Path('/var/www/business.roadrunners.run')")
source=source.replace('result=json.loads(p.stdout)', 'result=json.loads(p.stdout) if p.stdout.startswith("{") else {"error":"bridge response","details":p.stdout[:6000].replace(token,"REDACTED"),"stderr":p.stderr}')
mode=sys.argv[1]
if mode=='inspect':
 sql="""SELECT jsonb_build_object(
 'books',(SELECT jsonb_agg(to_jsonb(b)) FROM estudo.cadernos b),
 'sections',(SELECT jsonb_agg(to_jsonb(n)) FROM estudo.notebooks n),
 'cells',(SELECT jsonb_agg(to_jsonb(c)) FROM estudo.notebook_cells c WHERE c.notebook_id<=29),
 'runs',(SELECT jsonb_agg(jsonb_build_object('id',id,'cell_id',cell_id,'frozen',frozen,'status',status)) FROM estudo.notebook_runs),
 'definitions',(SELECT jsonb_object_agg(p.proname,pg_get_functiondef(p.oid)) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname='get_id_geracao'),
 'view_definition',pg_get_viewdef('public.vw_resultados'::regclass),
 'snapshots',(SELECT jsonb_agg(jsonb_build_object('id',id_snapshot,'hash',encode(sha256(convert_to(to_jsonb(s)::text,'UTF8')),'hex'))) FROM estudo.snapshots s)
 )::text AS payload"""
 body="report=deserializeJSON(q.payload[1]);"
 extra="payload=json.load(sys.stdin);result=bridge(Path('/var/www/business.roadrunners.run'),raw_query(payload['sql'])+payload['body']);print(json.dumps(result))"
 payload={'sql':sql,'body':body}
elif mode=='import':
 payload={'sql':Path(sys.argv[2]).read_text(),'file':Path(sys.argv[2]).name}
 source=source.replace("  (work/'run.cfm').write_text","  (work/'import.sql').write_text(payload['sql'])\n  (work/'run.cfm').write_text")
 backup_sql="SELECT jsonb_build_object('books',(SELECT jsonb_agg(to_jsonb(b)) FROM estudo.cadernos b),'sections',(SELECT jsonb_agg(to_jsonb(n)) FROM estudo.notebooks n),'cells',(SELECT jsonb_agg(to_jsonb(c)) FROM estudo.notebook_cells c))::text AS payload"
 extra="payload=json.load(sys.stdin);root=Path('/var/www/business.roadrunners.run');stage=Path('/var/backups/business-estudo-paginas-20260928');stage.mkdir(mode=0o700,exist_ok=True);before=bridge(root,raw_query("+repr(backup_sql)+")+'report=deserializeJSON(q.payload[1]);');bp=stage/'before.json';bp.write_text(json.dumps(before)) if not bp.exists() else None;(stage/Path(payload['file']).name).write_text(payload['sql']);result=bridge(root,'importSQL=fileRead(expandPath(\"import.sql\"));transaction{cfquery(datasource=\"runner_dba\",timeout=50){writeOutput(preserveSingleQuotes(importSQL));}}report={saved=true};');print(json.dumps(result))"

elif mode=='check':
 import base64
 queries=[{'key':c['key'],'sql':c['content']} for sec in json.loads(((Path(__file__).resolve().parents[2]/'_codex/staging/estudo-paginas')/'estudo-pages.json').read_text())['sections'] for c in sec['cells'] if c['lang']=='sql']
 source=source.replace("  (work/'run.cfm').write_text","  (work/'queries.json').write_text(json.dumps(payload['queries']))\n  (work/'run.cfm').write_text")
 payload={'queries':queries,'body':'queries=deserializeJSON(fileRead(expandPath("queries.json")));report={checks=[]};guard=new estudo.includes.SqlReadGuard();for(item in queries){out={key=item.key,ok=false};try{safe=guard.validate(item.sql);transaction{cfquery(datasource="runner_dba"){writeOutput("SET TRANSACTION READ ONLY");}cfquery(datasource="runner_dba"){writeOutput("SET LOCAL ROLE estudo_reader");}cfquery(datasource="runner_dba"){writeOutput("SET LOCAL statement_timeout=\'5s\'");}checkSQL="SELECT * FROM ("&safe&chr(10)&") AS source_check LIMIT 0";cfquery(name="cols",datasource="runner_dba",timeout=7){writeOutput(preserveSingleQuotes(checkSQL));}}out.ok=true;}catch(any e){out.error=e.message&" "&e.detail;}arrayAppend(report.checks,out);}' }
 extra="payload=json.load(sys.stdin);result=bridge(Path('/var/www/business.roadrunners.run'),payload['body']);print(json.dumps(result))"
elif mode=='preservation':
 sql="SELECT jsonb_build_object('books',(SELECT jsonb_agg(to_jsonb(b)) FROM estudo.cadernos b WHERE source_key IS DISTINCT FROM 'pdf-2025-pages-v1'),'sections',(SELECT jsonb_agg(to_jsonb(n)) FROM estudo.notebooks n WHERE source_key IS NULL OR source_key NOT LIKE 'pdf-2025-p%'),'cells',(SELECT jsonb_agg(to_jsonb(c)) FROM estudo.notebook_cells c WHERE source_key IS NULL OR source_key NOT LIKE 'pdf-2025-%'))::text AS payload"
 payload={'sql':sql,'body':'report=deserializeJSON(q.payload[1]);'}
 extra="payload=json.load(sys.stdin);actual=bridge(Path('/var/www/business.roadrunners.run'),raw_query(payload['sql'])+payload['body']);before=json.loads(Path('/var/backups/business-estudo-paginas-20260928/before.json').read_text());ident={'books':'id','sections':'notebook_id','cells':'id'};result={k:{'before':len(before[k]),'after':len(actual[k]),'equal':sorted(before[k],key=lambda x:x[ident[k]])==sorted(actual[k],key=lambda x:x[ident[k]])} for k in ident};print(json.dumps(result))"
elif mode=='catalogue':
 sql="""SELECT jsonb_build_object('books',(SELECT jsonb_agg(to_jsonb(b)) FROM estudo.cadernos b WHERE source_key='pdf-2025-pages-v1'),'sections',(SELECT jsonb_agg(to_jsonb(n) ORDER BY call_order) FROM estudo.notebooks n WHERE source_key LIKE 'pdf-2025-p%'),'cells',(SELECT jsonb_agg(jsonb_build_object('id',c.id,'notebook_id',c.notebook_id,'cell_type',c.cell_type,'lang',c.lang,'source_key',c.source_key,'version',c.version,'sha256',encode(sha256(convert_to(c.content,'UTF8')),'hex')) ORDER BY c.id) FROM estudo.notebook_cells c WHERE c.source_key LIKE 'pdf-2025-%'),'runs',(SELECT jsonb_agg(to_jsonb(r) ORDER BY r.id) FROM estudo.notebook_runs r JOIN estudo.notebook_cells c ON c.id=r.cell_id WHERE c.source_key LIKE 'pdf-2025-%'))::text AS payload"""
 payload={'sql':sql,'body':'report=deserializeJSON(q.payload[1]);'}
 extra="payload=json.load(sys.stdin);result=bridge(Path('/var/www/business.roadrunners.run'),raw_query(payload['sql'])+payload['body']);print(json.dumps(result))"
else:raise SystemExit('Unknown mode')
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
p=subprocess.run(ssh+['python3 -c '+shlex.quote(source+'\n'+extra)],input=json.dumps(payload),capture_output=True,text=True,timeout=110)
if p.returncode:print(p.stderr[-5000:]);sys.exit(p.returncode)
data=json.loads(p.stdout);dest=(Path(__file__).resolve().parents[2]/'_codex/staging/estudo-paginas')/('estudo-pages-'+mode+'.json');dest.write_text(json.dumps(data,ensure_ascii=False,indent=2));print(str(dest))
if mode=='inspect':print(json.dumps({'books':len(data['books']),'sections':len(data['sections']),'cells':len(data['cells']),'definitions':data['definitions'],'view_definition':data['view_definition']},ensure_ascii=False))
elif mode=='check':print(json.dumps({'checked':len(data.get('CHECKS',[])),'all_ok':all(x.get('OK') for x in data.get('CHECKS',[]))}))
elif mode=='catalogue':print(json.dumps({'books':data['books'],'sections':[(x['notebook_id'],x['notebook_title']) for x in data['sections']],'cells':len(data['cells']),'runs':len(data['runs'] or [])},ensure_ascii=False))
else:print(data)
