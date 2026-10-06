# Funil — arquivos para deployment Business

Enviar a pasta **`portal/funil/` inteira** (7 arquivos) e **`includes/estrutura/sidenav.cfm`**. A navegação adiciona somente o item Funil em Marketing e audiência > Audiência e relacionamento.

Depois do envio, abrir **`/portal/funil/` no domínio do Business** com uma conta administradora, fora de simulação de conta. A consulta é feita por `report.cfm` exclusivamente pelo datasource ColdFusion `runner_dba`. Não existe conexão direta ao banco nem dados fictícios no runtime.

Arquivos do escopo:

- `portal/funil/index.cfm`
- `portal/funil/home.cfm`
- `portal/funil/report.cfm`
- `portal/funil/includes/report_backend.cfm`
- `portal/funil/includes/legacy_payments.cfm` — consulta protegida incluída pelo ColdFusion; não é uma migração.
- `portal/funil/assets/funil.css`
- `portal/funil/assets/funil.js`
- `includes/estrutura/sidenav.cfm`

Antes de substituir o menu, guardar sua versão de produção e conferir se há alterações de outras frentes. Os arquivos da pasta Funil são novos; se a pasta já existir em produção, guardar sua versão também. Para reverter a integração, restaurar o menu anterior e retirar o acesso à nova rota.

## Fontes

- Cadastros: `public.tb_usuarios`, por ID e `data_criacao`.
- Participantes do Desafio: `public.desafios` e, quando disponível, `crm_interno.challenge_signup_events`. Inscrição não é pagamento nem uso comprovado de uma funcionalidade.
- Pagamentos antigos: `public.tb_transacoes`, origem `pagarme`, evento `order.paid`, valor positivo, ID de usuário armazenado e código do item do Desafio no JSON. Nunca apenas contar todas as transações pagas do usuário, pois elas podem ser de outros produtos. Deduplicar pedidos e excluir reversões encontradas. A vinculação antiga por ID armazenado é identificada na interface como legado; não se faz novo cruzamento por email.
- Pagamentos do CRM: `crm_interno.conversion_order_state` + `crm_interno.pagarme_order_audit`, confirmação nas duas fontes e identidade autenticada. O CRM prevalece sobre o legado para o mesmo pedido; auditoria não confirmada impede usar esse pedido pelo legado.
- Vigência: 12 meses desde o pagamento de `todosantodia` ou `todosantodiavip`. `todosantodiaupg` confirma compra, mas não inicia outra vigência nem renovação. Quando falta data utilizável, a vigência fica desconhecida.
- Organizadores: IDs únicos com papel `OWNER` e status de vínculo `ATIVO` em `tb_conta_usuarios`, ligados a `tb_contas`. Funcionários não aumentam a base. Um dono com várias contas é contado uma vez. O grupo também pode conter parceiros.
- Origem: evento de vínculo ao Desafio atribuído a clique de campanha nos 7 dias anteriores. Origem geral do cadastro não mapeada.

## Limites desta primeira entrega

O banco não foi consultado neste ambiente e os arquivos ainda não foram executados no ColdFusion de produção. O mapeamento foi obtido do código existente do Business e RoadRunners; a presença de tabelas e colunas será consultada pelo próprio ColdFusion após o envio. A validação real fica para depois da sua publicação, conforme solicitado.

O histórico é parcial e usa o estado atual dos registros. O filtro de data reconstrói vigências conhecidas; não garante um retrato imutável de pagamentos reembolsados depois nem de donos de conta anteriores. Origem geral, uso/teste de funcionalidades e pagamentos dos demais produtos ainda não têm fonte validada e ficam explicitamente não mapeados. Nenhuma tabela é criada ou alterada.

Não enviar `output/funnel-mvp`, `output/product-planner` nem arquivos temporários de teste. Não houve commit, push ou publicação nesta entrega.
