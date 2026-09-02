(function (root, factory) {
    var api = factory();

    if (typeof module === "object" && module.exports) {
        module.exports = api;
    } else {
        root.BusinessEventRequestPanel = api;
        api.init(root.document, root);
    }
})(typeof window !== "undefined" ? window : this, function () {
    "use strict";

    var panelId = "event-request-panel";
    var panelHash = "#" + panelId;
    var requestLinkSelector = 'a[href$="' + panelHash + '"]';

    function open(panel) {
        if (!panel) {
            return false;
        }

        if (String(panel.tagName || "").toUpperCase() === "DETAILS") {
            panel.open = true;
        }

        if (typeof panel.scrollIntoView === "function") {
            panel.scrollIntoView({ behavior: "smooth", block: "start" });
        }

        var searchInput = typeof panel.querySelector === "function"
            ? panel.querySelector('[name="evento_referencia"]')
            : null;

        if (searchInput && typeof searchInput.focus === "function") {
            searchInput.focus();
        }

        return true;
    }

    function openFromDocument(documentObject) {
        return open(documentObject.getElementById(panelId));
    }

    function updateHash(windowObject) {
        if (!windowObject.history || typeof windowObject.history.replaceState !== "function") {
            return;
        }

        windowObject.history.replaceState(
            null,
            "",
            windowObject.location.pathname + windowObject.location.search + panelHash
        );
    }

    function init(documentObject, windowObject) {
        if (!documentObject || !windowObject) {
            return;
        }

        documentObject.addEventListener("click", function (event) {
            var target = event.target;
            var requestLink = target && typeof target.closest === "function"
                ? target.closest(requestLinkSelector)
                : null;

            if (!requestLink) {
                return;
            }

            event.preventDefault();
            updateHash(windowObject);
            openFromDocument(documentObject);
        });

        function openInitialHash() {
            if (windowObject.location.hash === panelHash) {
                openFromDocument(documentObject);
            }
        }

        if (documentObject.readyState === "loading") {
            documentObject.addEventListener("DOMContentLoaded", openInitialHash);
        } else {
            openInitialHash();
        }
    }

    return {
        init: init,
        open: open
    };
});
