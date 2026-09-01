const brl = (value) => `R$ ${Number(value ?? 0).toLocaleString("pt-BR", {
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
})}`;

export function reportCopy(status, overview = {}) {
  if (!new Set(["fixture", "ready"]).has(status)) {
    throw new Error(`Unsupported report status: ${status}`);
  }

  if (status === "fixture") {
    return {
      qualification: "**Fixture sintética de desenvolvimento.** Esta versão valida o pipeline, a estrutura editorial e a rastreabilidade do Data App; não representa os resultados finais da Maratona de Floripa 2026. A Task 8 substituirá a base e os mapeamentos por uma extração fresca e completamente revisada.",
      eventOverviewTitle: "Visão geral da fixture",
      eventOverviewBody: "## Visão geral da fixture\n\nA leitura separa **pedidos pagos únicos** de **inscrições pagas** e usa valores de pedido alocados às inscrições para os recortes por canal. Pedidos tocados não são aditivos entre canais. Os números abaixo servem apenas para provar a consistência do produto analítico.",
      metricsAria: "Indicadores da fixture",
      ordersDescription: "Pedidos pagos únicos na fixture.",
      registrationsDescription: "Inscrições vinculadas a pedidos pagos.",
      grossDescription: "Soma dos pedidos pagos; valores sintéticos.",
      ticketDescription: "Valor bruto dividido pelas inscrições pagas.",
      timeIntro: "## Tempo, lote e modalidade\n\nOs três recortes usam a mesma base de inscrições pagas. A série semanal mostra quando a fixture concentra registros; lote e modalidade mostram composição, sem inferir desempenho futuro ou preferência comercial.",
      temporalOverlapDescription: "Semelhança do calendário semanal observado na fixture.",
      channelIndexTitle: "Canais observados na fixture",
      productDescription: "Adoção e receita somente quando o valor do produto está explícito na fixture.",
      methodology: `## Metodologia, limitações e reconciliação\n\nA produção filtra o evento **72611**, normaliza o status pago, constrói facts com grãos explícitos, aplica mapeamentos exatos revisados e só então calcula agregados. Células pequenas são agrupadas nos cruzamentos definidos; nenhum identificador, texto livre de questionário ou fact bruto entra no app.\n\nNesta fixture, a reconciliação declara ${overview.paid_orders ?? 0} pedidos pagos e ${overview.paid_registrations ?? 0} inscrições pagas. Patrocínio, espaço de expo, permutas e valor de cortesias não são mensurados. A Task 8 fará a extração fresca, completará mapeamentos e substituirá toda afirmação baseada na fixture.`,
      dataQualityTitle: "Qualidade e cobertura da fixture",
      channelSummary: (channel) => `## ${channel.channel_name}\n\nNa fixture, o canal reúne **${channel.paid_registrations} inscrições pagas** em ${channel.touched_paid_orders} pedidos tocados — contagem não aditiva entre canais. O valor bruto alocado é ${brl(channel.gross_value)} e o ticket ponderado por inscrição é ${brl(channel.registration_ticket)}. Esta é uma descrição da base sintética, não uma avaliação comercial nem uma recomendação.`,
    };
  }

  return {
    qualification: "**Snapshot final com fontes frescas.** O estudo consolida as inscrições encerradas do evento 72611, aplica mapeamentos completos revisados e apresenta evidências descritivas, sem avaliação automática de canais.",
    eventOverviewTitle: "Visão geral do evento",
    eventOverviewBody: "## Visão geral do evento\n\nA leitura separa **pedidos pagos únicos** de **inscrições pagas**. Valores de pedido são alocados às inscrições para os recortes por canal, lote e modalidade; pedidos tocados são não aditivos entre canais. Tickets são calculados diretamente a partir dos totais no grão correto.",
    metricsAria: "Indicadores finais do evento",
    ordersDescription: "Pedidos pagos únicos no evento encerrado.",
    registrationsDescription: "Inscrições vinculadas a pedidos pagos.",
    grossDescription: "Soma do valor bruto dos pedidos pagos únicos.",
    ticketDescription: "Valor bruto dos pedidos pagos dividido pelas inscrições pagas.",
    timeIntro: "## Tempo, lote e modalidade\n\nOs três recortes usam a mesma base de inscrições pagas. Como a fonte de participantes não informa a data de venda, a série semanal usa a data do pedido vinculado; lote e modalidade mostram composição, sem inferir desempenho futuro ou preferência comercial.",
    temporalOverlapDescription: "Semelhança do calendário semanal observado nas fontes finais.",
    channelIndexTitle: "Canais observados",
    productDescription: "Adoção por inscrição paga; receita somente quando o valor do produto está explícito na fonte.",
    methodology: `## Metodologia, limitações e reconciliação\n\nA produção filtra o evento **72611**, normaliza o status pago, constrói fatos nos grãos de pedido e inscrição, aplica mapeamentos exatos revisados e só então calcula os agregados. A reconciliação declara **${overview.paid_orders ?? 0} pedidos pagos únicos** e **${overview.paid_registrations ?? 0} inscrições pagas**. Cobertura válida, ausências e valores inválidos permanecem visíveis antes de cada interpretação; células pequenas são agrupadas nos cruzamentos definidos. Nenhum identificador, texto livre de questionário ou fato bruto entra no app.\n\nPatrocínio, espaço de expo, permutas e valor de cortesias não são mensurados neste estudo e não são descontados nem atribuídos aos canais.`,
    dataQualityTitle: "Qualidade e cobertura das fontes finais",
    channelSummary: (channel) => `## ${channel.channel_name}\n\nO canal reúne **${channel.paid_registrations} inscrições pagas** em ${channel.touched_paid_orders} pedidos tocados — contagem não aditiva entre canais. O valor bruto alocado é ${brl(channel.gross_value)} e o ticket ponderado por inscrição é ${brl(channel.registration_ticket)}. A leitura é descritiva e deve ser combinada com cobertura, composição e limitações; não constitui avaliação comercial nem recomendação.`,
  };
}
