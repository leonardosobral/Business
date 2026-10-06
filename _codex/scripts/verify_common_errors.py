from pathlib import Path
import json,subprocess,shlex,sys
ROOT=Path(__file__).resolve().parents[2]
source=(ROOT/'_codex/scripts/deploy_error_triage.py').read_text().split("if __name__=='__main__':")[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
source+=r'''
root=Path('/var/www/business.roadrunners.run')
start=bridge(root,'q=queryExecute("SELECT max(id_log) AS id FROM tb_log",{},{datasource="runner_dba"});report={id=q.id[1]};')['ID']
checks=[]
for origin in [True,False]:
 for path,want in [('/org/',404),('/org/?tag=',404),('/org/__codex_missing_supplier_20261004__/',404),('/org/yescom/',200)]:
  cmd=['curl','-sS','--max-time','30','-w','\n%{http_code}','https://roadrunners.run'+path]
  if origin:cmd[1:1]=['--resolve','roadrunners.run:443:127.0.0.1']
  p=subprocess.run(cmd,capture_output=True,text=True,check=True);body,status=p.stdout.rsplit('\n',1)
  assert int(status)==want,(origin,path,status)
  if want==404:assert 'Esse caminho' in body or '404' in body
  checks.append({'origin':origin,'path':path,'status':int(status)})
body='q=queryExecute("SELECT count(*) AS n FROM tb_log WHERE id_log>'+str(int(start))+' AND log_item=\'erro\' AND log_item_id LIKE \'%org%\'",{},{datasource="runner_dba",timeout=10});report={org_errors=q.n[1]};'
logs=bridge(root,body);assert logs['ORG_ERRORS']==0,logs
print(json.dumps({'passed':True,'checks':checks,'new_org_errors':logs['ORG_ERRORS']}))
'''
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(source)],capture_output=True,text=True,timeout=180)
print(p.stdout);print(p.stderr[-1500:]);(ROOT/'_codex/staging/common-errors-20261004/runtime-org.json').write_text(p.stdout);sys.exit(p.returncode)
