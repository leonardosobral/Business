# Mensuração LIVE! 2026 — auditoria e entrega

Auditoria inicial de 12/09/2026. Objetivo: medir **chegadas ao Road Runners, visitas às provas e cliques de saída para LIVE!**, sem instalar rastreamento na LIVE!. Os achados abaixo preservam o estado anterior à implementação. As alterações operacionais de Google Ads são registradas separadamente em [retomada LIVE!](/Users/Shared/Projects/RunnerHub/Business/_codex/analyses/plano-midia-2026-09-12/retomada-live-google-ads.md).

**Atualização da entrega, 12/09/2026:** a instrumentação e o relatório foram implementados, publicados e validados. Um fluxo QA real registrou 1 sessão, 2 páginas vistas e 1 saída para a prova de Tamboré, identificada como Barueri/SP. Foram cobertos quatro CTAs (incluindo edição aberta), identidade do circuito e relatório por origem/meio/campanha × prova/cidade. O novo resumo deduplica entre variantes; o detalhe de variantes continua na seção Aquisição existente. Os quatro cadastros divergentes também foram corrigidos. [Registro de publicação e limites da medição](/Users/Shared/Projects/RunnerHub/Business/_codex/docs/2026-09-12_live_measurement_publicado.md).

Uma campanha central pode gerar um relatório por prova/cidade. Não é necessário criar dez campanhas para obter essa dimensão: a página visitada e o destino da saída identificam a etapa. Separar campanhas é uma decisão de controle de orçamento, segmentação e mensagem; não substitui a medição da navegação.

## O que existia no código antes desta entrega

| Etapa | Evidência e limite |
|---|---|
| Entrada no Road Runners | O tracker identifica visitante estimado e sessão, captura origem, meio, campanha e conteúdo UTM, e registra `page_view`. A origem é a do início da sessão; outra UTM durante uma sessão ativa não a substitui. Sessão expira após 30 minutos de inatividade. [Tracker](/Users/Shared/Projects/RunnerHub/RoadRunners/assets/js/rr-audience.js:54). |
| Visita à prova | A página de evento recebe contexto assinado com `contentType=event`, `contentId=id_evento`, caminho canônico e UF da prova. Uma visita ao evento pode ser entrada direta ou continuação da navegação. [Contexto](/Users/Shared/Projects/RunnerHub/RoadRunners/services/AudienceMeasurementService.cfc:63). |
| Entrada pelo circuito | `/circuito/` cai na família `other`, sem ID próprio; o caminho registrado fica `/circuito/`, sem distinguir o circuito. O código que preserva a URL canônica não inclui essa família. [Rota](/Users/Shared/Projects/RunnerHub/RoadRunners/circuito/index.cfm:7), [mapeamento](/Users/Shared/Projects/RunnerHub/RoadRunners/services/AudienceMeasurementService.cfc:44), [canônica](/Users/Shared/Projects/RunnerHub/RoadRunners/services/AudienceMeasurementService.cfc:89). |
| Copiar cupom | A ação chama Clipboard e mostra uma mensagem, sem evento de audiência. A mensagem não espera a confirmação de sucesso da cópia. [Função](/Users/Shared/Projects/RunnerHub/RoadRunners/includes/modal/modal_cupom_link.cfm:34). |
| Sair para inscrição | O modal usa o link externo `linkInscricao`; outras superfícies usam links normais e `window.open`. Não foi encontrado emissor de saída nesses caminhos. [Modal](/Users/Shared/Projects/RunnerHub/RoadRunners/includes/modal/modal_cupom_link_conteudo.cfm:72), [CTA da página](/Users/Shared/Projects/RunnerHub/RoadRunners/evento/index.cfm:703), [barra de ações](/Users/Shared/Projects/RunnerHub/RoadRunners/evento/parts/barra_acoes.cfm:30). |
| Contrato de saída | `outbound_click` já é um tipo aceito pelo serviço e SQL. O tracker não expõe método nem implementa emissor correspondente. [Contrato](/Users/Shared/Projects/RunnerHub/RoadRunners/services/AudienceMeasurementService.cfc:5), [SQL](/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/sql/2026-09-10_audience_editorial.sql:71), [API do tracker](/Users/Shared/Projects/RunnerHub/RoadRunners/assets/js/rr-audience.js:367). |
| Relatórios Business | Aquisição agrupa UTM; conteúdo mostra visitas por `content_id`. Ainda não há relatório cruzando UTM, prova/cidade e saída, nem filtro por cidade/evento. [Aquisição](/Users/Shared/Projects/RunnerHub/Business/portal/audiencia/queries/acquisition.sql:11), [conteúdo](/Users/Shared/Projects/RunnerHub/Business/portal/audiencia/queries/content.sql:2), [filtros](/Users/Shared/Projects/RunnerHub/Business/portal/includes/audience_backend.cfm:22). |

