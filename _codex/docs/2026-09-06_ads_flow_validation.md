# Validação funcional pós-deploy — 06/09/2026

## Resultado desta rodada

Login Google confirmado pelo usuário após sair e entrar novamente. A sessão administrativa também foi usada nesta rodada para navegar em Ads, trocar o contexto para Grupo STC e retornar a Todas as contas.

**A veiculação do Avaí foi observada no site real. O fluxo completo de um cliente novo ainda não foi repetido.** Não considerar as verificações abaixo como homologação de reserva, cadastro e aprovações HTTP ponta a ponta.

## Verificações no navegador

| Etapa | Evidência | Limite |
| --- | --- | --- |
| Admin global | Performance, fila de revisão e campanhas em operação renderizaram; fila sem solicitações. | Não havia campanha pendente para testar uma decisão real. |
| Contexto da conta | Grupo STC mostrou sua lista, saldo e detalhe; retorno para Todas as contas funcionou. | Sessão de admin real, não substitui o teste com OWNER/OPERADOR/cliente pendente. |
| Vouchers | Cadastro promocional/de conta disponível ao admin; voucher de teste antigo aparece resgatado na Protta Corp. | Não criado/resgatado outro código; nenhum teste de reserva duplicada em produção. |
| Campanhas | Lista exibiu Avaí ativo e Campanha Final Floripa pausada; detalhe individual do Avaí abriu com gráfico, orçamento, segmentação e histórico. | As campanhas existentes não foram editadas, pausadas ou reenviadas. |
| Assistente | Percorridos os quatro passos de criação, sem salvar. Evento e nome automáticos; CPC sugerido R$ 0,94 e estimativa 80–106 cliques para R$ 100; região SC; fim sugerido três dias antes da data cadastrada do evento. | Não foi enviado POST de criação. |
| Navegação do assistente | Captura visual confirmou o passo 4 destacado e os três anteriores concluídos; Página inicial aparece como opção única para ambos os destaques. | Não valida todas as larguras de tela ou edição de campanha aprovada. |
| Saldo/pagamentos | Formulários de voucher e crédito adicional renderizaram; histórico mostrou PIX anterior como Pago/Creditado. | Checkout novo, webhook, débito e reconciliação contábil não foram provocados. |
| RoadRunners | Em `https://roadrunners.run/estado/sc/`, o Avaí apareceu visualmente no bloco Patrocinado acima da lista orgânica. | Um contexto de estado e navegador; não é matriz completa de spots/dispositivos/visitantes. |

Na leitura inicial, o Avaí mostrava 112 impressões, 11 cliques, 504 entregas e R$ 5,61 consumidos. Ao final, mostrava 114 impressões, 11 cliques, 506 entregas e os mesmos R$ 5,61. Visitas de validação podem produzir entregas/impressões normais; não foi clicado o link CPC do anúncio e não se atribui toda a variação exclusivamente ao teste.

O navegador foi devolvido ao contexto administrativo Todas as contas. A aba pública de SC foi mantida aberta como evidência visual. O formulário de campanha não foi salvo.

## Testes locais executados novamente

- Node: **24 testes passaram**, em `ads-campaign-wizard`, `ads-performance-dashboard`, `ads-coldfusion-symbols`, `banner-management-https` e `event-request-panel`.
- PostgreSQL descartável: **24 contratos de revisão/invariantes passaram**, incluindo conta/evento aprovados em ambas as ordens, isolamento de ator, revisão obrigatória, invalidação de revisão após edição e decisão vinculada ao ID apresentado.
- Concorrência: **duas ordens passaram** — edição antes da aprovação e aprovação antes da edição; operação concorrente rejeitada sem deadlock.
- Helpers SQL do leilão: `test_ads_event_auction_scoring.sh` passou, cobrindo relevância regional, lance, preço limitado ao lance e desempate determinístico. Não equivale a executar todo o delivery em produção.
- Contratos shell passaram: login routing; existing account access request; pending onboarding access/schema/campaigns/approvals; global vouchers; voucher balance bridge; approved campaign edit; campaign detail; performance dashboard; payment reconciliation; business access.

Os testes PostgreSQL não usam conexão de produção: criam cluster local com socket privado, carregam funções reais e fixtures públicas mínimas e removem esse cluster ao terminar. A primeira tentativa foi bloqueada pela restrição de memória compartilhada da sandbox; a execução local autorizada fora dela passou.

### Uma assertiva antiga falhou — não ocultar

`test_ads_phase2_payment_panel.sh` falhou apenas no gate “administracao financeira permanece restrita ao admin interno”. O padrão estático espera o include de `workspace_admin.cfm` condicionado exclusivamente a `adsAccessCanAdminFinance`; o workspace atual também contém a revisão global e aceita `adsAccessCanReviewCampaign`.

Diagnóstico dos limites efetivos:

- `ads/home.cfm`: a rota administrativa exige capacidade de finanças ou revisão.
- `ads/includes/workspace_admin.cfm`: crédito, movimentações e estorno ficam em bloco próprio condicionado a `adsAccessCanAdminFinance`.
- `ads/includes/access.cfm`: capacidade financeira exige conta, ator e administrador real.
- `ads/includes/backend.cfm`: as consultas do ledger e a execução de crédito/estorno exigem essa capacidade; tentativa sem capacidade é rejeitada com 403.
- `test_ads_phase2_business_access.sh`: os contratos atuais desses limites passaram.

A assertiva precisa ser atualizada para verificar os dois níveis de proteção. Nenhum código ou teste foi alterado para fazê-la passar nesta rodada; a inspeção estática não substitui teste HTTP com usuário não-admin.

## Próximo teste necessário

1. Confirmar usuário/conta de teste — sugerido novamente Cauã — e inspecionar seus vínculos atuais, sem reset destrutivo automático.
2. Usar voucher não consumido; o código antigo não representa uma reserva nova disponível.
3. Repetir como cliente: cadastro → pedido de evento → reserva do voucher → salvar rascunho → enviar para análise enquanto pendente.
4. Conferir e executar as decisões autorizadas, verificando aplicação única do voucher e manutenção do anúncio fora do ar até aprovação RunnerHub.
5. Validar delivery e, com autorização financeira específica, clique controlado/ledger no ambiente escolhido.

Não houve deploy, migration, concessão de acesso, aprovação, criação de campanha, resgate ou limpeza de usuário nesta rodada. Os pontos R08–R11 do relatório de rollout continuam pendentes, assim como a homologação completa de cliente novo e conta existente.
