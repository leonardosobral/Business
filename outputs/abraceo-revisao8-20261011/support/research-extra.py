from pathlib import Path
import subprocess,hashlib,json,re,html,concurrent.futures
P=Path(__file__).parent/'sources'
jobs=[('amigos-do-horto-eventos-abraceo', 'https://abraceo.com.br/filiado/amigos-do-horto-eventos/'), ('cronustec-abraceo', 'https://abraceo.com.br/filiado/cronustec/'), ('mmb-eventos-esportivos-abraceo', 'https://abraceo.com.br/filiado/mmb-eventos-esportivos/'), ('mp3-solucoes-abraceo', 'https://abraceo.com.br/filiado/mp3-solucoes/'), ('nk-sports-abraceo', 'https://abraceo.com.br/filiado/nk-sports/'), ('premium-abraceo', 'https://abraceo.com.br/filiado/premium/'), ('soulmais-abraceo', 'https://abraceo.com.br/filiado/soulmais/'), ('tm4-sports-business-abraceo', 'https://abraceo.com.br/filiado/tm4-sports-business/'), ('horto-ticket', 'https://www.ticketsports.com.br/e/corrida-kids-trimais-places-6-edicao-88357'), ('premium-future', 'https://meiamaratonadosreismagos.com.br/regulamento/'), ('assai-48766', 'https://storagefileta.blob.core.windows.net/ticketagora/arquivos/evento/88118/bcbeec1049b84b6da8588720d963c4e3639263470646879556.pdf'), ('assai-48783', 'https://storagefileta.blob.core.windows.net/ticketagora/arquivos/evento/88119/04eaf22feeda40e292e43b1ac881ea89639263469096967453.pdf')]
def one(job):
 name,url=job;p=P/(name+('.pdf' if url.endswith('.pdf') else '.html'))
 r=subprocess.run(['curl','-fLsS','--max-time','35','-o',str(p),url],capture_output=True,text=True,timeout=40)
 if r.returncode:return dict(source=url,error=r.stderr[:300])
 raw=p.read_bytes()
 if p.suffix=='.pdf':
  subprocess.run(['/opt/homebrew/bin/pdftotext','-layout',str(p),str(P/(name+'.txt'))],check=True);txt=(P/(name+'.txt')).read_text()
 else:
  txt=html.unescape(re.sub('<[^>]+>',' ',raw.decode('utf-8','replace')))
  (P/(name+'.txt')).write_text(txt)
 emails=sorted(set(re.findall(r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}',txt.lower())))
 return dict(source=url,file=p.name,sha256=hashlib.sha256(raw).hexdigest(),emails=emails)
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as e:rows=list(e.map(one,jobs))
(P/'sources-extra.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2));print(json.dumps(rows,ensure_ascii=False))
