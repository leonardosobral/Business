SELECT jsonb_build_object(
 'consultado_em',now(),
 'contas',(SELECT coalesce(jsonb_agg(x),'[]') FROM (SELECT c.id_conta,c.nome_conta,c.tipo_titular,c.documento,c.nome_titular,c.email_principal,c.telefone_principal,c.status,c.data_criacao,(SELECT count(*) FROM public.tb_conta_usuarios u WHERE u.id_conta=c.id_conta AND u.status::text='ATIVO') AS usuarios_ativos,(SELECT count(*) FROM public.tb_conta_eventos ce WHERE ce.id_conta=c.id_conta AND ce.status::text='ATIVO') AS eventos_ativos FROM public.tb_contas c WHERE c.tipo_titular::text='PJ' ORDER BY c.id_conta) x),
 'solicitacoes',(SELECT coalesce(jsonb_agg(x),'[]') FROM (SELECT id_solicitacao,nome_empresa,documento,id_conta,status,site,cidade,estado,tipo_prestador,data_criacao FROM public.tb_conta_cadastro_solicitacoes WHERE tipo_titular::text='PJ' ORDER BY id_solicitacao) x),
 'fornecedores',(SELECT coalesce(jsonb_agg(x),'[]') FROM (SELECT id_fornecedor,nome_fornecedor,CASE WHEN length(regexp_replace(coalesce(cnpj_cpf,''),'[^0-9]','','g'))=14 THEN cnpj_cpf ELSE NULL END AS cnpj,ativo,tag_fornecedor,imagem_fornecedor,site_fornecedor,cidade,estado,tag_tipo,status FROM public.tb_fornecedores ORDER BY id_fornecedor) x),
 'tipos_fornecedor',(SELECT jsonb_agg(x) FROM public.tb_fornecedores_tipos x),
 'eventos_totais',(SELECT count(*) FROM public.tb_evento_corridas),
 'eventos_ativos',(SELECT count(*) FROM public.tb_evento_corridas WHERE ativo),
 'contas_pf_nao_extraidas',(SELECT count(*) FROM public.tb_contas WHERE tipo_titular::text='PF')
)::text AS payload
