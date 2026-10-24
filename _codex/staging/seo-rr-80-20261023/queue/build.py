from pathlib import Path
from datetime import datetime
from zoneinfo import ZoneInfo
import json,re,hashlib
S=Path(__file__).resolve().parent;n='portal/includes/seo_queue_data.cfm';old=(S/'baseline'/n).read_text()
now=datetime.now(ZoneInfo('America/Sao_Paulo'));v=old
v=re.sub(r'updatedAt = "[^"]+"','updatedAt = "'+now.isoformat(timespec='seconds')+'"',v,count=1)
v=re.sub(r'updatedLabel = "[^"]+"','updatedLabel = "'+now.strftime('%d/%m/%Y às %H:%M')+' (Brasília)"',v,count=1)
v=v.replace('Posição curada manualmente; última auditoria em _codex/docs/2026-10-03_seo_evidencias.md.','Fila curada manualmente; coletas e verificações têm datas próprias. Revisão atual em _codex/docs/2026-10-23_seo_semrush_5000.md.')
def cf(x):
 if isinstance(x,str):return '"'+x.replace('"','""').replace('#','##')+'"'
 if isinstance(x,bool):return 'true' if x else 'false'
 if isinstance(x,list):return '['+', '.join(cf(i) for i in x)+']'
 if isinstance(x,dict):return '{'+', '.join(k+' = '+cf(i) for k,i in x.items())+'}'
 raise TypeError(type(x))
def item(id,title,summary,evidence,acceptance,urls,resolved=True,rule='semrush.6',owner='RoadRunners'):
 return dict(resolved=resolved,id=id,sites=['roadrunners'],priority='p1',priorityLabel='P1 · SEO técnico',title=title,summary=summary,impact='Melhora a consistência e o acesso às páginas ativas; notas e indexação exigem medições próprias.',owner=owner,rule=rule,evidence=evidence,acceptance=acceptance,urls=[dict(url=u,label=l) for u,l in urls],stateLabel=('Publicado e verificado' if resolved else 'Pendente — investigado; sem nova publicação'))