**Cidade da prova não é geografia do visitante.** A primeira pode ser obtida pelo cadastro associado ao `id_evento`. A dimensão geográfica de audiência hoje é UF de acesso, perfil ou contexto comercial; não há cidade de acesso no contrato. Uma pessoa de outra cidade visitando Jaraguá do Sul demonstra interesse nessa prova. Campanha com várias cidades-alvo também não permite deduzir a cidade física de cada sessão.

## Proposta original que orientou a implementação

1. **Road Runners:** marcar os CTAs de inscrição LIVE! e emitir `outbound_click` no coletor existente. Cobrir o modal dinâmico de cupom, o CTA direto e a barra de ações. Preservar a abertura do destino, inclusive em nova aba, e o funcionamento quando a coleta estiver recusada ou indisponível.
2. **Identificação:** usar `contentType=event`, `contentId=id_evento` e uma chave estável que identifique a ação `live_registration`. Validar o destino permitido; não inferir inscrição de qualquer link externo. Sessão, visitante e UTM já pertencem ao envelope. A cidade vem do cadastro da prova.
3. **Circuito:** incluir identificação canônica da página de circuito para distinguir a chegada à LIVE! de outros circuitos. Preservar o contrato assinado e a separação entre a abertura do circuito e a visita posterior à prova.
4. **Business:** acrescentar relatório de origem/campanha/variante × prova/cidade com sessões, sessões qualificadas e sessões com saída. Mostrar última recepção, filtros e definição das métricas.

Os campos existentes não incluem `dest_host` ou cidade; `event_id` é representado por `contentId`. `campaign` guarda a UTM, enquanto `campaignId` representa UUID de anúncio interno e não deve receber ID Google. Para o mínimo, ação identificada e destino validado evitam armazenar URL externa completa. Se for necessário guardar domínio, posição exata do CTA ou outras dimensões próprias, isso exigirá ampliar o contrato explicitamente.

O suporte existente a `outbound_click` permite, em princípio, acrescentar a emissão e o relatório sem nova migration para esse tipo. A versão implantada precisa ser conferida antes de implementar. Cópia de cupom deve ser medida separadamente, após sucesso da operação; ela não é uma saída e pode ficar fora do primeiro lote.

Validar em desktop/mobile e com modal assíncrono: link normal, teclado, nova aba, repetição de clique, recusa/GPC, falha de rede e preservação do destino. Confirmar recebimento no Business com dados de teste identificados. O beacon pode ser perdido; clique de saída não comprova carregamento na LIVE!.

## KPIs propostos

Todos os indicadores devem usar a mesma janela e a mesma campanha/coorte. O painel atual oferece 7, 30 ou 90 dias; o gasto externo deve ser conciliado no mesmo corte de horário.

| Indicador | Definição |
|---|---|
| Chegadas ao Road Runners | Sessões distintas com abertura confirmada e UTM do piloto. Não equivale a novos usuários, cliques Google ou última interação paga. |
| Sessões com visita à prova | Sessões distintas que geraram abertura da página daquele `id_evento`. |
| Sessões com saída por prova | Contar uma vez cada par `session_id + contentId` com saída LIVE!, mesmo com cliques repetidos ou CTAs diferentes. |
| Taxa de saída da prova | Sessões que visitaram a prova e saíram ÷ sessões que visitaram essa prova. Usar o vínculo sessão/prova, não dividir eventos brutos de clique por pessoas. |
| Progressão total da campanha | Sessões distintas com ao menos uma saída LIVE! ÷ sessões de chegada ao Road Runners. Deduplicar entre provas; não somar cidades como pessoas únicas. |
| Custo por sessão com saída | Gasto Google conciliado ÷ sessões distintas com saída LIVE! definida acima. É custo por encaminhamento, não CPA de inscrição paga. |
| Custo por sessão qualificada | Gasto Google conciliado ÷ sessões qualificadas da campanha: 30 segundos ativos ou duas páginas distintas no recorte. |

