# Preparação de voucher e publicidade durante a análise Business

Data: 23/08/2026

## Objetivo

Permitir que o responsável por uma conta Business nova continue o onboarding enquanto a conta e o evento ainda estão em análise. O usuário poderá reservar um voucher, preparar uma campanha e enviá-la para a fila de análise. Nenhum crédito será aplicado, saldo consumido ou anúncio publicado antes das aprovações necessárias.

O fluxo não se aplica a alguém que pediu acesso a uma conta já existente. Nesse caso, a pessoa continua sem acesso às ferramentas até ser aprovada por um OWNER da conta ou por um administrador RunnerHub.

## Princípios do fluxo

- Preparar não significa efetivar.
- Cada etapa informa claramente o que já foi salvo e o que ainda está esperando.
- A aprovação da conta aplica o voucher, mas não publica campanha.
- A aprovação do evento torna a campanha elegível para análise, mas não a publica.
- Somente um administrador RunnerHub aprova a publicidade para veiculação.
- Nenhuma campanha ativa sem conta ativa, evento ativo, aprovação do anúncio, saldo suficiente e período válido.
- Registros recusados ou cancelados não são apagados; ficam disponíveis para auditoria.

## Escopo de autorização

### Conta nova em análise

O usuário que criou a conta provisória conserva o papel OWNER somente dentro dessa conta. Ele pode:

- solicitar o vínculo de um evento;
- reservar um voucher para a conta provisória;
- criar e editar campanhas vinculadas a eventos pendentes solicitados por ele;
- enviar uma campanha pronta para aguardar os pré-requisitos e a análise RunnerHub;
- acompanhar todos os estados do onboarding.

Ele não pode:

- transformar o voucher em saldo antes da aprovação da conta;
- ativar campanhas;
- consumir saldo;
- operar eventos ainda não aprovados;
- acessar outra conta ou outro evento pendente.

### Pedido de acesso a conta existente

O solicitante não recebe acesso provisório. Home, login e navegação continuam mostrando apenas o estado de espera e o suporte. OWNERs da conta existente e administradores RunnerHub continuam sendo os únicos revisores desse pedido.

## Modelo de estados

### Voucher

O voucher terá uma reserva separada do resgate financeiro:

1. `RESERVED`: código validado e reservado de forma exclusiva para a conta provisória.
2. `APPLIED`: conta aprovada e crédito lançado uma única vez no saldo.
3. `RELEASED`: conta recusada/cancelada ou reserva cancelada; voucher volta a ficar disponível se ainda for válido.
4. `EXPIRED`: validade encerrada antes da aplicação.

Informar o voucher durante a análise não cria lançamento no `credit_ledger` e não altera o saldo disponível.

### Evento

O vínculo continua usando os estados atuais de `tb_conta_eventos`:

- `PENDENTE`: pedido enviado, disponível somente para preparar a campanha da própria conta provisória;
- `ATIVO`: vínculo aprovado e campanha elegível para análise;
- `INATIVO`: vínculo recusado ou desativado.

### Campanha e análise

A campanha continua `DRAFT` no mecanismo de publicidade enquanto não for aprovada. A análise é registrada separadamente para não introduzir estados incompatíveis com o delivery atual:

1. `DRAFT`: campanha ainda sendo preenchida.
2. `WAITING_PREREQUISITES`: usuário enviou; conta e/ou evento ainda não foram aprovados.
3. `PENDING_REVIEW`: conta e evento ativos; anúncio disponível na fila RunnerHub.
4. `CHANGES_REQUESTED`: admin devolveu a campanha com um motivo; usuário pode editar e reenviar.
5. `APPROVED`: admin aprovou e a campanha foi ativada pelo fluxo canônico.
6. `CANCELED`: conta recusada/cancelada ou campanha descartada.

`DRAFT`, `ACTIVE`, `PAUSED` e `ENDED` continuam sendo os estados do mecanismo de entrega. Os estados de análise pertencem a uma entidade própria de revisão.

## Persistência

### Reservas de voucher

Criar `ads.voucher_reservations` com:

- identificador da reserva;
- `id_ad_voucher`;
- `id_conta` provisória;
- `id_solicitacao_cadastro`;
- usuário que reservou;
- status da reserva;
- datas de criação, atualização, aplicação, liberação e expiração;
- motivo da última transição.

