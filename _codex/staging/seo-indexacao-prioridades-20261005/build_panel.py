from pathlib import Path
from datetime import datetime
from zoneinfo import ZoneInfo
import json,re,base64,importlib.util,copy,shutil
P=Path(__file__).resolve().parent;ROOT=P.parents[2]
names=['portal/includes/seo_queue_data.cfm','portal/includes/seo_semrush_data.cfm','portal/conteudo/seo_semrush.cfm']
for n in names:
 f=P/'candidate/business'/n;f.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(P/'baseline/business'/n,f)
spec=importlib.util.spec_from_file_location('snapshot',ROOT/'_codex/scripts/seo_semrush_snapshot.py');mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod)
f=P/'candidate/business/portal/includes/seo_semrush_data.cfm';snapshot=json.loads(base64.b64decode(re.search(r'binaryDecode\("([^"]+)"',f.read_text()).group(1)));before=copy.deepcopy(snapshot)
labels={'Grupos de títulos duplicados':'Páginas com títulos duplicados','Grupos de conteúdo duplicado':'Páginas com conteúdo duplicado','Descrições duplicadas':'Páginas com descrições duplicadas'}
for row in snapshot['audit']['errorsByType']:row['label']=labels.get(row['label'],row['label'])
check=copy.deepcopy(snapshot);check['audit']['errorsByType']=before['audit']['errorsByType'];assert check==before
f.write_text(mod.render_cfml(snapshot))
f=P/'candidate/business/portal/conteudo/seo_semrush.cfm';s=f.read_text();s=s.replace('62 grupos de títulos duplicados','62 páginas com títulos duplicados').replace('Os grupos e ocorrências não correspondem a páginas únicas.','Uma página pode aparecer em vários tipos de problema; não somar os grupos como páginas únicas.')
anchor='  <cfif structKeyExists(VARIABLES.seoSemrush.audit,"errorsByType")'
note='''  <p class="seo-note"><strong>Revisão por URL em 05/10:</strong> duas rotas do circuito FCA representam o mesmo cadastro e foram consolidadas; rankings Supra 2024 e 2025 receberam títulos e descrições específicos. Entrega e controles em <a href="/portal/seo/?aba=fila&amp;site=roadrunners##RR-29">RR-29</a>. As duas corridas Farmelhor têm cidades e datas diferentes e foram preservadas. O sitemap histórico e a página lenta responderam HTTP 200 nesta checagem; isso não confirma indexação. Os contadores Semrush acima continuam históricos.</p>
'''
assert s.count(anchor)==1;s=s.replace(anchor,note+anchor,1);f.write_text(s)
f=P/'candidate/business/portal/includes/seo_queue_data.cfm';s=f.read_text();now=datetime.now(ZoneInfo('America/Sao_Paulo'))
s=re.sub(r'updatedAt = "[^"]+"','updatedAt = "'+now.isoformat(timespec='seconds')+'"',s,count=1)
s=re.sub(r'updatedLabel = "[^"]+"','updatedLabel = "'+now.strftime('%d/%m/%Y às %H:%M')+' (Brasília)"',s,count=1)
s=s.replace('62 grupos de títulos iguais','62 páginas com títulos iguais').replace('oito grupos de conteúdo duplicado','oito páginas com conteúdo duplicado').replace('todos os 62 grupos','todas as 62 páginas')
end='As 126 ocorrências de erro e as notas acima'
record='''        {
            resolved = true,
            id = "RR-29", sites = ["roadrunners"], priority = "p1", priorityLabel = "P1 · Consolidação de URLs",
            title = "Consolidar o circuito FCA e distinguir rankings anuais",
            summary = "As duas rotas do circuito FCA usam um canonical; o alias sem parâmetros redireciona em 301. Rankings Supra 2024 e 2025 têm títulos e descrições distintos.",
            impact = "Concentra os sinais de um mesmo circuito no endereço já usado pelos links e diferencia duas páginas anuais reais.",
            owner = "RoadRunners — canonicals e metadados de circuitos e rankings",
            rule = "semrush.6; semrush.7; semrush.15; canonical.circuit-alias",
            evidence = "Detalhes da auditoria 6ac31bf647d73ceec1b0b861 consultados em 05/10. Duas rotas FCA resolvem o agregador legado 82 e os mesmos seis eventos; cada rota declarava canonical próprio. Agora canonical e redirect apontam a /circuito/circuito-catarinense-corrida-de-rua/, já usado no cabeçalho. Redirect somente em GET/HEAD sem filtros, ações ou formulário, com uma correspondência e tag válida. Demais requisições conservam o fluxo e declaram o mesmo canonical. Rankings Supra 2024 e 2025 tinham título e descrição iguais; recebem o ano e o nome já visíveis, sem alterar consultas ou resultados. Testes Adobe: 15 cenários e 36 verificações aprovadas, incluindo filtros padrão acrescentados pela aplicação, filtros explícitos, HEAD, POST e formulário. O teste de integração reproduziu o bloqueio do redirect pelos parâmetros internos; corrigido avaliando a requisição antes de acrescentar esses valores. Publicação de três templates com baseline, backup, compilação e controles HTTP. Farmelhor: dois eventos distintos, em Nova Cruz em 28/11 e Canguaretama em 18/10; não foram unidos nem retirados. Sitemap events-history-3.xml devolveu XML válido com 5.223 URLs e a página Trail in Motion respondeu 200 em menos de um segundo nesta amostra. Estes controles não são inspeção Google nem nova auditoria Semrush.",
            acceptance = "Entrega publicada e verificada em 05/10. Contadores e notas da auditoria anterior preservados; o efeito exige novo rastreamento e acompanhamento no Google. Demais duplicações permanecem no RR-20.",
            urls = [{url = "https://roadrunners.run/circuito/circuito-catarinense-corrida-de-rua/", label = "FCA — endereço consolidado"}, {url = "https://roadrunners.run/desafiosupra/2024/", label = "Ranking 2024"}, {url = "https://roadrunners.run/desafiosupra/2025/", label = "Ranking 2025"}],
            stateLabel = "Publicado e verificado — indexação e ranking ainda não medidos"
        },
'''
assert 'id = "RR-29"' not in s;s=s.replace('    items = [\n','    items = [\n'+record,1)
old='Não foi criado reinício automático nem ajustado o limite às cegas. Recuperação pontual não encerra esta frente.'
new=old+' Correções de 04/10 também coordenaram o cache Runner Apps, retiraram catálogo completo de rotas OpenResults que não o usam e limitaram espera de negociação TLS, com testes e verificações próprios. Checagens de 05/10, 14:00 a 14:08 (Brasília): servidor com aproximadamente 16 horas desde o reinício Apache, fila HTTPS zero e entre um e quatro workers ocupados. Treze URLs públicas de calendário, circuito, eventos, rankings e sitemap responderam 200. Amostra pontual e uptime não garantem estabilidade contínua; outras chamadas de conteúdo síncronas seguem fora desta entrega.'
assert s.count(old)==1;s=s.replace(old,new,1)
old='A revisão não abrangeu todas as 62 páginas.'
new=old+' Segunda entrega em RR-29 consolidou duas rotas FCA e diferenciou rankings Supra por ano. Farmelhor representa dois eventos distintos; sitemap e página lenta responderam normalmente em 05/10, sem prova de indexação. Os 62 e oito itens são páginas afetadas nos relatórios detalhados, não 62 e oito conjuntos distintos.'
assert s.count(old)==1;s=s.replace(old,new,1);f.write_text(s)
print(json.dumps({'panel_files':len(names),'audit_counts_preserved':True,'organic_snapshot_preserved':True,'new_queue_item':'RR-29'}))
