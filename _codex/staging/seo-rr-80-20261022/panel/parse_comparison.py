"""Parse only the visible Semrush comparison table, never network/session state."""
from pathlib import Path
import json,re,sys

def decode_value(s):
 s=s.rstrip(':').strip()
 return json.loads(s) if s.startswith('"') else s

def number(s):
 if s in ('—','–','-',''):return None
 assert re.fullmatch(r'\d+(?:[.,]\d{3})*',s),s
 return int(s.replace(',','').replace('.',''))

def parse(text):
 rows=[];r=None;indent=None
 for line in text.splitlines():
  line=re.sub(r"^(\s*)- '(row|cell) (.*)'(:?)$",r'\1- \2 \3\4',line)
  hit=re.match(r'^(\s*)- row (.+):$',line)
  if hit:
   if r:rows.append(r)
   indent=len(hit[1]);r={'title':decode_value(hit[2]),'cells':[],'heading':None,'issueId':None,'metricId':None};continue
  if not r:continue
  hit=re.match(r'^(\s*)- cell(?: (.*))?$',line)
  if hit and len(hit[1])==indent+2:r['cells'].append(decode_value(hit[2] or '""'));continue
  hit=re.search(r'- heading "([^"]+)" \[level=2\]',line)
  if hit:r['heading']=hit[1]
  hit=re.search(r'/review/issue/detail/(\d+)',line)
  if hit:r['issueId']=int(hit[1])
  hit=re.search(r'/review/history/id/(g\d+)',line)
  if hit:r['metricId']=hit[1]
 if r:rows.append(r)
 groups={'erros':'errors','advertências':'warnings','avisos':'notices'};group=None;out={'metrics':{},'errors':[],'warnings':[],'notices':[]}
 for r in rows:
  if r['heading'] and r['heading'].casefold() in groups:group=groups[r['heading'].casefold()]
  if len(r['cells'])!=5:continue
  if r['metricId']:
   out['metrics'][r['metricId']]={'previous':number(r['cells'][1]),'current':number(r['cells'][2]),'fixed':number(r['cells'][3]),'new':number(r['cells'][4])}
  if r['issueId']:
   assert group, r
   label=r['cells'][0].split(', abrir')[0].split(' Saiba mais')[0]
   entry={'issueId':r['issueId'],'label':label,'previous':number(r['cells'][1]),'current':number(r['cells'][2]),'fixed':number(r['cells'][3]),'new':number(r['cells'][4])}
   assert entry['current'] is not None and entry['previous'] is not None,r
   if entry['fixed'] is not None and entry['new'] is not None:assert entry['previous']-entry['fixed']+entry['new']==entry['current'],entry
   out[group].append(entry)
 assert out['metrics']['g1']['current']==out['metrics']['g1']['previous']==5000
 for group,key in [('errors','g4'),('warnings','g5'),('notices','g6')]:
  assert out[group],group
  assert len({x['issueId'] for x in out[group]})==len(out[group]),group
  for period in ['previous','current']:
   n=sum(x[period] for x in out[group]);assert n==out['metrics'][key][period],(group,period,n,out['metrics'][key][period])
 return out

if __name__=='__main__':
 p=Path(sys.argv[1]);r=parse(p.read_text());p.with_suffix('.parsed.json').write_text(json.dumps(r,ensure_ascii=False,indent=2));print(json.dumps({'metrics':r['metrics'],'groups':{k:len(r[k]) for k in ['errors','warnings','notices']}}))
