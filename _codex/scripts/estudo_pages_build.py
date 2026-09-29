from pathlib import Path
import json,re,hashlib,sys,difflib
from estudo_pages_compare import load,toks,sha,D,RR
items=load();by={x['key']:x for x in items};reference=json.loads((D/'referencia_2025.json').read_text());live=json.loads((Path(__file__).resolve().parents[2]/'_codex/staging/estudo-paginas/estudo-pages-inspect.json').read_text())
BASE='https://business.roadrunners.run/estudo/'
PDF='https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf'
BOOK='pdf-2025-pages-v1'
sections=[]
def lit(s):return "'"+str(s).replace("'","''")+"'"
def block(f,n,family='datagrip'):return by[f'{family}:{f}.sql.txt:{n}']['sql'].strip().rstrip(';')
def source(f,n,family='datagrip'):return f'{family}:{f}.sql.txt:{n}'
def sec(page,title,notes):
 s={'page':page,'title':title,'key':f'pdf-2025-p{page:02d}','cells':[]};sections.append(s)
 md(s,'intro',f'## {title}\n\n'+notes)
 return s
def md(s,key,content):s['cells'].append({'key':s['key']+'-'+key,'type':'markdown','lang':'','content':content,'origin':{'tipo':'conciliacao_por_pagina','pagina_pdf':s['page'],'referencia_pdf':PDF,'data_registro':'2026-09-28'}})
def sql(s,key,title,query,notes,refs):
 md(s,key+'-nota','### '+title+'\n\n'+notes+'\n\n**Linhas de origem:** '+', '.join('`'+r+'`' for r in refs)+'.\n\nA saída representa a base atual no momento da execução; não é o snapshot usado no PDF.')
 s['cells'].append({'key':s['key']+'-'+key,'type':'code','lang':'sql','content':'-- '+title+'\n'+query.strip().rstrip(';')+';','origin':{'tipo':'consulta_conciliacao','pagina_pdf':s['page'],'fontes':refs,'regra':notes,'data_registro':'2026-09-28'},'title':title})
def ref(s):
 arr=[x for x in reference['series'] if x['pagina_pdf']==s['page']]
 txt='### Referência publicada — PDF v3.10.3\n\n[Consultar a página '+str(s['page'])+']('+PDF+'#page='+str(s['page'])+'). Valores transcritos; não foram recalculados.\n\n'
 for a in arr:
  txt+='**'+a['id']+'** ('+a['unidade']+')\n\n'
  txt+=' | '.join(str(v['rotulo'])+': **'+str(v['valor'])+'**' for v in a['valores'])+'\n\n'
  if a.get('ressalva'):txt+='Nota: '+a['ressalva']+'\n\n'
 md(s,'pdf',txt)
def src_links(ids):
 return '; '.join(f'[{next(n["notebook_title"] for n in live["sections"] if n["notebook_id"]==i)}]({BASE}?caderno=1&secao={i})' for i in ids)
def combine(queries,select):
 return 'WITH '+',\n'.join(f'q{i} AS (\n{q}\n)' for i,(label,q) in enumerate(queries))+ '\n'+'\nUNION ALL\n'.join(f'SELECT {lit(label)} AS versao, {select} FROM q{i}' for i,(label,q) in enumerate(queries))
