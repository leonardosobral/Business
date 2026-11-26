"""GET-only reconciliation. Secrets stay on the server; customer data stays in memory."""
from pathlib import Path
import importlib.util,json,os,shlex,subprocess,sys

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'_codex/analyses/verified-challenges-20261124'
spec=importlib.util.spec_from_file_location('op',ROOT.parent/'RoadRunners/_codex/scripts/verified_dev_operator.py')
op=importlib.util.module_from_spec(spec);spec.loader.exec_module(op)
rows=json.loads((OUT/'audit.json').read_text())['registrations']
ids=sorted({r['profile_id'] for r in rows if r['desafio']=='todosantodia' and r['produto'] in ('todosantodiavip','todosantodiaupg') and r['status']=='C'})
if '--three' in sys.argv:ids=[53854,15644,17923]
previous=None
if '--retry' in sys.argv:
 previous=json.loads((OUT/'vip-api-all.json').read_text())
 ids=sorted({r['profile_id'] for r in previous['results'] if r['errors']})
sql="""SELECT DISTINCT pu.id_pagina AS profile_id,u.id AS user_id,trim(u.email) AS email,
 coalesce((SELECT json_agg(DISTINCT trim(d.num_pedido)) FROM public.desafios d
 WHERE d.id_usuario=u.id AND trim(coalesce(d.num_pedido,''))<>''),'[]')::text AS refs,
 coalesce((SELECT json_agg(DISTINCT t.json_transacao->'data'->>'id') FROM public.tb_transacoes t
 WHERE t.id_usuario=u.id AND t.origem_transacao='pagarme'
 AND (t.json_transacao->'data'->>'id') ~ '^or_[A-Za-z0-9]+$'),'[]')::text AS order_ids
 FROM public.tb_paginas_usuarios pu JOIN public.tb_usuarios u ON u.id=pu.id_usuario
 WHERE pu.id_pagina IN ("""+','.join(map(str,ids))+') AND u.id>0'
body='report={};transaction {queryExecute("SET TRANSACTION READ ONLY",{},{datasource="runner_dba"});report.identities=queryExecute("'+sql.replace('"','""')+'",{},{datasource="runner_dba",returntype="array"});transaction action="rollback";}'
identities={k.lower():v for k,v in op.run(body).items()}['identities']

