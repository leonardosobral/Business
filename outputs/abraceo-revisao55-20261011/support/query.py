from pathlib import Path
import base64,json,os,shlex,shutil,subprocess,sys,tempfile
root=Path(__file__).resolve().parents[3]
helper=(root/'_codex/scripts/deploy_estudo.py').read_text();helper=helper[helper.index('def bridge('):helper.index('\ndef raw_query(')]
sql=Path(sys.argv[1]).read_text()
body='q=queryExecute(toString(binaryDecode("'+base64.b64encode(sql.encode()).decode()+'","base64")),{}, {datasource="runner_dba",timeout=40});report={data=deserializeJSON(q.payload[1])};'
script='from pathlib import Path\nimport os,tempfile,subprocess,json,shutil\n'+helper+'\nprint(json.dumps(bridge(Path("/var/www/business.roadrunners.run"),'+repr(body)+')))'
a=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(script)]
r=subprocess.run(a,capture_output=True,text=True,timeout=110)
if r.returncode:raise SystemExit(r.stderr[-2000:])
x=json.loads(r.stdout);data=x.get('DATA',x.get('data'));Path(sys.argv[2]).write_text(json.dumps(data,ensure_ascii=False,indent=2));print('Saved query result:',sys.argv[2])
