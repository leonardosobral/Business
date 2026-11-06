# Numeração de mandalas Brasil Gigante

Pedido: confirmar obrigatoriamente o número da mandala entregue ao participante, no botão de entrega existente. Implementação direta do incremento solicitado.

- Campo de número obrigatório (1 a12 dígitos, positivo; conservar zeros impressos) e confirmação de conferência, dentro de formulário recolhido junto ao botão. Sem dependência de JS; manter filtros e permissões atuais.
- Usar o histórico existente desafios_obs, sem DDL: preservar obs=mandala_entregue para compatibilidade e acrescentar obs=mandala_numero:<número>, com id_atendente e data_obs da gravação.
- Registro atômico, lock PostgreSQL por operação do módulo, rejeitar número já atribuído a outro usuário, equivalência de zeros à esquerda para duplicidade. Repetir o mesmo envio não duplica; número existente diferente não é substituído silenciosamente.
- Manter elegibilidade atual de sete etapas para nova entrega. Nas entregas históricas sem número, permitir completar o dado preservando a data e o responsável da entrega original.
- Mostrar número na listagem e Excel, indicar legado sem número; erros explicativos preservam formulário preenchido. Sem alterar outros desafios, resultados, critérios ou permissões.
- Testar validação, persistência/duplicação/conflito com transações revertidas e render sintético; publicar escopo com CAS, backup e conferência no navegador, sem confirmar uma entrega real durante teste.

## Verificação e publicação
- Cinco suítes específicas aprovadas:10 entradas de validação;9 verificações de persistência/leitura/idempotência/duplicidade/backfill com rollback; render e String no Excel;6 casos HTTP de guardas; backend real completo com6061 inscritos.
- Serviço preserva o marcador legado e data original. Testes de persistência usam somente alterações transacionais revertidas; nenhum número nem entrega de teste ficou atribuído a um participante.
- Publicados somente seis arquivos de runtime, com baseline HEAD correspondente em produção e backup recuperável /var/backups/business-cbg-mandala-hi0w3x7r. Sem DDL, credenciais, Git ou mudanças de outras frentes.
- Navegador autenticado: filtro de entregues mostra as três entregas antigas com “Número não informado”; abrir “Informar número” exibe campo obrigatório e caixa de conferência. Nenhum formulário real foi enviado. Captura /private/tmp/business-cbg-mandala-number-20261104.png.
- Excel real baixado no navegador validado como XLSX:21 colunas,3 linhas, cabeçalho “Número da mandala” em U1. Preservação de zeros testada no helper String. Busca por nome ou número disponível.
