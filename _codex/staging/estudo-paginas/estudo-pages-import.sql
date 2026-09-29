SET LOCAL lock_timeout='3s';
SELECT pg_advisory_xact_lock(9282026,3);
INSERT INTO estudo.cadernos(titulo,ano,descricao,source_key) VALUES('2025 — Reprodução por página do PDF',2025,'Conciliação de PDF, editor migrado, DataGrip e DBA; resultados atuais identificados.','pdf-2025-pages-v1') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebooks(notebook_title,caderno_id,call_order,source_key) SELECT 'Comece aqui — mapa das páginas',id,0,'pdf-2025-p00' FROM estudo.cadernos WHERE source_key='pdf-2025-pages-v1' ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,1,'markdown','','## Comece aqui — mapa das páginas

Este é o caderno de trabalho para reproduzir o PDF de 2025. Cada seção corresponde a uma página analítica (3–15). As páginas 1, 2 e 16 são capa, metodologia e encerramento; estão referenciadas aqui.

**Como trabalhar:** leia a comparação das fontes, execute uma célula SQL e congele a saída com uma nota sobre os filtros. A tabela gerada substitui a colagem de HTML. Os HTMLs antigos permanecem no caderno original como evidência histórica, pois não comprovam qual query foi executada.

**Prioridade das fontes (informação do responsável, 28/09/2026):** vw_resultados foi criada depois para tratar/consolidar os dados e provavelmente embasou o estudo. Portanto, as queries DataGrip/DBA que a usam são candidatas prioritárias; o editor bruto é comparação histórica. A definição atual da view aplica status_final=0/homologado=true sobre a tabela viva. Sua criação posterior não recupera, sozinha, o estado da base na publicação.

**Três referências distintas:** PDF = o que foi publicado; editor/DataGrip/DBA = regras candidatas; execução atual = resultado da regra hoje. Coincidência após arredondamento não certifica a linhagem histórica. Temos apenas a base atual.

**Metodologia publicada (p.2):** Brasil, 2025, homens e mulheres, 14+ anos. Vários SQLs não implementam todos esses filtros. As diferenças ficam visíveis; não foram harmonizadas silenciosamente.

[PDF completo](https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf) · [Acervo migrado](https://business.roadrunners.run/estudo/?caderno=1) · [Arquivos DBA/DataGrip](https://business.roadrunners.run/estudo/?caderno=2)

**Pendências para fechar 2025:** denominador dos 84,1%; fronteiras de idade/geração; localização capital/interior; regra das estações; critérios de tempos/pódio; dez cards do perfil. As seções explicam exatamente o que falta.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 0, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p00-intro' FROM estudo.notebooks WHERE source_key='pdf-2025-p00' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p00-intro' AND encode(sha256(convert_to(content,'UTF8')),'hex')='dfba7090e95d63333899347e897fe552c65f247e910cd6ccf5af898e31259918') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p00-intro'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,2,'markdown','','| Página | Assunto | Situação |
|---|---|---|
| 3 | Panorama, volume e gênero | Consultas candidatas e diferenças registradas |
| 4 | Faixas etárias | Consultas candidatas e diferenças registradas |
| 5 | Gerações e comparações anuais | Consultas candidatas e diferenças registradas |
| 6 | Distâncias e participação por sexo | Consultas candidatas e diferenças registradas |
| 7 | Gerações nas distâncias | Consultas candidatas e diferenças registradas |
| 8 | Ritmo e performance | Consultas candidatas e diferenças registradas |
| 9 | Regiões e gênero | Consultas candidatas e diferenças registradas |
| 10 | Estados, cidades e capital/interior | Consultas candidatas e diferenças registradas |
| 11 | Calendário, trimestres e estações | Consultas candidatas e diferenças registradas |
| 12 | Top maratonas e tempos | Consultas candidatas e diferenças registradas |
| 13 | Maratonas rápidas e pódio | Consultas candidatas e diferenças registradas |
| 14 | Faixas Corrida no Ar | Consultas candidatas e diferenças registradas |
| 15 | Perfil e outros esportes | Consultas candidatas e diferenças registradas |

Escolha a página no seletor Seção. Os resultados ficam em “Execuções e congelados”.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 0, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p00-mapa' FROM estudo.notebooks WHERE source_key='pdf-2025-p00' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p00-mapa' AND encode(sha256(convert_to(content,'UTF8')),'hex')='86fade309a238589e70bf7b367414331735285111b06bce4589bf1af6ab719b1') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p00-mapa'; END IF; END $verify$;
INSERT INTO estudo.notebooks(notebook_title,caderno_id,call_order,source_key) SELECT 'P03 — Panorama, volume e gênero',id,3,'pdf-2025-p03' FROM estudo.cadernos WHERE source_key='pdf-2025-pages-v1' ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,1,'markdown','','## P03 — Panorama, volume e gênero

**Editor:** [Escopo Infograficos](https://business.roadrunners.run/estudo/?caderno=1&secao=1); [Gênero](https://business.roadrunners.run/estudo/?caderno=1&secao=2). Usa tb_resultados sem homologação/status/concluinte. HTML 65 registra 5.545.343; HTML 71 registra F=2.918.372, M=2.601.046, X=2.134 (soma 5.521.552). Nem esses dois resultados colados têm o mesmo total.

**DataGrip:** INFOGRAFICO, blocos 1–4. Usa vw_resultados (status_final=0 e homologado=true); gênero 2025 ainda exige tempo positivo. A versão BI usa outra população.

**DBA:** estudo_treinos anota 9.245 eventos de rua/trail; DOCX F+M=5.101.962 e 52,9% F, compatível com a view BI na coleta de 27/09. Isso não prova que a BI gerou todo o PDF.

**Decisão:** manter as três populações identificadas. A cobertura de 84,1% não tem regra recuperada. O diagnóstico de eventos abaixo usa presença de resultados e não substitui aquele percentual.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 3, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p03-intro' FROM estudo.notebooks WHERE source_key='pdf-2025-p03' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p03-intro' AND encode(sha256(convert_to(content,'UTF8')),'hex')='ea2d3c93c1783b5000f6b97701dc8e154b8eee43af78a80c4c23a233a13147b2') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p03-intro'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,2,'markdown','','### Gênero — comparar editor, DataGrip e BI

Reproduz cada variante sem igualar os filtros; o denominador inclui todos os sexos presentes em cada consulta.

**Linhas de origem:** `editor:02_genero.sql.txt:1`, `datagrip:INFOGRAFICO.sql.txt:2`, `datagrip:INFOGRAFICO.sql.txt:3`, `datagrip:INFOGRAFICO.sql.txt:4`.

A saída representa a base atual no momento da execução; não é o snapshot usado no PDF.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 3, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p03-genero-nota' FROM estudo.notebooks WHERE source_key='pdf-2025-p03' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p03-genero-nota' AND encode(sha256(convert_to(content,'UTF8')),'hex')='d5f912ea69252b1bece9ab16cdc4f3643c3bf5a776051d5142f3b42910d4a9d3') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p03-genero-nota'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,3,'code','sql','-- Gênero — comparar editor, DataGrip e BI
WITH q0 AS (
-- TOTAL DE CONCLUINTES POR GENERO

SELECT
  COALESCE(res.sexo, ''N/A'') AS genero,
  COUNT(res.id_resultado) AS total,
  ROUND(
    COUNT(res.id_resultado) * 100.0
    / NULLIF(SUM(COUNT(res.id_resultado)) OVER (), 0),
    2
  ) AS porcentagem
FROM tb_resultados res
JOIN tb_evento_corridas evt
  ON evt.id_evento = res.id_evento
WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
  AND evt.pais = ''BR''
GROUP BY COALESCE(res.sexo, ''N/A'')
ORDER BY total DESC
),
q1 AS (
-- TOTAL DE CONCLUINTES POR GENERO 2025
SELECT
  COALESCE(res.sexo, ''N/A'') AS genero,
  COUNT(res.id_resultado) AS total,
  ROUND(
    COUNT(res.id_resultado) * 100.0
    / NULLIF(SUM(COUNT(res.id_resultado)) OVER (), 0),
    2
  ) AS porcentagem
FROM vw_resultados res
JOIN tb_evento_corridas evt
  ON evt.id_evento = res.id_evento
WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
  AND evt.pais = ''BR''
  and res.tempo_total is not null and res.tempo_total > ''00:00:00''
  --and pcd = false and (evt.ranking is null OR evt.ranking = ''1'')
GROUP BY COALESCE(res.sexo, ''N/A'')
ORDER BY total DESC
),
q2 AS (
-- TOTAL DE CONCLUINTES POR GENERO (TABELA FLAT)
SELECT
  COALESCE(res.sexo, ''N/A'') AS genero,
  COUNT(res.id_resultado) AS total,
  ROUND(
    COUNT(res.id_resultado) * 100.0
    / NULLIF(SUM(COUNT(res.id_resultado)) OVER (), 0),
    2
  ) AS porcentagem
FROM vwbi_fat_perfil_br_2025 res
GROUP BY COALESCE(res.sexo, ''N/A'')
ORDER BY total DESC
),
q3 AS (
-- TOTAL DE CONCLUINTES POR GENERO 2024

SELECT
  COALESCE(res.sexo, ''N/A'') AS genero,
  COUNT(res.id_resultado) AS total,
  ROUND(
    COUNT(res.id_resultado) * 100.0
    / NULLIF(SUM(COUNT(res.id_resultado)) OVER (), 0),
    2
  ) AS porcentagem
FROM tb_resultados res
JOIN tb_evento_corridas evt
  ON evt.id_evento = res.id_evento
WHERE evt.data_final BETWEEN DATE ''2024-01-01'' AND DATE ''2024-12-31''
  AND evt.pais = ''BR''
GROUP BY COALESCE(res.sexo, ''N/A'')
ORDER BY total DESC
),
q4 AS (
-- TOTAL DE CONCLUINTES POR GENERO 2024
SELECT
  COALESCE(res.sexo, ''N/A'') AS genero,
  COUNT(res.id_resultado) AS total,
  ROUND(
    COUNT(res.id_resultado) * 100.0
    / NULLIF(SUM(COUNT(res.id_resultado)) OVER (), 0),
    2
  ) AS porcentagem
FROM vw_resultados res
JOIN tb_evento_corridas evt
  ON evt.id_evento = res.id_evento
WHERE evt.data_final BETWEEN DATE ''2024-01-01'' AND DATE ''2024-12-31''
  AND evt.pais = ''BR''
GROUP BY COALESCE(res.sexo, ''N/A'')
ORDER BY total DESC
)
SELECT ''Editor 2025'' AS versao, genero,total,porcentagem FROM q0
UNION ALL
SELECT ''DataGrip 2025 (tempo positivo)'' AS versao, genero,total,porcentagem FROM q1
UNION ALL
SELECT ''BI 2025 (fonte DBA)'' AS versao, genero,total,porcentagem FROM q2
UNION ALL
SELECT ''Editor 2024'' AS versao, genero,total,porcentagem FROM q3
UNION ALL
SELECT ''DataGrip 2024'' AS versao, genero,total,porcentagem FROM q4;',CAST('{"tipo": "consulta_conciliacao", "pagina_pdf": 3, "fontes": ["editor:02_genero.sql.txt:1", "datagrip:INFOGRAFICO.sql.txt:2", "datagrip:INFOGRAFICO.sql.txt:3", "datagrip:INFOGRAFICO.sql.txt:4"], "regra": "Reproduz cada variante sem igualar os filtros; o denominador inclui todos os sexos presentes em cada consulta.", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p03-genero' FROM estudo.notebooks WHERE source_key='pdf-2025-p03' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p03-genero' AND encode(sha256(convert_to(content,'UTF8')),'hex')='34355c02373b83da6feda1a2ed2c41d00ed632469d85c34af14a9236838b36de') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p03-genero'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,4,'markdown','','### Total de linhas — editor versus DataGrip

As fontes chamam a medida de concluintes, mas nenhuma exige concluinte=true. A saída conta linhas de resultados, não atletas únicos.

**Linhas de origem:** `editor:01_escopo_infograficos.sql.txt:1`, `datagrip:INFOGRAFICO.sql.txt:1`.

A saída representa a base atual no momento da execução; não é o snapshot usado no PDF.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 3, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p03-total-nota' FROM estudo.notebooks WHERE source_key='pdf-2025-p03' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p03-total-nota' AND encode(sha256(convert_to(content,'UTF8')),'hex')='c85f84ce27532400f852687c4c9e4c490d1953e5758811e7dc6b10d4efc60b66') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p03-total-nota'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,5,'code','sql','-- Total de linhas — editor versus DataGrip
WITH q0 AS (
-- TOTAL DE CONCLUINTES

select count(res.id_resultado) from tb_resultados res
inner join tb_evento_corridas evt ON evt.id_evento = res.id_evento
where evt.data_final between ''2025-01-01'' and ''2025-12-31'' and evt.pais = ''BR''
),
q1 AS (
-- TOTAL DE CONCLUINTES

select count(res.id_resultado) from vw_resultados res
inner join tb_evento_corridas evt ON evt.id_evento = res.id_evento
where evt.data_final between ''2025-01-01'' and ''2025-12-31'' and evt.pais = ''BR''
)
SELECT ''Editor'' AS versao, count AS total FROM q0
UNION ALL
SELECT ''DataGrip'' AS versao, count AS total FROM q1;',CAST('{"tipo": "consulta_conciliacao", "pagina_pdf": 3, "fontes": ["editor:01_escopo_infograficos.sql.txt:1", "datagrip:INFOGRAFICO.sql.txt:1"], "regra": "As fontes chamam a medida de concluintes, mas nenhuma exige concluinte=true. A saída conta linhas de resultados, não atletas únicos.", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p03-total' FROM estudo.notebooks WHERE source_key='pdf-2025-p03' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p03-total' AND encode(sha256(convert_to(content,'UTF8')),'hex')='83585bfd2de0dcabe30f9a9f3d7656fe9f5ea601531d138a7af4803344a2e609') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p03-total'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,6,'markdown','','### Eventos cadastrados e eventos com resultados

Diagnóstico novo: BR, rua/trail e data final de cada ano; inclui cadastros sem resultado e sem filtro de ativo/status do evento. Presença de uma linha não garante coleta completa. Não é a fórmula histórica dos 84,1%.

**Linhas de origem:** `dba:estudo_treinos.sql.txt:calendario`, `diagnostico_novo_cobertura`.

A saída representa a base atual no momento da execução; não é o snapshot usado no PDF.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 3, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p03-eventos-nota' FROM estudo.notebooks WHERE source_key='pdf-2025-p03' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p03-eventos-nota' AND encode(sha256(convert_to(content,'UTF8')),'hex')='0fa3c929d140cd66234aeb50f6a5f1c4aa787cb8d55383b453eaf2e1bc2437f5') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p03-eventos-nota'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,7,'code','sql','-- Eventos cadastrados e eventos com resultados
WITH eventos AS (
 SELECT id_evento,extract(year FROM data_final)::integer AS ano
 FROM public.tb_evento_corridas
 WHERE pais=''BR'' AND tipo_corrida IN (''rua'',''trail'')
 AND data_final>=DATE ''2024-01-01'' AND data_final<DATE ''2026-01-01''
), presenca AS (
 SELECT r.id_evento,count(*) AS linhas,
 count(*) FILTER (WHERE r.status_final=0 AND r.homologado IS TRUE) AS linhas_view
 FROM public.tb_resultados r JOIN eventos e ON e.id_evento=r.id_evento GROUP BY r.id_evento
)
SELECT e.ano,count(*) AS eventos_cadastrados,
 count(*) FILTER(WHERE p.linhas>0) AS eventos_com_resultados_brutos,
 count(*) FILTER(WHERE p.linhas_view>0) AS eventos_com_resultados_view,
 round(count(*) FILTER(WHERE p.linhas>0)*100.0/nullif(count(*),0),2) AS cobertura_bruta_pct
FROM eventos e LEFT JOIN presenca p ON p.id_evento=e.id_evento GROUP BY e.ano ORDER BY e.ano;',CAST('{"tipo": "consulta_conciliacao", "pagina_pdf": 3, "fontes": ["dba:estudo_treinos.sql.txt:calendario", "diagnostico_novo_cobertura"], "regra": "Diagnóstico novo: BR, rua/trail e data final de cada ano; inclui cadastros sem resultado e sem filtro de ativo/status do evento. Presença de uma linha não garante coleta completa. Não é a fórmula histórica dos 84,1%.", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p03-eventos' FROM estudo.notebooks WHERE source_key='pdf-2025-p03' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p03-eventos' AND encode(sha256(convert_to(content,'UTF8')),'hex')='c5a34c1e05821a94b49c5fae3232133708ec7ed6dcfc493d3d52623acb713a5c') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p03-eventos'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,8,'markdown','','### Referência publicada — PDF v3.10.3

[Consultar a página 3](https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf#page=3). Valores transcritos; não foram recalculados.

**destaques** (texto_publicado)

Concluintes: **5.3Mi** | Eventos: **9.2mil** | Resultados mapeados: **84.1%**

Nota: Não converter destaques abreviados em contagens exatas; denominador da cobertura pendente.

**sexo_2024** (percentual)

F: **50.7** | M: **49.3**

**sexo_2025** (percentual)

F: **52.9** | M: **47.1**

',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 3, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p03-pdf' FROM estudo.notebooks WHERE source_key='pdf-2025-p03' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p03-pdf' AND encode(sha256(convert_to(content,'UTF8')),'hex')='6bd3b60085d80860383e18154738d55eecba471d99c8b4d9dde662c92db9203c') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p03-pdf'; END IF; END $verify$;
INSERT INTO estudo.notebooks(notebook_title,caderno_id,call_order,source_key) SELECT 'P04 — Faixas etárias',id,4,'pdf-2025-p04' FROM estudo.cadernos WHERE source_key='pdf-2025-pages-v1' ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,1,'markdown','','## P04 — Faixas etárias

**Editor:** [Faixa etária](https://business.roadrunners.run/estudo/?caderno=1&secao=3). Tabela bruta, faixas por sobreposição (&&), geral; também inclui 40+/50+/60+. Primeiro grupo começa em 13.

**DataGrip:** INFOGRAFICO, blocos 5–9. View filtrada; o bloco de faixas está fixo em M e arredonda a uma casa. O HTML 72 mostra 13–19 = 3,48% geral, enquanto o PDF rotula 14–19 = 6,7%.

**DBA/BI:** a carga atribui uma categoria por função, com prioridade entre ranges; não é a mesma regra da sobreposição múltipla.

**Decisão:** a consulta abaixo separa população e sexo, preservando a regra histórica. Um mesmo intervalo pode entrar em várias faixas; percentuais somam 100% das associações, não de pessoas únicas. Corrigir para idades exclusivas exige uma nova metodologia.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 4, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p04-intro' FROM estudo.notebooks WHERE source_key='pdf-2025-p04' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p04-intro' AND encode(sha256(convert_to(content,'UTF8')),'hex')='15e8569c710c6957c30ad32ee6a89fd36a25038e2d5ddee45edb2acf9c5283ca') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p04-intro'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,2,'markdown','','### Idades — duas fontes, geral e por sexo

Derivação explícita do bloco do editor: executa geral/F/M em tb_resultados e vw_resultados, mantendo 13–19, sobreposição e duas casas para comparar. As repetições por fonte/sexo são intencionais.

**Linhas de origem:** `editor:03_faixa_etaria.sql.txt:4`, `datagrip:INFOGRAFICO.sql.txt:9`.

A saída representa a base atual no momento da execução; não é o snapshot usado no PDF.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 4, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p04-faixas-nota' FROM estudo.notebooks WHERE source_key='pdf-2025-p04' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p04-faixas-nota' AND encode(sha256(convert_to(content,'UTF8')),'hex')='d7e9745cd831ae0275769042bed5c0923e85699e3d19f9bd76bd928696b1bb85') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p04-faixas-nota'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,3,'code','sql','-- Idades — duas fontes, geral e por sexo
WITH q0 AS (
-- TOTAL DE CONCLUINTES POR FAIXA ETARIA

WITH faixas AS (
  SELECT 1 AS ordem, ''13–19'' AS faixa, int4range(13, 20, ''[)'') AS r UNION ALL
  SELECT 2, ''20–24'', int4range(20, 25, ''[)'') UNION ALL
  SELECT 3, ''25–29'', int4range(25, 30, ''[)'') UNION ALL
  SELECT 4, ''30–34'', int4range(30, 35, ''[)'') UNION ALL
  SELECT 5, ''35–39'', int4range(35, 40, ''[)'') UNION ALL
  SELECT 6, ''40–44'', int4range(40, 45, ''[)'') UNION ALL
  SELECT 7, ''45–49'', int4range(45, 50, ''[)'') UNION ALL
  SELECT 8, ''50–54'', int4range(50, 55, ''[)'') UNION ALL
  SELECT 9, ''55–59'', int4range(55, 60, ''[)'') UNION ALL
  SELECT 10, ''60–64'', int4range(60, 65, ''[)'') UNION ALL
  SELECT 11, ''65–69'', int4range(65, 70, ''[)'') UNION ALL
  SELECT 12, ''70+'',   int4range(70, NULL, ''[)'')
),
eventos_filtrados AS (
  SELECT DISTINCT id_evento
  FROM tb_evento_corridas
  WHERE data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
  AND pais = ''BR''
),
resultados_filtrados AS (
  SELECT a.*
  FROM tb_resultados a
  JOIN eventos_filtrados e ON e.id_evento = a.id_evento
  
),
agg AS (
  SELECT
    f.ordem,
    f.faixa,
    COUNT(rf.*) AS total
  FROM faixas f
  LEFT JOIN resultados_filtrados rf
    ON rf.idade_range && f.r
  GROUP BY f.ordem, f.faixa
)
SELECT
  faixa,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 2) AS porcentagem
