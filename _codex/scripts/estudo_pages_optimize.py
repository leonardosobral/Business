from pathlib import Path
import sys,json
from estudo_pages_compare import sha
p=((Path(__file__).resolve().parents[2]/'_codex/staging/estudo-paginas')/'estudo-pages-v1.json');j=json.loads(p.read_text());cells={c['key']:c for s in j['sections'] for c in s['cells']};changes=[]
def change(key,sql,why):
 c=cells[key];before=c['content'];c['content']=sql.strip()+';';c['origin']['otimizacao']=why
 changes.append({'key':key,'before_hash':sha(before),'after':c})
faixas='\nUNION ALL\n'.join(f"SELECT {i+1} AS ordem, '{label}' AS faixa, int4range({lo},{hi},'[)') AS r" for i,(label,lo,hi) in enumerate([('13–19',13,20),('20–24',20,25),('25–29',25,30),('30–34',30,35),('35–39',35,40),('40–44',40,45),('45–49',45,50),('50–54',50,55),('55–59',55,60),('60–64',60,65),('65–69',65,70),('70+',70,'NULL')]))
change('pdf-2025-p04-faixas',"""-- Idades: mesmas faixas e populações; agregar intervalos antes do cruzamento.
WITH intervalos AS (
 SELECT r.idade_range,coalesce(r.sexo,'N/A') AS sexo,
 count(r.id_resultado) AS editor,
 count(r.id_resultado) FILTER(WHERE r.status_final=0 AND r.homologado IS TRUE) AS datagrip
 FROM public.tb_resultados r JOIN public.tb_evento_corridas e ON e.id_evento=r.id_evento
 WHERE e.pais='BR' AND e.data_final BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
 GROUP BY r.idade_range,r.sexo
), popula AS (
 SELECT 'Editor / geral' AS versao,idade_range,sum(editor) AS n FROM intervalos GROUP BY idade_range
 UNION ALL SELECT 'DataGrip / geral',idade_range,sum(datagrip) FROM intervalos GROUP BY idade_range
 UNION ALL SELECT 'Editor / '||sexo,idade_range,editor FROM intervalos WHERE sexo IN ('F','M')
 UNION ALL SELECT 'DataGrip / '||sexo,idade_range,datagrip FROM intervalos WHERE sexo IN ('F','M')
), versoes AS (
 SELECT 'Editor / geral' AS versao UNION ALL SELECT 'DataGrip / geral'
 UNION ALL SELECT 'Editor / F' UNION ALL SELECT 'Editor / M'
 UNION ALL SELECT 'DataGrip / F' UNION ALL SELECT 'DataGrip / M'
), faixas AS (
"""+faixas+"""
), agregados AS (
 SELECT v.versao,f.ordem,f.faixa,coalesce(sum(p.n),0) AS total
 FROM versoes v CROSS JOIN faixas f
 LEFT JOIN popula p ON p.versao=v.versao AND p.idade_range && f.r
 GROUP BY v.versao,f.ordem,f.faixa
)
SELECT versao,faixa,total,round(total*100.0/nullif(sum(total) OVER(PARTITION BY versao),0),2) AS porcentagem
FROM agregados ORDER BY versao,ordem""",'Após timeout da revisão 1: agrega as contagens por intervalo/sexo antes do join &&. Mantém as seis populações, o primeiro grupo 13–19 e o denominador por associações; não é correção metodológica.')
old=cells['pdf-2025-p04-faixas-nota'];newtext=old['content']+'\n\n**Otimização da execução:** a revisão 1 atingiu 45s. A revisão seguinte agrega por intervalo/sexo antes do cruzamento. Preserva as populações, as sobreposições e os percentuais; reduz a repetição de varreduras.'
changes.append({'key':old['key'],'before_hash':sha(old['content']),'after':dict(old,content=newtext)});old['content']=newtext
# Reuse the literal historic generation ranges, but aggregate before the small joins.
from estudo_pages_compare import load
items={x['key']:x for x in load()}
parts=[]
for year,sex,idx in [(2025,'F',10),(2024,'M',11),(2023,'geral',12)]:
 original=items[f'datagrip:INFOGRAFICO.sql.txt:{idx}']['sql']
 rangebody=original.split('WITH faixas AS (',1)[1].split('),',1)[0]
 # Inline generated range definitions are the same literals; add historical year/sex identifier.
 parts.append((year,sex,rangebody))
rangeunion='\nUNION ALL\n'.join(f"SELECT {year} AS ano, f.* FROM ({b}) f" for year,sex,b in parts)
change('pdf-2025-p05-historico',"""-- Gerações históricas: mesmos ranges e sexos, com pré-agregação.
WITH intervalos AS (
 SELECT extract(year FROM e.data_final)::integer AS ano,r.idade_range,count(*) AS n
 FROM public.vw_resultados r JOIN public.tb_evento_corridas e ON e.id_evento=r.id_evento
 WHERE e.pais='BR' AND e.data_final>=DATE '2023-01-01' AND e.data_final<DATE '2026-01-01'
 AND (extract(year FROM e.data_final)=2023 OR extract(year FROM e.data_final)=2024 AND r.sexo='M'
 OR extract(year FROM e.data_final)=2025 AND r.sexo='F')
 GROUP BY extract(year FROM e.data_final),r.idade_range
), faixas AS (
"""+rangeunion+"""
), agregados AS (
 SELECT f.ano,f.ordem,f.faixa,coalesce(sum(i.n),0) AS total
 FROM faixas f LEFT JOIN intervalos i ON i.ano=f.ano AND i.idade_range && f.r
 GROUP BY f.ano,f.ordem,f.faixa
)
SELECT CASE ano WHEN 2025 THEN 'DataGrip 2025 / F' WHEN 2024 THEN 'DataGrip 2024 / M' ELSE 'DataGrip 2023 / geral' END AS versao,
 faixa,total,round(total*100.0/nullif(sum(total) OVER(PARTITION BY ano),0),1) AS porcentagem
FROM agregados ORDER BY ano,ordem""",'Pré-agrega por ano/intervalo antes de cruzar as faixas literais; preserva filtros de sexo e limites dos três blocos de origem.')
# Date and inherited display names stay unchanged; revisions provide the audit trail.
((Path(__file__).resolve().parents[2]/'_codex/staging/estudo-paginas')/'estudo-pages-revisions.json').write_text(json.dumps(changes,ensure_ascii=False,indent=2))
((Path(__file__).resolve().parents[2]/'_codex/staging/estudo-paginas')/'estudo-pages-optimized.json').write_text(json.dumps(j,ensure_ascii=False,indent=2))
def lit(s):return "'"+str(s).replace("'","''")+"'"
sql=["SET LOCAL lock_timeout='3s';"]
for c in changes:
 a=c['after'];sql.append(f"DO $r$ BEGIN IF NOT EXISTS (SELECT 1 FROM estudo.notebook_cells WHERE source_key={lit(c['key'])} AND version=1 AND encode(sha256(convert_to(content,'UTF8')),'hex')={lit(c['before_hash'])} FOR UPDATE) THEN RAISE EXCEPTION 'Célula alterada: {c['key']}'; END IF; UPDATE estudo.notebook_cells SET content={lit(a['content'])},origem=CAST({lit(json.dumps(a['origin'],ensure_ascii=False))} AS jsonb),updated_by=NULL WHERE source_key={lit(c['key'])}; END $r$;")
((Path(__file__).resolve().parents[2]/'_codex/staging/estudo-paginas')/'estudo-pages-optimize.sql').write_text('\n'.join(sql))
print('Preparadas 2 revisões SQL e 1 nota, com checks de versão/hash.')
