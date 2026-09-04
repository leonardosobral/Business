const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const root = path.resolve(__dirname, '..', '..', 'relatorios', 'maratona-floripa-2026');
const pages = [
  ['index.cfm', 'Visão geral'],
  ['estados/index.cfm', 'Estados'],
  ['portfolio/index.cfm', 'Portfólio 2027'],
  ['portfolio/simulador.cfm', 'Simulador'],
  ['canais/index.cfm', 'Canais'],
  ['canais/dossie.cfm', 'Canais'],
  ['explorador/index.cfm', 'Explorador'],
];
const requiredDestinations = [
  ['/relatorios/maratona-floripa-2026/', 'Visão geral'],
  ['/relatorios/maratona-floripa-2026/portfolio/', 'Portfólio 2027'],
  ['/relatorios/maratona-floripa-2026/estados/', 'Estados'],
  ['/relatorios/maratona-floripa-2026/canais/', 'Canais'],
  ['/relatorios/maratona-floripa-2026/portfolio/simulador.cfm', 'Simulador'],
  ['/relatorios/maratona-floripa-2026/explorador/', 'Explorador'],
];

test('every report screen exposes the full global navigation and highlights the current screen', () => {
  for (const [relativePath, currentLabel] of pages) {
    const source = fs.readFileSync(path.join(root, relativePath), 'utf8');
    const header = source.match(/<header class=["']report-topbar no-print["']>[\s\S]*?<\/header>/i)?.[0] || '';
    const actions = header.match(/<nav class=["']report-actions["'][^>]*>[\s\S]*?<\/nav>/i)?.[0] || '';

    assert.ok(actions, `${relativePath} must use the semantic global action nav`);
    const renderedLabels = [...actions.matchAll(/<a\b[^>]*>\s*([^<]+?)\s*<\/a>/gi)]
      .map((match) => match[1].trim());
    assert.deepEqual(
      renderedLabels,
      requiredDestinations.map(([, label]) => label),
      `${relativePath} must keep the agreed global navigation order`,
    );
    for (const [href, label] of requiredDestinations) {
      assert.match(
        actions,
        new RegExp(`href=["']${href.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}["'][^>]*>\\s*${label}\\s*<`, 'i'),
        `${relativePath} is missing ${label}`,
      );
    }
    assert.match(actions, /onclick=["']window\.print\(\)["'][^>]*>\s*Gerar PDF\s*</i);
    assert.match(actions, /class=["'][^"']*button-pdf[^"']*["'][^>]*onclick=["']window\.print\(\)["']/i);
    assert.equal((actions.match(/aria-current=["']page["']/gi) || []).length, 1, relativePath);
    assert.match(
      actions,
      new RegExp(`class=["'][^"']*button-current[^"']*["'][^>]*aria-current=["']page["'][^>]*href=["'][^"']+["'][^>]*>\\s*${currentLabel}\\s*<`, 'i'),
      `${relativePath} must highlight ${currentLabel}`,
    );
    assert.doesNotMatch(header, /<span>[^<]*(?:Evento 72611|pós-vendas|Dossiê comercial|Explorador controlado)[^<]*<\/span>/i);
  }
});

test('shared header and hero use available width without hiding navigation', () => {
  const css = fs.readFileSync(path.join(root, 'assets', 'report.css'), 'utf8');
  const topbar = css.match(/\.report-topbar\s*\{[^}]*\}/i)?.[0] || '';
  const actions = css.match(/\.report-actions\s*\{[^}]*\}/i)?.[0] || '';
  const hero = css.match(/\.report-hero\s*\{[^}]*\}/i)?.[0] || '';
  const heroTitle = css.match(/\.report-hero h1\s*\{[^}]*\}/i)?.[0] || '';

  assert.match(css, /--content-width:\s*1200px/i);
  assert.match(css, /--page-gutter:\s*max\(1rem,\s*calc\(\(100vw\s*-\s*var\(--content-width\)\)\s*\/\s*2\)\)/i);
  assert.match(topbar, /flex-wrap:\s*wrap/i);
  assert.match(topbar, /padding-inline:\s*var\(--page-gutter\)/i);
  assert.match(actions, /flex:\s*1\s+1/i);
  assert.match(actions, /justify-content:\s*flex-end/i);
  assert.match(hero, /padding-inline:\s*var\(--page-gutter\)/i);
  assert.match(heroTitle, /max-width:\s*min\(32ch,\s*100%\)/i);
  assert.doesNotMatch(heroTitle, /max-width:\s*16ch/i);
  assert.match(css, /\.button-current\s*\{[^}]*background:\s*var\(--accent\)/is);
  assert.match(css, /\.button-pdf\s*\{[^}]*border-color:\s*var\(--accent\)[^}]*color:\s*var\(--accent-light\)[^}]*background:\s*transparent/is);
  assert.match(css, /\.report-content\s*\{[^}]*width:\s*min\(var\(--content-width\),\s*calc\(100%\s*-\s*2rem\)\)/is);
  assert.match(css, /\.metric-card-value-numeric\s*\{[^}]*white-space:\s*nowrap/is);
  assert.match(css, /\.table-expansion\s*>\s*summary\s*\{/i);
  assert.match(css, /@media\s+print[\s\S]*\.table-expansion:not\(\[open\]\)\s*>\s*:not\(summary\)\s*\{[^}]*display:\s*block\s*!important/is);
  const mobile = css.match(/@media\s*\(max-width:\s*820px\)[\s\S]*?(?=@media|$)/i)?.[0] || '';
  assert.match(mobile, /\.report-topbar\s*\{[^}]*position:\s*static/is);
  assert.match(mobile, /\.report-actions\s*\{[^}]*width:\s*100%/is);
  assert.doesNotMatch(mobile, /\.report-actions[^}]*display:\s*none/is);
});
