from pathlib import Path
import ast, json, subprocess
src=Path('_codex/scripts/deploy_estudo.py').read_text()
bridge=next(ast.get_source_segment(src,n) for n in ast.parse(src).body if isinstance(n,ast.FunctionDef) and n.name=='bridge')
bridge=bridge.replace("prefix='error-triage-op-'","prefix='event-handler-test-20261117-'")
bridge=bridge.replace("(work/'run.cfm').write_text", "(work/'handler.cfm').write_text(handler)\n  (work/'run.cfm').write_text")
bridge=bridge.replace('finally:shutil.rmtree(work)','finally:\n  shutil.rmtree(work)\n  assert not work.exists()')
bridge=bridge.replace('this.datasource=', 'this.sessionManagement=true;this.datasource=')
remote='from pathlib import Path\nimport base64,json,os,tempfile,subprocess,shutil,signal,re\ndef interrupted(s,f):raise RuntimeError("Interrupted")\nsignal.signal(signal.SIGTERM,interrupted)\nsignal.signal(signal.SIGHUP,interrupted)\n'+bridge
remote+=r'''
root=Path('/var/www/business.roadrunners.run')
handler=(root/'eventos/includes/backend/backend_evento_solicitacoes.cfm').read_text()
handler=handler.replace('datasource="runnerhub"','datasource="runner_dba"')
handler=re.sub(r'<cflocation addtoken="false" url="([^"]+)"/>',r'<cfset report.redirect="\1"/>',handler)
handler=handler.replace('<cfcatch type="any">','<cfcatch type="any"><cfset report.caught={message=cfcatch.message,detail=cfcatch.detail}/>')
body='report={};function eventDelegationActive(){return false;}function adminEventoResolveUniqueTag(){};qPerfil=queryNew("id,is_admin","integer,bit",[{id=139,is_admin=true}]);VARIABLES.businessRealIsAdmin=true;VARIABLES.businessEffectiveIsAdmin=false;VARIABLES.businessEffectiveAccountIds="25";VARIABLES.businessAccountSimulationActive=true;FORM.evento_solicitacao_action="aprovar";FORM.id_solicitacao=24;transaction {try {include "handler.cfm";report.notice=VARIABLES.eventoSolicitacaoNoticeMessage;report.errorMessage=VARIABLES.eventoSolicitacaoErrorMessage;}finally {transaction action="rollback";}}'
print(json.dumps(bridge(root,body),ensure_ascii=False))
'''
r=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -'],input=remote,capture_output=True,text=True,timeout=120)
if r.returncode:raise RuntimeError(r.stderr)
print(r.stdout)
