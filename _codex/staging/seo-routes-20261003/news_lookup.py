exec(open('_codex/staging/seo-routes-20261003/probe.py').read().split('remote=helpers+')[0])
remote=helpers+'''
qsql="SELECT id,slug,title,published,editorial_status,published_at,updated_at,length(body_html) AS body_length FROM news.tb_content WHERE lower(slug) LIKE '%ranking-atualizado%' OR lower(title) LIKE '%ranking%atualizado%' ORDER BY id DESC LIMIT 30"
report=bridge(Path('/var/www/business.roadrunners.run'),raw_query(qsql)+'report={rows=[]};for(row in q){arrayAppend(report.rows,row);}')
print(json.dumps(report))
'''
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],capture_output=True,text=True,timeout=65)
if p.returncode:raise RuntimeError(p.stderr[-1500:])
r=json.loads(p.stdout);(STAGE/'news_lookup.json').write_text(json.dumps(r,indent=2,ensure_ascii=False));print(json.dumps(r,ensure_ascii=False))
