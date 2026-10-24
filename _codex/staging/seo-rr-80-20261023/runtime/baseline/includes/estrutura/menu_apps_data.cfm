<cfscript>
function runnerAppsMenuFallbackData(required any catalog, required string homeUrl) {
        var items = [
            {
                "href" = arguments.homeUrl,
                "target" = "",
                "rel" = "",
                "imgSrc" = "https://roadrunners.run/assets/rr_icon.jpg",
                "imgAlt" = arguments.catalog.roadRunnersAlt,
                "label" = arguments.catalog.roadRunners,
                "labelHtml" = arguments.catalog.roadRunners
            },
            {
                "href" = "https://openresults.run/",
                "target" = "_blank",
                "rel" = "",
                "imgSrc" = "https://roadrunners.run/assets/or_icon.jpg",
                "imgAlt" = arguments.catalog.openResultsAlt,
                "label" = arguments.catalog.openResults,
                "labelHtml" = arguments.catalog.openResults
            },
            {
                "href" = "https://store.roadrunners.run/",
                "target" = "_blank",
                "rel" = "",
                "imgSrc" = "https://roadrunners.run/assets/rrs_icon.jpg",
                "imgAlt" = arguments.catalog.runnersStoreAlt,
                "label" = arguments.catalog.runnersStore,
                "labelHtml" = arguments.catalog.runnersStore
            },
            {
                "href" = "https://circuitobrasilgigante.com.br",
                "target" = "_blank",
                "rel" = "noopener",
                "imgSrc" = "https://roadrunners.run/assets/cbg_icon.png",
                "imgAlt" = arguments.catalog.desafioSupraAlt,
                "label" = arguments.catalog.desafioSupra,
                "labelHtml" = arguments.catalog.desafioSupra
            },
            {
                "href" = "https://roadrunners.run/circuitocatarinense/",
                "target" = "_blank",
                "rel" = "",
                "imgSrc" = "https://roadrunners.run/assets/ico_fca.jpg",
                "imgAlt" = arguments.catalog.circuitoCatarinenseAlt,
                "label" = arguments.catalog.circuitoCatarinense,
                "labelHtml" = arguments.catalog.circuitoCatarinense
            },
            {
                "href" = "https://roadrunners.run/desafio/todosantodia/",
                "target" = "_blank",
                "rel" = "",
                "imgSrc" = "https://roadrunners.run/assets/ico_tsd.jpg",
                "imgAlt" = arguments.catalog.todoSantoDiaAlt,
                "label" = arguments.catalog.todoSantoDia,
                "labelHtml" = replace(arguments.catalog.todoSantoDia, " ", "<br>", "one")
            }
        ];

        var primaryItems = [items[1], items[2], items[3]];
        var secondaryItems = [items[4], items[5], items[6]];

        return {
            "groups" = [
                {
                    "id" = 1,
                    "name" = "Apps Principais",
                    "itemsPerRow" = 3,
                    "items" = primaryItems
                },
                {
                    "id" = 2,
                    "name" = "Apps Secundários",
                    "itemsPerRow" = 3,
                    "items" = secondaryItems
                }
            ],
            "items" = items,
            "poweredBy" = {
                "label" = arguments.catalog.poweredBy,
                "href" = "https://runnerhub.run/",
                "name" = "RunnerHub"
            }
        };
}

function runnerAppsMenuNormalizeItem(required struct item, required string homeUrl) {
        var normalizedItem = duplicate(arguments.item);

        if (!structKeyExists(normalizedItem, "href")) {
            normalizedItem.href = "";
        }
        if (!structKeyExists(normalizedItem, "target")) {
            normalizedItem.target = "";
        }
        if (!structKeyExists(normalizedItem, "rel")) {
            normalizedItem.rel = "";
        }
        if (!structKeyExists(normalizedItem, "imgSrc")) {
            normalizedItem.imgSrc = "";
        }
        if (!structKeyExists(normalizedItem, "imgAlt")) {
            normalizedItem.imgAlt = structKeyExists(normalizedItem, "name") ? normalizedItem.name : "";
        }
        if (!structKeyExists(normalizedItem, "label")) {
            normalizedItem.label = structKeyExists(normalizedItem, "name") ? normalizedItem.name : normalizedItem.imgAlt;
        }
        if (!structKeyExists(normalizedItem, "labelHtml")) {
            normalizedItem.labelHtml = normalizedItem.label;
        }

        if (!len(trim(normalizedItem.href)) OR trim(normalizedItem.href) EQ "/") {
            normalizedItem.href = arguments.homeUrl;
        }

        return normalizedItem;
}