REMOTE=r'''
from pathlib import Path
from urllib.parse import urlencode,quote
import base64,datetime,http.client,json,re,socket,ssl,sys
identities=json.load(sys.stdin)
source=Path('/var/www/dev.roadrunners.run/config/verified.local.cfm').read_text()
match=re.search(r'secretKey\s*=\s*"([^"]+)"',source,re.I)
if not match:raise RuntimeError('Dedicated provider credential missing')
key=match.group(1)
if not key.startswith('sk_') or key.startswith('sk_test_'):raise RuntimeError('Expected live read-only audit')
auth='Basic '+base64.b64encode((key+':').encode()).decode()
class IPv4HTTPS(http.client.HTTPSConnection):
 def connect(self):
  addr=socket.getaddrinfo(self.host,self.port,socket.AF_INET,socket.SOCK_STREAM)[0][4]
  raw=socket.create_connection(addr,self.timeout)
  try:self.sock=self._context.wrap_socket(raw,server_hostname=self.host)
  except BaseException:raw.close();raise
def get(path):
 if not path.startswith(('/customers?','/orders?','/orders/or_')):raise RuntimeError('Endpoint outside read-only scope')
 conn=IPv4HTTPS('api.pagar.me',timeout=20,context=ssl.create_default_context())
 try:
  conn.request('GET','/core/v5'+path,headers={'Authorization':auth,'Accept':'application/json'})
  response=conn.getresponse();raw=response.read(4_000_000)
  if response.status!=200:raise RuntimeError('provider_http_'+str(response.status))
  return json.loads(raw)
 finally:conn.close()
def listing(path,params):
 result=[]
 for page in range(1,21):
  data=get(path+'?'+urlencode(dict(params,page=page,size=30)))
  rows=data.get('data')
  if not isinstance(rows,list):raise RuntimeError('unexpected_list_shape')
  result.extend(rows)
  if len(rows)<30 and not (data.get('paging') or {}).get('next'):return result
 raise RuntimeError('pagination_limit')
def sanitize(d,basis):
 items=d.get('items',[]);charges=d.get('charges',[])
 codes=[str(i.get('code','')) for i in items]
 refunded=any(c.get('status')=='canceled' or (c.get('last_transaction') or {}).get('status') in ('refunded','partial_refunded') or
  any(int(c.get(k) or 0)>0 for k in ('canceled_amount','refunded_amount')) or int((c.get('last_transaction') or {}).get('canceled_amount') or 0)>0 for c in charges)
 valid=d.get('currency')=='BRL' and isinstance(d.get('amount'),int) and d['amount']>0 and not d.get('is_test',False)
 paid=[c.get('paid_at') for c in charges if c.get('status')=='paid' and c.get('paid_at')]
 classification='confirmed' if valid and d.get('status')=='paid' and paid and not refunded else ('refunded_or_partial' if refunded else 'unconfirmed')
 return {'id':d.get('id'),'code':d.get('code'),'status':d.get('status'),'classification':classification,'amount':d.get('amount'),
  'currency':d.get('currency'),'products':codes,'descriptions':[str(i.get('description',''))[:160] for i in items],
  'paid_at':paid,'created_at':d.get('created_at'),'charge_statuses':[c.get('status') for c in charges],
  'transaction_statuses':[(c.get('last_transaction') or {}).get('status') for c in charges],'match_basis':sorted(basis)}
results=[]
for idx,identity in enumerate(identities):
 result={'profile_id':identity['profile_id'],'user_id':identity['user_id'],'customers':0,'orders':[],'errors':[]}
 orders={};customers={};email=(identity.get('email') or '').lower().strip()
 def add_order(d,basis):
  oid=d.get('id','')
  if not re.fullmatch('or_[A-Za-z0-9]+',oid):return
  if oid not in orders:orders[oid]=[d,set()]
  orders[oid][1].add(basis)
 try:
  if email:
   for c in listing('/customers',{'email':email}):
    if str(c.get('email','')).lower().strip()==email:customers[c['id']]='exact_account_email'
  refs=set(json.loads(identity['refs'])+json.loads(identity['order_ids']))
  for ref in refs:
   try:
    found=[get('/orders/'+ref)] if re.fullmatch('or_[A-Za-z0-9]+',ref) else listing('/orders',{'code':ref})
    for d in found:
     if ref not in (d.get('id'),d.get('code')):continue
     add_order(d,'registration_or_transaction_reference')
     c=d.get('customer') or {}
     if c.get('id'):customers.setdefault(c['id'],'customer_from_registration_order')
   except Exception as e:result['errors'].append(str(e) if isinstance(e,RuntimeError) else type(e).__name__)
  for cid,basis in customers.items():
   for d in listing('/orders',{'customer_id':cid}):
    if (d.get('customer') or {}).get('id')!=cid:raise RuntimeError('customer_filter_mismatch')
    add_order(d,basis)
  result['customers']=len(customers)
  result['orders_examined']=len(orders)
  for d,basis in orders.values():
   if any('todosantodia' in str(i.get('code','')).lower() or 'santo dia' in str(i.get('description','')).lower() for i in d.get('items',[])):
    result['orders'].append(sanitize(d,basis))
 except Exception as e:result['errors'].append(str(e) if isinstance(e,RuntimeError) else type(e).__name__)
 results.append(result)
 if (idx+1)%5==0:print(json.dumps({'progress':idx+1,'total':len(identities)}),flush=True)
print(json.dumps({'audited_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'method':'GET only; exact email and registered order references','results':results}),flush=True)
'''
proc=subprocess.Popen(op.SSH+['python3 -c '+shlex.quote(REMOTE)],stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
try:
 proc.stdin.write(json.dumps(identities));proc.stdin.close()
 for line in proc.stdout:
  result=json.loads(line)
  if 'results' not in result:print(json.dumps(result),flush=True);continue
  if previous:
   merged={r['profile_id']:r for r in previous['results']};merged.update({r['profile_id']:r for r in result['results']});result['results']=list(merged.values())
  path=OUT/('vip-api-three.json' if '--three' in sys.argv else 'vip-api-all.json')
  path.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n');os.chmod(path,0o600)
  print(json.dumps({'file':str(path),'profiles':len(result['results']),'with_tsd_orders':sum(bool(r['orders']) for r in result['results']),'errors':sum(bool(r['errors']) for r in result['results'])}),flush=True)
 if proc.wait(timeout=30):raise RuntimeError('Read-only remote audit failed: '+proc.stderr.read()[-200:])
finally:
 if proc.poll() is None:proc.terminate();proc.wait(timeout=30)
 proc.stdout.close();proc.stderr.close()
 assert proc.poll() is not None
