const test = require("node:test");
const assert = require("node:assert/strict");

const sidenav = require("../../assets/js/business-sidenav.js");

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