FROM agg
ORDER BY ordem
),
q1 AS (
-- TOTAL DE CONCLUINTES POR FAIXA ETARIA

WITH faixas AS (
  SELECT 1 AS ordem, ''13–19'' AS faixa, int4range(13, 20, ''[)'') AS r UNION ALL
  SELECT 2, ''20–24'', int4range(20, 25, ''[)'') UNION ALL
  SELECT 3, ''25–29'', int4range(25, 30, ''[)'') UNION ALL
  SELECT 4, ''30–34'', int4range(30, 35, ''[)'') UNION ALL
  SELECT 5, ''35–39'', int4range(35, 40, ''[)'') UNION ALL
  SELECT 6, ''40–44'', int4range(40, 45, ''[)'') UNION ALL
  SELECT 7, ''45–49'', int4range(45, 50, ''[)'') UNION ALL
  SELECT 8, ''50–54'', int4range(50, 55, ''[)'') UNION ALL
  SELECT 9, ''55–59'', int4range(55, 60, ''[)'') UNION ALL
  SELECT 10, ''60–64'', int4range(60, 65, ''[)'') UNION ALL
  SELECT 11, ''65–69'', int4range(65, 70, ''[)'') UNION ALL
  SELECT 12, ''70+'',   int4range(70, NULL, ''[)'')
),
eventos_filtrados AS (
  SELECT DISTINCT id_evento
  FROM tb_evento_corridas
  WHERE data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
  AND pais = ''BR''
),
resultados_filtrados AS (
  SELECT a.*
  FROM tb_resultados a
  JOIN eventos_filtrados e ON e.id_evento = a.id_evento
  WHERE a.sexo = ''F''
),
agg AS (
  SELECT
    f.ordem,
    f.faixa,
    COUNT(rf.*) AS total
  FROM faixas f
  LEFT JOIN resultados_filtrados rf
    ON rf.idade_range && f.r
  GROUP BY f.ordem, f.faixa
)
SELECT
  faixa,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 2) AS porcentagem
FROM agg
ORDER BY ordem
),
q2 AS (
-- TOTAL DE CONCLUINTES POR FAIXA ETARIA

WITH faixas AS (
  SELECT 1 AS ordem, ''13–19'' AS faixa, int4range(13, 20, ''[)'') AS r UNION ALL
  SELECT 2, ''20–24'', int4range(20, 25, ''[)'') UNION ALL
  SELECT 3, ''25–29'', int4range(25, 30, ''[)'') UNION ALL
  SELECT 4, ''30–34'', int4range(30, 35, ''[)'') UNION ALL
  SELECT 5, ''35–39'', int4range(35, 40, ''[)'') UNION ALL
  SELECT 6, ''40–44'', int4range(40, 45, ''[)'') UNION ALL
  SELECT 7, ''45–49'', int4range(45, 50, ''[)'') UNION ALL
  SELECT 8, ''50–54'', int4range(50, 55, ''[)'') UNION ALL
  SELECT 9, ''55–59'', int4range(55, 60, ''[)'') UNION ALL
  SELECT 10, ''60–64'', int4range(60, 65, ''[)'') UNION ALL
  SELECT 11, ''65–69'', int4range(65, 70, ''[)'') UNION ALL
  SELECT 12, ''70+'',   int4range(70, NULL, ''[)'')
),
eventos_filtrados AS (
  SELECT DISTINCT id_evento
  FROM tb_evento_corridas
  WHERE data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
  AND pais = ''BR''
),
resultados_filtrados AS (
  SELECT a.*
  FROM tb_resultados a
  JOIN eventos_filtrados e ON e.id_evento = a.id_evento
  WHERE a.sexo = ''M''
),
agg AS (
  SELECT
    f.ordem,
    f.faixa,
    COUNT(rf.*) AS total
  FROM faixas f
  LEFT JOIN resultados_filtrados rf
    ON rf.idade_range && f.r
  GROUP BY f.ordem, f.faixa
)
SELECT
  faixa,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 2) AS porcentagem
FROM agg
ORDER BY ordem
),
q3 AS (
-- TOTAL DE CONCLUINTES POR FAIXA ETARIA

WITH faixas AS (
  SELECT 1 AS ordem, ''13–19'' AS faixa, int4range(13, 20, ''[)'') AS r UNION ALL
  SELECT 2, ''20–24'', int4range(20, 25, ''[)'') UNION ALL
  SELECT 3, ''25–29'', int4range(25, 30, ''[)'') UNION ALL
  SELECT 4, ''30–34'', int4range(30, 35, ''[)'') UNION ALL
  SELECT 5, ''35–39'', int4range(35, 40, ''[)'') UNION ALL
  SELECT 6, ''40–44'', int4range(40, 45, ''[)'') UNION ALL
  SELECT 7, ''45–49'', int4range(45, 50, ''[)'') UNION ALL
  SELECT 8, ''50–54'', int4range(50, 55, ''[)'') UNION ALL
  SELECT 9, ''55–59'', int4range(55, 60, ''[)'') UNION ALL
  SELECT 10, ''60–64'', int4range(60, 65, ''[)'') UNION ALL
  SELECT 11, ''65–69'', int4range(65, 70, ''[)'') UNION ALL
  SELECT 12, ''70+'',   int4range(70, NULL, ''[)'')
),
eventos_filtrados AS (
  SELECT DISTINCT id_evento
  FROM tb_evento_corridas
  WHERE data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
  AND pais = ''BR''
),
resultados_filtrados AS (
  SELECT a.*
  FROM vw_resultados a
  JOIN eventos_filtrados e ON e.id_evento = a.id_evento
  
),
agg AS (
  SELECT
    f.ordem,
    f.faixa,
    COUNT(rf.*) AS total
  FROM faixas f
  LEFT JOIN resultados_filtrados rf
    ON rf.idade_range && f.r
  GROUP BY f.ordem, f.faixa
)
SELECT
  faixa,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 2) AS porcentagem
FROM agg
ORDER BY ordem
),
q4 AS (
-- TOTAL DE CONCLUINTES POR FAIXA ETARIA

WITH faixas AS (
  SELECT 1 AS ordem, ''13–19'' AS faixa, int4range(13, 20, ''[)'') AS r UNION ALL
  SELECT 2, ''20–24'', int4range(20, 25, ''[)'') UNION ALL
  SELECT 3, ''25–29'', int4range(25, 30, ''[)'') UNION ALL
  SELECT 4, ''30–34'', int4range(30, 35, ''[)'') UNION ALL
  SELECT 5, ''35–39'', int4range(35, 40, ''[)'') UNION ALL
  SELECT 6, ''40–44'', int4range(40, 45, ''[)'') UNION ALL
  SELECT 7, ''45–49'', int4range(45, 50, ''[)'') UNION ALL
  SELECT 8, ''50–54'', int4range(50, 55, ''[)'') UNION ALL
  SELECT 9, ''55–59'', int4range(55, 60, ''[)'') UNION ALL
  SELECT 10, ''60–64'', int4range(60, 65, ''[)'') UNION ALL
  SELECT 11, ''65–69'', int4range(65, 70, ''[)'') UNION ALL
  SELECT 12, ''70+'',   int4range(70, NULL, ''[)'')
),
eventos_filtrados AS (
  SELECT DISTINCT id_evento
  FROM tb_evento_corridas
  WHERE data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
  AND pais = ''BR''
),
resultados_filtrados AS (
  SELECT a.*
  FROM vw_resultados a
  JOIN eventos_filtrados e ON e.id_evento = a.id_evento
  WHERE a.sexo = ''F''
),
agg AS (
  SELECT
    f.ordem,
    f.faixa,
    COUNT(rf.*) AS total
  FROM faixas f
  LEFT JOIN resultados_filtrados rf
    ON rf.idade_range && f.r
  GROUP BY f.ordem, f.faixa
)
SELECT
  faixa,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 2) AS porcentagem
FROM agg
ORDER BY ordem
),
q5 AS (
-- TOTAL DE CONCLUINTES POR FAIXA ETARIA

WITH faixas AS (
  SELECT 1 AS ordem, ''13–19'' AS faixa, int4range(13, 20, ''[)'') AS r UNION ALL
  SELECT 2, ''20–24'', int4range(20, 25, ''[)'') UNION ALL
  SELECT 3, ''25–29'', int4range(25, 30, ''[)'') UNION ALL
  SELECT 4, ''30–34'', int4range(30, 35, ''[)'') UNION ALL
  SELECT 5, ''35–39'', int4range(35, 40, ''[)'') UNION ALL
  SELECT 6, ''40–44'', int4range(40, 45, ''[)'') UNION ALL
  SELECT 7, ''45–49'', int4range(45, 50, ''[)'') UNION ALL
  SELECT 8, ''50–54'', int4range(50, 55, ''[)'') UNION ALL
  SELECT 9, ''55–59'', int4range(55, 60, ''[)'') UNION ALL
  SELECT 10, ''60–64'', int4range(60, 65, ''[)'') UNION ALL
  SELECT 11, ''65–69'', int4range(65, 70, ''[)'') UNION ALL
  SELECT 12, ''70+'',   int4range(70, NULL, ''[)'')
),
eventos_filtrados AS (
  SELECT DISTINCT id_evento
  FROM tb_evento_corridas
  WHERE data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
  AND pais = ''BR''
),
resultados_filtrados AS (
  SELECT a.*
  FROM vw_resultados a
  JOIN eventos_filtrados e ON e.id_evento = a.id_evento
  WHERE a.sexo = ''M''
),
agg AS (
  SELECT
    f.ordem,
    f.faixa,
    COUNT(rf.*) AS total
  FROM faixas f
  LEFT JOIN resultados_filtrados rf
    ON rf.idade_range && f.r
  GROUP BY f.ordem, f.faixa
)
SELECT
  faixa,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 2) AS porcentagem
FROM agg
ORDER BY ordem
)
SELECT ''Editor / geral'' AS versao, faixa,total,porcentagem FROM q0
UNION ALL
SELECT ''Editor / F'' AS versao, faixa,total,porcentagem FROM q1
UNION ALL
SELECT ''Editor / M'' AS versao, faixa,total,porcentagem FROM q2
UNION ALL
SELECT ''DataGrip / geral'' AS versao, faixa,total,porcentagem FROM q3
UNION ALL
SELECT ''DataGrip / F'' AS versao, faixa,total,porcentagem FROM q4
UNION ALL
SELECT ''DataGrip / M'' AS versao, faixa,total,porcentagem FROM q5;',CAST('{"tipo": "consulta_conciliacao", "pagina_pdf": 4, "fontes": ["editor:03_faixa_etaria.sql.txt:4", "datagrip:INFOGRAFICO.sql.txt:9"], "regra": "Derivação explícita do bloco do editor: executa geral/F/M em tb_resultados e vw_resultados, mantendo 13–19, sobreposição e duas casas para comparar. As repetições por fonte/sexo são intencionais.", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p04-faixas' FROM estudo.notebooks WHERE source_key='pdf-2025-p04' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p04-faixas' AND encode(sha256(convert_to(content,'UTF8')),'hex')='c31f0942aa75f7335f2ee6bbb379c79b9b6c455632e12e492929f89c3da3dab9') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p04-faixas'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,4,'markdown','','### Referência publicada — PDF v3.10.3

[Consultar a página 4](https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf#page=4). Valores transcritos; não foram recalculados.

**idades_geral** (percentual)

14–19: **6.7** | 20–24: **8.6** | 25–29: **11.1** | 30–34: **14.4** | 35–39: **14.7** | 40–44: **13.0** | 45–49: **11.0** | 50–54: **6.4** | 55–59: **5.3** | 60–64: **3.6** | 65–69: **2.9** | 70+: **2.4**

**idades_F** (percentual)

14–19: **6.1** | 20–24: **8.1** | 25–29: **11.1** | 30–34: **14.9** | 35–39: **15.2** | 40–44: **13.5** | 45–49: **11.3** | 50–54: **6.5** | 55–59: **5.2** | 60–64: **3.4** | 65–69: **2.7** | 70+: **2.2**

**idades_M** (percentual)

14–19: **7.4** | 20–24: **9.0** | 25–29: **11.2** | 30–34: **13.8** | 35–39: **14.1** | 40–44: **12.5** | 45–49: **10.7** | 50–54: **6.4** | 55–59: **5.4** | 60–64: **3.8** | 65–69: **3.1** | 70+: **2.6**

',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 4, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p04-pdf' FROM estudo.notebooks WHERE source_key='pdf-2025-p04' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p04-pdf' AND encode(sha256(convert_to(content,'UTF8')),'hex')='2b786db195cafd0dda8893c169b81fe5515a5814ce0a4b64b19eafcedcd12ef2') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p04-pdf'; END IF; END $verify$;
INSERT INTO estudo.notebooks(notebook_title,caderno_id,call_order,source_key) SELECT 'P05 — Gerações e comparações anuais',id,5,'pdf-2025-p05' FROM estudo.cadernos WHERE source_key='pdf-2025-pages-v1' ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,1,'markdown','','## P05 — Gerações e comparações anuais

**Editor:** nenhuma seção de gerações recuperada.

**DataGrip:** INFOGRAFICO, blocos 10–12; 2025 está em F, 2024 em M e 2023 geral. Os ranges deixam lacunas e não representam limites inclusivos iguais aos rótulos do PDF.

**DBA/BI:** possui id_geracao e uma função baseada em ano de nascimento estimado a partir do intervalo de idade. A função usa prioridade de correspondência e devolve zero para Alfa/não classificado. Essa regra difere das faixas fixas do DataGrip.

**Decisão:** executar as variantes históricas exatamente como salvas; a tabela BI é uma alternativa identificada, não uma substituição automática. Os percentuais comparativos do PDF exigem o mesmo sexo e regras equivalentes nos três anos.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 5, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p05-intro' FROM estudo.notebooks WHERE source_key='pdf-2025-p05' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p05-intro' AND encode(sha256(convert_to(content,'UTF8')),'hex')='14edb8c70a78bf2ee2f749af59cfa7540122f99a09bcd1840f64e9614f99e732') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p05-intro'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,2,'markdown','','### Gerações — variantes históricas disponíveis

Preserva os filtros salvos F/2025, M/2024 e geral/2023; não interpretar essa saída como evolução anual de uma população comum.

**Linhas de origem:** `datagrip:INFOGRAFICO.sql.txt:10`, `datagrip:INFOGRAFICO.sql.txt:11`, `datagrip:INFOGRAFICO.sql.txt:12`.

A saída representa a base atual no momento da execução; não é o snapshot usado no PDF.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 5, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p05-historico-nota' FROM estudo.notebooks WHERE source_key='pdf-2025-p05' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p05-historico-nota' AND encode(sha256(convert_to(content,'UTF8')),'hex')='f0b11ca900ddee69206e9b9b67651ce722dde7bc242cc1d68c539372df354bfe') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p05-historico-nota'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,3,'code','sql','-- Gerações — variantes históricas disponíveis
WITH q0 AS (
-- TOTAL DE CONCLUINTES POR GERACAO
WITH faixas AS (
  SELECT 1 AS ordem, ''Alfa'' AS faixa, int4range(0, 15, ''[)'') AS r UNION ALL
  SELECT 2, ''Z'', int4range(16, 28, ''[)'') UNION ALL
  SELECT 3, ''Y'', int4range(29, 44, ''[)'') UNION ALL
  SELECT 4, ''X'', int4range(45, 60, ''[)'') UNION ALL
  SELECT 12, ''60+'',   int4range(60, NULL, ''[)'')
),
eventos_filtrados AS (
  SELECT DISTINCT id_evento
  FROM tb_evento_corridas
  WHERE data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
  AND pais = ''BR''
),
resultados_filtrados AS (
  SELECT a.*
  FROM vw_resultados a
  JOIN eventos_filtrados e ON e.id_evento = a.id_evento
  WHERE a.sexo = ''F''
),
agg AS (
  SELECT
    f.ordem,
    f.faixa,
    COUNT(rf.*) AS total
  FROM faixas f
  LEFT JOIN resultados_filtrados rf
    ON rf.idade_range && f.r
  GROUP BY f.ordem, f.faixa
)
SELECT
  faixa,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 1) AS porcentagem
FROM agg
ORDER BY ordem
),
q1 AS (
-- TOTAL DE CONCLUINTES POR GERACAO 2024
WITH faixas AS (
  SELECT 1 AS ordem, ''Alfa'' AS faixa, int4range(0, 15, ''[)'') AS r UNION ALL
  SELECT 2, ''Z'', int4range(16, 28, ''[)'') UNION ALL
  SELECT 3, ''Y'', int4range(29, 44, ''[)'') UNION ALL
  SELECT 4, ''X'', int4range(45, 60, ''[)'') UNION ALL
  SELECT 12, ''Boomers'',   int4range(60, NULL, ''[)'')
),
eventos_filtrados AS (
  SELECT DISTINCT id_evento
  FROM tb_evento_corridas
  WHERE data_final BETWEEN DATE ''2024-01-01'' AND DATE ''2024-12-31''
  AND pais = ''BR''
),
resultados_filtrados AS (
  SELECT a.*
  FROM vw_resultados a
  JOIN eventos_filtrados e ON e.id_evento = a.id_evento
  WHERE a.sexo = ''M''
),
agg AS (
  SELECT
    f.ordem,
    f.faixa,
    COUNT(rf.*) AS total
  FROM faixas f
  LEFT JOIN resultados_filtrados rf
    ON rf.idade_range && f.r
  GROUP BY f.ordem, f.faixa
)
SELECT
  faixa,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 1) AS porcentagem
FROM agg
ORDER BY ordem
),
q2 AS (
-- TOTAL DE CONCLUINTES POR GERACAO 2023
WITH faixas AS (
  SELECT 1 AS ordem, ''Alfa'' AS faixa, int4range(0, 14, ''[)'') AS r UNION ALL
  SELECT 2, ''Z'', int4range(15, 28, ''[)'') UNION ALL
  SELECT 3, ''Y'', int4range(29, 44, ''[)'') UNION ALL
  SELECT 4, ''X'', int4range(45, 60, ''[)'') UNION ALL
  SELECT 12, ''Boomers'',   int4range(60, NULL, ''[)'')
),
eventos_filtrados AS (
  SELECT DISTINCT id_evento
  FROM tb_evento_corridas
  WHERE data_final BETWEEN DATE ''2023-01-01'' AND DATE ''2023-12-31''
  AND pais = ''BR''
),
resultados_filtrados AS (
  SELECT a.*
  FROM vw_resultados a
  JOIN eventos_filtrados e ON e.id_evento = a.id_evento
  --WHERE a.sexo = ''M''
),
agg AS (
  SELECT
    f.ordem,
    f.faixa,
    COUNT(rf.*) AS total
  FROM faixas f
  LEFT JOIN resultados_filtrados rf
    ON rf.idade_range && f.r
  GROUP BY f.ordem, f.faixa
)
SELECT
  faixa,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 1) AS porcentagem
FROM agg
ORDER BY ordem
)
SELECT ''DataGrip 2025 / F'' AS versao, faixa,total,porcentagem FROM q0
UNION ALL
SELECT ''DataGrip 2024 / M'' AS versao, faixa,total,porcentagem FROM q1
UNION ALL
SELECT ''DataGrip 2023 / geral'' AS versao, faixa,total,porcentagem FROM q2;',CAST('{"tipo": "consulta_conciliacao", "pagina_pdf": 5, "fontes": ["datagrip:INFOGRAFICO.sql.txt:10", "datagrip:INFOGRAFICO.sql.txt:11", "datagrip:INFOGRAFICO.sql.txt:12"], "regra": "Preserva os filtros salvos F/2025, M/2024 e geral/2023; não interpretar essa saída como evolução anual de uma população comum.", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p05-historico' FROM estudo.notebooks WHERE source_key='pdf-2025-p05' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p05-historico' AND encode(sha256(convert_to(content,'UTF8')),'hex')='2a20b33645aa8d7d6c4af85b55b85882894ecef7924d4885d8993fdedfa48e7e') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p05-historico'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,4,'markdown','','### Gerações — população da view BI 2025

