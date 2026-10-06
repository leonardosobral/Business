"""Preview/apply a fingerprint regroup plan using the tested production service."""
from pathlib import Path
import json,subprocess,shlex,sys
ROOT=Path(__file__).resolve().parents[2];STAGE=ROOT/'_codex/staging/error-grouping-20261004'
mode=sys.argv[1];assert mode in ('preview','apply','verify')
source=(ROOT/'_codex/scripts/deploy_error_triage.py').read_text().split("if __name__=='__main__':")[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
source=source.replace('this.datasource="runner_dba";','this.datasource="runner_dba";this.mappings["/portal"]="/var/www/business.roadrunners.run/portal";')
source+=r'''
payload=json.load(sys.stdin);root=Path('/var/www/business.roadrunners.run');stage=Path('/var/backups/business-error-grouping-20261004')
def operation(body):return bridge(root,'svc=new portal.erros.includes.ErrorTriage().init();'+body)
def brief(result):
 return {k:v for k,v in result.items() if k not in ['GROUPS','SKIPPED']} | {'groups':[{'target':g['TARGET'],'ids':[m['ID'] for m in g['MEMBERS']],'occurrences':g['OCCURRENCES'],'title':g['TITLE']} for g in result.get('GROUPS',[])],'skipped_count':len(result.get('SKIPPED',[]))}
if payload['mode']=='preview':
 result=operation('report=svc.regroupFingerprints(0);')
 (stage/'regroup-preview.json').write_text(json.dumps(result));os.chmod(stage/'regroup-preview.json',0o600)
 print(json.dumps(brief(result)))
elif payload['mode']=='apply':
 assert not (stage/'regroup-applied.json').exists(),'Already applied'
 plan=json.loads((stage/'regroup-preview.json').read_text())['PLAN'];assert len(plan)==64 and all(c in '0123456789abcdef' for c in plan)
 backup=stage/'triage-before-regroup.json';assert not backup.exists(),'Backup already exists; inspect before retrying'
 snapshot=bridge(root,"q=queryExecute(\"SELECT json_build_object('problems',(SELECT json_agg(p) FROM tb_error_problem p),'occurrences',(SELECT json_agg(o) FROM tb_error_occurrence o),'history',(SELECT json_agg(h) FROM tb_error_history h),'collector',(SELECT json_agg(c) FROM tb_error_collector c))::text AS snapshot\",{},{datasource=\"runner_dba\",timeout=30});report=deserializeJSON(q.snapshot[1]);")
 backup.write_text(json.dumps(snapshot));os.chmod(backup,0o600)
 result=operation('report=svc.regroupFingerprints(0,true,"'+plan+'");')
 (stage/'regroup-applied.json').write_text(json.dumps(result));print(json.dumps(brief(result)))
else:
 applied=json.loads((stage/'regroup-applied.json').read_text());ids=sorted(set(m['ID'] for g in applied['GROUPS'] for m in g['MEMBERS']));assert all(isinstance(i,(float,int)) for i in ids)
 id_list=','.join(str(int(i)) for i in ids)
 result=operation('report={problems=[],occurrences=[]};q=queryExecute("SELECT id,occurrences,status FROM tb_error_problem WHERE id IN ('+id_list+')",{},{datasource="runner_dba"});for(r in q)arrayAppend(report.problems,r);q=queryExecute("SELECT o.id_log,o.problem_id,l.id_log AS original_id FROM tb_error_occurrence o LEFT JOIN tb_log l ON l.id_log=o.id_log WHERE o.problem_id IN ('+id_list+')",{},{datasource="runner_dba"});for(r in q)arrayAppend(report.occurrences,r);report.default_total=svc.list({}).total;report.remaining_groups=arrayLen(svc.regroupFingerprints(0).groups);')
 byid={p['ID']:p for p in result['PROBLEMS']}
 for g in applied['GROUPS']:
  assert byid[g['TARGET']]['OCCURRENCES']==g['OCCURRENCES'],g['TARGET']
  for m in g['MEMBERS']:
   if m['ID']!=g['TARGET']:assert byid[m['ID']]['OCCURRENCES']==0 and byid[m['ID']]['STATUS']=='ignored',m['ID']
 before=json.loads((stage/'triage-before-regroup.json').read_text());before_rows=before.get('occurrences',before.get('OCCURRENCES'))
 expected={r['id_log'] for r in before_rows if r['problem_id'] in ids};actual={r['ID_LOG'] for r in result['OCCURRENCES']}
 assert expected==actual,'Occurrence preservation failed'
 assert all(r['ID_LOG']==r['ORIGINAL_ID'] for r in result['OCCURRENCES']),'Original log absent'
 print(json.dumps({'verified':True,'preserved_occurrences':len(actual),'retained_problem_ids':len(ids),'default_total':result['DEFAULT_TOTAL'],'remaining_groups':result['REMAINING_GROUPS']}))
'''
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(source)],input=json.dumps({'mode':mode}),capture_output=True,text=True,timeout=160)
print(p.stdout);print(p.stderr[-1800:]);(STAGE/('regroup-'+mode+'.json')).write_text(p.stdout);sys.exit(p.returncode)
