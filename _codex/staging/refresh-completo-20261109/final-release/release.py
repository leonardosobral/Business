from pathlib import Path
import base64,hashlib,importlib.util,json,subprocess,sys
W=Path(__file__).resolve().parent;STUDY=W.parent;BUSINESS=STUDY.parents[2];RR=BUSINESS.parent/'RoadRunners'
spec=importlib.util.spec_from_file_location('scoped_release',RR/'_codex/scripts/deploy_estudo_q3.py');release=importlib.util.module_from_spec(spec);spec.loader.exec_module(release)
m=json.loads((W/'manifest.json').read_text());STAGE='/var/backups/study-refresh-q3-20261109-final'
body=release.REMOTE_RELEASE.replace('/opt/ColdFusion/cfusion/bin/cfcompile.sh','/opt/coldfusion2025/cfusion/bin/cfcompile.sh').replace("'-cfruntimeuser','nobody'","'-cfruntimeuser','coldfusion'")
body=body.replace("if not (stage/'migration.json').exists():raise RuntimeError('Migration first')","if not (stage/'cutover-verified.json').exists():raise RuntimeError('DataGrip cutover not verified')")
def files():
 result={'business':{},'portal':{}}
 for k,v in m['runtime_files'].items():
  site,name=k.split('/',1);data=(W/'candidate'/k).read_bytes();assert hashlib.sha256(data).hexdigest()==v['candidate_sha256'];result[site][name]=base64.b64encode(data).decode()
 return result
def hold():
 for root in [RR,W/'candidate/portal']:subprocess.run(['node',str(RR/'_codex/scripts/check_rr_teams_release_hold.mjs'),'--root',str(root)],check=True)
def cutover_proof():
 # Read only: no attempt to run CREATE/ALTER through ColdFusion.
 proof=release.query("""SELECT jsonb_build_object('destination',EXISTS(SELECT 1 FROM estudo.web_destinos WHERE ano=2026 AND publicacao_id=42 AND versao=23),'historical',EXISTS(SELECT 1 FROM estudo.web_destinos WHERE ano=2025 AND publicacao_id=37 AND versao=19),'product',EXISTS(SELECT 1 FROM estudo.produtos WHERE id=1 AND publicacao_id=42 AND status='ACTIVE'),'public_view',EXISTS(SELECT 1 FROM estudo.lancamento_publico WHERE encode(sha256(convert_to(payload::text,'UTF8')),'hex')='584fee688f5826365ed33534eb7da4b6256c9037ef937bdd4b6ed8fab2180dd8'),'annual_draft',EXISTS(SELECT 1 FROM estudo.produtos WHERE id=2 AND status='DRAFT' AND publicacao_id IS NULL))::text AS payload""")
 assert all(proof.values()),proof
 return proof
mode=sys.argv[1]
if mode=='baseline':
 result=release.remote(body,{'mode':mode,'stage':STAGE,'files':files()})
 (W/'baseline-raw.json').write_text(json.dumps(result,indent=2))
 for k,v in m['runtime_files'].items():
  site,name=k.split('/',1);assert result[site][name]==v.get('production_before_sha256',v['before_sha256']),('Production conflict',k)
elif mode=='prepare':
 hold();result=release.remote(body,{'mode':mode,'stage':STAGE,'files':files(),'before':json.loads((W/'baseline-receipt.json').read_text())})
elif mode=='cutover-proof':
 result=cutover_proof();release.remote("p=Path(payload['stage']);(p/'cutover-verified.json').write_text(json.dumps(payload['proof']));print(json.dumps({'verified':True}))",{'stage':STAGE,'proof':result})
elif mode=='publish':
 site=sys.argv[2];assert site in ['business','portal'];cutover_proof()
 if site=='portal':hold()
 result=release.remote(body,{'mode':mode,'stage':STAGE,'site':site})
elif mode=='verify':result=release.remote(body,{'mode':mode,'stage':STAGE})
elif mode=='sync':
 result={}
 for k,v in m['runtime_files'].items():
  site,name=k.split('/',1);root=BUSINESS if site=='business' else RR;local=root/name;sha=hashlib.sha256(local.read_bytes()).hexdigest() if local.is_file() else None;assert sha in [v['before_sha256'],v['candidate_sha256']],('Local conflict',k)
 for k in m['runtime_files']:
  site,name=k.split('/',1);root=BUSINESS if site=='business' else RR;p=root/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes((W/'candidate'/k).read_bytes());result[site]=result.get(site,0)+1
 fixture=RR/'brasilquecorreprovas/2026/public-preview.json';f=m['local_fixture'];assert hashlib.sha256(fixture.read_bytes()).hexdigest() in [f['before_sha256'],f['candidate_sha256']];fixture.write_bytes((W/'candidate/portal/brasilquecorreprovas/2026/public-preview.json').read_bytes());result['local_only_fixture']=1
else:raise SystemExit(mode)
(W/(mode+('-'+sys.argv[2] if mode=='publish' else '')+'-receipt.json')).write_text(json.dumps(result,ensure_ascii=False,indent=2))
print(json.dumps(result,ensure_ascii=False))