intro=sec(0,'Comece aqui — mapa das páginas', '''Este é o caderno de trabalho para reproduzir o PDF de 2025. Cada seção corresponde a uma página analítica (3–15). As páginas 1, 2 e 16 são capa, metodologia e encerramento; estão referenciadas aqui.

**Como trabalhar:** leia a comparação das fontes, execute uma célula SQL e congele a saída com uma nota sobre os filtros. A tabela gerada substitui a colagem de HTML. Os HTMLs antigos permanecem no caderno original como evidência histórica, pois não comprovam qual query foi executada.

**Prioridade das fontes (informação do responsável, 28/09/2026):** vw_resultados foi criada depois para tratar/consolidar os dados e provavelmente embasou o estudo. Portanto, as queries DataGrip/DBA que a usam são candidatas prioritárias; o editor bruto é comparação histórica. A definição atual da view aplica status_final=0/homologado=true sobre a tabela viva. Sua criação posterior não recupera, sozinha, o estado da base na publicação.

**Três referências distintas:** PDF = o que foi publicado; editor/DataGrip/DBA = regras candidatas; execução atual = resultado da regra hoje. Coincidência após arredondamento não certifica a linhagem histórica. Temos apenas a base atual.

**Metodologia publicada (p.2):** Brasil, 2025, homens e mulheres, 14+ anos. Vários SQLs não implementam todos esses filtros. As diferenças ficam visíveis; não foram harmonizadas silenciosamente.

[PDF completo]('''+PDF+''') · [Acervo migrado]('''+BASE+'''?caderno=1) · [Arquivos DBA/DataGrip]('''+BASE+'''?caderno=2)

**Pendências para fechar 2025:** denominador dos 84,1%; fronteiras de idade/geração; localização capital/interior; regra das estações; critérios de tempos/pódio; dez cards do perfil. As seções explicam exatamente o que falta.''')
p3=sec(3,'P03 — Panorama, volume e gênero', '''**Editor:** '''+src_links([1,2])+'''. Usa tb_resultados sem homologação/status/concluinte. HTML 65 registra 5.545.343; HTML 71 registra F=2.918.372, M=2.601.046, X=2.134 (soma 5.521.552). Nem esses dois resultados colados têm o mesmo total.

**DataGrip:** INFOGRAFICO, blocos 1–4. Usa vw_resultados (status_final=0 e homologado=true); gênero 2025 ainda exige tempo positivo. A versão BI usa outra população.

**DBA:** estudo_treinos anota 9.245 eventos de rua/trail; DOCX F+M=5.101.962 e 52,9% F, compatível com a view BI na coleta de 27/09. Isso não prova que a BI gerou todo o PDF.

**Decisão:** manter as três populações identificadas. A cobertura de 84,1% não tem regra recuperada. O diagnóstico de eventos abaixo usa presença de resultados e não substitui aquele percentual.''')
q=[]
for label,n,fam,f in [('Editor 2025',1,'editor','02_genero'),('DataGrip 2025 (tempo positivo)',2,'datagrip','INFOGRAFICO'),('BI 2025 (fonte DBA)',3,'datagrip','INFOGRAFICO'),('Editor 2024',2,'editor','02_genero'),('DataGrip 2024',4,'datagrip','INFOGRAFICO')]:q.append((label,block(f,n,fam)))
sql(p3,'genero','Gênero — comparar editor, DataGrip e BI',combine(q,'genero,total,porcentagem'),'Reproduz cada variante sem igualar os filtros; o denominador inclui todos os sexos presentes em cada consulta.',[source('02_genero',1,'editor'),source('INFOGRAFICO',2),source('INFOGRAFICO',3),source('INFOGRAFICO',4)])
sql(p3,'total','Total de linhas — editor versus DataGrip',combine([('Editor',block('01_escopo_infograficos',1,'editor')),('DataGrip',block('INFOGRAFICO',1))],'count AS total'),'As fontes chamam a medida de concluintes, mas nenhuma exige concluinte=true. A saída conta linhas de resultados, não atletas únicos.',[source('01_escopo_infograficos',1,'editor'),source('INFOGRAFICO',1)])
sql(p3,'eventos','Eventos cadastrados e eventos com resultados',"""WITH eventos AS (
 SELECT id_evento,extract(year FROM data_final)::integer AS ano
 FROM public.tb_evento_corridas
 WHERE pais='BR' AND tipo_corrida IN ('rua','trail')
 AND data_final>=DATE '2024-01-01' AND data_final<DATE '2026-01-01'
), presenca AS (
 SELECT r.id_evento,count(*) AS linhas,
 count(*) FILTER (WHERE r.status_final=0 AND r.homologado IS TRUE) AS linhas_view
 FROM public.tb_resultados r JOIN eventos e ON e.id_evento=r.id_evento GROUP BY r.id_evento
)
SELECT e.ano,count(*) AS eventos_cadastrados,
 count(*) FILTER(WHERE p.linhas>0) AS eventos_com_resultados_brutos,
 count(*) FILTER(WHERE p.linhas_view>0) AS eventos_com_resultados_view,
 round(count(*) FILTER(WHERE p.linhas>0)*100.0/nullif(count(*),0),2) AS cobertura_bruta_pct
FROM eventos e LEFT JOIN presenca p ON p.id_evento=e.id_evento GROUP BY e.ano ORDER BY e.ano""",'Diagnóstico novo: BR, rua/trail e data final de cada ano; inclui cadastros sem resultado e sem filtro de ativo/status do evento. Presença de uma linha não garante coleta completa. Não é a fórmula histórica dos 84,1%.',['dba:estudo_treinos.sql.txt:calendario','diagnostico_novo_cobertura'])
ref(p3)
p4=sec(4,'P04 — Faixas etárias', '''**Editor:** '''+src_links([3])+'''. Tabela bruta, faixas por sobreposição (&&), geral; também inclui 40+/50+/60+. Primeiro grupo começa em 13.

**DataGrip:** INFOGRAFICO, blocos 5–9. View filtrada; o bloco de faixas está fixo em M e arredonda a uma casa. O HTML 72 mostra 13–19 = 3,48% geral, enquanto o PDF rotula 14–19 = 6,7%.

**DBA/BI:** a carga atribui uma categoria por função, com prioridade entre ranges; não é a mesma regra da sobreposição múltipla.

**Decisão:** a consulta abaixo separa população e sexo, preservando a regra histórica. Um mesmo intervalo pode entrar em várias faixas; percentuais somam 100% das associações, não de pessoas únicas. Corrigir para idades exclusivas exige uma nova metodologia.''')
faixas=block('03_faixa_etaria',4,'editor')
variants=[]
for family,table in [('Editor','tb_resultados'),('DataGrip','vw_resultados')]:
 for sexo in ['geral','F','M']:
  v=faixas.replace('FROM tb_resultados a',f'FROM {table} a')
  v=v.replace("--WHERE a.sexo = 'M'",'' if sexo=='geral' else f"WHERE a.sexo = '{sexo}'")
  variants.append((family+' / '+sexo,v))
