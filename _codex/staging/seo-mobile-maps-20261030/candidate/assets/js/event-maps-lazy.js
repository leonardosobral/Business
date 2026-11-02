(function () {
    "use strict";

    if (window.__rrEventMapsLazyLoaded) {
        return;
    }
    window.__rrEventMapsLazyLoaded = true;

    var script = document.currentScript;
    if (!script) {
        return;
    }

    var librarySource = script.getAttribute("data-mapbox-src") || "";
    var routeSource = script.getAttribute("data-route-src") || "";
    var locationSource = script.getAttribute("data-location-src") || "";
    var scripts = Object.create(null);
    var libraryPromise;

    function allowedSource(source, path) {
        try {
            var url = new URL(source, window.location.href);
            if (url.username || url.password) {
                return "";
            }
            if (path) {
                return url.origin === window.location.origin && url.pathname === path
                    ? url.href : "";
            }
            return url.origin === "https://api.mapbox.com"
                && /^\/mapbox-gl-js\/v\d+\.\d+\.\d+\/mapbox-gl\.js$/.test(url.pathname)
                && !url.search && !url.hash ? url.href : "";
        } catch (error) {
            return "";
        }
    }

    function loadScript(source) {
        if (!source) {
            return Promise.reject(new Error("Map script unavailable"));
        }
        if (!scripts[source]) {
            scripts[source] = new Promise(function (resolve, reject) {
                var node = document.createElement("script");
                var settled = false;
                var timeout;
                function finish(error) {
                    if (settled) {
                        return;
                    }
                    settled = true;
                    window.clearTimeout(timeout);
                    node.onload = null;
                    node.onerror = null;
                    if (error) {
                        reject(error);
                    } else {
                        resolve();
                    }
                }
                node.src = source;
                node.async = true;
                node.onload = function () { finish(); };
                node.onerror = function () { finish(new Error("Map script failed")); };
                timeout = window.setTimeout(function () {
                    finish(new Error("Map script timed out"));
                }, 20000);
                document.head.appendChild(node);
            });
        }
        return scripts[source];
    }

    function loadLibrary() {
        if (window.mapboxgl) {
            return Promise.resolve();
        }
        if (!libraryPromise) {
            // The existing widgets provide their normal fallback without Mapbox.
            libraryPromise = loadScript(allowedSource(librarySource)).catch(function () {});
        }
        return libraryPromise;
    }

    function showUnavailable(root, type) {
        var loading = root.querySelector("[data-event-" + type + "-loading]");
        var unavailable = root.querySelector(type === "route"
            ? "[data-event-route-unavailable]" : "[data-event-location-error]");
        var toolbar = root.querySelector("[data-event-" + type + "-toolbar]");
        var shell = root.querySelector("[data-event-" + type + "-map-shell]");
        if (loading) { loading.hidden = true; }
        if (unavailable) { unavailable.hidden = false; }
        if (toolbar) { toolbar.hidden = true; }
        if (shell && type === "route") { shell.hidden = true; }
    }

    function mount(root, type, source) {
        var started = false;
        var observer;
        var queuedTab;
        source = allowedSource(source, "/assets/js/event-" + type + "-mapbox.min.js");
        root.setAttribute("data-event-map-load", "waiting");

        // Reserve the existing map area while its scripts are deferred.
        if (type === "route") {
            var shell = root.querySelector("[data-event-route-map-shell]");
            var loading = root.querySelector("[data-event-route-loading]");
            if (shell) { shell.hidden = false; }
            if (loading) { loading.hidden = false; }
        }

        function rememberTab(event) {
            var tab = event.target.closest && event.target.closest("[data-event-route-index]");
            if (tab && root.contains(tab)) {
                queuedTab = tab;
            }
            start();
        }

        function cleanup() {
            root.removeEventListener("pointerdown", start);
            root.removeEventListener("focusin", start);
            root.removeEventListener("click", rememberTab);
        }

        function start() {
            if (started) {
                return;
            }
            started = true;
            if (observer) { observer.disconnect(); }
            root.setAttribute("data-event-map-load", "loading");
            loadLibrary().then(function () {
                return loadScript(source);
            }).then(function () {
                root.setAttribute("data-event-map-load", "loaded");
                cleanup();
                // Keep a route chosen while the scripts were still downloading.
                if (queuedTab && root.contains(queuedTab)
                    && queuedTab.getAttribute("aria-selected") !== "true") {
                    queuedTab.click();
                }
            }).catch(function () {
                root.setAttribute("data-event-map-load", "error");
                cleanup();
                showUnavailable(root, type);
            });
        }

        root.addEventListener("pointerdown", start, { passive: true });
        root.addEventListener("focusin", start);
        root.addEventListener("click", rememberTab);
        if (window.IntersectionObserver) {
            try {
                observer = new window.IntersectionObserver(function (entries) {
                    if (entries.some(function (entry) { return entry.isIntersecting; })) {
                        start();
                    }
                }, { rootMargin: "300px 0px" });
                observer.observe(root);
                return;
            } catch (error) {
                // Older browsers still receive the original interactive widgets.
            }
        }
        start();
    }

    function initialize() {
        if (routeSource) {
            document.querySelectorAll("[data-event-route-component]").forEach(function (root) {
                mount(root, "route", routeSource);
            });
        }
        if (locationSource) {
            document.querySelectorAll("[data-event-location-component]").forEach(function (root) {
                mount(root, "location", locationSource);
            });
        }
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", initialize, { once: true });
    } else {
        initialize();
    }
}());
