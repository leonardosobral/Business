const test = require("node:test");
const assert = require("node:assert/strict");

const wizard = require("../../assets/js/ads-campaign-wizard.js");

test("estimates a realistic click range from budget and CPC", () => {
    assert.deepEqual(wizard.estimateClicks(100, 0.94), { min: 80, max: 106 });
    assert.deepEqual(wizard.estimateClicks(100, 0.56), { min: 134, max: 178 });
    assert.deepEqual(wizard.estimateClicks(100, 1.32), { min: 57, max: 75 });
});

test("returns no estimate when budget or CPC is invalid", () => {
    assert.deepEqual(wizard.estimateClicks(0, 0.94), { min: 0, max: 0 });
    assert.deepEqual(wizard.estimateClicks(100, 0), { min: 0, max: 0 });
    assert.deepEqual(wizard.estimateClicks("abc", 0.94), { min: 0, max: 0 });
});

test("suggests ending the campaign on the event date at 23:59", () => {
    assert.equal(
        wizard.suggestEndAt("2026-11-23"),
        "2026-11-23T23:59"
    );
});

// DOM boundary doubles: run the real initWizard and its registered handlers.
// No network, saved campaign or application session is involved.
function setupEventWizard({ isNew = true, region = "", end = "2026-10-11T14:51", preserve = false, initialStep = 1 } = {}) {
    const elements = new Map();
    function element(selector) {
        if (!elements.has(selector)) elements.set(selector, {
            value: "", dataset: {}, handlers: {}, hidden: false,
            classList: { toggle() {}, remove() {}, add() {} },
            addEventListener(type, handler) { this.handlers[type] = handler; },
            removeAttribute() {}, setAttribute() {}, setCustomValidity() {}
        });
        return elements.get(selector);
    }
    const form = {
        dataset: { isNew: String(isNew), preserveInputs: String(preserve), initialStep: String(initialStep) },
        querySelector: element, querySelectorAll: () => [], addEventListener() {}
    };
    const select = element("#ads-v1-event");
    select.options = [
        { value: "", dataset: {} },
        { value: "1", dataset: { eventName: "Brasília", eventCity: "Brasília", eventState: "DF", eventEnd: "2026-10-11", eventDate: "11/10/2026", eventTag: "brasilia", eventImage: "" } },
        { value: "2", dataset: { eventName: "Campinas", eventCity: "Campinas", eventState: "SP", eventEnd: "2026-10-18", eventDate: "18/10/2026", eventTag: "campinas", eventImage: "" } }
    ];
    select.selectedIndex = preserve || !isNew ? 1 : 0;
    element("#ads-v1-region").value = region;
    element("#ads-v1-end").value = end;
    wizard.initWizard(form);
    return {
        element,
        choose(index) { select.selectedIndex = index; select.handlers.change(); },
        input(selector, value) {
            const field = element(selector);
            field.value = value;
            if (field.handlers.input) field.handlers.input();
            if (field.handlers.change) field.handlers.change();
        }
    };
}

test("draft and review buttons only appear on the last step", () => {
    const first = setupEventWizard();
    assert.equal(first.element("#ads-wizard-submit").hidden, true);
    assert.equal(first.element("#ads-wizard-draft").hidden, true);
    const last = setupEventWizard({ initialStep: 4 });
    assert.equal(last.element("#ads-wizard-submit").hidden, false);
    assert.equal(last.element("#ads-wizard-draft").hidden, false);
    last.element("#ads-wizard-back").handlers.click();
    assert.equal(last.element("#ads-wizard-submit").hidden, true);
    assert.equal(last.element("#ads-wizard-draft").hidden, true);
});

test("switching events replaces the automatically suggested region", () => {
    const app = setupEventWizard();
    app.choose(1);
    assert.equal(app.element("#ads-v1-region").value, "DF");
    app.choose(2);
    assert.equal(app.element("#ads-v1-region").value, "SP");
});

test("selecting another event suggests its final day at 23:59", () => {
    const app = setupEventWizard();
    app.choose(1);
    assert.equal(app.element("#ads-v1-end").value, "2026-10-11T23:59");
    app.choose(2);
    assert.equal(app.element("#ads-v1-end").value, "2026-10-18T23:59");
});

