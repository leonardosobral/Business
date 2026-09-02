(function (root, factory) {
    const api = factory();

    if (typeof module === "object" && module.exports) {
        module.exports = api;
    }

    if (root) {
        root.RaceTagOpenResults = api;
    }
})(typeof window !== "undefined" ? window : globalThis, function () {
    "use strict";

    function classify(present, value) {
        if (!present) return "missing";
        if (value === true) return "enabled";
        if (value === false) return "disabled";
        return "invalid";
    }

    function processingDecision(state, isInternalAdmin, overrideConfirmed) {
        if (state === "enabled" || state === "missing") {
            return {
                allowed: true,
                overrideAvailable: false,
                mode: "standard"
            };
        }

        const overrideAvailable = Boolean(isInternalAdmin)
            && (state === "disabled" || state === "invalid");
        const allowed = overrideAvailable && Boolean(overrideConfirmed);

        return {
            allowed,
            overrideAvailable,
            mode: allowed ? "override" : "blocked"
        };
    }

    function effectiveDecision(
        eventState,
        payloadEnabled,
        hasPersistedPayload,
        isInternalAdmin,
        overrideConfirmed
    ) {
        const state = ["enabled", "disabled", "missing", "invalid"].includes(eventState)
            ? eventState
            : "invalid";
        const hasPayload = Boolean(hasPersistedPayload);
        const normalizedPayloadEnabled = Boolean(payloadEnabled);
        const eventHasBoolean = state === "enabled" || state === "disabled";
        let standardAllowed = false;
        let source = "event_json";

        if (state === "enabled") {
            standardAllowed = true;
        } else if (state === "missing") {
            standardAllowed = hasPayload ? normalizedPayloadEnabled : true;
            source = hasPayload ? "payload" : "legacy";
        }

        const overrideAvailable = !standardAllowed && Boolean(isInternalAdmin);
        const overrideAccepted = overrideAvailable && Boolean(overrideConfirmed);
        const allowed = standardAllowed || overrideAccepted;

        return {
            allowed,
            standardAllowed,
            overrideAvailable,
            overrideAccepted,
            mode: overrideAccepted ? "override" : (standardAllowed ? "standard" : "blocked"),
            source,
            eventState: state,
            payloadEnabled: hasPayload ? normalizedPayloadEnabled : null,
            divergent: eventHasBoolean
                && hasPayload
                && ((state === "enabled") !== normalizedPayloadEnabled)
        };
    }

    function initialize(rootElement) {
        const rootNode = rootElement || document;
        const checkbox = rootNode.querySelector("[data-racetag-open-results-override]");
        const button = rootNode.querySelector("[data-racetag-open-results-force-button]");

        if (!checkbox || !button) return;

        function syncButton() {
            button.disabled = !checkbox.checked;
        }

        checkbox.addEventListener("change", syncButton);
        syncButton();
    }

    return {
        classify,
        processingDecision,
        effectiveDecision,
        initialize
    };
});
