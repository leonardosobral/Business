const categoryCollator = new Intl.Collator("pt-BR", {
  numeric: true,
  sensitivity: "base",
});

const normalizedCategory = (value) => String(value ?? "")
  .normalize("NFD")
  .replace(/[\u0300-\u036f]/gu, "")
  .trim()
  .toLowerCase();

const isOther = (value) => new Set(["outros", "other"]).has(normalizedCategory(value));
const roundPct = (numerator, denominator) => Number.isFinite(numerator) && denominator > 0
  ? Number((numerator / denominator * 100).toFixed(2))
  : null;

function numericValue(row, field) {
  const value = row?.[field];
  if (!Number.isFinite(value)) {
    throw new TypeError(`Ranking field "${field}" must contain only finite numbers.`);
  }
  return value;
}

function sumField(rows, field) {
  return rows.reduce((total, row) => total + numericValue(row, field), 0);
}

function completeSum(rows, field) {
  return rows.every((row) => Number.isFinite(row?.[field])) ? sumField(rows, field) : null;
}

function constantField(rows, field) {
  if (!rows.length) return null;
  const first = JSON.stringify(rows[0]?.[field]);
  return rows.every((row) => JSON.stringify(row?.[field]) === first) ? rows[0]?.[field] ?? null : null;
}

function uniqueLabel(rows, field, fallback = "misto") {
  const values = [...new Set(rows.map((row) => row?.[field]).filter((value) => value != null))];
  return values.length === 1 ? values[0] : fallback;
}

function geographyOther(categoryField) {
  return (tail) => {
    const paid = sumField(tail, "paid_registrations");
    const denominator = constantField(tail, "denominator");
    return {
      [categoryField]: "Outros",
      paid_registrations: paid,
      denominator,
      share_pct: roundPct(paid, denominator),
    };
  };
}

function productOther(tail) {
  const registrations = sumField(tail, "registrations_with_product");
  const denominator = constantField(tail, "take_rate_denominator");
  const allRevenueAbsent = tail.every((row) => row.explicit_revenue == null);
  const completeRevenue = tail.every((row) => Number.isFinite(row.explicit_revenue));
  return {
    product_name: "Outros",
    classification: uniqueLabel(tail, "classification"),
    registrations_with_product: registrations,
    product_quantity: sumField(tail, "product_quantity"),
    take_rate_denominator: denominator,
    take_rate_pct: roundPct(registrations, denominator),
    explicit_revenue: completeRevenue ? completeSum(tail, "explicit_revenue") : null,
    explicit_revenue_coverage_pct: completeRevenue
      ? 100
      : allRevenueAbsent && tail.every((row) => row.explicit_revenue_coverage_pct === 0) ? 0 : null,
  };
}

function channelStateOther(tail) {
  const registrations = sumField(tail, "paid_registrations");
  const channelDenominator = constantField(tail, "channel_denominator");
  const denominator = constantField(tail, "denominator");
  const eventCount = sumField(tail, "event_count");
  const eventDenominator = constantField(tail, "event_denominator");
  const share = roundPct(registrations, denominator);
  const eventShare = roundPct(eventCount, eventDenominator);
  return {
    channel_name: constantField(tail, "channel_name"),
    state: "Outros",
    paid_registrations: registrations,
    channel_count: sumField(tail, "channel_count"),
    channel_denominator: channelDenominator,
    denominator,
    event_count: eventCount,
    event_denominator: eventDenominator,
    share_pct: share,
    delta_pp: share == null || eventShare == null ? null : Number((share - eventShare).toFixed(2)),
    coverage: constantField(tail, "coverage"),
  };
}

/**
 * Prepare chart-only categorical ranking rows without mutating or truncating the
 * reviewed source rows used by source inspectors and paginated tables.
 */
