# Notificações: público dos indicadores — 28/09/2026

Publicado e verificado em produção. Escopo: `notificacoes/home.cfm`,
`notificacoes/includes/backend.cfm`, novo `notificacoes/includes/audience_filter.cfm`
e `includes/estrutura/home_admin_dashboard.cfm`.

## Comportamento

- Home exclui destinatários admin, destinatários sem usuário e publicações futuras; janela móvel de sete dias.
- Histórico abre em Usuários; abas Admins e Todos preservam filtros e reiniciam a página.
- Cards e listagem compartilham filtros. Clicks passa a Lidas; o antigo card comercial Conversão passa a Não lidas.
- Ações em lote recebem o mesmo filtro de público. Nenhuma ação de envio, leitura, exclusão ou desativação foi executada em produção nesta validação.
- Classificação usa o perfil atual do destinatário. Leitura registrada não comprova clique nem entrega de push.

## Evidência

- Teste isolado real CFML/PostgreSQL: `python3 _codex/scripts/test_notification_audience.py`, 20 verificações aprovadas. O revisor tentou repetir sem escalonamento e encontrou bloqueio no initdb; não conta como reprodução independente.
- Adobe ColdFusion: quatro arquivos compilados, zero erros.
- `git diff --check` aprovado.
- Revisão independente somente leitura: nenhum bloqueio encontrado.
- Suíte geral Node: 280/285 aprovados. Cinco falhas alheias ao escopo: arquivo News ausente; jsdom ausente; duas dependências pglite ausentes; contrato antigo compara Inscrições contra commit 87ccfa7. Nenhuma dessas áreas foi alterada por esta tarefa.
- Baseline de produção conferido antes da publicação; quatro hashes publicados e verificados.
- Backup recuperável: `/var/backups/business-notification-audience-20260928/baseline`.
- Navegador autenticado: Usuários padrão, Admins, Todos, paginação Admins página 2, troca de abas preservando campanha/data e reiniciando página, ativação por Enter, busca sem resultado com 0,00%, limpar filtros mantendo público.
- Layout conferido em desktop e 390×844; viewport restaurado. Evidência: `_codex/staging/notification-audience-published.png`.

Valores observados no momento da conferência (não são totais permanentes):

| Público / período | Total | Lidas | Taxa |
| --- | ---: | ---: | ---: |
| Usuários / histórico completo | 72.330 | 2.227 | 3,08% |
| Admins / histórico completo | 5.617 | 2.999 | 53,39% |
| Todos / histórico completo | 77.947 | 5.226 | 6,70% |
| Home / usuários últimos 7 dias | 4.598 | 62 | 1,3% |

Campanha rr-welcome desde 21/09/2026 em Todos: 278 notificações, 13 lidas (4,68%). A aba Admins no mesmo filtro retornou zero. Nenhum dado de produção foi alterado para os testes.

## Recuperação

`python3 _codex/scripts/deploy_notification_audience.py rollback` verifica alterações concorrentes antes de restaurar o baseline e remover somente o novo include introduzido pela publicação. Não foi necessário executar rollback.

Sem commit, push, migração ou publicação de arquivos de outras frentes.