test("event changes preserve manually entered region and end date", () => {
    const app = setupEventWizard();
    app.choose(1);
    app.input("#ads-v1-region", "SC");
    app.input("#ads-v1-end", "2026-10-20T12:30");
    app.choose(2);
    assert.equal(app.element("#ads-v1-region").value, "SC");
    assert.equal(app.element("#ads-v1-end").value, "2026-10-20T12:30");
});

test("a manually cleared region stays unrestricted on event change", () => {
    const app = setupEventWizard();
    app.choose(1);
    app.input("#ads-v1-region", "");
    app.choose(2);
    assert.equal(app.element("#ads-v1-region").value, "");
});

test("reopening an existing campaign preserves saved targeting and dates", () => {
    const app = setupEventWizard({ isNew: false, region: "SC", end: "2026-10-20T12:30" });
    app.choose(2);
    assert.equal(app.element("#ads-v1-region").value, "SC");
    assert.equal(app.element("#ads-v1-end").value, "2026-10-20T12:30");
});

test("redisplaying a failed submission preserves the user's blank region and date", () => {
    const app = setupEventWizard({ preserve: true, end: "2026-10-20T12:30" });
    assert.equal(app.element("#ads-v1-region").value, "");
    assert.equal(app.element("#ads-v1-end").value, "2026-10-20T12:30");
});

test("does not invent an end date when the event date is unavailable", () => {
    assert.equal(wizard.suggestEndAt("", 3), "");
    assert.equal(wizard.suggestEndAt("not-a-date", 3), "");
});

test("normalizes decimal values entered with Brazilian commas", () => {
    assert.equal(wizard.parseMoney("0,94"), 0.94);
    assert.equal(wizard.parseMoney("R$ 100,00"), 100);
});

test("requires the linked event and campaign name in the first step", () => {
    assert.equal(wizard.isStepValid(1, { eventId: "", name: "" }), false);
    assert.equal(wizard.isStepValid(1, { eventId: "40260", name: "Divulgação da prova" }), true);
});

test("rejects a daily limit above the total budget", () => {
    assert.equal(wizard.isStepValid(2, { cpc: "0.94", budget: "100", daily: "120" }), false);
    assert.equal(wizard.isStepValid(2, { cpc: "0.94", budget: "100", daily: "20" }), true);
});

test("enforces the auction floor for a custom CPC bid", () => {
    assert.equal(wizard.isStepValid(2, { cpc: "0.50", budget: "100", daily: "" }), false);
    assert.equal(wizard.isStepValid(2, { cpc: "0.51", budget: "100", daily: "" }), true);
});

test("requires chronological dates and a country in the audience step", () => {
    assert.equal(wizard.isStepValid(3, {
        startsAt: "2026-08-25T10:00",
        endsAt: "2026-08-24T10:00",
        country: "BR"
    }), false);
    assert.equal(wizard.isStepValid(3, {
        startsAt: "2026-08-25T10:00",
        endsAt: "2026-11-20T23:59",
        country: "BR"
    }), true);
});

test("requires at least one native placement in the final step", () => {
    assert.equal(wizard.isStepValid(4, { placements: [] }), false);
    assert.equal(wizard.isStepValid(4, { placements: ["rr-home-upcoming-native"] }), true);
});

test("finds the step navigation in the wizard shell outside the form", () => {
    const navigationButtons = [{ step: 1 }, { step: 2 }, { step: 3 }, { step: 4 }];
    const shell = {
        querySelectorAll(selector) {
            assert.equal(selector, "[data-wizard-step-button]");
            return navigationButtons;
        }
    };
    const form = {
        closest(selector) {
            assert.equal(selector, ".ads-wizard-shell");
            return shell;
        }
    };

    assert.deepEqual(wizard.findStepButtons(form), navigationButtons);
});

test("allows direct access to every step while editing", () => {
    assert.equal(wizard.initialMaxReached(false, 1, 4), 4);
    assert.equal(wizard.initialMaxReached(false, 3, 4), 4);
});

test("keeps progressive unlocking for a new campaign", () => {
    assert.equal(wizard.initialMaxReached(true, 1, 4), 1);
    assert.equal(wizard.initialMaxReached(true, 3, 4), 3);
});
