import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

import {
  OPERATIONAL_ORDERS,
  RANKING_CONFIGS,
  chartRankingDescription,
  prepareChartRows,
  prepareOperationalChartRows,
} from "../src/content/report/report-chart-rows.js";

const descending = (rows, field) => rows.every((row, index) =>
  index === 0 || rows[index - 1][field] >= row[field]);

test("geography rankings are deterministic Top 10 plus one honest Outros bucket", () => {
  const labels = ["A", "B", "D", "C", "E", "F", "G", "H", "I", "J", "K"];
  const values = [100, 90, 80, 80, 70, 60, 50, 40, 30, 20, 10];
  const source = labels.map((country, index) => ({
    country,
    paid_registrations: values[index],
    denominator: 1_000,
    share_pct: values[index] / 10,
  }));
  source.push({ country: "Outros", paid_registrations: 5, denominator: 1_000, share_pct: 0.5 });
  const before = structuredClone(source);

  const chartRows = prepareChartRows(source, RANKING_CONFIGS.country);

  assert.deepEqual(source, before, "chart preparation must not mutate reviewed rows");
  assert.equal(chartRows.length, 11);
  assert.equal(chartRows.filter((row) => row.country === "Outros").length, 1);
  assert.ok(descending(chartRows, "paid_registrations"));
  assert.ok(chartRows.findIndex((row) => row.country === "C")
    < chartRows.findIndex((row) => row.country === "D"), "ties use a deterministic pt-BR label order");
  const other = chartRows.find((row) => row.country === "Outros");
  assert.deepEqual(other, {
    country: "Outros",
    paid_registrations: 15,
    denominator: 1_000,
    share_pct: 1.5,
  });
  assert.equal(chartRows.reduce((total, row) => total + row.paid_registrations, 0),
    source.reduce((total, row) => total + row.paid_registrations, 0));
});

test("rankings with at most ten categories are sorted without inventing Outros", () => {
  const source = [
    { state: "PR", paid_registrations: 4, denominator: 10, share_pct: 40 },
    { state: "SC", paid_registrations: 6, denominator: 10, share_pct: 60 },
  ];

  const chartRows = prepareChartRows(source, RANKING_CONFIGS.state);

  assert.deepEqual(chartRows.map((row) => row.state), ["SC", "PR"]);
  assert.equal(chartRows.some((row) => row.state === "Outros"), false);
});

test("lot and modality charts follow explicit operational orders without grouping", () => {
  const lots = ["5", "3", "7", "2", "4", "1", "6", "OUTRO: 0"]
    .map((lot) => ({ lot, paid_registrations: 1 }));
  const modalities = ["21K", "42K", "5K", "DESAFIO", "KIDS"]
    .map((modality) => ({ modality, paid_registrations: 1 }));

  assert.deepEqual(
    prepareOperationalChartRows(lots, { field: "lot", order: OPERATIONAL_ORDERS.lot }).map((row) => row.lot),
    ["1", "2", "3", "4", "5", "6", "7", "OUTRO: 0"],
  );
  assert.deepEqual(
    prepareOperationalChartRows(modalities, { field: "modality", order: OPERATIONAL_ORDERS.modality })
      .map((row) => row.modality),
    ["5K", "21K", "42K", "DESAFIO", "KIDS"],
  );
  assert.equal(prepareOperationalChartRows(lots, { field: "lot", order: OPERATIONAL_ORDERS.lot }).length,
    lots.length, "operational order must not aggregate or truncate categories");
});

test("product Outros sums quantities but fails closed on partial explicit revenue", () => {
  const source = Array.from({ length: 12 }, (_, index) => ({
    product_name: `Produto ${String(index + 1).padStart(2, "0")}`,
    classification: index === 10 ? "kit_incluso" : "adicional",
    registrations_with_product: 120 - index * 5,
    product_quantity: 130 - index * 5,
    take_rate_denominator: 1_000,
    take_rate_pct: (120 - index * 5) / 10,
    explicit_revenue: index === 10 ? 100 : null,
    explicit_revenue_coverage_pct: index === 10 ? 100 : 0,
  }));

  const chartRows = prepareChartRows(source, RANKING_CONFIGS.product);
  const tail = source.slice(10);
  const other = chartRows.find((row) => row.product_name === "Outros");

  assert.equal(chartRows.length, 11);
  assert.equal(other.registrations_with_product,
    tail.reduce((total, row) => total + row.registrations_with_product, 0));
  assert.equal(other.product_quantity,
    tail.reduce((total, row) => total + row.product_quantity, 0));
  assert.equal(other.take_rate_denominator, 1_000);
  assert.equal(other.take_rate_pct, other.registrations_with_product / 10);
  assert.equal(other.classification, "misto");
  assert.equal(other.explicit_revenue, null);
  assert.equal(other.explicit_revenue_coverage_pct, null);
  assert.ok(descending(chartRows, "registrations_with_product"));
});

