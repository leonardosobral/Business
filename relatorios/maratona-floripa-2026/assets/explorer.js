(function attachMifExplorer(globalScope) {
  'use strict';

  const METRIC_CONTRACTS = Object.freeze({
    paid_registrations: { cube: 'registrations', label: 'Inscrições pagas', kind: 'sum', field: 'paid_registrations', formatter: 'integer' },
    gross_value: { cube: 'registrations', label: 'Valor bruto alocado', kind: 'sum', field: 'allocated_gross_value', formatter: 'currency' },
    discount_value: { cube: 'registrations', label: 'Desconto alocado', kind: 'sum', field: 'allocated_discount_value', formatter: 'currency' },
    fee_value: { cube: 'registrations', label: 'Taxa alocada', kind: 'sum', field: 'allocated_fee_value', formatter: 'currency' },
    registration_ticket: { cube: 'registrations', label: 'Ticket por inscrição', kind: 'ratio', numerator: 'allocated_gross_value', denominator: 'paid_registrations', formatter: 'currency' },
    product_quantity: { cube: 'products', label: 'Quantidade de itens', kind: 'sum', field: 'product_quantity', formatter: 'integer' },
    registrations_with_product: { cube: 'products', label: 'Ocorrências inscrição-produto', kind: 'sum', field: 'registrations_with_product', formatter: 'integer' },
    explicit_revenue: { cube: 'products', label: 'Receita explícita de produto', kind: 'sum', field: 'explicit_revenue', formatter: 'currency' },
  });
  const FILTER_FIELDS = Object.freeze([
    'week_start', 'phase', 'modality', 'lot', 'state', 'city', 'channel_name', 'classification', 'product_name',
  ]);

  function number(value) {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : 0;
  }

  function availableDimensions(data, cube) {
    const declared = data?.dimensions?.[cube];
    if (Array.isArray(declared)) return declared;
    const rows = cube === 'products' ? data?.product_cube : data?.registration_cube;
    return rows?.length ? Object.keys(rows[0]).filter((key) => FILTER_FIELDS.includes(key)) : [];
  }

  function validateSelection(selection, data) {
    const metric = METRIC_CONTRACTS[selection?.metric];
    if (!metric) throw new Error('Métrica não permitida neste explorador.');
    if (selection?.thirdDimension) throw new Error('Selecione no máximo duas dimensões.');
    const primary = selection?.primaryDimension;
    const comparison = selection?.comparisonDimension || '';
    if (!primary) throw new Error('A dimensão principal é obrigatória.');
    if (comparison && comparison === primary) throw new Error('A comparação deve usar outra dimensão.');
    const dimensions = availableDimensions(data, metric.cube);
    if (!dimensions.includes(primary) || (comparison && !dimensions.includes(comparison))) {
      throw new Error('Dimensão incompatível com a métrica selecionada.');
    }
    return { ...metric, metric: selection.metric, primaryDimension: primary, comparisonDimension: comparison };
  }

  function filterRows(rows, filters = {}) {
    const active = Object.entries(filters)
      .filter(([key, value]) => FILTER_FIELDS.includes(key) && value != null && String(value).trim() !== '')
      .map(([key, value]) => [key, String(value)]);
    return (rows || []).filter((row) => active.every(([key, value]) => String(row[key] ?? '') === value));
  }

  function emptyComponents(contract) {
    return contract.kind === 'ratio' ? { numerator: 0, denominator: 0 } : { total: 0 };
  }

  function addComponents(components, row, contract) {
    if (contract.kind === 'ratio') {
      components.numerator += number(row[contract.numerator]);
      components.denominator += number(row[contract.denominator]);
    } else {
      components.total += number(row[contract.field]);
    }
  }

  function mergeComponents(target, source, contract) {
    if (contract.kind === 'ratio') {
      target.numerator += source.numerator;
      target.denominator += source.denominator;
    } else {
      target.total += source.total;
    }
  }

  function componentValue(components, contract) {
    if (contract.kind === 'ratio') {
      return components.denominator ? components.numerator / components.denominator : null;
    }
    return components.total;
  }

  function aggregateRows(data, selection, filters = {}) {
    const contract = validateSelection(selection, data);
    const sourceRows = contract.cube === 'products' ? data.product_cube : data.registration_cube;
    const dimensions = availableDimensions(data, contract.cube);
    const invalidFilter = Object.entries(filters).find(([key, value]) => value != null && String(value).trim() && !dimensions.includes(key));
    if (invalidFilter) throw new Error(`Filtro incompatível com o grão: ${invalidFilter[0]}.`);
    const rows = filterRows(sourceRows, filters);
    const groups = new Map();
    for (const row of rows) {
      const primary = String(row[contract.primaryDimension] ?? 'Não informado');
      const comparison = contract.comparisonDimension
        ? String(row[contract.comparisonDimension] ?? 'Não informado')
        : '';
      const key = JSON.stringify([primary, comparison]);
      if (!groups.has(key)) groups.set(key, { primary, comparison, components: emptyComponents(contract) });
      addComponents(groups.get(key).components, row, contract);
    }
    const resultRows = [...groups.values()].map((row) => ({
      primary: row.primary,
      comparison: row.comparison,
      value: componentValue(row.components, contract),
      components: row.components,
    })).sort((left, right) => {
      const valueDifference = number(right.value) - number(left.value);
      return valueDifference
        || left.primary.localeCompare(right.primary, 'pt-BR', { numeric: true })
        || left.comparison.localeCompare(right.comparison, 'pt-BR', { numeric: true });
    });

    const productNamesOverlap = contract.cube === 'products'
      && [contract.primaryDimension, contract.comparisonDimension].includes('product_name');
    let chartTailMode = 'complete';
    let chartRows = resultRows.map((row) => ({ ...row }));
    if (chartRows.length > 10) {
      if (productNamesOverlap) {
        chartRows = chartRows.slice(0, 10);
        chartTailMode = 'truncate-products';
      } else {
        const tailComponents = emptyComponents(contract);
        for (const row of chartRows.slice(10)) mergeComponents(tailComponents, row.components, contract);
        chartRows = [
          ...chartRows.slice(0, 10),
          {
            primary: 'Outros',
            comparison: '',
            value: componentValue(tailComponents, contract),
            components: tailComponents,
            aggregated_rows: resultRows.length - 10,
          },
        ];
        chartTailMode = 'aggregate-other';
      }
    }
    const denominator = contract.cube === 'registrations'
      ? rows.reduce((total, row) => total + number(row.paid_registrations), 0)
      : rows.reduce((total, row) => total + number(row.product_quantity), 0);
    return {
      contract,
      rows: resultRows,
      chartRows,
      chartTailMode,
      denominator,
      sourceRowCount: rows.length,
      grain: contract.cube === 'registrations' ? 'inscrições pagas agregadas' : 'itens de produto vinculados',
    };
  }

  function buildShareUrl(baseUrl, selection, filters = {}) {
    const url = new URL(baseUrl);
    const entries = [
      ['comparacao', selection.comparisonDimension || ''],
      ['dimensao', selection.primaryDimension || ''],
      ['metrica', selection.metric || ''],
      ...Object.entries(filters)
        .filter(([key, value]) => FILTER_FIELDS.includes(key) && value != null && String(value).trim())
        .map(([key, value]) => [`filtro_${key}`, String(value)]),
    ].filter(([, value]) => value !== '').sort(([left], [right]) => left.localeCompare(right));
    url.search = '';
    for (const [key, value] of entries) url.searchParams.set(key, value);
    return url.toString();
  }

  function formatter(report, contract) {
    if (contract.formatter === 'currency') return report.formatCurrency;
    if (contract.formatter === 'percent') return report.formatPercent;
    return report.formatInteger;
  }

  function render(root, data, selection, filters = {}) {
    const result = aggregateRows(data, selection, filters);
    const report = globalScope.MifReport;
    if (!report) throw new Error('Renderizador compartilhado indisponível.');
    const format = formatter(report, result.contract);
    const chartRows = result.rows.map((row) => ({
      label: row.comparison ? `${row.primary} · ${row.comparison}` : row.primary,
      value: row.value,
    }));
    const tableRows = result.rows.map((row) => ({
      primary: row.primary,
      comparison: row.comparison || '—',
      value: row.value,
    }));
    root.innerHTML = `<div class="explorer-receipt"><strong>Grão:</strong> ${report.escapeHtml(result.grain)} · <strong>Células observadas:</strong> ${report.formatInteger(result.sourceRowCount)} · <strong>Base aditiva:</strong> ${report.formatInteger(result.denominator)}</div>
      ${report.renderBarChart({ title: result.contract.label, description: result.chartTailMode === 'truncate-products' ? 'Produtos são sobrepostos; visual Top 10 sem somar “Outros”. A tabela mantém todos os itens.' : 'Cruzamento controlado sobre cubos anônimos pré-calculados.', rows: chartRows, labelKey: 'label', valueKey: 'value', valueFormatter: format, limit: 10, aggregateOther: result.chartTailMode === 'truncate-products' ? false : undefined, denominator: result.denominator, source: result.grain })}
      ${report.renderTable({ columns: [
        { key: 'primary', label: selection.primaryDimension },
        { key: 'comparison', label: selection.comparisonDimension || 'Comparação' },
        { key: 'value', label: result.contract.label, format },
      ], rows: tableRows })}`;
    return result;
  }

  const api = {
    METRIC_CONTRACTS,
    FILTER_FIELDS,
    validateSelection,
    filterRows,
    aggregateRows,
    buildShareUrl,
    render,
  };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  if (globalScope) globalScope.MifExplorer = api;
})(typeof window !== 'undefined' ? window : globalThis);
