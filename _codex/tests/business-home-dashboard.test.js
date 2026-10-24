const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const source = fs.readFileSync(path.resolve(__dirname, "../../assets/js/business-home-dashboard.js"), "utf8");
const areaKeys = ["audiencia", "contas", "conteudo", "comunicacao"];

function eventTarget(target = {}) {
    const listeners = new Map();
    target.addEventListener = (type, handler) => {
        if (!listeners.has(type)) listeners.set(type, []);
        listeners.get(type).push(handler);
    };
    target.dispatch = (type, properties = {}) => {
        const event = {
            type, target, currentTarget: target, button: 0, defaultPrevented: false,
            preventDefault() { this.defaultPrevented = true; }, ...properties
        };
        for (const handler of listeners.get(type) || []) handler(event);
        return event;
    };
    return target;
}

function element(attributes = {}, children = []) {
    const attrs = new Map(Object.entries(attributes));
    const classes = new Set();
    const node = eventTarget({
        children, hidden: false, tabIndex: 0,
        getAttribute: name => attrs.has(name) ? attrs.get(name) : null,
        setAttribute: (name, value) => attrs.set(name, String(value)),
        removeAttribute: name => attrs.delete(name),
        hasAttribute: name => attrs.has(name),
        classList: {
            toggle(name, present) { if (present) classes.add(name); else classes.delete(name); },
            contains: name => classes.has(name)
        },
        querySelectorAll(selector) {
            const matches = [];
            for (const child of this.children) {
                if (selector[0] === "#" ? child.id === selector.slice(1) : child.hasAttribute(selector.slice(1, -1))) matches.push(child);
                matches.push(...child.querySelectorAll(selector));
            }
            return matches;
        },
        querySelector(selector) { return this.querySelectorAll(selector)[0] || null; }
    });
    Object.defineProperty(node, "id", {get: () => attrs.get("id") || "", set: value => attrs.set("id", value)});
    return node;
}

function setup(options = {}) {
    const selected = options.selected || "audiencia";
    const tabs = Object.fromEntries(areaKeys.map(key => [key, element({
        "data-home-tab": key,
        href: "/?periodo=30&home_area=" + key + "#business-admin-areas"
    })]));
    const panels = Object.fromEntries(areaKeys.map(key => {
        const panel = element({"data-home-panel": key, id: "home-area-" + key});
        panel.hidden = key !== selected;
        return [key, panel];
    }));
    const tablist = element({"data-home-tabs": ""}, Object.values(tabs));
    const areas = element({id: "business-admin-areas"}, [tablist, ...Object.values(panels)]);
    const alerts = element({id: "business-admin-pending"});
    const periodLinks = [
        element({"data-home-period": "", href: "?periodo=7&home_area=audiencia"}),
        element({"data-home-period": "", href: "?periodo=30&home_area=audiencia#business-admin-areas"}),
        element({"data-home-period": "", href: "?periodo=30&home_area=audiencia&refresh=1"})
    ];
    const root = element({"data-business-home": ""}, [...periodLinks, alerts, areas]);
    const document = eventTarget(element({}, options.noRoot ? [] : [root]));
    document.readyState = options.loading ? "loading" : "complete";
    document.getElementById = id => document.querySelector("#" + id);
    const scrolls = [];
    for (const node of [root, alerts, areas, ...Object.values(panels), ...Object.values(tabs)]) {
        node.focus = () => { document.activeElement = node; };
        node.scrollIntoView = () => scrolls.push(node.id);
    }
    const replacements = [];
    const window = eventTarget({
        location: new URL(options.url || "https://business.example/index.cfm?periodo=30&origem=atalho"),
        history: {
            state: {retained: true},
            replaceState(state, title, url) {
                if (options.historyError) throw new Error("History unavailable");
                replacements.push({state, url});
                window.location = new URL(url, window.location.href);
            }
        }
    });
    vm.runInNewContext(source, {window, document, URL});
    return {tabs, panels, tablist, periodLinks, document, window, replacements, scrolls};
}

function assertSelected(app, key) {
    for (const area of areaKeys) {
        assert.equal(app.panels[area].hidden, area !== key, "panel " + area);
        assert.equal(app.tabs[area].getAttribute("aria-selected"), area === key ? "true" : "false", "selection " + area);
        assert.equal(app.tabs[area].tabIndex, area === key ? 0 : -1, "tab stop " + area);
    }
}

test("enhances server-selected links into connected accessible tabs without changing the URL", () => {
    const app = setup({selected: "contas"});
    assert.equal(app.tablist.getAttribute("role"), "tablist");
    assertSelected(app, "contas");
    for (const key of areaKeys) {
        assert.equal(app.tabs[key].getAttribute("role"), "tab");
        assert.equal(app.tabs[key].getAttribute("aria-controls"), app.panels[key].id);
        assert.equal(app.panels[key].getAttribute("role"), "tabpanel");
        assert.equal(app.panels[key].getAttribute("aria-labelledby"), app.tabs[key].id);
        assert.equal(app.panels[key].tabIndex, 0);
    }
    assert.equal(app.replacements.length, 0);
});

test("primary click switches the panel and preserves path, period, other query values and history state", () => {
    const app = setup();
    const event = app.tabs.conteudo.dispatch("click");
    assert.equal(event.defaultPrevented, true);
    assertSelected(app, "conteudo");
    assert.equal(app.window.location.href, "https://business.example/index.cfm?periodo=30&origem=atalho&home_area=conteudo#business-admin-areas");
    assert.deepEqual(app.replacements[0].state, {retained: true});
    assert.equal(app.tabs.conteudo.classList.contains("is-active"), true);
});

