"""Publish only format equivalence, using the existing atomic backup/rollback transport."""
import ast
import datetime
import hashlib
import json
import pathlib
import shlex
import subprocess
import sys

ROOT=pathlib.Path(__file__).resolve().parents[2]
RELATIVE='services/EventDescriptionRewriteService.cfc'
BASELINE='f4432dcc124ae2cf13ab7b00f462665495fe6056b608683104d5bdc50413dc34'
content=(ROOT/RELATIVE).read_text()
tests=json.loads((ROOT/'_codex/deploy/event-rewrite-format-tests-20261021.json').read_text())
tested_hash=hashlib.sha256((ROOT/RELATIVE).read_bytes()).hexdigest()
age=datetime.datetime.now(datetime.timezone.utc)-datetime.datetime.fromisoformat(tests['checked_at'])
if not (tests.get('ok') and tests.get('guards_ok') and tests.get('database_ok')
        and tests.get('stage_removed') and tests.get('observed_formats') and tests.get('historical_regressions')
        and tests.get('native_checks',0)>=340 and len(tests.get('privacy_checks',[]))==5
        and all(check.get('ok') for check in tests['privacy_checks'])
        and tests.get('service_sha256')==tested_hash and 0<=age.total_seconds()<3600):
    raise SystemExit('Fresh, matching native test evidence is required before publication')

# Read only the already-reviewed transport constant; do not execute its older
# multi-file payload, baseline selectors, or hard-coded historical test receipt.
tree=ast.parse((ROOT/'_codex/scripts/deploy_event_rewrite_audit.py').read_text())
remote=next(ast.literal_eval(node.value) for node in tree.body if isinstance(node,ast.Assign)
    and any(isinstance(target,ast.Name) and target.id=='REMOTE' for target in node.targets))
remote=remote.replace('business-rewrite-audit-20261015-','business-rewrite-formats-20261021-')
payload={RELATIVE:{'baseline':BASELINE,'content':content}}
proc=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12',
    'rr-prod','python3 -c '+shlex.quote(remote)],input=json.dumps(payload).encode(),capture_output=True,timeout=80)
try:result=json.loads(proc.stdout)
except Exception:result={'ok':False,'error':'Publication transport failed; output suppressed'}
if proc.returncode==0 and result.get('ok'):
    result['tests']=tests
    (ROOT/'_codex/deploy/event-rewrite-formats-20261021.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(result,ensure_ascii=False))
if proc.returncode or not result.get('ok'):sys.exit(1)
