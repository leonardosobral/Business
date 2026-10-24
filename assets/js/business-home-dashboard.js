(function () {
    "use strict";

    function init() {
        var root = document.querySelector("[data-business-home]");
        if (!root) return;

        var tablist = root.querySelector("[data-home-tabs]");
        if (!tablist) return;

        var panels = Array.prototype.slice.call(root.querySelectorAll("[data-home-panel]"));
        var areas = Array.prototype.slice.call(tablist.querySelectorAll("[data-home-tab]")).map(function (tab) {
            var key = tab.getAttribute("data-home-tab");
            var panel = panels.find(function (item) {
                return item.getAttribute("data-home-panel") === key;
            });
            return panel ? {key: key, tab: tab, panel: panel} : null;
        }).filter(Boolean);
        if (!areas.length) return;

        var initialArea = areas.find(function (area) { return !area.panel.hidden; }) || areas[0];
        var periodLinks = Array.prototype.slice.call(root.querySelectorAll("[data-home-period]"));

        function findArea(key) {
            return areas.find(function (area) { return area.key === key; });
        }

        function replaceLocation(key, hash) {
            var url = new URL(window.location.href);
            if (key) url.searchParams.set("home_area", key);
            url.hash = hash;
            try {
                window.history.replaceState(window.history.state, "", url.pathname + url.search + url.hash);
            } catch (error) {
                // Restricted browser history must not prevent the local tabs from working.
            }
        }

        function selectArea(selected, focus, updateLocation) {
            areas.forEach(function (area) {
                var active = area === selected;
                area.panel.hidden = !active;
                area.tab.setAttribute("aria-selected", active ? "true" : "false");
                area.tab.tabIndex = active ? 0 : -1;
                area.tab.classList.toggle("is-active", active);
            });
            periodLinks.forEach(function (link) {
                var url = new URL(link.getAttribute("href"), window.location.href);
                url.searchParams.set("home_area", selected.key);
                link.setAttribute("href", url.pathname + url.search + url.hash);
            });
            if (focus) selected.tab.focus();
            if (updateLocation) replaceLocation(selected.key, "business-admin-areas");
        }

        function scrollTo(id) {
            var destination = document.getElementById(id);
            if (destination) destination.scrollIntoView({block: "start"});
        }

        function restoreLocation() {
            var url = new URL(window.location.href);
            var selected = findArea(url.searchParams.get("home_area")) || initialArea;
            var legacyArea = {
                "#business-admin-content": "conteudo",
                "#business-admin-health": "audiencia"
            }[url.hash];
            var directArea = areas.find(function (area) { return "#" + area.panel.id === url.hash; });

            if (legacyArea) selected = findArea(legacyArea) || selected;
            if (directArea) selected = directArea;
            selectArea(selected, false, false);

            if (legacyArea) {
                replaceLocation(selected.key, "business-admin-areas");
                scrollTo("business-admin-areas");
            } else if (url.hash === "#business-admin-payments" || url.hash === "#business-admin-infra") {
                replaceLocation(null, "business-admin-pending");
                scrollTo("business-admin-pending");
            } else if (directArea) {
                scrollTo(directArea.panel.id);
            }
        }

        function modified(event) {
            return event.defaultPrevented || event.altKey || event.ctrlKey || event.metaKey || event.shiftKey;
        }

        tablist.setAttribute("role", "tablist");
        tablist.setAttribute("aria-orientation", "horizontal");
        areas.forEach(function (area, index) {
            area.tab.id = area.tab.id || "home-tab-" + area.key;
            area.panel.id = area.panel.id || "home-area-" + area.key;
            area.tab.setAttribute("role", "tab");
            area.tab.setAttribute("aria-controls", area.panel.id);
            area.tab.removeAttribute("aria-current");
            area.panel.setAttribute("role", "tabpanel");
            area.panel.setAttribute("aria-labelledby", area.tab.id);
            area.panel.tabIndex = 0;

            area.tab.addEventListener("click", function (event) {
                if (modified(event) || event.button !== 0) return;
                event.preventDefault();
                selectArea(area, false, true);
            });

            area.tab.addEventListener("keydown", function (event) {
                if (modified(event)) return;
                var next;
                switch (event.key) {
                    case "ArrowRight": next = (index + 1) % areas.length; break;
                    case "ArrowLeft": next = (index + areas.length - 1) % areas.length; break;
                    case "Home": next = 0; break;
                    case "End": next = areas.length - 1; break;
                    case " ":
                    case "Spacebar": next = index; break;
                    default: return;
                }
                event.preventDefault();
                selectArea(areas[next], true, true);
            });
        });

        restoreLocation();
        window.addEventListener("popstate", restoreLocation);
        window.addEventListener("hashchange", restoreLocation);
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", init, {once: true});
    } else {
        init();
    }
})();
