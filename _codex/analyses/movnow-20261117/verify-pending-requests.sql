SELECT jsonb_build_object(
'account',(SELECT jsonb_build_object('id_conta',id_conta,'nome_conta',nome_conta,'status',status) FROM tb_contas WHERE id_conta=25),
'links',(SELECT coalesce(jsonb_agg(to_jsonb(v) ORDER BY id_evento),'[]') FROM tb_conta_eventos v WHERE id_conta=25),
'requests',(SELECT coalesce(jsonb_agg(to_jsonb(s) ORDER BY id_evento),'[]') FROM tb_conta_evento_solicitacoes s WHERE id_conta=25),
'logs',(SELECT coalesce(jsonb_agg(to_jsonb(l) ORDER BY id_log),'[]') FROM tb_log l WHERE log_user='codex:movnow-20261117;actor=139' AND log_item='solicitar_evento_conta')
)::text AS payload