import React from "react";

import {
  ChartRenderer, DataComponent, DataTable, MetricCard, ReportSection,
  RichNarrative, useDataApp,
} from "../../data-app-public.jsx";

const brl = (value) => `R$ ${Number(value ?? 0).toLocaleString("pt-BR", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
const slug = (value) => String(value).normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");

function EvidenceChart({ id, queryId, title, rows, spec, description, height = 320 }) {
  const { chartOverrides, chartProps, visible } = useDataApp();
  if (!visible(id)) return null;
  const chart = chartOverrides[id] ?? spec;
  return <DataComponent id={id} queryId={queryId} title={title} kind="chart" chart={chart}
    sourceRows={rows} displayRows={rows} description={description} variant="card">
    <ChartRenderer spec={chart} rows={rows} height={height} {...chartProps(id)} />
  </DataComponent>;
}

function EvidenceTable({ id, queryId, title, rows, columns, description }) {
  const { visible } = useDataApp();
  if (!visible(id)) return null;
  return <DataComponent id={id} queryId={queryId} title={title} kind="table"
    sourceRows={rows} displayRows={rows} description={description} variant="card">
    <DataTable rows={rows} columns={columns} />
  </DataComponent>;
}

function ChannelDossier({ channel, rows }) {
  const channelSlug = slug(channel.channel_name);
  const select = (queryId) => rows(queryId).filter((row) => row.channel_name === channel.channel_name);
  const weekly = select("channel_weekly_sales");
  const modality = select("channel_modality_mix").map((row) => ({ ...row, base: channel.channel_name }));
  const lots = select("channel_lot_mix").map((row) => ({ ...row, base: channel.channel_name }));
  const states = select("channel_state_mix");
  const products = select("channel_product_mix");
  const profile = select("channel_profile_coverage");
  const summaryId = `mif-dossier-${channelSlug}-summary`;
  const geographyCoverage = states[0]?.coverage?.valid_coverage_pct ?? 0;

  return <section className="dossier" id={`canal-${channelSlug}`}>
    <ReportSection id={summaryId} queryId="channel_index" title={channel.channel_name}
      sourceRows={[channel]} showHeading={false}>
      <RichNarrative id={`${summaryId}:body`} label={`Editar leitura de ${channel.channel_name}`}
        value={`## ${channel.channel_name}\n\nNa fixture, o canal reúne **${channel.paid_registrations} inscrições pagas** em ${channel.touched_paid_orders} pedidos tocados — contagem não aditiva entre canais. O valor bruto alocado é ${brl(channel.gross_value)} e o ticket ponderado por inscrição é ${brl(channel.registration_ticket)}. Esta é uma descrição da base sintética, não uma avaliação comercial nem uma recomendação.`} />
    </ReportSection>
    <div className="evidence-grid">
      <EvidenceChart id={`mif-dossier-${channelSlug}-weekly`} queryId="channel_weekly_sales"
        title={`Vendas semanais — ${channel.channel_name}`} rows={weekly}
        spec={{ type: "line", x: "week_start", y: "paid_registrations", yLabel: "Inscrições pagas" }}
        description="Inscrições pagas por semana; base e período são os da fixture sintética." />
      <EvidenceChart id={`mif-dossier-${channelSlug}-modality`} queryId="channel_modality_mix"
        title={`Mix de modalidade — ${channel.channel_name}`} rows={modality}
        spec={{ type: "stackedBar", x: "base", y: "paid_registrations", series: "modality", yLabel: "Inscrições pagas" }}
        description="Composição das inscrições pagas do canal; o denominador está em cada linha revisada." />
      <EvidenceChart id={`mif-dossier-${channelSlug}-lot`} queryId="channel_lot_mix"
        title={`Mix de lote — ${channel.channel_name}`} rows={lots}
        spec={{ type: "stackedBar", x: "base", y: "paid_registrations", series: "lot", yLabel: "Inscrições pagas" }}
        description="Composição por lote dentro da base paga do canal." />
      {geographyCoverage >= 70 && <EvidenceChart id={`mif-dossier-${channelSlug}-state`} queryId="channel_state_mix"
        title={`Distribuição por UF — ${channel.channel_name}`} rows={states}
        spec={{ type: "rankedList", x: "state", y: "paid_registrations" }}
        description="A geografia aparece porque a cobertura válida da fixture é de pelo menos 70%." />}
      <EvidenceTable id={`mif-dossier-${channelSlug}-product`} queryId="channel_product_mix"
        title={`Produtos — ${channel.channel_name}`} rows={products}
        columns={[
          { key: "product_name", label: "Produto" }, { key: "classification", label: "Classificação" },
          { key: "registrations_with_product", label: "Inscrições", align: "right" },
          { key: "take_rate_pct", label: "Adoção (%)", align: "right" },
          { key: "explicit_revenue", label: "Receita explícita (R$)", align: "right" },
        ]} description="Adoção e receita somente quando o valor do produto está explícito na fixture." />
      <EvidenceTable id={`mif-dossier-${channelSlug}-profile`} queryId="channel_profile_coverage"
        title={`Cobertura de perfil — ${channel.channel_name}`} rows={profile}
        columns={[
          { key: "profile_dimension", label: "Dimensão" }, { key: "valid", label: "Válidos", align: "right" },
          { key: "missing", label: "Ausentes", align: "right" }, { key: "denominator", label: "Base", align: "right" },
          { key: "valid_coverage_pct", label: "Cobertura válida (%)", align: "right" },
        ]} description="Cobertura de perfil antes de interpretar qualquer composição." />
    </div>
  </section>;
}

