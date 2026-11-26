from pathlib import Path
import hashlib,json,shutil
W=Path(__file__).resolve().parent;STUDY=W.parent;BUSINESS=STUDY.parents[2];RR=BUSINESS.parent/'RoadRunners'
manifest={}
def add(key,source,want=None,before='local'):
 data=source.read_bytes();sha=hashlib.sha256(data).hexdigest()
 if want:assert sha==want,('Source drift',key)
 assert key not in manifest,('Duplicate',key)
 site,name=key.split('/',1);root=BUSINESS if site=='business' else RR;local=root/name
 local_sha=hashlib.sha256(local.read_bytes()).hexdigest() if local.is_file() else None
 if before!='local':assert local_sha==before,('Local drift',key,local_sha,before)
 dest=W/'candidate'/key;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(data)
 manifest[key]={'before_sha256':local_sha,'candidate_sha256':sha,'bytes':len(data)}
p=STUDY/'postload-consumers/candidates-42-352/final-only';m=json.loads((p/'manifest.json').read_text())
for k,v in m['runtime_files'].items():add(k,p/'candidate'/k,v['candidate_sha256'],v['before_sha256'])
p=STUDY/'postload-marathons';m=json.loads((p/'candidate-manifest.json').read_text())
for k,v in m['files'].items():add(k,p/'runtime'/k,v)
p=STUDY/'postload-media/candidate';m=json.loads((p/'qa/manifest.json').read_text())
for k,v in m['files'].items():add(k,p/k,v)
p=STUDY/'postload-internal-docs';m=json.loads((p/'candidate-manifest.json').read_text())
for v in m['artifacts']:add('business/'+v['destination'],p/v['candidate'],v['sha256'],v['baseline_sha256'])
p=STUDY/'postload-final-pages';m=json.loads((p/'manifest.json').read_text())
for k,v in m['files'].items():add(k,p/v['candidate'],v['candidate_sha256'],v['before_sha256'])
# This JSON is an offline fixture; the production shell uses dados.cfm only.
local_fixture=manifest.pop('portal/brasilquecorreprovas/2026/public-preview.json')
key='portal/brasilquecorreprovas/imprensa/maratonas/index.cfm'
production=(W/'production-capture'/key).read_bytes()
local=(RR/key.split('/',1)[1]).read_bytes()
assert local==production+b'\n','Unexpected production difference; review required'
manifest[key]['production_before_sha256']=hashlib.sha256(production).hexdigest()
manifest[key]['baseline_note']='Production differs only by absent trailing newline; byte content otherwise identical.'
validation=['atleta/index.cfm','atleta/parts/configuracoes.cfm','configuracoes/perfil/index.cfm','includes/estrutura/header.cfm','includes/backend/backend_profile_settings.cfm','api/profile/teams.cfm','teams/includes/start.cfm','.rsync-filter']
for n in validation:
 data=(RR/n).read_bytes()
 if n in ['api/profile/teams.cfm','teams/includes/start.cfm']:data=data[:data.lower().index(b'<cfabort/>')+len(b'<cfabort/>')]+b'\n'
 dest=W/'candidate/portal'/n;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(data)
(W/'manifest.json').write_text(json.dumps({'ids':{'publication':42,'main':351,'public':352,'annual_internal':353},'runtime_files':manifest,'validation_only':validation,'local_fixture':local_fixture,'database_mutation':False},ensure_ascii=False,indent=2))
print(json.dumps({'files':len(manifest),'sites':{s:sum(k.startswith(s+'/') for k in manifest) for s in ['business','portal']},'bytes':sum(x['bytes'] for x in manifest.values())}))
