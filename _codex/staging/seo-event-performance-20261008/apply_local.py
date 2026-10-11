from pathlib import Path
import hashlib,json,sys
S=Path(__file__).resolve().parent;B=S.parents[2];R=B.parent/'RoadRunners';mode=sys.argv[1]
assert mode in ['business','rr']
root=B if mode=='business' else R
name='portal/includes/seo_queue_data.cfm' if mode=='business' else 'includes/backend/backend_evento.cfm'
old=(S/'baseline'/mode/name).read_bytes();new=(S/'candidate'/mode/name).read_bytes();target=root/name
assert target.read_bytes()==old or target.read_bytes()==new,'Local change needs review'
backup=S/'local-before'/mode/name;backup.parent.mkdir(parents=True,exist_ok=True)
if not backup.exists():backup.write_bytes(target.read_bytes())
assert (S/('panel-verify.json' if mode=='business' else 'release-verify.json')).exists()
target.write_bytes(new)
if mode=='rr':
    doc='_codex/docs/2026-10-08_seo_performance_eventos.md';dest=R/doc;data=(B/doc).read_bytes()
    assert not dest.exists() or dest.read_bytes()==data
    dest.write_bytes(data)
print(json.dumps({'mode':mode,'synced':[name],'sha256':hashlib.sha256(new).hexdigest()}))
