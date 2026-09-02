const test = require("node:test");
const assert = require("node:assert/strict");

function loadQueue() {
    try {
        return require("../../assets/js/result-import-queue.js");
    } catch (error) {
        assert.fail("result-import-queue.js precisa existir e exportar a regra da fila");
    }
}

test("extracts the RaceTag event slug from the public URL fragment", () => {
    const queue = loadQueue();

    assert.equal(queue.eventHint({
        publicUrl: "https://resultados.exemplo.com/#/mogeiro-run-2026"
    }), "mogeiro-run-2026");
});

test("prefers submitted event identifiers over URL-derived hints", () => {
    const queue = loadQueue();

    assert.equal(queue.eventHint({
        submittedTag: "mogeiro-road-runners",
        externalEventId: "racezone-981",
        publicUrl: "https://resultados.exemplo.com/#/mogeiro-run-2026"
    }), "mogeiro-road-runners");
    assert.equal(queue.eventHint({
        externalEventId: "racezone-981",
        publicUrl: "https://resultados.exemplo.com/#/mogeiro-run-2026"
    }), "racezone-981");
});

test("falls back to the final public URL path segment", () => {
    const queue = loadQueue();

    assert.equal(queue.eventHint({
        publicUrl: "https://resultados.exemplo.com/eventos/t-explore-queimadas-2026/?origem=rr"
    }), "t-explore-queimadas-2026");
});

test("extracts the external ID from a technical event.json URL", () => {
    const queue = loadQueue();

    assert.equal(queue.eventHint({
        dataUrl: "https://resultados.exemplo.com/data/47116/event.json"
    }), "47116");
    assert.equal(queue.eventHint({
        publicUrl: "https://resultados.exemplo.com/data/47116/event.json"
    }), "47116");
});

test("returns no event hint for missing or malformed sources", () => {
    const queue = loadQueue();

    assert.equal(queue.eventHint({}), "");
    assert.equal(queue.eventHint({ publicUrl: "nao-e-url" }), "");
});

test("allows discarding only pending or failed submissions with process permission", () => {
    const queue = loadQueue();

    assert.equal(queue.canDiscard(true, "pendente"), true);
    assert.equal(queue.canDiscard(true, "falhou"), true);
    assert.equal(queue.canDiscard(false, "pendente"), false);
    assert.equal(queue.canDiscard(true, "processando"), false);
    assert.equal(queue.canDiscard(true, "processado"), false);
    assert.equal(queue.canDiscard(true, "cancelado"), false);
});

test("hides cancelled submissions only from the unfiltered queue", () => {
    const queue = loadQueue();

    assert.equal(queue.shouldList("cancelado", ""), false);
    assert.equal(queue.shouldList("cancelado", "cancelado"), true);
    assert.equal(queue.shouldList("pendente", ""), true);
});

test("renders the external event hint in unlinked queue rows", () => {
    const queue = loadQueue();
    const hintElement = {
        dataset: {
            submittedTag: "",
            externalEventId: "",
            publicUrl: "https://resultados.exemplo.com/#/mogeiro-run-2026",
            dataUrl: ""
        },
        textContent: "aguardando identificação"
    };
    const root = {
        querySelectorAll(selector) {
            return selector === "[data-result-import-event-hint]" ? [hintElement] : [];
        }
    };

    queue.initialize(root);

    assert.equal(hintElement.textContent, "Evento externo: mogeiro-run-2026");
});

test("applies discard and default-list rules to queue elements", () => {
    const queue = loadQueue();
    const cancelledRow = { dataset: { status: "cancelado" }, hidden: false };
    const processedForm = {
        dataset: { canProcess: "true", status: "processado" },
        hidden: false
    };
    const root = {
        querySelector(selector) {
            return selector === "[data-result-import-queue]"
                ? { dataset: { selectedStatus: "" } }
                : null;
        },
        querySelectorAll(selector) {
            if (selector === "[data-result-import-row]") {
                return [cancelledRow];
            }
            if (selector === "[data-result-import-discard]") {
                return [processedForm];
            }
            return [];
        }
    };

    queue.initialize(root);

    assert.equal(cancelledRow.hidden, true);
    assert.equal(processedForm.hidden, true);
});
