from config import *
import base64,copy,datetime,importlib.util,json,re
spec=importlib.util.spec_from_file_location('snapshot',B/'_codex/scripts/seo_semrush_snapshot.py');mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod)
source=json.loads((S/'source-20261008.json').read_text());assert source['projectId']==26661911 and source['status']=='complete' and source['crawled']==source['limit']==5000
for field,group in [('errors','errorsByType'),('warnings','warningsByType'),('notices','noticesByType')]:assert sum(x['count'] for x in source[group])==source[field]
snapshot=json.loads(base64.b64decode(re.search(r'binaryDecode\("([A-Za-z0-9+/=]+)"',(S/'baseline/business/portal/includes/seo_semrush_data.cfm').read_text())[1]));organic=copy.deepcopy({k:v for k,v in snapshot.items() if k!='audit'});old=snapshot['audit'];assert old['siteHealth']==75 and old['errors']==27
audit={k:v for k,v in source.items() if k not in ['domain']};audit.update(checkedLabel=mod.label(source['checkedAt']),lastFinishedLabel=mod.label(source['lastFinishedAt']),previous=old)
audit['comparison']={'previousLabel':old['lastFinishedLabel'],'currentLabel':audit['lastFinishedLabel'],'note':'As duas rodadas têm 5.000 páginas, rastreador móvel e JavaScript sem renderização. A amostra mudou; os contadores medem achados técnicos e não indexação ou posição no Google. Esta coleta começou antes das últimas publicações de 08/10.','rows':[]}
for label,key,higher in [('Site Health (%)','siteHealth',True),('Estado de pesquisa IA (%)','aiHealth',True),('Erros','errors',False),('Advertências','warnings',False),('Observações','notices',False)]:
 delta=audit[key]-old[key];totals=source['observedDetails']['comparison_totals'].get(key,{})
 audit['comparison']['rows'].append(dict(label=label,previous=old[key],current=audit[key],fixedLabel=str(totals.get('fixed','—')),newLabel=str(totals.get('new','—')),deltaLabel=('+' if delta>0 else '')+str(delta),tone='pass' if delta*(1 if higher else -1)>0 else 'warning' if delta else 'unknown'))
for group in ['errorsByType','warningsByType','noticesByType']:
 previous={x['label']:x['count'] for x in old[group]}
 for item in audit[group]:
  delta=item['count']-previous[item['label']]
  audit['comparison']['rows'].append(dict(label=item['label'],previous=previous[item['label']],current=item['count'],fixedLabel='—',newLabel='—',deltaLabel=('+' if delta>0 else '')+str(delta),tone='pass' if delta<0 else 'warning' if delta else 'unknown'))
