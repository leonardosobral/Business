from pathlib import Path
import base64,datetime,hashlib,json,shlex,subprocess
from zoneinfo import ZoneInfo
S=Path(__file__).resolve().parent;B=S.parents[2];NAME='portal/includes/seo_queue_data.cfm'
remote='''from pathlib import Path
import base64,hashlib,json
root=Path('/var/www/business.roadrunners.run');name='portal/includes/seo_queue_data.cfm'
watch=['Application.cfc','portal/conteudo/seo.cfm','portal/includes/seo_queue_backend.cfm','includes/backend/require_admin.cfm','portal/includes/seo_semrush_data.cfm','portal/conteudo/seo_semrush.cfm','portal/seo/index.cfm']
print(json.dumps({'source':base64.b64encode((root/name).read_bytes()).decode(),'watch':{n:hashlib.sha256((root/n).read_bytes()).hexdigest() for n in watch}}))
'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],capture_output=True,text=True,timeout=40)
if cp.returncode:raise RuntimeError(cp.stderr[-1800:])
r=json.loads(cp.stdout);data=base64.b64decode(r.pop('source'));assert (B/NAME).read_bytes()==data
target=S/'baseline/business'/NAME;target.parent.mkdir(parents=True,exist_ok=True);assert not target.exists() or target.read_bytes()==data;target.write_bytes(data)
r['sha256']=hashlib.sha256(data).hexdigest();(S/'panel-baseline.json').write_text(json.dumps(r,indent=2))
check=json.loads((S/'public-passed.json').read_text());now=datetime.datetime.now(ZoneInfo('America/Sao_Paulo'));label=now.strftime('%d/%m/%Y às %H:%M (Brasília)')
before=check['previous_origin_median_s'];after=check['origin_median_s'];improvement=(1-after/before)*100
def decimal(x):return f'{x:.2f}'.replace('.',',')
item='''        {
            resolved = true, id = "RR-39", sites = ["roadrunners"], priority = "p1", priorityLabel = "P1 · Tempo de resposta de eventos",
            title = "Otimizar a consulta das edições anteriores",
            summary = "As quatro páginas de São Silvestre marcadas como lentas passaram de mediana de BEFORE s para AFTER s na origem (REDUCTION% menor nesta medição).",
            impact = "Reduz o trabalho necessário para entregar o HTML dos eventos e mantém os resultados disponíveis aos buscadores; a baixa dos erros depende de nova auditoria.",
            owner = "RoadRunners — consulta das edições", rule = "performance.event_editions",
            evidence = "A auditoria de 08/10 às 20:20 apontou quatro páginas lentas de São Silvestre (2007, 2008, 2019 e 2026). Medição confirmou que a consulta das edições levava cerca de dois segundos. A consulta agora lê os resultados elegíveis uma vez por edição, encontra a melhor classificação de cada sexo e mantém todos os empates antes da escolha de perfil. A validação de identidade e perfil público permanece em tempo real. Nenhum cache de atletas foi adicionado. Passaram 34 cenários sintéticos, incluindo empates, categorias excluídas, homologação, importador com nome diferente e perfil privado; a comparação completa de 32 edições reais em quatro séries retornou zero diferenças. Um template compilado, publicado com backup recuperável e quatro dependências preservadas. Após publicação: 16 respostas 200, pela origem e acesso público, com título, H1, canonical, hreflang e robots iguais ao baseline. A mediana de resposta pública mudou de PUBLICBEFORE s para PUBLICAFTER s. Não houve alteração de resultados, datas, cadastros, permissões nem estrutura do banco.",
            acceptance = "Publicado e conferido; confirmar a baixa dos quatro erros e o Site Health em nova auditoria comparável de 5.000 páginas. A nota permanece 75% da coleta anterior.",
            urls = [{url="https://roadrunners.run/evento/2026-101-corrida-internacional-de-sao-silvestre/",label="São Silvestre 2026"},{url="https://roadrunners.run/en/event/2007-83-corrida-internacional-de-sao-silvestre/",label="São Silvestre 2007"}],
            stateLabel = "Publicado — resposta de eventos otimizada; aguardando reauditoria"
        },
'''
for key,value in [('PUBLICBEFORE',decimal(check['previous_public_median_s'])),('PUBLICAFTER',decimal(check['public_median_s'])),('BEFORE',decimal(before)),('AFTER',decimal(after)),('REDUCTION',decimal(improvement))]:item=item.replace(key,value)
src=data.decode();assert 'id = "RR-39"' not in src
src=src.replace('    items = [\n','    items = [\n'+item,1)
import re
src=re.sub(r'    updatedAt = "[^"]+",','    updatedAt = "'+now.isoformat(timespec='seconds')+'",',src,count=1)
src=re.sub(r'    updatedLabel = "[^"]+",','    updatedLabel = "'+label+'",',src,count=1)
target=S/'candidate/business'/NAME;target.parent.mkdir(parents=True,exist_ok=True);target.write_text(src)
receipt=json.loads((B/'_codex/staging/seo-links-assets-20261008/import-receipt.json').read_text());receipt['queue_updatedLabel']=label;receipt['queue_updatedAt']=now.isoformat(timespec='seconds')
(S/'import-receipt.json').write_text(json.dumps(receipt,indent=2));print(json.dumps({'new_item':'RR-39','queue_updatedLabel':label,'audit_metric_unchanged':75}))
