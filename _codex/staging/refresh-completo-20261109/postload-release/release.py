"""Publish only the eight compatible reader files; never changes database pins."""
from pathlib import Path
import base64
import hashlib
import importlib.util
import json
import subprocess
import sys

W=Path(__file__).resolve().parent
STUDY=W.parent
BUSINESS=STUDY.parents[2]
RR=BUSINESS.parent/'RoadRunners'
CANDIDATE=STUDY/'postload-consumers/candidates-42-352/compatible'
manifest=json.loads((CANDIDATE/'manifest.json').read_text())
STAGE='/var/backups/study-refresh-q3-20261109-compatible'
spec=importlib.util.spec_from_file_location('scoped_existing_release',RR/'_codex/scripts/deploy_estudo_q3.py')
release=importlib.util.module_from_spec(spec);spec.loader.exec_module(release)
body=release.REMOTE_RELEASE.replace('/opt/ColdFusion/cfusion/bin/cfcompile.sh','/opt/coldfusion2025/cfusion/bin/cfcompile.sh').replace("'-cfruntimeuser','nobody'","'-cfruntimeuser','coldfusion'")
# This phase has no database mutation. Its gate is the prepared/compiled package.
body=body.replace("if not (stage/'migration.json').exists():raise RuntimeError('Migration first')","if not (stage/'prepared-compatible.json').exists():raise RuntimeError('Compatible package not prepared')")

def files():
    result={'business':{},'portal':{}}
    for key,entry in manifest['runtime_files'].items():
        site,name=key.split('/',1)
        data=(CANDIDATE/'candidate'/key).read_bytes()
        assert hashlib.sha256(data).hexdigest()==entry['candidate_sha256']
        result[site][name]=base64.b64encode(data).decode()
    assert sum(map(len,result.values()))==8
    return result

def hold():
    for root in (RR,CANDIDATE/'candidate/portal'):
        subprocess.run(['node',str(RR/'_codex/scripts/check_rr_teams_release_hold.mjs'),'--root',str(root)],check=True)

mode=sys.argv[1]
if mode=='baseline':
    result=release.remote(body,{'mode':'baseline','stage':STAGE,'files':files()})
    for key,entry in manifest['runtime_files'].items():
        site,name=key.split('/',1)
        assert result[site][name]==entry['before_sha256'],'Production changed: '+key
        root=BUSINESS if site=='business' else RR
        assert hashlib.sha256((root/name).read_bytes()).hexdigest()==entry['before_sha256'],'Local changed: '+key
elif mode=='prepare':
    hold()
    before=json.loads((W/'baseline-receipt.json').read_text())
    result=release.remote(body,{'mode':'prepare','stage':STAGE,'files':files(),'before':before})
    release.remote("p=Path(payload['stage']);(p/'prepared-compatible.json').write_text(json.dumps(payload['proof']));print(json.dumps({'prepared':True}))",
                   {'stage':STAGE,'proof':{'database_changed':False,'mode':'compatible-only','approved_pairs':manifest['approved_pairs'],'file_count':8}})
elif mode=='publish':
    site=sys.argv[2];assert site in ('business','portal')
    if site=='portal':hold()
    result=release.remote(body,{'mode':'publish','stage':STAGE,'site':site})
elif mode=='verify':
    result=release.remote(body,{'mode':'verify','stage':STAGE})
elif mode=='sync':
    result={}
    for key,entry in manifest['runtime_files'].items():
        site,name=key.split('/',1);root=BUSINESS if site=='business' else RR
        current=hashlib.sha256((root/name).read_bytes()).hexdigest()
        assert current in (entry['before_sha256'],entry['candidate_sha256']),'Local concurrent change: '+key
    for key in manifest['runtime_files']:
        site,name=key.split('/',1);root=BUSINESS if site=='business' else RR
        (root/name).write_bytes((CANDIDATE/'candidate'/key).read_bytes())
        result[site]=result.get(site,0)+1
else:raise SystemExit(mode)
(W/(mode+('-'+sys.argv[2] if mode=='publish' else '')+'-receipt.json')).write_text(json.dumps(result,ensure_ascii=False,indent=2))
print(json.dumps(result,ensure_ascii=False))
