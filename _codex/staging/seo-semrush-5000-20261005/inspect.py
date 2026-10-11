from pathlib import Path
import base64,json,shlex,subprocess
ROOT=Path('/Users/Shared/Projects/RunnerHub/Business'); STAGE=Path(__file__).resolve().parent
helpers=(ROOT/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
sql="""SELECT jsonb_build_object(
 'events',(SELECT jsonb_agg(to_jsonb(e)) FROM (SELECT id_evento,nome_evento,nome_simplificado,tag,tag_301,ativo,data_inicial,data_final,cidade,estado,status_evento FROM tb_evento_corridas WHERE tag LIKE '2025-live-run-xp-brasilia%' OR tag LIKE '2026-1-corrida-de-aniversario-do-grupo-corrida%' OR tag LIKE '2026-atibaia-run-fest-trail-mode%' OR tag LIKE '2026-endorfina-run-santo-andre%' OR tag LIKE '2026-rock-n-run%' OR tag LIKE '2026-live-run-xp-sao-paulo-2026%' OR tag LIKE '2026-%palmeira%' OR tag LIKE '2026-%ponta-grossa%' OR tag LIKE '2026-\"%' ORDER BY id_evento LIMIT 90)e),
 'suppliers',(SELECT jsonb_agg(to_jsonb(f)) FROM (SELECT id_fornecedor,nome_fornecedor,tag_fornecedor,to_jsonb(fr)->>'url_site' as url_site,to_jsonb(fr)->>'website' as website,to_jsonb(fr)->>'url_fornecedor' as url_fornecedor FROM tb_fornecedores fr WHERE tag_fornecedor IN ('branca-esportes-saude-e-lazer','corpo-e-saude','geracao-saude','grupo-de-corrida-espaco-saude','zero-meia-um-saude-e-esporte'))f)
 )::text AS payload"""
remote=helpers+'''
payload=json.load(sys.stdin)
body='transaction {'+raw_query('SET TRANSACTION READ ONLY')+raw_query(payload['sql'])+'report=deserializeJSON(q.payload[1]);}'
result=bridge(ROOT,body)
result['files']={}
for group,names in payload['files'].items():
 root=Path('/var/www/roadrunners.com.br') if group=='rr' else ROOT
 for name in names:result['files'][group+':'+name]=base64.b64encode((root/name).read_bytes()).decode()
result['public']=[]
for path in payload['paths']:
 cp=subprocess.run(['curl','-sS','--max-time','30','-A','RunnerHub-SEO-Verification/1.0','-w','\\n%{http_code}','https://roadrunners.run'+path],capture_output=True,text=True,timeout=35)
 body,_,status=cp.stdout.rpartition('\\n');result['public'].append({'path':path,'status':status,'body':body,'returncode':cp.returncode})
print(json.dumps(result,ensure_ascii=False))
'''
names={'rr':['includes/card_evento_individual.cfm','includes/estrutura/head.cfm','includes/estrutura/header.cfm','includes/estrutura/footer.cfm','includes/estrutura/header_tema.cfm','evento/index.cfm','timer/index.cfm','services/EventRedirectService.cfc'], 'business':['portal/conteudo/seo_semrush.cfm','portal/includes/seo_semrush_data.cfm','portal/includes/seo_queue_data.cfm']}
paths=['/estado/pr/palmeira/','/estado/pb/lastro/','/estado/sp/ubatuba/','/timer/branca-esportes-saude-e-lazer/','/evento/2025-live-run-xp-brasilia-i-2025/','/evento/2026-endorfina-run-santo-andre-ii/']
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'sql':sql,'files':names,'paths':paths}),capture_output=True,text=True,timeout=240)
if cp.returncode:raise RuntimeError(cp.stderr[-3000:])
data=json.loads(cp.stdout);(STAGE/'inspection.json').write_text(json.dumps(data,indent=2,ensure_ascii=False))
for key,value in data.pop('files').items():
 group,name=key.split(':',1);body=base64.b64decode(value);local=(ROOT.parent/'RoadRunners' if group=='rr' else ROOT)/name
 if local.read_bytes()!=body:raise RuntimeError('Local/production differ: '+key)
 p=STAGE/'baseline'/group/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(body)
for item in data['public']:
 p=STAGE/('public-'+str(paths.index(item['path']))+'.html');p.write_text(item.pop('body'))
print(json.dumps(data,ensure_ascii=False))