sql(p4,'faixas','Idades — duas fontes, geral e por sexo',combine(variants,'faixa,total,porcentagem'),'Derivação explícita do bloco do editor: executa geral/F/M em tb_resultados e vw_resultados, mantendo 13–19, sobreposição e duas casas para comparar. As repetições por fonte/sexo são intencionais.',[source('03_faixa_etaria',4,'editor'),source('INFOGRAFICO',9)])
ref(p4)
p5=sec(5,'P05 — Gerações e comparações anuais', '''**Editor:** nenhuma seção de gerações recuperada.

**DataGrip:** INFOGRAFICO, blocos 10–12; 2025 está em F, 2024 em M e 2023 geral. Os ranges deixam lacunas e não representam limites inclusivos iguais aos rótulos do PDF.

**DBA/BI:** possui id_geracao e uma função baseada em ano de nascimento estimado a partir do intervalo de idade. A função usa prioridade de correspondência e devolve zero para Alfa/não classificado. Essa regra difere das faixas fixas do DataGrip.

**Decisão:** executar as variantes históricas exatamente como salvas; a tabela BI é uma alternativa identificada, não uma substituição automática. Os percentuais comparativos do PDF exigem o mesmo sexo e regras equivalentes nos três anos.''')
sql(p5,'historico','Gerações — variantes históricas disponíveis',combine([(f'DataGrip {year} / {sex}',block('INFOGRAFICO',n)) for year,sex,n in [(2025,'F',10),(2024,'M',11),(2023,'geral',12)]],'faixa,total,porcentagem'),'Preserva os filtros salvos F/2025, M/2024 e geral/2023; não interpretar essa saída como evolução anual de uma população comum.',[source('INFOGRAFICO',n) for n in [10,11,12]])
sql(p5,'bi','Gerações — população da view BI 2025',"""SELECT nome_geracao,coalesce(sexo,'N/A') AS sexo,count(*) AS total,
round(count(*)*100.0/nullif(sum(count(*)) OVER(PARTITION BY sexo),0),2) AS percentual_dentro_sexo
FROM public.vwbi_fat_perfil_br_2025 GROUP BY nome_geracao,sexo ORDER BY sexo,total DESC""",'Consulta nova sobre a view BI cuja carga veio do DBA. Usa a classificação existente e explicita a população BI; não deduz idade exata do intervalo.',['dba:script_perfil_br_corre_2025.sql.txt','dba:script_perfil_2025_segundo_semestre.txt.txt'])
ref(p5)
p6=sec(6,'P06 — Distâncias e participação por sexo', '''**Editor:** '''+src_links([4,5,6])+'''. Uma consulta está intitulada RUA, mas filtra trail; o agrupamento padrão de rua usa valores exatos de percurso e tb_resultados.

**DataGrip/DBA:** seis blocos de distâncias são iguais após retirar comentários/espaços; usam vw_resultados. DataGrip também traz recortes adicionais por sexo/UF/geração. Não confundir count(distinct evento) somado por faixa com total de eventos únicos: uma prova pode oferecer várias distâncias.

**Decisão:** conservar a diferença entre detalhe (floor), faixas e distâncias padrão. O diagnóstico de presença de 5 km usa um denominador de eventos únicos explícito.''')
sql(p6,'detalhe','Distâncias detalhadas — DataGrip/DBA',block('INFOGRAFICO_DISTANCIAS',1),'Consulta original comum ao DataGrip e DBA: rua, vw_resultados, floor(percurso). Não equivale aos buckets por valores exatos do editor.',[source('INFOGRAFICO_DISTANCIAS',1),source('INFOGRAFICO_DISTANCIAS',1,'dba')])
sql(p6,'padrao','Distâncias padrão — editor versus DataGrip',combine([('Editor',block('05_distancias',2,'editor')),('DataGrip / DBA',block('INFOGRAFICO_DISTANCIAS',2))],'percurso,total,perc'),'Mantém os buckets e arredondamentos originais: editor duas casas, DataGrip uma. A principal diferença de população é tabela bruta versus view.',[source('05_distancias',2,'editor'),source('INFOGRAFICO_DISTANCIAS',2)])
sql(p6,'faixas','Faixas de distância — geral e por sexo',combine([('Geral',block('INFOGRAFICO_DISTANCIAS',4)),('Dentro do sexo',block('INFOGRAFICO_DISTANCIAS',7))],'*'),'Blocos originais têm colunas diferentes; executados em células separadas abaixo.',[]) if False else None
sql(p6,'faixas','Faixas de distância — população geral',block('INFOGRAFICO_DISTANCIAS',4),'Bloco original: os intervalos deixam eventuais frações entre 10,99 e 11 / 29,99 e 30 como Outras. Mantido para reprodução.',[source('INFOGRAFICO_DISTANCIAS',4),source('INFOGRAFICO_DISTANCIAS',4,'dba')])
sql(p6,'sexo','Distância dentro do sexo — denominador revisado',block('INFOGRAFICO_DISTANCIAS',7).replace('SUM(total) OVER ()','SUM(total) OVER (PARTITION BY sexo)'), 'Revisão explícita do bloco DataGrip: o original divide pelo total F+M de todas as distâncias. Para confrontar o gráfico dentro de cada sexo, acrescenta PARTITION BY sexo. Conta participações, apesar do título original mencionar provas.',[source('INFOGRAFICO_DISTANCIAS',7)])
sql(p6,'presenca','Presença de 5 km nos eventos com resultados',"""SELECT count(DISTINCT evt.id_evento) AS eventos_com_resultados_rua,
 count(DISTINCT evt.id_evento) FILTER(WHERE res.percurso=5) AS eventos_com_5km,
 round(count(DISTINCT evt.id_evento) FILTER(WHERE res.percurso=5)*100.0/nullif(count(DISTINCT evt.id_evento),0),2) AS percentual
FROM public.vw_resultados res JOIN public.tb_evento_corridas evt ON evt.id_evento=res.id_evento
WHERE evt.pais='BR' AND evt.tipo_corrida='rua'
AND evt.data_final BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'""",'Derivação do bloco de eventos por distância. Denominador revisto: eventos únicos com resultados de rua; não soma eventos repetidos em vários buckets. Comparar ao 74,6% sem presumir a fórmula histórica.',[source('INFOGRAFICO_DISTANCIAS',3)])
ref(p6)
p7=sec(7,'P07 — Gerações nas distâncias', '''**Editor:** não há SQL equivalente recuperado.

**DataGrip:** INFOGRAFICO_DISTANCIAS, blocos 9–10; os mesmos totais têm dois denominadores: geração dentro da distância e distância dentro da geração.

**DBA:** o arquivo de distâncias não contém esses dois blocos; a carga BI registra dimensões relacionadas, com outra população.

**Decisão:** a consulta abaixo reproduz a função get_id_geracao com CASE, conforme definição inspecionada em produção em 28/09/2026. A função não foi habilitada nem alterada no banco. Preserva ordem de prioridade e exclusão de zero; Alfa não aparece nos quatro grupos desta página.''')
fun=live['definitions']['get_id_geracao'].replace('\r\n','\n');expr=fun.split('SELECT',1)[1].split(';',1)[0].strip().replace('p_faixa_idade','res.idade_range').replace('p_ano_referencia','2025')
qs=[]
for n,label in [(9,'Geração dentro da distância'),(10,'Distância dentro da geração')]:
 q=block('INFOGRAFICO_DISTANCIAS',n).replace('get_id_geracao(res.idade_range,EXTRACT(YEAR FROM evt.data_final)::int)', '('+expr+')')
 qs.append((label,q))
