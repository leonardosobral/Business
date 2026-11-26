# Consulta financeira dos 57 pendentes

## Resultado da API V5 em 24/11/2026

Consulta GET por e-mail exato e referências individuais de pedido. Paginação limitada e conferência individual de cada pedido retornado. Inclui todos os produtos e upgrades, sem exigir inscrição prévia na Básica. Segredos permanecem no servidor; não foram feitas cobranças, estornos, criação de pedidos ou alterações de selos.

Foram localizados 105 pedidos para 33 dos 57 perfis; 24 ficaram sem correspondência pelos vínculos disponíveis. Houve 36 pedidos aprovados, 6 com estorno confirmado e 63 sem aprovação. Entre os aprovados: 13 Básica Todo Santo Dia, 14 inscrição Desafio 365 e 9 VIP Desafio 365. Os sete upgrades TSD encontrados não estão aprovados. Não foi encontrado novo VIP/upgrade TSD aprovado sem vínculo com o selo. VIP Desafio 365 é informação histórica, não comprovação de vigência do Todo Santo Dia.

A pesquisa é limitada à conta Pagar.me V5 consultada e aos vínculos disponíveis. Pagamentos em outros e-mails sem referência individual não podem ser descartados pela ausência de resultado. Não há busca aproximada por nome.

## Identidade

O código antigo `UPD365VIP`, presente no cadastro do perfil 15398, foi reutilizado em 12 pedidos. A primeira exploração identificou a ambiguidade; a consulta final não seguiu clientes externos encontrados por esse código genérico. Somente dois pedidos individualmente identificados permaneceram no perfil. Nenhum pagamento de terceiro foi persistido ou associado ao selo a partir da referência ambígua.

O perfil 53887 tem um pedido encontrado por referência individual com e-mail do comprador diferente do cadastro; foi sinalizado para revisão, sem conciliação de direitos. Essa revisão de titularidade não substitui nem mistura os quatro casos da aba Divergências VIP.

## Business

Arquivos: `services/VerifiedAdmin.cfc`, `portal/verificados/home.cfm`, `portal/verificados/evidence.cfm`, `portal/verificados/verified.css`.

A seção Pagamentos e pedidos mostra valor em reais/centavos, produto, aprovação/recusa/estorno, datas, meio, pedido e horário da conferência. Todos os produtos dos eventos locais agora são incluídos, não apenas uma lista de seis códigos. Pedidos com vários produtos conservam os nomes dos itens. Duplicatas de eventos viram uma linha por pedido; a consulta API substitui a apresentação dos eventos locais desse pedido. A tela lê a última auditoria salva; não chama a API ao abrir e não apresenta o retrato como atualização contínua.

Resultados foram adicionados em 57 registros `crm_interno.audit`, action `verified.payment_scan`, com request_id derivado do SHA-256 do lote. Operação repetível sem duplicar o lote. Nenhuma migração, mudança de ledger financeiro, concessão, classificação administrativa, validade ou inscrição. Hash antes/depois de grants, pedidos, origens, reclassificações e flags preservado.

## Artefatos e validação

- Análise privada: `_codex/analyses/verified-pending-payments-20261124/` (consulta sanitizada, controle de titularidade, snapshots, recibo e relatório HTML).
- Testes/publicação: `_codex/staging/verified-pending-payments-20261124/`.
- Classificador: aprovação exige BRL, valor positivo, pedido pago e soma capturada compatível, sem estorno ou chargeback. Seis cenários verificados, incluindo upgrade sem inscrição, tentativa cancelada sem captura, estorno parcial, chargeback, captura divergente e sandbox.
- Testes CF somente de leitura: 315 verificações, 105 pedidos, 36 aprovados, 6 estornos e zero novos VIP TSD aprovados; direitos e filas preservados. Gates de administrador/CSRF/ação antiga e escape HTML verificados.
- Testes visuais com sessão e servidor exclusivos, desktop/celular, limpeza obrigatória.

Referência de estados do provedor: [Cobranças Pagar.me](https://docs.pagar.me/reference/cobran%C3%A7as-1). Valores recebidos na API são tratados em centavos, conforme o contrato de [cobranças](https://docs.pagar.me/reference/incluir-cobran%C3%A7a-no-pedido). Os totais e situações acima são da consulta autenticada, não da documentação pública.

Publicação de quatro arquivos concluída em 24/11/2026, com backup `/var/backups/business-verified-pending-payments-_rmfsckb`. Auditoria reaplicada sem gerar novos registros: 57 preservados, zero duplicações e hash dos direitos inalterado.

Verificação publicada: sete páginas/casos HTTP 200 com os arquivos reais, incluindo valores e estornos. Prévia, sessões de navegador e operadores temporários removidos.
