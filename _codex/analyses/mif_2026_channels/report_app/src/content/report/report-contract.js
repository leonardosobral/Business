export const CHART_SPECS = Object.freeze({
  weekly_sales: { type: "line", x: "week_start", y: "paid_registrations", yLabel: "Inscrições pagas" },
  lot_performance: { type: "stackedBar", x: "base", y: "paid_registrations", series: "lot", yLabel: "Inscrições pagas" },
  modality_mix: { type: "stackedBar", x: "base", y: "paid_registrations", series: "modality", yLabel: "Inscrições pagas" },
  country_distribution: { type: "horizontalBar", x: "country", y: "paid_registrations", yLabel: "Inscrições pagas", preserveBarChart: true },
  state_distribution: { type: "horizontalBar", x: "state", y: "paid_registrations", yLabel: "Inscrições pagas", preserveBarChart: true },
  city_distribution: { type: "horizontalBar", x: "city", y: "paid_registrations", yLabel: "Inscrições pagas", preserveBarChart: true },
  product_summary: { type: "horizontalBar", x: "product_name", y: "registrations_with_product", yLabel: "Inscrições com produto", preserveBarChart: true },
});

const observedPeriod = (rows, periodField) => {
  if (!periodField) return [];
  return rows.map((row) => row?.[periodField]).filter(Boolean).sort();
};

export function evidenceDescription(rows, {
  periodField,
  periodStart,
  periodEnd,
  unit,
  denominator,
  denominatorLabel = "inscrições pagas",
}) {
  const periods = observedPeriod(rows, periodField);
  const start = periods[0] ?? periodStart ?? "não disponível";
  const end = periods.at(-1) ?? periodEnd ?? start;
  const base = Number.isFinite(Number(denominator)) ? Number(denominator).toLocaleString("pt-BR") : "não disponível";
  return `Período: ${start} a ${end}. Unidade: ${unit}. Denominador: ${base} ${denominatorLabel}.`;
}
