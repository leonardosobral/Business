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

test("suggests ending the campaign three days before the event", () => {
    assert.equal(
        wizard.suggestEndAt("2026-11-23", 3),
        "2026-11-20T23:59"
    );
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
