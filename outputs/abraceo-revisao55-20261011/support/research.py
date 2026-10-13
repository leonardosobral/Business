from pathlib import Path
import concurrent.futures,csv,hashlib,html,json,re,subprocess,unicodedata
BASE=Path(__file__).resolve().parents[2]/'abraceo-20261010'
OUT=Path(__file__).resolve().parent
def norm(s):return ''.join(c for c in unicodedata.normalize('NFD',s.lower()) if not unicodedata.combining(c))
members=list(csv.DictReader((BASE/'abraceo_filiados.csv').open(encoding='utf-8-sig'),delimiter=';'))
created={r['id_origem'] for r in json.loads((BASE/'importacao/resultado_business.json').read_text())['contas']}
members=[r for r in members if r['id_filiado'] not in created]
events=list(csv.DictReader((BASE/'abraceo_eventos_relacionados.csv').open(encoding='utf-8-sig'),delimiter=';'))
aliases=json.loads((BASE/'research/aliases-v3.json').read_text())
jobs=[]
for r in members:
 eid=r['id_filiado'];es=[e for e in events if e['id_filiado']==eid]
 future=[e for e in es if e['evento_ativo']=='SIM' and e['data_inicial']>'2026-10-11']
 selected=future or sorted([e for e in es if e['url_regulamento']],key=lambda e:e['data_inicial'],reverse=True)[:2]
 for e in selected:
  url=e['url_regulamento'] or e['url_inscricao']
  if url:jobs.append({'id':eid,'kind':'event','event':e,'url':url})
 site=r['site_revisado'] or r['site_abraceo']
 if site and not any(x in site for x in ['instagram.com','facebook.com','msha.ke']):jobs.append({'id':eid,'kind':'site','url':site})
def fetch(j):
 key=hashlib.sha256(j['url'].encode()).hexdigest()[:16];file=OUT/(key+'.download');textfile=OUT/(key+'.txt')
 if textfile.exists():text=textfile.read_text()
 else:
  try:
   p=subprocess.run(['curl','-fLsS','--max-time','25','-o',str(file),j['url']],capture_output=True,timeout=30)
   if p.returncode:return dict(j,error='HTTP indisponível')
   raw=file.read_bytes()
   if raw.startswith(b'%PDF'):
    p=subprocess.run(['/opt/homebrew/bin/pdftotext','-layout',str(file),str(textfile)],capture_output=True,timeout=25)
    if p.returncode:return dict(j,error='PDF sem texto extraível')
    text=textfile.read_text()
   else:
    source=raw.decode('utf-8','replace');source=re.sub(r'<(script|style)\b[^>]*>.*?</\1>','',source,flags=re.S|re.I)
    text=html.unescape(re.sub('<[^>]+>',' ',source));text=re.sub(r'\s+',' ',text);textfile.write_text(text)
  except Exception as e:return dict(j,error=type(e).__name__)
 n=norm(text);a=aliases.get(j['id'],[]);terms=a+[j['id'].replace('-',' ')]
 spans=[]
 for term in terms:
  for match in list(re.finditer(re.escape(norm(term)),n))[:8]:
   start=max(0,match.start()-180);end=min(len(text),match.end()+240)
   snippet=re.sub(r'\s+',' ',text[start:end])
   if snippet not in spans:spans.append(snippet)
 if not spans:
  for match in list(re.finditer(r'organiza[cç][aã]o|organizador|realiza[cç][aã]o|produ[cç][aã]o',n))[:5]:spans.append(re.sub(r'\s+',' ',text[max(0,match.start()-70):match.end()+200]))
 return dict(j,file=textfile.name,snippets=spans[:10],chars=len(text))
with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:result=list(pool.map(fetch,jobs))
(OUT/'research.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
(OUT/'members.json').write_text(json.dumps(members,ensure_ascii=False,indent=2))
print(json.dumps({'members':len(members),'sources':len(result),'retrieved':sum('file' in j for j in result),'failed':sum('error' in j for j in result)}))
