SELECT jsonb_build_object(
 'papeis',(SELECT jsonb_agg(x) FROM (SELECT v.campo,v.valor,count(*) AS eventos FROM public.tb_evento_corridas e CROSS JOIN LATERAL (VALUES ('organizador',e.organizador),('cronometragem',e.cronometragem),('realizacao',e.realizacao)) v(campo,valor) WHERE length(trim(coalesce(v.valor,'')))>0 GROUP BY v.campo,v.valor ORDER BY eventos DESC) x),
 'fornecedores_eventos',(SELECT jsonb_agg(x) FROM (SELECT f.id_fornecedor,f.nome_fornecedor,ef.id_fornecedor_tipo,count(DISTINCT ef.id_evento) AS eventos FROM public.tb_evento_corridas_fornecedores ef JOIN public.tb_fornecedores f USING(id_fornecedor) GROUP BY f.id_fornecedor,f.nome_fornecedor,ef.id_fornecedor_tipo ORDER BY eventos DESC) x),
 'contas_pf',(SELECT jsonb_agg(x) FROM (SELECT id_conta,nome_conta,tipo_titular,status FROM public.tb_contas WHERE tipo_titular::text='PF') x)
)::text AS payload