Consulta nova sobre a view BI cuja carga veio do DBA. Usa a classificação existente e explicita a população BI; não deduz idade exata do intervalo.

**Linhas de origem:** `dba:script_perfil_br_corre_2025.sql.txt`, `dba:script_perfil_2025_segundo_semestre.txt.txt`.

A saída representa a base atual no momento da execução; não é o snapshot usado no PDF.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 5, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p05-bi-nota' FROM estudo.notebooks WHERE source_key='pdf-2025-p05' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p05-bi-nota' AND encode(sha256(convert_to(content,'UTF8')),'hex')='c976edaeb33ee7ad9ca4c137a5ba7af70f7cdf9ff04b570882557cccb3a3183d') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p05-bi-nota'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,5,'code','sql','-- Gerações — população da view BI 2025
SELECT nome_geracao,coalesce(sexo,''N/A'') AS sexo,count(*) AS total,
round(count(*)*100.0/nullif(sum(count(*)) OVER(PARTITION BY sexo),0),2) AS percentual_dentro_sexo
FROM public.vwbi_fat_perfil_br_2025 GROUP BY nome_geracao,sexo ORDER BY sexo,total DESC;',CAST('{"tipo": "consulta_conciliacao", "pagina_pdf": 5, "fontes": ["dba:script_perfil_br_corre_2025.sql.txt", "dba:script_perfil_2025_segundo_semestre.txt.txt"], "regra": "Consulta nova sobre a view BI cuja carga veio do DBA. Usa a classificação existente e explicita a população BI; não deduz idade exata do intervalo.", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p05-bi' FROM estudo.notebooks WHERE source_key='pdf-2025-p05' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p05-bi' AND encode(sha256(convert_to(content,'UTF8')),'hex')='2b06fa6d0888f974dfceba54a9237551cda2f0bf3c1f2eb6c38c146902b5ecc5') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p05-bi'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,6,'markdown','','### Referência publicada — PDF v3.10.3

[Consultar a página 5](https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf#page=5). Valores transcritos; não foram recalculados.

**geracoes_2023_geral** (percentual)

Alfa: **1.7** | Geração Z: **15.4** | Millennials: **50** | Geração X: **25.1** | Boomers: **7.8**

**geracoes_2024_geral** (percentual)

Alfa: **2.7** | Geração Z: **18** | Millennials: **50.1** | Geração X: **22.6** | Boomers: **6.7**

**geracoes_2025_geral** (percentual)

Alfa: **3.7** | Geração Z: **18.2** | Millennials: **50.5** | Geração X: **21.6** | Boomers: **6**

**geracoes_2024_F** (percentual)

Alfa: **2.5** | Geração Z: **17.8** | Millennials: **51** | Geração X: **22.6** | Boomers: **6**

**geracoes_2025_F** (percentual)

Alfa: **3.4** | Geração Z: **17.5** | Millennials: **51.7** | Geração X: **21.8** | Boomers: **5.5**

**geracoes_2024_M** (percentual)

Alfa: **2.9** | Geração Z: **18.2** | Millennials: **49.1** | Geração X: **22.5** | Boomers: **7.3**

**geracoes_2025_M** (percentual)

Alfa: **4** | Geração Z: **19** | Millennials: **49.1** | Geração X: **21.3** | Boomers: **6.6**

**variacoes_a_z** (texto_publicado)

geral versus 2023: **+4.81%** | geral versus 2024: **+1.22%** | F versus 2024: **+0.64%** | M versus 2024: **+1.91%**

Nota: Unidade a revisar: rótulos sugerem diferenças em pontos percentuais, não crescimento relativo.

',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 5, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p05-pdf' FROM estudo.notebooks WHERE source_key='pdf-2025-p05' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p05-pdf' AND encode(sha256(convert_to(content,'UTF8')),'hex')='122218780fc3bf9612b2c6c152fc34f88df1e1e1215672b5e0c74d997610cf18') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p05-pdf'; END IF; END $verify$;
INSERT INTO estudo.notebooks(notebook_title,caderno_id,call_order,source_key) SELECT 'P06 — Distâncias e participação por sexo',id,6,'pdf-2025-p06' FROM estudo.cadernos WHERE source_key='pdf-2025-pages-v1' ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,1,'markdown','','## P06 — Distâncias e participação por sexo

**Editor:** [Modalidade](https://business.roadrunners.run/estudo/?caderno=1&secao=4); [Distâncias](https://business.roadrunners.run/estudo/?caderno=1&secao=5); [Headline distâncias](https://business.roadrunners.run/estudo/?caderno=1&secao=6). Uma consulta está intitulada RUA, mas filtra trail; o agrupamento padrão de rua usa valores exatos de percurso e tb_resultados.

**DataGrip/DBA:** seis blocos de distâncias são iguais após retirar comentários/espaços; usam vw_resultados. DataGrip também traz recortes adicionais por sexo/UF/geração. Não confundir count(distinct evento) somado por faixa com total de eventos únicos: uma prova pode oferecer várias distâncias.

**Decisão:** conservar a diferença entre detalhe (floor), faixas e distâncias padrão. O diagnóstico de presença de 5 km usa um denominador de eventos únicos explícito.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 6, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p06-intro' FROM estudo.notebooks WHERE source_key='pdf-2025-p06' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p06-intro' AND encode(sha256(convert_to(content,'UTF8')),'hex')='c2a792b8bbfd70ba187e64ff5ef4f613ac221ab88866d7864ae744c2748a07ca') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p06-intro'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,2,'markdown','','### Distâncias detalhadas — DataGrip/DBA

Consulta original comum ao DataGrip e DBA: rua, vw_resultados, floor(percurso). Não equivale aos buckets por valores exatos do editor.

**Linhas de origem:** `datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:1`, `dba:INFOGRAFICO_DISTANCIAS.sql.txt:1`.

A saída representa a base atual no momento da execução; não é o snapshot usado no PDF.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 6, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p06-detalhe-nota' FROM estudo.notebooks WHERE source_key='pdf-2025-p06' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p06-detalhe-nota' AND encode(sha256(convert_to(content,'UTF8')),'hex')='ca4de2dfb6a787edd9b71019049d275626a855dd8c2f2a0af1c5d03e0c2819a3') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p06-detalhe-nota'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,3,'code','sql','-- Distâncias detalhadas — DataGrip/DBA
-- TOTAL DE CONCLUINTES POR DISTANCIA (TODAS)
SELECT
  FLOOR(res.percurso) AS percurso,
  COUNT(res.id_resultado) AS total,
  ROUND(
    COUNT(res.id_resultado) * 100.0
    / NULLIF(SUM(COUNT(res.id_resultado)) OVER (), 0),
    2
  ) AS porcentagem
FROM vw_resultados res
JOIN tb_evento_corridas evt
  ON evt.id_evento = res.id_evento
WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
  AND evt.pais = ''BR''
AND tipo_corrida = ''rua''
GROUP BY FLOOR(res.percurso)
ORDER BY total DESC;',CAST('{"tipo": "consulta_conciliacao", "pagina_pdf": 6, "fontes": ["datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:1", "dba:INFOGRAFICO_DISTANCIAS.sql.txt:1"], "regra": "Consulta original comum ao DataGrip e DBA: rua, vw_resultados, floor(percurso). Não equivale aos buckets por valores exatos do editor.", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p06-detalhe' FROM estudo.notebooks WHERE source_key='pdf-2025-p06' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p06-detalhe' AND encode(sha256(convert_to(content,'UTF8')),'hex')='89ff26290a94792aeed469bd9e9031d9cd93319d138184cc436eb53f8d8f08de') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p06-detalhe'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,4,'markdown','','### Distâncias padrão — editor versus DataGrip

Mantém os buckets e arredondamentos originais: editor duas casas, DataGrip uma. A principal diferença de população é tabela bruta versus view.

**Linhas de origem:** `editor:05_distancias.sql.txt:2`, `datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:2`.

A saída representa a base atual no momento da execução; não é o snapshot usado no PDF.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 6, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p06-padrao-nota' FROM estudo.notebooks WHERE source_key='pdf-2025-p06' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p06-padrao-nota' AND encode(sha256(convert_to(content,'UTF8')),'hex')='cdcfd67670c48b5eaac118837193e94dbaebeab1284608ed077786f17e664b93') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p06-padrao-nota'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,5,'code','sql','-- Distâncias padrão — editor versus DataGrip
WITH q0 AS (
-- TOTAL DE CONCLUINTES POR DISTANCIA (RUA)

WITH base AS (
  SELECT
    CASE
      WHEN res.percurso IN (21, 21.1) THEN ''21''
      WHEN res.percurso IN (42, 42.2) THEN ''42''
      WHEN res.percurso IN (5, 5.00) THEN ''5''
      WHEN res.percurso IN (10, 10.00) THEN ''10''
      WHEN res.percurso IN (15) THEN ''15''
      WHEN res.percurso IN (30) THEN ''30''
      ELSE ''Outras''
    END AS percurso_bucket,
    res.id_resultado
  FROM tb_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    --AND res.sexo = ''F''
    and tipo_corrida = ''rua''
),
agg AS (
  SELECT
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY percurso_bucket
)
SELECT
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 2) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''5''  THEN 1
    WHEN percurso_bucket = ''10'' THEN 2
    WHEN percurso_bucket = ''15'' THEN 3
    WHEN percurso_bucket = ''21'' THEN 4
    WHEN percurso_bucket = ''30'' THEN 5
    WHEN percurso_bucket = ''42'' THEN 6
    ELSE 99
  END
),
q1 AS (
-- TOTAL DE CONCLUINTES POR DISTANCIA PADRAO (5,10,15,21,30.42)
WITH base AS (
  SELECT
    CASE
      WHEN res.percurso IN (21, 21.1) THEN ''21''
      WHEN res.percurso IN (42, 42.2) THEN ''42''
      WHEN res.percurso IN (5, 5.00) THEN ''5''
      WHEN res.percurso IN (10, 10.00) THEN ''10''
      WHEN res.percurso IN (15) THEN ''15''
      WHEN res.percurso IN (30) THEN ''30''
      ELSE ''Outras''
    END AS percurso_bucket,
    res.id_resultado
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    --AND res.sexo = ''F''
    and tipo_corrida = ''rua''
),
agg AS (
  SELECT
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY percurso_bucket
)
SELECT
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 1) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''5''  THEN 1
    WHEN percurso_bucket = ''10'' THEN 2
    WHEN percurso_bucket = ''15'' THEN 3
    WHEN percurso_bucket = ''21'' THEN 4
    WHEN percurso_bucket = ''30'' THEN 5
    WHEN percurso_bucket = ''42'' THEN 6
    ELSE 99
  END
)
SELECT ''Editor'' AS versao, percurso,total,perc FROM q0
UNION ALL
SELECT ''DataGrip / DBA'' AS versao, percurso,total,perc FROM q1;',CAST('{"tipo": "consulta_conciliacao", "pagina_pdf": 6, "fontes": ["editor:05_distancias.sql.txt:2", "datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:2"], "regra": "Mantém os buckets e arredondamentos originais: editor duas casas, DataGrip uma. A principal diferença de população é tabela bruta versus view.", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p06-padrao' FROM estudo.notebooks WHERE source_key='pdf-2025-p06' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p06-padrao' AND encode(sha256(convert_to(content,'UTF8')),'hex')='f2ff5a9a789619919b9ed705f5217f7ec87e586d3d86d5012e98457761790b59') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p06-padrao'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,6,'markdown','','### Faixas de distância — população geral

Bloco original: os intervalos deixam eventuais frações entre 10,99 e 11 / 29,99 e 30 como Outras. Mantido para reprodução.

**Linhas de origem:** `datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:4`, `dba:INFOGRAFICO_DISTANCIAS.sql.txt:4`.

A saída representa a base atual no momento da execução; não é o snapshot usado no PDF.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 6, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p06-faixas-nota' FROM estudo.notebooks WHERE source_key='pdf-2025-p06' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p06-faixas-nota' AND encode(sha256(convert_to(content,'UTF8')),'hex')='53920ee9b4074d746e925e972a2485de25f2c5ce583004da53fade0645f81ce0') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p06-faixas-nota'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,7,'code','sql','-- Faixas de distância — população geral
-- TOTAL DE CONCLUINTES POR RANGES (< 6, 6-11, 11-30, 30+)
WITH base AS (
  SELECT
    CASE
      WHEN res.percurso < 6 THEN ''< 6''
      WHEN res.percurso BETWEEN 6 AND 10.99 THEN ''6-11''
      WHEN res.percurso BETWEEN 11 AND 29.99 THEN ''11-30''
      WHEN res.percurso >= 30 THEN ''30+''
      ELSE ''Outras''
    END AS percurso_bucket,
    res.id_resultado
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    --AND res.sexo = ''M''
    and tipo_corrida = ''rua''
),
agg AS (
  SELECT
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY percurso_bucket
)
SELECT
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 1) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''< 6''  THEN 0
    WHEN percurso_bucket = ''6-11''  THEN 1
    WHEN percurso_bucket = ''11-30'' THEN 2
    WHEN percurso_bucket = ''30+'' THEN 3
    ELSE 99
  END;',CAST('{"tipo": "consulta_conciliacao", "pagina_pdf": 6, "fontes": ["datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:4", "dba:INFOGRAFICO_DISTANCIAS.sql.txt:4"], "regra": "Bloco original: os intervalos deixam eventuais frações entre 10,99 e 11 / 29,99 e 30 como Outras. Mantido para reprodução.", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p06-faixas' FROM estudo.notebooks WHERE source_key='pdf-2025-p06' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p06-faixas' AND encode(sha256(convert_to(content,'UTF8')),'hex')='4249ddb14acc98d1ac78e2a95dfd78684062fc1b5424e03f8b6b13b27a2c2ebe') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p06-faixas'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,8,'markdown','','### Distância dentro do sexo — denominador revisado

Revisão explícita do bloco DataGrip: o original divide pelo total F+M de todas as distâncias. Para confrontar o gráfico dentro de cada sexo, acrescenta PARTITION BY sexo. Conta participações, apesar do título original mencionar provas.

**Linhas de origem:** `datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:7`.

A saída representa a base atual no momento da execução; não é o snapshot usado no PDF.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 6, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p06-sexo-nota' FROM estudo.notebooks WHERE source_key='pdf-2025-p06' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p06-sexo-nota' AND encode(sha256(convert_to(content,'UTF8')),'hex')='554bd011b9723f1d8c79968f6b8ac4d95576db7440c07af3fcc4802774084d8f') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p06-sexo-nota'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,9,'code','sql','-- Distância dentro do sexo — denominador revisado
-- TOTAL DE PROVAS POR RANGES x GENEROS (< 6, 6-11, 11-30, 30+)
WITH base AS (
  SELECT
    CASE
      WHEN res.percurso < 6 THEN ''< 6''
      WHEN res.percurso BETWEEN 6 AND 10.99 THEN ''6-11''
      WHEN res.percurso BETWEEN 11 AND 29.99 THEN ''11-30''
      WHEN res.percurso >= 30 THEN ''30+''
      ELSE ''Outras''
    END AS percurso_bucket,
    res.id_resultado,
    res.sexo
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    and tipo_corrida = ''rua''
    and res.sexo IN (''M'', ''F'')
),
agg AS (
  SELECT
    sexo,
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY sexo,percurso_bucket
)
SELECT
  sexo,
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (PARTITION BY sexo), 0), 1) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''< 6''  THEN 0
    WHEN percurso_bucket = ''6-11''  THEN 1
    WHEN percurso_bucket = ''11-30'' THEN 2
    WHEN percurso_bucket = ''30+'' THEN 3
    ELSE 99
  END;',CAST('{"tipo": "consulta_conciliacao", "pagina_pdf": 6, "fontes": ["datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:7"], "regra": "Revisão explícita do bloco DataGrip: o original divide pelo total F+M de todas as distâncias. Para confrontar o gráfico dentro de cada sexo, acrescenta PARTITION BY sexo. Conta participações, apesar do título original mencionar provas.", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p06-sexo' FROM estudo.notebooks WHERE source_key='pdf-2025-p06' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p06-sexo' AND encode(sha256(convert_to(content,'UTF8')),'hex')='a666ce7ab026028e8d888a974beca94db22a5070e6456d802c8533be4b33e6b6') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p06-sexo'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,10,'markdown','','### Presença de 5 km nos eventos com resultados

Derivação do bloco de eventos por distância. Denominador revisto: eventos únicos com resultados de rua; não soma eventos repetidos em vários buckets. Comparar ao 74,6% sem presumir a fórmula histórica.

**Linhas de origem:** `datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:3`.

A saída representa a base atual no momento da execução; não é o snapshot usado no PDF.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 6, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p06-presenca-nota' FROM estudo.notebooks WHERE source_key='pdf-2025-p06' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p06-presenca-nota' AND encode(sha256(convert_to(content,'UTF8')),'hex')='b9ce0cdb06953167adb16aa75858084b5ffa4cc6d1cfd559b958f6c5f04e1382') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p06-presenca-nota'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,11,'code','sql','-- Presença de 5 km nos eventos com resultados
SELECT count(DISTINCT evt.id_evento) AS eventos_com_resultados_rua,
 count(DISTINCT evt.id_evento) FILTER(WHERE res.percurso=5) AS eventos_com_5km,
 round(count(DISTINCT evt.id_evento) FILTER(WHERE res.percurso=5)*100.0/nullif(count(DISTINCT evt.id_evento),0),2) AS percentual
FROM public.vw_resultados res JOIN public.tb_evento_corridas evt ON evt.id_evento=res.id_evento
WHERE evt.pais=''BR'' AND evt.tipo_corrida=''rua''
AND evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31'';',CAST('{"tipo": "consulta_conciliacao", "pagina_pdf": 6, "fontes": ["datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:3"], "regra": "Derivação do bloco de eventos por distância. Denominador revisto: eventos únicos com resultados de rua; não soma eventos repetidos em vários buckets. Comparar ao 74,6% sem presumir a fórmula histórica.", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p06-presenca' FROM estudo.notebooks WHERE source_key='pdf-2025-p06' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p06-presenca' AND encode(sha256(convert_to(content,'UTF8')),'hex')='39874eab9731c5acaebaae71106f2aa10956dba6b8befd19356349100354325f') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p06-presenca'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,12,'markdown','','### Referência publicada — PDF v3.10.3

[Consultar a página 6](https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf#page=6). Valores transcritos; não foram recalculados.

**distancias_faixas** (percentual)

Até 5 km: **59.1** | 6 a 10 km: **28.4** | 11 a 29 km: **11.1** | +30 km: **1.4**

Nota: Os SQLs candidatos usam <6, 6–10.99, 11–29.99 e >=30; confirmar rótulos.

**distancias_detalhe** (percentual)

5 km: **53.96** | 10 km: **17.37** | 21 km: **6.36** | 6 km: **4.55** | 7 km: **4.02** | 4 km: **2.44** | 3 km: **2.36** | 15 km: **2.31** | 8 km: **2.01** | 42 km: **1.15** | Outras: **3.43**

**eventos_com_5km** (percentual)

5 km: **74.6**

Nota: População de eventos do denominador precisa ser confirmada.

**distancia_dentro_sexo_F** (percentual)

Até 5 km: **66.1** | 6 a 10 km: **25.2** | 11 a 29 km: **8.1** | +30 km: **0.6**

**distancia_dentro_sexo_M** (percentual)

Até 5 km: **51.2** | 6 a 10 km: **32** | 11 a 29 km: **14.5** | +30 km: **2.2**

**sexo_dentro_distancia_Até 5 km** (percentual)

F: **59.2** | M: **40.8**

**sexo_dentro_distancia_6 a 10 km** (percentual)

F: **47** | M: **53**

**sexo_dentro_distancia_11 a 29 km** (percentual)

F: **38.7** | M: **61.3**

**sexo_dentro_distancia_+30 km** (percentual)

F: **23.1** | M: **76.9**

',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 6, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p06-pdf' FROM estudo.notebooks WHERE source_key='pdf-2025-p06' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p06-pdf' AND encode(sha256(convert_to(content,'UTF8')),'hex')='1594880bf009e184ea269c2fe3efd8d1da3184386866710f438bedd7a38c401f') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p06-pdf'; END IF; END $verify$;
INSERT INTO estudo.notebooks(notebook_title,caderno_id,call_order,source_key) SELECT 'P07 — Gerações nas distâncias',id,7,'pdf-2025-p07' FROM estudo.cadernos WHERE source_key='pdf-2025-pages-v1' ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,1,'markdown','','## P07 — Gerações nas distâncias

**Editor:** não há SQL equivalente recuperado.

**DataGrip:** INFOGRAFICO_DISTANCIAS, blocos 9–10; os mesmos totais têm dois denominadores: geração dentro da distância e distância dentro da geração.

**DBA:** o arquivo de distâncias não contém esses dois blocos; a carga BI registra dimensões relacionadas, com outra população.

**Decisão:** a consulta abaixo reproduz a função get_id_geracao com CASE, conforme definição inspecionada em produção em 28/09/2026. A função não foi habilitada nem alterada no banco. Preserva ordem de prioridade e exclusão de zero; Alfa não aparece nos quatro grupos desta página.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 7, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p07-intro' FROM estudo.notebooks WHERE source_key='pdf-2025-p07' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p07-intro' AND encode(sha256(convert_to(content,'UTF8')),'hex')='56d71724b8e22c4d51a278ae16d6004d84094e28912a615ac7a808969574d8a7') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p07-intro'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,2,'markdown','','### Gerações × distâncias — os dois denominadores