sql(p7,'geracoes','Gerações × distâncias — os dois denominadores',combine(qs,'geracao,percurso,total,perc'),'Única adaptação funcional: a função SQL foi expandida literalmente como CASE. Demais filtros, denominadores e arredondamento preservados.',[source('INFOGRAFICO_DISTANCIAS',9),source('INFOGRAFICO_DISTANCIAS',10),'public.get_id_geracao:2026-09-28'])
ref(p7)
p8=sec(8,'P08 — Ritmo e performance', '''**Editor:** '''+src_links([12,13])+''', população bruta geral. HTML 81: faixa 5 km / 30+ = 75,25%; PDF = 73,5%. Não são saídas idênticas.

**DataGrip:** quatro blocos de tempo fixam F ou M. **DBA:** os mesmos quatro blocos não filtram sexo; os outros seis blocos de distâncias coincidem com DataGrip.

**Decisão:** comparar geral/F/M sem ocultar fonte. Fronteiras <= são preservadas apesar do rótulo “sub”; tempo nulo vai para a última faixa e zero para a primeira. Corrigir tempos inválidos será outra revisão, pois altera a metodologia.''')
q=[]
for n,dist in enumerate(['5k','10k','21k','42k'],1):
 for family in ['editor','dba']:
  txt=block('12_faixas_de_tempo' if family=='editor' else 'INFOGRAFICO_DISTANCIAS',n if family=='editor' else n+6,family)
  q.append((family+' / '+dist,txt))
sql(p8,'tempos','Performance — comparar editor com DBA',combine(q,'percurso,total,perc'),'Reprodução dos quatro blocos gerais em cada fonte. Tabela bruta no editor; view com homologação/status no DBA. Sem normalização de tempos nulos/zero.',[source('12_faixas_de_tempo',n,'editor') for n in range(1,5)]+[source('INFOGRAFICO_DISTANCIAS',n,'dba') for n in range(7,11)])
q=[('DataGrip / '+dist+' / '+re.search(r"(?m)^\s*AND res.sexo = '([FM])'",block('INFOGRAFICO_DISTANCIAS',n+10)).group(1),block('INFOGRAFICO_DISTANCIAS',n+10)) for n,dist in enumerate(['5k','10k','21k','42k'],1)]
sql(p8,'sexo','Performance — filtros por sexo salvos no DataGrip',combine(q,'percurso,total,perc'),'Mantém literalmente o sexo fixado em cada bloco DataGrip; conferir o WHERE antes de usar como série F ou M.',[source('INFOGRAFICO_DISTANCIAS',n) for n in range(11,15)])
ref(p8)
p9=sec(9,'P09 — Regiões e gênero', '''**Editor:** '''+src_links([7])+'''. O segundo bloco seleciona uf.uf como regiao; o HTML 75 contém SE/NE/S/CO/N. O HTML foi atualizado em 30/01 e o SQL em 01/02/2026: vínculo de execução não comprovado.

**DataGrip:** INFOGRAFICO, bloco 15, usa uf.regiao corretamente, mas está fixo em 2024/M.

**DBA:** cruza cidade por nome sem UF e pode perder/multiplicar linhas. O bloco chamado capital/interior também contém sexo por região; não é equivalente ao agrupamento direto pela UF do evento.

**Decisão:** derivar de DataGrip com ano/sexo explícitos. A correção do bloco do editor é uf.uf → uf.regiao, registrada como derivação; o original não foi sobrescrito.''')
q=[]
for year in [2024,2025]:
 for sex in ['geral','F','M']:
  txt=block('INFOGRAFICO',15).replace('2024-',str(year)+'-').replace("AND res.sexo = 'M'",'' if sex=='geral' else f"AND res.sexo = '{sex}'")
  q.append((str(year)+' / '+sex,txt))
