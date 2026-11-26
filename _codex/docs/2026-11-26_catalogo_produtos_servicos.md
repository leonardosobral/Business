# Catálogo comercial do Business

O menu **Contas e parceiros → Produtos e serviços RH** abre `/administracao/produtos-servicos/` para administradores. Cada item descreve público, cobrança, início e fim da relação comercial e sistemas de registro. O campo `a_confirmar` identifica regras propostas e lacunas de conciliação.

A página consulta `public.tb_business_produtos_servicos` pelo datasource `runner_dba`. Para instalar, execute [o SQL](../sql/2026-11-26_catalogo_produtos_servicos.sql) inteiro no banco `runnerhub` como `runner_dba`. Na primeira instalação, o recibo mostra nove itens, cinco no grupo de atletas e consumidores e quatro no de organizadores e parceiros. Reexecutar o arquivo preserva alterações feitas depois do cadastro inicial.

A tabela descreve o portfólio. Compras, créditos e concessões de selo continuam sob responsabilidade dos respectivos módulos. Antes da instalação, a página informa que aguarda o SQL.
