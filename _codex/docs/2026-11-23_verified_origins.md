# Origens dos selos no Business — 23/11/2026

Publicado em `/portal/verificados/` no Business. Escopo: consulta de direitos efetivos e classificação administrativa das concessões permanentes. Não altera os checkouts ou a concessão de benefícios do Road Runners.

## Fonte dos dados

- Estado e validade: contrato `rr_verified.profile_status` do Road Runners.
- VIP e upgrade: `rr_verified.challenge_orders`, com confirmação, período e estorno separados. Inscrição básica ou simples presença no cadastro de desafios não comprova direito ao selo.
- Compra anual: pedidos e concessões de `rr_verified.orders` / `grants`.
- Permanentes: marcação manual ou legado que não foi reclassificado como Todo Santo Dia.
- Influencer, imprensa, parceiro, equipe, cortesia e outro: anotações administrativas expressas, nunca inferidas do perfil ou das permissões da conta.

### Compras diretas do Atleta Verificado

No painel, **Ver pagantes** abre a lista de perfis com compra ou renovação avulsa, em ordem do último pagamento. O filtro inclui tanto uma renovação comprada antes do fim do VIP quanto um período pago já encerrado. O detalhe do perfil mostra o comprador, a data do pagamento e o período adquirido para cada pedido.

O resumo conta pedidos pagos do produto `rr_selo_verificado_anual`, contas compradoras distintas e a soma dos valores dos pedidos. Um segundo pedido pago pela mesma conta soma uma venda. Estornos e pedidos identificados como internos ou de DEV ficam fora dos totais, conforme a regra do funil. Os pagamentos do desafio têm sua própria origem. A situação atual do selo continua vindo de `rr_verified.profile_status`.

Na publicação: 418 ativos, sendo 128 permanentes e 290 com prazo. Há 244 perfis com VIP ativo e 48 com upgrade ativo, com sobreposição. O selo de Leonardo continua retirado conforme solicitação anterior. Os 419 registros originais de DEV não foram alterados; o legado operacional possui 418 após aquela retirada.

## Classificação manual pendente de migração

Executar `_codex/sql/2026-11-23_verified_classifications.sql` pelo DataGrip em `runnerhub`, como `runner_dba`, conforme preferência do proprietário. O SQL foi solicitado ao usuário, mas ainda não foi aplicado nesta entrega.

A tela funciona antes da migração e mostra a pendência apenas no editor. Depois, identifica automaticamente a disponibilidade da tabela e função. O editor registra categoria, motivo, administrador e data; versões anteriores permanecem. Não é possível classificar uma compra como concessão permanente. A função confere administrador, concessão existente, categoria, tamanho do texto e revisão concorrente. O runtime tem SELECT no histórico e EXECUTE na função, sem UPDATE/DELETE no histórico.

A interface antiga alterava apenas `tb_paginas.verificado`: não representava o direito anual e podia transformar compras em permanência ou não revogar um legado. Os atalhos antigos de ativar/desativar, inclusive em lote, foram retirados desta tela. POSTs antigos recebem 409 sem alteração. Esta entrega não implementa um novo fluxo de concessão/revogação.

## Validação

- 102 verificações nativas CF2025: contagens, origens, paginação, busca parametrizada, filtros de cadastro, validade e dois estornos reais da conta de teste.
- Respostas 403 para falta de autorização e CSRF inválido; 409 para ação antiga. Testes de POST protegidos por transação PostgreSQL READ ONLY e rollback, sem possibilidade de alteração no banco real.
- Migração testada em PostgreSQL 16 temporário local: idempotência, autorização, validação, conflito de versão, histórico e preservação dos selos. Cluster encerrado/removido ao concluir.
- Compilação CF2025, hashes e acesso público conferidos. Pós-publicação: lista, VIP, permanente e estorno renderizados pelo código efetivamente publicado, com HTTP 200 em fixture privada somente de leitura.
- Desktop e mobile (390px) conferidos em prévia do HTML renderizado; sem overflow horizontal. Não houve sessão administrativa de usuário autenticada no navegador de teste.

## Publicação

Cinco arquivos de runtime: `services/VerifiedAdmin.cfc`, `portal/includes/verified_backend.cfm`, `portal/verificados/{index.cfm,home.cfm,verified.css}`.

Backup recuperável: `/var/backups/business-verified-origins-7nhm9zqh`.

Recibos, hashes e prévias em `_codex/staging/verified-origins-20261123/`.
Não houve commit, push, migração remota, envio de notificação, alteração de pagamentos, concessão ou remoção de selo nesta tarefa.
