(function (root, factory) {
    var api = factory();

    if (typeof module === "object" && module.exports) {
        module.exports = api;
    } else {
        root.BusinessSidenav = api;
    }
})(typeof globalThis !== "undefined" ? globalThis : this, function () {
    "use strict";

    function normalizeText(value) {
        return String(value || "")
            .toLowerCase()
            .normalize("NFD")
            .replace(/[\u0300-\u036f]/g, "")
            .replace(/\s+/g, " ")
            .trim();
    }

    function sectionKey(label) {
        return normalizeText(label)
            .replace(/\s+/g, "-")
            .replace(/[^a-z0-9-]/g, "");
    }

    function chooseInitialSection(options) {
        return options.activeSection || options.persistedSection || options.defaultSection || "";
    }

    function nextExpandedSection(currentSection, selectedSection) {
        return currentSection === selectedSection ? "" : selectedSection;
    }

    function matchesMenuItem(label, aliases, query) {
        var terms = normalizeText(query).split(" ").filter(Boolean);
        var haystack = normalizeText(label + " " + aliases);

        return terms.length > 0 && terms.every(function (term) {
            return haystack.indexOf(term) >= 0;
        });
    }

    function safelyRead(storageKey, fallbackValue) {
        try {
            var storedValue = window.localStorage.getItem(storageKey);
            return storedValue ? JSON.parse(storedValue) : fallbackValue;
        } catch (error) {
            return fallbackValue;
        }
    }

    function safelyWrite(storageKey, value) {
        try {
            window.localStorage.setItem(storageKey, JSON.stringify(value));
        } catch (error) {}
    }

    function sectionItems(headingItem) {
        var items = [];
        var currentItem = headingItem.nextElementSibling;

        while (currentItem && !currentItem.querySelector(".sidenav-subheading")) {
            items.push(currentItem);
            currentItem = currentItem.nextElementSibling;
        }

        return items;
    }

    function setSectionState(section, expanded) {
        section.button.setAttribute("aria-expanded", expanded ? "true" : "false");
        section.items.forEach(function (item) {
            item.classList.toggle("business-sidenav-section-collapsed", !expanded);
        });
    }

    function buildSections(sidenavMenu) {
        var headings = Array.prototype.slice.call(sidenavMenu.querySelectorAll(".sidenav-subheading"));

        return headings.map(function (heading) {
            var headingItem = heading.closest(".sidenav-item");
            var label = heading.textContent.trim();
            var button = document.createElement("button");
            var labelSpan = document.createElement("span");
            var icon = document.createElement("i");
            var section = {
                headingItem: headingItem,
                items: sectionItems(headingItem),
                key: sectionKey(label),
                label: label,
                button: button
            };

            button.type = "button";
            button.className = "business-sidenav-section-toggle";
            labelSpan.textContent = label;
            icon.className = "fa-solid fa-chevron-down business-sidenav-section-icon";
            icon.setAttribute("aria-hidden", "true");
            button.appendChild(labelSpan);
            button.appendChild(icon);
            heading.replaceWith(button);

            section.items.forEach(function (item) {
                item.setAttribute("data-business-sidenav-section", section.key);
            });

            return section;
        });
    }

    function activeSectionKey(sections) {
        var activeSection = sections.find(function (section) {
            return section.items.some(function (item) {
                return Boolean(item.querySelector(".sidenav-link.link-warning"));
            });
        });

        return activeSection ? activeSection.key : "";
    }

    function setSearchVisibility(item, visible) {
        item.classList.toggle("business-sidenav-search-hidden", !visible);
    }

    function updateSubgroupVisibility(section) {
        var currentSubgroup = null;
        var currentHasMatch = false;

        function finishSubgroup() {
            if (currentSubgroup) {
                setSearchVisibility(currentSubgroup, currentHasMatch);
            }
        }

        section.items.forEach(function (item) {
            if (item.classList.contains("business-sidenav-subgroup-label")) {
                finishSubgroup();
                currentSubgroup = item;
                currentHasMatch = false;
            } else if (!item.classList.contains("business-sidenav-search-hidden")) {
                currentHasMatch = true;
            }
        });

        finishSubgroup();
    }

    function initSearch(options, sections) {
        var input = document.querySelector(options.searchInputSelector || "#business-sidenav-search-input");
        var emptyState = document.querySelector(options.searchEmptySelector || "#business-sidenav-search-empty");

        if (!options.isAdmin || options.isPending || !input) {
            return;
        }

        function filterMenu() {
            var query = input.value;
            var totalMatches = 0;

            sections.forEach(function (section) {
                var sectionMatches = 0;

                section.items.forEach(function (item) {
                    if (item.classList.contains("business-sidenav-subgroup-label")) {
                        setSearchVisibility(item, false);
                        return;
                    }

                    var link = item.querySelector(".sidenav-link");
                    var visible = !normalizeText(query) || (link && matchesMenuItem(
                        link.textContent,
                        link.getAttribute("data-menu-aliases") || "",
                        query
                    ));

                    setSearchVisibility(item, visible);
                    if (visible && normalizeText(query)) {
                        sectionMatches += 1;
                    }
                });

                if (normalizeText(query)) {
                    updateSubgroupVisibility(section);
                    setSearchVisibility(section.headingItem, sectionMatches > 0);
                    setSectionState(section, sectionMatches > 0);
                    totalMatches += sectionMatches;
                } else {
                    section.headingItem.classList.remove("business-sidenav-search-hidden");
                    section.items.forEach(function (item) {
                        item.classList.remove("business-sidenav-search-hidden");
                    });
                }
            });

            if (!normalizeText(query)) {
                options.restoreSections();
            }

            if (emptyState) {
                emptyState.classList.toggle("business-sidenav-search-hidden", !normalizeText(query) || totalMatches > 0);
            }
        }

        input.addEventListener("input", filterMenu);
        input.addEventListener("keydown", function (event) {
            if (event.key === "Escape") {
                input.value = "";
                filterMenu();
                input.blur();
            }
        });

        document.addEventListener("keydown", function (event) {
            if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k") {
                event.preventDefault();
                input.focus();
                input.select();
            }
        });
    }

    function initialize(options) {
        var sidenavMenu = document.querySelector(options.menuSelector || "#main-sidenav .sidenav-menu");

        if (!sidenavMenu) {
            return;
        }

        var sections = buildSections(sidenavMenu);
        var isSingleSectionMode = options.isAdmin && !options.isPending;
        var defaultSections = options.defaultExpandedSections || [];
        var state = safelyRead(options.storageKey, isSingleSectionMode ? "" : {});
        var expandedSection = isSingleSectionMode
            ? chooseInitialSection({
                activeSection: activeSectionKey(sections),
                persistedSection: typeof state === "string" ? state : "",
                defaultSection: defaultSections[0] || ""
            })
            : "";

        function restoreSections() {
            sections.forEach(function (section) {
                var expanded = isSingleSectionMode
                    ? section.key === expandedSection
                    : (Object.prototype.hasOwnProperty.call(state, section.key)
                        ? Boolean(state[section.key])
                        : defaultSections.indexOf(section.key) >= 0);
                setSectionState(section, expanded);
            });
        }

        sections.forEach(function (section) {
            section.button.addEventListener("click", function () {
                if (isSingleSectionMode) {
                    expandedSection = nextExpandedSection(expandedSection, section.key);
                    safelyWrite(options.storageKey, expandedSection);
                } else {
                    state[section.key] = section.button.getAttribute("aria-expanded") !== "true";
                    safelyWrite(options.storageKey, state);
                }

                restoreSections();
            });
        });

        restoreSections();
        initSearch({
            isAdmin: options.isAdmin,
            isPending: options.isPending,
            searchInputSelector: options.searchInputSelector,
            searchEmptySelector: options.searchEmptySelector,
            restoreSections: restoreSections
        }, sections);
    }

    function init(options) {
        if (typeof document === "undefined") {
            return;
        }

        if (document.readyState === "loading") {
            document.addEventListener("DOMContentLoaded", function () {
                initialize(options);
            }, { once: true });
        } else {
            initialize(options);
        }
    }

    return {
        chooseInitialSection: chooseInitialSection,
        init: init,
        matchesMenuItem: matchesMenuItem,
        nextExpandedSection: nextExpandedSection,
        normalizeText: normalizeText,
        sectionKey: sectionKey
    };
});