Única adaptação funcional: a função SQL foi expandida literalmente como CASE. Demais filtros, denominadores e arredondamento preservados.

**Linhas de origem:** `datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:9`, `datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:10`, `public.get_id_geracao:2026-09-28`.

A saída representa a base atual no momento da execução; não é o snapshot usado no PDF.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 7, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p07-geracoes-nota' FROM estudo.notebooks WHERE source_key='pdf-2025-p07' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p07-geracoes-nota' AND encode(sha256(convert_to(content,'UTF8')),'hex')='2184d4a40da9f94ca91b33b18f484ead37b708361c2ab42a5fa17ea4ac6c4749') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p07-geracoes-nota'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,3,'code','sql','-- Gerações × distâncias — os dois denominadores
WITH q0 AS (
-- TOTAL DE PROVAS POR RANGES x GENEROS STACKED 100% (< 6, 6-11, 11-30, 30+)
WITH base AS (
  SELECT
    CASE
      WHEN res.percurso < 6 THEN ''< 6''
      WHEN res.percurso BETWEEN 6 AND 10.99 THEN ''6-11''
      WHEN res.percurso BETWEEN 11 AND 29.99 THEN ''11-30''
      WHEN res.percurso >= 30 THEN ''30+''
      ELSE ''Outras''
    END AS percurso_bucket,
    res.id_resultado,
    (CASE

        WHEN res.idade_range IS NULL OR 2025 IS NULL THEN 0
        WHEN int4range(
                 2025 - upper(res.idade_range),
                 2025 - lower(res.idade_range),
                 ''[)''
             ) && int4range(1946, 1965, ''[)'') THEN 1
        WHEN int4range(
                 2025 - upper(res.idade_range),
                 2025 - lower(res.idade_range),
                 ''[)''
             ) && int4range(1965, 1981, ''[)'') THEN 2
        WHEN int4range(
                 2025 - upper(res.idade_range),
                 2025 - lower(res.idade_range),
                 ''[)''
             ) && int4range(1981, 1996, ''[)'') THEN 3
        WHEN int4range(
                 2025 - upper(res.idade_range),
                 2025 - lower(res.idade_range),
                 ''[)''
             ) && int4range(1996, 2011, ''[)'') THEN 4
        WHEN int4range(
                 2025 - upper(res.idade_range),
                 2025 - lower(res.idade_range),
                 ''[)''
             ) && int4range(2010, NULL, ''[)'') THEN 0
        ELSE 0
    END) as id_geracao
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    and tipo_corrida = ''rua''
    and res.idade_range is not null
),
agg AS (
  SELECT
    id_geracao,
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  where id_geracao > 0
  GROUP BY id_geracao,percurso_bucket
),
agg_percurso AS (
  SELECT
    percurso_bucket,
    COUNT(id_resultado) AS total_percurso
  FROM base
  where id_geracao > 0
  GROUP BY percurso_bucket
)
SELECT
  nome_geracao AS geracao,
  agg.percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / (select sum(total_percurso) from agg_percurso where percurso_bucket = agg.percurso_bucket), 1) AS perc
FROM agg
inner join tbbi_dim_geracoes dg on dg.id_geracao = agg.id_geracao
ORDER BY
  CASE
    WHEN agg.percurso_bucket = ''< 6''  THEN 0
    WHEN agg.percurso_bucket = ''6-11''  THEN 1
    WHEN agg.percurso_bucket = ''11-30'' THEN 2
    WHEN agg.percurso_bucket = ''30+'' THEN 3
    ELSE 99
  END
),
q1 AS (
-- DISTRIBUICAO DAS GERACOES NAS DISTANCIAS (< 6, 6-11, 11-30, 30+)
WITH base AS (
  SELECT
    CASE
      WHEN res.percurso < 6 THEN ''< 6''
      WHEN res.percurso BETWEEN 6 AND 10.99 THEN ''6-11''
      WHEN res.percurso BETWEEN 11 AND 29.99 THEN ''11-30''
      WHEN res.percurso >= 30 THEN ''30+''
      ELSE ''Outras''
    END AS percurso_bucket,
    res.id_resultado,
    (CASE

        WHEN res.idade_range IS NULL OR 2025 IS NULL THEN 0
        WHEN int4range(
                 2025 - upper(res.idade_range),
                 2025 - lower(res.idade_range),
                 ''[)''
             ) && int4range(1946, 1965, ''[)'') THEN 1
        WHEN int4range(
                 2025 - upper(res.idade_range),
                 2025 - lower(res.idade_range),
                 ''[)''
             ) && int4range(1965, 1981, ''[)'') THEN 2
        WHEN int4range(
                 2025 - upper(res.idade_range),
                 2025 - lower(res.idade_range),
                 ''[)''
             ) && int4range(1981, 1996, ''[)'') THEN 3
        WHEN int4range(
                 2025 - upper(res.idade_range),
                 2025 - lower(res.idade_range),
                 ''[)''
             ) && int4range(1996, 2011, ''[)'') THEN 4
        WHEN int4range(
                 2025 - upper(res.idade_range),
                 2025 - lower(res.idade_range),
                 ''[)''
             ) && int4range(2010, NULL, ''[)'') THEN 0
        ELSE 0
    END) as id_geracao
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    and tipo_corrida = ''rua''
    and res.idade_range is not null
),
agg AS (
  SELECT
    id_geracao,
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  where id_geracao > 0
  GROUP BY id_geracao,percurso_bucket
),
agg_percurso AS (
  SELECT
    id_geracao,
    COUNT(id_resultado) AS total_percurso
  FROM base
  where id_geracao > 0
  GROUP BY id_geracao
)
SELECT
  nome_geracao AS geracao,
  agg.percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / (select sum(total_percurso) from agg_percurso where id_geracao = agg.id_geracao), 1) AS perc
FROM agg
inner join tbbi_dim_geracoes dg on dg.id_geracao = agg.id_geracao
ORDER BY
  geracao,
  CASE
    WHEN agg.percurso_bucket = ''< 6''  THEN 0
    WHEN agg.percurso_bucket = ''6-11''  THEN 1
    WHEN agg.percurso_bucket = ''11-30'' THEN 2
    WHEN agg.percurso_bucket = ''30+'' THEN 3
    ELSE 99
  END
)
SELECT ''Geração dentro da distância'' AS versao, geracao,percurso,total,perc FROM q0
UNION ALL
SELECT ''Distância dentro da geração'' AS versao, geracao,percurso,total,perc FROM q1;',CAST('{"tipo": "consulta_conciliacao", "pagina_pdf": 7, "fontes": ["datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:9", "datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:10", "public.get_id_geracao:2026-09-28"], "regra": "Única adaptação funcional: a função SQL foi expandida literalmente como CASE. Demais filtros, denominadores e arredondamento preservados.", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p07-geracoes' FROM estudo.notebooks WHERE source_key='pdf-2025-p07' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p07-geracoes' AND encode(sha256(convert_to(content,'UTF8')),'hex')='244e526b3c96c730f075d1c2ac3e27d73534342eb585abc3f98b1e7b443b5087') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p07-geracoes'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,4,'markdown','','### Referência publicada — PDF v3.10.3

[Consultar a página 7](https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf#page=7). Valores transcritos; não foram recalculados.

**geracao_dentro_distancia_Até 5 km** (percentual)

Geração Z: **8.2** | Millennials: **47.4** | Geração X: **36.2** | Boomers: **8.2**

Nota: Alfa não aparece nas séries publicadas desta página.

**geracao_dentro_distancia_6 a 10 km** (percentual)

Geração Z: **6.3** | Millennials: **46.6** | Geração X: **38.6** | Boomers: **8.5**

Nota: Alfa não aparece nas séries publicadas desta página.

**geracao_dentro_distancia_11 a 29 km** (percentual)

Geração Z: **4.7** | Millennials: **45.3** | Geração X: **43.7** | Boomers: **6.4**

Nota: Alfa não aparece nas séries publicadas desta página.

**geracao_dentro_distancia_+30 km** (percentual)

Geração Z: **2.5** | Millennials: **40.1** | Geração X: **51.7** | Boomers: **5.7**

Nota: Alfa não aparece nas séries publicadas desta página.

**distancia_dentro_geracao_Geração Z** (percentual)

Até 5 km: **68.7** | 6 a 10 km: **24.2** | 11 a 29 km: **6.8** | +30 km: **0.3**

**distancia_dentro_geracao_Millennials** (percentual)

Até 5 km: **61.4** | 6 a 10 km: **27.7** | 11 a 29 km: **10.1** | +30 km: **0.8**

**distancia_dentro_geracao_Geração X** (percentual)

Até 5 km: **58.1** | 6 a 10 km: **28.4** | 11 a 29 km: **12.1** | +30 km: **1.3**

**distancia_dentro_geracao_Boomers** (percentual)

Até 5 km: **61.6** | 6 a 10 km: **29.4** | 11 a 29 km: **8.3** | +30 km: **0.7**

',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 7, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p07-pdf' FROM estudo.notebooks WHERE source_key='pdf-2025-p07' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p07-pdf' AND encode(sha256(convert_to(content,'UTF8')),'hex')='584a91277cd1f19e924420777f5be461f019cbe36a5eeb54588daa6fc1a65291') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p07-pdf'; END IF; END $verify$;
INSERT INTO estudo.notebooks(notebook_title,caderno_id,call_order,source_key) SELECT 'P08 — Ritmo e performance',id,8,'pdf-2025-p08' FROM estudo.cadernos WHERE source_key='pdf-2025-pages-v1' ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,1,'markdown','','## P08 — Ritmo e performance

**Editor:** [Faixas de tempo](https://business.roadrunners.run/estudo/?caderno=1&secao=12); [Headline performance](https://business.roadrunners.run/estudo/?caderno=1&secao=13), população bruta geral. HTML 81: faixa 5 km / 30+ = 75,25%; PDF = 73,5%. Não são saídas idênticas.

**DataGrip:** quatro blocos de tempo fixam F ou M. **DBA:** os mesmos quatro blocos não filtram sexo; os outros seis blocos de distâncias coincidem com DataGrip.

**Decisão:** comparar geral/F/M sem ocultar fonte. Fronteiras <= são preservadas apesar do rótulo “sub”; tempo nulo vai para a última faixa e zero para a primeira. Corrigir tempos inválidos será outra revisão, pois altera a metodologia.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 8, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p08-intro' FROM estudo.notebooks WHERE source_key='pdf-2025-p08' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p08-intro' AND encode(sha256(convert_to(content,'UTF8')),'hex')='47922851e9aef604fbf9b0f034b9f951491619c6b986aaf1999fed6382633d55') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p08-intro'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,2,'markdown','','### Performance — comparar editor com DBA

Reprodução dos quatro blocos gerais em cada fonte. Tabela bruta no editor; view com homologação/status no DBA. Sem normalização de tempos nulos/zero.

**Linhas de origem:** `editor:12_faixas_de_tempo.sql.txt:1`, `editor:12_faixas_de_tempo.sql.txt:2`, `editor:12_faixas_de_tempo.sql.txt:3`, `editor:12_faixas_de_tempo.sql.txt:4`, `dba:INFOGRAFICO_DISTANCIAS.sql.txt:7`, `dba:INFOGRAFICO_DISTANCIAS.sql.txt:8`, `dba:INFOGRAFICO_DISTANCIAS.sql.txt:9`, `dba:INFOGRAFICO_DISTANCIAS.sql.txt:10`.

A saída representa a base atual no momento da execução; não é o snapshot usado no PDF.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 8, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p08-tempos-nota' FROM estudo.notebooks WHERE source_key='pdf-2025-p08' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p08-tempos-nota' AND encode(sha256(convert_to(content,'UTF8')),'hex')='3290bbeb55ba53145addfaf9aacab9bd94c13ca2157579c818399a20ae27358d') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p08-tempos-nota'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,3,'code','sql','-- Performance — comparar editor com DBA
WITH q0 AS (
--5k 
WITH base AS (
  SELECT
    CASE
      WHEN res.tempo_total <= ''00:20:00''::time THEN ''5k Sub 20''
      WHEN res.tempo_total > ''00:20:00''::time AND  res.tempo_total <= ''00:25:00''::time THEN ''5k 20-25''
      WHEN res.tempo_total > ''00:25:00''::time AND  res.tempo_total <= ''00:30:00''::time THEN ''5k 25-30''
      ELSE ''5k 30+''
    END AS percurso_bucket,
    res.tempo_total,
    res.id_resultado
  FROM tb_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    AND res.percurso = 5
    --AND res.sexo = ''F''
    and tipo_corrida = ''rua''
),
agg AS (
  SELECT
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY percurso_bucket
)
SELECT
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 2) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''5k Sub 20''  THEN 1
    WHEN percurso_bucket = ''5k 20-25''   THEN 2
    WHEN percurso_bucket = ''5k 25-30''   THEN 3
    ELSE 99
  END
),
q1 AS (
-- 5k
WITH base AS (
  SELECT
    CASE
      WHEN res.tempo_total <= ''00:20:00''::time THEN ''5k Sub 20''
      WHEN res.tempo_total > ''00:20:00''::time AND  res.tempo_total <= ''00:25:00''::time THEN ''5k 20-25''
      WHEN res.tempo_total > ''00:25:00''::time AND  res.tempo_total <= ''00:30:00''::time THEN ''5k 25-30''
      ELSE ''5k 30+''
    END AS percurso_bucket,
    res.tempo_total,
    res.id_resultado
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    AND res.percurso = 5
    --AND res.sexo = ''F''
    and tipo_corrida = ''rua''
),
agg AS (
  SELECT
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY percurso_bucket
)
SELECT
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 1) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''5k Sub 20''  THEN 1
    WHEN percurso_bucket = ''5k 20-25''   THEN 2
    WHEN percurso_bucket = ''5k 25-30''   THEN 3
    ELSE 99
  END
),
q2 AS (
-- 10k
  WITH base AS (
  SELECT
    CASE
      WHEN res.tempo_total <= ''00:40:00''::time THEN ''10k Sub 40''
      WHEN res.tempo_total > ''00:40:00''::time AND  res.tempo_total <= ''00:50:00''::time THEN ''10k 40-50''
      WHEN res.tempo_total > ''00:50:00''::time AND  res.tempo_total <= ''01:00:00''::time THEN ''10k 50-60''
      ELSE ''10k 60+''
    END AS percurso_bucket,
    res.tempo_total,
    res.id_resultado
  FROM tb_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    AND res.percurso = 10
    --AND res.sexo = ''F''
    and tipo_corrida = ''rua''
),
agg AS (
  SELECT
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY percurso_bucket
)
SELECT
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 2) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''10k Sub 40''  THEN 5
    WHEN percurso_bucket = ''10k 40-50''   THEN 6
    WHEN percurso_bucket = ''10k 50-60''   THEN 7
    ELSE 8
  END
),
q3 AS (
-- 10k
WITH base AS (
  SELECT
    CASE
      WHEN res.tempo_total <= ''00:40:00''::time THEN ''10k Sub 40''
      WHEN res.tempo_total > ''00:40:00''::time AND  res.tempo_total <= ''00:50:00''::time THEN ''10k 40-50''
      WHEN res.tempo_total > ''00:50:00''::time AND  res.tempo_total <= ''01:00:00''::time THEN ''10k 50-60''
      ELSE ''10k 60+''
    END AS percurso_bucket,
    res.tempo_total,
    res.id_resultado
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    AND res.percurso = 10
    --AND res.sexo = ''F''
    and tipo_corrida = ''rua''
),
agg AS (
  SELECT
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY percurso_bucket
)
SELECT
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 1) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''10k Sub 40''  THEN 5
    WHEN percurso_bucket = ''10k 40-50''   THEN 6
    WHEN percurso_bucket = ''10k 50-60''   THEN 7
    ELSE 8
  END
),
q4 AS (
-- 21k
  WITH base AS (
  SELECT
    CASE
      WHEN res.tempo_total <= ''01:30:00''::time THEN ''21k Sub 01:30''
      WHEN res.tempo_total > ''01:30:00''::time AND  res.tempo_total <= ''02:00:00''::time THEN ''21k 1h30 - 2h''
      WHEN res.tempo_total > ''02:00:00''::time AND  res.tempo_total <= ''02:30:00''::time THEN ''21k 2h - 2h30''
      ELSE ''21k 2h30+''
    END AS percurso_bucket,
    res.tempo_total,
    res.id_resultado
  FROM tb_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    AND res.percurso >= 21
    AND res.percurso <  22
    --AND res.sexo = ''F''
    and tipo_corrida = ''rua''
),
agg AS (
  SELECT
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY percurso_bucket
)
SELECT
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 2) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''21k Sub 01:30''  THEN 1
    WHEN percurso_bucket = ''21k 1h30 - 2h''   THEN 2
    WHEN percurso_bucket = ''21k 2h - 2h30''   THEN 3
    ELSE 4
  END
),
q5 AS (
-- 21k
WITH base AS (
SELECT
CASE
  WHEN res.tempo_total <= ''01:30:00''::time THEN ''21k Sub 01:30''
  WHEN res.tempo_total > ''01:30:00''::time AND  res.tempo_total <= ''02:00:00''::time THEN ''21k 1h30 - 2h''
  WHEN res.tempo_total > ''02:00:00''::time AND  res.tempo_total <= ''02:30:00''::time THEN ''21k 2h - 2h30''
  ELSE ''21k 2h30+''
END AS percurso_bucket,
res.tempo_total,
res.id_resultado
FROM vw_resultados res
JOIN tb_evento_corridas evt
ON evt.id_evento = res.id_evento
WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
AND evt.pais = ''BR''
AND res.percurso >= 21
AND res.percurso <  22
--AND res.sexo = ''F''
and tipo_corrida = ''rua''
),
agg AS (
  SELECT
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY percurso_bucket
)
SELECT
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 1) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''21k Sub 01:30''  THEN 1
    WHEN percurso_bucket = ''21k 1h30 - 2h''   THEN 2
    WHEN percurso_bucket = ''21k 2h - 2h30''   THEN 3
    ELSE 4
  END
),
q6 AS (
--42k 
WITH base AS (
  SELECT
    CASE
      WHEN res.tempo_total <= ''03:00:00''::time THEN ''42k Sub 3h''
      WHEN res.tempo_total > ''03:00:00''::time AND  res.tempo_total <= ''03:30:00''::time THEN ''42k 3h - 3h30''
      WHEN res.tempo_total > ''03:30:00''::time AND  res.tempo_total <= ''04:00:00''::time THEN ''42k 3h30 - 4h''
      WHEN res.tempo_total > ''04:00:00''::time AND  res.tempo_total <= ''04:30:00''::time THEN ''42k 4h - 4h30''
      ELSE ''42k 4h30+''
    END AS percurso_bucket,
    res.tempo_total,
    res.id_resultado
  FROM tb_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    AND res.percurso >= 42
    AND res.percurso <  43
    --AND res.sexo = ''F''
    and tipo_corrida = ''rua''
),
agg AS (
  SELECT
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY percurso_bucket
)
SELECT
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 2) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''42k Sub 3h''  THEN 1
    WHEN percurso_bucket = ''42k 3h - 3h30''   THEN 2
    WHEN percurso_bucket = ''42k 3h30 - 4h''   THEN 3
    WHEN percurso_bucket = ''42k 4h - 4h30''   THEN 4
    ELSE 5
  END
),
q7 AS (
-- 42k
WITH base AS (
  SELECT
    CASE
      WHEN res.tempo_total <= ''03:00:00''::time THEN ''42k Sub 3h''
      WHEN res.tempo_total > ''03:00:00''::time AND  res.tempo_total <= ''03:30:00''::time THEN ''42k 3h - 3h30''
      WHEN res.tempo_total > ''03:30:00''::time AND  res.tempo_total <= ''04:00:00''::time THEN ''42k 3h30 - 4h''
      WHEN res.tempo_total > ''04:00:00''::time AND  res.tempo_total <= ''04:30:00''::time THEN ''42k 4h - 4h30''
      ELSE ''42k 4h30+''
    END AS percurso_bucket,
    res.tempo_total,
    res.id_resultado
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    AND res.percurso >= 42
    AND res.percurso <  43
    --AND res.sexo = ''F''
    and tipo_corrida = ''rua''
),
agg AS (
  SELECT
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY percurso_bucket
)
SELECT
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 1) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''42k Sub 3h''  THEN 1
    WHEN percurso_bucket = ''42k 3h - 3h30''   THEN 2
    WHEN percurso_bucket = ''42k 3h30 - 4h''   THEN 3
    WHEN percurso_bucket = ''42k 4h - 4h30''   THEN 4
    ELSE 5
  END
)
SELECT ''editor / 5k'' AS versao, percurso,total,perc FROM q0
UNION ALL
SELECT ''dba / 5k'' AS versao, percurso,total,perc FROM q1
UNION ALL
SELECT ''editor / 10k'' AS versao, percurso,total,perc FROM q2
UNION ALL
SELECT ''dba / 10k'' AS versao, percurso,total,perc FROM q3
UNION ALL
SELECT ''editor / 21k'' AS versao, percurso,total,perc FROM q4
UNION ALL
SELECT ''dba / 21k'' AS versao, percurso,total,perc FROM q5
UNION ALL
SELECT ''editor / 42k'' AS versao, percurso,total,perc FROM q6
UNION ALL
SELECT ''dba / 42k'' AS versao, percurso,total,perc FROM q7;',CAST('{"tipo": "consulta_conciliacao", "pagina_pdf": 8, "fontes": ["editor:12_faixas_de_tempo.sql.txt:1", "editor:12_faixas_de_tempo.sql.txt:2", "editor:12_faixas_de_tempo.sql.txt:3", "editor:12_faixas_de_tempo.sql.txt:4", "dba:INFOGRAFICO_DISTANCIAS.sql.txt:7", "dba:INFOGRAFICO_DISTANCIAS.sql.txt:8", "dba:INFOGRAFICO_DISTANCIAS.sql.txt:9", "dba:INFOGRAFICO_DISTANCIAS.sql.txt:10"], "regra": "Reprodução dos quatro blocos gerais em cada fonte. Tabela bruta no editor; view com homologação/status no DBA. Sem normalização de tempos nulos/zero.", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p08-tempos' FROM estudo.notebooks WHERE source_key='pdf-2025-p08' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p08-tempos' AND encode(sha256(convert_to(content,'UTF8')),'hex')='9307917c333cc1726ba455f62abb6092b2958e7c031ac944cad3b64162f658c9') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p08-tempos'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,4,'markdown','','### Performance — filtros por sexo salvos no DataGrip

