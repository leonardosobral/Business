"""Isolated adaptation of the reviewed v6 PDF generators. No runtime writes."""
from pathlib import Path
import hashlib,json,re,shutil
W=Path(__file__).resolve().parent;BUSINESS=W.parents[3];RR=BUSINESS.parent/'RoadRunners'
SOURCE=RR/'_codex/docs/brasil_que_corre_provas/lancamento_q3_2026_10_09'
FONTS=RR/'_codex/docs/brasil_que_corre_provas/estrategia_comercial_2026_10_09/assets/fonts'
BASELINE=W/'baseline';GEN=W/'generators';BASELINE.mkdir(exist_ok=True);GEN.mkdir(exist_ok=True)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
files=['estudos/lancamento/index.cfm','estudos/lancamento/arquivo.cfm','estudos/lancamento/arquivos/brasil-que-corre-provas-guia-rapido-q3.pdf','estudos/lancamento/arquivos/brasil-que-corre-provas-lancamento-q3-execucao-v6.pdf','estudos/lancamento/arquivos/brasil-que-corre-provas-lancamento-q3-execucao-v5.pdf']
before={}
for rel in files:
 src=BUSINESS/rel;dst=BASELINE/rel;dst.parent.mkdir(parents=True,exist_ok=True)
 if dst.exists():assert dst.read_bytes()==src.read_bytes(),'Runtime changed after baseline: '+rel
 else:shutil.copy2(src,dst)
 before[rel]=sha(src)
for name in ['gerar_pdf_guia_rapido.py','gerar_pdf_execucao_v6.py']:
 dst=BASELINE/name
 if not dst.exists():shutil.copy2(SOURCE/name,dst)
source_base=W.parent/'postload/runs'
load=lambda cell:json.loads((source_base/f'{cell}.json').read_text())
projection=load(420);main=load(251);cohort=load(387)
assert projection['run']['id']=='352' and main['run']['id']=='351' and cohort['run']['id']=='329'
p=projection['data']['result']['rows'][0]['payload'];p=json.loads(p)if isinstance(p,str)else p
release=p['release'];h=release['historias'];indicators={i['id']:i for i in release['indicadores']};matched=cohort['data']['result']['rows'][0]['payload']['coorte_pareada']
assert matched['pares']==615
fmt=lambda n:f'{float(n):.1f}'.replace('.',',')+'%'
facts={'snapshot':42,'main_run':351,'main_cell':251,'public_run':352,'public_cell':420,'cohort_run':329,'pairs':matched['pares'],'cutoff':'2026-09-30','collection':release['coleta'],'matched':fmt(h['pareadas']['variacao_percentual']),'calendar':fmt(h['provas']['variacao_percentual']),'volume':fmt(h['resultados']['variacao_percentual']),'women_before':fmt(h['mulheres']['anterior']),'women_after':fmt(h['mulheres']['atual']),'short':fmt(indicators['distancias_curtas']['valor']),'interior':fmt(indicators['interior']['valor'])}
(W/'facts.json').write_text(json.dumps(facts,ensure_ascii=False,indent=2))
def once(s,a,b):
 assert s.count(a)==1,(a,s.count(a));return s.replace(a,b)

g=(BASELINE/'gerar_pdf_guia_rapido.py').read_text()
g=once(g,"FONT = BASE.parent / 'estrategia_comercial_2026_10_09/assets/fonts'",'FONT = Path('+repr(str(FONTS))+')')
g=once(g,'Capítulos completos no Business.<br/>Acesso pessoal por convite/voucher.','37 páginas completas no Business.<br/>Acesso pessoal por convite/voucher.')
g=once(g,"'ANUAL 2026', 'Em preparação para janeiro de 2027.<br/>Benefício: compra antecipada com -50%.'","'ANUAL 2026 - RASCUNHO', 'Rascunho interno. Anual separado.<br/>Benefício: compra antecipada com -50%.'")
g=once(g,'+2,1% mesmas provas; +33,9% calendário.<br/>Resultados registrados: +27,3%.','+'+facts['matched']+' em 615 pares; +'+facts['calendar']+' calendário.<br/>Volume registrado: +'+facts['volume']+'.')
g=once(g,"entry('Execução v6 / plano atual', '8 telas. Estreia confirmada em 13/11/2026.',\n      HUB+'arquivo.cfm?doc=execucao-v6', 298, 230)","entry('Execução v7 / plano atual', '8 telas. Fonte renovada; estreia em 13/11.',\n      HUB+'arquivo.cfm?doc=execucao-v7', 298, 230)")
g=once(g,"entry('Execução v5 / histórico', '8 telas. Versão de 04/11 preservada.',\n      HUB+'arquivo.cfm?doc=execucao-v5', 298, 282)","entry('Execução v6 / histórico', '8 telas. Fechamento anterior de 09/11.',\n      HUB+'arquivo.cfm?doc=execucao-v6', 298, 282)")
g=once(g,"entry('Conselheiros v2', '11 telas. Estratégia e exemplos visuais.',\n      HUB+'arquivo.cfm?doc=conselho-v2', 298, 334)","entry('Execução v5 / histórico', '8 telas. Versão de 04/11 preservada.',\n      HUB+'arquivo.cfm?doc=execucao-v5', 298, 334)")
g=once(g,"entry('Conselheiros v1 / histórico', '6 telas. Primeira proposta visual preservada.',\n      HUB+'arquivo.cfm?doc=conselho-v1', 298, 386)","entry('Conselheiros v2', '11 telas. Estratégia e exemplos visuais.',\n      HUB+'arquivo.cfm?doc=conselho-v2', 298, 386)")
g=once(g,"entry('Estratégia inicial / histórico', '10 páginas. Fundamentação em texto.',\n      HUB+'arquivo.cfm?doc=estrategia-inicial', 298, 438)","entry('Histórico completo da central', 'Conselheiros v1, planos e estratégia inicial.',\n      HUB+'#pdfs', 298, 438)")
g=once(g,'50% já implementado em 04/11; checkout anual pendente. Maratonas: apoio separado em revisão web.','Snapshot 42/run 351; público 420/run 352; coleta 09/11. Participações, não pessoas únicas.')
(GEN/'gerar_pdf_guia_rapido.py').write_text(g)

