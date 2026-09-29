const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const sidenav = require("../../assets/js/business-sidenav.js");

function adminSectionForHref(href) {
    const template = fs.readFileSync(
        path.resolve(__dirname, "../../includes/estrutura/sidenav.cfm"),
        "utf8"
    );
    const adminStart = template.indexOf('<li class="sidenav-item business-sidenav-search-item">');
    const clientStart = template.indexOf(
        '<cfelse>\n            <li class="sidenav-item business-sidenav-fixed-item">',
        adminStart
    );
    const adminMenu = template.slice(adminStart, clientStart);
    const tokens = adminMenu.matchAll(
        /<span class="sidenav-subheading[^>]*>([^<]+)<\/span>|href="([^"]+)"/g
    );
    let currentSection = "";

    for (const token of tokens) {
        if (token[1]) {
            currentSection = token[1].trim();
        } else if (token[2] === href) {
            return currentSection;
        }
    }

    return null;
}

test("opens the section containing the active page before persisted or default state", () => {
    assert.equal(sidenav.chooseInitialSection({
        activeSection: "plataforma",
        persistedSection: "marketing-e-audiencia",
        defaultSection: "eventos-e-resultados"
    }), "plataforma");
});

test("admin accordion keeps at most one first-level section open", () => {
    assert.equal(sidenav.nextExpandedSection("conteudo-e-portal", "plataforma"), "plataforma");
    assert.equal(sidenav.nextExpandedSection("plataforma", "plataforma"), "");
});

test("search ignores accents and finds operational aliases", () => {
    assert.equal(sidenav.matchesMenuItem("Conteúdos", "curadoria matérias notícias", "noticias"), true);
    assert.equal(sidenav.matchesMenuItem("Cron Jobs", "automações tarefas agendadas", "automacoes"), true);
    assert.equal(sidenav.matchesMenuItem("Monitor da API", "saúde integrações", "financeiro"), false);
});

test("section keys remain stable for Portuguese labels", () => {
    assert.equal(sidenav.sectionKey("Marketing e audiência"), "marketing-e-audiencia");
});

test("admin places Banners in Marketing e audiência", () => {
    assert.equal(adminSectionForHref("/portal/banners/"), "Marketing e audiência");
});

test("admin places Verificados in Contas e parceiros", () => {
    assert.equal(adminSectionForHref("/portal/verificados/"), "Contas e parceiros");
});

for (const [label, href] of [
    ["Runner Apps", "/portal/runner-apps/"],
    ["Notificações", "/notificacoes/"],
    ["Temas", "/temas/"],
    ["CRM interno", "/crm-interno/"],
    ["Vicky Pacer", "/administracao/vicky/"]
]) {
    test(`admin finds ${label} under Plataforma`, () => {
        assert.equal(adminSectionForHref(href), "Plataforma");
    });
}

test("admin exposes challenges and training as their own top-level section", () => {
    assert.equal(adminSectionForHref("/treinos-config/"), "Desafios e treinos");
    assert.equal(adminSectionForHref("/desafios/circuitobrasilgigante/"), "Desafios e treinos");
});

test("admin lists Plataforma destinations alphabetically", () => {
    const template = fs.readFileSync(path.resolve(__dirname, "../../includes/estrutura/sidenav.cfm"), "utf8");
    const section = template.split("<!--- PLATAFORMA --->")[1].split("<!--- AJUDA --->")[0];
    assert.deepEqual([...section.matchAll(/href="([^"]+)"/g)].map(match => match[1]), [
        "/bi/", "/crm-interno/", "/administracao/cron-jobs/", "/portal/erros/",
        "/estudo/", "/administracao/api-monitor/", "/notificacoes/", "/administracao/pesquisas/",
        "/portal/runner-apps/", "/portal/seo/", "/administracao/status/", "/temas/", "/administracao/vicky/"
    ]);
});
