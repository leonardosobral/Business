<cfset appsMenuCatalog = REQUEST.i18n.common.appsMenu />
<cfset menuAppsHomeUrl = REQUEST.currentBaseUrl & REQUEST.i18nBuildPath("home")/>
<cfinclude template="menu_apps_data.cfm" />

<cfif NOT structKeyExists(REQUEST, "runnerAppsMenuGroups") OR NOT isArray(REQUEST.runnerAppsMenuGroups) OR NOT arrayLen(REQUEST.runnerAppsMenuGroups)>
    <cfset REQUEST.runnerAppsMenuGroups = [
        {
            "id" = 1,
            "name" = "Apps",
            "itemsPerRow" = 3,
            "items" = REQUEST.runnerAppsMenuItems
        }
    ]/>
</cfif>

<cfset menuAppItemsPerRow = 3/>
<cfloop array="#REQUEST.runnerAppsMenuGroups#" index="menuAppGroup">
    <cfif structKeyExists(menuAppGroup, "items") AND isArray(menuAppGroup.items) AND arrayLen(menuAppGroup.items)>
        <cfset menuAppItemsPerRow = structKeyExists(menuAppGroup, "itemsPerRow") AND listFind("3,4,5", val(menuAppGroup.itemsPerRow)) ? val(menuAppGroup.itemsPerRow) : 3/>
        <cfbreak/>
    </cfif>
</cfloop>
<cfset menuAppDropdownWidth = max(200, (menuAppItemsPerRow * 58) + 24)/>

<!--- APPS --->

<div class="btn-group ms-3 shadow-0">

    <a href="#"
       class="link-light link-opacity-50 link-opacity-100-hover"
       data-mdb-dropdown-init
       data-runner-apps-toggle
       aria-expanded="false"
       aria-label="<cfoutput>#appsMenuCatalog.title#</cfoutput>"
       title="<cfoutput>#appsMenuCatalog.title#</cfoutput>"
       id="dropdownMenuApps">
        <i class="fas fa-grip"></i>
    </a>

    <ul class="dropdown-menu dropdown-menu-lg-end bg-white p-0" style="z-index: 99999; width: <cfoutput>#menuAppDropdownWidth#</cfoutput>px; min-width: <cfoutput>#menuAppDropdownWidth#</cfoutput>px" aria-labelledby="dropdownMenuApps" data-runner-apps-menu data-runner-apps-endpoint="/api/runner_apps_menu.cfm">

        <li class="bg-dark bg-opacity-10">
            <span class="dropdown-header text-center"><cfoutput>#appsMenuCatalog.title#</cfoutput></span>
        </li>

        <cfoutput>
            <div class="px-3 py-2 small gap-2" data-runner-apps-grid style="display: grid; grid-template-columns: repeat(#menuAppItemsPerRow#, minmax(0, 1fr));">
                <cfloop array="#REQUEST.runnerAppsMenuItems#" index="menuApp">
                    <div class="p-0 text-center lh-1 align-content-center" style="font-size: 0.7rem">
                        <a href="#menuApp.href#"<cfif len(menuApp.target)> target="#menuApp.target#"</cfif><cfif len(menuApp.rel)> rel="#menuApp.rel#"</cfif> class="w-100 mx-auto d-flex flex-column align-items-center text-center link-dark link-underline-opacity-0">
                            <img class="rounded-3 bg-black w-50px mb-1" src="#menuApp.imgSrc#" alt="#menuApp.imgAlt#"/>
                            <span class="d-block w-100 text-center">#menuApp.labelHtml#</span>
                        </a>
                    </div>
                </cfloop>
            </div>
        </cfoutput>

        <!---<li class="small"><hr class="hr dropdown-divider m-0"></li>--->
        <!---<li class="small"><a class="dropdown-item link-opacity-25-hover" href="https://roadrunners.run/maratonas/">Maratonas no Brasil</a></li>--->
        <!---<li><a class="dropdown-item" href="/desafiosupra/" target="_blank">Ranking Supra</a></li>--->
        <!---<li><a class="dropdown-item" href="/desafiocna/" target="_blank">Desafio 365</a></li>--->
        <!---<li><a class="dropdown-item" href="/internacionais/">Eventos no exterior</a></li>--->
        <!---<li><hr class="dropdown-divider m-0"></li>--->
        <!---<li><div class="dropdown-item link"  data-mdb-modal-init data-mdb-target="#modal_evento_cadastro">Sugerir evento</div></li>--->

        <li>
            <hr class="hr dropdown-divider m-0">
        </li>

        <li class="small text-center p-1" data-runner-apps-powered-by>
            <small class="opacity-35">
                <span data-runner-apps-powered-label><cfoutput>#REQUEST.runnerAppsMenuPoweredBy.label#</cfoutput></span>
                <a href="<cfoutput>#REQUEST.runnerAppsMenuPoweredBy.href#</cfoutput>" class="link-dark link-underline-opacity-0" target="_blank" rel="noopener" data-runner-apps-powered-link>
                    <cfoutput>#REQUEST.runnerAppsMenuPoweredBy.name#</cfoutput>
                </a>
            </small>
        </li>

    </ul>

</div>

<cfif NOT structKeyExists(REQUEST, "runnerAppsMenuLazyScriptLoaded")>
    <cfset REQUEST.runnerAppsMenuLazyScriptLoaded = true/>
    <script defer src="/assets/js/runner-apps-menu-lazy.min.js?v=20261008seo"></script>
</cfif>