O status será texto com `CHECK` limitado a `RESERVED`, `APPLIED`, `RELEASED` e `EXPIRED`. Índices únicos parciais devem permitir no máximo uma reserva `RESERVED` por voucher e uma por solicitação de cadastro. As funções SQL de reserva, aplicação e liberação devem usar bloqueio de linha e transação para impedir resgate concorrente.

O resgate tradicional também deve rejeitar vouchers com reserva ativa pertencente a outro fluxo. A aplicação da reserva chama o mesmo lançamento idempotente usado no resgate atual.

### Revisão de campanha

Criar `ads.campaign_review_requests` com:

- identificador da revisão;
- `campaign_id`, `account_id` e `core_event_id`;
- status da revisão;
- usuário solicitante e revisor;
- data de envio, revisão e atualização;
- motivo de recusa/ajustes;
- chave idempotente da aprovação.

O status será texto com `CHECK` limitado a `WAITING_PREREQUISITES`, `PENDING_REVIEW`, `CHANGES_REQUESTED`, `APPROVED` e `CANCELED`. Um índice único parcial deve permitir apenas uma revisão aberta por campanha.

Criar também `ads.campaign_review_history` como histórico imutável de cada transição, contendo revisão, status anterior, novo status, ator, motivo e data.

## Regras de transição

### Reserva do voucher

1. O usuário informa o código em `/ads/`.
2. O backend confirma que ele é o OWNER da conta provisória criada por sua solicitação.
3. Em transação, valida código, disponibilidade, validade e ausência de outra reserva ativa.
4. Cria a reserva e mostra `Voucher reservado`.
5. Nenhum saldo é criado nesse momento.

### Aprovação da conta

Na mesma transação lógica da aprovação:

1. ativa a conta e o vínculo OWNER;
2. aplica uma eventual reserva de voucher à própria conta provisória;
3. marca a reserva como `APPLIED`;
4. reavalia campanhas em `WAITING_PREREQUISITES`;
5. mantém as campanhas fora do ar.

A aprovação não pode usar a conta originalmente associada ao voucher para substituir a conta provisória. O destino sempre é a conta criada na solicitação.

### Preparação e envio da campanha

1. A lista de eventos de campanha inclui vínculos `PENDENTE` pertencentes à conta provisória e solicitados pelo próprio usuário.
2. O usuário preenche evento, locais, período, CPC e orçamento normalmente.
3. `Salvar rascunho` mantém a campanha editável.
4. `Enviar para análise` cria ou atualiza a revisão:
   - `WAITING_PREREQUISITES` se conta ou evento ainda estiverem pendentes;
   - `PENDING_REVIEW` quando ambos estiverem ativos.
5. O orçamento pode superar o voucher reservado. Isso não cobra nem cria crédito; o saldo será conferido antes da ativação.

### Aprovação do evento

Após ativar o vínculo, o sistema reavalia revisões ligadas ao evento. Se a conta também estiver ativa, a revisão passa para `PENDING_REVIEW`. Caso contrário, permanece em `WAITING_PREREQUISITES`.

### Revisão do anúncio

O admin RunnerHub vê uma fila global de anúncios elegíveis. Ele pode:

- visualizar campanha, evento, placements, período, orçamento e conta;
- aprovar;
- solicitar ajustes com motivo obrigatório;
- cancelar em caso de abuso.

Ao aprovar, o backend verifica novamente conta ativa, evento ativo, saldo suficiente, período válido e integridade da campanha. Somente então chama `ads.activate_campaign`. Falha em qualquer pré-condição mantém a revisão aberta e informa o motivo; nunca ativa parcialmente.

### Recusas e cancelamentos

- Conta recusada/cancelada: libera voucher reservado e marca revisões abertas como `CANCELED`.
- Evento recusado/inativado: devolve a revisão para `CHANGES_REQUESTED`, informa o motivo e permite escolher outro evento.
- Campanha devolvida: permanece `DRAFT`, editável, sem perder os dados.
- Voucher expirado antes da aprovação: marca reserva como `EXPIRED` e avisa o usuário; aprovação da conta continua normalmente.

## Interface do usuário

### Home provisória

- Etapa 3 deixa de estar bloqueada e ganha `Reservar voucher`.
- Etapa 4 fica disponível depois que existir ao menos um pedido de evento e ganha `Preparar campanha`.
- Cada card mostra o estado real: `Reservado`, `Aguardando conta`, `Aguardando evento`, `Em análise` ou `Ajustes solicitados`.
- O rodapé reforça: nada é publicado e nenhum saldo é consumido antes das aprovações.

