"""Read-only verification of the published scoped manifest; no secrets or DB writes."""
import json,pathlib,shlex,subprocess,sys
root=pathlib.Path(__file__).resolve().parents[2]
expected=json.loads((root/'_codex/deploy/geocoding-20261017.json').read_text())['manifest']
incremental=root/'_codex/deploy/geocoding-fontes-20261017.json'
if incremental.exists():expected.update(json.loads(incremental.read_text())['manifest'])
acceleration=root/'_codex/deploy/geocoding-aceleracao-20261018.json'
if acceleration.exists():expected.update(json.loads(acceleration.read_text())['manifest'])
ai=root/'_codex/deploy/geocoding-ia-kit-20261019.json'
if ai.exists():
    if '--ai-kit' in sys.argv:expected=json.loads(ai.read_text())['manifest']
    else:expected.update(json.loads(ai.read_text())['manifest'])
astra=root/'_codex/deploy/geocoding-astra-20261019.json'
if astra.exists():expected.update(json.loads(astra.read_text())['manifest'])
enrichment=root/'_codex/deploy/geocoding-enrichment-20261019.json'
if enrichment.exists():expected.update(json.loads(enrichment.read_text())['manifest'])
quota=root/'_codex/deploy/geocoding-quota-3000-20261019.json'
if quota.exists():expected.update(json.loads(quota.read_text())['manifest'])
remote="""import hashlib,json,pathlib,sys
expected=json.load(sys.stdin);root=pathlib.Path('/var/www/business.roadrunners.run');checks=[]
for rel,item in expected.items():
 target=root/rel
 checks.append({'path':rel,'ok':target.is_file() and hashlib.sha256(target.read_bytes()).hexdigest()==item['after']})
print(json.dumps({'ok':all(x['ok'] for x in checks),'checks':checks}))
"""
run=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(remote)],input=json.dumps(expected).encode(),capture_output=True,timeout=25)
result=json.loads(run.stdout);print(json.dumps(result));sys.exit(0 if run.returncode==0 and result['ok'] else 1)
