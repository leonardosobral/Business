from pathlib import Path
import json,subprocess,shlex,sys
p=Path(__file__).resolve().parent;root=p.parents[2];mode=sys.argv[1];start=0 if mode=='before' else json.loads((p/'history-before.json').read_text())['last_id']
helpers=(root/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
sql="SELECT jsonb_build_object('last_id',coalesce(max(id_historico),0),'rows',coalesce(jsonb_agg(jsonb_build_object('id',id_historico,'event',id_evento,'entity',entidade,'row',id_entidade,'operation',operacao,'changes',alteracoes) ORDER BY id_historico) FILTER (WHERE id_historico>"+str(start)+"),'[]'::jsonb))::text payload FROM public.tb_evento_fatos_historico WHERE id_evento IN (42850,44229,45646,48246)"
remote=helpers+'\np=json.load(sys.stdin)\nprint(json.dumps(bridge(ROOT,raw_query(p["sql"])+"report=deserializeJSON(q.payload);")))'
c=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(dict(sql=sql)),text=True,capture_output=True,timeout=40)
if c.returncode:raise RuntimeError(c.stderr[-1800:])
r=json.loads(c.stdout);(p/('history-'+mode+'.json')).write_text(json.dumps(r,ensure_ascii=False,indent=2));print(json.dumps(r if mode=='after' else {'last_id':r['last_id'],'existing_rows':len(r['rows'])}))
if mode=='after':
 assert len(r['rows'])==6,r
 assert sum(x['entity']=='percurso' for x in r['rows'])==6
 assert all(set(x['changes'])==({'data_percurso'} if x['entity']=='percurso' else {'url_regulamento'}) for x in r['rows'])
