# Help Desk — encerramento automático por inatividade

Pedido: quando a última interação for da equipe e tiver mais de 48 horas, com status diferente de Em atendimento, adicionar mensagem automática e mudar para Fechado. Escopo suficiente para implementação direta, sem ampliar a política de atendimento.

Usar um job autenticado no agendador existente, a cada 15 minutos, com lote limitado de 50. Não executar fechamento no carregamento da página (dependeria de navegação), nem criar scheduler paralelo. Sem IA, migração DDL, credenciais novas ou push adicional.

Elegíveis: status conhecidos aberto, cliente_respondeu, aguardando_cliente ou resolvido; última mensagem pública por data/id, escrita por administrador do atendimento que não seja o próprio solicitante; timestamp estritamente anterior a agora menos 48 horas. Notas internas não contam como interação com o usuário. Excluir fechado, em_atendimento, estados desconhecidos, última resposta do usuário e último aviso automático desta rotina.

Mensagem pública identificada como automática: `[Mensagem automática] Este chamado foi encerrado automaticamente por falta de interação. Não recebemos uma nova resposta sua nas últimas 48 horas após a mensagem da equipe de atendimento. Se ainda precisar de ajuda, responda a este chamado para continuar o atendimento.` Usar o autor da última resposta de atendimento para satisfazer a FK legada não nula, sem criar conta técnica ou atribuir uma nova resposta humana; identificação da automação explícita no texto e histórico do job.

Inserção da mensagem e status fechado/updated_at na mesma transação; lock dos chamados, SKIP LOCKED, revalidação após lock contra novas mensagens; execução repetida não duplica aviso. Histórico existente preservado, sem apagar dados. Resposta posterior do solicitante continua reabrindo pelo comportamento atual.

Publicação restrita a serviço/endpoint/alias de segredo de cron, com baseline, backup, testes privados revertidos, dry run e verificação real. Preservar outras frentes, estado pausado da geolocalização e não fazer commit/push.
