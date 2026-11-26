# Conciliação autorizada de 42 pagamentos VIP — 24/11/2026

O proprietário autorizou conciliar os 42 pedidos confirmados e, em resposta
específica, aplicar a todos os 42 o prazo do desafio. Os quatro casos divergentes
foram excluídos da alteração de direitos e separados para revisão.

## Dados e regras do Road Runners

- Nova consulta GET autenticada aos 42 pedidos: 38 VIP e quatro upgrades,
  todos pagos antes de 01/01/2026 no horário de Brasília. Nenhuma chamada de
  criação, cobrança, cancelamento ou estorno.
- Importação histórica usando `CrmPagarmeSnapshotService` e
  `CrmConversionService.ingest`, com classificação financeira, auditoria do
  provedor e eventos de pagamento. Preservado o contrato `provider_historical` /
  `unmatched` do CRM: não foi inventado um checkout autenticado retroativo nem
  atribuída receita a campanhas.
- Vínculo entre pagamento e atleta registrado em `rr_verified.challenge_orders`,
  com usuário, perfil, produto, valor e data efetiva conferidos contra a API e a
  referência local em `tb_transacoes`. A associação não foi inferida só por nome
  ou e-mail.
- Acrescentadas 42 `legacy_reclassifications` e removida apenas a flag permanente
  desses perfis. A função existente `challenge_end` definiu o vencimento exclusivo
  em 01/01/2027 00:00 de Brasília: ativo até **31/12/2026** inclusive.
- Os registros de concessão anteriores e todas as classificações administrativas
  foram preservados, inclusive a categoria elite do Guilherme. A decisão posterior
  do proprietário de aplicar prazo aos 42 abrangeu esse perfil; sua anotação não
  foi apagada ou reescrita.
- Resultado: 418 selos ativos, sendo 332 com prazo e 86 permanentes. O histórico
  mantém 418 grants legados em produção (o do proprietário havia sido removido
  em tarefa anterior) e o histórico de DEV permaneceu intacto.

Não foi necessária migração de schema nem publicação de runtime do Road Runners.
A operação usou somente DML nas tabelas existentes, em transação serializable,
com locks, validação de identidade e pré/pós-condições. Não alterou flags de compra.

## Revisão no Business

A aba [Divergências VIP](https://business.roadrunners.run/portal/verificados/?filter_status=divergent)
exibe exatamente:

- Gisele Lima: somente tentativas VIP recusadas.
- Paulo Dieter: pagamento confirmado somente da Básica.
- Gabi La Rosa: pedido estornado; cadastro de upgrade exige revisão.
- Wanessa Santos: nenhum pedido TSD localizado pelos vínculos consultados.

Seus selos permanentes continuam intactos. A fila usa registros de auditoria
`crm_interno.audit`, ação `verified.vip_review`, com status e razão estruturados.
Não depende de IDs fixos no código. A última anotação define a revisão; um vínculo
financeiro conciliado deixa de ser apontado como pendente. Os outros seis casos
ainda não conciliados permanecem em “Conferir VIP”; 61 motivos continuam a classificar.

Arquivos publicados: `services/VerifiedAdmin.cfc`,
`portal/includes/verified_backend.cfm` e `portal/verificados/home.cfm`.

## Evidências e recuperação

Pasta privada: `_codex/staging/verified-vip-reconcile-20261124/`.
`input.json` contém a evidência financeira sanitizada; `before.json` e
`financial-before.json` registram o estado anterior; `first-apply.json` é o recibo
da aplicação; `idempotence.json` confirma repetição sem nova gravação.

Backup de dados: `/var/backups/business-verified-vip-reconcile-20261124`.
`restore-permanents.sql` é uma recuperação emergencial, restrita ao lote e a 48h:
restaura apenas os direitos permanentes, preservando o histórico financeiro.
Não foi executada. Backup da publicação do painel:
`/var/backups/business-verified-vip-reconcile-ui-yr10vaam`.

Validação: ensaio integral com rollback, recusa de usuário incorreto, valor
divergente e evidência expirada; pós-condições dos 42 pedidos; hashes dos direitos
e históricos fora do escopo; repetição sem duplicidade; 64 verificações do painel,
incluindo 403 de administração/CSRF e 409 para a antiga ação de toggle. O datasource
de leitura do produto confirmou os 42 ativos no último segundo de 31/12/2026 e
os 42 inativos após a virada, sem concessões permanentes remanescentes no lote.
Desktop e mobile conferidos. Navegador, servidor de prévia e fixtures temporárias
foram encerrados/removidos e verificados. Não houve commit ou push.

Pós-publicação: oito páginas/casos renderizados com sucesso (HTTP 200), incluindo
os três exemplos e a aba com exatamente quatro divergentes. Fixtures removidas.
A flag de compras públicas foi lida em produção e permanece desativada.