Mantém literalmente o sexo fixado em cada bloco DataGrip; conferir o WHERE antes de usar como série F ou M.

**Linhas de origem:** `datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:11`, `datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:12`, `datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:13`, `datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:14`.

A saída representa a base atual no momento da execução; não é o snapshot usado no PDF.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 8, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p08-sexo-nota' FROM estudo.notebooks WHERE source_key='pdf-2025-p08' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p08-sexo-nota' AND encode(sha256(convert_to(content,'UTF8')),'hex')='be0bb20af697cdbaee12fd43b6c441aefae496f1db4201b8a7dd7273ab0ad79b') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p08-sexo-nota'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,5,'code','sql','-- Performance — filtros por sexo salvos no DataGrip
WITH q0 AS (
-- 5k
WITH base AS (
  SELECT
    CASE
      WHEN res.tempo_total <= ''00:20:00''::time THEN ''5k Sub 20''
      WHEN res.tempo_total > ''00:20:00''::time AND  res.tempo_total <= ''00:25:00''::time THEN ''5k 20-25''
      WHEN res.tempo_total > ''00:25:00''::time AND  res.tempo_total <= ''00:30:00''::time THEN ''5k 25-30''
      ELSE ''5k 30+''
    END AS percurso_bucket,
    res.tempo_total,
    res.id_resultado
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    AND res.percurso = 5
    AND res.sexo = ''F''
    and tipo_corrida = ''rua''
),
agg AS (
  SELECT
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY percurso_bucket
)
SELECT
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 1) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''5k Sub 20''  THEN 1
    WHEN percurso_bucket = ''5k 20-25''   THEN 2
    WHEN percurso_bucket = ''5k 25-30''   THEN 3
    ELSE 99
  END
),
q1 AS (
-- 10k
WITH base AS (
  SELECT
    CASE
      WHEN res.tempo_total <= ''00:40:00''::time THEN ''10k Sub 40''
      WHEN res.tempo_total > ''00:40:00''::time AND  res.tempo_total <= ''00:50:00''::time THEN ''10k 40-50''
      WHEN res.tempo_total > ''00:50:00''::time AND  res.tempo_total <= ''01:00:00''::time THEN ''10k 50-60''
      ELSE ''10k 60+''
    END AS percurso_bucket,
    res.tempo_total,
    res.id_resultado
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    AND res.percurso = 10
    AND res.sexo = ''M''
    and tipo_corrida = ''rua''
),
agg AS (
  SELECT
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY percurso_bucket
)
SELECT
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 1) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''10k Sub 40''  THEN 5
    WHEN percurso_bucket = ''10k 40-50''   THEN 6
    WHEN percurso_bucket = ''10k 50-60''   THEN 7
    ELSE 8
  END
),
q2 AS (
-- 21k
WITH base AS (
SELECT
CASE
  WHEN res.tempo_total <= ''01:30:00''::time THEN ''21k Sub 01:30''
  WHEN res.tempo_total > ''01:30:00''::time AND  res.tempo_total <= ''02:00:00''::time THEN ''21k 1h30 - 2h''
  WHEN res.tempo_total > ''02:00:00''::time AND  res.tempo_total <= ''02:30:00''::time THEN ''21k 2h - 2h30''
  ELSE ''21k 2h30+''
END AS percurso_bucket,
res.tempo_total,
res.id_resultado
FROM vw_resultados res
JOIN tb_evento_corridas evt
ON evt.id_evento = res.id_evento
WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
AND evt.pais = ''BR''
AND res.percurso >= 21
AND res.percurso <  22
AND res.sexo = ''M''
and tipo_corrida = ''rua''
),
agg AS (
  SELECT
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY percurso_bucket
)
SELECT
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 1) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''21k Sub 01:30''  THEN 1
    WHEN percurso_bucket = ''21k 1h30 - 2h''   THEN 2
    WHEN percurso_bucket = ''21k 2h - 2h30''   THEN 3
    ELSE 4
  END
),
q3 AS (
-- 42k
WITH base AS (
  SELECT
    CASE
      WHEN res.tempo_total <= ''03:00:00''::time THEN ''42k Sub 3h''
      WHEN res.tempo_total > ''03:00:00''::time AND  res.tempo_total <= ''03:30:00''::time THEN ''42k 3h - 3h30''
      WHEN res.tempo_total > ''03:30:00''::time AND  res.tempo_total <= ''04:00:00''::time THEN ''42k 3h30 - 4h''
      WHEN res.tempo_total > ''04:00:00''::time AND  res.tempo_total <= ''04:30:00''::time THEN ''42k 4h - 4h30''
      ELSE ''42k 4h30+''
    END AS percurso_bucket,
    res.tempo_total,
    res.id_resultado
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    AND res.percurso >= 42
    AND res.percurso <  43
    AND res.sexo = ''M''
    and tipo_corrida = ''rua''
),
agg AS (
  SELECT
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY percurso_bucket
)
SELECT
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 1) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''42k Sub 3h''  THEN 1
    WHEN percurso_bucket = ''42k 3h - 3h30''   THEN 2
    WHEN percurso_bucket = ''42k 3h30 - 4h''   THEN 3
    WHEN percurso_bucket = ''42k 4h - 4h30''   THEN 4
    ELSE 5
  END
)
SELECT ''DataGrip / 5k / F'' AS versao, percurso,total,perc FROM q0
UNION ALL
SELECT ''DataGrip / 10k / M'' AS versao, percurso,total,perc FROM q1
UNION ALL
SELECT ''DataGrip / 21k / M'' AS versao, percurso,total,perc FROM q2
UNION ALL
SELECT ''DataGrip / 42k / M'' AS versao, percurso,total,perc FROM q3;',CAST('{"tipo": "consulta_conciliacao", "pagina_pdf": 8, "fontes": ["datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:11", "datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:12", "datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:13", "datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:14"], "regra": "Mantém literalmente o sexo fixado em cada bloco DataGrip; conferir o WHERE antes de usar como série F ou M.", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p08-sexo' FROM estudo.notebooks WHERE source_key='pdf-2025-p08' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p08-sexo' AND encode(sha256(convert_to(content,'UTF8')),'hex')='458d73b37563e7826fd698c83b0db4d56e279fd0342110178e43eeae5825b9c7') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p08-sexo'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,6,'markdown','','### Referência publicada — PDF v3.10.3

[Consultar a página 8](https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf#page=8). Valores transcritos; não foram recalculados.

**performance_5k_geral** (percentual)

<20min: **2** | 20–25min: **8.3** | 25–30min: **16.3** | 30+min: **73.5**

Nota: Rótulos preservados; SQL usa <= em fronteiras publicadas como <. <4:00 é a terceira faixa, não acumulado.

**performance_5k_F** (percentual)

<20min: **0.2** | 20–25min: **2.7** | 25–30min: **11.3** | 30+min: **85.9**

Nota: Rótulos preservados; SQL usa <= em fronteiras publicadas como <. <4:00 é a terceira faixa, não acumulado.

**performance_5k_M** (percentual)

<20min: **4.5** | 20–25min: **16.2** | 25–30min: **23.3** | 30+min: **56**

Nota: Rótulos preservados; SQL usa <= em fronteiras publicadas como <. <4:00 é a terceira faixa, não acumulado.

**performance_10k_geral** (percentual)

<40min: **2.5** | 40–50min: **14.1** | 50–60min: **30.6** | 60+min: **52.8**

Nota: Rótulos preservados; SQL usa <= em fronteiras publicadas como <. <4:00 é a terceira faixa, não acumulado.

**performance_10k_F** (percentual)

<40min: **0.5** | 40–50min: **5.1** | 50–60min: **24.3** | 60+min: **70.1**

Nota: Rótulos preservados; SQL usa <= em fronteiras publicadas como <. <4:00 é a terceira faixa, não acumulado.

**performance_10k_M** (percentual)

<40min: **4** | 40–50min: **20.7** | 50–60min: **35.1** | 60+min: **40.1**

Nota: Rótulos preservados; SQL usa <= em fronteiras publicadas como <. <4:00 é a terceira faixa, não acumulado.

**performance_21k_geral** (percentual)

<1:30: **4.1** | 1:30–2:00: **40.3** | 2:00–2:30: **41.2** | 2:30+: **14.3**

Nota: Rótulos preservados; SQL usa <= em fronteiras publicadas como <. <4:00 é a terceira faixa, não acumulado.

**performance_21k_F** (percentual)

<1:30: **0.7** | 1:30–2:00: **25.2** | 2:00–2:30: **52.4** | 2:30+: **21.7**

Nota: Rótulos preservados; SQL usa <= em fronteiras publicadas como <. <4:00 é a terceira faixa, não acumulado.

**performance_21k_M** (percentual)

<1:30: **6.1** | 1:30–2:00: **48.9** | 2:00–2:30: **34.9** | 2:30+: **10.1**

Nota: Rótulos preservados; SQL usa <= em fronteiras publicadas como <. <4:00 é a terceira faixa, não acumulado.

**performance_42k_geral** (percentual)

<3:00: **3.8** | 3:00–3:30: **12.6** | <4:00: **26.5** | 4:00–4:30: **24.6** | 4:30+: **32.4**

Nota: Rótulos preservados; SQL usa <= em fronteiras publicadas como <. <4:00 é a terceira faixa, não acumulado.

**performance_42k_F** (percentual)

<3:00: **0.7** | 3:00–3:30: **4.5** | <4:00: **20.5** | 4:00–4:30: **27.7** | 4:30+: **46.6**

Nota: Rótulos preservados; SQL usa <= em fronteiras publicadas como <. <4:00 é a terceira faixa, não acumulado.

**performance_42k_M** (percentual)

<3:00: **4.8** | 3:00–3:30: **15** | <4:00: **28.3** | 4:00–4:30: **23.7** | 4:30+: **28.2**

Nota: Rótulos preservados; SQL usa <= em fronteiras publicadas como <. <4:00 é a terceira faixa, não acumulado.

',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 8, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p08-pdf' FROM estudo.notebooks WHERE source_key='pdf-2025-p08' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p08-pdf' AND encode(sha256(convert_to(content,'UTF8')),'hex')='357dbf2e046f71ecade6e27a4b1c78d0df2a56a62aefbc31f1ca9a461ab25aa8') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p08-pdf'; END IF; END $verify$;
INSERT INTO estudo.notebooks(notebook_title,caderno_id,call_order,source_key) SELECT 'P09 — Regiões e gênero',id,9,'pdf-2025-p09' FROM estudo.cadernos WHERE source_key='pdf-2025-pages-v1' ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,1,'markdown','','## P09 — Regiões e gênero

**Editor:** [UFs](https://business.roadrunners.run/estudo/?caderno=1&secao=7). O segundo bloco seleciona uf.uf como regiao; o HTML 75 contém SE/NE/S/CO/N. O HTML foi atualizado em 30/01 e o SQL em 01/02/2026: vínculo de execução não comprovado.

**DataGrip:** INFOGRAFICO, bloco 15, usa uf.regiao corretamente, mas está fixo em 2024/M.

**DBA:** cruza cidade por nome sem UF e pode perder/multiplicar linhas. O bloco chamado capital/interior também contém sexo por região; não é equivalente ao agrupamento direto pela UF do evento.

**Decisão:** derivar de DataGrip com ano/sexo explícitos. A correção do bloco do editor é uf.uf → uf.regiao, registrada como derivação; o original não foi sobrescrito.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 9, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p09-intro' FROM estudo.notebooks WHERE source_key='pdf-2025-p09' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p09-intro' AND encode(sha256(convert_to(content,'UTF8')),'hex')='ea27869a08d7ff171e53c365c32011173bf435a0ebaeede89be32ebca2821575') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p09-intro'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,2,'markdown','','### Regiões — 2024/2025, geral/F/M

Derivação explícita do bloco DataGrip: seis recortes com os mesmos filtros de resultado. Percentual da região dentro do sexo/ano; não confundir com participação F/M dentro de cada região.

**Linhas de origem:** `datagrip:INFOGRAFICO.sql.txt:15`, `editor:07_ufs.sql.txt:2`.

A saída representa a base atual no momento da execução; não é o snapshot usado no PDF.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 9, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p09-regioes-nota' FROM estudo.notebooks WHERE source_key='pdf-2025-p09' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p09-regioes-nota' AND encode(sha256(convert_to(content,'UTF8')),'hex')='280fe1107f215e60e5875c0641439cc820e5ff1d9f3ace214b098040671b92f8') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p09-regioes-nota'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,3,'code','sql','-- Regiões — 2024/2025, geral/F/M
WITH q0 AS (
-- TOTAL DE CONCLUINTES POR REGIAO
SELECT
  COALESCE(uf.regiao, ''N/A'') AS regiao,
  COUNT(res.id_resultado) AS total,
  ROUND(
    COUNT(res.id_resultado) * 100.0
    / NULLIF(SUM(COUNT(res.id_resultado)) OVER (), 0),
    1
  ) AS porcentagem
FROM vw_resultados res
JOIN tb_evento_corridas evt
  ON evt.id_evento = res.id_evento
LEFT JOIN tb_uf uf
  ON uf.uf = evt.estado
WHERE evt.data_final BETWEEN DATE ''2024-01-01'' AND DATE ''2024-12-31''
  AND evt.pais = ''BR''
  
GROUP BY COALESCE(uf.regiao, ''N/A'')
ORDER BY total DESC
),
q1 AS (
-- TOTAL DE CONCLUINTES POR REGIAO
SELECT
  COALESCE(uf.regiao, ''N/A'') AS regiao,
  COUNT(res.id_resultado) AS total,
  ROUND(
    COUNT(res.id_resultado) * 100.0
    / NULLIF(SUM(COUNT(res.id_resultado)) OVER (), 0),
    1
  ) AS porcentagem
FROM vw_resultados res
JOIN tb_evento_corridas evt
  ON evt.id_evento = res.id_evento
LEFT JOIN tb_uf uf
  ON uf.uf = evt.estado
WHERE evt.data_final BETWEEN DATE ''2024-01-01'' AND DATE ''2024-12-31''
  AND evt.pais = ''BR''
  AND res.sexo = ''F''
GROUP BY COALESCE(uf.regiao, ''N/A'')
ORDER BY total DESC
),
q2 AS (
-- TOTAL DE CONCLUINTES POR REGIAO
SELECT
  COALESCE(uf.regiao, ''N/A'') AS regiao,
  COUNT(res.id_resultado) AS total,
  ROUND(
    COUNT(res.id_resultado) * 100.0
    / NULLIF(SUM(COUNT(res.id_resultado)) OVER (), 0),
    1
  ) AS porcentagem
FROM vw_resultados res
JOIN tb_evento_corridas evt
  ON evt.id_evento = res.id_evento
LEFT JOIN tb_uf uf
  ON uf.uf = evt.estado
WHERE evt.data_final BETWEEN DATE ''2024-01-01'' AND DATE ''2024-12-31''
  AND evt.pais = ''BR''
  AND res.sexo = ''M''
GROUP BY COALESCE(uf.regiao, ''N/A'')
ORDER BY total DESC
),
q3 AS (
-- TOTAL DE CONCLUINTES POR REGIAO
SELECT
  COALESCE(uf.regiao, ''N/A'') AS regiao,
  COUNT(res.id_resultado) AS total,
  ROUND(
    COUNT(res.id_resultado) * 100.0
    / NULLIF(SUM(COUNT(res.id_resultado)) OVER (), 0),
    1
  ) AS porcentagem
FROM vw_resultados res
JOIN tb_evento_corridas evt
  ON evt.id_evento = res.id_evento
LEFT JOIN tb_uf uf
  ON uf.uf = evt.estado
WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
  AND evt.pais = ''BR''
  
GROUP BY COALESCE(uf.regiao, ''N/A'')
ORDER BY total DESC
),
q4 AS (
-- TOTAL DE CONCLUINTES POR REGIAO
SELECT
  COALESCE(uf.regiao, ''N/A'') AS regiao,
  COUNT(res.id_resultado) AS total,
  ROUND(
    COUNT(res.id_resultado) * 100.0
    / NULLIF(SUM(COUNT(res.id_resultado)) OVER (), 0),
    1
  ) AS porcentagem
FROM vw_resultados res
JOIN tb_evento_corridas evt
  ON evt.id_evento = res.id_evento
LEFT JOIN tb_uf uf
  ON uf.uf = evt.estado
WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
  AND evt.pais = ''BR''
  AND res.sexo = ''F''
GROUP BY COALESCE(uf.regiao, ''N/A'')
ORDER BY total DESC
),
q5 AS (
-- TOTAL DE CONCLUINTES POR REGIAO
SELECT
  COALESCE(uf.regiao, ''N/A'') AS regiao,
  COUNT(res.id_resultado) AS total,
  ROUND(
    COUNT(res.id_resultado) * 100.0
    / NULLIF(SUM(COUNT(res.id_resultado)) OVER (), 0),
    1
  ) AS porcentagem
FROM vw_resultados res
JOIN tb_evento_corridas evt
  ON evt.id_evento = res.id_evento
LEFT JOIN tb_uf uf
  ON uf.uf = evt.estado
WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
  AND evt.pais = ''BR''
  AND res.sexo = ''M''
GROUP BY COALESCE(uf.regiao, ''N/A'')
ORDER BY total DESC
)
SELECT ''2024 / geral'' AS versao, regiao,total,porcentagem FROM q0
UNION ALL
SELECT ''2024 / F'' AS versao, regiao,total,porcentagem FROM q1
UNION ALL
SELECT ''2024 / M'' AS versao, regiao,total,porcentagem FROM q2
UNION ALL
SELECT ''2025 / geral'' AS versao, regiao,total,porcentagem FROM q3
UNION ALL
SELECT ''2025 / F'' AS versao, regiao,total,porcentagem FROM q4
UNION ALL
SELECT ''2025 / M'' AS versao, regiao,total,porcentagem FROM q5;',CAST('{"tipo": "consulta_conciliacao", "pagina_pdf": 9, "fontes": ["datagrip:INFOGRAFICO.sql.txt:15", "editor:07_ufs.sql.txt:2"], "regra": "Derivação explícita do bloco DataGrip: seis recortes com os mesmos filtros de resultado. Percentual da região dentro do sexo/ano; não confundir com participação F/M dentro de cada região.", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p09-regioes' FROM estudo.notebooks WHERE source_key='pdf-2025-p09' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p09-regioes' AND encode(sha256(convert_to(content,'UTF8')),'hex')='1b31ba2b6068e028299020fcf411b5a9faf6e775a7451debcfff2c9b7bcbbc6b') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p09-regioes'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,4,'markdown','','### Referência publicada — PDF v3.10.3

