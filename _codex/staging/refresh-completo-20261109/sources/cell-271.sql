-- Auditoria agregada: disponibilidade de nascimento e coerência com idade_range.
-- Nenhuma data de nascimento individual é retornada. Não atesta exatidão dos dados.
WITH base AS (
 SELECT extract(year FROM e.data_final)::integer AS ano,r.idade_range,r.data_nascimento,
 e.data_final,extract(year FROM age(e.data_final::timestamp,r.data_nascimento::timestamp))::integer AS idade_evento,
 extract(year FROM age(make_date(extract(year FROM e.data_final)::integer,12,31)::timestamp,r.data_nascimento::timestamp))::integer AS idade_fim_ano
 FROM public.tb_resultados r JOIN public.tb_evento_corridas e USING(id_evento)
 WHERE e.pais='BR' AND e.data_final>=DATE '2025-01-01' AND e.data_final<DATE '2026-09-27'
 AND r.status_final=0 AND r.homologado IS TRUE
 AND (e.data_final<DATE '2026-01-01' OR r.concluinte IS TRUE)
)
SELECT ano,count(*) AS participacoes,
 count(*) FILTER(WHERE data_nascimento IS NOT NULL) AS nascimento_informado,
 count(*) FILTER(WHERE data_nascimento IS NULL) AS nascimento_ausente,
 count(*) FILTER(WHERE data_nascimento>data_final) AS nascimento_futuro,
 count(*) FILTER(WHERE idade_evento>120) AS idade_maior_120,
 count(*) FILTER(WHERE data_nascimento<=data_final AND idade_evento BETWEEN 0 AND 120) AS nascimento_idade_plausivel,
 count(*) FILTER(WHERE data_nascimento<=data_final AND idade_evento BETWEEN 0 AND 120 AND idade_range IS NOT NULL AND idade_range<>'empty'::int4range) AS nascimento_com_faixa,
 count(*) FILTER(WHERE data_nascimento<=data_final AND idade_evento BETWEEN 0 AND 120 AND idade_evento<@idade_range) AS faixa_contem_idade_evento,
 count(*) FILTER(WHERE data_nascimento<=data_final AND idade_evento BETWEEN 0 AND 120 AND idade_fim_ano<@idade_range) AS faixa_contem_idade_31dez,
 count(*) FILTER(WHERE data_nascimento IS NOT NULL AND extract(month FROM data_nascimento)=1 AND extract(day FROM data_nascimento)=1) AS nascimento_primeiro_janeiro
FROM base GROUP BY ano ORDER BY ano
