import concurrent.futures, html, json, re, subprocess
from pathlib import Path
from urllib.parse import urlparse

ROOT=Path(__file__).resolve().parent.parent
def fetch(url):
    p=subprocess.run(['curl','-L','--max-time','25','--retry','1','-sS',url],capture_output=True)
    if p.returncode: raise RuntimeError(p.stderr.decode()[:100])
    return p.stdout
def plain(s):
    s=re.sub(r'<(script|style)\b[^>]*>.*?</\1>','',s,flags=re.S|re.I)
    return re.sub(r'\s+',' ',html.unescape(re.sub('<[^>]+>',' ',s))).strip()
def links(s):
    return sorted(set(re.findall(r'https://abraceo.com.br/filiado/(?!page/)[a-z0-9-]+/',s)))
def collect():
    index=Path('/tmp/abraceo-filiados.html').read_text()
    (ROOT/'research/index.html').write_text(index)
    urls=set(links(index))
    pages=sorted(set(re.findall(r'https://abraceo.com.br/filiado/page/\d+/',index)))
    for u in pages:
        try:
            h=fetch(u).decode(); urls.update(links(h))
            (ROOT/'research'/('page-'+u.rstrip('/').split('/')[-1]+'.html')).write_text(h)
        except Exception as e: print('PAGE ERROR',u,str(e))
    def one(u):
        slug=u.rstrip('/').split('/')[-1]
        try:
            h=fetch(u).decode(); (ROOT/'research'/f'{slug}.html').write_text(h)
            core=h[h.index('<h1'):]; core=core[:core.index('Associados ABRACEO')]
            name=plain(re.search(r'<h1[^>]*>(.*?)</h1>',core,re.S)[1])
            vals=[plain(x) for x in re.findall(r'<span class="elementor-icon-list-text">(.*?)</span>',core,re.S)]
            sites=re.findall(r'<a[^>]*href="([^"]+)"[^>]*>\s*<span class="elementor-button-content-wrapper"',core)
            logo=re.search(r'<img[^>]*data-src="([^"]+)"',core)
            r={'id':slug,'nome':name,'fonte_abraceo':u,'campos_abraceo':vals,'site':html.unescape(sites[0]) if sites else '', 'logo_url':logo[1] if logo else ''}
            if logo:
                try:
                    ext=Path(urlparse(logo[1]).path).suffix.lower()
                    dest=ROOT/'logotipos'/f'{slug}{ext}'
                    dest.write_bytes(fetch(logo[1])); r['logo_arquivo']=str(dest.relative_to(ROOT))
                except Exception as e: r['logo_erro']=str(e)
            return r
        except Exception as e: return {'id':slug,'fonte_abraceo':u,'erro':str(e)}
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool: rows=list(pool.map(one,sorted(urls)))
    (ROOT/'research/filiados.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2))
    print('TOTAL',len(rows),'ERROS',sum('erro' in r for r in rows))
    for r in rows: print(r.get('nome',r['id']),r.get('campos_abraceo',r.get('erro')),r.get('site'))
if __name__=='__main__': collect()