items=[
 item('RR-40','Consolidar a URL duplicada da Corrida das Cores da Amazônia','A mesma prova tinha duas URLs em cada idioma. A auditoria de 22/10 às16:38 passou de seis para zero casos de conteúdo duplicado.',
 'Fonte oficial TicketSports87544 confirma a prova em ManausAM em28/03/2027. Somente tag_301 do cadastro46375 passou a apontar ao original44162. Datas e demais campos preservados, sem excluir ou unir fisicamente registros ou transferir vínculos. Baseline recuperável, ensaio de ida e volta em transação e serviço existente conferidos. Nove respostas301 em GET/HEAD e borda nos três idiomas; três destinos200 com metadados intactos. Sitemap real mantém três URLs originais e zero aliases.',
 'Publicado em22/10 e medido na coleta concluída às16:38: conteúdo duplicado6→0. O prefixo2026 da URL original não muda a data correta de28/03/2027.',
 [('https://roadrunners.run/evento/2026-corrida-das-cores-da-amazonia/','Cadastro original'),('https://roadrunners.run/evento/2027-corrida-das-cores-da-amazonia/','Alias301')],rule='semrush.7; semrush.6; canonical.alias'),
 item('RR-41','Preservar a identidade das provas nos títulos e descrições','Quatro provas distintas perdiam parte do nome no título; aspas no nome de Franco Verão deixavam a descrição vazia nos três idiomas.',
 'O título agora preserva o nome cadastrado completo e a data, reduzindo primeiro o rótulo opcional de modalidade. A descrição é codificada somente nos atributos HTML; texto do corpo e JSON-LD preservados. Cadastro público Business recebeu descrição. Noventa verificações Adobe de títulos e20 de metadados aprovadas, três templates compilados e respostas reais conferidas. Nenhum nome, data, tag ou cadastro alterado por este lote.',
 'Coleta de22/10 às16:38: títulos duplicados14→4 e descrições ausentes2→0. Os quatro títulos restantes eram da loja, desativada conforme informação do proprietário em23/10; RR-36 registra o encerramento dessa pendência.',
 [('https://roadrunners.run/evento/2026-trackfield-run-series-2025-sao-jose-do-rio-preto/','Track&Field São José do Rio Preto'),('https://roadrunners.run/evento/2026-trackfield-run-series-2025-shopping-vitoria-ii/','Track&Field Vitória')],rule='semrush.6; semrush.106; metadata.encoding',owner='RoadRunners / Business'),
 item('RR-42','Retirar o atalho de compra da loja desativada','O catálogo administrativo já mantinha a loja oculta; o fallback estático ainda oferecia o link no HTML inicial.',
 'O proprietário confirmou a desativação em23/10. O app7 já estava Oculto no catálogo real; nenhum registro precisou mudar. Foi retirado somente o item obsoleto de menu_apps_data.cfm, preservando os demais grupos, itens, textos, links, idiomas e ambientes. Trinta e seis verificações Adobe, um template compilado, cinco páginas200 com links da loja5→0 e metadados iguais. Menu conferido em desktop e390px, incluindo os oito apps ativos carregados sob demanda.',
 'Publicado e conferido em23/10. Nova auditoria de5.000 páginas iniciada depois da entrega; o resultado anterior continua75% até a conclusão real. Não houve alteração de configurações ou exclusão de checks no Semrush.',
 [('https://roadrunners.run/','Menu da home'),('https://roadrunners.run/estado/ba/','Menu do calendário')],rule='navigation.retired_product'),
 item('RR-43','Reduzir o custo de carregar as edições da São Silvestre','A coleta de22/10 às16:38 apontou cinco páginas lentas de edições da São Silvestre.',
 'A consulta de edições levou1,3–2,6s em fixture Adobe READ ONLY e cerca de1,8s no plano SQL. Uma alternativa preservou os resultados em34 cenários sintéticos e32 edições de quatro séries, mas não mostrou ganho de tempo e não foi publicada. As demais tentativas também ficaram fora de produção. O backend atual permanece preservado; não foi criado cache de atletas, índice ou estrutura no banco.',
 'Demonstrar redução consistente antes de publicar outra consulta. Preservar empates, PCD, classificação, homologação, conclusão, identidade e perfil público consultado ao vivo. Confirmar a baixa dos achados em auditoria comparável.',
 [('https://roadrunners.run/evento/2026-101-corrida-internacional-de-sao-silvestre/','São Silvestre2026'),('https://roadrunners.run/en/event/2015-91-corrida-internacional-de-sao-silvestre/','São Silvestre2015')],resolved=False,rule='semrush.111; performance.event_editions')
]
for x in items:assert f'id = "{x["id"]}"' not in old
v=v.replace('    items = [','    items = [\n        '+',\n        '.join(cf(x) for x in items)+',',1)
start=v.index('            id = "RR-36"');end=v.index('        },',start)
prefix=v[:start];block=v[start:end];suffix=v[end:]
before,marker,between=prefix.rpartition('resolved = false,')
assert marker and not between.strip(), 'Unexpected RR-36 status placement'
prefix=before+'resolved = true,'+between
changes={'title':'Encerrar a pendência da loja desativada','summary':'O proprietário confirmou em23/10 que a loja está desativada. Os quatro títulos e seis descrições duplicadas da coleta de22/10 permanecem no histórico medido; não são correções na plataforma externa.',
 'evidence':'A inspeção anterior confirmou que a loja é servida por plataforma externa. Em23/10 o proprietário confirmou sua desativação e a tela administrativa Runner Apps já mostrava o app7 Oculto. O fallback estático foi corrigido emRR-42 para não oferecer compra em um produto fora de operação. Nenhuma configuração da loja externa, DNS ou indexação foi alterada.',
 'acceptance':'Encerrada por desativação comercial confirmada, sem afirmar que os metadados externos foram corrigidos. Preservar os contadores da coleta histórica e medir o site ativo na nova auditoria com as mesmas configurações.',
 'stateLabel':'Encerrado — loja desativada; histórico preservado'}
for k,val in changes.items():
 block,count=re.subn(r'(?m)^(\s*'+k+r' = )"(?:""|[^"])*"',lambda m:m[1]+cf(val),block,count=1);assert count==1,k
v=prefix+block+suffix
p=S/'candidate'/n;p.write_text(v)
(S/'build.json').write_text(json.dumps(dict(new_ids=[x['id'] for x in items],changed_existing=['RR-36'],source_hash=hashlib.sha256(v.encode()).hexdigest(),updatedAt=now.isoformat(timespec='seconds')),ensure_ascii=False,indent=2))
print(json.dumps(dict(new_items=len(items),existing_changed=['RR-36'],updated=now.isoformat(timespec='seconds'))))
