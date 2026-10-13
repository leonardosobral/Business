from pathlib import Path
import json,subprocess,shlex
P=Path(__file__).parent;ROOT=P.parents[2]
s=(ROOT/'_codex/scripts/deploy_estudo.py').read_text();helper=s[s.index('def bridge('):s.index('\ndef raw_query(')]
body='q=queryExecute("SELECT v.id,v.email_destinatario,v.status FROM estudo.vouchers v JOIN estudo.primeiro_acesso_convites x ON x.voucher_id=v.id WHERE x.id_conta BETWEEN 111 AND 117",{}, {datasource="runner_dba"});report={new_vouchers=q.recordCount,validation=[]};'
for x in json.loads((P/'contacts.json').read_text()):body+='arrayAppend(report.validation,{company='+str(x['id_conta'])+',valid=isValid("email","'+x['email']+'")});'
script='from pathlib import Path\nimport json,os,shutil,tempfile,subprocess\n'+helper+'\nprint(json.dumps(bridge(Path("/var/www/business.roadrunners.run"),'+repr(body)+')))'
r=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(script)],capture_output=True,text=True,timeout=60)
assert r.returncode==0,r.stderr;print(r.stdout);(P/'issuance-check.json').write_text(r.stdout)
