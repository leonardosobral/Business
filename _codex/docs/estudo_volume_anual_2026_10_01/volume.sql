-- P03 — Volume anual na base atual (2023–2025); não reconstrói o congelamento do PDF.
-- Ano pela data final, Brasil, todas as modalidades e idades.
-- A view atual equivale a status_final=0 e homologado=true (definição conferida em 01/10/2026).
-- Agregação por evento antes do calendário: uma linha por evento, sem multiplicar resultados.
-- Coletado: ao menos uma linha bruta; elegível: ao menos uma linha que entra na view.
WITH calendario AS (
 SELECT id_evento,extract(year FROM data_final)::integer AS ano
 FROM public.tb_evento_corridas
 WHERE pais='BR' AND data_final>=DATE '2023-01-01' AND data_final<DATE '2026-01-01'
), por_evento AS (
 SELECT r.id_evento,count(*) AS resultados_brutos,
 count(*) FILTER(WHERE r.status_final=0 AND r.homologado IS TRUE) AS resultados_elegiveis
 FROM public.tb_resultados r JOIN calendario c ON c.id_evento=r.id_evento
 GROUP BY r.id_evento
), por_ano AS (
 SELECT c.ano,count(*) AS cadastradas,
 count(*) FILTER(WHERE p.resultados_brutos>0) AS coletadas,
 count(*) FILTER(WHERE p.resultados_elegiveis>0) AS eventos_elegiveis,
 coalesce(sum(p.resultados_brutos),0)::bigint AS resultados_brutos,
 coalesce(sum(p.resultados_elegiveis),0)::bigint AS resultados,
 sum(p.resultados_elegiveis) FILTER(WHERE p.resultados_elegiveis>0) AS controle_soma
 FROM calendario c LEFT JOIN por_evento p ON p.id_evento=c.id_evento GROUP BY c.ano
), anterior AS (
 SELECT *,lag(resultados) OVER(ORDER BY ano) AS resultados_ano_anterior FROM por_ano
)
SELECT *,resultados_brutos-resultados AS resultados_fora_view,
 (resultados-resultados_ano_anterior)*100.0/nullif(resultados_ano_anterior,0) AS variacao_percentual,
 current_timestamp AS coletado_em
FROM anterior ORDER BY ano;
