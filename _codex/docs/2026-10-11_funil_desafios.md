# Funil dos desafios — definição das etapas

Na visão `Usuários / atletas` e `Desafio Todo Santo Dia`, o funil usa pessoas únicas até a data final selecionada:

- **Já pagaram:** ao menos uma compra anual confirmada do Desafio 365 (`desafio365`, `desafio365vip`, `inscricao365` ou `inscricao365vip`) ou do Todo Santo Dia (`todosantodia` ou `todosantodiavip`). Upgrade isolado não conta como anuidade.
- **Pagantes Todo Santo Dia:** ao menos uma compra confirmada de `todosantodia` ou `todosantodiavip`, mesmo quando a data do pagamento não permite determinar a vigência.
- **Pagaram 365 e Todo Santo Dia:** interseção das duas compras. A etapa inclui quem já teve a anuidade encerrada e não presume a ordem das compras quando faltam datas.

O indicador **Vigência comprovada na data final** é separado: exige data de pagamento utilizável e aplica 12 meses à compra anual do Todo Santo Dia. O filtro de vigência encerrada exige também que não exista compra anual do Todo Santo Dia sem data, porque essa compra pode ter iniciado novo prazo. Os indicadores do período dependem de datas utilizáveis e podem ser menores que as etapas acumuladas.

As fontes seguem os controles do relatório: pedido Pagar.me confirmado no CRM com auditoria e vínculo autenticado, `order.paid` legado associado ao `id_usuario`, ou evento histórico `order.paid` em `tb_webhook` com valor positivo e código do pedido igual ao da inscrição 365. Pedidos são deduplicados e reversões conhecidas são excluídas. Inscrição, status do cadastro e acesso não provam pagamento. O histórico legado vinculado por usuário ou pedido não oferece a mesma garantia de identidade do checkout autenticado. O funil não calcula receita nem atribui vendas a campanhas.

Verificação autenticada da visão solicitada em 11/10/2026: base de 56.732 usuários, 3.003 com vínculo, 2.513 compradores de um dos desafios, 715 compradores do Todo Santo Dia e 273 compradores de ambos. A lista da última etapa retornou 273 pessoas em 11 páginas. O histórico de pagamentos continua parcial. A consulta foi consolidada em uma execução por carregamento para evitar três leituras dos mesmos webhooks; o layout foi conferido em desktop e a 390 px, sem rolagem horizontal da página.
