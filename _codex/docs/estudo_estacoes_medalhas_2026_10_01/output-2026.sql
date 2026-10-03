-- P11/P13: estações por meses, pódio revisado de 2025.
-- PDF e demais séries preservados. Derivações sobre resultados congelados.
WITH anterior AS(SELECT result->'rows'->0->'payload' AS payload FROM estudo.notebook_runs WHERE id=96 AND frozen AND status='ok' AND NOT truncated AND row_count=1),
novos_valores AS(SELECT 'estacoes' AS serie,r->>'estacao' AS categoria,jsonb_build_object('valor',r->'percentual','contagem',r->'total','denominador',r->'denominador') AS atual
 FROM estudo.notebook_runs n CROSS JOIN LATERAL jsonb_array_elements(n.result->'rows')r
 WHERE n.id=97 AND n.cell_id=300 AND n.cell_version=1 AND n.frozen AND n.status='ok' AND NOT n.truncated AND n.row_count=8 AND (r->>'ano')::integer=2026),
alvos AS(SELECT x AS s FROM jsonb_array_elements('[{"id": "estacoes", "status": "pendente", "filtros": {}, "unidade": "percentual", "valores": [{"valor": null, "rotulo": "Verão"}, {"valor": null, "rotulo": "Outono"}, {"valor": null, "rotulo": "Inverno"}, {"valor": null, "rotulo": "Primavera"}], "ressalva": "Meses inteiros confirmados pelo responsável em 01/10/2026 e descritos nas notas insights_previa do DBA: verão dez–fev, outono mar–mai, inverno jun–ago, primavera set–nov. Agrupa os meses dentro do ano civil, não uma estação contínua entre dois anos. Percentual das participações do recorte, calculado pelas contagens mensais congeladas, sem somar percentuais arredondados nem recoletar resultados. Regra revisada: os percentuais históricos do PDF não correspondem a esse agrupamento; referência preservada. Célula 300 rev1, execução 97; origens 95/2025 e 96/2026. Em 2026 até 26/09: verão só janeiro/fevereiro e primavera só setembro parcial; dezembro/outubro/novembro estão fora do corte. Não são estações completas nem comparação de crescimento.", "pagina_pdf": null, "casas_decimais": 1}]'::jsonb)x),
originais AS(SELECT x AS s,row_number() OVER() AS ord FROM anterior CROSS JOIN LATERAL jsonb_array_elements(payload->'series')x),
series AS(SELECT coalesce(a.s,p.s) AS s,p.ord FROM originais p LEFT JOIN alvos a ON a.s->>'id'=p.s->>'id'
 UNION ALL SELECT a.s,1000+row_number() OVER(ORDER BY a.s->>'id') FROM alvos a WHERE NOT EXISTS(SELECT 1 FROM originais p WHERE p.s->>'id'=a.s->>'id')),
comparacoes AS(SELECT x AS item FROM anterior CROSS JOIN LATERAL jsonb_array_elements(payload->'comparacoes')x WHERE x->>'serie' NOT IN(SELECT jsonb_array_elements_text('["estacoes"]'::jsonb))
 UNION ALL SELECT jsonb_build_object('serie',serie,'categoria',categoria,'status','calculado','atual',atual) FROM novos_valores)
SELECT payload||jsonb_build_object('meta',payload->'meta'||jsonb_build_object('contrato_versao',4, 'origem',(payload->'meta'->>'origem')||'; estações por meses confirmadas: derivação 97 sobre contagens mensais de 96, sem nova coleta nem alteração dos comparativos'),
 'series',(SELECT jsonb_agg(s ORDER BY ord) FROM series),
 'comparacoes',(SELECT jsonb_agg(item ORDER BY item->>'serie',item->>'categoria') FROM comparacoes),
 'conciliacao','{"pendente": 0, "calculado": 0, "coletado_notebook": 0}'::jsonb||(SELECT jsonb_object_agg(status,n) FROM(SELECT item->>'status' AS status,count(*) AS n FROM comparacoes GROUP BY 1)t)) AS payload
 FROM anterior WHERE (SELECT count(*) FROM novos_valores)=4
 AND (SELECT count(DISTINCT serie||'/'||categoria) FROM novos_valores)=4;
