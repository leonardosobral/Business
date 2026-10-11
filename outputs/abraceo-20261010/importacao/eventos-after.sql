SELECT e.id_evento,e.nome_evento,e.data_inicial::date::text,e.data_final::date::text,e.ativo,e.organizador,
 coalesce((SELECT jsonb_agg(to_jsonb(c)) FROM tb_conta_eventos c WHERE c.id_evento=e.id_evento),'[]')::text contas,
 coalesce((SELECT jsonb_agg(to_jsonb(f)) FROM tb_evento_corridas_fornecedores f WHERE f.id_evento=e.id_evento),'[]')::text fornecedores
FROM tb_evento_corridas e WHERE e.id_evento IN (45372,46865,45442,47969,43912,40609,42066,42360,37144,36659,39384) ORDER BY e.id_evento