[Consultar a página 9](https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf#page=9). Valores transcritos; não foram recalculados.

**regioes_2024** (percentual)

Sudeste: **49.4** | Nordeste: **19.3** | Sul: **18.1** | Centro-Oeste: **9.1** | Norte: **4.1**

**regioes_2025** (percentual)

Sudeste: **47.6** | Nordeste: **19.7** | Sul: **17.5** | Centro-Oeste: **9.3** | Norte: **5.8**

**sexo_por_regiao_Norte** (percentual)

F: **55.5** | M: **44.5**

**sexo_por_regiao_Nordeste** (percentual)

F: **51.5** | M: **48.5**

**sexo_por_regiao_Centro-Oeste** (percentual)

F: **56** | M: **44**

**sexo_por_regiao_Sudeste** (percentual)

F: **53.8** | M: **46.2**

**sexo_por_regiao_Sul** (percentual)

F: **50.9** | M: **49.1**

**regioes_feminino_rotulos_visiveis** (percentual)

Sudeste: **50.5** | Nordeste: **18.8** | Sul: **17.1** | Centro-Oeste: **9.4**

Nota: Parcial: rótulo de Norte não aparece no gráfico. Não completar por diferença.

**regioes_masculino_rotulos_visiveis** (percentual)

Sudeste: **48.3** | Nordeste: **19.8** | Sul: **19.2** | Centro-Oeste: **8.8**

Nota: Parcial: rótulo de Norte não aparece no gráfico. Não completar por diferença.

',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 9, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p09-pdf' FROM estudo.notebooks WHERE source_key='pdf-2025-p09' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p09-pdf' AND encode(sha256(convert_to(content,'UTF8')),'hex')='c9ea2c63b0ccc58ff501b758ff0c274c5c4ef8446e4c9fef67b6f73d85a4c3fc') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p09-pdf'; END IF; END $verify$;
INSERT INTO estudo.notebooks(notebook_title,caderno_id,call_order,source_key) SELECT 'P10 — Estados, cidades e capital/interior',id,10,'pdf-2025-p10' FROM estudo.cadernos WHERE source_key='pdf-2025-pages-v1' ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,1,'markdown','','## P10 — Estados, cidades e capital/interior

**Editor:** [UFs](https://business.roadrunners.run/estudo/?caderno=1&secao=7); [Concentração de mercado](https://business.roadrunners.run/estudo/?caderno=1&secao=8); estados vêm diretamente de evt.estado, sem cruzar cidades. **DataGrip:** INFOGRAFICO, blocos 13–14; cidades são agrupadas apenas por nome, reunindo homônimas de UFs diferentes.

**DBA:** regiao_capital_interior é uma fonte candidata, mas o primeiro SELECT usa uma coluna total inexistente e divide pelo total nacional. O relacionamento nome_cidade=evt.cidade não usa UF. Auditoria de 27/09: 434.079 participações sem correspondência; 381.706 linhas ligadas a outra UF. Esses efeitos pertencem àquela regra/população, não ao PDF inteiro.

**Decisão:** estados são comparáveis por fonte; cidades ganham UF na consulta candidata. Capital/interior abaixo usa id_localidade já presente na fato BI e contabiliza ausentes; tem população diferente e não certifica o gráfico histórico. O percentual é exibido dentro de cada região e com não classificados visíveis.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 10, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p10-intro' FROM estudo.notebooks WHERE source_key='pdf-2025-p10' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p10-intro' AND encode(sha256(convert_to(content,'UTF8')),'hex')='4f0be94363788abb3fca8d5b74148af73e58fd3e5ab3d5879b2cf264b504726f') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p10-intro'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,2,'markdown','','### Estados — editor versus DataGrip

Consulta original em cada fonte. A diferença de status/homologação permanece visível.

**Linhas de origem:** `editor:07_ufs.sql.txt:1`, `datagrip:INFOGRAFICO.sql.txt:13`.

A saída representa a base atual no momento da execução; não é o snapshot usado no PDF.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 10, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p10-ufs-nota' FROM estudo.notebooks WHERE source_key='pdf-2025-p10' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p10-ufs-nota' AND encode(sha256(convert_to(content,'UTF8')),'hex')='996325562342708a3055d53ff83b325711dcdce95ee4e63e1906d46fb2b64dea') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p10-ufs-nota'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,3,'code','sql','-- Estados — editor versus DataGrip
WITH q0 AS (
-- TOTAL DE CONCLUINTES POR ESTADO

SELECT
  COALESCE(evt.estado, ''N/A'') AS estado,
  COUNT(res.id_resultado) AS total,
  ROUND(
    COUNT(res.id_resultado) * 100.0
    / NULLIF(SUM(COUNT(res.id_resultado)) OVER (), 0),
    1
  ) AS porcentagem
FROM tb_resultados res
JOIN tb_evento_corridas evt
  ON evt.id_evento = res.id_evento
WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
  AND evt.pais = ''BR''
GROUP BY COALESCE(evt.estado, ''N/A'')
ORDER BY total DESC
),
q1 AS (
-- TOTAL DE CONCLUINTES POR ESTADO
SELECT
  COALESCE(evt.estado, ''N/A'') AS estado,
  COUNT(res.id_resultado) AS total,
  ROUND(
    COUNT(res.id_resultado) * 100.0
    / NULLIF(SUM(COUNT(res.id_resultado)) OVER (), 0),
    1
  ) AS porcentagem
FROM vw_resultados res
JOIN tb_evento_corridas evt
  ON evt.id_evento = res.id_evento
WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
  AND evt.pais = ''BR''
GROUP BY COALESCE(evt.estado, ''N/A'')
ORDER BY total DESC
)
SELECT ''Editor'' AS versao, estado,total,porcentagem FROM q0
UNION ALL
SELECT ''DataGrip'' AS versao, estado,total,porcentagem FROM q1;',CAST('{"tipo": "consulta_conciliacao", "pagina_pdf": 10, "fontes": ["editor:07_ufs.sql.txt:1", "datagrip:INFOGRAFICO.sql.txt:13"], "regra": "Consulta original em cada fonte. A diferença de status/homologação permanece visível.", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p10-ufs' FROM estudo.notebooks WHERE source_key='pdf-2025-p10' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p10-ufs' AND encode(sha256(convert_to(content,'UTF8')),'hex')='a8779ec92a887de05bde6554b892bc896b44e5a3e24ebd353996544b1d4e7ddf') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p10-ufs'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,4,'markdown','','### Cidades com UF — candidato revisado

Nova revisão baseada no bloco DataGrip: acrescenta UF, normaliza apenas caixa/espaços e mantém acentos distintos. Top 50 para revisão; percentual usa todas as cidades antes do LIMIT. Ainda não é a normalização definitiva por ID de localidade.

**Linhas de origem:** `datagrip:INFOGRAFICO.sql.txt:14`.

A saída representa a base atual no momento da execução; não é o snapshot usado no PDF.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 10, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p10-cidades-nota' FROM estudo.notebooks WHERE source_key='pdf-2025-p10' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p10-cidades-nota' AND encode(sha256(convert_to(content,'UTF8')),'hex')='fb345a44e74d5a7b87f32ce34e1660491d68481c25e5dad8f7e41dc47c98a5e3') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p10-cidades-nota'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,5,'code','sql','-- Cidades com UF — candidato revisado
SELECT coalesce(upper(btrim(evt.estado)),''N/A'') AS uf,
 coalesce(upper(btrim(evt.cidade)),''N/A'') AS cidade,count(*) AS total,
 round(count(*)*100.0/nullif(sum(count(*)) OVER(),0),2) AS percentual
FROM public.vw_resultados res JOIN public.tb_evento_corridas evt ON evt.id_evento=res.id_evento
WHERE evt.pais=''BR'' AND evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
GROUP BY upper(btrim(evt.estado)),upper(btrim(evt.cidade)) ORDER BY total DESC LIMIT 50;',CAST('{"tipo": "consulta_conciliacao", "pagina_pdf": 10, "fontes": ["datagrip:INFOGRAFICO.sql.txt:14"], "regra": "Nova revisão baseada no bloco DataGrip: acrescenta UF, normaliza apenas caixa/espaços e mantém acentos distintos. Top 50 para revisão; percentual usa todas as cidades antes do LIMIT. Ainda não é a normalização definitiva por ID de localidade.", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p10-cidades' FROM estudo.notebooks WHERE source_key='pdf-2025-p10' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p10-cidades' AND encode(sha256(convert_to(content,'UTF8')),'hex')='3b1cc76899663992236954373028b57895098f361d73b76f4eb23d0be32b484c') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p10-cidades'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,6,'markdown','','### Capital/interior — candidato pelo ID da fato BI

Nova metodologia candidata: LEFT JOIN pelo id_localidade da fato; preserva registros sem dimensão. Mede participações da fato BI, não da view BI nem a população bruta do editor. Não usar para substituir silenciosamente 2025.

**Linhas de origem:** `dba:regiao_capital_interior.sql.txt`, `dba:script_perfil_br_corre_2025.sql.txt`.

A saída representa a base atual no momento da execução; não é o snapshot usado no PDF.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 10, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p10-capital-nota' FROM estudo.notebooks WHERE source_key='pdf-2025-p10' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p10-capital-nota' AND encode(sha256(convert_to(content,'UTF8')),'hex')='3e9c5f7dd0d8c64ca3666b5d0ee61b677c625a3d45bbf66e77156cdaaeae0055') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p10-capital-nota'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,7,'code','sql','-- Capital/interior — candidato pelo ID da fato BI
WITH contagens AS (
 SELECT coalesce(l.regiao,''Não classificada'') AS regiao,
 CASE WHEN l.capital IS TRUE THEN ''Capital'' WHEN l.capital IS FALSE THEN ''Interior'' ELSE ''Não classificada'' END AS tipo,
 count(*) AS total
 FROM public.tbbi_fat_perfil_br_2025 f LEFT JOIN public.tbbi_dim_localidade l ON l.id_localidade=f.id_localidade
 WHERE f.data_evento>=DATE ''2025-01-01'' AND f.data_evento<DATE ''2026-01-01''
 GROUP BY coalesce(l.regiao,''Não classificada''),l.capital
)
SELECT regiao,tipo,total,
 round(total*100.0/nullif(sum(total) OVER(PARTITION BY regiao),0),2) AS percentual_dentro_regiao,
 round(total*100.0/nullif(sum(total) OVER(),0),2) AS percentual_nacional
FROM contagens ORDER BY regiao,tipo;',CAST('{"tipo": "consulta_conciliacao", "pagina_pdf": 10, "fontes": ["dba:regiao_capital_interior.sql.txt", "dba:script_perfil_br_corre_2025.sql.txt"], "regra": "Nova metodologia candidata: LEFT JOIN pelo id_localidade da fato; preserva registros sem dimensão. Mede participações da fato BI, não da view BI nem a população bruta do editor. Não usar para substituir silenciosamente 2025.", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p10-capital' FROM estudo.notebooks WHERE source_key='pdf-2025-p10' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p10-capital' AND encode(sha256(convert_to(content,'UTF8')),'hex')='361857bf52d2aed9de109bea35122cb125eead44d196f4c8c3a92d95b47f7e04') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p10-capital'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,8,'markdown','','### Referência publicada — PDF v3.10.3

[Consultar a página 10](https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf#page=10). Valores transcritos; não foram recalculados.

**ufs** (percentual)

SP: **26.2** | RJ: **12.5** | PR: **8.3** | MG: **6.5** | SC: **6** | BA: **5** | DF: **4.4** | CE: **3.8** | RS: **3.2** | PE: **3** | PA: **2.8** | GO: **2.8** | PB: **2.7** | ES: **2.4** | RN: **1.7** | MT: **1.6** | SE: **1.5** | AM: **1.3** | AL: **1.1** | MA: **0.6** | MS: **0.5** | RO: **0.5** | AP: **0.4** | RR: **0.4** | TO: **0.4** | PI: **0.4** | AC: **0.1**

**ufs_top_grafico** (percentual)

SP: **26.2** | RJ: **12.5** | PR: **8.3** | MG: **6.5** | SC: **6** | BA: **5** | DF: **4.4** | CE: **3.8** | RS: **3.2** | Outros: **24.1**

Nota: Título Top 10; contém nove UFs e Outros.

**cidades** (percentual)

São Paulo: **12.4** | Rio de Janeiro: **10.8** | Belo Horizonte: **4.8** | Brasília: **4.4** | Curitiba: **3** | Salvador: **2.8** | Fortaleza: **2.6** | Porto Alegre: **1.7** | Belém: **1.6** | Recife: **1.6** | Florianópolis: **1.5** | Goiânia: **1.4** | João Pessoa: **1.4** | Santos: **1.3**

Nota: Somente cidades listadas. Percentuais são do universo nacional, não normalizar este subconjunto para 100%.

**capital_interior_Brasil** (percentual)

Capital: **56.5** | Interior: **43.5**

**capital_interior_Norte** (percentual)

Capital: **71.6** | Interior: **28.4**

**capital_interior_Nordeste** (percentual)

Capital: **46.7** | Interior: **53.3**

**capital_interior_Centro-Oeste** (percentual)

Capital: **79.6** | Interior: **20.4**

**capital_interior_Sudeste** (percentual)

Capital: **63.4** | Interior: **36.6**

**capital_interior_Sul** (percentual)

Capital: **37.7** | Interior: **62.3**

',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 10, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p10-pdf' FROM estudo.notebooks WHERE source_key='pdf-2025-p10' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p10-pdf' AND encode(sha256(convert_to(content,'UTF8')),'hex')='f08892e2b51973e25b2a2131ea44a44777ee2fd0cc9898cd11bd3d58a2e41734') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p10-pdf'; END IF; END $verify$;
INSERT INTO estudo.notebooks(notebook_title,caderno_id,call_order,source_key) SELECT 'P11 — Calendário, trimestres e estações',id,11,'pdf-2025-p11' FROM estudo.cadernos WHERE source_key='pdf-2025-pages-v1' ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,1,'markdown','','## P11 — Calendário, trimestres e estações

**Editor:** [Conclusões por mês](https://business.roadrunners.run/estudo/?caderno=1&secao=9); [Picos de calendário](https://business.roadrunners.run/estudo/?caderno=1&secao=10). Consultas coladas sem separador em alguns pontos; meses ordenados por volume. O HTML 79 mostra apenas dez meses (janeiro e fevereiro ausentes na tabela mensal), embora os trimestres cubram o ano.

**DataGrip:** INFOGRAFICO, blocos 16–17, usa view e mês numérico. **DBA:** o DOCX tem 24 contagens mensais F/M iguais à view BI na coleta de 27/09.

**Decisão:** usar tabelas de 12 meses em ordem para confronto. O denominador dos “top 3/5 meses” no editor é só a seleção, portanto soma 100% e não mede sua participação no ano. A regra de estações não foi localizada: não converter trimestres em estações por suposição.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 11, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p11-intro' FROM estudo.notebooks WHERE source_key='pdf-2025-p11' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p11-intro' AND encode(sha256(convert_to(content,'UTF8')),'hex')='b01b19aa07a3d09338e8c4353fc7db25fe22387a26341868fd39c6bc6bb99067') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p11-intro'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,2,'markdown','','### Calendário — editor versus DataGrip

Derivação para confronto em uma leitura: repete a definição inspecionada de vw_resultados como filtro e preserva o denominador anual; ordem cronológica e aliases uniformizados.

**Linhas de origem:** `editor:09_conclusoes_por_mes.sql.txt:1`, `editor:09_conclusoes_por_mes.sql.txt:2`, `datagrip:INFOGRAFICO.sql.txt:16`, `datagrip:INFOGRAFICO.sql.txt:17`.

A saída representa a base atual no momento da execução; não é o snapshot usado no PDF.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 11, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p11-calendario-nota' FROM estudo.notebooks WHERE source_key='pdf-2025-p11' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p11-calendario-nota' AND encode(sha256(convert_to(content,'UTF8')),'hex')='e5fd656dac8e6069b3510c5f6c8451b07f904a0ca9ca6b6394c11a9004707893') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p11-calendario-nota'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,3,'code','sql','-- Calendário — editor versus DataGrip
WITH base AS (
 SELECT extract(month FROM e.data_final)::integer AS mes,extract(quarter FROM e.data_final)::integer AS trimestre,
 count(*) AS editor,count(*) FILTER(WHERE r.status_final=0 AND r.homologado IS TRUE) AS datagrip
 FROM public.tb_resultados r JOIN public.tb_evento_corridas e ON e.id_evento=r.id_evento
 WHERE e.pais=''BR'' AND e.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
 GROUP BY extract(month FROM e.data_final),extract(quarter FROM e.data_final)
), recortes AS (
 SELECT ''Mês'' AS periodo,mes AS ordem,''Editor'' AS versao,editor AS total FROM base
 UNION ALL SELECT ''Mês'',mes,''DataGrip'',datagrip FROM base
 UNION ALL SELECT ''Trimestre'',trimestre,''Editor'',sum(editor) FROM base GROUP BY trimestre
 UNION ALL SELECT ''Trimestre'',trimestre,''DataGrip'',sum(datagrip) FROM base GROUP BY trimestre
)
SELECT periodo,ordem,versao,total,round(total*100.0/nullif(sum(total) OVER(PARTITION BY periodo,versao),0),2) AS percentual
FROM recortes ORDER BY periodo,ordem,versao;',CAST('{"tipo": "consulta_conciliacao", "pagina_pdf": 11, "fontes": ["editor:09_conclusoes_por_mes.sql.txt:1", "editor:09_conclusoes_por_mes.sql.txt:2", "datagrip:INFOGRAFICO.sql.txt:16", "datagrip:INFOGRAFICO.sql.txt:17"], "regra": "Derivação para confronto em uma leitura: repete a definição inspecionada de vw_resultados como filtro e preserva o denominador anual; ordem cronológica e aliases uniformizados.", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p11-calendario' FROM estudo.notebooks WHERE source_key='pdf-2025-p11' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p11-calendario' AND encode(sha256(convert_to(content,'UTF8')),'hex')='43e8855ae972b257a9faecd0b8b3d7b7460ddd3befd2d78822d3b39f2f6ff67d') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p11-calendario'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,4,'markdown','','### Referência publicada — PDF v3.10.3

