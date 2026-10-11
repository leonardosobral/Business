from pathlib import Path
import json,shlex,subprocess,hashlib
P=Path(__file__).resolve().parent
block=(P/'redirect-block.txt').read_text()
candidate=(P/'candidate/rr/.htaccess').read_text();assert candidate.count(block)==1
prefixes=['evento','en/event','es/evento'];tag='2026-costa-esmeralda-trail-2026'
cases=[{'name':m+' '+prefix,'method':m,'path':prefix+'/'+tag,'status':301,'location':'/'+prefix+'/'+tag+'/'} for prefix in prefixes for m in ['GET','HEAD']]
cases +=[{'name':'already canonical '+prefix,'method':'GET','path':prefix+'/'+tag+'/','status':404} for prefix in prefixes]
cases +=[{'name':'query '+q,'method':'GET','path':'evento/'+tag+'?'+q,'status':404} for q in ['action=delete','id_evento=1','utm_source=google','tag=another','route_geometry=1','i18n_lang=en']]
cases +=[{'name':'method '+m,'method':m,'path':'evento/'+tag,'status':404} for m in ['POST','PUT','DELETE']]
cases +=[{'name':'out of scope '+path,'method':'GET','path':path,'status':404} for path in ['evento/not-registered','evento/2025-corrida-night-run-vitoria-airport','evento/'+tag+'/extra','evento/'+tag.upper(),'en/event/other-event','es/evento/other-event','evento','evento/']]
cases +=[{'name':'existing file preserved','method':'GET','path':'control.txt','status':200}]
remote='''from pathlib import Path
import json,tempfile,os,sys,shutil,subprocess,re
p=json.load(sys.stdin);root=Path('/var/www/business.roadrunners.run');work=Path(tempfile.mkdtemp(prefix='seo-alias-apache-',dir=root/'_codex'));os.chmod(work,0o755)
try:
 (work/'baseline').mkdir(mode=0o755)
 (work/'candidate').mkdir(mode=0o755)
 (work/'candidate/.htaccess').write_text('Require local\\nErrorDocument 404 default\\n<IfModule mod_rewrite.c>\\nRewriteEngine on\\n'+p['block']+'</IfModule>\\n')
 (work/'baseline/.htaccess').write_text('Require local\\nErrorDocument 404 default\\n')
 for group in ['baseline','candidate']:
  (work/group/'evento').mkdir(mode=0o755)
  child=p['child_block'] if group=='candidate' else ''
  (work/group/'evento/.htaccess').write_text('Require local\\nErrorDocument 404 default\\n<IfModule mod_rewrite.c>\\nRewriteEngine on\\n'+child+'</IfModule>\\n')
 (work/'baseline/control.txt').write_text('seo routing control')
 (work/'candidate/control.txt').write_text('seo routing control')
 result=[]
 for c in p['cases']:
  responses={}
  for group in ['baseline','candidate']:
   cmd=['curl','-sS','--path-as-is','--max-time','10','--resolve','business.roadrunners.run:443:127.0.0.1']
   cmd+=['-I'] if c['method']=='HEAD' else ['-X',c['method'],'-D','-','-o','/dev/null']
   cmd+=['https://business.roadrunners.run/_codex/'+work.name+'/'+group+'/'+c['path']]
   cp=subprocess.run(cmd,capture_output=True,text=True,timeout=13);headers=cp.stdout.splitlines();status=next((int(x.split()[1]) for x in headers if x.startswith('HTTP/')),0);location=next((x.split(':',1)[1].strip() for x in headers if x.lower().startswith('location:')),'')
   responses[group]={'status':status,'location':location,'returncode':cp.returncode}
  old=responses['baseline'];new=responses['candidate']
  ok=not old['returncode'] and not new['returncode']
  if c.get('location'):ok=ok and old['status']==404 and new['status']==301 and new['location'] in [c['location'],'https://business.roadrunners.run'+c['location']]
  else:
   old_control=dict(old,location=old['location'].replace('/baseline/','/fixture/'))
   new_control=dict(new,location=new['location'].replace('/candidate/','/fixture/'))
   ok=ok and new_control==old_control
  result.append({'name':c['name'],'before':old,'after':new,'passed':ok})
 print(json.dumps({'checks':result}))
finally:shutil.rmtree(work)
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'block':block,'child_block':(P/'child-redirect-block.txt').read_text(),'cases':cases}),capture_output=True,text=True,timeout=170)
assert cp.returncode==0,cp.stderr[-2500:];r=json.loads(cp.stdout);r['source_hash']=hashlib.sha256((P/'candidate/rr/.htaccess').read_bytes()).hexdigest();r['child_source_hash']=hashlib.sha256((P/'candidate/rr/evento/.htaccess').read_bytes()).hexdigest();r['block_hash']=hashlib.sha256(block.encode()).hexdigest();r['failed']=[x for x in r['checks'] if not x['passed']]
(P/'apache-tests.json').write_text(json.dumps(r,indent=2));print(json.dumps({'checks':len(r['checks']),'failed':r['failed']}));assert not r['failed']
