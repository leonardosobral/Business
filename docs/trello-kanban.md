# Integração Trello / Kanban

O módulo `/administracao/kanban/` permite que administradores do RunnerHub Business operem quadros autorizados do Trello no painel interno.

## Modelo de segurança

- O Trello continua sendo a fonte de verdade para quadros, listas, cartões, comentários, responsáveis e prazos.
- A chave e o token do Trello existem somente no servidor; nenhum segredo é enviado ao navegador.
- O Business usa uma credencial de serviço com acesso apenas aos quadros do Workspace RunnerHub.
- Cada quadro precisa ser autorizado em `tb_trello_quadros` pela tela **Kanban > Quadros**.
- Toda mutação valida se quadro, lista, cartão e sub-recurso pertencem ao escopo autorizado. Isso inclui checklist, comentário, anexo, etiqueta, membro e campo personalizado.
- Criações, alterações, movimentos e exclusões são gravados em `tb_trello_auditoria` com o administrador responsável.
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

- consultar quadros autorizados, listas, cartões, etiquetas e membros;
- criar e editar título, descrição, lista, data inicial, prazo e estado do prazo;
- atribuir ou remover responsáveis e etiquetas, além de criar uma etiqueta diretamente no cartão;
- definir capa colorida ou usar um anexo como capa;
- configurar endereço, nome do local e coordenadas;
- observar ou deixar de observar o cartão pela conta integrada;
- criar, renomear e excluir checklists; criar, concluir, editar e excluir itens, com prazo, lembrete e responsável;
- anexar links e enviar arquivos de até 10 MB; abrir, definir como capa e remover anexos;
- consultar a atividade, publicar, editar e excluir comentários permitidos pela credencial do Trello;
- visualizar e alterar Campos Personalizados de texto, número, data, checkbox e lista quando o Power-Up estiver habilitado no quadro;
- reordenar cartões por arrastar e soltar, inclusive entre listas;
- duplicar cartões com seu conteúdo e mover cartões entre departamentos autorizados;
- arquivar, consultar arquivados, restaurar e excluir permanentemente cartões;
- criar, renomear e arquivar listas;
- vincular ou remover quadros departamentais do painel.

Remover um vínculo local não altera nem arquiva o quadro no Trello. Arquivamentos de cartões e listas usam o mecanismo recuperável do próprio Trello. A exclusão permanente de um cartão exige que o administrador digite `EXCLUIR` e não pode ser desfeita.

Uploads são mantidos apenas no diretório temporário durante o envio e apagados imediatamente depois. Arquivos executáveis, scripts e páginas HTML são bloqueados. O limite do Business é 10 MB, ainda que o plano do Trello permita um valor diferente.

Como as chamadas usam uma credencial de serviço compartilhada, o Trello mostra esse usuário como autor das alterações e dos comentários. A autoria individual do administrador do Business fica preservada em `tb_trello_auditoria`.

## Comportamentos do Trello e limites intencionais

O módulo não mantém uma cópia local dos cartões e não faz sincronização bidirecional. Cada carregamento consulta o Trello ao vivo. Webhooks podem ser adicionados futuramente para notificações ou indicadores agregados, sem transformar o Business em uma segunda fonte de verdade.

- **Campos Personalizados:** dependem do Power-Up correspondente e do plano/permissões do quadro.
- **Comentários:** a API só permite editar ou excluir comentários que a credencial integrada possa alterar. Comentários de outros usuários continuam visíveis, mas o Trello pode negar a edição.
- **Observar:** notificações são associadas ao usuário de serviço do Trello, não individualmente ao administrador do Business.
- **Recursos decorativos ou de Power-Ups:** stickers, votos, dados privados de Power-Ups, automações Butler e cartões espelho não são reproduzidos no Business. Eles continuam disponíveis no link **Abrir no Trello**.

## Rotação da credencial

Ao trocar o usuário de serviço ou revogar o token, atualize o segredo no ambiente e reinicie a aplicação. Não registre tokens em logs, banco, URLs, screenshots ou chamados.
