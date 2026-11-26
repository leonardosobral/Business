from pathlib import Path
import base64,json,os,tempfile,subprocess,shutil,signal,hashlib
def bridge(root,body):
 import secrets
 work=Path(tempfile.mkdtemp(prefix='business-support-audit-20261117-',dir=root/'_codex'));os.chmod(work,0o755)
 token=secrets.token_hex(24)
 try:
  (work/'.htaccess').write_text('Require local\n')
  (work/'Application.cfc').write_text('component {this.name="'+work.name+'";this.datasource="runner_dba";boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||cgi.request_method!="POST"||compare(form.key ?: "","'+token+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
  (work/'run.cfm').write_text('<cfsetting requesttimeout="90" showdebugoutput="false"/><cfcontent type="application/json" reset="true"/><cftry><cfscript>'+body+'writeOutput(serializeJSON(report));</cfscript><cfcatch><cfheader statuscode="500"/><cfoutput>#serializeJSON({error=cfcatch.message,detail=cfcatch.detail})#</cfoutput></cfcatch></cftry>')
  p=subprocess.run(['curl','-sS','--max-time','95','--resolve','business.roadrunners.run:443:127.0.0.1','-X','POST','--data-urlencode','key='+token,'https://business.roadrunners.run/_codex/'+work.name+'/run.cfm'],capture_output=True,text=True,timeout=100)
  result=json.loads(p.stdout)
  if any(k.lower()=='error' for k in result):raise RuntimeError(json.dumps(result))
  return result
 finally:
  shutil.rmtree(work)
  assert not work.exists()
def raw_query(sql,target='q'):
 encoded=base64.b64encode(sql.encode()).decode()
 return 'cfquery(name="'+target+'",datasource="runner_dba",timeout=50){writeOutput(toString(binaryDecode("'+encoded+'","base64")));}'
def interrupted(s,f):raise RuntimeError("Interrupted")
signal.signal(signal.SIGHUP,interrupted)
signal.signal(signal.SIGTERM,interrupted)
root=Path("/var/www/business.roadrunners.run")
body="transaction {"+raw_query("SET TRANSACTION READ ONLY")+raw_query("SELECT jsonb_build_object('rows',(SELECT coalesce(jsonb_agg(to_jsonb(a)),'[]') FROM (SELECT id_auditoria,acao,id_usuario_autor,id_usuario_alvo,data_criacao,dados_novos->>'SUPPORTID' support_id,dados_novos->>'PATH' path,dados_novos->>'REASON' reason FROM public.tb_usuarios_gestao_auditoria WHERE id_usuario_autor=139 AND id_usuario_alvo=136808 AND acao LIKE 'business_suporte_%' AND data_criacao>=CURRENT_DATE ORDER BY id_auditoria DESC LIMIT 25) a),'fixture_rows',(SELECT count(*) FROM public.tb_usuarios_gestao_auditoria WHERE acao LIKE 'business_suporte_%' AND dados_novos->>'PATH' LIKE '/_codex/business-support-check-20261117-%'))::text payload")+"report=deserializeJSON(q.payload[1]);}"
audit=bridge(root,body)
expected={'services/BusinessSupportSession.cfc': '7f560113a0667f5deef32a20cd88c81132b7975afe508042dc0450b1d9715c1c', 'includes/backend/business_support_request.cfm': '95607cf4d3c666c4eee8125aca4f8b0f0dd9d0614f87f2b22dcd7177f6a1a135', 'includes/estrutura/business_support_banner.cfm': '0c013db360116214cc68b6f935fccc162080a646525443d713fa4b6fb69a9e34', 'suporte/acesso/index.cfm': '990f19472742a5ac04779d18eb40f651b11061f0dbc1f5ecf7112beff4387c34', 'includes/backend/business_remember_issue.cfm': '916f7b1e2e98dfcda7a11808ef1a77d0bf822f493274071924616fa2cd787a03', 'includes/backend/business_delegation_request.cfm': 'bfcad388936ef980b40bb34c63016fe7d9703043cdc4080f51ff764f00502428', 'includes/estrutura/header.cfm': '01c655128430de30c93e0040ff06a3326eee93559926578547f7e510b0d6f29b', 'teams/includes/header.cfm': 'ead13fe746596bbd489d2ac4f6db7c17c43e3dc2a0fcc0a47b2e11ee6416e6d3', 'selecionar-conta/index.cfm': '4ca628c2d54d7a1d5ac2919737eb71dee950afb2fb3af37e0b9904aedec8c29f', 'includes/backend/business_request_identity.cfm': '579e736d4b74a84c2f88a8038fe6996994f27ace10d237bd9c47fef54471d2f4', 'administracao/usuarios/home.cfm': '74efd5906b8eda1f3b009645595caca519b796e082f1c5e632ac155ea01c4a18'}
assert all(hashlib.sha256((root/p).read_bytes()).hexdigest()==h for p,h in expected.items()),"Published file mismatch"
assert not list((root/"_codex").glob("business-support-check-20261117-*")),"Fixture remains"
assert audit["fixture_rows"]==0
assert audit["rows"][0]["acao"]=="business_suporte_fim" and audit["rows"][0]["reason"]=="retorno_administrador",audit
print(json.dumps({"audit":audit,"verified_files":len(expected),"fixtures_removed":True}))
