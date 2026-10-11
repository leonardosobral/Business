from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import hashlib, html, json, re, subprocess
P=Path(__file__).resolve().parent;events=json.loads((P/'date-divergences-before.json').read_text())['events']
jobs=[]
for e in events:
 for field,kind in [('url_hotsite','source'),('url_regulamento','regulation')]:
  url=e.get(field)
  if not url or not url.startswith('https://'):continue
  jobs.append((e['id_evento'],kind,url))
def run(job):
 eid,kind,url=job;target=P/f'{kind}-{eid}.bin'
 cp=subprocess.run(['curl','-sS','-L','--max-time','22','--max-redirs','5','-A','Mozilla/5.0','-o',str(target),'-w','%{http_code}\n%{url_effective}\n%{content_type}',url],capture_output=True,text=True,timeout=26)
 info=cp.stdout.split('\n');data=target.read_bytes() if target.exists() else b'';pdf=data.startswith(b'%PDF')
 if pdf:
  dest=target.with_suffix('.pdf');target.rename(dest);subprocess.run(['pdftotext','-layout',str(dest),str(target.with_suffix('.txt'))],capture_output=True,timeout=30)
 else:
  dest=target.with_suffix('.html');target.rename(dest) if target.exists() else None
  t=data.decode('utf-8',errors='replace');t=re.sub(r'<(?:script|style)\b[^>]*>.*?</(?:script|style)>','',t,flags=re.S|re.I)
  (target.with_suffix('.txt')).write_text(html.unescape(re.sub('<[^>]+>',' ',t)))
 return {'id':eid,'kind':kind,'requested_url':url,'status':info[0] if info else '', 'effective_url':info[1] if len(info)>1 else '', 'content_type':info[2] if len(info)>2 else '', 'pdf':pdf,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest(),'curl_exit':cp.returncode}
with ThreadPoolExecutor(max_workers=4) as pool:results=list(pool.map(run,jobs))
(P/'source-fetch.json').write_text(json.dumps(results,indent=2,ensure_ascii=False))
print(json.dumps({'events':len(events),'fetches':len(results),'http200':sum(x['status']=='200' for x in results),'pdf':sum(x['pdf'] for x in results),'source_missing':sum(not x.get('url_hotsite') for x in events),'errors':sum(x['curl_exit']!=0 for x in results)},ensure_ascii=False))
