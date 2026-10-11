"""Scoped read-only SQL through the repository's existing loopback-only bridge."""
from pathlib import Path
import base64, json, shlex, subprocess, sys

root = Path(__file__).resolve().parents[3]
sqlpath = Path(sys.argv[1])
sql = sqlpath.read_text().strip().rstrip(';')
assert sql.upper().startswith(('SELECT ', 'WITH '))
source = (root/'_codex/scripts/deploy_estudo.py').read_text()
bridge = source[source.index('def bridge('):source.index('\ndef raw_query(')]
encoded = base64.b64encode(sql.encode()).decode()
body = '''transaction {queryExecute("SET TRANSACTION READ ONLY",{}, {datasource="runner_dba"});queryExecute("SET LOCAL statement_timeout='40s'",{}, {datasource="runner_dba"});queryExecute("SET LOCAL lock_timeout='2s'",{}, {datasource="runner_dba"});q=queryExecute(toString(binaryDecode("ENCODED","base64")),{}, {datasource="runner_dba",timeout=45});report={rows=[]};for(r in q)arrayAppend(report.rows,r);}'''.replace('ENCODED',encoded)
remote = 'from pathlib import Path\nimport os,tempfile,subprocess,json,shutil\n'+bridge+'\nprint(json.dumps(bridge(Path("/var/www/business.roadrunners.run"),'+repr(body)+')))\n'
args=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)]
p = subprocess.run(args,capture_output=True,text=True,timeout=115)
if p.returncode: raise SystemExit(p.stderr[-3000:])
data=json.loads(p.stdout)
data=data.get("ROWS",data.get("rows"))
data=[{k.lower():v for k,v in row.items()} for row in data]
dest=sqlpath.with_suffix('.json')
dest.write_text(json.dumps(data,ensure_ascii=False,indent=2))
print(json.dumps({'rows':len(data),'saved':str(dest)}))
