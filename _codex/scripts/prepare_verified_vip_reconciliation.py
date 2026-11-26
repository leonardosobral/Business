"""Refresh the 42 approved orders by authenticated GET; export no customer/card data."""
from pathlib import Path
import importlib.util,json,os,shlex,subprocess
ROOT=Path(__file__).resolve().parents[2]
STAGE=ROOT/'_codex/staging/verified-vip-reconcile-20261124'
spec=importlib.util.spec_from_file_location('op',ROOT.parent/'RoadRunners/_codex/scripts/verified_dev_operator.py')
op=importlib.util.module_from_spec(spec);spec.loader.exec_module(op)
original=json.loads((ROOT/'_codex/analyses/verified-challenges-20261124/vip-api-all.json').read_text())
approved=[];review=[]
for row in original['results']:
 paid=[o for o in row['orders'] if o['classification']=='confirmed' and set(o['products'])&{'todosantodiavip','todosantodiaupg'}]
 if paid:
  assert len(paid)==1
  o=paid[0];assert set(o['match_basis'])>={'exact_account_email','registration_or_transaction_reference'}
  approved.append({'profile_id':row['profile_id'],'user_id':row['user_id'],'id':o['id'],'code':o['code'],
   'product':o['products'][0],'amount':o['amount'],'paid_at':o['paid_at'][0]})
 else:review.append({'profile_id':row['profile_id'],'user_id':row['user_id']})
assert len(approved)==42 and {r['profile_id'] for r in review}=={53015,53067,53296,53742}
REMOTE=r'''
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import base64,datetime,http.client,json,re,socket,ssl,sys
rows=json.load(sys.stdin)
source=Path('/var/www/dev.roadrunners.run/config/verified.local.cfm').read_text()
key=re.search(r'secretKey\s*=\s*"([^"]+)"',source,re.I).group(1)
if not key.startswith('sk_') or key.startswith('sk_test_'):raise RuntimeError('Expected live credential')
auth='Basic '+base64.b64encode((key+':').encode()).decode()
class IPv4HTTPS(http.client.HTTPSConnection):
 def connect(self):
  addr=socket.getaddrinfo(self.host,self.port,socket.AF_INET,socket.SOCK_STREAM)[0][4]
  raw=socket.create_connection(addr,self.timeout)
  try:self.sock=self._context.wrap_socket(raw,server_hostname=self.host)
  except BaseException:raw.close();raise
def refresh(row):
 conn=IPv4HTTPS('api.pagar.me',timeout=20,context=ssl.create_default_context())
 try:
  if not re.fullmatch('or_[A-Za-z0-9]+',row['id']):raise RuntimeError('Invalid order ID')
  conn.request('GET','/core/v5/orders/'+row['id'],headers={'Authorization':auth,'Accept':'application/json'})
  response=conn.getresponse();raw=response.read(2_000_000)
  if response.status!=200:raise RuntimeError('Provider HTTP '+str(response.status))
  d=json.loads(raw);items=d.get('items',[]);charges=d.get('charges',[])
  if not(d.get('id')==row['id'] and d.get('code')==row['code'] and d.get('amount')==row['amount'] and d.get('currency')=='BRL'
   and d.get('status')=='paid' and not d.get('is_test',False) and len(items)==1 and items[0].get('code')==row['product']
   and items[0].get('quantity')==1 and items[0].get('amount')==row['amount'] and len(charges)==1):raise RuntimeError('Order changed '+row['id'])
  c=charges[0];t=c.get('last_transaction') or {}
  if not(c.get('status')=='paid' and c.get('paid_amount')==row['amount'] and c.get('paid_at')==row['paid_at']
   and not int(c.get('canceled_amount') or 0) and not int(c.get('refunded_amount') or 0) and not int(t.get('canceled_amount') or 0)
   and t.get('status') not in ('refunded','partial_refunded','chargedback')):raise RuntimeError('Charge changed '+row['id'])
  row['provider_order']={k:d[k] for k in ('id','code','amount','currency','status','updated_at','created_at')}
  row['provider_order']['items']=[{k:items[0][k] for k in ('code','amount','quantity')}]
  row['provider_order']['charges']=[{k:c[k] for k in ('id','currency','amount','status','paid_amount','paid_at','updated_at','canceled_amount') if k in c}]
  row['verified_at']=datetime.datetime.now(datetime.timezone.utc).isoformat()
  return row
 finally:conn.close()
with ThreadPoolExecutor(max_workers=3) as pool:out=list(pool.map(refresh,rows))
print(json.dumps(out))
'''
r=subprocess.run(op.SSH+['python3 -c '+shlex.quote(REMOTE)],input=json.dumps(approved),capture_output=True,text=True,timeout=300)
if r.returncode:raise RuntimeError(r.stderr[-500:])
approved=json.loads(r.stdout);assert len(approved)==42
payload={'batch':'verified-vip-20261124','approved':sorted(approved,key=lambda r:r['profile_id']),'review':review}
path=STAGE/'input.json';path.write_text(json.dumps(payload,indent=2));os.chmod(path,0o600)
print(json.dumps({'refreshed_orders':len(approved),'review_excluded':len(review),'file':str(path)}))
