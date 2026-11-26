"""One approved DML transaction. Preview rolls back; repeat apply is a no-op."""
from pathlib import Path
import argparse,base64,hashlib,importlib.util,json,os,shlex,subprocess
ROOT=Path(__file__).resolve().parents[2];STAGE=ROOT/'_codex/staging/verified-vip-reconcile-20261124'
parser=argparse.ArgumentParser();parser.add_argument('--apply',action='store_true');parser.add_argument('--negative',choices=['owner','amount','stale']);args=parser.parse_args()
assert not(args.apply and args.negative)
spec=importlib.util.spec_from_file_location('op',ROOT.parent/'RoadRunners/_codex/scripts/verified_dev_operator.py')
op=importlib.util.module_from_spec(spec);spec.loader.exec_module(op)
data=json.loads((STAGE/'input.json').read_text());before=json.loads((STAGE/'before.json').read_text())
grants={json.loads(r['row'])['profile_id']:r['row'] for r in before['grants']}
for r in data['approved']:
 r['legacy_grant']=grants[r['profile_id']]
 r['audit_details_json']=json.dumps({'batch':data['batch'],'profile_id':r['profile_id'],'user_id':r['user_id'],'product':r['product'],
  'provider_order_id':r['id'],'amount_cents':r['amount'],'paid_at':r['paid_at'],'provider_verified_at':r['verified_at'],
  'legacy_grant_id':json.loads(r['legacy_grant'])['id'],'match_basis':'local_order_reference_and_exact_email','status':'conciliated'})
reasons={53015:'failed_only',53067:'basic_only',53296:'refunded_only',53742:'no_order_found'}
for r in data['review']:
 r.update(batch=data['batch'],status='pending',reason=reasons[r['profile_id']])
 r['audit_details_json']=json.dumps(r)
if args.negative=='owner':data['approved'][0]['user_id']=139
if args.negative=='amount':data['approved'][0]['amount']+=1
if args.negative=='stale':data['approved'][0]['verified_at']='2020-01-01T00:00:00Z'
source=(ROOT/'_codex/scripts/reconcile_verified_vip_20261124.cfscript').read_text()
payload=base64.b64encode(json.dumps(data).encode()).decode()
cohort=','.join(str(r['profile_id']) for r in data['approved'])
body=source.replace('__PAYLOAD__',payload).replace('__APPLY__','true' if args.apply else 'false').replace('__COHORT_HASH__',hashlib.sha256(cohort.encode()).hexdigest().upper())
fingerprint=hashlib.sha256((source+(STAGE/'input.json').read_text()+(STAGE/'before.json').read_text()).encode()).hexdigest()
if args.apply:
 proof=json.loads((STAGE/'preview.json').read_text())
 assert proof['fingerprint']==fingerprint and proof['result']['CONCILIATED']==42
 for case in ('owner','amount','stale'):assert json.loads((STAGE/('negative-'+case+'.json')).read_text())['rejected']
 remote="""from pathlib import Path
import json,os,sys
p=json.load(sys.stdin);root=Path('/var/backups/business-verified-vip-reconcile-20261124')
root.mkdir(mode=0o700,exist_ok=True)
if root.is_symlink():raise RuntimeError('Unexpected backup path')
for name,data in p.items():
 path=root/name
 if path.exists():
  if path.read_text()!=data:raise RuntimeError('Backup differs')
 else:
  fd=os.open(path,os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o600)
  with os.fdopen(fd,'w') as f:f.write(data)
print(json.dumps({'backup_ready':True,'path':str(root)}))
"""
 backup={name:(STAGE/name).read_text() for name in ['input.json','before.json','financial-before.json','preview.json','restore-permanents.sql']}
 backup['operation.cfscript']=source
 result=subprocess.run(op.SSH+['python3 -c '+shlex.quote(remote)],input=json.dumps(backup),capture_output=True,text=True,timeout=25)
 if result.returncode:raise RuntimeError(result.stderr[-500:])
 print(result.stdout.strip(),flush=True)
try:result=op.run(body)
except RuntimeError as e:
 if not args.negative:raise
 expected={'owner':'Ownership or registration changed','amount':'Provider no longer confirms','stale':'Provider evidence expired'}[args.negative]
 if expected not in str(e):raise
 result={'rejected':True,'case':args.negative}
 print(json.dumps(result));path=STAGE/('negative-'+args.negative+'.json');path.write_text(json.dumps(result,indent=2));raise SystemExit(0)
assert not args.negative,'Negative guard did not reject'
path=STAGE/('applied.json' if args.apply else 'preview.json')
path.write_text(json.dumps({'fingerprint':fingerprint,'result':result},indent=2));os.chmod(path,0o600)
print(json.dumps({k:v for k,v in result.items() if k.lower()!='terms'},ensure_ascii=False,indent=2))
