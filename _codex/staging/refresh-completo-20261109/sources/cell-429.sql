-- Síntese do piloto Maratonas do Brasil. Fontes congeláveis 240–245; ver seção66.
-- Cohorte: mesmo agregador, exatamente uma edição em cada seleção, Jan-Set nos dois anos.
-- Não atesta coleta completa nem crescimento causal do mercado.
-- Cenário anual da amostra: selecionadas Jan-Set2026 + sete provas Q4/2025 selecionadas.
-- Alternativas: repetir volume Q4/2025; ou aplicar a variação agregada da coorte.
-- Não é intervalo de confiança, nem projeção nacional. Não cobre outras provas Q4 ou lacunas.
WITH a AS MATERIALIZED (
 SELECT (j.value->>'id_evento')::int AS id_evento,j.value->>'nome_evento' AS nome_evento,
 (j.value->>'data_final')::date AS data_final,(j.value->>'participacoes')::int AS participacoes,
 (j.value->>'feminino')::int AS feminino,(j.value->>'sub3')::int AS sub3,(j.value->>'sub4')::int AS sub4,
 (j.value->>'id_agrega_evento')::int AS agregador
 FROM estudo.notebook_runs r CROSS JOIN LATERAL jsonb_array_elements(r.result->'rows') j
 WHERE r.id=244 AND j.value->>'decisao'='selecionada'
), b AS MATERIALIZED (
 SELECT (j.value->>'id_evento')::int AS id_evento,j.value->>'nome_evento' AS nome_evento,
 (j.value->>'data_final')::date AS data_final,(j.value->>'participacoes')::int AS participacoes,
 (j.value->>'feminino')::int AS feminino,(j.value->>'sub3')::int AS sub3,(j.value->>'sub4')::int AS sub4,
 (j.value->>'id_agrega_evento')::int AS agregador
 FROM estudo.notebook_runs r CROSS JOIN LATERAL jsonb_array_elements(r.result->'rows') j WHERE r.id=245
), pares AS (
 SELECT a.agregador,a.id_evento AS id2025,b.id_evento AS id2026,a.nome_evento,a.participacoes AS n2025,b.participacoes AS n2026
 FROM a JOIN b USING(agregador) WHERE a.data_final<DATE '2025-10-01'
 AND (SELECT count(*) FROM a x WHERE x.agregador=a.agregador)=1
 AND (SELECT count(*) FROM b x WHERE x.agregador=b.agregador)=1
), coorte AS (
 SELECT count(*) AS pares,sum(n2025) AS n2025,sum(n2026) AS n2026,
 sum(n2026)::numeric/nullif(sum(n2025),0) AS fator FROM pares
), totais AS (
 SELECT 2025 AS ano,count(*) AS provas,sum(participacoes) AS participacoes,sum(feminino) AS feminino,sum(sub3) AS sub3,sum(sub4) AS sub4 FROM a
 UNION ALL SELECT 2026,count(*),sum(participacoes),sum(feminino),sum(sub3),sum(sub4) FROM b
), cauda AS (SELECT count(*) AS provas,sum(participacoes) AS participacoes FROM a WHERE data_final>=DATE '2025-10-01')
SELECT jsonb_build_object('coletado_em',current_timestamp,'totais',(SELECT jsonb_agg(to_jsonb(t)) FROM totais t),
 'coorte',(SELECT to_jsonb(c) FROM coorte c),'pares',(SELECT jsonb_agg(to_jsonb(p) ORDER BY n2026 DESC) FROM pares p),
 'cenarios',(SELECT jsonb_build_object('provas_q4_referencia',cauda.provas,'q4_2025',cauda.participacoes,
 'jan_set_2026',(SELECT sum(participacoes) FROM b),
 'q4_estavel',(SELECT sum(participacoes) FROM b)+cauda.participacoes,
 'q4_varia_com_coorte',round((SELECT sum(participacoes) FROM b)+cauda.participacoes*coorte.fator),
 'natureza','Cenários da amostra monitorada; não previsão nacional; sem intervalo estatístico; pressupõe as sete provas Q4 e cobertura equivalente') FROM cauda CROSS JOIN coorte)) AS payload
