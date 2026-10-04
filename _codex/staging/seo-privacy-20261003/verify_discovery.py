from pathlib import Path
import json,shlex,subprocess
STAGE=Path(__file__).resolve().parent
remote="\nimport json,urllib.request,urllib.parse,xml.etree.ElementTree as ET,concurrent.futures\nbase='https://openresults.run'\ndef get(url):\n with urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'RunnerHub-SEO-noindex/20261003','Cache-Control':'no-cache'}),timeout=30) as r:return r.status,ET.fromstring(r.read(20*1024*1024))\nstatus,index=get(base+'/sitemap.cfm');children=[e.text for e in index.iter() if e.tag.endswith('loc')]\nfor url in children:\n assert urllib.parse.urlsplit(url).hostname=='openresults.run' and urllib.parse.urlsplit(url).path.startswith('/sitemap'), 'Unexpected sitemap child'\ndef child(url):\n status,xml=get(url);urls=[e.text for e in xml.iter() if e.tag.endswith('loc')]\n private=[u for u in urls if urllib.parse.urlsplit(u).path.startswith(('/resultados','/perfil'))]\n return {'sitemap':url,'status':status,'urls':len(urls),'athlete_history_urls':len(private),'ok':status==200 and not private}\nwith concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:rows=list(pool.map(child,children))\nprint(json.dumps({'sitemaps':rows,'urls':sum(row['urls'] for row in rows),'ok':len(rows)>0 and all(row['ok'] for row in rows)}))\n"
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],capture_output=True,text=True,timeout=580)
if p.returncode:raise RuntimeError(p.stderr[-2200:])
r=json.loads(p.stdout);(STAGE/'sitemap-verification.json').write_text(json.dumps(r,indent=2,ensure_ascii=False))
print(json.dumps(r,ensure_ascii=False))
if not r['ok']:raise SystemExit(2)