[Consultar a página 11](https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf#page=11). Valores transcritos; não foram recalculados.

**meses** (percentual)

Jan: **2.6** | Fev: **3.6** | Mar: **7.4** | Abr: **7** | Mai: **8.2** | Jun: **9.6** | Jul: **8.1** | Ago: **9.5** | Set: **10.5** | Out: **11.1** | Nov: **13.4** | Dez: **8.9**

**trimestres** (percentual)

1: **13.6** | 2: **24.9** | 3: **28** | 4: **33.5**

**estacoes** (percentual)

Verão: **11.9** | Outono: **25.5** | Inverno: **28.3** | Primavera: **34.3**

Nota: Regra das datas sazonais não localizada.

',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 11, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p11-pdf' FROM estudo.notebooks WHERE source_key='pdf-2025-p11' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p11-pdf' AND encode(sha256(convert_to(content,'UTF8')),'hex')='8c8a56f61daff7c4004e008f64fa002ff57c12ebb23a0d95b723136bf824b7a9') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p11-pdf'; END IF; END $verify$;
INSERT INTO estudo.notebooks(notebook_title,caderno_id,call_order,source_key) SELECT 'P12 — Top maratonas e tempos',id,12,'pdf-2025-p12' FROM estudo.cadernos WHERE source_key='pdf-2025-pages-v1' ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,1,'markdown','','## P12 — Top maratonas e tempos

**Editor:** [Provas Rápidas](https://business.roadrunners.run/estudo/?caderno=1&secao=11) usa tb_resultados_resumo_2025, evento homologado, ranking=''true'', data inicial e exclusões por texto de modalidade. HTML 77 está vazio.

**DataGrip:** INFOGRAFICO_MARATONAS: primeiro bloco usa vw_resultados, PCD=false, rua, data final e 42–42,2 km; outros blocos usam dez IDs fixos, limites e filtros distintos. Há também UPDATE de pace, mantido apenas como fonte, sem execução.

**DBA:** estudo_treinos tem explorações de maratonas femininas, não a regra completa deste ranking.

**Decisão:** o candidato abaixo usa o primeiro bloco DataGrip e mostra tanto o top 10 recalculado quanto a seleção de IDs legada. Resultados com tempo zero/nulo são contados explicitamente. Isso não resolve sozinho a regra de média/mediana/pódio do PDF.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 12, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p12-intro' FROM estudo.notebooks WHERE source_key='pdf-2025-p12' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p12-intro' AND encode(sha256(convert_to(content,'UTF8')),'hex')='a7d1024379c5ac4274e3c70e2c01a448ff461e7ac713e1fb9fe741f917217318') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p12-intro'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,2,'markdown','','### Maratonas — top atual e seleção legada

Derivação do primeiro bloco DataGrip com filtros preservados, ranking por volume, percentuais e tempos agregados. A regra do editor e o SQL extenso de limites permanecem referências distintas.

**Linhas de origem:** `datagrip:INFOGRAFICO_MARATONAS.sql.txt:1`, `reconciliacao:05_maratonas_legado_2025.sql`.

A saída representa a base atual no momento da execução; não é o snapshot usado no PDF.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 12, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p12-ranking-nota' FROM estudo.notebooks WHERE source_key='pdf-2025-p12' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p12-ranking-nota' AND encode(sha256(convert_to(content,'UTF8')),'hex')='c72b4d6ba2290c648a45107b96f6e64e7e29c91df3b8b4c110cefda8b3ba24cc') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p12-ranking-nota'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,3,'code','sql','-- Maratonas — top atual e seleção legada
WITH base AS (
 SELECT e.id_evento,e.nome_evento,r.sexo,r.tempo_total
 FROM public.tb_resultados r JOIN public.tb_evento_corridas e USING(id_evento)
 WHERE r.status_final=0 AND r.homologado IS TRUE AND r.percurso BETWEEN 42 AND 42.2
   AND r.pcd IS FALSE AND e.tipo_corrida=''rua'' AND e.pais=''BR''
   AND (e.ranking IS NULL OR e.ranking<>''false'')
   AND e.data_final>=DATE ''2025-01-01'' AND e.data_final<DATE ''2026-01-01''
), por_evento AS (
 SELECT id_evento,nome_evento,count(*) AS concluintes,
   count(*) FILTER(WHERE sexo=''F'') AS feminino,count(*) FILTER(WHERE sexo=''M'') AS masculino,
   count(*) FILTER(WHERE tempo_total IS NULL OR tempo_total=TIME ''00:00:00'') AS tempo_ausente_ou_zero,
   count(*) FILTER(WHERE tempo_total<TIME ''04:00:00'') AS sub4,
   count(*) FILTER(WHERE tempo_total<TIME ''03:00:00'') AS sub3,
   count(*) FILTER(WHERE tempo_total<TIME ''02:30:00'') AS sub2h30,
   min(tempo_total)::text AS tempo_minimo,
   to_char((avg(extract(epoch FROM tempo_total))::double precision * INTERVAL ''1 second''),''HH24:MI:SS'') AS tempo_medio,
   to_char((percentile_cont(0.5) WITHIN GROUP(ORDER BY extract(epoch FROM tempo_total)) * INTERVAL ''1 second''),''HH24:MI:SS'') AS tempo_mediano
 FROM base GROUP BY id_evento,nome_evento
), ranking AS (
 SELECT *,row_number() OVER(ORDER BY concluintes DESC,id_evento) AS posicao
 FROM por_evento
)
SELECT posicao,id_evento,nome_evento,concluintes,feminino,masculino,
 round(feminino*100.0/nullif(concluintes,0),2) AS feminino_pct,
 tempo_ausente_ou_zero,tempo_minimo,tempo_medio,tempo_mediano,
 posicao<=10 AS top10_atual,
 id_evento IN(24999,24998,26867,22792,22582,27104,28253,22590,25481,24016) AS selecao_legada
FROM ranking WHERE posicao<=10 OR id_evento IN(24999,24998,26867,22792,22582,27104,28253,22590,25481,24016)
ORDER BY posicao;',CAST('{"tipo": "consulta_conciliacao", "pagina_pdf": 12, "fontes": ["datagrip:INFOGRAFICO_MARATONAS.sql.txt:1", "reconciliacao:05_maratonas_legado_2025.sql"], "regra": "Derivação do primeiro bloco DataGrip com filtros preservados, ranking por volume, percentuais e tempos agregados. A regra do editor e o SQL extenso de limites permanecem referências distintas.", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p12-ranking' FROM estudo.notebooks WHERE source_key='pdf-2025-p12' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p12-ranking' AND encode(sha256(convert_to(content,'UTF8')),'hex')='3dfcf0808925f9632f68f27950291fbb167d751bccc76ec2b602d17ac70778a9') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p12-ranking'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,4,'markdown','','### Referência publicada — PDF v3.10.3

[Consultar a página 12](https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf#page=12). Valores transcritos; não foram recalculados.

**maratonas_concluintes** (participacoes)

Maratona do Rio: **13132** | Maratona de Porto Alegre: **5769** | SP City Marathon: **5380** | Maratona de Floripa: **5137** | Maratona de São Paulo: **4851** | Maratona de Curitiba: **3012** | Maratona Monumental de Brasília: **1848** | New Balance 42k Porto Alegre: **1765** | Maratona de Aracaju: **1363** | Maratona de Salvador: **1105**

**maratonas_feminino** (percentual)

Maratona do Rio: **28.8** | Maratona de Porto Alegre: **25.7** | SP City Marathon: **20.3** | Maratona de Floripa: **28.9** | Maratona de São Paulo: **15.8** | Maratona de Curitiba: **19.9** | Maratona Monumental de Brasília: **19.9** | New Balance 42k Porto Alegre: **21.9** | Maratona de Aracaju: **19.7** | Maratona de Salvador: **16.8**

**maratonas_masculino** (percentual)

Maratona do Rio: **71.2** | Maratona de Porto Alegre: **74.3** | SP City Marathon: **79.7** | Maratona de Floripa: **71.1** | Maratona de São Paulo: **84.2** | Maratona de Curitiba: **80.1** | Maratona Monumental de Brasília: **80.1** | New Balance 42k Porto Alegre: **78.1** | Maratona de Aracaju: **80.3** | Maratona de Salvador: **83.2**

**maratonas_destaques** (texto_publicado)

Top 10 soma: **43.362** | Provas no ano: **62** | Mulheres: **24%** | Provas que são maratonas: **0.9%** | New York: **59.226**

Nota: Confirmar denominadores dos percentuais; New York é referência externa, não validada nesta coleta.

**maratonas_tempo_menor** (duracao_hh_mm_ss)

Maratona do Rio: **02:14:18** | Maratona de Porto Alegre: **02:15:47** | SP City Marathon: **02:15:58** | Maratona de Floripa: **02:20:32** | Maratona de São Paulo: **02:13:22** | Maratona de Curitiba: **02:15:13** | Maratona Monumental de Brasília: **02:27:15** | New Balance 42k Porto Alegre: **02:12:43** | Maratona de Aracaju: **02:30:16** | Maratona de Salvador: **02:22:29**

**maratonas_tempo_medio** (duracao_hh_mm_ss)

Maratona do Rio: **04:14:42** | Maratona de Porto Alegre: **03:55:15** | SP City Marathon: **04:17:57** | Maratona de Floripa: **04:07:52** | Maratona de São Paulo: **04:18:39** | Maratona de Curitiba: **04:10:03** | Maratona Monumental de Brasília: **04:17:41** | New Balance 42k Porto Alegre: **03:53:04** | Maratona de Aracaju: **04:21:40** | Maratona de Salvador: **04:15:05**

**maratonas_tempo_mediano** (duracao_hh_mm_ss)

Maratona do Rio: **04:10:21** | Maratona de Porto Alegre: **03:51:21** | SP City Marathon: **04:13:53** | Maratona de Floripa: **04:02:55** | Maratona de São Paulo: **04:14:00** | Maratona de Curitiba: **04:04:14** | Maratona Monumental de Brasília: **04:11:36** | New Balance 42k Porto Alegre: **03:49:55** | Maratona de Aracaju: **04:21:07** | Maratona de Salvador: **04:12:13**

',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 12, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p12-pdf' FROM estudo.notebooks WHERE source_key='pdf-2025-p12' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p12-pdf' AND encode(sha256(convert_to(content,'UTF8')),'hex')='b4a9e39f5a79a6043243b846a8eb30e489f39c7c9aecdab0a02efc5fd8a1ca7b') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p12-pdf'; END IF; END $verify$;
INSERT INTO estudo.notebooks(notebook_title,caderno_id,call_order,source_key) SELECT 'P13 — Maratonas rápidas e pódio',id,13,'pdf-2025-p13' FROM estudo.cadernos WHERE source_key='pdf-2025-pages-v1' ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,1,'markdown','','## P13 — Maratonas rápidas e pódio

**Editor:** [Provas Rápidas](https://business.roadrunners.run/estudo/?caderno=1&secao=11); [Headline performance](https://business.roadrunners.run/estudo/?caderno=1&secao=13) traz resumos por sexo e destaques gerais; não reconstitui sozinho o quadro de medalhas.

**DataGrip:** os blocos longos de maratonas usam seleção fixa, exclusões por texto, limites por evento e percentis; não equivalem ao primeiro ranking. Há diferenças entre menor tempo, média, mediana e grupos percentuais. “Sub” no quadro desta página é estritamente menor, enquanto outros blocos usam <=.

**Decisão:** preservar os dez IDs como referência identificada e recalcular os limites <4h/<3h/<2h30 na população do primeiro bloco, deixando essa derivação explícita. A classificação de pódio e a tabela top10/top100/5%/10%/50% ainda exigem conciliar o SQL extenso, não foram reconstruídas por aproximação.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 13, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p13-intro' FROM estudo.notebooks WHERE source_key='pdf-2025-p13' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p13-intro' AND encode(sha256(convert_to(content,'UTF8')),'hex')='e72c63a4951a7cb1f7f898e4f720647877b2e9340fc90bcccdd097d217f8a335') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p13-intro'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,2,'markdown','','### Maratonas — faixas sub4/sub3/sub2h30

Seleção fixa legada, população do primeiro bloco DataGrip, limites estritos (<). Zero entra como abaixo do limite e é sinalizado; não corrigido silenciosamente.

**Linhas de origem:** `datagrip:INFOGRAFICO_MARATONAS.sql.txt:1`, `datagrip:INFOGRAFICO_MARATONAS.sql.txt:2`.

A saída representa a base atual no momento da execução; não é o snapshot usado no PDF.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 13, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p13-limites-nota' FROM estudo.notebooks WHERE source_key='pdf-2025-p13' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p13-limites-nota' AND encode(sha256(convert_to(content,'UTF8')),'hex')='11d458463848a219b19bd883bcbbb7fa7b5098d2823e0c42f7a050e732cb5744') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p13-limites-nota'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,3,'code','sql','-- Maratonas — faixas sub4/sub3/sub2h30
WITH base AS (
 SELECT e.id_evento,e.nome_evento,r.sexo,r.tempo_total
 FROM public.tb_resultados r JOIN public.tb_evento_corridas e USING(id_evento)
 WHERE r.status_final=0 AND r.homologado IS TRUE AND r.percurso BETWEEN 42 AND 42.2
   AND r.pcd IS FALSE AND e.tipo_corrida=''rua'' AND e.pais=''BR''
   AND (e.ranking IS NULL OR e.ranking<>''false'')
   AND e.data_final>=DATE ''2025-01-01'' AND e.data_final<DATE ''2026-01-01''
), por_evento AS (
 SELECT id_evento,nome_evento,count(*) AS concluintes,
   count(*) FILTER(WHERE sexo=''F'') AS feminino,count(*) FILTER(WHERE sexo=''M'') AS masculino,
   count(*) FILTER(WHERE tempo_total IS NULL OR tempo_total=TIME ''00:00:00'') AS tempo_ausente_ou_zero,
   count(*) FILTER(WHERE tempo_total<TIME ''04:00:00'') AS sub4,
   count(*) FILTER(WHERE tempo_total<TIME ''03:00:00'') AS sub3,
   count(*) FILTER(WHERE tempo_total<TIME ''02:30:00'') AS sub2h30,
   min(tempo_total)::text AS tempo_minimo,
   to_char((avg(extract(epoch FROM tempo_total))::double precision * INTERVAL ''1 second''),''HH24:MI:SS'') AS tempo_medio,
   to_char((percentile_cont(0.5) WITHIN GROUP(ORDER BY extract(epoch FROM tempo_total)) * INTERVAL ''1 second''),''HH24:MI:SS'') AS tempo_mediano
 FROM base GROUP BY id_evento,nome_evento
), ranking AS (
 SELECT *,row_number() OVER(ORDER BY concluintes DESC,id_evento) AS posicao
 FROM por_evento
)
SELECT posicao,id_evento,nome_evento,concluintes,sub4,round(sub4*100.0/nullif(concluintes,0),2) AS sub4_pct,
sub3,round(sub3*100.0/nullif(concluintes,0),2) AS sub3_pct,
sub2h30,round(sub2h30*100.0/nullif(concluintes,0),2) AS sub2h30_pct,tempo_ausente_ou_zero
FROM ranking WHERE id_evento IN(24999,24998,26867,22792,22582,27104,28253,22590,25481,24016) ORDER BY posicao;',CAST('{"tipo": "consulta_conciliacao", "pagina_pdf": 13, "fontes": ["datagrip:INFOGRAFICO_MARATONAS.sql.txt:1", "datagrip:INFOGRAFICO_MARATONAS.sql.txt:2"], "regra": "Seleção fixa legada, população do primeiro bloco DataGrip, limites estritos (<). Zero entra como abaixo do limite e é sinalizado; não corrigido silenciosamente.", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p13-limites' FROM estudo.notebooks WHERE source_key='pdf-2025-p13' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p13-limites' AND encode(sha256(convert_to(content,'UTF8')),'hex')='57dc05deb9c2d037e97ae783dbb1148ed685de8a9a41ae0acdd93cbf122a1e8b') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p13-limites'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,4,'markdown','','### Referência publicada — PDF v3.10.3

[Consultar a página 13](https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf#page=13). Valores transcritos; não foram recalculados.

**maratonas_sub4_contagem** (participacoes)

Maratona do Rio: **5242** | Maratona de Porto Alegre: **3473** | SP City Marathon: **2018** | Maratona de Floripa: **2416** | Maratona de São Paulo: **1840** | Maratona de Curitiba: **1367** | Maratona Monumental de Brasília: **728** | New Balance 42k Porto Alegre: **1101** | Maratona de Aracaju: **461** | Maratona de Salvador: **432**

**maratonas_sub4_percentual** (percentual)

Maratona do Rio: **39.9** | Maratona de Porto Alegre: **60.2** | SP City Marathon: **37.5** | Maratona de Floripa: **47** | Maratona de São Paulo: **37.9** | Maratona de Curitiba: **45.4** | Maratona Monumental de Brasília: **39.4** | New Balance 42k Porto Alegre: **62.4** | Maratona de Aracaju: **33.8** | Maratona de Salvador: **39.1**

**maratonas_sub3_contagem** (participacoes)

Maratona do Rio: **334** | Maratona de Porto Alegre: **438** | SP City Marathon: **155** | Maratona de Floripa: **204** | Maratona de São Paulo: **116** | Maratona de Curitiba: **132** | Maratona Monumental de Brasília: **33** | New Balance 42k Porto Alegre: **161** | Maratona de Aracaju: **22** | Maratona de Salvador: **48**

**maratonas_sub3_percentual** (percentual)

Maratona do Rio: **2.5** | Maratona de Porto Alegre: **7.6** | SP City Marathon: **2.9** | Maratona de Floripa: **4** | Maratona de São Paulo: **2.4** | Maratona de Curitiba: **4.4** | Maratona Monumental de Brasília: **1.8** | New Balance 42k Porto Alegre: **9.1** | Maratona de Aracaju: **1.6** | Maratona de Salvador: **4.3**

**maratonas_sub2h30_contagem** (participacoes)

Maratona do Rio: **11** | Maratona de Porto Alegre: **13** | SP City Marathon: **6** | Maratona de Floripa: **9** | Maratona de São Paulo: **10** | Maratona de Curitiba: **10** | Maratona Monumental de Brasília: **3** | New Balance 42k Porto Alegre: **15** | Maratona de Aracaju: **0** | Maratona de Salvador: **7**

**maratonas_sub2h30_percentual** (percentual)

Maratona do Rio: **0.08** | Maratona de Porto Alegre: **0.23** | SP City Marathon: **0.11** | Maratona de Floripa: **0.18** | Maratona de São Paulo: **0.21** | Maratona de Curitiba: **0.33** | Maratona Monumental de Brasília: **0.16** | New Balance 42k Porto Alegre: **0.85** | Maratona de Aracaju: **0** | Maratona de Salvador: **0.63**

',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 13, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p13-pdf' FROM estudo.notebooks WHERE source_key='pdf-2025-p13' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p13-pdf' AND encode(sha256(convert_to(content,'UTF8')),'hex')='5f80034f026d2fad2e6b8de474c6a91dc5df9b72187a9e082702e05d56385be8') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p13-pdf'; END IF; END $verify$;
INSERT INTO estudo.notebooks(notebook_title,caderno_id,call_order,source_key) SELECT 'P14 — Faixas Corrida no Ar',id,14,'pdf-2025-p14' FROM estudo.cadernos WHERE source_key='pdf-2025-pages-v1' ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,1,'markdown','','## P14 — Faixas Corrida no Ar

**Editor:** a seção chamada “Faixas de tempo” corresponde à performance da p.8, não às oito faixas CNA.

**DataGrip:** INFOGRAFICO_COLAB_CNA, blocos 1–4, contém as quatro distâncias e oito faixas. **DBA:** não enviou equivalente CNA separado.

**Decisão:** separar este capítulo da performance. CNA exige PCD=false e ranking nulo/diferente de false; não exige tipo_corrida=''rua''. Limites usam <; nulos vão à faixa branca e zero à mestre. São distribuições de participações, não transições individuais entre faixas.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 14, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p14-intro' FROM estudo.notebooks WHERE source_key='pdf-2025-p14' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p14-intro' AND encode(sha256(convert_to(content,'UTF8')),'hex')='564277ad9728339925b6f5d2394cb3e2877238ff429f5e054d61f1bf691de26b') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p14-intro'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,2,'markdown','','### CNA — quatro distâncias

Blocos originais DataGrip unidos com identificador de distância; filtros e fronteiras preservados.

**Linhas de origem:** `datagrip:INFOGRAFICO_COLAB_CNA.sql.txt:1`, `datagrip:INFOGRAFICO_COLAB_CNA.sql.txt:2`, `datagrip:INFOGRAFICO_COLAB_CNA.sql.txt:3`, `datagrip:INFOGRAFICO_COLAB_CNA.sql.txt:4`.

