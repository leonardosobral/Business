-- Renovação candidata09/11; curadoria/capturas externas preservadas; entradas=[{"cell": 444, "revision": 1, "run": 296, "started_at": "2026-11-09 15:52:55.286256-03"}, {"cell": 445, "revision": 5, "run": 342, "started_at": "2026-11-09 18:31:17.62935-03"}]
-- Referência externa: lista de 33 provas, artigo Contra-Relógio de 27/11/2024.
-- Transcrição dos volumes individuais para conferência; não usados como volumes da série RR.
-- O total impresso 39.358 diverge da soma das 33 linhas: 41.280 (+1.922).
-- Pares: mesma regra do congelamento260, restritos à lista CR com identificação confirmada.
-- Goiânia permanece como hipótese; não entra nos pares. Pelotas26402: cadastro sem candidata42km.
WITH referencia(ordem,nome_cr,id2024,cr2024,identificacao) AS (VALUES
(1,'Ribeirão Preto',9644,386,'confirmada'),(2,'Blumenau',9663,257,'confirmada'),
(3,'São Paulo',2997,3871,'confirmada'),(4,'Cascavel',13777,114,'confirmada'),
(5,'João Pessoa',9581,477,'confirmada'),(6,'Brasília',10626,305,'confirmada'),
(7,'NB Porto Alegre',9645,1230,'confirmada'),(8,'Uberlândia',10627,312,'confirmada'),
(9,'Ponta Grossa',10721,108,'confirmada'),(10,'Natal',13157,114,'confirmada'),
(11,'FMO Olinda',14424,89,'confirmada'),(12,'Rio de Janeiro',9831,9812,'confirmada'),
(13,'Florianópolis',14096,763,'confirmada'),(14,'Internacional de Olinda',9173,470,'confirmada'),
(15,'Londrina',13763,587,'confirmada'),(16,'Campo Grande',13136,294,'confirmada'),
(17,'Manaus',13833,408,'confirmada'),(18,'Campinas',13104,167,'confirmada'),
(19,'SP City',9808,4691,'confirmada'),(20,'Internacional João Pessoa',9803,514,'confirmada'),
(21,'Goiânia',13082,212,'identificação a confirmar'),(22,'FILA SP',9164,495,'confirmada'),
(23,'Vitória',9797,563,'confirmada'),(24,'Floripa',9162,3788,'confirmada'),
(25,'Salvador',9794,1211,'confirmada'),(26,'Foz do Iguaçu',13752,503,'confirmada'),
(27,'Porto Alegre',3000,2412,'confirmada'),(28,'Pomerode',9172,825,'confirmada'),
(29,'Jurerê',10630,630,'confirmada'),(30,'Curitiba',10631,2873,'confirmada'),
(31,'Pelotas',26402,222,'confirmada'),(32,'Sorocaba',24126,932,'confirmada'),
(33,'Monumental',13012,1645,'confirmada')
), inv AS MATERIALIZED (
 SELECT j.value AS dado FROM estudo.notebook_runs r CROSS JOIN LATERAL jsonb_array_elements(r.result->'rows') j WHERE r.id=296
), anterior AS (
 SELECT (result->'rows'->0->>'payload')::jsonb AS dado FROM estudo.notebook_runs WHERE id=342
), pares AS (
 SELECT (j.value->>'n2025')::int AS volume2025,j.value || jsonb_build_object('nome_cr',ref.nome_cr,'cr2024',ref.cr2024,'delta_cr',(j.value->>'n2024')::int-ref.cr2024) AS dado
 FROM anterior a CROSS JOIN LATERAL jsonb_array_elements(a.dado->'pares') j
 JOIN referencia ref ON ref.id2024=(j.value->>'id2024')::int AND ref.identificacao='confirmada'
), conciliacao AS (
 SELECT ref.*,e.nome_evento,e.data_final,e.url_resultado,i.dado->>'participacoes' AS rr2024,
 (i.dado->>'participacoes')::int-ref.cr2024 AS delta_cr,i.dado->>'sub2_auditar' AS sub2_auditar,
 CASE WHEN ref.identificacao<>'confirmada' THEN 'Identificação pendente'
 WHEN i.dado IS NULL THEN 'Sem candidata42km no inventário'
 WHEN (i.dado->>'participacoes')::int=0 THEN 'Sem conclusões elegíveis'
 ELSE 'Resultados disponíveis; divergências de volume não resolvidas' END AS situacao,
 EXISTS(SELECT 1 FROM pares p WHERE (p.dado->>'id2024')::int=ref.id2024) AS no_comparativo
 FROM referencia ref LEFT JOIN inv i ON (i.dado->>'id_evento')::int=ref.id2024
 LEFT JOIN public.tb_evento_corridas e ON e.id_evento=ref.id2024
)
SELECT current_timestamp AS coletado_em,jsonb_build_object(
 'reference_url','https://contrarelogio.com.br/ultima-atualizacao-do-ranking-cr-2024-agora-com-os-selecionados-nas-maratonas-de-curitiba-pelotas-sorocaba-e-monumental-cheque-sua-classificacao/',
 'reference_date','2024-11-27','total_declarado_cr',39358,'soma_linhas_cr',(SELECT sum(cr2024) FROM referencia),
 'coorte',(SELECT jsonb_build_object('pares',count(*),'n2024',sum((dado->>'n2024')::int),'n2025',sum((dado->>'n2025')::int),'variacao_registros',100.0*(sum((dado->>'n2025')::numeric)/nullif(sum((dado->>'n2024')::numeric),0)-1),'cobertura_volume2025',100.0*sum((dado->>'n2025')::numeric)/(SELECT (dado->'selecao2025'->>'participacoes')::numeric FROM anterior),'cr2024',sum((dado->>'cr2024')::int),'delta_cr',sum((dado->>'delta_cr')::int)) FROM pares),
 'pares',(SELECT jsonb_agg(dado ORDER BY volume2025 DESC) FROM pares),
 'conciliacao',(SELECT jsonb_agg(to_jsonb(c) ORDER BY ordem) FROM conciliacao c),
 'pelotas_resultados',(SELECT jsonb_build_object('linhas_todas_distancias',count(*),'linhas42',count(*) FILTER(WHERE percurso BETWEEN 42 AND 42.2)) FROM public.tb_resultados WHERE id_evento=26402),
 'excluidos_da_coorte',(SELECT jsonb_agg(j.value) FROM anterior a CROSS JOIN LATERAL jsonb_array_elements(a.dado->'pares') j WHERE NOT EXISTS(SELECT 1 FROM pares p WHERE p.dado->>'id2024'=j.value->>'id2024'))
) AS payload

