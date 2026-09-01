import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

const copyModule = await import("../src/content/report/report-copy.js");
const snapshot = JSON.parse(await readFile(new URL("../src/data.json", import.meta.url), "utf8"));

test("generated narratives pass through unchanged and fail closed when absent", () => {
  assert.equal(typeof copyModule.generatedNarrative, "function");
  assert.equal(
    copyModule.generatedNarrative({ executive_summary: "## Evidência" }, "executive_summary"),
    "## Evidência",
  );
  assert.throws(
    () => copyModule.generatedNarrative({}, "executive_summary"),
    /generated narrative/iu,
  );
});

test("ready ROADRUNNERS capstone carries the exact reconciled comparisons", () => {
  const query = snapshot.queries.roadrunners_capstone;
  assert.ok(query, "the canonical snapshot must expose the capstone query");
  const [row] = query.rows;
  assert.equal(row.available, true);
  assert.equal(row.coupon_channel_position, 1);
  assert.equal(row.paid_registrations, 1_876);
  assert.equal(row.event_share_pct, 11.94);
  assert.equal(row.coupon_assisted_share_pct, 23.16);
  assert.equal(row.gross_value, "545290.12");
  assert.equal(row.gross_event_share_pct, 12.62);
  assert.equal(row.registration_ticket, "290.67");
  assert.equal(row.event_registration_ticket, "275.05");
  assert.equal(row.registration_ticket_delta_pct, 5.68);
  assert.equal(row.long_distance_share_pct, 82.35);
  assert.equal(row.event_long_distance_share_pct, 79.11);
  assert.equal(row.long_distance_delta_pp, 3.24);
  assert.equal(row.observed_states, 27);
  assert.equal(row.state_valid_coverage_pct, 93.23);
  assert.deepEqual(row.state_deltas, [
    { state: "SP", delta_pp: 4.72 },
    { state: "SC", delta_pp: -8.7 },
  ]);
  assert.equal(row.peak_week_start, "2026-06-08");
  assert.equal(row.peak_week_paid_registrations, 87);
  assert.deepEqual(row.organic_similarity, {
    geography: 0.8891,
    modality: 0.9672,
    product: 0.9438,
  });
  assert.match(row.capstone_markdown, /escala e alcance.*mais claros.*composição/isu);
  assert.match(row.capstone_markdown, /1\.876 inscrições/u);
  assert.match(row.capstone_markdown, /8 jun\. 2026.*87 inscrições/u);
  assert.doesNotMatch(row.capstone_markdown, /\b1876\b|2026-06-08/u);
  assert.doesNotMatch(row.capstone_markdown, /\b(?:manter|cortar|eliminar|priorizar|ranking|score|recomenda)/iu);
});

test("generated channel narratives use ranked products, bounded aliases, and pt-BR labels", () => {
  const channels = snapshot.queries.channel_index.rows;
  const road = channels.find((row) => row.channel_name === "ROADRUNNERS");
  const sportsWeek = channels.find((row) => row.channel_name === "Sports Week");
  const pcd = channels.find((row) => row.channel_name === "PCD");
  const corre = channels.find((row) => row.channel_name === "Corre Criciúma");

  assert.match(road.executive_summary, /Camiseta FINISHER Maratona de Floripa: 114\/1\.876/u);
  assert.match(sportsWeek.executive_summary, /Gravação de medalha: 69\/949/u);
  assert.match(pcd.executive_summary, /Camiseta FINISHER Maratona de Floripa: 2\/71/u);
  assert.match(pcd.executive_summary, /71 identidades:[\s\S]*e mais 68 identidades/u);
  assert.doesNotMatch(pcd.executive_summary, /\b1 inscrições/u);
  assert.equal((corre.executive_summary.match(/\([0-9.]+ inscriç(?:ão|ões)\)/gu) ?? []).length, 2);
  for (const label of [
    "geografia:", "lote:", "modalidade:", "produtos:",
    "perfil: idade:", "perfil: gênero:", "tempo:",
  ]) {
    assert.match(road.executive_summary, new RegExp(label, "u"));
  }
  assert.doesNotMatch(
    road.executive_summary,
    /\b(?:geography|lot|modality|product|profile|temporal):/u,
  );
});

test("channel and compact datasets follow numeric commercial order while aliases stay grouped", () => {
  const commercialKey = (left, right) =>
    Number(right.gross_value) - Number(left.gross_value)
    || Number(right.paid_registrations) - Number(left.paid_registrations)
    || left.channel_name.localeCompare(right.channel_name, "pt-BR", { sensitivity: "base" })
    || left.channel_name.localeCompare(right.channel_name, "pt-BR");
  const channelIndex = snapshot.queries.channel_index.rows;
  const compact = snapshot.queries.long_tail.rows;
  assert.deepEqual(channelIndex.map((row) => row.channel_name), [...channelIndex].sort(commercialKey).map((row) => row.channel_name));
  assert.deepEqual(compact.map((row) => row.channel_name), [...compact].sort(commercialKey).map((row) => row.channel_name));
  assert.ok(compact.every((row) => /^\d+\.\d{2}$/u.test(row.gross_value)));

  const aliases = snapshot.queries.channel_aliases.rows;
  const closedGroups = new Set();
  let currentGroup = null;
  for (const row of aliases) {
    if (row.channel_name === currentGroup) continue;
    if (currentGroup !== null) closedGroups.add(currentGroup);
    assert.equal(closedGroups.has(row.channel_name), false, "an alias group must remain contiguous");
    currentGroup = row.channel_name;
  }
  assert.notEqual(aliases[0].channel_name, channelIndex[0].channel_name, "alias audit must not inherit gross ordering");
});

test("ReportContent consumes generated executive text in the visible reading path", async () => {
  const report = await readFile(new URL("../src/content/report/ReportContent.jsx", import.meta.url), "utf8");
  assert.match(report, /mif-executive-summary[\s\S]*generatedNarrative\(capstone, "executive_summary"\)/u);
  assert.match(report, /generatedNarrative\(channel, "executive_summary"\)/u);
  assert.match(report, /executive_highlight[\s\S]*Resumo executivo/u);
  assert.match(report, /long_tail[\s\S]*gross_value[\s\S]*Valor bruto \(R\$\)/u);
  assert.match(report, /const fullChannels = channelIndex\.filter/u);
  assert.doesNotMatch(report, /O índice é alfabético/u);
  assert.match(report, /mif-roadrunners-capstone[\s\S]*generatedNarrative\(capstone, "capstone_markdown"\)/u);
  assert.ok(report.indexOf("mif-executive-summary") < report.indexOf("mif-event-overview"));
  assert.ok(report.indexOf("mif-decision-questions") < report.indexOf("mif-roadrunners-capstone"));
  assert.ok(report.indexOf("mif-roadrunners-capstone") < report.indexOf("mif-methodology-limitations"));
});