sql(p9,'regioes','Regiões — 2024/2025, geral/F/M',combine(q,'regiao,total,porcentagem'),'Derivação explícita do bloco DataGrip: seis recortes com os mesmos filtros de resultado. Percentual da região dentro do sexo/ano; não confundir com participação F/M dentro de cada região.',[source('INFOGRAFICO',15),source('07_ufs',2,'editor')])
ref(p9)
p10=sec(10,'P10 — Estados, cidades e capital/interior', '''**Editor:** '''+src_links([7,8])+'''; estados vêm diretamente de evt.estado, sem cruzar cidades. **DataGrip:** INFOGRAFICO, blocos 13–14; cidades são agrupadas apenas por nome, reunindo homônimas de UFs diferentes.

**DBA:** regiao_capital_interior é uma fonte candidata, mas o primeiro SELECT usa uma coluna total inexistente e divide pelo total nacional. O relacionamento nome_cidade=evt.cidade não usa UF. Auditoria de 27/09: 434.079 participações sem correspondência; 381.706 linhas ligadas a outra UF. Esses efeitos pertencem àquela regra/população, não ao PDF inteiro.

**Decisão:** estados são comparáveis por fonte; cidades ganham UF na consulta candidata. Capital/interior abaixo usa id_localidade já presente na fato BI e contabiliza ausentes; tem população diferente e não certifica o gráfico histórico. O percentual é exibido dentro de cada região e com não classificados visíveis.''')
sql(p10,'ufs','Estados — editor versus DataGrip',combine([('Editor',block('07_ufs',1,'editor')),('DataGrip',block('INFOGRAFICO',13))],'estado,total,porcentagem'),'Consulta original em cada fonte. A diferença de status/homologação permanece visível.',[source('07_ufs',1,'editor'),source('INFOGRAFICO',13)])
sql(p10,'cidades','Cidades com UF — candidato revisado',"""SELECT coalesce(upper(btrim(evt.estado)),'N/A') AS uf,
 coalesce(upper(btrim(evt.cidade)),'N/A') AS cidade,count(*) AS total,
 round(count(*)*100.0/nullif(sum(count(*)) OVER(),0),2) AS percentual
FROM public.vw_resultados res JOIN public.tb_evento_corridas evt ON evt.id_evento=res.id_evento
WHERE evt.pais='BR' AND evt.data_final BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
GROUP BY upper(btrim(evt.estado)),upper(btrim(evt.cidade)) ORDER BY total DESC LIMIT 50""",'Nova revisão baseada no bloco DataGrip: acrescenta UF, normaliza apenas caixa/espaços e mantém acentos distintos. Top 50 para revisão; percentual usa todas as cidades antes do LIMIT. Ainda não é a normalização definitiva por ID de localidade.',[source('INFOGRAFICO',14)])
sql(p10,'capital','Capital/interior — candidato pelo ID da fato BI',"""WITH contagens AS (
 SELECT coalesce(l.regiao,'Não classificada') AS regiao,
 CASE WHEN l.capital IS TRUE THEN 'Capital' WHEN l.capital IS FALSE THEN 'Interior' ELSE 'Não classificada' END AS tipo,
 count(*) AS total
 FROM public.tbbi_fat_perfil_br_2025 f LEFT JOIN public.tbbi_dim_localidade l ON l.id_localidade=f.id_localidade
 WHERE f.data_evento>=DATE '2025-01-01' AND f.data_evento<DATE '2026-01-01'
 GROUP BY coalesce(l.regiao,'Não classificada'),l.capital
)
SELECT regiao,tipo,total,
 round(total*100.0/nullif(sum(total) OVER(PARTITION BY regiao),0),2) AS percentual_dentro_regiao,
 round(total*100.0/nullif(sum(total) OVER(),0),2) AS percentual_nacional
FROM contagens ORDER BY regiao,tipo""",'Nova metodologia candidata: LEFT JOIN pelo id_localidade da fato; preserva registros sem dimensão. Mede participações da fato BI, não da view BI nem a população bruta do editor. Não usar para substituir silenciosamente 2025.',['dba:regiao_capital_interior.sql.txt','dba:script_perfil_br_corre_2025.sql.txt'])
ref(p10)
p11=sec(11,'P11 — Calendário, trimestres e estações', '''**Editor:** '''+src_links([9,10])+'''. Consultas coladas sem separador em alguns pontos; meses ordenados por volume. O HTML 79 mostra apenas dez meses (janeiro e fevereiro ausentes na tabela mensal), embora os trimestres cubram o ano.

**DataGrip:** INFOGRAFICO, blocos 16–17, usa view e mês numérico. **DBA:** o DOCX tem 24 contagens mensais F/M iguais à view BI na coleta de 27/09.

**Decisão:** usar tabelas de 12 meses em ordem para confronto. O denominador dos “top 3/5 meses” no editor é só a seleção, portanto soma 100% e não mede sua participação no ano. A regra de estações não foi localizada: não converter trimestres em estações por suposição.''')
# Output unified month/quarter with separate source populations in one current scan.
sql(p11,'calendario','Calendário — editor versus DataGrip',"""WITH base AS (
 SELECT extract(month FROM e.data_final)::integer AS mes,extract(quarter FROM e.data_final)::integer AS trimestre,
 count(*) AS editor,count(*) FILTER(WHERE r.status_final=0 AND r.homologado IS TRUE) AS datagrip
 FROM public.tb_resultados r JOIN public.tb_evento_corridas e ON e.id_evento=r.id_evento
 WHERE e.pais='BR' AND e.data_final BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
 GROUP BY extract(month FROM e.data_final),extract(quarter FROM e.data_final)
), recortes AS (
 SELECT 'Mês' AS periodo,mes AS ordem,'Editor' AS versao,editor AS total FROM base
 UNION ALL SELECT 'Mês',mes,'DataGrip',datagrip FROM base
 UNION ALL SELECT 'Trimestre',trimestre,'Editor',sum(editor) FROM base GROUP BY trimestre
 UNION ALL SELECT 'Trimestre',trimestre,'DataGrip',sum(datagrip) FROM base GROUP BY trimestre
)
SELECT periodo,ordem,versao,total,round(total*100.0/nullif(sum(total) OVER(PARTITION BY periodo,versao),0),2) AS percentual
FROM recortes ORDER BY periodo,ordem,versao""",'Derivação para confronto em uma leitura: repete a definição inspecionada de vw_resultados como filtro e preserva o denominador anual; ordem cronológica e aliases uniformizados.',[source('09_conclusoes_por_mes',1,'editor'),source('09_conclusoes_por_mes',2,'editor'),source('INFOGRAFICO',16),source('INFOGRAFICO',17)])
ref(p11)
# Shared marathon CTE adapted only the final output and interval construction to standard allowed expressions.
raw=(RR/'_codex/sql/brasil_que_corre_provas/05_maratonas_legado_2025.sql').read_text().split('-- QUERY_START')[1].split('-- QUERY_END')[0]
mar=raw.split('SELECT jsonb_build_object(',1)[0].replace(' AS MATERIALIZED (',' AS (')
mar=mar.replace("make_interval(secs=>avg(extract(epoch FROM tempo_total))::double precision)","(avg(extract(epoch FROM tempo_total))::double precision * INTERVAL '1 second')").replace("make_interval(secs=>percentile_cont(0.5) WITHIN GROUP(ORDER BY extract(epoch FROM tempo_total)))","(percentile_cont(0.5) WITHIN GROUP(ORDER BY extract(epoch FROM tempo_total)) * INTERVAL '1 second')")
p12=sec(12,'P12 — Top maratonas e tempos', '''**Editor:** '''+src_links([11])+''' usa tb_resultados_resumo_2025, evento homologado, ranking='true', data inicial e exclusões por texto de modalidade. HTML 77 está vazio.

**DataGrip:** INFOGRAFICO_MARATONAS: primeiro bloco usa vw_resultados, PCD=false, rua, data final e 42–42,2 km; outros blocos usam dez IDs fixos, limites e filtros distintos. Há também UPDATE de pace, mantido apenas como fonte, sem execução.

**DBA:** estudo_treinos tem explorações de maratonas femininas, não a regra completa deste ranking.

**Decisão:** o candidato abaixo usa o primeiro bloco DataGrip e mostra tanto o top 10 recalculado quanto a seleção de IDs legada. Resultados com tempo zero/nulo são contados explicitamente. Isso não resolve sozinho a regra de média/mediana/pódio do PDF.''')
sql(p12,'ranking','Maratonas — top atual e seleção legada',mar+"""SELECT posicao,id_evento,nome_evento,concluintes,feminino,masculino,
 round(feminino*100.0/nullif(concluintes,0),2) AS feminino_pct,
 tempo_ausente_ou_zero,tempo_minimo,tempo_medio,tempo_mediano,
 posicao<=10 AS top10_atual,
 id_evento IN(24999,24998,26867,22792,22582,27104,28253,22590,25481,24016) AS selecao_legada
FROM ranking WHERE posicao<=10 OR id_evento IN(24999,24998,26867,22792,22582,27104,28253,22590,25481,24016)
ORDER BY posicao""",'Derivação do primeiro bloco DataGrip com filtros preservados, ranking por volume, percentuais e tempos agregados. A regra do editor e o SQL extenso de limites permanecem referências distintas.',[source('INFOGRAFICO_MARATONAS',1),'reconciliacao:05_maratonas_legado_2025.sql'])
ref(p12)
p13=sec(13,'P13 — Maratonas rápidas e pódio', '''**Editor:** '''+src_links([11,13])+''' traz resumos por sexo e destaques gerais; não reconstitui sozinho o quadro de medalhas.

**DataGrip:** os blocos longos de maratonas usam seleção fixa, exclusões por texto, limites por evento e percentis; não equivalem ao primeiro ranking. Há diferenças entre menor tempo, média, mediana e grupos percentuais. “Sub” no quadro desta página é estritamente menor, enquanto outros blocos usam <=.

**Decisão:** preservar os dez IDs como referência identificada e recalcular os limites <4h/<3h/<2h30 na população do primeiro bloco, deixando essa derivação explícita. A classificação de pódio e a tabela top10/top100/5%/10%/50% ainda exigem conciliar o SQL extenso, não foram reconstruídas por aproximação.''')
sql(p13,'limites','Maratonas — faixas sub4/sub3/sub2h30',mar+"""SELECT posicao,id_evento,nome_evento,concluintes,sub4,round(sub4*100.0/nullif(concluintes,0),2) AS sub4_pct,
sub3,round(sub3*100.0/nullif(concluintes,0),2) AS sub3_pct,
sub2h30,round(sub2h30*100.0/nullif(concluintes,0),2) AS sub2h30_pct,tempo_ausente_ou_zero
FROM ranking WHERE id_evento IN(24999,24998,26867,22792,22582,27104,28253,22590,25481,24016) ORDER BY posicao""",'Seleção fixa legada, população do primeiro bloco DataGrip, limites estritos (<). Zero entra como abaixo do limite e é sinalizado; não corrigido silenciosamente.',[source('INFOGRAFICO_MARATONAS',1),source('INFOGRAFICO_MARATONAS',2)])
ref(p13)
p14=sec(14,'P14 — Faixas Corrida no Ar', '''**Editor:** a seção chamada “Faixas de tempo” corresponde à performance da p.8, não às oito faixas CNA.

**DataGrip:** INFOGRAFICO_COLAB_CNA, blocos 1–4, contém as quatro distâncias e oito faixas. **DBA:** não enviou equivalente CNA separado.

**Decisão:** separar este capítulo da performance. CNA exige PCD=false e ranking nulo/diferente de false; não exige tipo_corrida='rua'. Limites usam <; nulos vão à faixa branca e zero à mestre. São distribuições de participações, não transições individuais entre faixas.''')
sql(p14,'cna','CNA — quatro distâncias',combine([(d,block('INFOGRAFICO_COLAB_CNA',i)) for i,d in enumerate(['5k','10k','21k','42k'],1)],'faixa_tempo,total,porcentagem'),'Blocos originais DataGrip unidos com identificador de distância; filtros e fronteiras preservados.',[source('INFOGRAFICO_COLAB_CNA',n) for n in range(1,5)])
ref(p14)
p15=sec(15,'P15 — Perfil e outros esportes', '''**Editor:** não foram recuperadas células desta página.

**DataGrip:** INFOGRAFICO_USUARIO contém agregações de atividades por esporte; não recupera os dez cards do perfil. Algumas explorações mensais não filtram ano. INFOGRAFICO_PERSONAS analisa poucos atletas selecionados e não representa a plataforma; não foi promovido a consulta nacional.

**DBA:** a view de treinos se relaciona ao Desafio 365; os 2.231 usuários anotados são uma amostra selecionada. Não é uma fonte automática para os dez cards.

**Decisão:** executar apenas esportes com filtro 2025. A saída mede atividades importadas, não percentual de usuários. Mapeamento de rótulos (fortalecimento etc.) e denominador do gráfico precisam ser confirmados. Os dez cards ficam marcados como fonte pendente, sem números fabricados.''')
sql(p15,'esportes','Atividades por esporte — candidato DataGrip',block('INFOGRAFICO_USUARIO',1),'Consulta original: activity_date em 2025 e type não nulo. Inclui corrida no denominador, não filtra exclusões do Strava. Atribuição dos rótulos do PDF pendente.',[source('INFOGRAFICO_USUARIO',1)])
ref(p15)
extra=sec(99,'Apoio — qualidade, fontes e pendências', '''As fontes completas continuam no caderno “Fontes e conciliação — 2025”. Estes tópicos não foram forçados para dentro de uma página do PDF:

- INFOGRAFICO_MERCADO: nove blocos sobre sites, equipes e organizadores. O PDF desta versão não publica um capítulo de fornecedores.
- INFOGRAFICO_INUTEIS: distâncias quebradas/padrão, diagnóstico auxiliar.
- INFOGRAFICO_PERSONAS: exploração de indivíduos selecionados, não amostra nacional; nenhuma saída pessoal foi coletada aqui.
- DBA: DDL, INSERTs e GRANTs são somente fonte. Não há carga de janeiro/março/abril no pacote; sua presença na fato não recupera os scripts faltantes.
- Editor “Taxa de completude”: preenchimento dos campos, não cobertura de provas. Faltam separadores entre os dois últimos blocos SQL; separar as consultas antes de executar. Isso não comprova que as tabelas HTML tenham sido geradas exatamente pela revisão salva.

**HTML histórico:** conservado no caderno original com seus IDs. Este novo caderno usa tabelas de execuções; não requer HTML colado. Executar novamente produz nova observação, nunca atualiza um congelamento anterior.

**Próxima revisão metodológica:** decidir a população comum de 2025/2026, fronteiras exclusivas de idade/tempo, qualidade de localidades e denominadores. A web ainda não consome automaticamente estas execuções.''')
sql(extra,'qualidade','População bruta e qualidade dos campos em 2025',"""SELECT count(*) AS linhas_brutas,
 count(*) FILTER(WHERE r.status_final=0 AND r.homologado IS TRUE) AS linhas_vw_resultados,
 count(*) FILTER(WHERE r.concluinte IS TRUE) AS sinalizadas_concluintes,
 count(*) FILTER(WHERE r.idade_range IS NULL) AS idade_ausente,
 count(*) FILTER(WHERE r.tempo_total IS NULL) AS tempo_nulo,
 count(*) FILTER(WHERE r.tempo_total=TIME '00:00:00') AS tempo_zero,
 count(*) FILTER(WHERE r.sexo IS NULL OR btrim(r.sexo)='') AS sexo_ausente
FROM public.tb_resultados r JOIN public.tb_evento_corridas e ON e.id_evento=r.id_evento
WHERE e.pais='BR' AND e.data_final BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'""",'Diagnóstico novo, uma linha por resultado bruto de evento BR em 2025. As categorias se sobrepõem; não somar ausências como participantes únicos.',[source('14_taxa_de_completude',1,'editor'),'definicao_public.vw_resultados:2026-09-28'])
# A navigable page map is resolved to actual IDs by the import SQL, avoiding guessed links.
page_rows='| Página | Assunto | Situação |\n|---|---|---|\n'+ '\n'.join(f'| {s["page"]} | {s["title"].split(" — ",1)[-1]} | Consultas candidatas e diferenças registradas |' for s in sections if 3<=s['page']<=15)
md(intro,'mapa',page_rows+'\n\nEscolha a página no seletor Seção. Os resultados ficam em “Execuções e congelados”.')
# Explicit SQL comparison matrix; matching never relies only on fuzzy text similarity.
pairs=[('01_escopo_infograficos',1,'INFOGRAFICO',1),('02_genero',1,'INFOGRAFICO',2),('02_genero',2,'INFOGRAFICO',4),('03_faixa_etaria',4,'INFOGRAFICO',9),('05_distancias',2,'INFOGRAFICO_DISTANCIAS',2),('07_ufs',1,'INFOGRAFICO',13),('07_ufs',2,'INFOGRAFICO',15),('09_conclusoes_por_mes',1,'INFOGRAFICO',16),('09_conclusoes_por_mes',2,'INFOGRAFICO',17)]+[('12_faixas_de_tempo',n,'INFOGRAFICO_DISTANCIAS',n+10) for n in range(1,5)]
comparison=[]
for ef,en,df,dn in pairs:
 a=by[source(ef,en,'editor')];b=by[source(df,dn)]
 equal=a['tokens']==b['tokens'];tableonly=['vw_resultados' if t=='tb_resultados' else t for t in a['tokens']]==b['tokens']
 comparison.append({'editor':a['key'],'datagrip':b['key'],'classificacao':'igual' if equal else 'somente_tabela_vs_view' if tableonly else 'filtros_ou_estrutura_diferentes','diff':'\n'.join(difflib.unified_diff(a['sql'].splitlines(),b['sql'].splitlines(),fromfile=a['key'],tofile=b['key'],n=2))})
