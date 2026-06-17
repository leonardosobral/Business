# Vouchers de Credito para Ads

## Objetivo

Permitir que o time interno gere um codigo de voucher para uma conta Business. A empresa recebe esse codigo e o usuario que fizer o cadastro ou estiver logado pode resgatar o voucher para:

- vincular o usuario a conta;
- liberar credito de ads para a conta;
- operar campanhas usando os eventos ja vinculados a conta.

## Fluxo MVP

1. Admin cria ou seleciona uma conta em `/administracao/contas/`.
2. Admin cria um voucher na secao "Vouchers de ads".
3. Sistema grava o voucher em `tb_ad_vouchers`, com:
   - `id_conta`;
   - `codigo`;
   - `credito`;
   - `credito_disponivel`;
   - `papel_resgate`;
   - `status = 1`.
4. Empresa recebe o codigo.
5. Se o usuario ja estiver logado, pode informar o codigo em `/cadastro/` e o sistema vincula o usuario direto a conta.
6. Se o usuario ainda nao estiver logado/cadastrado, envia a solicitacao por `/cadastro/` com o codigo. O admin aprova a solicitacao e o voucher e resgatado para esse usuario.
7. Depois do resgate, o voucher fica `status = 2`, com `id_usuario_resgate` e `data_resgate`.
8. Admin pode cancelar ou reativar vouchers ainda nao resgatados pela mesma secao da conta.
9. `/ads/` mostra saldo calculado como credito resgatado menos consumo registrado em `tb_ad_log`.
10. `/ads/` mostra um extrato resumido com vouchers resgatados e consumo por campanha.
11. Contas sem saldo positivo nao criam campanhas; contas com saldo nao podem criar campanha com limite maior que o saldo disponivel.

## Status de `tb_ad_vouchers`

- `1`: disponivel para resgate.
- `2`: resgatado.
- `3`: cancelado/inativo.

## SQL

O incremental esta em:

- `_codex/sql/2026-06-14_tb_ad_vouchers_contas.sql`

Ele estende a tabela legada `tb_ad_vouchers` para o modelo de contas e adiciona referencia opcional na fila de cadastro externo `tb_conta_cadastro_solicitacoes`.

## Calculo de saldo

No MVP, o saldo nao e persistido em uma tabela de lancamentos. Ele e calculado em `/ads/` assim:

- credito total: soma de `tb_ad_vouchers.credito_disponivel` dos vouchers resgatados (`status = 2`);
- consumo: soma de `tb_ad_log.valor_ad` dos clicks cobrados (`status = 2`) das campanhas da conta;
- saldo: credito total menos consumo, limitado a zero.

O reposititorio atual nao contem o ponto que insere os registros em `tb_ad_log`. Por isso, a tela de ads exibe o extrato por leitura do log existente, mas ainda nao atualiza `credito_disponivel` nem cria lancamentos persistidos por consumo.

## Pendencias futuras

- Criar controle de extrato de credito por conta se o produto precisar de historico financeiro auditavel.
- Persistir abatimentos em `credito_disponivel` ou em tabela propria de ledger se o saldo precisar ser auditado por lancamento.
- Definir se voucher resgatado sempre cria `OWNER` ou se campanhas futuras devem usar `OPERADOR` como padrao.
