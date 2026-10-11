from pathlib import Path
import json,shlex,subprocess,sys
p=Path(__file__).resolve().parent;root=p.parents[2];mode=sys.argv[1]
helpers=(root/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')").replace('detail=cfcatch.detail}', 'detail=cfcatch.detail,context=cfcatch.tagContext}')
remote=helpers+'''
p=json.load(sys.stdin);work=Path(tempfile.mkdtemp(prefix='fact_public_test_',dir=ROOT/'_codex'));os.chmod(work,0o755)
try:
 (work/'services').mkdir();source=p['service'] if p['mode']!='published' else (ROOT/'services/EventFactReviewService.cfc').read_text()
 source=source.replace('public.tb_evento_corridas','pg_temp.event_fact_test').replace('public.tb_evento_fatos_revisao','pg_temp.review_fact_test')
 (work/'services/EventFactReviewService.cfc').write_text(source)
 setup="CREATE TEMP TABLE event_fact_test AS SELECT * FROM public.tb_evento_corridas WHERE id_evento IN (37570,37526);ALTER TABLE event_fact_test ADD COLUMN IF NOT EXISTS conferencia_datas_publica jsonb;UPDATE event_fact_test SET conferencia_datas_publica=NULL;CREATE TEMP TABLE review_fact_test (LIKE public.tb_evento_fatos_revisao INCLUDING ALL);"
 component='_codex.'+work.name+'.services.EventFactReviewService';results=[]
 for case in p['cases']:
  body='transaction {'+raw_query(setup,'setup')+'s=createObject("component","'+component+'");checks=[];function check(n,v){arrayAppend(checks,{name=n,passed=v});}'+p['common']+case['body']+'report={checks=checks};transaction action="rollback";}'
  r=bridge(ROOT,body);results.extend(r['CHECKS'])
 print(json.dumps({'checks':results}))
finally:shutil.rmtree(work)
'''
common='''d=s.load(37570,true,false);f={grupo="datas",source_url="https://example.org/official",version=d.versions.datas,request_id=createObject("java","java.util.UUID").randomUUID().toString(),confirmed="1"};s.save(37570,f,true,false,true,true);rid=s.load(37570,true,false).reviews.id_revisao;'''
cases=[{'body':'''check("private before explicit publication",!len(s.load(37570,true,false).publicDateReview));s.publishDates(37570,rid,true,false,true,true);d=s.load(37570,true,false);m=deserializeJSON(d.publicDateReview);check("published",m.state=="published");check("source bound",m.sourceUrl==f.source_url);check("snapshot bound",m.startDate==d.snapshots.datas.data_inicial);check("review bound",m.reviewId==rid);check("server review date",isDate(m.checkedAt));s.publishDates(37570,rid,true,false,true,true);check("idempotent",s.load(37570,true,false).publicDateReview==d.publicDateReview);s.unpublishDates(37570,rid,true,false,true,true);d=s.load(37570,true,false);check("withdrawn marker",deserializeJSON(d.publicDateReview).state=="withdrawn");check("internal retained",!d.reviews.revoked);s.publishDates(37570,rid,true,false,true,true);s.revoke(37570,rid,true,false,true,true);check("revoke withdraws",deserializeJSON(s.load(37570,true,false).publicDateReview).state=="withdrawn");'''},
{'body':'''s.publishDates(37570,rid,true,false,true,true);f.request_id=createObject("java","java.util.UUID").randomUUID().toString();s.save(37570,f,true,false,true,true);check("new review withdraws prior",deserializeJSON(s.load(37570,true,false).publicDateReview).state=="withdrawn");'''}]
cases.append({'body': 's.publishDates(37570,rid,true,false,true,true);for(i=1;i<=11;i++){f.grupo="local";f.version=d.versions.local;f.request_id=createObject("java","java.util.UUID").randomUUID().toString();s.save(37570,f,true,false,true,true);}rows=s.load(37570,true,false).reviews;found=false;for(row in rows){if(row.id_revisao==rid)found=true;}check("latest dates survives history limit",found);'})
for name,prep,call in [
('stale withdrawal','s.publishDates(37570,rid,true,false,true,true);f.request_id=createObject("java","java.util.UUID").randomUUID().toString();s.save(37570,f,true,false,true,true);rid2=s.load(37570,true,false).reviews.id_revisao;s.publishDates(37570,rid2,true,false,true,true);','s.unpublishDates(37570,rid,true,false,true,true);'),
('stale','queryExecute("UPDATE pg_temp.event_fact_test SET data_final=data_final+1 WHERE id_evento=37570");','s.publishDates(37570,rid,true,false,true,true);'),
('old','f.request_id=createObject("java","java.util.UUID").randomUUID().toString();s.save(37570,f,true,false,true,true);','s.publishDates(37570,rid,true,false,true,true);'),
('revoked','s.revoke(37570,rid,true,false,true,true);','s.publishDates(37570,rid,true,false,true,true);'),
('mismatched event','','s.publishDates(37526,rid,true,false,true,true);'),
('nonadmin','','s.publishDates(37570,rid,false,false,true,true);'),
('delegated','','s.publishDates(37570,rid,true,true,true,true);'),
('GET','','s.publishDates(37570,rid,true,false,false,true);'),
('CSRF','','s.publishDates(37570,rid,true,false,true,false);'),
('other group','f.grupo="local";f.version=d.versions.local;f.request_id=createObject("java","java.util.UUID").randomUUID().toString();s.save(37570,f,true,false,true,true);rid=s.load(37570,true,false).reviews.id_revisao;','s.publishDates(37570,rid,true,false,true,true);')]:
 cases.append({'body':prep+'denied=false;try{'+call+'}catch(FactReview e){denied=true;}check("reject '+name+'",denied);'})
service=p/('baseline' if mode=='red' else 'candidate')/'business/services/EventFactReviewService.cfc'
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(dict(mode=mode,service=service.read_text(),common=common,cases=cases)),capture_output=True,text=True,timeout=130)
if mode=='red':
 assert cp.returncode and ('PUBLICDATEREVIEW' in cp.stderr.upper() or 'PUBLISHDATES' in cp.stderr.upper()),cp.stderr[-2000:]
 (p/'service-red.txt').write_text(cp.stderr);print('RED: baseline lacks explicit public review contract');sys.exit()
if cp.returncode:raise RuntimeError(cp.stderr[-4500:])
r=json.loads(cp.stdout);(p/('service-'+mode+'.json')).write_text(json.dumps(r,indent=2));assert all(c['PASSED'] for c in r['checks']),r
print(json.dumps({'checks':len(r['checks']),'passed':True}))