Os indicadores de custo usam o total da campanha. Na Smart central, a cidade de interesse identificada pela prova visitada não estabelece a alocação do gasto Google para aquela prova. Não dividir o gasto total da campanha pelas saídas de cada cidade e chamar isso de CPA local; tampouco repartir igualmente a verba como se fosse custo observado. O relatório geográfico Google responde a outra dimensão. O recorte por prova pode mostrar visitas e taxa de saída enquanto não houver vínculo de custo confiável.

O total de saídas e o total de cópias de cupom devem permanecer separados. Na tabela de inventário existente, “Pedidos” continua significando solicitações de anúncio (`slot_request`), não inscrições. [Definições](/Users/Shared/Projects/RunnerHub/Business/portal/audiencia/queries/summary.sql:6), [pedidos de anúncios](/Users/Shared/Projects/RunnerHub/Business/portal/audiencia/queries/inventory.sql:4).

## Atribuição e dados comerciais fora do site

Usar UTMs legíveis e sem dados pessoais, URLs ou identificadores numéricos longos. O sanitizador descarta valores com sequência de 11 dígitos: por isso `smart_20864149648` é incompatível com a regra atual e `smart_retomada` é uma alternativa adequada. Preservar o filtro de privacidade; não aplicar UTM em links internos para tentar simular aquisição. [Sanitização](/Users/Shared/Projects/RunnerHub/RoadRunners/assets/js/rr-audience.js:45), [validação no servidor](/Users/Shared/Projects/RunnerHub/RoadRunners/services/AudienceMeasurementService.cfc:167).

O usuário confirmou que o Road Runners recebe **10% do valor efetivamente pago**, com preços variáveis. A conciliação comercial pode usar relatório/planilha do parceiro, sem instalar código na LIVE!, desde que existam pagamentos confirmados, identificação única, etapa, base elegível e cancelamentos/estornos. Um pedido pode conter várias inscrições; declarar a unidade usada.

`Comissão = 10% × soma dos pagamentos elegíveis confirmados`

`Retorno sobre mídia = (comissão atribuída líquida de ajustes − gasto Google) ÷ gasto Google`

O cálculo só representa a campanha quando a comissão estiver atribuída a ela de forma verificável. Totais de um cupom comum a Google, redes sociais e tráfego direto não comprovam essa origem. O valor integral da inscrição não é receita do portal; custos adicionais continuam necessários para avaliar lucro completo.

O contrato atual da audiência não guarda GCLID. **Não importar os totais do cupom como conversões Google atribuídas** sem vínculo individual suportado e validado — GCLID ou outro identificador aceito pelo método de importação escolhido. A viabilidade desse vínculo depende do relatório do parceiro e da configuração da conta. Se houver somente total por cupom, apresentar comissão do cupom separada dos encaminhamentos Google, sem afirmar ROI específico ou incremento causal.

## Limites desta auditoria

- A conclusão sobre implementação vem dos arquivos locais citados e da documentação. Não houve consulta ao banco, inspeção de eventos atuais ou confirmação de paridade completa com produção nesta auditoria.
- O Google Tag Manager/Google Tag está incluído no site, mas sua configuração remota não foi inspecionada. Pode existir medição externa automática; isso não demonstra cobertura do modal nem integração ao Business. [Tags existentes](/Users/Shared/Projects/RunnerHub/RoadRunners/includes/estrutura/seo-web-tools-head.cfm:64).
- A coleta nativa foi ativada em 08/09/2026; não recupera saídas históricas nem reconstrói o tráfego Google anterior. [Registro de ativação](/Users/Shared/Projects/RunnerHub/Business/README.md:26).
- Bloqueios, recusa, GPC, falha de armazenamento e perda de beacon limitam a cobertura. Sem instrumentação no destino, mede-se a ação de sair do Road Runners; inscrição paga depende da confirmação do parceiro.

Foi criado somente este parecer documental. Não houve alteração de código, interface de produto, banco ou produção por esta auditoria; as etapas de implementação acima permanecem propostas.
