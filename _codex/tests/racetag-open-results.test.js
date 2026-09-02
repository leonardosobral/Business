const test = require("node:test");
const assert = require("node:assert/strict");

function loadPolicy() {
    try {
        return require("../../assets/js/racetag-open-results.js");
    } catch (error) {
        assert.fail("racetag-open-results.js precisa existir e exportar a politica de processamento");
    }
}

test("classifies boolean, missing and invalid openResultsEnabled values", () => {
    const policy = loadPolicy();

    assert.equal(policy.classify(true, true), "enabled");
    assert.equal(policy.classify(true, false), "disabled");
    assert.equal(policy.classify(false), "missing");
    assert.equal(policy.classify(true, "false"), "invalid");
});

test("blocks a disabled event for external account users", () => {
    const policy = loadPolicy();
    const decision = policy.processingDecision("disabled", false, false);

    assert.equal(decision.allowed, false);
    assert.equal(decision.overrideAvailable, false);
    assert.equal(decision.mode, "blocked");
});

test("requires an explicit internal-admin override for a disabled event", () => {
    const policy = loadPolicy();
    const beforeConfirmation = policy.processingDecision("disabled", true, false);
    const afterConfirmation = policy.processingDecision("disabled", true, true);

    assert.equal(beforeConfirmation.allowed, false);
    assert.equal(beforeConfirmation.overrideAvailable, true);
    assert.equal(afterConfirmation.allowed, true);
    assert.equal(afterConfirmation.mode, "override");
});

test("allows enabled and legacy events without an override", () => {
    const policy = loadPolicy();

    assert.deepEqual(policy.processingDecision("enabled", false, false), {
        allowed: true,
        overrideAvailable: false,
        mode: "standard"
    });
    assert.equal(policy.processingDecision("missing", false, false).allowed, true);
});

test("treats an invalid flag as blocked but overridable by an internal admin", () => {
    const policy = loadPolicy();

    assert.equal(policy.processingDecision("invalid", false, true).allowed, false);
    assert.equal(policy.processingDecision("invalid", true, true).allowed, true);
});

test("event.json prevails over a conflicting persisted API intent", () => {
    const policy = loadPolicy();
    const enabledEvent = policy.effectiveDecision("enabled", false, true, false, false);
    const disabledEvent = policy.effectiveDecision("disabled", true, true, false, false);

    assert.equal(enabledEvent.allowed, true);
    assert.equal(enabledEvent.source, "event_json");
    assert.equal(enabledEvent.divergent, true);
    assert.equal(disabledEvent.allowed, false);
    assert.equal(disabledEvent.source, "event_json");
    assert.equal(disabledEvent.divergent, true);
});

test("falls back to the persisted API intent only when event.json omits the flag", () => {
    const policy = loadPolicy();

    assert.equal(policy.effectiveDecision("missing", false, true, false, false).allowed, false);
    assert.equal(policy.effectiveDecision("missing", true, true, false, false).allowed, true);
    assert.equal(policy.effectiveDecision("missing", true, true, false, false).source, "payload");
    assert.equal(policy.effectiveDecision("missing", false, false, false, false).allowed, true);
    assert.equal(policy.effectiveDecision("missing", false, false, false, false).source, "legacy");
});

test("only an internal administrator can override an effective block", () => {
    const policy = loadPolicy();

    assert.equal(policy.effectiveDecision("invalid", true, true, false, true).allowed, false);
    assert.equal(policy.effectiveDecision("invalid", true, true, true, false).allowed, false);
    assert.equal(policy.effectiveDecision("invalid", true, true, true, true).mode, "override");
    assert.equal(policy.effectiveDecision("missing", false, true, true, true).allowed, true);
});

test("enables the manual override button only after confirmation", () => {
    const policy = loadPolicy();
    const listeners = {};
    const checkbox = {
        checked: false,
        addEventListener(eventName, callback) {
            listeners[eventName] = callback;
        }
    };
    const button = { disabled: false };
    const root = {
        querySelector(selector) {
            if (selector === "[data-racetag-open-results-override]") return checkbox;
            if (selector === "[data-racetag-open-results-force-button]") return button;
            return null;
        }
    };

    policy.initialize(root);
    assert.equal(button.disabled, true);

    checkbox.checked = true;
    listeners.change();
    assert.equal(button.disabled, false);
});
