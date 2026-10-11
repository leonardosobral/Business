from collect import *
from urllib.parse import urljoin

def one(r):
    url=r.get('site','')
    if not url or any(x in url for x in ['instagram.com','facebook.com','msha.ke']): return {'id':r['id'],'paginas':[]}
    if url.startswith('http:'): url='https:'+url[5:]
    results=[]; queue=[url]; seen=set()
    for u in queue:
        if u in seen or len(seen)>=4: continue
        seen.add(u)
        try:
            h=fetch(u).decode('utf-8',errors='replace')
            if len(h)>3000000: continue
            t=plain(h)
            cn=list(dict.fromkeys(re.findall(r'\b\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}\b',t)))
            if not cn: cn=list(dict.fromkeys(re.findall(r'(?:CNPJ|cnpj)[\s: nºº.-]*(\d{14})\b',t)))
            contexts=[t[max(0,m.start()-160):m.end()+220] for m in re.finditer(r'cnpj|raz[aã]o social|endere[çc]o|organiza[çc][aã]o|cronometragem|produ[çc][aã]o de eventos',t,re.I)]
            results.append({'url':u,'cnpj':cn,'contextos':contexts[:25],'emails':list(dict.fromkeys(re.findall(r'[\w.+-]+@[\w.-]+\.[a-zA-Z]{2,}',t)))[:12]})
            (ROOT/'research'/f"site-{r['id']}-{len(results)}.txt").write_text(t)
            if len(seen)==1:
                for href,label in re.findall(r'<a\b[^>]*href=[\"\x27]([^\"\x27]+)[\"\x27][^>]*>(.*?)</a>',h,re.S|re.I):
                    nu=urljoin(u,html.unescape(href))
                    if urlparse(nu).netloc==urlparse(u).netloc and re.search('contato|sobre|quem.somos|privacidade|termos',href+' '+plain(label),re.I) and not re.search(r'\.(pdf|jpg|png|zip)$',nu,re.I): queue.append(nu)
        except Exception as e: results.append({'url':u,'erro':str(e)})
    return {'id':r['id'],'paginas':results}
rows=json.loads((ROOT/'research/filiados.json').read_text())
with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool: enriched=list(pool.map(one,rows))
(ROOT/'research/sites.json').write_text(json.dumps(enriched,ensure_ascii=False,indent=2))
for r in enriched:
    for p in r['paginas']:
        if p.get('cnpj'): print(r['id'],p['url'],p['cnpj'],p['contextos'])
print('TOTAL SITES',sum(bool(r['paginas']) for r in enriched))
