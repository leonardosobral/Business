<cfset VARIABLES.runnerAppsCatalog = {
    title = "Runners Apps",
    poweredBy = "Powered by"
}/>

<cfset VARIABLES.runnerAppsGroups = [
    [
        {
            label = "Road Runners",
            alt = "Road Runners",
            href = "https://roadrunners.run/?utm_source=openresults&utm_medium=referral&utm_campaign=openresults_to_roadrunners&utm_content=menu_apps_roadrunners",
            placement = "menu_apps_roadrunners",
            outboundPlacement = "menu_apps_roadrunners",
            icon = "https://roadrunners.run/assets/rr_icon.jpg",
            targetBlank = true
        },
        {
            label = "Open Results",
            alt = "Open Results",
            href = "/",
            icon = "https://roadrunners.run/assets/or_icon.jpg",
            targetBlank = false
        },
        {
            label = "Runners Store",
            alt = "Runners Store",
            href = "https://store.roadrunners.run/",
            outboundPlacement = "menu_apps_runners_store",
            icon = "https://roadrunners.run/assets/rrs_icon.jpg",
            targetBlank = true
        }
    ],
    [
        {
            label = "Brasil Gigante",
            alt = "Brasil Gigante",
            href = "https://circuitobrasilgigante.com.br",
            outboundPlacement = "menu_apps_brasil_gigante",
            icon = "https://roadrunners.run/assets/cbg_icon.png",
            targetBlank = true
        },
        {
            label = "Circuito Catarinense",
            alt = "Circuito Catarinense",
            href = "https://roadrunners.run/circuitocatarinense/?utm_source=openresults&utm_medium=referral&utm_campaign=openresults_to_roadrunners&utm_content=menu_apps_circuito_catarinense",
            placement = "menu_apps_circuito_catarinense",
            outboundPlacement = "menu_apps_circuito_catarinense",
            icon = "https://roadrunners.run/assets/ico_fca.jpg",
            targetBlank = true
        },
        {
            label = "Todo<br>Santo Dia",
            alt = "Todo Santo Dia",
            href = "https://roadrunners.run/desafio/todosantodia/?utm_source=openresults&utm_medium=referral&utm_campaign=openresults_to_roadrunners&utm_content=menu_apps_todo_santo_dia",
            placement = "menu_apps_todo_santo_dia",
            outboundPlacement = "menu_apps_todo_santo_dia",
            icon = "https://roadrunners.run/assets/ico_tsd.jpg",
            targetBlank = true
        }
    ]
]/>

<div class="btn-group shadow-0">

    <a href="#"
       class="link-dark"
       data-mdb-dropdown-init
       aria-expanded="false"
       aria-label="<cfoutput>#VARIABLES.runnerAppsCatalog.title#</cfoutput>"
       title="<cfoutput>#VARIABLES.runnerAppsCatalog.title#</cfoutput>"
       id="dropdownMenuApps">
        <i class="fas fa-grip"></i>
    </a>

    <ul class="dropdown-menu dropdown-menu-lg-end w-200px bg-white p-0" style="z-index: 99999" aria-labelledby="dropdownMenuApps">

        <li class="bg-dark bg-opacity-10">
            <span class="dropdown-header text-center"><cfoutput>#VARIABLES.runnerAppsCatalog.title#</cfoutput></span>
        </li>

        <cfloop from="1" to="#arrayLen(VARIABLES.runnerAppsGroups)#" index="runnerAppsGroupIndex">
            <cfset runnerAppsGroup = VARIABLES.runnerAppsGroups[runnerAppsGroupIndex]/>

            <div class="row px-3 py-2 small<cfif arrayLen(runnerAppsGroup) GT 1> g-2</cfif>">
                <cfloop array="#runnerAppsGroup#" index="runnerApp">
                    <div class="col-4 p-0 text-center lh-1 align-content-center" style="font-size: 0.7rem">
                        <cfoutput>
                            <a href="#encodeForHTMLAttribute(runnerApp.href)#" class="w-50px link-dark link-underline-opacity-0"<cfif runnerApp.targetBlank> target="_blank" rel="noopener"</cfif><cfif structKeyExists(runnerApp, "placement")> data-rr-placement="#runnerApp.placement#"</cfif><cfif structKeyExists(runnerApp, "outboundPlacement")> data-outbound-placement="#encodeForHTMLAttribute(runnerApp.outboundPlacement)#"</cfif>>
                                <img class="rounded-3 bg-black w-50px mb-1" src="#runnerApp.icon#" alt="#runnerApp.alt#"/>
                                #runnerApp.label#
                            </a>
                        </cfoutput>
                    </div>
                </cfloop>
            </div>

            <cfif runnerAppsGroupIndex LT arrayLen(VARIABLES.runnerAppsGroups)>
                <li>
                    <hr class="hr dropdown-divider m-0">
                </li>
            </cfif>
        </cfloop>

        <li>
            <hr class="hr dropdown-divider m-0">
        </li>

        <li class="small text-center p-1">
            <small class="opacity-35">
                <cfoutput>#VARIABLES.runnerAppsCatalog.poweredBy#</cfoutput>
                <a href="https://runnerhub.run/" class="link-dark link-underline-opacity-0" target="_blank" rel="noopener" data-outbound-placement="menu_apps_powered_by">
                    RunnerHub
                </a>
            </small>
        </li>

    </ul>

</div>
