"""Verify published templates on Adobe; auth fixture is local-only and temporary."""
from pathlib import Path
from html import unescape
import json,shlex,subprocess,sys
ROOT=Path('/Users/Shared/Projects/RunnerHub/Business');STAGE=Path(__file__).resolve().parent
mode=sys.argv[1];assert mode in ['candidate','published']
helpers=(ROOT/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
remote=helpers+'''
import secrets
payload=json.load(sys.stdin)
root=Path('/var/www/business.roadrunners.run');work=Path(tempfile.mkdtemp(prefix='seo-evidence-verify-',dir=root/'_codex'));os.chmod(work,0o755);key=secrets.token_hex(24)
try:
 if payload['mode']=='candidate':
  names=['portal/conteudo/seo.cfm','portal/conteudo/seo_report.cfm','portal/conteudo/seo_ai.cfm','portal/includes/seo_score_backend.cfm','portal/includes/seo_queue_backend.cfm','portal/includes/seo_score_data.cfm','portal/includes/seo_queue_data.cfm','includes/backend/require_admin.cfm','portal/includes/seo_search_evidence.cfm']
  for name in names:
   target=work/name;target.parent.mkdir(parents=True,exist_ok=True)
   if name in payload['files']:target.write_text(payload['files'][name])
   else:shutil.copyfile(root/name,target)
 (work/'.htaccess').write_text('Require local\\n')
 (work/'Application.cfc').write_text('component {this.name="'+work.name+'";this.sessionManagement=false;boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||cgi.request_method!="GET"||compare(cgi.http_x_seo_verify ?: "","'+key+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
 body='<cfsetting requesttimeout="45" showdebugoutput="false"/><cfcontent type="application/json" reset="true"/><cfset VARIABLES.qPerfil=queryNew("is_admin","bit",[{is_admin=true}])/><cfset VARIABLES.businessEffectiveIsAdmin=true/><cfset URL.aba="relatorio"/><cfsavecontent variable="html"><cfinclude template="/portal/conteudo/seo.cfm"/></cfsavecontent><cfset URL.aba="fila"/><cfsavecontent variable="queueHtml"><cfinclude template="/portal/conteudo/seo.cfm"/></cfsavecontent><cfscript>html &= queueHtml;report={runs=VARIABLES.seoQueueSnapshot.runs,updatedLabel=VARIABLES.seoQueueSnapshot.updatedLabel,total=VARIABLES.seoQueueTotal,pending=VARIABLES.seoQueueOpenTotal,resolved=VARIABLES.seoQueueResolvedTotal,items=[],sites=[],html=toBase64(html,"utf-8")};for(item in VARIABLES.seoQueueSnapshot.items)arrayAppend(report.items,{id=item.id,resolved=item.resolved,evidence=item.evidence});for(site in VARIABLES.seoScoreSnapshot.sites)arrayAppend(report.sites,{id=site.id,auditAt=site.auditAt,score=site.score,checks=site.aiChecks});writeOutput(serializeJSON(report));</cfscript>'
 if payload['mode']=='candidate':body=body.replace('template="/portal/conteudo/seo.cfm"','template="portal/conteudo/seo.cfm"')
 (work/'run.cfm').write_text(body)
 cp=subprocess.run(['curl','-sS','--fail-with-body','--max-time','50','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-SEO-Verify: '+key,'https://business.roadrunners.run/_codex/'+work.name+'/run.cfm'],capture_output=True,text=True,timeout=55)
 if cp.returncode:raise RuntimeError('Panel fixture failed: '+cp.stdout[:12000])
 print(cp.stdout)
finally:shutil.rmtree(work)
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'mode':mode,'files':{n:(STAGE/'candidate'/n).read_text() for n in ['portal/includes/seo_queue_data.cfm']}}),capture_output=True,text=True,timeout=75)
if cp.returncode:raise RuntimeError(cp.stderr[:14000])
def lower(v):return {k.lower():lower(x) for k,x in v.items()} if isinstance(v,dict) else [lower(x) for x in v] if isinstance(v,list) else v
r=lower(json.loads(cp.stdout));html=__import__('base64').b64decode(r.pop('html')).decode('utf-8')
from html.parser import HTMLParser
class Cards(HTMLParser):
 def __init__(self):super().__init__();self.stack=[];self.statuses=[];self.collapsed=0
 def handle_starttag(self,t,attrs):
  a=dict(attrs)
  if 'data-seo-search-status' in a:self.statuses.append(a['data-seo-search-status'])
  if t=='details' and a.get('class')=='seo-technical-score':
   assert 'open' not in a, 'Technical score should be secondary and collapsed';self.collapsed+=1
parser=Cards();parser.feed(html)
visible=unescape(html)
assert parser.statuses==['warning','warning'], parser.statuses
assert parser.collapsed==2
assert '14,1 mil páginas indexadas em 20/09/2026' in visible and '0 páginas indexadas em 20/09/2026' in visible and '135.791' in visible and '103.030 URLs descobertas' in visible
assert 'Não há nota geral de SEO' in visible and 'Registro manual; não é consulta ao vivo.' in visible
assert len({i['id'] for i in r['items']})==len(r['items']), 'Duplicate correction IDs'
assert r['total']==24 and r['pending']==6 and r['resolved']==18
assert next(i for i in r['items'] if i['id']=='OR-04')['resolved']
assert not next(i for i in r['items'] if i['id']=='OR-05')['resolved']
assert '34.319 URLs descobertas' in visible and 'Quatro lotes processados' in visible
assert 'Indexação atual ainda não confirmada' in visible
assert 'Falha de leitura do sitemap no Google' not in visible
assert next(i for i in r['items'] if i['id']=='SH-03')['resolved']
assert [(x['id'],x['score']) for x in r['sites']]==[('roadrunners',70),('openresults',100)]
assert '04/10/2026, 01:02 (Brasília)' in visible and '03/10/2026, 19:14 (Brasília)' in visible
(STAGE/('panel-'+mode+'-verification.json')).write_text(json.dumps(r,indent=2,ensure_ascii=False))
(STAGE/('panel-'+mode+'.html')).write_text('<!doctype html><html lang="pt-br"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>SEO — validação do relatório</title><link rel="stylesheet" href="/assets/css/mdb.min.css"><link rel="stylesheet" href="/assets/css/business-ui.css"></head><body data-mdb-theme="dark" class="bg-dark-subtle"><main class="container-fluid px-4 py-4">'+html+'</main></body></html>')

assert next(i for i in r["items"] if i["id"]=="RR-13")["resolved"]
assert "Estatísticas de 2025 corrigidas e verificadas" in visible

assert not next(i for i in r["items"] if i["id"]=="SH-02")["resolved"]
facts=next(i for i in r["items"] if i["id"]=="SH-02")["evidence"]
assert "13.068" in facts and "Organizador informado" in facts

assert "504 visualizações" in facts and "Regulamento do evento" in facts

assert "178 visualizações" in facts and "Corrida das Nações" in facts and "Onze IDs" in facts

record=next(i for i in r['items'] if i['id']=='RR-14')
assert not record['resolved'] and '01:42:19/2008' in record['evidence'] and '02:39:58' in record['evidence']
assert 'página oficial de campeões da Yescom' in visible

assert next(i for i in r['items'] if i['id']=='RR-15')['resolved']
assert 'WebSite e Organization' in visible

assert 'Sessenta verificações Adobe' in next(i for i in r['items'] if i['id']=='RR-12')['evidence']

assert '108 visualizações' in facts and 'Dezesseis IDs' in facts and 'fallback português' in facts

assert '86 eventos futuros' in facts and 'percursos bloqueados' in facts

assert '103 visualizações' in facts and 'onze datas' in facts

assert not next(i for i in r['items'] if i['id']=='RR-16')['resolved']
assert '33 verificações' in visible and 'Nove URLs ausentes' in visible

assert 'Fontes das datas publicadas em quatro eventos' in facts
assert '54 verificações' in facts
assert '96 endereços de eventos' in next(i for i in r['items'] if i['id']=='RR-16')['evidence']
assert 'Canal de correção contextual publicado' in facts
assert '148 percursos em 77 eventos futuros' in facts and 'IZ1 Telecom excluída' in facts
assert 'Histórico público de correções publicado em oito eventos' in facts and '181 verificações Adobe' in facts
if mode=='candidate':
 import hashlib
 hashes={n:hashlib.sha256((STAGE/'candidate'/n).read_bytes()).hexdigest() for n in ['portal/includes/seo_queue_data.cfm']}
 (STAGE/'candidate-render-passed.json').write_text(json.dumps({'hashes':hashes,'watch':json.loads((STAGE/'watch.json').read_text())}))

print(json.dumps({'total':r['total'],'pending':r['pending'],'resolved':r['resolved'],'google_statuses':parser.statuses,'collapsed_technical_scores':parser.collapsed,'historical_scores_unchanged':True,'auth':'isolated fixture with actual admin guard'},ensure_ascii=False))
