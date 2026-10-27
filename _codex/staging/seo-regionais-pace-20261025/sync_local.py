from pathlib import Path
import hashlib,json
S=Path(__file__).resolve().parent;R=S.parents[3]/'RoadRunners';b=json.loads((S/'baseline.json').read_text());v=json.loads((S/'candidate-verified.json').read_text())
def sha(f):return hashlib.sha256(f.read_bytes()).hexdigest() if f.exists() else None
for n in b['names']:
 assert sha(S/'candidate'/n)==v['hashes'][n],('Candidate drift',n)
 assert sha(R/n)==b['local'][n],('Local change since user update',n)
extra={
 '_codex/scripts/build_regionais_pace.mjs':(S/'build.mjs').read_text(),
 '_codex/tests/seo_regionais_pace.test.cjs':(S/'pace.test.cjs').read_text().replace("path.join(__dirname,'candidate')","path.resolve(__dirname,'../..')"),
 '_codex/tests/seo_regionais_pace.cfm':(S/'regional.test.cfm').read_text().replace('template="includes/','template="/includes/').replace('template="evento/','template="/evento/'),
 '_codex/docs/2026-10-25_regionais_pace.md':(S/'implementation.md').read_text()
}
for n in extra:assert not (R/n).exists(),('Existing local document',n)
for n in b['names']:
 f=R/n;f.parent.mkdir(parents=True,exist_ok=True);f.write_bytes((S/'candidate'/n).read_bytes())
for n,c in extra.items():
 f=R/n;f.parent.mkdir(parents=True,exist_ok=True);f.write_text(c)
print(json.dumps({'runtime_files_synchronized':len(b['names']),'docs_build_tests':len(extra),'repository':str(R)}))
