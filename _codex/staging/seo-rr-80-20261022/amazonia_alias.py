"""One recoverable alias; existing EventRedirectService owns routing/sitemap policy."""
from pathlib import Path
import hashlib, json, shlex, subprocess, sys

S = Path(__file__).resolve().parent
B = S.parents[2]
R = B.parent / 'RoadRunners'
SOURCE = '2027-corrida-das-cores-da-amazonia'
TARGET = '2026-corrida-das-cores-da-amazonia'
SNAPSHOT = """SELECT jsonb_build_object('events',
 (SELECT jsonb_agg(jsonb_build_object(
  'id',e.id_evento,'tag',e.tag,'redirect',e.tag_301,'active',e.ativo,
  'name',e.nome_evento,'start',e.data_inicial,'end',e.data_final,
  'city',e.cidade,'state',e.estado,'source',e.url_hotsite,'registration',e.url_inscricao,
  'hash',md5(to_jsonb(e)::text),
  'without_redirect_hash',md5((to_jsonb(e)-'tag_301')::text),
  'forward_hash',md5((to_jsonb(e)||jsonb_build_object('tag_301',CASE WHEN id_evento=46375
    THEN '2026-corrida-das-cores-da-amazonia' ELSE e.tag_301 END))::text)) ORDER BY e.id_evento)
  FROM public.tb_evento_corridas e WHERE e.id_evento IN (44162,46375)
   OR e.tag IN ('2026-corrida-das-cores-da-amazonia','2027-corrida-das-cores-da-amazonia')),
 'routes',(SELECT jsonb_agg(jsonb_build_object('event',p.id_evento,'hash',md5(to_jsonb(p)::text))
   ORDER BY p.id_evento,md5(to_jsonb(p)::text)) FROM public.tb_evento_corridas_percursos p
   WHERE p.id_evento IN (44162,46375)))::text payload"""
