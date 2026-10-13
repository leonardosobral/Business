from pathlib import Path
import subprocess,hashlib,json,re,html,concurrent.futures
P=Path(__file__).parent/'sources'
jobs=[
('horto-reg','https://cdn.ticketsports.com.br/ticketagora/arquivos/evento/72515/3cdfdafd8400487e875e6981692863ca638872333840376248.pdf'),
('horto-futuro','https://storagefileta.blob.core.windows.net/ticketagora/arquivos/evento/88357/6b98b02bbe274e6ebc5758cf7e788fd3639245634275113111.pdf'),
('cronustec','https://www.cronusteccorridas.com.br/nossos-servicos'),
('premium-reg','https://cdn.ticketsports.com.br/ticketagora/arquivos/evento/74528/2e71b03b701c4ccba37e9916ad4061e5639003551430006270.pdf'),
('premium-unimed','https://circuitounimed.com.br/regulamento/'),
('tm4','https://www.tm4.business/'),
('soul-assai','https://www.assai.com.br/imprensa/corrida-assai-em-fortaleza-dobra-de-tamanho-e-abre-novo-lote-de-inscricoes'),
('assai-site','https://www.corridaassai.com.br/'),
('mmb-ticket','https://www.ticketsports.com.br/e/maratona-monumental-de-brasilia-2026-74828'),
('mmb-reg','https://storagefileta.blob.core.windows.net/ticketagora/arquivos/evento/74828/4e91b6e5359b4b4389243a2939d996ff639199082801291559.pdf'),
('nk-ticket','https://www.ticketsports.com.br/e/2-corrida-santa-casa-araraquara-2026-85837'),
('mp3-site','https://mp3promocoes.com.br/')]

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
(P/'sources.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2));print(json.dumps(rows,ensure_ascii=False))