export function prepareChartRows(rows = [], {
  categoryField,
  valueField,
  topN = 10,
  otherLabel = "Outros",
  aggregateOther,
} = {}) {
  if (!Array.isArray(rows) || !categoryField || !valueField) return rows;
  if (!Number.isSafeInteger(topN) || topN < 1) throw new TypeError("topN must be a positive safe integer.");

  const seen = new Set();
  const ranked = rows.map((row, index) => {
    const category = row?.[categoryField];
    const normalized = normalizedCategory(category);
    if (!normalized) throw new TypeError(`Ranking field "${categoryField}" must contain non-empty labels.`);
    if (!isOther(category) && seen.has(normalized)) {
      throw new TypeError(`Ranking field "${categoryField}" contains duplicate category "${category}".`);
    }
    if (!isOther(category)) seen.add(normalized);
    numericValue(row, valueField);
    return { row, index };
  }).sort((left, right) => numericValue(right.row, valueField) - numericValue(left.row, valueField)
    || categoryCollator.compare(String(left.row[categoryField]), String(right.row[categoryField]))
    || left.index - right.index);

  if (ranked.length <= topN) return ranked.map(({ row }) => row);

  const ordinary = ranked.filter(({ row }) => !isOther(row[categoryField]));
  const reviewedOther = ranked.filter(({ row }) => isOther(row[categoryField]));
  const leaders = ordinary.slice(0, topN);
  const tail = [...ordinary.slice(topN), ...reviewedOther].map(({ row }) => row);
  if (!tail.length) return leaders.map(({ row }) => row);

  const fallback = {
    [categoryField]: otherLabel,
    [valueField]: sumField(tail, valueField),
  };
  const other = aggregateOther ? aggregateOther(tail, fallback) : fallback;
  const normalizedOther = {
    ...other,
    [categoryField]: otherLabel,
    [valueField]: sumField(tail, valueField),
  };
  return [...leaders.map(({ row }) => row), normalizedOther]
    .map((row, index) => ({ row, index }))
    .sort((left, right) => numericValue(right.row, valueField) - numericValue(left.row, valueField)
      || categoryCollator.compare(String(left.row[categoryField]), String(right.row[categoryField]))
      || left.index - right.index)
    .map(({ row }) => row);
}

export function chartRankingDescription(description, sourceRows, chartRows, {
  categoryField,
  topN = 10,
} = {}) {
  if (!Array.isArray(sourceRows) || sourceRows.length <= topN
    || !chartRows.some((row) => isOther(row?.[categoryField]))) return description;
  return `${description} Visualização do gráfico: Top ${topN} + Outros; as ${sourceRows.length.toLocaleString("pt-BR")} categorias completas permanecem na tabela paginada da fonte.`;
}

/** Apply a reviewed business order without ranking, grouping, or truncating rows. */
export function prepareOperationalChartRows(rows = [], { field, order = [] } = {}) {
  if (!Array.isArray(rows) || !field || !Array.isArray(order)) return rows;
  const positions = new Map(order.map((value, index) => [normalizedCategory(value), index]));
  return rows.map((row, index) => ({ row, index })).sort((left, right) => {
    const leftLabel = String(left.row?.[field] ?? "");
    const rightLabel = String(right.row?.[field] ?? "");
    const leftPosition = positions.get(normalizedCategory(leftLabel)) ?? positions.size;
    const rightPosition = positions.get(normalizedCategory(rightLabel)) ?? positions.size;
    return leftPosition - rightPosition
      || categoryCollator.compare(leftLabel, rightLabel)
      || left.index - right.index;
  }).map(({ row }) => row);
}

export const OPERATIONAL_ORDERS = Object.freeze({
  lot: Object.freeze(["1", "2", "3", "4", "5", "6", "7", "OUTRO: 0"]),
  modality: Object.freeze(["5K", "21K", "42K", "DESAFIO", "KIDS"]),
});

export const OPERATIONAL_CONFIGS = Object.freeze({
  lot: Object.freeze({ field: "lot", order: OPERATIONAL_ORDERS.lot }),
  modality: Object.freeze({ field: "modality", order: OPERATIONAL_ORDERS.modality }),
});

export const RANKING_CONFIGS = Object.freeze({
  country: Object.freeze({
    categoryField: "country", valueField: "paid_registrations", aggregateOther: geographyOther("country"),
  }),
  state: Object.freeze({
    categoryField: "state", valueField: "paid_registrations", aggregateOther: geographyOther("state"),
  }),
  city: Object.freeze({
    categoryField: "city", valueField: "paid_registrations", aggregateOther: geographyOther("city"),
  }),
  product: Object.freeze({
    categoryField: "product_name", valueField: "registrations_with_product", aggregateOther: productOther,
  }),
  channelState: Object.freeze({
    categoryField: "state", valueField: "paid_registrations", aggregateOther: channelStateOther,
  }),
});
