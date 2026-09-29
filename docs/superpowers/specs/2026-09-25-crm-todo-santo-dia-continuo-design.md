# Todo Santo Dia: acompanhamento contínuo no CRM

Data: 25/09/2026. Estado: desenho e execução aprovados pelo usuário; incrementos publicados e cobertura histórica em andamento.

## Resultado esperado

O operador encontra “Todo Santo Dia” em Campanhas como uma iniciativa ativa de acompanhamento, sem data final. A página mostra a evolução do produto, a composição do público e, quando comprovadas, compras de anuidades Básica/VIP, renovações e upgrades. Atividade comercial do produto não é apresentada como efeito de uma mensagem sem um clique registrado elegível. O operador pode associar campanhas de card, notificação ou e-mail à iniciativa, mas cada veiculação continua a exigir sua própria revisão e confirmação. Criar a iniciativa e abrir seus resultados não envia nada.

O primeiro teste ponta a ponta será uma inscrição e compra reais feitas pelo próprio usuário com outra conta, somente **depois** que o vínculo de pedido e a conciliação estiverem publicados e verificados. A implantação não cria pedido, captura, estorno, campanha de envio nem mensagem de teste.

## Modelo e fronteiras

RoadRunners é dono da iniciativa `todosantodia`, identidade de usuário, registro de desafio, pedidos vinculados, reconciliação e indicadores. Business consome apenas a API administrativa assinada e exibe dados agregados e listas de usuários autorizadas; não recebe credenciais nem payloads completos do Pagar.me. A iniciativa é um recurso de acompanhamento distinto de `crm_interno.campaigns`, cujo estado `active` hoje significa veiculação e cuja revisão exige canal, público e `ends_at`. A interface pode chamá-la de **Campanha contínua**, com selo “Ativa · acompanhamento”, sem criar entregas. Campanhas promocionais existentes podem ganhar um vínculo opcional com essa iniciativa; o vínculo não altera elegibilidade, revisão, limite de contato nem execução.

Há uma única iniciativa do Todo Santo Dia, identificada por código estável. Ela não tem término automático. Sua data editorial de lançamento, se confirmada, é separada das datas de cobertura de cada fonte. Uma data antiga de lançamento não retroage a coleta nem produz conversões atribuídas.

## Métricas e evidência

O painel separa estes grãos:

1. **Base cadastrada atual:** pessoas distintas com registro `public.desafios` para `todosantodia`, por estado atual do registro. É estoque observado, não uma série histórica de novos cadastros, pagamento ou vigência. `data_inscricao` pode ser regravada e não serve para reconstruir a data da primeira inscrição.
2. **Inícios de inscrição:** eventos imutáveis de `crm_interno.challenge_signup_events`, uma pessoa por desafio, apenas desde `challenge_signup_source.started_at`. A série semanal/mensal usa `occurred_at`; reenvio do formulário não a infla. Os eventos sem clique são orgânicos/não atribuídos.
3. **Pedidos históricos do produto:** somente pedidos que uma leitura autenticada no Pagar.me identificar por `items[].code` de Básica, VIP ou upgrade e cujo estado financeiro for classificável. São totais de pedidos, não de pessoas nem receita atribuída, quando a identidade antiga não puder ser comprovada. A conciliação guarda data da compra, estado, moeda e valor com origem, última verificação e deduplicação por pedido. Pedido não confirmado, estorno parcial, chargeback, cobranças múltiplas ou divergência ficam em “pendente de conciliação”, fora dos indicadores confirmados até uma regra validada cobri-los. A série histórica informa início/fim e lacunas da cobertura efetivamente auditada.
4. **Compras futuras vinculadas:** antes de criar o pedido, o checkout autenticado reserva um código opaco associado a usuário e SKU permitido; após a resposta, vincula ID/código do pedido. A conciliação por GET autenticado compara esse vínculo, `items[].code`, moeda, cobrança e estado atual do provedor. E-mail e `id_pagina` do formulário não estabelecem identidade. Básica e VIP iniciam uma anuidade em `paid_at`; uma nova compra anual da mesma pessoa vinculada conta como renovação distinta e inicia seu próprio período de um ano civil na data do novo pagamento, mesmo se a vigência anterior ainda não terminou. Para a situação atual, prevalece a compra anual confirmada mais recente cuja vigência inclua o instante consultado; se ela for estornada, outra compra anterior ainda vigente pode voltar a prevalecer. Upgrade confirmado durante uma anuidade vigente muda a modalidade para VIP até o fim daquela vigência, sem renová-la; upgrade fora de vigência aparece como pedido, mas não ativa uma anuidade. Estorno do upgrade reverte essa mudança de modalidade. Estorno/cancelamento comprovado corrige o saldo e a vigência do pedido afetado sem apagar seu histórico. Quando não houver vínculo seguro ou estado suportado, o CRM informa “não comprovado” e não atribui perfil ou receita.

