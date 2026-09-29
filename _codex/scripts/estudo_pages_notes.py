from pathlib import Path
import json, hashlib

root=Path(__file__).resolve().parents[2]/'_codex/staging/estudo-paginas'
data=json.loads((root/'estudo-pages-optimized.json').read_text())
catalogue=json.loads((root/'estudo-pages-catalogue.json').read_text())
by_cell={c['id']:c for c in catalogue['cells']}
frozen={by_cell[r['cell_id']]['source_key']:r for r in catalogue['runs'] if r['frozen']}
sql_cells=[c for s in data['sections'] for c in s['cells'] if c['lang']=='sql']
assert len(frozen)==len(sql_cells)==24
for c in sql_cells:
 r=frozen[c['key']]
 assert r['status']=='ok' and not r['truncated'] and r['row_count']==len(r['result']['rows'])
 assert hashlib.sha256(r['sql_text'].encode()).hexdigest()==r['sql_sha256']
 assert r['sql_text'].strip().rstrip(';')==c['content'].strip().rstrip(';')

notes={
0:'''**24 consultas executadas e congeladas em 28/09/2026.** As tabelas de resultados ficam nas próprias células SQL e na aba “Execuções e congelados”; não é necessário copiar HTML.

Este caderno confronta o PDF de 2025 com o editor migrado, os oito arquivos DataGrip e o pacote do DBA. São 15 seções, incluindo as páginas analíticas 3–15, e 23 pares de consultas comparados. Os cadernos anteriores e seus HTMLs foram preservados.

**Fonte prioritária:** conforme a informação do responsável, a `vw_resultados` foi preparada depois e provavelmente alimentou o estudo. Essa procedência orienta a conciliação. A definição inspecionada hoje é uma view comum sobre `tb_resultados`, com `status_final = 0 AND homologado = true`; por isso esta coleta representa a base atual de 2025. Não recupera automaticamente o estado do banco usado em março de 2026.

**Primeiras evidências:** a view retorna 5.279.415 participações, compatíveis com “5,3 milhões”; as quatro faixas de distância coincidem numericamente com o PDF. No top 10 de maratonas, sete contagens coincidem e três diferem. Compatibilidade não certifica a metodologia inteira.

**Ainda a conciliar:** cobertura de 84,1%; idades por sobreposição; recortes anuais de gerações; normalização de localidades; estações do ano; critérios de pódio e médias por grupos; dez cartões de perfil. Cada página registra seus filtros, diferenças e pendências. A web pública ainda não consome estes congelamentos.''',
3:'''- Total bruto do editor: **5.599.435**. Total tratado da view: **5.279.415**, compatível com o destaque abreviado “5,3 milhões” do PDF.
- Mulheres: **52,85%** no recorte DataGrip de 2025 com tempo positivo; o PDF publica **52,9%**. Isso é compatível na precisão publicada, sem provar identidade da base histórica.
- Eventos cadastrados: **6.167 em 2024** e **9.360 em 2025**. Com pelo menos um resultado na view: **3.214 e 5.121**, respectivamente. Estes são eventos encontrados na base atual, não uma estimativa de todas as provas brasileiras.
- “Pelo menos um resultado coletado” é uma definição distinta de completude da coleta. O destaque **84,1%** continua com denominador pendente.''',
4:'''A variante da view produz, no total, **6,69% em 13–19**, **14,40% em 30–34** e **14,72% em 35–39**. O PDF mostra 6,7%, 14,4% e 14,7%, mas rotula a primeira faixa como **14–19**.

As 12 contagens do recorte geral somam **6.620.729**, acima das 5.279.415 linhas da view: um intervalo de idade pode se sobrepor a mais de uma faixa. Os percentuais usam a soma dessas atribuições como denominador. Não interpretar as faixas como uma partição exclusiva de pessoas ou participações.

A execução inicial #9 ultrapassou 45 segundos e ficou registrada como erro. A revisão 2 agrega intervalos antes do cruzamento; testes com intervalos sobrepostos, vazios e nulos confirmaram equivalência. A execução #10 terminou em 10,087 segundos.''',
5:'''A versão DataGrip **2024 / M** reproduz os cinco percentuais do recorte masculino do PDF: **2,9 / 18,2 / 49,1 / 22,5 / 7,3**. Já a versão **2025 / F** retorna **3,4 / 17,6 / 51,8 / 21,8 / 5,4**, com pequenas diferenças em relação ao quadro feminino publicado.

Os três blocos históricos preservam filtros diferentes: **2023 geral, 2024 masculino e 2025 feminino**. Eles não formam uma série anual comparável entre si. A saída BI é outra população/regra e mantém “Não Definido” visível; não deve substituir silenciosamente as faixas do PDF.''',
6:'''As quatro faixas da view retornam **59,1% / 28,4% / 11,1% / 1,4%**, iguais aos valores publicados. A coincidência numérica não elimina a revisão dos rótulos: o SQL usa `<6`, `6–10,99`, `11–29,99` e `>=30` km; os limites BETWEEN são inclusivos.

Na distribuição detalhada, 5 km representa **54,04%**, contra **53,96%** no PDF. A presença de 5 km é **3.728 de 5.002 eventos com resultados de rua (74,53%)**, contra 74,6% publicado.

A comparação dentro de cada sexo utiliza denominador próprio, conforme explicado na célula de método. Nos arquivos originais havia um denominador conjunto para F+M; essa alteração está identificada, não foi tratada como consulta original.''',
7:'''Entre as participações classificadas em 6–10 km, os percentuais por geração coincidem com o PDF: **Z 6,3%, Y 46,6%, X 38,6%, Boomers 8,5%**.

Em 30 km ou mais há diferenças: **X 51,0%** no congelamento contra **51,7%** publicado; **Y 40,6%** contra **40,1%**. A regra de classificação deriva da função inspecionada hoje e exclui geração zero. Isso não representa toda a população com idade desconhecida.''',
8:'''A versão geral do DBA reproduz as faixas publicadas de **10 km (2,5 / 14,1 / 30,6 / 52,8%)**, **21 km (4,1 / 40,3 / 41,2 / 14,3%)** e **42 km (3,8 / 12,6 / 26,5 / 24,6 / 32,4%)**. Em 5 km, a faixa 25–30 minutos deu **16,2%**, contra 16,3% no PDF.

Os blocos DataGrip executados preservam **5 km feminino** e **10/21/42 km masculino**. Os recortes complementares publicados ainda precisam ser derivados explicitamente. Os operadores de fronteira e o tratamento de zero/nulo foram mantidos como nos scripts; “Sub” no título nem sempre corresponde a `<` no SQL.''',
9:'''No recorte geral de 2025, a view retorna **Sudeste 47,5%, Nordeste 19,9%, Sul 17,5%, Centro-Oeste 9,2% e Norte 5,9%**. O PDF mostra 47,6%, 19,7%, 17,5%, 9,3% e 5,8%.

As seis saídas distinguem ano e sexo. “Regiões dentro de cada sexo” e “sexos dentro de cada região” têm denominadores diferentes; a tabela congelada fornece contagens para a segunda derivação, mas não se deve reutilizar diretamente o percentual da primeira.''',
10:'''São Paulo/UF aparece com **25,9%** na view e 26,2% no PDF. Na tabela de cidades, São Paulo/SP soma **647.968 (12,27%)**, contra 12,4% publicado.

A chave inclui UF, mas ainda é textual: **BRASÍLIA/DF (204.519)** e **BRASILIA/DF (23.492)** aparecem separadas. Isso registra uma pendência de normalização; não foram fundidas sem uma regra de localidade.

Na alternativa BI, o cruzamento é pelo **id_localidade**. Permanecem **125.710 participações sem classificação de localidade (2,40%)**, visíveis na saída. É outra população, com resultado nacional diferente; não é uma substituição automática da query geográfica original.''',
11:'''Novembro continua sendo o mês com maior volume: **697.187 participações tratadas (13,21%)**, contra **13,4%** no PDF. O quarto trimestre soma **1.743.230 (33,02%)**, contra **33,5%** publicado.

A tabela atual contém os 12 meses, inclusive janeiro e fevereiro, e quatro trimestres com denominador anual. A regra de **estações** não foi localizada; os percentuais publicados estão preservados como referência, sem criar uma regra nova por suposição.''',
12:'''Sete das dez contagens coincidem com o PDF. As diferenças estão em:

| Maratona | PDF | Coleta atual | Diferença |
|---|---:|---:|---:|
| SP City | 5.380 | 5.386 | +6 |
| São Paulo | 4.851 | 4.869 | +18 |
| Curitiba | 3.012 | 3.040 | +28 |

O total das dez passou de **43.362** publicados para **43.414** no recorte atual. Como a edição e o ano são os mesmos, essas diferenças não medem crescimento anual da prova; podem envolver atualização da base e diferenças de critério.

O menor tempo de Curitiba veio como **01:56:00**, contra **02:15:13** publicado. Fica sinalizado para revisar resultado, modalidade e filtros antes de promover essa estatística. Nenhum registro foi corrigido ou removido nesta conciliação.''',
13:'''A seleção fixa de Curitiba passou de **1.367 para 1.390** abaixo de 4h, de **132 para 139** abaixo de 3h e de **10 para 13** abaixo de 2h30, comparando PDF e recálculo atual. SP City e São Paulo também apresentam diferenças; o Rio mantém 5.242 / 334 / 11.

Esses números usam os dez IDs e limites estritos definidos na célula. Ainda não reproduzem o quadro de pódio nem as médias Top10/Top100/Top5%/Top10%/Top50%. O tempo mínimo de Curitiba sinalizado na página anterior também afeta a interpretação dessas faixas.''',
14:'''As quatro distâncias e oito faixas foram congeladas. Exemplos: branca de 5 km **73,59%** contra **73,51%** no PDF; branca de 10 km **53,09%**, igual ao publicado; branca de 42 km **57,82%** contra **57,84%**.

As regras CNA são distintas das faixas de performance da página 8. As pequenas diferenças atuais não demonstram sozinhas erro na publicação, pois não existe uma cópia histórica completa da base.''',
15:'''A query encontrou **110.058 atividades WeightTraining (9,51%)**, **91.809 Walk (7,93%)**, **75.111 Workout (6,49%)** e **61.151 Ride (5,28%)** em 2025. O gráfico publica 9,5%, 7,93%, 6,49% e 5,21% para os rótulos correspondentes.

O denominador da consulta inclui corrida e conta **atividades, não usuários**. Os rótulos traduzidos e as exclusões precisam ser confirmados. Os dez cartões de perfil continuam sem consulta reconciliada; não foram inferidos a partir da amostra de personas.''',
99:'''O diagnóstico bruto encontrou **5.599.435 linhas**; a regra da view mantém **5.279.415**. O campo `concluinte=true` sinaliza **5.280.837** linhas, portanto não é sinônimo exato dos filtros da view.

Na população bruta há **1.265.472 linhas sem idade_range**, **318.457 com tempo nulo** e **142 com tempo zero**. As categorias podem se sobrepor e não devem ser somadas como pessoas distintas.

Todos os 24 congelamentos são completos dentro do limite de saída do notebook; nenhuma tabela foi truncada. A tentativa #9 com timeout foi preservada como erro e substituída por uma execução bem-sucedida da revisão otimizada. Congelamentos anteriores e HTMLs históricos permanecem intactos.'''
}
# Check numerical summaries from immutable evidence, not hand-transcribed assumptions.
rows=lambda key:frozen['pdf-2025-'+key]['result']['rows']
assert sum(r['total'] for r in rows('p04-faixas') if r['versao']=='DataGrip / geral')==6620729
assert sum(r['concluintes'] for r in rows('p12-ranking'))==43414
def lit(v):return "'"+v.replace("'","''")+"'"
statements=["SET LOCAL lock_timeout='3s';",'SELECT pg_advisory_xact_lock(9282026,4);']
for sec in data['sections']:
 runs=[frozen[c['key']] for c in sec['cells'] if c['lang']=='sql']
 body='### Conciliação executada — 28/09/2026\n\n'+notes[sec['page']]
 if runs:body+='\n\n**Evidência congelada:** '+', '.join('#'+str(r['id'])+' (célula '+str(r['cell_id'])+', revisão '+str(r['cell_version'])+')' for r in runs)+'.'
 c={'type':'markdown','lang':'','key':sec['key']+'-coleta-20260928','content':body,'origin':{'kind':'executed_reconciliation','date':'2026-09-28','runs':[{'id':r['id'],'cell_id':r['cell_id'],'version':r['cell_version'],'sql_sha256':r['sql_sha256']} for r in runs],'status':'candidate_current_data_not_historical_certification'}}
 sec['cells'].append(c)
 statements.append(f"INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,{len(sec['cells'])},'markdown','',{lit(body)},{lit(json.dumps(c['origin']))}::jsonb,{lit(c['key'])} FROM estudo.notebooks WHERE source_key={lit(sec['key'])} ON CONFLICT(source_key) DO NOTHING;")
 statements.append(f"DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key={lit(c['key'])} AND content={lit(body)}) THEN RAISE EXCEPTION 'Conflito de nota {c['key']}'; END IF; END $verify$;")
(root/'estudo-pages-notes.sql').write_text('\n'.join(statements)+'\n')
(root/'estudo-pages.json').write_text(json.dumps(data,ensure_ascii=False,indent=2))
print('Verified 24 frozen SQL outputs; prepared 15 reconciliation notes.')
