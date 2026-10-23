"""Isolated CFML tests for the usage ledger. No paid provider calls."""
import ast,json,pathlib,re,shlex,subprocess,sys
ROOT=pathlib.Path(__file__).resolve().parents[2]
mode=sys.argv[1] if len(sys.argv)>1 else 'pricing'
tree=ast.parse((ROOT/'_codex/scripts/test_geocoding_native.py').read_text())
remote=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='REMOTE' for t in n.targets))
payload={'_mode':mode}
for folder in ['services/openaiUsage','services/geocoding','_codex/tests/openai-usage','administracao/consumo-openai']:
 base=ROOT/folder
 if not base.exists():continue
 for path in base.rglob('*'):
  if not path.is_file() or path.suffix not in ['.cfm','.cfc']:continue
  name='tests/'+str(path.relative_to(base)) if folder.startswith('_codex') else str(path.relative_to(ROOT))
  payload[name]=path.read_text().replace('services.openaiUsage.','__GEO_TEST_PACKAGE__.services.openaiUsage.').replace('__GEO_TEST_PACKAGE__.__GEO_TEST_PACKAGE__.','__GEO_TEST_PACKAGE__.')
if mode=='legacy':
 payload['services/openaiUsage/Legacy.cfc']=payload['services/openaiUsage/Legacy.cfc'].replace('private struct function legacyUsage','public struct function legacyUsage')
if mode=='view':
 backend=(ROOT/'administracao/consumo-openai/includes/backend.cfm').read_text()
 start=backend.index('function usageNumber(')
 payload['tests/formatters.cfm']='<cfscript>'+backend[start:backend.index('</cfscript>',start)]+'</cfscript>'
if mode=='wrappers':
 wrappers={
  'tests/Rewrite.cfc':ROOT/'services/EventDescriptionRewriteService.cfc',
  'tests/Geo.cfc':ROOT/'services/geocoding/AIClient.cfc',
  'tests/Helpdesk.cfc':ROOT/'helpdesk/includes/HelpdeskAI.cfc',
  'tests/ai-mails.cfm':ROOT/'administracao/ai-mails/includes/ai.cfm',
  'tests/Summary.cfc':ROOT/'_codex/staging/openai-usage/news/inc/article_summary_provider.cfc',
  'tests/Digest.cfc':ROOT/'_codex/staging/openai-usage/news/inc/openai_client.cfc',
  'tests/Audio.cfc':ROOT/'_codex/staging/openai-usage/news/inc/news_audio_provider.cfc',
  'tests/Vicky.cfc':ROOT/'_codex/staging/openai-usage/rr/services/VickyAgentService.cfc'}
 for name,path in wrappers.items():
  text=path.read_text()
  pattern=r'cfhttp\([^;]*?result\s*=\s*"(\w+)"[^;]*?\)\s*\{[\s\S]*?\n\s*\}'
  def fake(match):
   return 'if(REQUEST.usageFixtureThrow)throw(type="UsageFixture.Transport",message="timeout"); '+match.group(1)+'=duplicate(REQUEST.usageFixtureResponse);'
  text,n=re.subn(pattern,fake,text)
  if n not in (1,2):raise SystemExit('Fixture HTTP boundary not found: '+name)
  text=text.replace('new services.openaiUsage.Observer()','new __GEO_TEST_PACKAGE__.services.openaiUsage.Observer(REQUEST.usageFixtureDir)')
  text=text.replace('application.vickyKnowledge','REQUEST.usageFixtureConfig')
  text=text.replace('createObject("component", "inc.weekly_digest_config").load()','REQUEST.usageFixtureConfig').replace('createObject("component", "inc.weekly_digest_config").load()','REQUEST.usageFixtureConfig')
  if name.endswith('Audio.cfc'):text=text.replace(' implements="inc.news_audio_provider_interface"','')
  if name.endswith('Helpdesk.cfc'):text=text.replace('</cfscript>','public struct function exercise(){return requestOpenAI("responses",{model="gpt-6.1-sol"},5);}\n</cfscript>',1)
  if name.endswith('Vicky.cfc'):text=text.replace('</cfscript>','public struct function exercise(){variables.config={apiKey="synthetic",endpoint="fixture",timeoutSeconds=5};return callOpenAI({model="gpt-6.1-sol"},1);}\n</cfscript>',1)
  payload[name]=text
run=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(remote)],input=json.dumps(payload).encode(),capture_output=True,timeout=75)
try:result=json.loads(run.stdout)
except Exception:result={'ok':False,'message':'Native transport returned no safe JSON.'}
print(json.dumps(result,ensure_ascii=False))
sys.exit(0 if run.returncode==0 and result.get('ok') else 1)