for a in [x for x in items if x['family']=='dba' and x['file']=='INFOGRAFICO_DISTANCIAS.sql.txt']:
 candidates=[b for b in items if b['family']=='datagrip' and b['file']==a['file'] and b['title']==a['title']]
 assert len(candidates)==1,(a['key'],len(candidates));b=candidates[0]
 comparison.append({'dba':a['key'],'datagrip':b['key'],'classificacao':'igual' if a['tokens']==b['tokens'] else 'filtro_sexo_diferente','diff':'\n'.join(difflib.unified_diff(a['sql'].splitlines(),b['sql'].splitlines(),fromfile=a['key'],tofile=b['key'],n=2))})
md(extra,'matriz','### Comparação dos blocos correspondentes\n\nIgual significa igualdade léxica do SQL sem comentários e espaços; não prova mesma base histórica. “Tabela/view” é uma diferença de população.\n\n| Origem | DataGrip | Comparação |\n|---|---|---|\n'+'\n'.join('| '+c.get('editor',c.get('dba'))+' | '+c['datagrip']+' | '+c['classificacao']+' |' for c in comparison))
# Store body and semantic provenance; never mutate the original notebooks.
artifact={'book_key':BOOK,'title':'2025 — Reprodução por página do PDF','reference_sha256':hashlib.sha256((RR/reference['fonte']).read_bytes()).hexdigest(),'reference':reference,'sections':sections,'comparison':comparison}
(Path(__file__).resolve().parents[2]/'_codex/staging/estudo-paginas/estudo-pages-v1.json').write_text(json.dumps(artifact,ensure_ascii=False,indent=2))
# This migration is additive/idempotent and refuses conflicting cell content rather than overwriting DBA edits.
statements=["SET LOCAL lock_timeout='3s';", "SELECT pg_advisory_xact_lock(9282026,3);",f"INSERT INTO estudo.cadernos(titulo,ano,descricao,source_key) VALUES({lit(artifact['title'])},2025,'Conciliação de PDF, editor migrado, DataGrip e DBA; resultados atuais identificados.',{lit(BOOK)}) ON CONFLICT(source_key) DO NOTHING;"]
for s in sections:
 statements.append(f"INSERT INTO estudo.notebooks(notebook_title,caderno_id,call_order,source_key) SELECT {lit(s['title'])},id,{s['page']},{lit(s['key'])} FROM estudo.cadernos WHERE source_key={lit(BOOK)} ON CONFLICT(source_key) DO NOTHING;")
 for i,c in enumerate(s['cells'],1):
  statements.append(f"INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,{i},{lit(c['type'])},{lit(c['lang'])},{lit(c['content'])},CAST({lit(json.dumps(c['origin'],ensure_ascii=False))} AS jsonb),{lit(c['key'])} FROM estudo.notebooks WHERE source_key={lit(s['key'])} ON CONFLICT(source_key) DO NOTHING;")
  statements.append(f"DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key={lit(c['key'])} AND encode(sha256(convert_to(content,'UTF8')),'hex')={lit(sha(c['content']))}) THEN RAISE EXCEPTION 'Conflito de conteudo: {c['key']}'; END IF; END $verify$;")
(Path(__file__).resolve().parents[2]/'_codex/staging/estudo-paginas/estudo-pages-import.sql').write_text('\n'.join(statements)+'\n')
print(json.dumps({'sections':len(sections),'cells':sum(len(s['cells']) for s in sections),'sql':sum(c['lang']=='sql' for s in sections for c in s['cells']),'comparisons':len(comparison),'equal_dba':sum('dba' in c and c['classificacao']=='igual' for c in comparison)},ensure_ascii=False))
