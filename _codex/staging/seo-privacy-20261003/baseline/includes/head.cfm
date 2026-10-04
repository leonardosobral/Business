<head>

    <cfparam name="VARIABLES.socialImage" default="https://openresults.run/assets/meta_imagem.jpg"/>
    <cfparam name="VARIABLES.twitterImage" default="#VARIABLES.socialImage#"/>

    <!--- REQUIRED META TAGS --->
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1"/>
    <meta name="theme-color" content="#222222" />
    <meta name="msapplication-TileColor" content="#222222" />
    <meta name="application-name" content="Open Results" />
    <meta name="apple-mobile-web-app-capable" content="yes" />
    <meta name="apple-mobile-web-app-status-bar-style" content="default" />
    <meta name="apple-mobile-web-app-title" content="Open Results" />

    <!--- META SEO --->
    <title><cfoutput>#VARIABLES.title#</cfoutput></title>
    <meta name="description" content="<cfoutput>#VARIABLES.description#</cfoutput>" />
    <meta name="keywords" content="<cfoutput>#VARIABLES.keywords#</cfoutput>" />
    <link rel="canonical" href="<cfoutput>#htmlEditFormat(VARIABLES.canonical)#</cfoutput>" />

    <cfif structKeyExists(VARIABLES, "eventSchemaJsonLd") AND len(VARIABLES.eventSchemaJsonLd)>
        <script type="application/ld+json"><cfoutput>#VARIABLES.eventSchemaJsonLd#</cfoutput></script>
    </cfif>

    <!--- SOCIAL MEDIA METADATA --->
    <meta name="twitter:title" content="<cfoutput>#VARIABLES.title#</cfoutput>" />
    <meta name="twitter:card" content="summary" />
    <meta name="twitter:description" content="<cfoutput>#VARIABLES.description#</cfoutput>" />
    <meta name="twitter:image" content="<cfoutput>#VARIABLES.twitterImage#</cfoutput>" />
    <meta name="twitter:site" content="<cfoutput>#htmlEditFormat(VARIABLES.canonical)#</cfoutput>" />

    <!--- OPEN GRAPH METADATA --->
    <meta property="og:type" content="website" />
    <meta property="og:title" content="<cfoutput>#VARIABLES.title#</cfoutput>" />
    <meta property="og:description" content="<cfoutput>#VARIABLES.description#</cfoutput>" />
    <meta property="og:url" content="<cfoutput>#htmlEditFormat(VARIABLES.canonical)#</cfoutput>" />
    <meta property="og:image" content="<cfoutput>#VARIABLES.socialImage#</cfoutput>" />

    <!--- FAVICON --->
    <link rel="shortcut icon" href="/favicon.ico"/>

    <!--- SEO WEBTOOLS SCRIPTS --->
    <cfinclude template="seo-web-tools-head.cfm"/>

</head>
