from pathlib import Path
import importlib.util,json,base64,subprocess,shlex
ROOT=Path(__file__).resolve().parents[3];W=Path(__file__).resolve().parent
s=importlib.util.spec_from_file_location('helpers',ROOT/'_codex/scripts/deploy_estudo.py');h=importlib.util.module_from_spec(s);s.loader.exec_module(h)
FILES=['estudos/includes/StudyAccess.cfc','estudos/includes/FirstAccess.cfc','estudos/primeiro-acesso/index.cfm','estudos/primeiro-acesso/primeiro-acesso.js']
def remote(body,payload):
 source=h.ROOT.joinpath('_codex/scripts/deploy_estudo.py').read_text().split('def legacy_sql')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")+'\npayload=json.load(sys.stdin)\n'+body
 p=subprocess.run(h.SSH+['python3 -c '+shlex.quote(source)],input=json.dumps(payload),capture_output=True,text=True,timeout=220)
 if p.returncode:raise RuntimeError(p.stderr[-7000:])
 return json.loads(p.stdout)
if __name__=='__main__':
 body="""result={};root=Path('/var/www/business.roadrunners.run')
for n in payload['files']:
 p=root/n;result[n]={'sha':digest(p.read_bytes())if p.exists()else None,'content':base64.b64encode(p.read_bytes()).decode()if p.exists()else None}
print(json.dumps(result))"""
 r=remote(body,{'files':FILES})
 for n,info in r.items():
  p=ROOT/n
  if info['content']:
   data=base64.b64decode(info.pop('content'));assert p.read_bytes()==data,'Local/live divergence: '+n
   dest=W/'baseline'/n;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(data)
  else:assert not p.exists(),n;info.pop('content')
 (W/'baseline.json').write_text(json.dumps(r,indent=2));print({n:i['sha']for n,i in r.items()})
 sql="SELECT jsonb_build_object('product',(SELECT jsonb_build_object('id',id,'code',codigo) FROM estudo.produtos WHERE codigo='previa-2026-q3'),'audit_columns',(SELECT jsonb_agg(jsonb_build_object('column',column_name,'type',data_type)) FROM information_schema.columns WHERE table_schema='estudo' AND table_name='auditoria_comercial'),'constraints',(SELECT jsonb_agg(pg_get_constraintdef(oid)) FROM pg_constraint WHERE conrelid='estudo.auditoria_comercial'::regclass),'checklist_rows',(SELECT count(*) FROM estudo.auditoria_comercial WHERE entidade='launch_checklist'))::text AS payload"
 r=remote("print(json.dumps(bridge(ROOT,raw_query(payload['sql'])+'report=deserializeJSON(q.payload[1]);')))",{'sql':sql});(W/'db-before.json').write_text(json.dumps(r,indent=2));print(r)
