(function (root, factory) {
    var api = factory();

    if (typeof module === "object" && module.exports) {
        module.exports = api;
    } else {
        root.ResultImportQueue = api;
    }
})(typeof globalThis !== "undefined" ? globalThis : this, function () {
    "use strict";

    function normalized(value) {
        return String(value || "").trim();
    }

    function decodeToken(value) {
        try {
            return decodeURIComponent(normalized(value));
        } catch (error) {
            return normalized(value);
        }
    }

    function parseUrl(value) {
        if (!normalized(value)) {
            return null;
        }

        try {
            return new URL(normalized(value));
        } catch (error) {
            return null;
        }
    }

    function lastSegment(value) {
        var segments = normalized(value).replace(/^#/, "").split("/").filter(Boolean);
        return segments.length ? decodeToken(segments[segments.length - 1]) : "";
    }

    function publicUrlHint(value) {
        var parsedUrl = parseUrl(value);

        if (!parsedUrl) {
            return "";
        }

        return lastSegment(parsedUrl.hash)
            || technicalUrlHint(value)
            || lastSegment(parsedUrl.pathname);
    }

    function technicalUrlHint(value) {
        var parsedUrl = parseUrl(value);
        var match = parsedUrl && parsedUrl.pathname.match(/\/data\/([^/]+)\/event\.json\/?$/i);

        return match ? decodeToken(match[1]) : "";
    }

    function eventHint(values) {
        values = values || {};

        return normalized(values.submittedTag)
            || normalized(values.externalEventId)
            || publicUrlHint(values.publicUrl)
            || technicalUrlHint(values.dataUrl);
    }

    function canDiscard(canProcess, status) {
        return Boolean(canProcess) && ["pendente", "falhou"].indexOf(normalized(status).toLowerCase()) >= 0;
    }

    function shouldList(status, selectedStatus) {
        var normalizedStatus = normalized(status).toLowerCase();
        var normalizedFilter = normalized(selectedStatus).toLowerCase();

        return normalizedFilter ? normalizedStatus === normalizedFilter : normalizedStatus !== "cancelado";
    }

    function initialize(rootElement) {
        var rootNode = rootElement || document;
        var queueElement = typeof rootNode.querySelector === "function"
            ? rootNode.querySelector("[data-result-import-queue]")
            : null;
        var selectedStatus = queueElement ? queueElement.dataset.selectedStatus : "";
        var hintElements = rootNode.querySelectorAll("[data-result-import-event-hint]");
        var rowElements = rootNode.querySelectorAll("[data-result-import-row]");
        var discardElements = rootNode.querySelectorAll("[data-result-import-discard]");

        Array.prototype.forEach.call(rowElements, function (element) {
            element.hidden = !shouldList(element.dataset.status, selectedStatus);
        });

        Array.prototype.forEach.call(discardElements, function (element) {
            element.hidden = !canDiscard(element.dataset.canProcess === "true", element.dataset.status);
        });

        Array.prototype.forEach.call(hintElements, function (element) {
            var hint = eventHint({
                submittedTag: element.dataset.submittedTag,
                externalEventId: element.dataset.externalEventId,
                publicUrl: element.dataset.publicUrl,
                dataUrl: element.dataset.dataUrl
            });

            if (hint) {
                element.textContent = "Evento externo: " + hint;
            }
        });
    }

    return {
        eventHint: eventHint,
        canDiscard: canDiscard,
        shouldList: shouldList,
        initialize: initialize
    };
});
