# Vínculos VIP na lista de selos — 24/11/2026

O usuário apontou Angélica Sandes, Bastos e Carina Aparecida Pereira como VIPs
confirmados ainda presentes em “Motivo a classificar”. A fila só considerava
concessões e pagamentos de `rr_verified`, ignorando a confirmação em `desafios`.

## Conferência financeira

Consulta GET na API V5, executada pelo servidor autorizado, sem expor a chave,
criar pedidos ou alterar pagamentos. Busca pelo e-mail exato e pelas referências
de pedidos já vinculadas ao usuário; paginação completa e validação dos filtros.
Dados de clientes/cartões não foram persistidos no relatório.

Nos 46 perfis da fila original com VIP/upgrade C no Todo Santo Dia:

- 42 têm pedido VIP/upgrade atualmente pago. Todos os 42 foram encontrados tanto
  pelo e-mail exato quanto pela referência local de pedido/transação.
- 4 exigem revisão: Gisele Lima (tentativas recusadas), Paulo Dieter (somente
  Básica paga), Gabi La Rosa (Básica estornada, upgrade C no cadastro) e Wanessa
  Santos (nenhum pedido TSD localizado pelos vínculos consultados).
- Os 42 pedidos pagos estão ausentes de `crm_interno.conversion_order_state`.
  Nos três exemplos do usuário, os eventos `order.paid` existem em `tb_transacoes`.
  A conciliação histórica incompleta explica a exclusão da migração anterior;
  não se tratava de falta de pagamento nesses três casos.
- Bastos também tem pedido estornado, mas outro pedido VIP permanece pago.
  O pagamento da Angélica é de dezembro/2025, embora seu cadastro VIP registre
  abril/2026. A data de inscrição não deve determinar o prazo pago.

Evidências privadas em `_codex/analyses/verified-challenges-20261124/`:
`vip-api-all.json`, `vip-api-three.json`, `vip-api-root-cause.json`,
`vip-api-ledger-coverage.json` e `conciliacao-vip-api.html`.

Referências dos filtros utilizados: [clientes](https://docs.pagar.me/reference/listar-clientes-1)
e [pedidos](https://docs.pagar.me/reference/listar-pedidos).

## Comportamento do Business

- A relação confirmada em `desafios` identifica VIP/upgrade, usando todas as
  associações válidas entre usuário e perfil. Básica e inscrições não confirmadas
  não retiram pessoas da fila de motivos desconhecidos.
- “Motivo a classificar” passa de 107 para 61. As 46 relações conhecidas ficam
  visíveis, sem inventar uma classificação manual ou uma origem exclusiva.
- “Conferir VIP” separa a conciliação pendente da identificação do vínculo.
  Mostra 52 perfis: os 46 analisados e outros seis que já possuíam classificação.
- Um upgrade conciliado também explica o cadastro VIP resultante; não gera
  pendência duplicada. Estornos e anotações de cancelamento continuam visíveis.
- Os resultados da consulta à API são uma auditoria datada. Não foram gravados
  no livro financeiro nem apresentados como conciliação permanente da aplicação.
  A tela diferencia cadastro confirmado de pagamento reconciliado.
- Não houve migração, concessão, revogação ou mudança de prazo. Permanecem
  418 selos ativos: 128 sem vencimento e 290 com prazo. Compras públicas inalteradas.
- A origem exclusiva dos outros selos permanentes não foi presumida. Corrigir
  a cobertura financeira e, se pertinente, seus prazos é uma operação separada.

## Validação e publicação

Escopo: `services/VerifiedAdmin.cfc`, `portal/includes/verified_backend.cfm` e
`portal/verificados/home.cfm`. 106 verificações no ColdFusion real, incluindo
os três perfis, contagens, filtros, upgrade, cancelamento e manutenção dos selos.
Controles de administração/CSRF retornaram 403; a ação antiga de toggle, 409.
Prévia desktop e mobile sem overflow horizontal, sessão Playwright isolada e
servidor local encerrados. Único erro de asset da prévia: favicon não fornecido.

Publicação com baseline, compilação CF2025, substituição atômica e backup:
`/var/backups/business-verified-vip-links-co_8da2l`.
Recibos em `_codex/staging/verified-vip-links-20261124/`.
Nenhum commit, push ou publicação de arquivos de outras frentes.

Verificação pós-publicação: lista, fila, Angélica, Bastos, Carina, conciliação e
histórico de estorno responderam 200 e passaram nas asserções. As fixtures
privadas foram removidas em `finally`, com confirmação de ausência.
