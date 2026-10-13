from pathlib import Path
import subprocess,hashlib,json,re,html,concurrent.futures
P=Path(__file__).parent
jobs=[('morro-contato','https://morro-mt.com.br/contato'),('morro-abraceo','https://abraceo.com.br/filiado/morro-mt/'),('pace-regulamento','https://storagefileta.blob.core.windows.net/ticketagora/arquivos/evento/88251/c9797e464fed4d4a830c43d23a714fde639236039846466297.pdf'),('pace-site','https://www.paceeventos.com.br/')]
def one(job):
 name,url=job;p=P/(name+('.pdf' if url.endswith('.pdf') else '.html'))
 r=subprocess.run(['curl','-fLsS','--max-time','35','-o',str(p),url],capture_output=True,text=True,timeout=40)
 if r.returncode:return dict(source=url,error=r.stderr[:300])
 raw=p.read_bytes()
 if p.suffix=='.pdf':
  subprocess.run(['/opt/homebrew/bin/pdftotext','-layout',str(p),str(P/(name+'.txt'))],check=True);txt=(P/(name+'.txt')).read_text()
 else:txt=html.unescape(re.sub('<[^>]+>',' ',raw.decode('utf-8','replace')))
 emails=sorted(set(re.findall(r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}',txt.lower())))
 return dict(source=url,file=p.name,sha256=hashlib.sha256(raw).hexdigest(),emails=emails)
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as e:rows=list(e.map(one,jobs))
(P/'sources.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2));print(json.dumps(rows,ensure_ascii=False))