export function ReportContent() {
  const { snapshot, reviewedRows, visible, canEdit, mode, appTitle, setAppTitle } = useDataApp();
  const rows = (queryId) => reviewedRows(queryId);
  const [overview = {}] = rows("event_overview");
  const channelIndex = rows("channel_index");
  const fullChannels = channelIndex.filter((row) => row.dossier_type === "full");
  const overlapSections = [
    ["geography_overlap", "Geografia", "Comparação descritiva das distribuições geográficas, com cobertura de cada canal."],
    ["modality_overlap", "Modalidade", "Semelhança do mix de modalidades; não compõe uma nota geral."],
    ["lot_overlap", "Lote", "Semelhança de composição por lote, preservada como dimensão independente."],
    ["temporal_overlap", "Tempo", "Semelhança do calendário semanal observado na fixture."],
    ["profile_overlap", "Perfil", "Comparações de perfil mantêm dimensão, base e cobertura separadas."],
    ["product_overlap", "Produtos", "Comparação de adicionais somente na cobertura efetivamente mapeada."],
  ];

  return <article className="report-content" aria-label="Estudo de vendas e canais">
    <header className="report-hero">
      <h1 data-data-app-title contentEditable={canEdit && mode === "edit"} suppressContentEditableWarning
        aria-label={canEdit && mode === "edit" ? "Editar título do relatório" : undefined}
        onBlur={canEdit && mode === "edit" ? (event) => setAppTitle(event.currentTarget.textContent.trim() || appTitle) : undefined}
        onKeyDown={canEdit && mode === "edit" ? (event) => { if (event.key === "Enter") { event.preventDefault(); event.currentTarget.blur(); } } : undefined}>
        {appTitle}
      </h1>
      <RichNarrative id="mif-report-qualification" className="report-deck" label="Editar qualificação"
        value="**Fixture sintética de desenvolvimento.** Esta versão valida o pipeline, a estrutura editorial e a rastreabilidade do Data App; não representa os resultados finais da Maratona de Floripa 2026. A Task 8 substituirá a base e os mapeamentos por uma extração fresca e completamente revisada." />
    </header>

    <ReportSection id="mif-event-overview" queryId="event_overview" title="Visão geral da fixture"
      sourceRows={[overview]} showHeading={false}>
      <RichNarrative id="mif-event-overview:body" label="Editar visão geral"
        value="## Visão geral da fixture\n\nA leitura separa **pedidos pagos únicos** de **inscrições pagas** e usa valores de pedido alocados às inscrições para os recortes por canal. Pedidos tocados não são aditivos entre canais. Os números abaixo servem apenas para provar a consistência do produto analítico." />
    </ReportSection>

    <div className="metric-grid" aria-label="Indicadores da fixture">
      {visible("mif-overview-orders") && <MetricCard id="mif-overview-orders" queryId="event_overview" title="Pedidos pagos" value={String(overview.paid_orders ?? 0)} sourceRows={[overview]} description="Pedidos pagos únicos na fixture." />}
      {visible("mif-overview-registrations") && <MetricCard id="mif-overview-registrations" queryId="event_overview" title="Inscrições pagas" value={String(overview.paid_registrations ?? 0)} sourceRows={[overview]} description="Inscrições vinculadas a pedidos pagos." />}
      {visible("mif-overview-gross") && <MetricCard id="mif-overview-gross" queryId="event_overview" title="Valor bruto" value={brl(overview.gross_value)} sourceRows={[overview]} description="Soma dos pedidos pagos; valores sintéticos." />}
      {visible("mif-overview-ticket") && <MetricCard id="mif-overview-ticket" queryId="event_overview" title="Ticket por inscrição" value={brl(overview.registration_ticket)} sourceRows={[overview]} description="Valor bruto dividido pelas inscrições pagas." />}
    </div>

    <section className="report-section">
      <RichNarrative id="mif-time-lot-modality-intro" label="Editar introdução temporal" value="## Tempo, lote e modalidade\n\nOs três recortes usam a mesma base de inscrições pagas. A série semanal mostra quando a fixture concentra registros; lote e modalidade mostram composição, sem inferir desempenho futuro ou preferência comercial." />
      <div className="evidence-grid">
        <EvidenceChart id="mif-weekly-sales" queryId="weekly_sales" title="Inscrições pagas por semana" rows={rows("weekly_sales")} spec={{ type: "line", x: "week_start", y: "paid_registrations", yLabel: "Inscrições pagas" }} description="Semanas ISO da fixture; unidade: inscrições pagas." />
        <EvidenceChart id="mif-lot-performance" queryId="lot_performance" title="Inscrições por lote" rows={rows("lot_performance")} spec={{ type: "bar", x: "lot", y: "paid_registrations", yLabel: "Inscrições pagas" }} description="Contagem e denominador do evento por lote." />
        <EvidenceChart id="mif-modality-mix" queryId="modality_mix" title="Composição por modalidade" rows={rows("modality_mix").map((row) => ({ ...row, base: "Evento" }))} spec={{ type: "stackedBar", x: "base", y: "paid_registrations", series: "modality", yLabel: "Inscrições pagas" }} description="Modalidades mutuamente exclusivas na base paga da fixture." />
      </div>
    </section>

    <section className="report-section">
      <RichNarrative id="mif-geography-intro" label="Editar leitura geográfica" value="## Geografia\n\nPaís, UF e cidade são descritos no grão de inscrição paga. Cobertura e células suprimidas devem ser consultadas antes de comparar canais; geografia observada não equivale a alcance estratégico." />
      <div className="evidence-grid">
        <EvidenceChart id="mif-country-distribution" queryId="country_distribution" title="Países observados" rows={rows("country_distribution")} spec={{ type: "rankedList", x: "country", y: "paid_registrations" }} />
        <EvidenceChart id="mif-state-distribution" queryId="state_distribution" title="Inscrições por UF" rows={rows("state_distribution")} spec={{ type: "rankedList", x: "state", y: "paid_registrations" }} />
        <EvidenceChart id="mif-city-distribution" queryId="city_distribution" title="Inscrições por cidade" rows={rows("city_distribution")} spec={{ type: "rankedList", x: "city", y: "paid_registrations" }} />
      </div>
    </section>

    <section className="report-section">
      <RichNarrative id="mif-profile-products-intro" label="Editar leitura de perfil e produtos" value="## Perfil, cobertura e produtos\n\nAs distribuições de idade, gênero, ritmo e clube dependem da cobertura válida indicada nas próprias linhas. Produtos permanecem separados entre kit incluso, adicional e identidade ainda desconhecida; receita só aparece quando explicitamente observada." />
      <div className="evidence-grid">
        <EvidenceChart id="mif-age-bands" queryId="age_bands" title="Faixas etárias" rows={rows("age_bands")} spec={{ type: "bar", x: "age_band", y: "paid_registrations" }} />
        <EvidenceChart id="mif-gender-distribution" queryId="gender_distribution" title="Distribuição de gênero" rows={rows("gender_distribution")} spec={{ type: "bar", x: "gender", y: "paid_registrations" }} />
        <EvidenceChart id="mif-pace-bands" queryId="pace_bands" title="Faixas de ritmo" rows={rows("pace_bands")} spec={{ type: "bar", x: "pace_band", y: "paid_registrations" }} />
        <EvidenceChart id="mif-club-coverage" queryId="club_coverage" title="Clube ou assessoria informado" rows={rows("club_coverage")} spec={{ type: "rankedList", x: "club", y: "paid_registrations" }} />
        <EvidenceTable id="mif-auxiliary-field-coverage" queryId="auxiliary_field_coverage" title="Cobertura dos campos auxiliares" rows={rows("auxiliary_field_coverage")} columns={[{ key: "field", label: "Campo" }, { key: "valid", label: "Válidos", align: "right" }, { key: "invalid", label: "Inválidos", align: "right" }, { key: "missing", label: "Ausentes", align: "right" }, { key: "denominator", label: "Base", align: "right" }, { key: "valid_coverage_pct", label: "Cobertura válida (%)", align: "right" }]} />
        <EvidenceTable id="mif-product-summary" queryId="product_summary" title="Resumo de produtos" rows={rows("product_summary")} columns={[{ key: "product_name", label: "Produto" }, { key: "classification", label: "Classificação" }, { key: "registrations_with_product", label: "Inscrições", align: "right" }, { key: "take_rate_pct", label: "Adoção (%)", align: "right" }, { key: "explicit_revenue", label: "Receita explícita (R$)", align: "right" }]} />
      </div>
    </section>

    <section className="report-section" id="indice-de-canais">
      <RichNarrative id="mif-channel-index-intro" label="Editar índice de canais" value="## Índice de canais\n\nO índice é alfabético. Canais com pelo menos 10 inscrições pagas recebem dossiê completo; bases menores permanecem na cauda longa com aviso de leitura indicativa. A ordem não é classificação de qualidade." />
      <EvidenceTable id="mif-channel-index" queryId="channel_index" title="Canais observados na fixture" rows={channelIndex}
        columns={[{ key: "channel_name", label: "Canal" }, { key: "channel_type", label: "Tipo revisado" }, { key: "dossier_type", label: "Tratamento" }, { key: "paid_registrations", label: "Inscrições pagas", align: "right" }, { key: "touched_paid_orders", label: "Pedidos tocados", align: "right" }, { key: "gross_value", label: "Valor bruto (R$)", align: "right" }]}
        description="Pedidos tocados não são aditivos entre canais." />
    </section>

    <section className="report-section">
      <RichNarrative id="mif-dossiers-intro" label="Editar introdução aos dossiês" value="## Dossiês completos\n\nCada dossiê preserva os mesmos grãos, denominadores e limites. As leituras são descritivas e não produzem score, ordenação comercial ou decisão automática." />
      {fullChannels.map((channel) => <ChannelDossier key={channel.channel_name} channel={channel} rows={rows} />)}
    </section>

    <section className="report-section">
      <RichNarrative id="mif-long-tail-intro" label="Editar cauda longa" value="## Cauda longa\n\nBases abaixo de 10 inscrições são exibidas de forma compacta. Percentuais e principais segmentos são indicativos; não se transformam em diagnóstico por causa do tamanho reduzido." />
      <EvidenceTable id="mif-long-tail" queryId="long_tail" title="Canais com base reduzida" rows={rows("long_tail")} columns={[{ key: "channel_name", label: "Canal" }, { key: "channel_type", label: "Tipo revisado" }, { key: "paid_registrations", label: "Inscrições", align: "right" }, { key: "registration_ticket", label: "Ticket (R$)", align: "right" }, { key: "sample_warning", label: "Qualificação" }]} />
    </section>

    <section className="report-section">
      <RichNarrative id="mif-overlaps-intro" label="Editar introdução aos overlaps" value="## Seis comparações de sobreposição\n\nAs semelhanças variam de 0 a 1 e ficam separadas por dimensão. Elas não são somadas, ponderadas ou convertidas em uma avaliação global. Sempre leia cobertura e segmentos compartilhados junto com o valor." />
      <div className="overlap-stack">
        {overlapSections.map(([queryId, label, description]) => <EvidenceTable key={queryId} id={`mif-${queryId.replaceAll("_", "-")}`} queryId={queryId} title={`Sobreposição — ${label}`} rows={rows(queryId)} description={description}
          columns={[{ key: "channel_a", label: "Canal A" }, { key: "channel_b", label: "Canal B" }, ...(queryId === "profile_overlap" ? [{ key: "profile_dimension", label: "Dimensão de perfil" }] : []), { key: "similarity_0_1", label: "Semelhança (0–1)", align: "right" }, { key: "shared_leading_segments", label: "Segmentos compartilhados" }, { key: "coverage_a", label: "Cobertura A (%)", align: "right" }, { key: "coverage_b", label: "Cobertura B (%)", align: "right" }]} />)}
      </div>
    </section>

    <section className="report-section">
      <RichNarrative id="mif-decision-questions" label="Editar perguntas de decisão" value="## Perguntas para a decisão humana\n\n- Quais canais cobrem estados ou modalidades pouco atendidos pelos demais?\n- Em quais pares a semelhança por uma dimensão merece investigação contratual conjunta?\n- Onde a concentração regional é intencional e onde limita o alcance desejado?\n- Quais diferenças de produtos persistem após considerar cobertura e denominadores?\n- Que evidência externa de patrocínio, exposição, permuta ou cortesia ainda precisa entrar na discussão?" />
    </section>

    <section className="report-section">
      <RichNarrative id="mif-methodology-limitations" label="Editar metodologia e limitações" value={`## Metodologia, limitações e reconciliação\n\nA produção filtra o evento **72611**, normaliza o status pago, constrói facts com grãos explícitos, aplica mapeamentos exatos revisados e só então calcula agregados. Células pequenas são agrupadas nos cruzamentos definidos; nenhum identificador, texto livre de questionário ou fact bruto entra no app.\n\nNesta fixture, a reconciliação declara ${overview.paid_orders ?? 0} pedidos pagos e ${overview.paid_registrations ?? 0} inscrições pagas. Patrocínio, espaço de expo, permutas e valor de cortesias não são mensurados. A Task 8 fará a extração fresca, completará mapeamentos e substituirá toda afirmação baseada na fixture.`} />
      <div className="evidence-grid">
        <EvidenceTable id="mif-data-quality" queryId="data_quality" title="Qualidade e cobertura da fixture" rows={rows("data_quality")} columns={[{ key: "grain", label: "Grão" }, { key: "field", label: "Campo" }, { key: "valid", label: "Válidos", align: "right" }, { key: "invalid", label: "Inválidos", align: "right" }, { key: "missing", label: "Ausentes", align: "right" }, { key: "denominator", label: "Base", align: "right" }, { key: "coverage_pct", label: "Cobertura (%)", align: "right" }]} />
      </div>
      <RichNarrative id="mif-source-appendix" label="Editar apêndice de fontes" value={`## Fontes\n\nAs consultas do snapshot apontam honestamente para \`public.tb_ticketsports_pedidos\` e \`public.tb_ticketsports_participantes\`, sempre com \`cod_evento = 72611\` e regra de status pago. O SQL visível é agregado; a extração em nível de linha permanece fora do HTML. Cada componente abre as linhas revisadas, definições, SQL e fluxo de evidência no painel de fonte.\n\nSnapshot: **${snapshot.status}**, preparado em **${snapshot.generatedAt}**.`} />
    </section>
  </article>;
}
