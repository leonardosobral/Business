SELECT table_schema,table_name,column_name,data_type
FROM information_schema.columns
WHERE table_schema='public' AND (table_name IN ('tb_contas','tb_conta_eventos','tb_conta_usuarios','tb_conta_cadastro_solicitacoes','tb_evento_corridas','tb_evento_corridas_fornecedores','tb_fornecedores','tb_fornecedor_tipos') OR table_name ILIKE '%fornecedor%')
ORDER BY table_name,ordinal_position
