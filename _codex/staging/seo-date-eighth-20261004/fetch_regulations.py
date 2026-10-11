from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import json,subprocess,hashlib
p=Path(__file__).resolve().parent;d=json.loads((p/'baseline-data.json').read_text())
def run(e):
 out=p/f"regulation-{e['id_evento']}.pdf";url=e['url_regulamento'];c=subprocess.run(['curl','-sS','-L','--max-time','30','-o',str(out),'-w','%{http_code}',url],capture_output=True,text=True)
 pdf=out.exists() and out.read_bytes().startswith(b'%PDF')
 if pdf:
  subprocess.run(['pdftotext','-layout',str(out),str(out.with_suffix('.txt'))],check=True)
  subprocess.run(['pdftoppm','-f','1','-l','1','-scale-to','1600','-png','-singlefile',str(out),str(out.with_suffix(''))],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
 return dict(id=e['id_evento'],url=url,http=c.stdout,pdf=pdf,sha256=hashlib.sha256(out.read_bytes()).hexdigest() if out.exists() else '')
with ThreadPoolExecutor(max_workers=3) as pool:r=list(pool.map(run,[e for e in d['events'] if e['id_evento'] in [40176,39867,40891,43392,45308,47482]]))
(p/'regulation-fetch.json').write_text(json.dumps(r,indent=2));print(json.dumps(r))
