exec(open('_codex/staging/seo-routes-20261003/probe.py').read().split('remote=helpers+')[0])
remote=helpers+'''
files={}
f=Path('/var/www/roadrunners.com.br/evento/.htaccess');files['RoadRunners/evento/.htaccess']=base64.b64encode(f.read_bytes()).decode()
sql="SELECT table_schema,table_name FROM information_schema.tables WHERE table_schema NOT IN ('pg_catalog','information_schema') AND (table_name ILIKE '%news%' OR table_name ILIKE '%noticia%' OR table_name ILIKE '%content%' OR table_name ILIKE '%post%' OR table_name ILIKE '%artigo%') ORDER BY table_schema,table_name"
db=bridge(Path('/var/www/business.roadrunners.run'),raw_query(sql)+'report={rows=[]};for(row in q){arrayAppend(report.rows,row);}')
print(json.dumps({'files':files,'db':db}))
'''
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],capture_output=True,text=True,timeout=65)
if p.returncode:raise RuntimeError(p.stderr[-1500:])
r=json.loads(p.stdout)
for name,b64 in r.pop('files').items():
 f=STAGE/'baseline'/name;f.parent.mkdir(parents=True,exist_ok=True);f.write_bytes(base64.b64decode(b64))
(STAGE/'news_diagnostic.json').write_text(json.dumps(r,indent=2))
print(json.dumps(r))