test("modified and non-primary clicks retain native link behavior", () => {
    const app = setup();
    for (const properties of [{ctrlKey: true}, {metaKey: true}, {shiftKey: true}, {altKey: true}, {button: 1}, {button: 2}, {defaultPrevented: true}]) {
        const event = app.tabs.contas.dispatch("click", properties);
        assert.equal(event.defaultPrevented, properties.defaultPrevented === true);
        assertSelected(app, "audiencia");
    }
    assert.equal(app.replacements.length, 0);
    assert.equal(app.tabs.contas.getAttribute("href"), "/?periodo=30&home_area=contas#business-admin-areas");
});

test("arrows wrap and Home/End activate and focus a single keyboard tab stop", () => {
    const app = setup();
    for (const [from, key, selected] of [
        ["audiencia", "ArrowRight", "contas"], ["contas", "End", "comunicacao"],
        ["comunicacao", "ArrowRight", "audiencia"], ["audiencia", "ArrowLeft", "comunicacao"],
        ["comunicacao", "Home", "audiencia"]
    ]) {
        assert.equal(app.tabs[from].dispatch("keydown", {key}).defaultPrevented, true);
        assertSelected(app, selected);
        assert.equal(app.document.activeElement, app.tabs[selected]);
        assert.equal(app.window.location.search.includes("periodo=30"), true);
        assert.equal(app.window.location.search.includes("home_area=" + selected), true);
    }
});

test("Space activates a tab but unrelated and modified keys retain native behavior", () => {
    const app = setup();
    assert.equal(app.tabs.contas.dispatch("keydown", {key: " "}).defaultPrevented, true);
    assertSelected(app, "contas");
    for (const properties of [{key: "Tab"}, {key: "ArrowDown"}, {key: "ArrowRight", ctrlKey: true}]) {
        assert.equal(app.tabs.contas.dispatch("keydown", properties).defaultPrevented, false);
        assertSelected(app, "contas");
    }
});

test("a valid URL area opens directly and an unknown value retains the server selection", () => {
    assertSelected(setup({url: "https://business.example/?periodo=7&home_area=comunicacao#business-admin-areas"}), "comunicacao");
    assertSelected(setup({url: "https://business.example/?home_area=unknown", selected: "contas"}), "contas");
});

test("legacy content and health hashes open their areas and scroll to the area navigation", () => {
    for (const [hash, area] of [["business-admin-content", "conteudo"], ["business-admin-health", "audiencia"]]) {
        const app = setup({url: "https://business.example/?periodo=7&home_area=contas#" + hash});
        assertSelected(app, area);
        assert.equal(app.window.location.hash, "#business-admin-areas");
        assert.equal(app.window.location.search.includes("periodo=7"), true);
        assert.equal(app.window.location.search.includes("home_area=" + area), true);
        assert.deepEqual(app.scrolls, ["business-admin-areas"]);
    }
});

test("legacy payment and infrastructure hashes keep the active area and reach current alerts", () => {
    for (const hash of ["business-admin-payments", "business-admin-infra"]) {
        const app = setup({url: "https://business.example/?periodo=30&home_area=contas#" + hash});
        assertSelected(app, "contas");
        assert.equal(app.window.location.hash, "#business-admin-pending");
        assert.equal(app.window.location.search, "?periodo=30&home_area=contas");
        assert.deepEqual(app.scrolls, ["business-admin-pending"]);
    }
});

test("a direct panel hash reveals its hidden panel", () => {
    const app = setup({url: "https://business.example/?periodo=30#home-area-comunicacao"});
    assertSelected(app, "comunicacao");
    assert.deepEqual(app.scrolls, ["home-area-comunicacao"]);
});

test("browser history and hash navigation resynchronize the panels without taking focus", () => {
    const app = setup();
    app.tabs.contas.dispatch("click");
    app.document.activeElement = app.tabs.contas;
    app.window.location = new URL("https://business.example/?periodo=30&home_area=comunicacao#business-admin-areas");
    app.window.dispatch("popstate");
    assertSelected(app, "comunicacao");
    assert.equal(app.document.activeElement, app.tabs.contas);
    assert.equal(app.replacements.length, 1);
    app.window.location = new URL("https://business.example/?periodo=30#business-admin-content");
    app.window.dispatch("hashchange");
    assertSelected(app, "conteudo");
    assert.deepEqual(app.scrolls, ["business-admin-areas"]);
});

test("initialization waits for markup and is harmless on pages without the dashboard", () => {
    const app = setup({loading: true});
    assert.equal(app.tablist.getAttribute("role"), null);
    app.document.dispatch("DOMContentLoaded");
    assertSelected(app, "audiencia");
    assert.doesNotThrow(() => setup({noRoot: true}));
});

test("an unavailable History API does not prevent local tab interaction", () => {
    const app = setup({historyError: true});
    assert.doesNotThrow(() => app.tabs.contas.dispatch("click"));
    assertSelected(app, "contas");
});

test("period and refresh links retain the selected area after switching tabs", () => {
    const app = setup({selected: "contas"});
    assert.equal(new URL(app.periodLinks[0].getAttribute("href"), app.window.location.href).searchParams.get("home_area"), "contas");
    app.tabs.conteudo.dispatch("click");
    const urls = app.periodLinks.map(link => new URL(link.getAttribute("href"), app.window.location.href));
    assert.deepEqual(urls.map(url => url.searchParams.get("home_area")), ["conteudo", "conteudo", "conteudo"]);
    assert.deepEqual(urls.map(url => url.searchParams.get("periodo")), ["7", "30", "30"]);
    assert.equal(urls[1].hash, "#business-admin-areas");
    assert.equal(urls[2].searchParams.get("refresh"), "1");
});
