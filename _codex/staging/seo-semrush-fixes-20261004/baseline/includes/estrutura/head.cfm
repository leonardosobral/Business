<head>
    <cfparam name="VARIABLES.metaType" default="website"/>
    <cfparam name="VARIABLES.metaImage" default=""/>
    <cfparam name="VARIABLES.metaImageAlt" default=""/>
    <cfparam name="VARIABLES.metaPublishedTime" default=""/>
    <cfparam name="VARIABLES.metaModifiedTime" default=""/>
    <cfparam name="VARIABLES.twitterCard" default="summary"/>
    <cfparam name="VARIABLES.structuredDataJsonLd" default=""/>
    <cfparam name="VARIABLES.metaRobots" default=""/>
    <cfparam name="VARIABLES.rrSharedAssetBaseUrl" default=""/>
    <cfparam name="VARIABLES.includePwaAssets" default="true"/>
    <cfparam name="VARIABLES.includeHreflang" type="boolean" default="true"/>
    <cfset VARIABLES.rrSharedAssetBaseUrl = reReplace(trim(VARIABLES.rrSharedAssetBaseUrl & ""), "/+$", "")/>

    <!--- REQUIRED META TAGS --->
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1"/>
    <meta name="theme-color" content="#222222" />
    <meta name="msapplication-TileColor" content="#222222" />
    <meta name="application-name" content="Road Runners" />
    <meta name="apple-mobile-web-app-capable" content="yes" />
    <meta name="apple-mobile-web-app-status-bar-style" content="default" />
    <meta name="apple-mobile-web-app-title" content="Road Runners" />

    <!--- META SEO --->
    <title><cfoutput>#VARIABLES.title#</cfoutput></title>
    <meta name="description" content="<cfoutput>#VARIABLES.description#</cfoutput>" />
    <meta name="keywords" content="<cfoutput>#VARIABLES.keywords#</cfoutput>" />
    <cfif len(trim(VARIABLES.metaRobots))>
        <meta name="robots" content="<cfoutput>#HTMLEditFormat(VARIABLES.metaRobots)#</cfoutput>" />
    </cfif>
    <cfif structKeyExists(APPLICATION, "seoVerification") AND isStruct(APPLICATION.seoVerification)>
        <cfif structKeyExists(APPLICATION.seoVerification, "google") AND len(trim(APPLICATION.seoVerification.google & ""))>
            <meta name="google-site-verification" content="<cfoutput>#HTMLEditFormat(APPLICATION.seoVerification.google)#</cfoutput>" />
        </cfif>
        <cfif structKeyExists(APPLICATION.seoVerification, "bing") AND len(trim(APPLICATION.seoVerification.bing & ""))>
            <meta name="msvalidate.01" content="<cfoutput>#HTMLEditFormat(APPLICATION.seoVerification.bing)#</cfoutput>" />
        </cfif>
    </cfif>
    <link rel="canonical" href="<cfoutput>#HTMLEditFormat(VARIABLES.canonical)#</cfoutput>" />
    <cfif VARIABLES.includeHreflang AND structKeyExists(REQUEST, "currentRouteKey") AND len(trim(REQUEST.currentRouteKey))>
        <cfloop array="#REQUEST.availableLanguages#" index="languageOption">
            <cfoutput><link rel="alternate" hreflang="#languageOption.hreflang#" href="#HTMLEditFormat(REQUEST.i18nBuildAbsoluteUrl(REQUEST.currentRouteKey, languageOption.code))#" /></cfoutput>
        </cfloop>
        <cfoutput><link rel="alternate" hreflang="x-default" href="#HTMLEditFormat(REQUEST.i18nBuildAbsoluteUrl(REQUEST.currentRouteKey, 'pt-BR'))#" /></cfoutput>
    </cfif>

    <!--- SOCIAL MEDIA METADATA --->
    <meta name="twitter:title" content="<cfoutput>#VARIABLES.title#</cfoutput>" />
    <meta name="twitter:card" content="<cfoutput>#VARIABLES.twitterCard#</cfoutput>" />
    <meta name="twitter:description" content="<cfoutput>#VARIABLES.description#</cfoutput>" />
    <cfif len(trim(VARIABLES.metaImage))>
            <meta name="twitter:image" content="<cfoutput>#VARIABLES.metaImage#</cfoutput>" />
            <cfif len(trim(VARIABLES.metaImageAlt))>
                <meta name="twitter:image:alt" content="<cfoutput>#VARIABLES.metaImageAlt#</cfoutput>" />
            </cfif>
    <cfelseif template EQ "/atleta/">
            <meta name="twitter:image" content="<cfoutput>#qPagina.imagem_usuario#</cfoutput>" onerror="this.content='https://roadrunners.run/assets/user.png';" />
    <cfelse>
            <meta name="twitter:image" content="https://roadrunners.run/assets/meta_imagem.jpg" />
    </cfif>
    <meta name="twitter:site" content="<cfoutput>#HTMLEditFormat(VARIABLES.canonical)#</cfoutput>" />

    <!--- OPEN GRAPH METADATA --->
    <meta property="og:type" content="<cfoutput>#VARIABLES.metaType#</cfoutput>" />
    <meta property="og:title" content="<cfoutput>#VARIABLES.title#</cfoutput>" />
    <meta property="og:description" content="<cfoutput>#VARIABLES.description#</cfoutput>" />
    <meta property="og:url" content="<cfoutput>#HTMLEditFormat(VARIABLES.canonical)#</cfoutput>" />
    <meta property="og:site_name" content="<cfoutput>#APPLICATION.nomeSite#</cfoutput>" />
    <cfif len(trim(VARIABLES.metaImage))>
        <meta property="og:image" content="<cfoutput>#VARIABLES.metaImage#</cfoutput>" />
        <cfif len(trim(VARIABLES.metaImageAlt))>
            <meta property="og:image:alt" content="<cfoutput>#VARIABLES.metaImageAlt#</cfoutput>" />
        </cfif>
    <cfelseif template EQ "/atleta/">
        <meta property="og:image" content="<cfoutput>#qPagina.imagem_usuario#</cfoutput>" onerror="this.content='https://roadrunners.run/assets/user.png';" />
    <cfelse>
        <meta property="og:image" content="https://roadrunners.run/assets/meta/roadrunners.jpg"/>
    </cfif>
    <cfif VARIABLES.metaType EQ "article" AND len(trim(VARIABLES.metaPublishedTime))>
        <meta property="article:published_time" content="<cfoutput>#VARIABLES.metaPublishedTime#</cfoutput>" />
    </cfif>
    <cfif VARIABLES.metaType EQ "article" AND len(trim(VARIABLES.metaModifiedTime))>
        <meta property="article:modified_time" content="<cfoutput>#VARIABLES.metaModifiedTime#</cfoutput>" />
    </cfif>
    <cfif len(trim(VARIABLES.structuredDataJsonLd))>
        <script type="application/ld+json"><cfoutput>#replace(VARIABLES.structuredDataJsonLd, "<", "\u003C", "all")#</cfoutput></script>
    </cfif>

    <!--- FAVICON --->
    <cfoutput><link rel="shortcut icon" href="#VARIABLES.rrSharedAssetBaseUrl#/favicon.ico"/></cfoutput>
    <cfif VARIABLES.includePwaAssets>
        <cfoutput>
            <link rel="apple-touch-icon" sizes="180x180" href="#VARIABLES.rrSharedAssetBaseUrl#/assets/pwa/apple-touch-icon.png?v=brand2"/>
            <link rel="apple-touch-icon" sizes="167x167" href="#VARIABLES.rrSharedAssetBaseUrl#/assets/pwa/apple-touch-icon-167.png?v=brand2"/>
            <link rel="apple-touch-icon" sizes="152x152" href="#VARIABLES.rrSharedAssetBaseUrl#/assets/pwa/apple-touch-icon-152.png?v=brand2"/>
            <link rel="apple-touch-icon" sizes="120x120" href="#VARIABLES.rrSharedAssetBaseUrl#/assets/pwa/apple-touch-icon-120.png?v=brand2"/>
            <link rel="apple-touch-startup-image" href="#VARIABLES.rrSharedAssetBaseUrl#/assets/pwa/startup/rr-startup-1290x2796.png?v=brand2" media="(device-width: 430px) and (device-height: 932px) and (-webkit-device-pixel-ratio: 3) and (orientation: portrait)"/>
            <link rel="apple-touch-startup-image" href="#VARIABLES.rrSharedAssetBaseUrl#/assets/pwa/startup/rr-startup-1179x2556.png?v=brand2" media="(device-width: 393px) and (device-height: 852px) and (-webkit-device-pixel-ratio: 3) and (orientation: portrait)"/>
            <link rel="apple-touch-startup-image" href="#VARIABLES.rrSharedAssetBaseUrl#/assets/pwa/startup/rr-startup-1284x2778.png?v=brand2" media="(device-width: 428px) and (device-height: 926px) and (-webkit-device-pixel-ratio: 3) and (orientation: portrait)"/>
            <link rel="apple-touch-startup-image" href="#VARIABLES.rrSharedAssetBaseUrl#/assets/pwa/startup/rr-startup-1170x2532.png?v=brand2" media="(device-width: 390px) and (device-height: 844px) and (-webkit-device-pixel-ratio: 3) and (orientation: portrait)"/>
            <link rel="apple-touch-startup-image" href="#VARIABLES.rrSharedAssetBaseUrl#/assets/pwa/startup/rr-startup-1125x2436.png?v=brand2" media="(device-width: 375px) and (device-height: 812px) and (-webkit-device-pixel-ratio: 3) and (orientation: portrait)"/>
            <link rel="apple-touch-startup-image" href="#VARIABLES.rrSharedAssetBaseUrl#/assets/pwa/startup/rr-startup-1242x2688.png?v=brand2" media="(device-width: 414px) and (device-height: 896px) and (-webkit-device-pixel-ratio: 3) and (orientation: portrait)"/>
            <link rel="apple-touch-startup-image" href="#VARIABLES.rrSharedAssetBaseUrl#/assets/pwa/startup/rr-startup-828x1792.png?v=brand2" media="(device-width: 414px) and (device-height: 896px) and (-webkit-device-pixel-ratio: 2) and (orientation: portrait)"/>
            <link rel="apple-touch-startup-image" href="#VARIABLES.rrSharedAssetBaseUrl#/assets/pwa/startup/rr-startup-750x1334.png?v=brand2" media="(device-width: 375px) and (device-height: 667px) and (-webkit-device-pixel-ratio: 2) and (orientation: portrait)"/>
            <link rel="apple-touch-startup-image" href="#VARIABLES.rrSharedAssetBaseUrl#/assets/pwa/startup/rr-startup-640x1136.png?v=brand2" media="(device-width: 320px) and (device-height: 568px) and (-webkit-device-pixel-ratio: 2) and (orientation: portrait)"/>
            <link rel="apple-touch-startup-image" href="#VARIABLES.rrSharedAssetBaseUrl#/assets/pwa/startup/rr-startup-2048x2732.png?v=brand2" media="(device-width: 1024px) and (device-height: 1366px) and (-webkit-device-pixel-ratio: 2) and (orientation: portrait)"/>
            <link rel="apple-touch-startup-image" href="#VARIABLES.rrSharedAssetBaseUrl#/assets/pwa/startup/rr-startup-1668x2388.png?v=brand2" media="(device-width: 834px) and (device-height: 1194px) and (-webkit-device-pixel-ratio: 2) and (orientation: portrait)"/>
            <link rel="apple-touch-startup-image" href="#VARIABLES.rrSharedAssetBaseUrl#/assets/pwa/startup/rr-startup-1640x2360.png?v=brand2" media="(device-width: 820px) and (device-height: 1180px) and (-webkit-device-pixel-ratio: 2) and (orientation: portrait)"/>
            <link rel="apple-touch-startup-image" href="#VARIABLES.rrSharedAssetBaseUrl#/assets/pwa/startup/rr-startup-1536x2048.png?v=brand2" media="(device-width: 768px) and (device-height: 1024px) and (-webkit-device-pixel-ratio: 2) and (orientation: portrait)"/>
            <link rel="manifest" href="#VARIABLES.rrSharedAssetBaseUrl#/manifest.webmanifest?v=brand2"/>
        </cfoutput>
    </cfif>

    <!--- SEO WEBTOOLS SCRIPTS --->
    <cfinclude template="seo-web-tools-head.cfm"/>

    <cfif structKeyExists(VARIABLES, "eventMapboxAssets") AND VARIABLES.eventMapboxAssets>
        <cfoutput>
            <link rel="stylesheet" href="https://api.mapbox.com/mapbox-gl-js/v#APPLICATION.eventRouteMapbox.libraryVersion#/mapbox-gl.css"/>
        </cfoutput>
    </cfif>
    <cfif structKeyExists(VARIABLES, "eventRouteMapboxAssets") AND VARIABLES.eventRouteMapboxAssets>
        <link rel="stylesheet" href="/assets/css/event-route-mapbox.css?v=20260726-21"/>
    </cfif>
    <cfif structKeyExists(VARIABLES, "eventLocationAssets") AND VARIABLES.eventLocationAssets>
        <link rel="stylesheet" href="/assets/css/event-location-mapbox.css?v=20260727-2"/>
    </cfif>

</head>