A saída representa a base atual no momento da execução; não é o snapshot usado no PDF.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 14, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p14-cna-nota' FROM estudo.notebooks WHERE source_key='pdf-2025-p14' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p14-cna-nota' AND encode(sha256(convert_to(content,'UTF8')),'hex')='deb04e1e5e488b8187ab6d309e6f84d412671430248af6e527e1b26de319668d') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p14-cna-nota'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,3,'code','sql','-- CNA — quatro distâncias
WITH q0 AS (
-- FAIXAS COLAB CORRIDA NO AR 5KM
SELECT
  faixa_tempo,
  total,
  ROUND(
    total * 100.0 / NULLIF(SUM(total) OVER (), 0),
    2
  ) AS porcentagem
FROM (
  SELECT
    CASE
        WHEN tempo_total < TIME ''00:15:00'' THEN ''Mestre < 15 min''
        WHEN tempo_total < TIME ''00:17:00'' THEN ''Faixa Preta < 17 min''
        WHEN tempo_total < TIME ''00:20:00'' THEN ''Faixa Marrom < 20 min''
        WHEN tempo_total < TIME ''00:22:00'' THEN ''Faixa Vermelha < 22 min''
        WHEN tempo_total < TIME ''00:25:00'' THEN ''Faixa Azul < 25 min''
        WHEN tempo_total < TIME ''00:27:00'' THEN ''Faixa Amarela < 27 min''
        WHEN tempo_total < TIME ''00:30:00'' THEN ''Faixa Laranja < 30 min''
        ELSE ''Faixa Branca > 30 min''
    END AS faixa_tempo,
    COUNT(*) AS total
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE res.percurso = 5
    AND res.pcd = false
    AND evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    and evt.pais = ''BR''
    --and res.sexo = ''M''
    --AND idade_range is not null
    --AND idade_range && int4range(50, 59, ''[)'')
    and (evt.ranking is null OR evt.ranking <> ''false'')
  GROUP BY faixa_tempo
) s
ORDER BY
  CASE faixa_tempo
    WHEN ''Mestre < 15 min'' THEN 8
    WHEN ''Faixa Preta < 17 min'' THEN 7
    WHEN ''Faixa Marrom < 20 min'' THEN 6
    WHEN ''Faixa Vermelha < 22 min'' THEN 5
    WHEN ''Faixa Azul < 25 min'' THEN 4
    WHEN ''Faixa Amarela < 27 min'' THEN 3
    WHEN ''Faixa Laranja < 30 min'' THEN 2
    ELSE 1
  END
),
q1 AS (
-- FAIXAS COLAB CORRIDA NO AR 10KM
SELECT
  faixa_tempo,
  total,
  ROUND(
    total * 100.0 / NULLIF(SUM(total) OVER (), 0),
    2
  ) AS porcentagem
FROM (
  SELECT
    CASE
        WHEN tempo_total < TIME ''00:35:00'' THEN ''Mestre < 35 min''
        WHEN tempo_total < TIME ''00:40:00'' THEN ''Faixa Preta < 40 min''
        WHEN tempo_total < TIME ''00:42:00'' THEN ''Faixa Marrom < 42 min''
        WHEN tempo_total < TIME ''00:45:00'' THEN ''Faixa Vermelha < 45 min''
        WHEN tempo_total < TIME ''00:50:00'' THEN ''Faixa Azul < 50 min''
        WHEN tempo_total < TIME ''00:55:00'' THEN ''Faixa Amarela < 55 min''
        WHEN tempo_total < TIME ''01:00:00'' THEN ''Faixa Laranja < 60 min''
        ELSE ''Faixa Branca > 60 min''
    END AS faixa_tempo,
    COUNT(*) AS total
  FROM vw_resultados res
    JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
    where res.percurso = 10 and res.pcd = false
    AND evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    and evt.pais = ''BR''
    --and res.sexo = ''M''
    and (evt.ranking is null OR evt.ranking <> ''false'')
  GROUP BY faixa_tempo
) s
ORDER BY
  CASE faixa_tempo
    WHEN ''Mestre < 35 min'' THEN 8
    WHEN ''Faixa Preta < 40 min'' THEN 7
    WHEN ''Faixa Marrom < 42 min'' THEN 6
    WHEN ''Faixa Vermelha < 45 min'' THEN 5
    WHEN ''Faixa Azul < 50 min'' THEN 4
    WHEN ''Faixa Amarela < 55 min'' THEN 3
    WHEN ''Faixa Laranja < 60 min'' THEN 2
    ELSE 1
  END
),
q2 AS (
-- FAIXAS COLAB CORRIDA NO AR 21KM
SELECT
  faixa_tempo,
  total,
  ROUND(
    total * 100.0 / NULLIF(SUM(total) OVER (), 0),
    2
  ) AS porcentagem
FROM (
  SELECT
    CASE
        WHEN tempo_total < TIME ''01:20:00'' THEN ''Mestre < 1:20''
        WHEN tempo_total < TIME ''01:25:00'' THEN ''Faixa Preta < 1:25''
        WHEN tempo_total < TIME ''01:30:00'' THEN ''Faixa Marrom < 1:30''
        WHEN tempo_total < TIME ''01:40:00'' THEN ''Faixa Vermelha < 1:40''
        WHEN tempo_total < TIME ''01:45:00'' THEN ''Faixa Azul < 1:45''
        WHEN tempo_total < TIME ''01:50:00'' THEN ''Faixa Amarela < 1:50''
        WHEN tempo_total < TIME ''02:00:00'' THEN ''Faixa Laranja < 2h''
        ELSE ''Faixa Branca > 2h''
    END AS faixa_tempo,
    COUNT(*) AS total
  FROM vw_resultados res
    JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
    where res.percurso between 21 and 21.1 and res.pcd = false
    AND evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    and evt.pais = ''BR''
    --and res.sexo = ''M''
    and (evt.ranking is null OR evt.ranking <> ''false'')
  GROUP BY faixa_tempo
) s
ORDER BY
  CASE faixa_tempo
    WHEN ''Mestre < 1:20'' THEN 8
    WHEN ''Faixa Preta < 1:25'' THEN 7
    WHEN ''Faixa Marrom < 1:30'' THEN 6
    WHEN ''Faixa Vermelha < 1:40'' THEN 5
    WHEN ''Faixa Azul < 1:45'' THEN 4
    WHEN ''Faixa Amarela < 1:50'' THEN 3
    WHEN ''Faixa Laranja < 2h'' THEN 2
    ELSE 1
  END
),
q3 AS (
-- FAIXAS COLAB CORRIDA NO AR 42KM
SELECT
  faixa_tempo,
  total,
  ROUND(
    total * 100.0 / NULLIF(SUM(total) OVER (), 0),
    2
  ) AS porcentagem
FROM (
  SELECT
    CASE
        WHEN tempo_total < TIME ''02:30:00'' THEN ''Mestre < 2:30''
        WHEN tempo_total < TIME ''02:45:00'' THEN ''Faixa Preta < 2:45''
        WHEN tempo_total < TIME ''03:00:00'' THEN ''Faixa Marrom < 3h''
        WHEN tempo_total < TIME ''03:15:00'' THEN ''Faixa Vermelha < 3:15''
        WHEN tempo_total < TIME ''03:30:00'' THEN ''Faixa Azul < 3:30''
        WHEN tempo_total < TIME ''03:45:00'' THEN ''Faixa Amarela < 3:45''
        WHEN tempo_total < TIME ''04:00:00'' THEN ''Faixa Laranja < 4h''
        ELSE ''Faixa Branca > 4h''
    END AS faixa_tempo,
    COUNT(*) AS total
  FROM vw_resultados res
    JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
    where res.percurso between 42 and 42.2 and res.pcd = false
    AND evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    and evt.pais = ''BR''
    --and res.sexo = ''M''
    and (evt.ranking is null OR evt.ranking <> ''false'')
  GROUP BY faixa_tempo
) s
ORDER BY
  CASE faixa_tempo
    WHEN ''Mestre < 2:30'' THEN 8
    WHEN ''Faixa Preta < 2:45'' THEN 7
    WHEN ''Faixa Marrom < 3h'' THEN 6
    WHEN ''Faixa Vermelha < 3:15'' THEN 5
    WHEN ''Faixa Azul < 3:30'' THEN 4
    WHEN ''Faixa Amarela < 3:45'' THEN 3
    WHEN ''Faixa Laranja < 4h'' THEN 2
    ELSE 1
  END
)
SELECT ''5k'' AS versao, faixa_tempo,total,porcentagem FROM q0
UNION ALL
SELECT ''10k'' AS versao, faixa_tempo,total,porcentagem FROM q1
UNION ALL
SELECT ''21k'' AS versao, faixa_tempo,total,porcentagem FROM q2
UNION ALL
SELECT ''42k'' AS versao, faixa_tempo,total,porcentagem FROM q3;',CAST('{"tipo": "consulta_conciliacao", "pagina_pdf": 14, "fontes": ["datagrip:INFOGRAFICO_COLAB_CNA.sql.txt:1", "datagrip:INFOGRAFICO_COLAB_CNA.sql.txt:2", "datagrip:INFOGRAFICO_COLAB_CNA.sql.txt:3", "datagrip:INFOGRAFICO_COLAB_CNA.sql.txt:4"], "regra": "Blocos originais DataGrip unidos com identificador de distância; filtros e fronteiras preservados.", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p14-cna' FROM estudo.notebooks WHERE source_key='pdf-2025-p14' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p14-cna' AND encode(sha256(convert_to(content,'UTF8')),'hex')='2c3733bf9bf8e39c229aa8754110448d7e5c43bc12d672e8d5f7f897138b77a1') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p14-cna'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,4,'markdown','','### Referência publicada — PDF v3.10.3

[Consultar a página 14](https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf#page=14). Valores transcritos; não foram recalculados.

**cna_5k** (percentual)

Branca: **73.51** | Laranja: **10.72** | Amarela: **5.53** | Azul: **5.86** | Vermelha: **2.42** | Marrom: **1.73** | Preta: **0.22** | Mestre: **0.01**

**cna_10k** (percentual)

Branca: **53.09** | Laranja: **16.77** | Amarela: **13.71** | Azul: **9.27** | Vermelha: **3.31** | Marrom: **1.51** | Preta: **1.95** | Mestre: **0.38**

**cna_21k** (percentual)

Branca: **55.78** | Laranja: **18.93** | Amarela: **7.51** | Azul: **6.17** | Vermelha: **7.53** | Marrom: **2.04** | Preta: **1.15** | Mestre: **0.89**

**cna_42k** (percentual)

Branca: **57.84** | Laranja: **15.12** | Amarela: **10.95** | Azul: **7.89** | Vermelha: **4.5** | Marrom: **2.8** | Preta: **0.68** | Mestre: **0.21**

',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 14, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p14-pdf' FROM estudo.notebooks WHERE source_key='pdf-2025-p14' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p14-pdf' AND encode(sha256(convert_to(content,'UTF8')),'hex')='23065ce9a7089d918658358297237ff3819b24fbca7c83b7d41a03206714610a') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p14-pdf'; END IF; END $verify$;
INSERT INTO estudo.notebooks(notebook_title,caderno_id,call_order,source_key) SELECT 'P15 — Perfil e outros esportes',id,15,'pdf-2025-p15' FROM estudo.cadernos WHERE source_key='pdf-2025-pages-v1' ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,1,'markdown','','## P15 — Perfil e outros esportes

**Editor:** não foram recuperadas células desta página.

**DataGrip:** INFOGRAFICO_USUARIO contém agregações de atividades por esporte; não recupera os dez cards do perfil. Algumas explorações mensais não filtram ano. INFOGRAFICO_PERSONAS analisa poucos atletas selecionados e não representa a plataforma; não foi promovido a consulta nacional.

**DBA:** a view de treinos se relaciona ao Desafio 365; os 2.231 usuários anotados são uma amostra selecionada. Não é uma fonte automática para os dez cards.

**Decisão:** executar apenas esportes com filtro 2025. A saída mede atividades importadas, não percentual de usuários. Mapeamento de rótulos (fortalecimento etc.) e denominador do gráfico precisam ser confirmados. Os dez cards ficam marcados como fonte pendente, sem números fabricados.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 15, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p15-intro' FROM estudo.notebooks WHERE source_key='pdf-2025-p15' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p15-intro' AND encode(sha256(convert_to(content,'UTF8')),'hex')='217cb54ee3b0bcc153d04cfb52af10b4708eadfb853d8c7207337fdcaec0aa40') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p15-intro'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,2,'markdown','','### Atividades por esporte — candidato DataGrip

Consulta original: activity_date em 2025 e type não nulo. Inclui corrida no denominador, não filtra exclusões do Strava. Atribuição dos rótulos do PDF pendente.

**Linhas de origem:** `datagrip:INFOGRAFICO_USUARIO.sql.txt:1`.

A saída representa a base atual no momento da execução; não é o snapshot usado no PDF.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 15, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p15-esportes-nota' FROM estudo.notebooks WHERE source_key='pdf-2025-p15' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p15-esportes-nota' AND encode(sha256(convert_to(content,'UTF8')),'hex')='32bd2743581a5a6b9106f3c0e736d3e93c1492635b25fec424192c39e6fd2e75') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p15-esportes-nota'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,3,'code','sql','-- Atividades por esporte — candidato DataGrip
-- ESPORTES MAIS PRATICADOS
SELECT
  act.type,
  COUNT(*) AS total,
  ROUND(
    COUNT(*) * 100.0
    / NULLIF(SUM(COUNT(*)) OVER (), 0),
    2
  ) AS porcentagem
FROM tb_strava_activities act
WHERE act.activity_date BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
  AND act.type IS NOT NULL
GROUP BY act.type
ORDER BY total DESC;',CAST('{"tipo": "consulta_conciliacao", "pagina_pdf": 15, "fontes": ["datagrip:INFOGRAFICO_USUARIO.sql.txt:1"], "regra": "Consulta original: activity_date em 2025 e type não nulo. Inclui corrida no denominador, não filtra exclusões do Strava. Atribuição dos rótulos do PDF pendente.", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p15-esportes' FROM estudo.notebooks WHERE source_key='pdf-2025-p15' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p15-esportes' AND encode(sha256(convert_to(content,'UTF8')),'hex')='aafab3adf9a86404cc98deec21654b2085b1d7b28a1c46b5da0a1b104a84720d') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p15-esportes'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,4,'markdown','','### Referência publicada — PDF v3.10.3

[Consultar a página 15](https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf#page=15). Valores transcritos; não foram recalculados.

**perfil_cards** (texto_publicado)

Associaram resultados: **+26%** | Incluíram provas ao calendário: **+22%** | Com equipe/assessoria: **+13%** | Desafios virtuais: **+6%** | Vincularam ao Strava: **+12%** | Strava Premium: **+43%** | Média seguidores: **131** | Peso médio: **67.8 kg** | Pares tênis ativos: **2.4** | Rodagem por par: **432 km**

Nota: Sem queries localizadas. O sinal + e os denominadores não estão definidos.

**outros_esportes** (percentual)

Fortalecimento: **9.5** | Caminhada: **7.93** | Treino livre: **6.49** | Pedal: **5.21** | Natação: **1.48** | Yoga: **0.27** | Rolo: **0.18** | Trilha: **0.16** | Elíptico: **0.15** | Crossfit: **0.12** | Stepper: **0.12**

Nota: Percentuais publicados não somam 100: corrida e outras categorias não estão listadas. Mapeamento de sport type pendente.

',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 15, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p15-pdf' FROM estudo.notebooks WHERE source_key='pdf-2025-p15' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p15-pdf' AND encode(sha256(convert_to(content,'UTF8')),'hex')='15b449c5100ae63168c18419c30c055dbc0bbca46aa7d676c706c43e3e0f0cd7') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p15-pdf'; END IF; END $verify$;
INSERT INTO estudo.notebooks(notebook_title,caderno_id,call_order,source_key) SELECT 'Apoio — qualidade, fontes e pendências',id,99,'pdf-2025-p99' FROM estudo.cadernos WHERE source_key='pdf-2025-pages-v1' ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,1,'markdown','','## Apoio — qualidade, fontes e pendências

As fontes completas continuam no caderno “Fontes e conciliação — 2025”. Estes tópicos não foram forçados para dentro de uma página do PDF:

- INFOGRAFICO_MERCADO: nove blocos sobre sites, equipes e organizadores. O PDF desta versão não publica um capítulo de fornecedores.
- INFOGRAFICO_INUTEIS: distâncias quebradas/padrão, diagnóstico auxiliar.
- INFOGRAFICO_PERSONAS: exploração de indivíduos selecionados, não amostra nacional; nenhuma saída pessoal foi coletada aqui.
- DBA: DDL, INSERTs e GRANTs são somente fonte. Não há carga de janeiro/março/abril no pacote; sua presença na fato não recupera os scripts faltantes.
- Editor “Taxa de completude”: preenchimento dos campos, não cobertura de provas. Faltam separadores entre os dois últimos blocos SQL; separar as consultas antes de executar. Isso não comprova que as tabelas HTML tenham sido geradas exatamente pela revisão salva.

**HTML histórico:** conservado no caderno original com seus IDs. Este novo caderno usa tabelas de execuções; não requer HTML colado. Executar novamente produz nova observação, nunca atualiza um congelamento anterior.

**Próxima revisão metodológica:** decidir a população comum de 2025/2026, fronteiras exclusivas de idade/tempo, qualidade de localidades e denominadores. A web ainda não consome automaticamente estas execuções.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 99, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p99-intro' FROM estudo.notebooks WHERE source_key='pdf-2025-p99' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p99-intro' AND encode(sha256(convert_to(content,'UTF8')),'hex')='f4fc0fc1396cf30e9eed7f07ef5f5adb4eb116b9bd3e5d4d9aa47e00756f9387') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p99-intro'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,2,'markdown','','### População bruta e qualidade dos campos em 2025

Diagnóstico novo, uma linha por resultado bruto de evento BR em 2025. As categorias se sobrepõem; não somar ausências como participantes únicos.

**Linhas de origem:** `editor:14_taxa_de_completude.sql.txt:1`, `definicao_public.vw_resultados:2026-09-28`.

A saída representa a base atual no momento da execução; não é o snapshot usado no PDF.',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 99, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p99-qualidade-nota' FROM estudo.notebooks WHERE source_key='pdf-2025-p99' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p99-qualidade-nota' AND encode(sha256(convert_to(content,'UTF8')),'hex')='f850130907ccb80af40fded6a67f1bf2dd73cc172f0b784d04bc16fff541f6d5') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p99-qualidade-nota'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,3,'code','sql','-- População bruta e qualidade dos campos em 2025
SELECT count(*) AS linhas_brutas,
 count(*) FILTER(WHERE r.status_final=0 AND r.homologado IS TRUE) AS linhas_vw_resultados,
 count(*) FILTER(WHERE r.concluinte IS TRUE) AS sinalizadas_concluintes,
 count(*) FILTER(WHERE r.idade_range IS NULL) AS idade_ausente,
 count(*) FILTER(WHERE r.tempo_total IS NULL) AS tempo_nulo,
 count(*) FILTER(WHERE r.tempo_total=TIME ''00:00:00'') AS tempo_zero,
 count(*) FILTER(WHERE r.sexo IS NULL OR btrim(r.sexo)='''') AS sexo_ausente
FROM public.tb_resultados r JOIN public.tb_evento_corridas e ON e.id_evento=r.id_evento
WHERE e.pais=''BR'' AND e.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31'';',CAST('{"tipo": "consulta_conciliacao", "pagina_pdf": 99, "fontes": ["editor:14_taxa_de_completude.sql.txt:1", "definicao_public.vw_resultados:2026-09-28"], "regra": "Diagnóstico novo, uma linha por resultado bruto de evento BR em 2025. As categorias se sobrepõem; não somar ausências como participantes únicos.", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p99-qualidade' FROM estudo.notebooks WHERE source_key='pdf-2025-p99' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p99-qualidade' AND encode(sha256(convert_to(content,'UTF8')),'hex')='6755652b9da27420452ae59ffa5406b57c89ffb0930a774b82b3d918355205cc') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p99-qualidade'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,4,'markdown','','### Comparação dos blocos correspondentes

Igual significa igualdade léxica do SQL sem comentários e espaços; não prova mesma base histórica. “Tabela/view” é uma diferença de população.

| Origem | DataGrip | Comparação |
|---|---|---|
| editor:01_escopo_infograficos.sql.txt:1 | datagrip:INFOGRAFICO.sql.txt:1 | somente_tabela_vs_view |
| editor:02_genero.sql.txt:1 | datagrip:INFOGRAFICO.sql.txt:2 | filtros_ou_estrutura_diferentes |
| editor:02_genero.sql.txt:2 | datagrip:INFOGRAFICO.sql.txt:4 | somente_tabela_vs_view |
| editor:03_faixa_etaria.sql.txt:4 | datagrip:INFOGRAFICO.sql.txt:9 | filtros_ou_estrutura_diferentes |
| editor:05_distancias.sql.txt:2 | datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:2 | filtros_ou_estrutura_diferentes |
| editor:07_ufs.sql.txt:1 | datagrip:INFOGRAFICO.sql.txt:13 | somente_tabela_vs_view |
| editor:07_ufs.sql.txt:2 | datagrip:INFOGRAFICO.sql.txt:15 | filtros_ou_estrutura_diferentes |
| editor:09_conclusoes_por_mes.sql.txt:1 | datagrip:INFOGRAFICO.sql.txt:16 | filtros_ou_estrutura_diferentes |
| editor:09_conclusoes_por_mes.sql.txt:2 | datagrip:INFOGRAFICO.sql.txt:17 | filtros_ou_estrutura_diferentes |
| editor:12_faixas_de_tempo.sql.txt:1 | datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:11 | filtros_ou_estrutura_diferentes |
| editor:12_faixas_de_tempo.sql.txt:2 | datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:12 | filtros_ou_estrutura_diferentes |
| editor:12_faixas_de_tempo.sql.txt:3 | datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:13 | filtros_ou_estrutura_diferentes |
| editor:12_faixas_de_tempo.sql.txt:4 | datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:14 | filtros_ou_estrutura_diferentes |
| dba:INFOGRAFICO_DISTANCIAS.sql.txt:1 | datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:1 | igual |
| dba:INFOGRAFICO_DISTANCIAS.sql.txt:2 | datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:2 | igual |
| dba:INFOGRAFICO_DISTANCIAS.sql.txt:3 | datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:3 | igual |
| dba:INFOGRAFICO_DISTANCIAS.sql.txt:4 | datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:4 | igual |
| dba:INFOGRAFICO_DISTANCIAS.sql.txt:5 | datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:5 | igual |
| dba:INFOGRAFICO_DISTANCIAS.sql.txt:6 | datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:7 | igual |
| dba:INFOGRAFICO_DISTANCIAS.sql.txt:7 | datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:11 | filtro_sexo_diferente |
| dba:INFOGRAFICO_DISTANCIAS.sql.txt:8 | datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:12 | filtro_sexo_diferente |
| dba:INFOGRAFICO_DISTANCIAS.sql.txt:9 | datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:13 | filtro_sexo_diferente |
| dba:INFOGRAFICO_DISTANCIAS.sql.txt:10 | datagrip:INFOGRAFICO_DISTANCIAS.sql.txt:14 | filtro_sexo_diferente |',CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 99, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),'pdf-2025-p99-matriz' FROM estudo.notebooks WHERE source_key='pdf-2025-p99' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p99-matriz' AND encode(sha256(convert_to(content,'UTF8')),'hex')='9027a4fce5f10d9b4596fda42a37af86de0637b8f6e958381514eacf9950abc7') THEN RAISE EXCEPTION 'Conflito de conteudo: pdf-2025-p99-matriz'; END IF; END $verify$;