test("channel-state Outros preserves coverage and recomputes both shares and delta", () => {
  const coverage = {
    answered: 90, valid: 90, invalid: 0, missing: 10,
    denominator: 100, coverage_pct: 90, valid_coverage_pct: 90,
  };
  const source = Array.from({ length: 12 }, (_, index) => ({
    channel_name: "Canal teste",
    state: `UF ${String(index + 1).padStart(2, "0")}`,
    paid_registrations: 24 - index,
    channel_count: 24 - index,
    channel_denominator: 100,
    denominator: 100,
    event_count: 120 - index,
    event_denominator: 1_000,
    share_pct: 24 - index,
    delta_pp: 12 - index * 0.9,
    coverage,
  }));

  const chartRows = prepareChartRows(source, RANKING_CONFIGS.channelState);
  const other = chartRows.find((row) => row.state === "Outros");
  const tail = source.slice(10);

  assert.equal(other.paid_registrations,
    tail.reduce((total, row) => total + row.paid_registrations, 0));
  assert.equal(other.channel_count,
    tail.reduce((total, row) => total + row.channel_count, 0));
  assert.equal(other.event_count, tail.reduce((total, row) => total + row.event_count, 0));
  assert.equal(other.share_pct, Number((other.paid_registrations / 100 * 100).toFixed(2)));
  assert.equal(other.delta_pp, Number((other.share_pct - other.event_count / 1_000 * 100).toFixed(2)));
  assert.deepEqual(other.coverage, coverage);
});

test("ranking descriptions disclose Top 10 + Outros and full paginated evidence", () => {
  const source = Array.from({ length: 12 }, (_, index) => ({
    city: `Cidade ${index}`,
    paid_registrations: 12 - index,
    denominator: 100,
    share_pct: 12 - index,
  }));
  const chartRows = prepareChartRows(source, RANKING_CONFIGS.city);

  assert.match(chartRankingDescription("Descrição-base.", source, chartRows, RANKING_CONFIGS.city),
    /Top 10 \+ Outros/u);
  assert.match(chartRankingDescription("Descrição-base.", source, chartRows, RANKING_CONFIGS.city),
    /12 categorias.*tabela paginada da fonte/u);
  assert.equal(chartRankingDescription("Descrição-base.", source.slice(0, 10), source.slice(0, 10), RANKING_CONFIGS.city),
    "Descrição-base.");
});

test("ReportContent applies ranking preparation only to categorical ranking charts", async () => {
  const report = await readFile(new URL("../src/content/report/ReportContent.jsx", import.meta.url), "utf8");

  for (const ranking of ["country", "state", "city", "product", "channelState"]) {
    assert.match(report, new RegExp(`ranking=\\{RANKING_CONFIGS\\.${ranking}\\}`, "u"));
  }
  assert.match(report, /prepareOperationalChartRows\(rows, operational\)/u);
  assert.equal((report.match(/operational=\{OPERATIONAL_CONFIGS\.lot\}/gu) ?? []).length, 2);
  assert.equal((report.match(/operational=\{OPERATIONAL_CONFIGS\.modality\}/gu) ?? []).length, 2);
  for (const id of ["mif-weekly-sales", "mif-lot-performance", "mif-modality-mix", "mif-age-bands", "mif-gender-distribution", "mif-pace-bands", "mif-club-coverage"]) {
    const openingTag = report.match(new RegExp(`<EvidenceChart id="${id}"[\\s\\S]*?/>`, "u"))?.[0] ?? "";
    assert.doesNotMatch(openingTag, /ranking=/u, `${id} must preserve temporal or semantic order`);
  }
  assert.match(report, /sourceRows=\{rows\} displayRows=\{chartRows\}/u,
    "source evidence stays complete while only chart rows are grouped");
  assert.match(report, /<DataTable rows=\{rows\}/u,
    "paginated tables must continue to receive the complete reviewed rows");
});

test("the ready snapshot reconciles every authored chart-only transformation", async () => {
  const snapshot = JSON.parse(await readFile(new URL("../src/data.json", import.meta.url), "utf8"));
  const checks = [
    ["country_distribution", RANKING_CONFIGS.country],
    ["state_distribution", RANKING_CONFIGS.state],
    ["city_distribution", RANKING_CONFIGS.city],
    ["product_summary", RANKING_CONFIGS.product],
  ];
  for (const [queryId, config] of checks) {
    const source = snapshot.queries[queryId].rows;
    const chartRows = prepareChartRows(source, config);
    assert.ok(chartRows.length <= 11, queryId);
    assert.ok(descending(chartRows, config.valueField), queryId);
    assert.equal(chartRows.reduce((total, row) => total + row[config.valueField], 0),
      source.reduce((total, row) => total + row[config.valueField], 0), queryId);
  }

  const stateGroups = Map.groupBy(snapshot.queries.channel_state_mix.rows, (row) => row.channel_name);
  for (const [channel, source] of stateGroups) {
    const chartRows = prepareChartRows(source, RANKING_CONFIGS.channelState);
    assert.ok(chartRows.length <= 11, channel);
    assert.ok(descending(chartRows, "paid_registrations"), channel);
    assert.equal(chartRows.reduce((total, row) => total + row.paid_registrations, 0),
      source.reduce((total, row) => total + row.paid_registrations, 0), channel);
  }

  for (const [queryId, config] of [
    ["lot_performance", { field: "lot", order: OPERATIONAL_ORDERS.lot }],
    ["modality_mix", { field: "modality", order: OPERATIONAL_ORDERS.modality }],
  ]) {
    const source = snapshot.queries[queryId].rows;
    const chartRows = prepareOperationalChartRows(source, config);
    assert.equal(chartRows.length, source.length, queryId);
    assert.equal(chartRows.reduce((total, row) => total + row.paid_registrations, 0),
      source.reduce((total, row) => total + row.paid_registrations, 0), queryId);
  }
});
