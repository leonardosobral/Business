SELECT c.id_conta,c.nome_conta,c.documento,c.status,c.email_principal,c.telefone_principal,p.id_origem,p.logo_path,
 (SELECT count(*) FROM tb_conta_usuarios u WHERE u.id_conta=c.id_conta) usuarios,
 (SELECT count(*) FROM tb_conta_eventos ce JOIN tb_evento_corridas e USING(id_evento) WHERE ce.id_conta=c.id_conta AND ce.status='ATIVO' AND e.data_inicial::date>'2026-10-11') eventos_futuros,
 p.dados->>'email_publico' email_pesquisado
FROM tb_contas c JOIN tb_conta_perfis_publicos p USING(id_conta) WHERE p.origem='ABRACEO' ORDER BY p.id_origem