function runnerAppsMenuNormalizePayload(required struct payload, required any catalog, required string homeUrl) {
        var normalizedPayload = {
            "groups" = [],
            "items" = [],
            "poweredBy" = {
                "label" = arguments.catalog.poweredBy,
                "href" = "https://runnerhub.run/",
                "name" = "RunnerHub"
            }
        };
        var menuGroup = {};
        var menuItem = {};
        var normalizedGroup = {};
        var menuItemIndex = 0;

        if (structKeyExists(arguments.payload, "poweredBy") AND isStruct(arguments.payload.poweredBy)) {
            if (structKeyExists(arguments.payload.poweredBy, "href") AND len(trim(arguments.payload.poweredBy.href & ""))) {
                normalizedPayload.poweredBy.href = arguments.payload.poweredBy.href;
            }
            if (structKeyExists(arguments.payload.poweredBy, "name") AND len(trim(arguments.payload.poweredBy.name & ""))) {
                normalizedPayload.poweredBy.name = arguments.payload.poweredBy.name;
            }
        }

        if (structKeyExists(arguments.payload, "groups") AND isArray(arguments.payload.groups) AND arrayLen(arguments.payload.groups)) {
            for (menuGroup in arguments.payload.groups) {
                normalizedGroup = duplicate(menuGroup);

                if (!structKeyExists(normalizedGroup, "items") OR !isArray(normalizedGroup.items)) {
                    normalizedGroup.items = [];
                }
                if (!structKeyExists(normalizedGroup, "itemsPerRow")
                    OR !isNumeric(normalizedGroup.itemsPerRow)
                    OR !listFind("3,4,5", val(normalizedGroup.itemsPerRow))) {
                    normalizedGroup.itemsPerRow = 3;
                } else {
                    normalizedGroup.itemsPerRow = val(normalizedGroup.itemsPerRow);
                }

                for (menuItemIndex = 1; menuItemIndex <= arrayLen(normalizedGroup.items); menuItemIndex++) {
                    normalizedGroup.items[menuItemIndex] = runnerAppsMenuNormalizeItem(normalizedGroup.items[menuItemIndex], arguments.homeUrl);
                    arrayAppend(normalizedPayload.items, normalizedGroup.items[menuItemIndex]);
                }

                if (arrayLen(normalizedGroup.items)) {
                    arrayAppend(normalizedPayload.groups, normalizedGroup);
                }
            }
        } else if (structKeyExists(arguments.payload, "items") AND isArray(arguments.payload.items)) {
            for (menuItem in arguments.payload.items) {
                arrayAppend(normalizedPayload.items, runnerAppsMenuNormalizeItem(menuItem, arguments.homeUrl));
            }

            if (arrayLen(normalizedPayload.items)) {
                arrayAppend(normalizedPayload.groups, {
                    "id" = 1,
                    "name" = "Apps",
                    "itemsPerRow" = 3,
                    "items" = normalizedPayload.items
                });
            }
        }

        return normalizedPayload;
}
</cfscript>

<cfif NOT structKeyExists(REQUEST, "runnerAppsMenuItems")>
    <cfset appsMenuCatalog = REQUEST.i18n.common.appsMenu />
    <cfset menuAppsHomeUrl = REQUEST.currentBaseUrl & REQUEST.i18nBuildPath("home")/>

    <cfset runnerAppsMenuData = runnerAppsMenuFallbackData(appsMenuCatalog, menuAppsHomeUrl)/>

    <cfset REQUEST.runnerAppsMenuGroups = runnerAppsMenuData.groups/>
    <cfset REQUEST.runnerAppsMenuItems = runnerAppsMenuData.items/>
    <cfset REQUEST.runnerAppsMenuPoweredBy = runnerAppsMenuData.poweredBy/>
</cfif>
