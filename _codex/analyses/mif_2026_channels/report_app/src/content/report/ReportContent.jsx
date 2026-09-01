import React from "react";

import {
  ChartRenderer, DataComponent, DataTable, MetricCard, ReportSection,
  RichNarrative, useDataApp,
} from "../../data-app-public.jsx";
import {
  OPERATIONAL_CONFIGS, RANKING_CONFIGS, chartRankingDescription,
  prepareChartRows, prepareOperationalChartRows,
} from "./report-chart-rows.js";
import { CHART_SPECS, evidenceDescription } from "./report-contract.js";
import { reportCopy } from "./report-copy.js";

const brl = (value) => `R$ ${Number(value ?? 0).toLocaleString("pt-BR", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
const slug = (value) => String(value).normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");

function EvidenceChart({ id, queryId, title, rows, spec, description, ranking, operational, height = 320 }) {
  const { chartOverrides, chartProps, visible } = useDataApp();
  if (!visible(id)) return null;
  const chart = chartOverrides[id] ?? spec;
  const chartRows = ranking
    ? prepareChartRows(rows, ranking)
    : operational ? prepareOperationalChartRows(rows, operational) : rows;
  const chartDescription = ranking
    ? chartRankingDescription(description, rows, chartRows, ranking)
    : description;
  return <DataComponent id={id} queryId={queryId} title={title} kind="chart" chart={chart}
    sourceRows={rows} displayRows={chartRows} description={chartDescription} variant="card">
    <ChartRenderer spec={chart} rows={chartRows} height={height} {...chartProps(id)} />
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

function ChannelDossier({ channel, rows, reportPeriod, copy }) {
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
  const describe = (sourceRows, options) => evidenceDescription(sourceRows, {
    periodStart: reportPeriod.start, periodEnd: reportPeriod.end,
    denominator: channel.paid_registrations, ...options,
  });

  return <section className="dossier" id={`canal-${channelSlug}`}>
    <ReportSection id={summaryId} queryId="channel_index" title={channel.channel_name}
      sourceRows={[channel]} showHeading={false}>
      <RichNarrative id={`${summaryId}:body`} label={`Editar leitura de ${channel.channel_name}`}
        value={copy.channelSummary(channel)} />
    </ReportSection>
    <div className="evidence-grid">
      <EvidenceChart id={`mif-dossier-${channelSlug}-weekly`} queryId="channel_weekly_sales"
        title={`Vendas semanais — ${channel.channel_name}`} rows={weekly}
        spec={CHART_SPECS.weekly_sales}
        description={describe(weekly, { periodField: "week_start", unit: "inscrições pagas por semana" })} />
      <EvidenceChart id={`mif-dossier-${channelSlug}-modality`} queryId="channel_modality_mix"
        title={`Mix de modalidade — ${channel.channel_name}`} rows={modality}
        spec={{ type: "stackedBar", x: "base", y: "paid_registrations", series: "modality", yLabel: "Inscrições pagas" }}
        operational={OPERATIONAL_CONFIGS.modality}
        description={describe(modality, { unit: "inscrições pagas por modalidade" })} />
      <EvidenceChart id={`mif-dossier-${channelSlug}-lot`} queryId="channel_lot_mix"
        title={`Mix de lote — ${channel.channel_name}`} rows={lots}
        spec={{ type: "stackedBar", x: "base", y: "paid_registrations", series: "lot", yLabel: "Inscrições pagas" }}
        operational={OPERATIONAL_CONFIGS.lot}
        description={describe(lots, { unit: "inscrições pagas por lote" })} />
      {geographyCoverage >= 70 && <EvidenceChart id={`mif-dossier-${channelSlug}-state`} queryId="channel_state_mix"
        title={`Distribuição por UF — ${channel.channel_name}`} rows={states}
        spec={CHART_SPECS.state_distribution}
        ranking={RANKING_CONFIGS.channelState}
        description={describe(states, { unit: "inscrições pagas por UF" })} />}
      <EvidenceTable id={`mif-dossier-${channelSlug}-product`} queryId="channel_product_mix"
        title={`Produtos — ${channel.channel_name}`} rows={products}
        columns={[
          { key: "product_name", label: "Produto" }, { key: "classification", label: "Classificação" },
          { key: "registrations_with_product", label: "Inscrições", align: "right" },
          { key: "take_rate_pct", label: "Adoção (%)", align: "right" },
          { key: "explicit_revenue", label: "Receita explícita (R$)", align: "right" },
        ]} description={copy.productDescription} />
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
  const copy = reportCopy(snapshot.status, overview);
  const channelIndex = rows("channel_index");
  const fullChannels = channelIndex.filter((row) => row.dossier_type === "full");
  const weeklyRows = rows("weekly_sales");
  const weeks = weeklyRows.map((row) => row.week_start).filter(Boolean).sort();
  const reportPeriod = { start: weeks[0] ?? snapshot.generatedAt, end: weeks.at(-1) ?? snapshot.generatedAt };
  const eventDenominator = Number(overview.paid_registrations ?? 0);
  const describe = (sourceRows, options) => evidenceDescription(sourceRows, {
    periodStart: reportPeriod.start, periodEnd: reportPeriod.end,
    denominator: eventDenominator, ...options,
  });
  const overlapSections = [
    ["geography_overlap", "Geografia", "Comparação descritiva das distribuições geográficas, com cobertura de cada canal."],
    ["modality_overlap", "Modalidade", "Semelhança do mix de modalidades; não compõe uma nota geral."],
    ["lot_overlap", "Lote", "Semelhança de composição por lote, preservada como dimensão independente."],
    ["temporal_overlap", "Tempo", copy.temporalOverlapDescription],
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
        value={copy.qualification} />
    </header>

    <ReportSection id="mif-event-overview" queryId="event_overview" title={copy.eventOverviewTitle}
      sourceRows={[overview]} showHeading={false}>
      <RichNarrative id="mif-event-overview:body" label="Editar visão geral"
        value={copy.eventOverviewBody} />
    </ReportSection>

    <div className="metric-grid" aria-label={copy.metricsAria}>
      {visible("mif-overview-orders") && <MetricCard id="mif-overview-orders" queryId="event_overview" title="Pedidos pagos" value={String(overview.paid_orders ?? 0)} sourceRows={[overview]} description={copy.ordersDescription} />}
      {visible("mif-overview-registrations") && <MetricCard id="mif-overview-registrations" queryId="event_overview" title="Inscrições pagas" value={String(overview.paid_registrations ?? 0)} sourceRows={[overview]} description={copy.registrationsDescription} />}
      {visible("mif-overview-gross") && <MetricCard id="mif-overview-gross" queryId="event_overview" title="Valor bruto" value={brl(overview.gross_value)} sourceRows={[overview]} description={copy.grossDescription} />}
      {visible("mif-overview-ticket") && <MetricCard id="mif-overview-ticket" queryId="event_overview" title="Ticket por inscrição" value={brl(overview.registration_ticket)} sourceRows={[overview]} description={copy.ticketDescription} />}
    </div>

    <section className="report-section">
      <RichNarrative id="mif-time-lot-modality-intro" label="Editar introdução temporal" value={copy.timeIntro} />
      <div className="evidence-grid">
        <EvidenceChart id="mif-weekly-sales" queryId="weekly_sales" title="Inscrições pagas por semana" rows={weeklyRows} spec={CHART_SPECS.weekly_sales} description={describe(weeklyRows, { periodField: "week_start", unit: "inscrições pagas por semana" })} />
        <EvidenceChart id="mif-lot-performance" queryId="lot_performance" title="Inscrições por lote" rows={rows("lot_performance").map((row) => ({ ...row, base: "Evento" }))} spec={CHART_SPECS.lot_performance} operational={OPERATIONAL_CONFIGS.lot} description={describe(rows("lot_performance"), { unit: "inscrições pagas por lote" })} />
        <EvidenceChart id="mif-modality-mix" queryId="modality_mix" title="Composição por modalidade" rows={rows("modality_mix").map((row) => ({ ...row, base: "Evento" }))} spec={CHART_SPECS.modality_mix} operational={OPERATIONAL_CONFIGS.modality} description={describe(rows("modality_mix"), { unit: "inscrições pagas por modalidade" })} />
      </div>
    </section>

    <section className="report-section">
      <RichNarrative id="mif-geography-intro" label="Editar leitura geográfica" value="## Geografia\n\nPaís, UF e cidade são descritos no grão de inscrição paga. Cobertura e células suprimidas devem ser consultadas antes de comparar canais; geografia observada não equivale a alcance estratégico." />
      <div className="evidence-grid">
        <EvidenceChart id="mif-country-distribution" queryId="country_distribution" title="Países observados" rows={rows("country_distribution")} spec={CHART_SPECS.country_distribution} ranking={RANKING_CONFIGS.country} description={describe(rows("country_distribution"), { unit: "inscrições pagas por país" })} />
        <EvidenceChart id="mif-state-distribution" queryId="state_distribution" title="Inscrições por UF" rows={rows("state_distribution")} spec={CHART_SPECS.state_distribution} ranking={RANKING_CONFIGS.state} description={describe(rows("state_distribution"), { unit: "inscrições pagas por UF" })} />
        <EvidenceChart id="mif-city-distribution" queryId="city_distribution" title="Inscrições por cidade" rows={rows("city_distribution")} spec={CHART_SPECS.city_distribution} ranking={RANKING_CONFIGS.city} description={describe(rows("city_distribution"), { unit: "inscrições pagas por cidade" })} />
      </div>
    </section>

    <section className="report-section">
      <RichNarrative id="mif-profile-products-intro" label="Editar leitura de perfil e produtos" value="## Perfil, cobertura e produtos\n\nAs distribuições de idade, gênero, ritmo e clube dependem da cobertura válida indicada nas próprias linhas. Produtos permanecem separados entre kit incluso, adicional e identidade ainda desconhecida; receita só aparece quando explicitamente observada." />
      <div className="evidence-grid">
        <EvidenceChart id="mif-age-bands" queryId="age_bands" title="Faixas etárias" rows={rows("age_bands")} spec={{ type: "bar", x: "age_band", y: "paid_registrations" }} description={describe(rows("age_bands"), { unit: "inscrições pagas por faixa etária" })} />
        <EvidenceChart id="mif-gender-distribution" queryId="gender_distribution" title="Distribuição de gênero" rows={rows("gender_distribution")} spec={{ type: "bar", x: "gender", y: "paid_registrations" }} description={describe(rows("gender_distribution"), { unit: "inscrições pagas por gênero" })} />
        <EvidenceChart id="mif-pace-bands" queryId="pace_bands" title="Faixas de ritmo" rows={rows("pace_bands")} spec={{ type: "bar", x: "pace_band", y: "paid_registrations" }} description={describe(rows("pace_bands"), { unit: "inscrições pagas por faixa de ritmo" })} />
        <EvidenceChart id="mif-club-coverage" queryId="club_coverage" title="Clube ou assessoria informado" rows={rows("club_coverage")} spec={{ type: "horizontalBar", x: "club", y: "paid_registrations", preserveBarChart: true }} description={describe(rows("club_coverage"), { unit: "inscrições pagas por situação de clube" })} />
        <EvidenceTable id="mif-auxiliary-field-coverage" queryId="auxiliary_field_coverage" title="Cobertura dos campos auxiliares" rows={rows("auxiliary_field_coverage")} columns={[{ key: "field", label: "Campo" }, { key: "valid", label: "Válidos", align: "right" }, { key: "invalid", label: "Inválidos", align: "right" }, { key: "missing", label: "Ausentes", align: "right" }, { key: "denominator", label: "Base", align: "right" }, { key: "valid_coverage_pct", label: "Cobertura válida (%)", align: "right" }]} />
        <EvidenceChart id="mif-product-summary-chart" queryId="product_summary" title="Adoção de produtos" rows={rows("product_summary")} spec={CHART_SPECS.product_summary} ranking={RANKING_CONFIGS.product} description={describe(rows("product_summary"), { unit: "inscrições pagas com produto", denominator: rows("product_summary")[0]?.take_rate_denominator ?? eventDenominator })} />
        <EvidenceTable id="mif-product-summary" queryId="product_summary" title="Resumo de produtos" rows={rows("product_summary")} columns={[{ key: "product_name", label: "Produto" }, { key: "classification", label: "Classificação" }, { key: "registrations_with_product", label: "Inscrições", align: "right" }, { key: "take_rate_pct", label: "Adoção (%)", align: "right" }, { key: "explicit_revenue", label: "Receita explícita (R$)", align: "right" }]} />
        <EvidenceTable id="mif-payment-mix" queryId="payment_mix" title="Meios de pagamento" rows={rows("payment_mix")} columns={[{ key: "payment_method", label: "Meio" }, { key: "paid_orders", label: "Pedidos pagos", align: "right" }, { key: "share_pct", label: "Participação (%)", align: "right" }]} description="Pedidos pagos únicos, com base explícita em cada linha." />
        <EvidenceTable id="mif-device-mix" queryId="device_mix" title="Dispositivos" rows={rows("device_mix")} columns={[{ key: "device_type", label: "Dispositivo" }, { key: "paid_orders", label: "Pedidos pagos", align: "right" }, { key: "share_pct", label: "Participação (%)", align: "right" }]} description="Pedidos pagos únicos, com base explícita em cada linha." />
      </div>
    </section>

    <section className="report-section" id="indice-de-canais">
      <RichNarrative id="mif-channel-index-intro" label="Editar índice de canais" value="## Índice de canais\n\nO índice é alfabético. Canais com pelo menos 10 inscrições pagas recebem dossiê completo; bases menores permanecem na cauda longa com aviso de leitura indicativa. A ordem não é classificação de qualidade." />
      <EvidenceTable id="mif-channel-index" queryId="channel_index" title={copy.channelIndexTitle} rows={channelIndex}
        columns={[{ key: "channel_name", label: "Canal" }, { key: "channel_type", label: "Tipo revisado" }, { key: "dossier_type", label: "Tratamento" }, { key: "paid_registrations", label: "Inscrições pagas", align: "right" }, { key: "touched_paid_orders", label: "Pedidos tocados", align: "right" }, { key: "gross_value", label: "Valor bruto (R$)", align: "right" }]}
        description="Pedidos tocados não são aditivos entre canais." />
      <EvidenceTable id="mif-channel-aliases" queryId="channel_aliases" title="Identidades de origem revisadas" rows={rows("channel_aliases")} columns={[{ key: "channel_name", label: "Canal canônico" }, { key: "coupon_title", label: "Título observado" }, { key: "coupon_code", label: "Código observado" }, { key: "paid_registrations", label: "Inscrições pagas", align: "right" }]} description="Aliases revisados e contagens agregadas; nenhuma identidade de participante é exibida." />
    </section>

    <section className="report-section">
      <RichNarrative id="mif-dossiers-intro" label="Editar introdução aos dossiês" value="## Dossiês completos\n\nCada dossiê preserva os mesmos grãos, denominadores e limites. As leituras são descritivas e não produzem avaliação consolidada, ordenação comercial ou decisão automática." />
      {fullChannels.map((channel) => <ChannelDossier key={channel.channel_name} channel={channel} rows={rows} reportPeriod={reportPeriod} copy={copy} />)}
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
      <RichNarrative id="mif-methodology-limitations" label="Editar metodologia e limitações" value={copy.methodology} />
      <div className="evidence-grid">
        <EvidenceTable id="mif-data-quality" queryId="data_quality" title={copy.dataQualityTitle} rows={rows("data_quality")} columns={[{ key: "grain", label: "Grão" }, { key: "field", label: "Campo" }, { key: "valid", label: "Válidos", align: "right" }, { key: "invalid", label: "Inválidos", align: "right" }, { key: "missing", label: "Ausentes", align: "right" }, { key: "denominator", label: "Base", align: "right" }, { key: "coverage_pct", label: "Cobertura (%)", align: "right" }]} />
      </div>
      <RichNarrative id="mif-source-appendix" label="Editar apêndice de fontes" value={`## Fontes\n\nAs consultas do snapshot apontam honestamente para \`public.tb_ticketsports_pedidos\` e \`public.tb_ticketsports_participantes\`, sempre com \`cod_evento = 72611\` e regra de status pago. O SQL visível é agregado; a extração em nível de linha permanece fora do HTML. Cada componente abre as linhas revisadas, definições, SQL e fluxo de evidência no painel de fonte.\n\nSnapshot: **${snapshot.status}**, preparado em **${snapshot.generatedAt}**.`} />
    </section>
  </article>;
}
