from pathlib import Path
import json,subprocess,shlex,sys
S=Path(__file__).resolve().parent;mode=sys.argv[1];assert mode in ('rehearse','publish','verify','rollback');b=json.loads((S/'membership-before.json').read_text());assert b['memberships']==[] and len(b['events'])==2
forward="DO $m$ BEGIN "
for e in b['events']:forward+=f"IF NOT EXISTS(SELECT 1 FROM tb_evento_corridas e WHERE id_evento={e['id_evento']} AND md5(to_jsonb(e)::text)='{e['row_hash']}') THEN RAISE EXCEPTION 'Event drift'; END IF;"
forward+="IF EXISTS(SELECT 1 FROM tb_agregadores_eventos WHERE id_evento IN (46521,46508)) THEN RAISE EXCEPTION 'Membership drift'; END IF; INSERT INTO tb_agregadores_eventos(agregador_tag,id_evento) VALUES ('estacoes',46521),('estacoes',46508); END $m$;"
snapshot="SELECT jsonb_build_object('events',(SELECT jsonb_agg(jsonb_build_object('id',id_evento,'hash',md5(to_jsonb(e)::text)) ORDER BY id_evento) FROM tb_evento_corridas e WHERE id_evento IN (46521,46508)),'memberships',(SELECT coalesce(jsonb_agg(to_jsonb(g) ORDER BY id_evento),'[]') FROM tb_agregadores_eventos g WHERE id_evento IN (46521,46508)))::text payload"
inverse="DELETE FROM tb_agregadores_eventos WHERE agregador_tag='estacoes' AND id_evento IN (46521,46508);"
helpers=Path('_codex/scripts/deploy_estudo.py').read_text().split('def legacy_sql(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
remote=helpers+'''
p=json.load(sys.stdin);stage=Path('/var/backups/seo-curadoria-estacoes-20261030')
def state():return bridge(ROOT,raw_query(p['snapshot'])+'report=deserializeJSON(q.payload[1]);')
if p['mode']=='rehearse':
 stage.mkdir(mode=0o700,exist_ok=False);before=state();(stage/'baseline.json').write_text(json.dumps(before));(stage/'input.json').write_text(json.dumps(p))
 result=bridge(ROOT,'transaction {'+raw_query(p['forward'],'fix')+raw_query(p['snapshot'])+'report=deserializeJSON(q.payload[1]);transaction action="rollback";}');assert state()==before
 restored=bridge(ROOT,'transaction {'+raw_query(p['forward'],'fix')+raw_query(p['inverse'],'restore')+raw_query(p['snapshot'])+'report=deserializeJSON(q.payload[1]);transaction action="rollback";}');assert restored==before and state()==before
 (stage/'expected.json').write_text(json.dumps(result));result={'rehearsed':True,'inverseVerified':True}
elif p['mode']=='publish':
 saved=json.loads((stage/'input.json').read_text());assert saved['forward']==p['forward'];assert state()==json.loads((stage/'baseline.json').read_text())
 result=bridge(ROOT,'transaction {'+raw_query(p['forward'],'fix')+raw_query(p['snapshot'])+'report=deserializeJSON(q.payload[1]);}');assert result==json.loads((stage/'expected.json').read_text());(stage/'published.json').write_text(json.dumps(result))
elif p['mode']=='rollback':
 assert state()==json.loads((stage/'published.json').read_text());result=bridge(ROOT,'transaction {'+raw_query(p['inverse'],'restore')+raw_query(p['snapshot'])+'report=deserializeJSON(q.payload[1]);}');assert result==json.loads((stage/'baseline.json').read_text())
else:
 result=state();assert result==json.loads((stage/'published.json').read_text())
print(json.dumps(result))
'''
r=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'mode':mode,'forward':forward,'snapshot':snapshot,'inverse':inverse}),capture_output=True,text=True,timeout=90);assert r.returncode==0,r.stderr[-2000:];result=json.loads(r.stdout);(S/('membership-'+mode+'.json')).write_text(json.dumps(result,indent=2));print(json.dumps(result))
