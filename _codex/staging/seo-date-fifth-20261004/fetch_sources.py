from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import json,subprocess,hashlib,re,html
p=Path(__file__).resolve().parent;d=json.loads((p/'baseline-data.json').read_text())
def run(e):
 url=e['url_hotsite'] or e['url_inscricao'];dest=p/('source-'+str(e['id_evento'])+'.html')
 c=subprocess.run(['curl','-sS','-L','--max-time','35','-A','Mozilla/5.0','-o',str(dest),'-w','%{http_code}',url],capture_output=True,text=True)
 text=dest.read_text(errors='replace');plain=html.unescape(re.sub('<[^>]+>',' ',text));(p/('source-'+str(e['id_evento'])+'.txt')).write_text(plain)
 return dict(id=e['id_evento'],url=url,http=c.stdout,sha256=hashlib.sha256(dest.read_bytes()).hexdigest(),bytes=dest.stat().st_size)
with ThreadPoolExecutor(max_workers=2) as pool:r=list(pool.map(run,d['events']))
(p/'source-fetch.json').write_text(json.dumps(r,indent=2));print(json.dumps(r));assert all(x['http']=='200' for x in r)