Os indicadores principais distinguem registros atuais, inícios, pedidos pagos confirmados, compradores identificados, anuidades vigentes, renovações, upgrades e estornos. A série pode alternar semana/mês e Básica/VIP/upgrade. Totais de pedidos e pessoas nunca são somados entre si. Valor só aparece por moeda e por estado financeiro conciliado; não se infere lucro a partir de receita bruta nem se apresenta o split como valor recebido pela RunnerHub.

## Perfil e atribuição

O painel mostra perfil **atual** da base cadastrada e, separadamente, de compradores com vínculo seguro: estado, cidade, faixa etária e distribuição Básica/VIP quando comprovada. Ausência de idade/localidade entra em “não informado”. Esses atributos não são apresentados como retrato histórico no momento da compra. Dados derivados de treinos privados do Strava ficam fora da segmentação comercial; somente participação própria do desafio e dados de conta entram aqui.

Campanhas promocionais relacionadas mantêm seus próprios resultados de entrega e clique. Um início ou pedido futuro só é **atribuído a um contato** quando houver último clique registrado elegível da mesma conta na janela de sete dias e revisão correta; a atribuição é observacional, não prova causalidade. O resultado geral da iniciativa inclui orgânico e campanhas vinculadas sem chamar tudo de conversão de campanha. Compras e registros anteriores à instrumentação não recebem clique retroativo.

## Fluxo e falhas

O operador abre a iniciativa no CRM, escolhe período e granularidade, consulta a curva e os segmentos, e pode inspecionar usuários somente onde a fonte comprova a identidade. A página mostra um quadro de cobertura por fonte e a última conciliação. Se o provedor falhar ou devolver estado não suportado, os últimos números comprovados permanecem com carimbo de atualização e alerta de atraso; zero e indisponível são estados diferentes. A ingestão é idempotente, tem limites de lote, retentativa observável e não interfere na compra do usuário se o registro analítico falhar. Um pedido criado sem vínculo deve ficar fora das métricas pessoais e da atribuição.

A configuração de produção do checkout RoadRunners difere do arquivo local. Antes de publicar alterações no checkout ou ativar conciliação, confirmar o contrato no runtime publicado, a disponibilidade da configuração existente e uma resposta representativa do provedor, sem alterar nem expor chaves. A API v5 documenta `code` do pedido e listagem paginada; reprocessamentos podem gerar cobrança nova. O classificador atual aceita apenas uma cobrança e deve sinalizar casos fora de seu contrato, não agregá-los silenciosamente. Referências oficiais: [criar pedido](https://docs.pagar.me/reference/criar-pedido-2), [listar pedidos](https://docs.pagar.me/reference/listar-pedidos), [obter pedido](https://docs.pagar.me/reference/obter-pedido) e [mudanças em pagamentos](https://docs.pagar.me/docs/pagamentos).

## Entrega e aceite

Entregar em etapas verificáveis: (1) iniciativa contínua e painel com base atual/inícios reais e cobertura; (2) vínculo seguro de compras futuras e conciliação Básica/VIP/upgrade, incluindo reversões suportadas; (3) backfill histórico somente de pedidos comprovados pelo provedor, com cobertura explícita. A etapa 2 deve estar publicada e conferida antes de convidar o usuário a fazer compra real. Se a auditoria histórica não sustentar pessoas ou valores, a etapa 3 exibe apenas a parcela comprovada e sua lacuna.

Testes em `crm_test` cobrem unicidade, repetição, renovação, upgrade, ano bissexto, estorno, pedido sem identidade, item divergente, clique posterior/teste e falha do provedor; a UI é verificada em desktop e 390 px. Publicação aplica migrations aditivas antes dos consumidores, compara baseline, guarda backup recuperável, compila CFML no Adobe e verifica hashes e comportamento real. Sem commit, branch, push ou PR por esta solicitação.

Critério operacional final: o usuário registra uma nova conta, inicia a inscrição e conclui pagamento real por sua escolha; a conciliação mostra o pedido confirmado ou uma pendência explícita, com SKU, horário, vigência e usuário vinculados corretamente. Sem clique promocional, a compra aparece como orgânica. O teste não é executado pelo agente nem substituído por eventos fabricados.

## Regras editoriais propostas para revisão

- “Campanha ativa” significa acompanhamento no CRM, sem veicular card automaticamente. Um card poderá ser criado e revisado como campanha promocional vinculada.
- “Um ano” é o intervalo fechado em `paid_at` e aberto no mesmo horário local de São Paulo da mesma data do calendário no ano seguinte. Se a compra ocorreu em 29/02, o aniversário no ano não bissexto é 28/02, no mesmo horário local. Uma nova compra anual inicia seu próprio intervalo na data do novo pagamento; períodos sobrepostos não se somam.
- A data editorial de início do Todo Santo Dia virá do registro do desafio somente se confirmada contra a documentação do produto; sem essa evidência, a interface mostrará “lançamento não verificado”. Essa data não altera a cobertura das fontes.
