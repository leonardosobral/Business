from pathlib import Path
import json,shlex,subprocess
S=Path(__file__).resolve().parent
helpers=(S.parents[2]/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
helpers=helpers.replace('cgi.request_method!="POST"','cgi.request_method!="GET"').replace('form.key ?: ""','url.key ?: ""').replace("'-X','POST'","'-G'")
body='\n'.join([
 'VARIABLES.qPerfil=queryNew("is_admin","bit",[{is_admin=true}]);',
 'VARIABLES.businessEffectiveIsAdmin=true;URL.aba="fila";URL.site="roadrunners";',
 'savecontent variable="rendered" {include "/portal/conteudo/seo.cfm";}',
 'report={rr37=find(\'id="RR-37"\',rendered)>0,rr38=find(\'id="RR-38"\',rendered)>0,updated=(VARIABLES.seoQueueSnapshot.updatedAt EQ "2026-10-08T22:54:20-03:00")};',
 'URL.aba="semrush";',
 'savecontent variable="semrushRendered" {include "/portal/conteudo/seo.cfm";}',
 'report.rr39=find(\'id="RR-39"\',rendered)>0;report.audit_note=find("Reauditoria concluída em 08/10",semrushRendered)>0;report.correct_metrics=(VARIABLES.seoSemrush.audit.errors EQ 39 AND VARIABLES.seoSemrush.audit.warnings EQ 35227 AND VARIABLES.seoSemrush.audit.siteHealth EQ 75);'
])
code=helpers+'\nreport=bridge(ROOT,'+repr(body)+')\nprint(json.dumps(report))\n'
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(code)],capture_output=True,text=True,timeout=115)
if cp.returncode:raise RuntimeError(cp.stderr[-2500:])
r=json.loads(cp.stdout);(S/'original-runtime-check.json').write_text(json.dumps(r,indent=2));print(json.dumps(r))
assert all(r.values()),r