### Navegação

Para conta nova provisória, `Resgatar voucher` e `Publicidade` tornam-se links ativos. Para pedido de acesso a conta existente, ambos continuam bloqueados.

### Publicidade

- Exibir aviso persistente de preparação quando a conta estiver pendente.
- Trocar `Resgatar voucher` por `Reservar voucher` nesse estado.
- Mostrar eventos pendentes autorizados no formulário.
- Separar `Salvar rascunho` de `Enviar para análise`.
- Remover qualquer ação de ativação direta para usuários da conta.
- Mostrar os estados de análise e o motivo de ajustes.

### Administração

- Adicionar fila global de anúncios `PENDING_REVIEW`.
- Exibir dependências ainda pendentes sem permitir aprovação prematura.
- Aprovação e pedido de ajustes devem ficar auditados com usuário, data e motivo.

## Segurança e integridade

- Toda mutação exige sessão autenticada, CSRF válido e verificação server-side da conta, do ator e do papel.
- A conta provisória só é aceita quando nasceu da solicitação pendente do próprio usuário.
- Eventos pendentes só podem ser usados quando pertencem à mesma conta e foram solicitados pelo ator autorizado.
- A reserva de voucher é exclusiva e idempotente.
- Aplicação de crédito e ativação de campanha são idempotentes.
- O delivery continua consultando somente campanhas `ACTIVE`; estados de preparação nunca são servidos.
- Nenhuma decisão depende apenas de esconder botões no frontend.

## Alterações previstas

- Migration SQL para reservas de voucher, revisões de campanha, índices, funções e grants.
- `includes/backend/backend_login.cfm`: liberar `/ads/` somente para conta nova provisória.
- `includes/estrutura/sidenav.cfm` e `includes/estrutura/home_pending_account.cfm`: links e estados progressivos.
- `ads/includes/access.cfm`: contexto limitado da conta provisória.
- `ads/includes/backend.cfm`: conta pendente, evento pendente, reserva, envio e estados de revisão.
- `ads/includes/payments_home.cfm`: reserva em vez de aplicação imediata.
- `ads/includes/workspace_campaign_form.cfm` e `ads/includes/workspace_campaigns.cfm`: rascunho, envio e acompanhamento.
- Administração de publicidade: fila, aprovação e solicitação de ajustes.
- `administracao/contas/includes/backend.cfm`: aplicar/liberar reserva na decisão da conta sem trocar a conta provisória.
- Backend de aprovação de eventos: reavaliar revisões aguardando pré-requisitos.

## Testes e critérios de aceite

### Autorização

- OWNER de conta nova pendente acessa voucher e publicidade somente na própria conta.
- Solicitante de acesso a conta existente continua sem acesso.
- Usuário não consegue forjar `account_id`, `event_id`, voucher ou campanha de outra conta.

### Voucher

- Código válido cria uma única reserva e não altera saldo.
- Tentativa concorrente não reserva o mesmo voucher duas vezes.
- Aprovação da conta aplica o crédito uma única vez.
- Recusa libera a reserva.
- Expiração não impede aprovação da conta.

### Campanha

- Evento pendente autorizado aparece no formulário.
- Campanha salva permanece fora do delivery.
- Envio antes das aprovações fica `WAITING_PREREQUISITES`.
- Aprovação de conta e evento leva a `PENDING_REVIEW`, independentemente da ordem.
- Usuário da conta não consegue ativar campanha.
- Admin não aprova sem pré-condições completas.
- Aprovação administrativa ativa uma única vez.
- Pedido de ajustes preserva os dados e o motivo.

### Regressão

- Fluxos de contas já ativas continuam resgatando voucher e criando campanhas.
- Login, cadastro, vínculo de evento e administração de contas continuam passando nos testes existentes.
- ColdFusion compila sem erros e a jornada é verificada no navegador em desktop e mobile.

## Implantação

1. Aplicar migration aditiva e funções idempotentes.
2. Publicar backend com detecção de readiness das novas estruturas.
3. Publicar a interface do workspace provisório.
4. Validar com uma conta nova de teste, voucher controlado e evento pendente.
5. Validar que nenhuma campanha aparece no delivery antes da aprovação RunnerHub.
6. Liberar para o onboarding comercial.

Rollback da interface mantém os registros de reserva e revisão sem efeito financeiro ou de entrega. Rollback do banco só deve ocorrer após liberar reservas e cancelar revisões abertas de forma auditável.