e=(BASELINE/'gerar_pdf_execucao_v6.py').read_text()
e=once(e,"FONT = BASE.parent / 'estrategia_comercial_2026_10_09/assets/fonts'",'FONT = Path('+repr(str(FONTS))+')')
for a,b in [('Launch execution brief, v6.','Launch execution brief, v7.'),('v5 and prior PDFs preserved.','v6, v5 and prior PDFs preserved.'),('professional publication 41/run 233 and public projection 239','approved snapshot 42/run 351 and public projection 352'),('lancamento-q3-execucao-v6.pdf','lancamento-q3-execucao-v7.pdf'),('Lançar a prévia Jan-Set | v6','Lançar a prévia Jan-Set | v7'),('09 NOV 2026 / V6','09 NOV 2026 / V7'),('execucao-layout-v6.json','execucao-layout-v7.json')]:e=once(e,a,b)
e=once(e,'Capítulos completos de perfil, idades, gerações, distâncias, geografia, calendário e porte. Fontes e critérios.','37 páginas de perfil, idades, gerações, distâncias, geografia, calendário e porte. Fontes e critérios.')
e=once(e,'Preços, kits e lotes, faixas de desempenho (CNA), ritmo nacional de 42 km e Q4: temas em preparação.','Rascunho interno (DRAFT): preços, kits/lotes, CNA, ritmo nacional de 42 km e Q4. Sem oferta anual ativa.')
e=once(e,'Profissional: publicação 41/run 233; corte 30/09/2026. Maratonas: apoio editorial separado, em revisão web; sem promessa de novo PDF.','Profissional: snapshot 42/run 351; 37 páginas; corte 30/09/2026. Maratonas: apoio web separado, sem novo PDF. Anual DRAFT.')
for a,b in [('+2,1%','+'+facts['matched']),('+33,9%','+'+facts['calendar']),('53,9%',facts['women_after']),('+27,3%','+'+facts['volume']),('61,2%',facts['short']),('47,5%',facts['interior'])]:e=once(e,a,b)
e=once(e,'concluintes nas mesmas provas','concluintes nos 615 pares')
e=once(e,'Participações elegíveis,<br/>não pessoas únicas.','52,5% em 2025 - 53,8% em 2026.<br/>Participações, não pessoas únicas.')
e=once(e,'Jan-Set 2025/2026. Público: célula 420/run 239; origem 41/run 233. Coleta por bloco; panorama 2026: 06/10. Não isola crescimento do mercado.','Jan-Set 2025/2026. 615 pares: 387/run 329. Público: 420/run 352; snapshot 42/run 351. Coleta 09/11. Não isola crescimento do mercado.')
(GEN/'gerar_pdf_execucao_v7.py').write_text(e)

candidate=W/'runtime/business/estudos/lancamento';candidate.mkdir(parents=True,exist_ok=True)
router=(BASELINE/'estudos/lancamento/arquivo.cfm').read_text();anchor="    'execucao-v6':'brasil-que-corre-provas-lancamento-q3-execucao-v6.pdf',"
router=once(router,anchor,"    'execucao-v7':'brasil-que-corre-provas-lancamento-q3-execucao-v7.pdf',\n"+anchor)
(candidate/'arquivo.cfm').write_text(router)
(W/'baseline-manifest.json').write_text(json.dumps({'runtime':before,'generators':{n:sha(BASELINE/n)for n in ['gerar_pdf_guia_rapido.py','gerar_pdf_execucao_v6.py']},'fonts':{p.name:sha(p)for p in sorted(FONTS.glob('*.ttf'))}},indent=2))
print(json.dumps({'facts':facts,'generators':str(GEN),'runtime_written':False},ensure_ascii=False,indent=2))
