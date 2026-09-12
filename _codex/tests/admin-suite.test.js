'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const root = path.resolve(__dirname, '../..');
const read = (file) => fs.readFileSync(path.join(root, file), 'utf8');

test('Kanban, Agenda and Documents share the administrative suite shell', () => {
    const pages = [
        read('administracao/kanban/index.cfm') + read('administracao/kanban/home.cfm'),
        read('administracao/agenda/index.cfm'),
        read('administracao/drive/index.cfm')
    ];

    for (const page of pages) {
        assert.match(page, /admin-suite\.css/);
        assert.match(page, /admin-suite-page/);
        assert.match(page, /admin-suite-header/);
        assert.match(page, /admin-suite-commandbar/);
        assert.match(page, /admin-suite-status/);
        assert.match(page, /admin_suite_nav\.cfm/);
    }
});

test('suite navigation exposes all tools and identifies the current page', () => {
    const nav = read('includes/estrutura/admin_suite_nav.cfm');

    assert.match(nav, /aria-label="Ferramentas administrativas"/);
    assert.match(nav, /href="\/administracao\/kanban\/"/);
    assert.match(nav, /href="\/administracao\/agenda\/"/);
    assert.match(nav, /href="\/administracao\/drive\/"/);
    assert.equal((nav.match(/aria-current="page"/g) || []).length, 3);
});

test('suite styles preserve keyboard focus and responsive navigation', () => {
    const css = read('assets/css/admin-suite.css');

    assert.match(css, /admin-suite-nav-link:focus-visible/);
    assert.match(css, /outline:\s*2px solid var\(--admin-suite-accent\)/);
    assert.match(css, /@media \(max-width: 575\.98px\)/);
    assert.match(css, /grid-template-columns:\s*repeat\(3, minmax\(0, 1fr\)\)/);
});