snapshot['audit']=audit;assert organic=={k:v for k,v in snapshot.items() if k!='audit'}
(S/'candidate/business/portal/includes/seo_semrush_data.cfm').write_text(mod.render_cfml(snapshot))
now=datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=-3)));stamp=now.isoformat(timespec='seconds');label=now.strftime('%d/%m/%Y às %H:%M (Brasília)')
q=(S/'baseline/business/portal/includes/seo_queue_data.cfm').read_text().replace('2026-10-08T19:27:41-03:00',stamp).replace('08/10/2026 às 19:27 (Brasília)',label)
items='''        {
            resolved = true, id = "RR-37", sites = ["roadrunners"], priority = "p2", priorityLabel = "P2 · Recursos compartilhados",
            title = "Minificar recursos da home, cidades e audiência",
            summary = "Cinco recursos receberam versões minificadas: 52.779 para 40.104 bytes, redução de 24,0% antes da compressão HTTP.",
            impact = "Reduz transferência e trata avisos de minificação nas páginas que usam esses arquivos; o efeito na nota depende da próxima coleta.",
            owner = "RoadRunners — assets e referências", rule = "semrush.135",
            evidence = "Publicado em 08/10 com backup recuperável: cinco assets e quatro templates. Cinco comparações de programa normalizado e 98 testes executados contra os arquivos gerados passaram, incluindo privacidade, GPC, opt-out e navegação por cidade. Quatro templates compilados. Dezoito páginas públicas e cinco assets conferidos por hash/MIME; 38 referências atualizadas, com atributos, metadados e status preservados. Desktop 1280 e celular 390: geometria da home e dos filtros igual ao baseline, sem overflow; busca Salvador retorna a cidade esperada. Dezoito dependências preservadas por hash. Fontes, coleta de audiência, configurações de privacidade e autenticação não foram alteradas. A auditoria concluída às 20:20 de 08/10 ainda representa a versão anterior a este lote.",
            acceptance = "Publicado e verificado; confirmar a baixa dos avisos em nova rodada de 5.000 páginas. Não atribuir ao lote uma nota ainda não medida.",
            urls = [{url="https://roadrunners.run/",label="Home"},{url="https://roadrunners.run/estado/ba/",label="Estado e cidade"}],
            stateLabel = "Publicado — recursos 24,0% menores; aguardando reauditoria"
        },
        {
            resolved = true, id = "RR-38", sites = ["roadrunners"], priority = "p1", priorityLabel = "P1 · Novos erros por URL",
            title = "Distinguir edições e codificar os links de eventos",
            summary = "Quatro títulos passaram a conservar data/local; links com aspas, quebra de linha e caractere de fragmento agora chegam à tag completa do evento.",
            impact = "Remove duplicação causada pelo corte do ano e links que interrompiam a descoberta dos eventos pelos buscadores.",
            owner = "RoadRunners — título e card de evento", rule = "semrush.6; semrush.8; semrush.2",
            evidence = "A auditoria de 08/10 às 20:20 apontou títulos iguais em Jurerê Night Run 2025/2026 e Meia Maratona de Florianópolis Oakberry 2025/2027. Os prefixos diferiam em maiúsculas e escapavam à comparação anterior; a correção ignora caixa no prefixo, mantendo nomes já diferenciados por data. Também apontou três URLs 404 truncadas: /evento/2026-, o aniversário do Grupo Corrida e Rock N Run Nashville. Consulta somente leitura confirmou aspas, caractere de fragmento e quebra de linha nas tags; o card passou a codificá-las para URL. O ajuste do card existente localmente tinha apenas essas três diferenças em relação à produção; nenhuma mudança de outra frente foi incluída. Baseline de títulos falhou em 21 de 91 verificações; candidato passou nas 91. Baseline dos links falhou em 16 de 40; candidato passou nas 40. Dois templates compilados, backup e sete dependências preservadas por hash. Após publicação: 28 páginas conferidas, sendo 12 títulos nos três idiomas, nove destinos codificados com resposta 200 e sete páginas de origem. Os quatro títulos por idioma são distintos mesmo ignorando caixa; metadados, canonical, hreflang, H1 e JSON-LD preservados. As tags dos links foram conferidas contra o catálogo real. Nenhum nome, data, tag, cadastro ou resultado alterado no banco. URLs antigas ambíguas não receberam redirecionamento inventado.",
            acceptance = "Publicado e conferido diretamente; a baixa dos contadores exige nova auditoria. A loja externa e a proteção de e-mail continuam com tratamento próprio.",
            urls = [{url="https://roadrunners.run/evento/2026-jurere-night-run-hard-rock-cafe-florianopolis-2026/",label="Jurerê Night Run"},{url="https://roadrunners.run/estado/pb/lastro/",label="Links de eventos"}],
            stateLabel = "Publicado — títulos distintos e links codificados; aguardando reauditoria"
        },
'''
q=q.replace('    items = [\n','    items = [\n'+items,1)
q=q.replace('Reauditoria de 06/10: Site Health 75%, 27 erros e 45.495 advertências. Erros caíram 99; Night Run e alias hreflang corrigidos em RR-32, 403 do atleta em RR-34; quatro títulos e seis descrições da loja seguem no RR-36.','Reauditoria de 08/10 às 20:20: Site Health 75%, 39 erros e 35.227 advertências. Foram 10.268 advertências a menos e 12 erros a mais. Novos títulos e links corrigidos em RR-38; recursos em RR-37. Loja externa segue no RR-36. Quatro páginas lentas exigem acompanhamento.')
q=q.replace('Reauditoria de 06/10 importada — 99 erros a menos; 27 pendentes','Reauditoria de 08/10 importada — 10.268 advertências a menos; nota 75%')
(S/'candidate/business/portal/includes/seo_queue_data.cfm').write_text(q)
v=(S/'baseline/business/portal/conteudo/seo_semrush.cfm').read_text()
start=v.index('  <p class="seo-note"><strong>Pendências da auditoria de 06/10:');end=v.index('  <cfif structKeyExists(VARIABLES.seoSemrush.audit,"comparison")>',start)
v=v[:start]+'''  <p class="seo-note"><strong>Reauditoria concluída em 08/10 às 20:20:</strong> 5.000 páginas, Site Health 75% e prontidão para IA 78%. Advertências passaram de 45.495 para 35.227; avisos de minificação caíram de 11.995 para 2.088. Os erros passaram de 27 para 39: 17 links quebrados, oito títulos duplicados, seis descrições duplicadas, quatro respostas 4xx e quatro páginas lentas. As métricas acima são as reais desta coleta.</p>
  <p class="seo-note"><strong>Correções publicadas depois dessa coleta:</strong> cinco recursos adicionais ficaram 24,0% menores em <a href="/portal/seo/?aba=fila&amp;site=roadrunners##RR-37">RR-37</a>; quatro títulos de edições e a codificação dos links de eventos foram corrigidos em <a href="/portal/seo/?aba=fila&amp;site=roadrunners##RR-38">RR-38</a>. Os destinos foram conferidos com HTTP 200 nos três idiomas. Os 39 erros acima continuam sendo o resultado medido; a baixa exige outro rastreamento. A sessão do Chrome ficou indisponível com o Mac bloqueado antes de iniciar a próxima rodada.</p>
  <p class="seo-note"><strong>Escopo e pendências:</strong> quatro títulos e seis descrições pertencem à <a href="https://store.roadrunners.run/roadrunnersstore/products" target="_blank" rel="noopener noreferrer">loja externa</a>, detalhada em <a href="/portal/seo/?aba=fila&amp;site=roadrunners##RR-36">RR-36</a>. Proteção de e-mail e login foram preservados. As quatro páginas lentas precisam de acompanhamento; uma resposta rápida pontual não encerra esse achado. As 47 páginas de maratonas receberam H1 em <a href="/portal/seo/?aba=fila&amp;site=roadrunners##RR-35">RR-35</a> durante o rastreamento, que pode ter lido parte da versão anterior.</p>
''' +v[end:]
v=v.replace('<th scope="col">05/10</th><th scope="col">06/10</th>','<th scope="col">Anterior</th><th scope="col">Atual</th>').replace('O comparativo de 06/10 acima apresenta o novo rastreamento.','O comparativo acima apresenta as duas últimas rodadas de 5.000 páginas.').replace('não foram atualizados pela auditoria técnica de 06/10','não foram atualizados pela auditoria técnica de 08/10')
(S/'candidate/business/portal/conteudo/seo_semrush.cfm').write_text(v)
(S/'import-receipt.json').write_text(json.dumps({'audit_date':audit['lastFinishedAt'],'health':75,'errors':39,'warnings':35227,'notices':5846,'organic_preserved':True,'keywords':len(snapshot['keywords']),'opportunities':len(snapshot['opportunities']),'queue_updatedAt':stamp,'queue_updatedLabel':label},indent=2))
print(json.dumps({'runtime_files':3,'audit':audit['lastFinishedLabel'],'organic_preserved':True,'deliveries':['RR-37','RR-38']}))
