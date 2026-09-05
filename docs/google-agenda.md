# Agenda Google do Business

Módulo: `/administracao/agenda/`. Conta autorizada: **contato@runnerhub.run**.

O código implementa OAuth 2.0 com PKCE, agenda mensal/semanal/lista, busca no período, criação/edição/exclusão, eventos de dia inteiro, participantes, recorrências e vínculo com cartões do Kanban. O Google mantém os eventos; o banco local guarda a conexão criptografada, as agendas habilitadas, os vínculos e a auditoria. Nenhum evento é publicado no portal de provas.

## Ativação no servidor

1. Publique `administracao/agenda/`, `Application.cfc`, `includes/estrutura/sidenav.cfm`, `administracao/kanban/index.cfm`, `administracao/kanban/home.cfm` e `administracao/kanban/assets/kanban.js`. Preserve as demais alterações locais do Kanban. O exemplo de configuração e esta documentação não contêm segredos.
2. Execute `administracao/agenda/agenda_schema.sql` no PostgreSQL `runner_dba`. A migração é transacional e pode ser repetida. Ela depende de `public.tb_usuarios`, já utilizada pelo Business. O vínculo com cartões exige também o schema do Kanban.
3. Configure no ambiente do processo ColdFusion:

   | Variável | Valor |
   |---|---|
   | `RR_GOOGLE_CALENDAR_CLIENT_ID` | Client ID do aplicativo Web criado no Google |
   | `RR_GOOGLE_CALENDAR_CLIENT_SECRET` | Client Secret desse mesmo cliente |
   | `RR_GOOGLE_CALENDAR_TOKEN_KEY` | Chave aleatória de 32 bytes codificada em Base64 |

   Gere a chave com `openssl rand -base64 32`, em um terminal privado do servidor. Guarde-a junto aos segredos e ao procedimento de restauração de backup. Não gere uma nova chave a cada reinício: isso invalidaria a leitura do refresh token existente. Para rotacioná-la, desconecte a integração, troque a chave, reinicie e conecte novamente.

   Como alternativa, mescle estes campos no struct existente de `config/business.local.cfm`, ignorado pelo Git: `googleCalendarClientId`, `googleCalendarClientSecret`, `googleCalendarTokenKey`. Não substitua as outras configurações. Consulte `config/business.local.example.cfm`. Variáveis de ambiente têm precedência.
4. Reinicie a aplicação ColdFusion pelo procedimento administrativo do servidor. Não é necessário reiniciar a conta Google.
5. Acesse `https://business.roadrunners.run/administracao/agenda/` como administrador do Business e clique em **Conectar Google**.
6. Entre com **contato@runnerhub.run** e conceda todas as permissões solicitadas. O módulo rejeita outro e-mail e exige e-mail verificado pelo Google.
7. Abra **Configurar agendas**, marque as agendas que os administradores poderão operar e salve. A seleção é compartilhada entre os administradores do Business.
8. Faça um teste com um compromisso sem participantes: criar, confirmar no Google, editar no Google, atualizar no Business, editar no Business e excluir. Depois teste um cartão pelo botão **Agendar**. Só use participantes reais quando desejar enviar os convites.

O código por si só não configura o servidor nem autoriza a conta. A validação com o Google real depende das etapas acima.

## Configuração Google já definida

- Cliente OAuth: **Aplicativo da Web**.
- URI de retorno exata: `https://business.roadrunners.run/administracao/agenda/oauth/callback.cfm`.
- API: **Google Calendar API**, habilitada no projeto desse cliente.
- Escopos: `openid`, `email`, `https://www.googleapis.com/auth/calendar.calendarlist.readonly`, `https://www.googleapis.com/auth/calendar.events.owned`.
- Agendas compartilhadas em que a conta não seja proprietária não são habilitadas nesta versão. O escopo solicitado corresponde às agendas próprias, conforme o planejamento inicial.
- Se o aplicativo for Externo/Testing, adicione a conta como test user; o refresh token para esses escopos expira em sete dias. Para operação contínua, configure o público/publicação apropriados e atenda à verificação que o Google exigir. Para um app interno de uma organização Workspace, use Internal quando disponível. O administrador Workspace pode precisar liberar o cliente.

## Comportamento dos eventos

- Horários de edição e exibição usam `America/Sao_Paulo`, inclusive regras históricas do fuso. Eventos de dia inteiro usam datas sem conversão de fuso; a data final é exclusiva.
- Mês e semana exibem eventos em cada dia ocupado, com horários. A lista mostra os dias com eventos. A busca filtra título, local e descrição no período carregado.
- Novas séries podem repetir diariamente, semanalmente ou mensalmente, com 2–52 ocorrências.
- Ao abrir uma ocorrência, editar ou excluir afeta somente essa ocorrência. **Editar série inteira** busca o evento principal e permite alterar seus dados ou excluir a série inteira. A regra de repetição existente é preservada; regras avançadas e mudanças de frequência de séries existentes são feitas em **Abrir no Google**.
- A leitura seguida de atualização condicional (`If-Match`) impede sobrescrever um evento alterado desde que o formulário foi aberto. Campos não editados, como lembretes e dados da conferência, são preservados.
- Em cada gravação/exclusão, o usuário escolhe notificar todos (`sendUpdates=all`) ou não solicitar notificações (`none`). Sem notificações, agendas externas podem não receber a atualização. A API Google pode ainda emitir determinados e-mails próprios do serviço.
- Tipos especiais de evento, como foco e ausência, devem ser editados no Google; o backend bloqueia a alteração desses tipos.
- Agendas e eventos são consultados ao vivo com paginação. A interface atualiza ao mudar de período ou clicar em Atualizar; não há webhook ou sincronização contínua em segundo plano. Uma consulta aceita no máximo 93 dias e 5.000 eventos.

