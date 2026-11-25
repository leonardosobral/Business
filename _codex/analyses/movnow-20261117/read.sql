SELECT jsonb_build_object(
'events',(SELECT coalesce(jsonb_agg(to_jsonb(e)),'[]') FROM (SELECT id_evento,nome_evento,cidade,estado,data_inicial,data_final,tag,ativo,url_inscricao,url_hotsite,tipo_corrida FROM tb_evento_corridas WHERE (data_final >= '2026-11-01' AND data_inicial<='2027-12-31') OR url_inscricao ILIKE '%movnow%' OR url_hotsite ILIKE '%movnow%' ORDER BY id_evento) e),
'account',(SELECT to_jsonb(c) FROM (SELECT id_conta,nome_conta,status FROM tb_contas WHERE id_conta=25) c),
'links',(SELECT coalesce(jsonb_agg(to_jsonb(c)),'[]') FROM tb_conta_eventos c WHERE id_conta=25),
'requests',(SELECT coalesce(jsonb_agg(to_jsonb(c)),'[]') FROM tb_conta_evento_solicitacoes c WHERE id_conta=25),
'actor',(SELECT coalesce(jsonb_agg(to_jsonb(a)),'[]') FROM (SELECT u.id,u.name,u.email,u.is_admin,coalesce(g.ativo,true) AS ativo,coalesce(g.excluido,false) AS excluido FROM tb_usuarios u LEFT JOIN tb_usuarios_gestao g ON g.id_usuario=u.id WHERE lower(u.email)='leonardo.sobral@gmail.com') a)
)::text AS payload