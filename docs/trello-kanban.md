# Integração Trello / Kanban

O módulo `/administracao/kanban/` permite que administradores do RunnerHub Business operem quadros autorizados do Trello no painel interno.

## Modelo de segurança

- O Trello continua sendo a fonte de verdade para quadros, listas, cartões, comentários, responsáveis e prazos.
- A chave e o token do Trello existem somente no servidor; nenhum segredo é enviado ao navegador.
- O Business usa uma credencial de serviço com acesso apenas aos quadros do Workspace RunnerHub.
- Cada quadro precisa ser autorizado em `tb_trello_quadros` pela tela **Kanban > Quadros**.
- Toda mutação valida se quadro, lista e cartão pertencem ao escopo autorizado.
- Criações, alterações, movimentos, comentários e arquivamentos são gravados em `tb_trello_auditoria` com o administrador responsável.
- Escritas exigem sessão administrativa e token CSRF.
- Parâmetros de escrita são enviados ao Trello em corpo `application/x-www-form-urlencoded`; chave e token seguem apenas no header `Authorization`.

## Instalação

1. Execute [`administracao/kanban/kanban_schema.sql`](../administracao/kanban/kanban_schema.sql) no banco `runner_dba`.
2. Crie uma aplicação/Power-Up no painel de desenvolvedores do Trello e gere uma API Key.
3. Autorize um usuário de serviço que seja membro somente dos quadros departamentais necessários e gere seu token.
4. Configure as variáveis de ambiente:

   - `RR_TRELLO_API_KEY`
   - `RR_TRELLO_API_TOKEN`
   - `RR_TRELLO_TIMEOUT_SECONDS` (opcional; padrão 20)

   Como alternativa local, use `trelloApiKey`, `trelloApiToken` e `trelloTimeoutSeconds` em `config/business.local.cfm`. Esse arquivo é ignorado pelo Git.

5. Reinicie a aplicação ColdFusion.
6. Acesse `/administracao/kanban/`, abra **Quadros** e vincule cada board ao respectivo departamento.

## Operações disponíveis

- consultar quadros autorizados, listas, cartões e membros;
- criar, editar, mover e arquivar cartões;
- atribuir responsáveis e prazos;
- consultar e publicar comentários;
- criar, renomear e arquivar listas;
- vincular ou remover quadros departamentais do painel.

Remover um vínculo local não altera nem arquiva o quadro no Trello. Arquivamentos de cartões e listas usam o mecanismo recuperável do próprio Trello.

Como as chamadas usam uma credencial de serviço compartilhada, o Trello mostra esse usuário como autor das alterações e dos comentários. A autoria individual do administrador do Business fica preservada em `tb_trello_auditoria`.

## Limites intencionais

O módulo não mantém uma cópia local dos cartões e não faz sincronização bidirecional. Cada carregamento consulta o Trello ao vivo. Webhooks podem ser adicionados futuramente para notificações ou indicadores agregados, sem transformar o Business em uma segunda fonte de verdade.

## Rotação da credencial

Ao trocar o usuário de serviço ou revogar o token, atualize o segredo no ambiente e reinicie a aplicação. Não registre tokens em logs, banco, URLs, screenshots ou chamados.