helpers = (B / '_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0]
helpers = helpers.replace('ROOT=Path(__file__).resolve().parents[2]', "ROOT=Path('/var/www/business.roadrunners.run')").replace('runner_dba','runnerhub')
helpers = helpers.replace("(work/'run.cfm').write_text", "(work/'services').mkdir();(work/'services/EventRedirectService.cfc').write_text(fixture_inputs['service'])\n  body=body.replace('ALIAS_SERVICE', '_codex.'+work.name+'.services.EventRedirectService')\n  (work/'run.cfm').write_text")
remote = helpers + r'''
p=json.load(sys.stdin)
fixture_inputs=p
stage=Path('/var/backups/seo-rr-80-20261022-amazonia-alias')
root=Path('/var/www/business.roadrunners.run')
runtime=Path('/var/www/roadrunners.com.br/services/EventRedirectService.cfc')
if hashlib.sha256(runtime.read_bytes()).hexdigest()!=p['service_sha']:raise RuntimeError('Runtime service drift')
def snapshot():
 return bridge(root,'transaction {'+raw_query("SET TRANSACTION READ ONLY; SET LOCAL statement_timeout='20s'",'limits')+raw_query(p['snapshot'])+'}report=deserializeJSON(q.payload[1]);')
def expected(b):
 import copy
 x=copy.deepcopy(b)
 for e in x['events']:
  if e['id']==46375:e['redirect']=p['target'];e['hash']=e['forward_hash']
 return x
def guard(x):
 # Snapshot is public fields plus hashes: compare inside transaction, not after commit.
 encoded=base64.b64encode(json.dumps(x,ensure_ascii=False,separators=(',',':')).encode()).decode()
 return raw_query(p['snapshot'],'currentState')+'if(serializeJSON(deserializeJSON(currentState.payload[1]))!=serializeJSON(deserializeJSON(toString(binaryDecode("'+encoded+'","base64")))))throw(message="Alias snapshot drift; rolling back");'
def update(sql):
 return raw_query(sql,'mutation')+'if(mutation.recordCount!=1)throw(message="Expected exactly one alias row; rolling back");'
def sqls(b,a):
 by={e['id']:e for e in b['events']};ay={e['id']:e for e in a['events']}
 target_guard=" AND EXISTS (SELECT 1 FROM tb_evento_corridas t WHERE t.id_evento=44162 AND md5(to_jsonb(t)::text)='"+by[44162]['hash']+"')"
 f="UPDATE tb_evento_corridas e SET tag_301='"+p['target']+"' WHERE e.id_evento=46375 AND e.tag='"+p['source']+"' AND tag_301 IS NULL AND md5(to_jsonb(e)::text)='"+by[46375]['hash']+"'"+target_guard+" RETURNING id_evento"
 r="UPDATE tb_evento_corridas e SET tag_301=NULL WHERE e.id_evento=46375 AND e.tag='"+p['source']+"' AND tag_301='"+p['target']+"' AND md5(to_jsonb(e)::text)='"+ay[46375]['hash']+"'"+target_guard+" RETURNING id_evento"
 return f,r
service_checks="""
 service=createObject("component","ALIAS_SERVICE");
 if(service.resolveTarget("SOURCE_TAG")!="TARGET_TAG" || service.resolveTarget("TARGET_TAG")!="")throw(message="Alias resolution failed");
 if(!service.isReadRequest("GET",{tag="SOURCE_TAG"}) || !service.isReadRequest("HEAD",{tag="SOURCE_TAG"})
  || service.isReadRequest("POST",{tag="SOURCE_TAG"}) || service.isReadRequest("GET",{tag="SOURCE_TAG",route_geometry="1"})
  || service.isReadRequest("GET",{tag="SOURCE_TAG",acao="save"}))throw(message="Read-only routing guard failed");
 """.replace('SOURCE_TAG',p['source']).replace('TARGET_TAG',p['target'])
policy_sql="SELECT jsonb_build_object('hidden_alias',(SELECT "+"POLICY"+" FROM tb_evento_corridas e WHERE id_evento=46375),'visible_original',(SELECT NOT (POLICY) FROM tb_evento_corridas e WHERE id_evento=44162))::text payload"
service_checks+='policySql=replace("'+policy_sql.replace('"','""')+'","POLICY",service.validTargetSql("e"),"all"); policy=queryExecute(policySql,{}, {timeout=10}); policyResult=deserializeJSON(policy.payload[1]); if(!policyResult.hidden_alias || !policyResult.visible_original)throw(message="Sitemap policy failed");'
mode=p['mode']
if mode=='prepare':
 b=snapshot();events=b['events']
 if len(events)!=2 or [e['id'] for e in events]!=[44162,46375]:raise RuntimeError('Ambiguous identifiers')
 a,brow=events
 if a['tag']!=p['target'] or brow['tag']!=p['source'] or any(e['redirect'] is not None or not e['active'] for e in events):raise RuntimeError('Unexpected alias baseline')
 for k in ['name','start','end','city','state','source','registration']:
  if a[k]!=brow[k]:raise RuntimeError('Identity mismatch: '+k)
 if a['start']!='2027-03-28' or a['end']!='2027-03-28' or a['city']!='Manaus' or a['state']!='AM' or '87544' not in a['source'] or '87544' not in a['registration']:raise RuntimeError('Official identity changed')
 stage.mkdir(mode=0o700,exist_ok=False)
 after=expected(b);f,r=sqls(b,after)
 for n,v in [('baseline.json',json.dumps(b,ensure_ascii=False,indent=2)),('expected.json',json.dumps(after,ensure_ascii=False,indent=2)),('forward.sql',f),('inverse.sql',r)]:
  (stage/n).write_text(v);os.chmod(stage/n,0o600)
 (stage/'evidence.json').write_text(json.dumps(p['evidence'],ensure_ascii=False,indent=2))
 out={'prepared':True,'baseline':b,'backup':str(stage)}
else:
 b=json.loads((stage/'baseline.json').read_text());a=json.loads((stage/'expected.json').read_text());f,r=sqls(b,a)
 if f!=(stage/'forward.sql').read_text() or r!=(stage/'inverse.sql').read_text():raise RuntimeError('Plan drift')
 locked=raw_query("SET LOCAL lock_timeout='3s'; SET LOCAL statement_timeout='20s'",'limits')+raw_query('SELECT id_evento FROM tb_evento_corridas WHERE id_evento IN (44162,46375) ORDER BY id_evento FOR UPDATE','locks')
 if mode=='rehearse':
  body='transaction {'+locked+guard(b)+update(f)+guard(a)+service_checks+update(r)+guard(b)+'transaction action="rollback";report={forward=true,inverse=true,only_redirect_changed=true,routing=true,sitemap=true};}'
  out=bridge(root,body)
  if snapshot()!=b:raise RuntimeError('Rehearsal did not restore baseline')
  (stage/'rehearsed.json').write_text(json.dumps(out))
 elif mode=='publish':
  if not (stage/'rehearsed.json').exists():raise RuntimeError('Rehearsal required')
  body='transaction {'+locked+guard(b)+update(f)+guard(a)+service_checks+'report={published=true,only_redirect_changed=true,routing=true,sitemap=true};}'
  out=bridge(root,body)
  if snapshot()!=a:raise RuntimeError('After commit snapshot differs; reconcile before any retry')
  (stage/'published.json').write_text(json.dumps(out))
 elif mode=='verify':
  if snapshot()!=a:raise RuntimeError('Published data drift')
  out=bridge(root,'transaction {'+raw_query('SET TRANSACTION READ ONLY','limits')+guard(a)+service_checks+'report={verified=true,routing=true,sitemap=true};}')
 elif mode=='rollback':
  out=bridge(root,'transaction {'+locked+guard(a)+update(r)+guard(b)+'report={restored=true};}')
 else:raise RuntimeError('Unknown mode')
print(json.dumps(out,ensure_ascii=False))
'''
service = (R/'services/EventRedirectService.cfc').read_text()
payload = dict(mode=sys.argv[1],source=SOURCE,target=TARGET,snapshot=SNAPSHOT,service=service,
 service_sha=hashlib.sha256(service.encode()).hexdigest(),evidence=json.loads((S/'amazonia-official-source.json').read_text()))
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps(payload),capture_output=True,text=True,timeout=120)
if cp.returncode:raise RuntimeError(cp.stderr[-4500:])
result=json.loads(cp.stdout)
(S/('amazonia-alias-'+sys.argv[1]+'.json')).write_text(json.dumps(result,ensure_ascii=False,indent=2))
print(json.dumps({k:v for k,v in result.items() if k!='baseline'},ensure_ascii=False))