## Kanban e novas tentativas

- O botão **Agendar** aparece em cartões salvos. O servidor consulta o Trello e valida que o cartão pertence a um quadro autorizado antes de ler ou criar o vínculo.
- Na primeira abertura, o título, a descrição e o prazo são usados como sugestão. O usuário revisa agenda, início e término antes de salvar. O compromisso inclui a origem com o link do cartão no Trello.
- Cada cartão possui no máximo um vínculo local. A próxima abertura do cartão encontra o compromisso existente. Alterar prazos, mover ou arquivar cartões no Trello não altera automaticamente os compromissos.
- O identificador da criação é estável durante novas tentativas do mesmo formulário. Para cartões, o vínculo é reservado antes da chamada Google: depois de uma resposta incerta, a nova tentativa usa o mesmo ID. Se o Google já criou o evento, o conflito de ID recupera esse evento em vez de duplicá-lo.
- Eventos excluídos por este módulo liberam o vínculo. Um evento cancelado no Google também libera o vínculo ao abrir o cartão. Uma reserva ainda sem evento mantém o ID para permitir nova tentativa segura.

## Segurança e operação

- Página, API e callback usam a autenticação existente e `require_admin.cfm`. Todas as chamadas à API exigem POST e token CSRF da sessão.
- O estado OAuth é de uso único, expira em dez minutos e é vinculado ao administrador que iniciou a conexão. O fluxo usa PKCE S256 e valida a identidade pelo endpoint UserInfo do Google antes de guardar a credencial.
- O refresh token é criptografado com AES-256-CBC, IV aleatório e HMAC-SHA256 sobre o ciphertext. A assinatura é comparada em tempo constante antes da descriptografia. Chaves de cifragem e autenticação são separadas por contexto. A chave raiz fica fora do banco.
- Access tokens ficam apenas na memória da aplicação. Credenciais não são enviadas à interface, aos logs ou à auditoria. Evite registrar cabeçalhos Authorization, corpos do token endpoint e query strings do callback na infraestrutura de observabilidade.
- A agenda selecionada é validada tanto na lista local quanto no Google antes de acessar eventos. Toda mutação registra o administrador do Business. A autoria exibida pelo Google é da conta compartilhada.
- Os registros de auditoria começam como `pending` antes da escrita remota e terminam como `success` ou `failed`. Um `pending` após uma interrupção ou `failed` após uma falha de rede exige conferir o Google antes de concluir que a alteração não aconteceu. A auditoria não armazena conteúdo dos eventos ou participantes.
- Operações da integração são serializadas por um lock da aplicação, protegendo renovação de tokens, conexão, seleção de agendas e reservas de cartões. Este mecanismo pressupõe uma única instância ColdFusion; múltiplas instâncias exigem lock distribuído antes de habilitar escritas concorrentes.
- Desconectar remove o refresh token local e tenta revogá-lo no Google. Se a revogação falhar, a tela orienta remover o acesso em Conta Google → Segurança → Conexões com apps de terceiros. Os eventos e vínculos são preservados.

## Verificação reproduzível

Sem Google real:

```sh
node --test _codex/tests/google-agenda.test.js _codex/tests/trello-kanban.test.js _codex/tests/business-sidenav.test.js
npm install --prefix /tmp/runnerhub-agenda-test --no-audit --no-fund jsdom @electric-sql/pglite
NODE_PATH=/tmp/runnerhub-agenda-test/node_modules node --test _codex/tests/google-agenda-browser.test.js _codex/tests/google-agenda-schema.test.js
```

`GoogleAgendaCfmlCheck.java` compila as funções CFML da API, serviço e callback e executa `google-agenda-service.cfscript` com fronteiras externas simuladas. Requer Java, Lucee 6.2.1.122 e os JARs Servlet API 4.0.1/JSP API 2.3.3 no classpath. Passe a raiz do repositório e uma pasta temporária gravável como argumentos. Este teste não substitui a homologação na versão ColdFusion do servidor.

Referências: [OAuth Web Server](https://developers.google.com/identity/protocols/oauth2/web-server), [escopos Calendar](https://developers.google.com/workspace/calendar/api/auth), [criar eventos e notificações](https://developers.google.com/workspace/calendar/api/v3/reference/events/insert), [atualizar eventos](https://developers.google.com/workspace/calendar/api/v3/reference/events/update).
