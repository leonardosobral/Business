<cfif NOT structKeyExists(VARIABLES, "adsAccessCanViewZones")>
    <cfinclude template="../../ads/includes/access.cfm"/>
</cfif>
<cfif VARIABLES.adsAccessCanViewZones>
    <li class="sidenav-item">
        <a class="sidenav-link <cfif VARIABLES.template EQ '/ads/gorunners/'>link-warning</cfif>" href="/ads/gorunners/"
           <cfif VARIABLES.template EQ "/ads/gorunners/">aria-current="page"</cfif> data-menu-aliases="zonas patrocinadas mapa jogo">
            <i class="fa-solid fa-map-location-dot fa-fw me-3" aria-hidden="true"></i><span>GoRunners</span>
        </a>
    </li>
</cfif>
