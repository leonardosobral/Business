const test = require("node:test");
const assert = require("node:assert/strict");
const { readFileSync } = require("node:fs");
const { join } = require("node:path");
const { execFileSync } = require("node:child_process");

test("event choices follow the displayed final date ascending, with undated events last", () => {
    const source = readFileSync(join(__dirname, "../../ads/includes/backend.cfm"), "utf8");
    const query = source.match(/<cfquery name="qAdsV1Events"[^>]*>([\s\S]*?)<\/cfquery>/i)[1];
    const orderBy = query.match(/\bORDER BY\s+[\s\S]*$/i)[0].trim();
    // Execute the production ordering over in-memory fixtures; no datasource or
    // production data is used. This ORDER BY syntax is shared with PostgreSQL.
    const actual = execFileSync("/usr/bin/sqlite3", [":memory:", `
        WITH evt(id_evento, nome_evento, data_inicial, data_final) AS (VALUES
            (1, 'Beta',  '2026-09-01', '2026-09-20'),
            (2, 'A sem data', '2026-01-01', NULL),
            (3, 'Alpha', '2026-09-18', '2026-09-19'),
            (4, 'Alpha', '2026-09-15', '2026-09-20'),
            (5, 'Antigo', '2025-12-31', '2025-12-31')
        )
        SELECT evt.id_evento FROM evt ${orderBy};
    `], { encoding: "utf8" }).trim().split("\n").map(Number);
    assert.deepEqual(actual, [5, 3, 4, 1, 2]);
});

test("creation lists only active linked events ending today or later", () => {
    const source = readFileSync(join(__dirname, "../../ads/includes/backend.cfm"), "utf8");
    // Render the active-account branch. Adapt only PostgreSQL's text cast for
    // SQLite; filters and ordering come from the production query unchanged.
    const query = source.match(/<cfquery name="qAdsV1Events"[^>]*>([\s\S]*?)<\/cfquery>/i)[1]
        .replace(/<cfif VARIABLES\.adsAccessIsPendingNewAccount>[\s\S]*?<\/cfif>/g, "")
        .replace(/<cfqueryparam[^>]*\/>/g, "1")
        .replace(/::text\b/g, "");
    const output = execFileSync("/usr/bin/sqlite3", ["-json", ":memory:", `
        ATTACH ':memory:' AS public;
        CREATE TABLE public.tb_evento_corridas (
            id_evento INTEGER, nome_evento TEXT, tag TEXT, data_inicial TEXT,
            data_final TEXT, cidade TEXT, estado TEXT, url_imagem TEXT,
            url_imagem_listagem TEXT, imagem TEXT, ativo BOOLEAN
        );
        CREATE TABLE public.tb_conta_eventos (id_conta INTEGER, id_evento INTEGER, status TEXT);
        INSERT INTO public.tb_evento_corridas(id_evento, nome_evento, data_inicial, data_final, ativo) VALUES
            (1, 'Encerrado', date(CURRENT_DATE, '-2 day'), date(CURRENT_DATE, '-1 day'), true),
            (2, 'Hoje', date(CURRENT_DATE, '-1 day'), CURRENT_DATE, true),
            (3, 'Futuro', date(CURRENT_DATE, '+2 day'), date(CURRENT_DATE, '+3 day'), true),
            (4, 'Sem data', CURRENT_DATE, NULL, true),
            (5, 'Outra conta', CURRENT_DATE, CURRENT_DATE, true),
            (6, 'Inativo', CURRENT_DATE, CURRENT_DATE, false);
        INSERT INTO public.tb_conta_eventos VALUES
            (1,1,'ATIVO'), (1,2,'ATIVO'), (1,3,'ATIVO'),
            (1,4,'ATIVO'), (2,5,'ATIVO'), (1,6,'ATIVO');
        ${query};
    `], { encoding: "utf8" });
    assert.deepEqual(JSON.parse(output).map(row => row.id_evento), [2, 3]);
});
