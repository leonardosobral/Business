from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import json,re,subprocess,sys,html
s=Path(__file__).resolve().parent;mode=sys.argv[1];assert mode in ['before','after']
receipts=json.loads((s.parent/'seo-event-history-20261004/source-receipts.json').read_text())['reviews'];events=json.loads((s.parent/'seo-date-priority-20261004/baseline-data.json').read_text())['events']+json.loads((s.parent/'seo-date-next-20261004/baseline-data.json').read_text())['events'];events=[x for x in events if str(x['id_evento']) in receipts]
cases=[{'id':e['id_evento'],'url':'https://roadrunners.run/'+prefix+'/'+e['tag']+'/','lang':lang} for e in events for prefix,lang in [('evento','pt-br'),('en/event','en'),('es/evento','es')]]
cases += [{'id':0,'url':'https://roadrunners.run/'+prefix+'/2025-maratona-internacional-de-floripa/','lang':lang} for prefix,lang in [('evento','pt-br'),('en/event','en'),('es/evento','es')]]
def metadata(h):
 return {'canonical':re.findall(r'<link[^>]*rel="canonical"[^>]*>',h),'alternates':re.findall(r'<link[^>]*hreflang[^>]*>',h),'jsonld':[json.loads(x) for x in re.findall(r'<script[^>]*type="application/ld\+json"[^>]*>(.*?)</script>',h,re.I|re.S)]}
def run(pair):
 i,c=pair;dest=s/f'public-{mode}-{i}.html';cp=subprocess.run(['curl','-sS','--max-time','35','-o',str(dest),'-w','%{http_code}',c['url']],capture_output=True,text=True);h=dest.read_text() if dest.exists() else '';checks={'http200':cp.stdout=='200'}
 if mode=='before':
  if c['id']:
   e=next(x for x in metadata(h)['jsonld'] if x.get('@type')=='SportsEvent');r=receipts[str(c['id'])];checks['receipt_matches_dates']=e['startDate']==r['startDate'] and e['endDate']==r['endDate']
 else:
  checks['metadata_unchanged']=metadata(h)==metadata((s/f'public-before-{i}.html').read_text())
  count=h.count('data-event-source="date-review"');checks['scoped_visibility']=count==(1 if c['id'] else 0);checks['history_visibility']=h.count('data-event-source="correction-history"')==(1 if c['id'] else 0)
  if c['id']:
   r=receipts[str(c['id'])];checks['source_visible']=r['sourceUrl'] in html.unescape(h);checks['checked_at_visible']='datetime="2026-10-04"' in h;checks['history_collapsed']=re.search(r'data-event-source="correction-history"[^>]*>\s*<details>',h) is not None;checks['history_scope']={'pt-br':'adiamento da prova','en':'race was postponed','es':'carrera fue aplazada'}[c['lang']] in html.unescape(h);checks['localized_scope']={'pt-br':'não foram verificados','en':'were not verified','es':'no se verificaron'}[c['lang']] in html.unescape(h)
 return {**c,'http':cp.stdout,'checks':checks}
with ThreadPoolExecutor(max_workers=3) as pool:rows=list(pool.map(run,enumerate(cases)))
(s/f'public-{mode}.json').write_text(json.dumps(rows,indent=2,ensure_ascii=False));fails=[x for x in rows if not all(x['checks'].values())];print(json.dumps({'urls':len(rows),'failed':fails}));assert not fails
