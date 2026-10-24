<!--- Rodape compartilhado do portal. Preserva as integracoes do layout legado. --->
<cfinclude template="footer_assets.cfm"/>
<cfif structKeyExists(REQUEST, "Usuario")>
    <cfset Usuario = REQUEST.Usuario/>
<cfelse>
    <cfset Usuario = createObject("component", "includes.models.Usuario").init()/>
    <cfset REQUEST.Usuario = Usuario/>
</cfif>
<!--- Evita expor chaves de i18n quando uma pagina ainda estiver usando um catalogo antigo em memoria. --->
<cfset VARIABLES.rrFooterFallbacks = {
    "pt-BR" = {
        "tagline" = "O ponto de encontro da corrida.",
        "description" = "Provas, resultados, histórias e pessoas. Tudo o que move a sua corrida, em um só lugar.",
        "explore" = "Explore",
        "athletes" = "Para o atleta",
        "institutional" = "Road Runners",
        "events" = "Encontre o que procura",
        "activities" = "Atividades",
        "results" = "Meus resultados",
        "news" = "Notícias",
        "videos" = "Vídeos",
        "profile" = "Meu perfil",
        "agenda" = "Minha agenda",
        "challenges" = "Meus desafios",
        "about" = "Sobre o Road Runners",
        "help" = "Central de ajuda",
        "support" = "Fale com a gente",
        "terms" = "Termos de Uso",
        "privacy" = "Privacidade e dados",
        "ecosystem" = "Mais conexões para sua corrida",
        "ecosystemLabel" = "Ecossistema RunnerHub",
        "follow" = "Corra com a comunidade",
        "rights" = "Todos os direitos reservados.",
        "navigationLabel" = "Navegação do rodapé",
        "socialLabel" = "Redes sociais do Road Runners",
        "top" = "Voltar ao topo",
        "companyDocument" = "CNPJ",
        "backToTop" = "Topo"
    },
    "en" = {
        "tagline" = "The meeting point for running.",
        "description" = "Races, results, stories and people. Everything that keeps you running, all in one place.",
        "explore" = "Explore",
        "athletes" = "For athletes",
        "institutional" = "Road Runners",
        "events" = "Find what you are looking for",
        "activities" = "Activities",
        "results" = "My results",
        "news" = "News",
        "videos" = "Videos",
        "profile" = "My profile",
        "agenda" = "My calendar",
        "challenges" = "My challenges",
        "about" = "About Road Runners",
        "help" = "Help center",
        "support" = "Get in touch",
        "terms" = "Terms of Use",
        "privacy" = "Privacy and data",
        "ecosystem" = "More connections for your running journey",
        "ecosystemLabel" = "RunnerHub ecosystem",
        "follow" = "Run with the community",
        "rights" = "All rights reserved.",
        "navigationLabel" = "Footer navigation",
        "socialLabel" = "Road Runners social media",
        "top" = "Back to top",
        "companyDocument" = "Company ID",
        "backToTop" = "Top"
    },
    "es" = {
        "tagline" = "El punto de encuentro del running.",
        "description" = "Carreras, resultados, historias y personas. Todo lo que te impulsa a correr, en un solo lugar.",
        "explore" = "Explora",
        "athletes" = "Para atletas",
        "institutional" = "Road Runners",
        "events" = "Encuentra lo que buscas",
        "activities" = "Actividades",
        "results" = "Mis resultados",
        "news" = "Noticias",
        "videos" = "Videos",
        "profile" = "Mi perfil",
        "agenda" = "Mi agenda",
        "challenges" = "Mis desafíos",
        "about" = "Sobre Road Runners",
        "help" = "Centro de ayuda",
        "support" = "Contáctanos",
        "terms" = "Términos de Uso",
        "privacy" = "Privacidad y datos",
        "ecosystem" = "Más conexiones para seguir corriendo",
        "ecosystemLabel" = "Ecosistema RunnerHub",
        "follow" = "Corre con la comunidad",
        "rights" = "Todos los derechos reservados.",
        "navigationLabel" = "Navegación del pie de página",
        "socialLabel" = "Redes sociales de Road Runners",
        "top" = "Volver arriba",
        "companyDocument" = "CNPJ",
        "backToTop" = "Arriba"
    }
}/>
<cfset VARIABLES.rrFooterLanguage = structKeyExists(REQUEST, "lang") AND structKeyExists(VARIABLES.rrFooterFallbacks, REQUEST.lang) ? REQUEST.lang : "pt-BR"/>
<cfset VARIABLES.rrFooterText = {}/>
<cfloop collection="#VARIABLES.rrFooterFallbacks[VARIABLES.rrFooterLanguage]#" item="VARIABLES.rrFooterTextKey">
    <cfset VARIABLES.rrFooterI18nKey = "common.footer." & VARIABLES.rrFooterTextKey/>
    <cfset VARIABLES.rrFooterTranslatedText = REQUEST.t(VARIABLES.rrFooterI18nKey)/>
    <cfif NOT len(trim(VARIABLES.rrFooterTranslatedText & "")) OR compareNoCase(trim(VARIABLES.rrFooterTranslatedText & ""), VARIABLES.rrFooterI18nKey) EQ 0>
        <cfset VARIABLES.rrFooterTranslatedText = VARIABLES.rrFooterFallbacks[VARIABLES.rrFooterLanguage][VARIABLES.rrFooterTextKey]/>
    </cfif>
    <cfset VARIABLES.rrFooterText[VARIABLES.rrFooterTextKey] = VARIABLES.rrFooterTranslatedText/>
</cfloop>
<cfset VARIABLES.rrFooterProfilePath = "/atleta/"/>
<cfif structKeyExists(REQUEST, "Usuario") AND REQUEST.Usuario.logado AND len(trim(REQUEST.Usuario.tag))>
    <cfset VARIABLES.rrFooterRouteParams = structKeyExists(REQUEST, "currentRouteParams") ? duplicate(REQUEST.currentRouteParams) : {}/>
    <cfset REQUEST.currentRouteParams = { "tag" = trim(REQUEST.Usuario.tag) }/>
    <cfset VARIABLES.rrFooterProfilePath = REQUEST.i18nBuildPath("athlete")/>
    <cfset REQUEST.currentRouteParams = VARIABLES.rrFooterRouteParams/>
</cfif>
<cfset VARIABLES.rrFooterGroups = [
    { title = "explore", links = [
        { label = "events", href = REQUEST.i18nBuildPath("search") & "?busca_tipo=eventos" },
        { label = "activities", href = REQUEST.i18nBuildPath("feed") },
        { label = "news", href = REQUEST.i18nBuildPath("news") },
        { label = "videos", href = REQUEST.i18nBuildPath("videos") }
    ]},
    { title = "athletes", links = [
        { label = "profile", href = VARIABLES.rrFooterProfilePath },
        { label = "agenda", href = REQUEST.i18nBuildPath("agenda") },
        { label = "results", href = REQUEST.i18nBuildPath("results") },
        { label = "challenges", href = REQUEST.i18nBuildPath("challenges") }
    ]},
    { title = "institutional", links = [
        { label = "about", href = REQUEST.i18nBuildPath("about") },
        { label = "help", href = REQUEST.i18nBuildPath("help") },
        { label = "support", href = REQUEST.i18nBuildPath("support") },
        { label = "terms", href = REQUEST.i18nBuildPath("terms") },
        { label = "privacy", href = REQUEST.i18nBuildPath("privacy") }
    ]}
]/>

<cfoutput>
<footer class="rr-portal-footer" aria-label="Road Runners">
    <div id="sticky-stop" class="container rr-portal-footer-inner">
        <div class="rr-footer-main">
            <div class="rr-footer-brand">
                <a class="rr-footer-logo" href="#REQUEST.i18nBuildPath('home')#" aria-label="Road Runners - #encodeForHTMLAttribute(REQUEST.t('common.header.home'))#">
<svg xmlns="http://www.w3.org/2000/svg" class="rr-footer-logo-mark" aria-hidden="true" focusable="false" zoomAndPan="magnify" viewBox="0 0 204.75 83.999999" preserveAspectRatio="xMidYMid meet" version="1.0"><defs><g/><clipPath id="rr-footer-logo-clip"><rect x="0" width="187" y="0" height="68"/></clipPath></defs><g transform="matrix(1, 0, 0, 1, 7, 9)"><g clip-path="url(##rr-footer-logo-clip)"><g fill="##333333" fill-opacity="1"><g transform="translate(1.242049, 59.583708)"><g><path d="M 19.953125 -0.8125 C 19.984375 -0.707031 20 -0.585938 20 -0.453125 C 20 -0.148438 19.8125 0 19.4375 0 L 13.640625 0 C 13.421875 0 13.25 -0.0507812 13.125 -0.15625 C 13.007812 -0.269531 12.921875 -0.476562 12.859375 -0.78125 L 11.125 -8.5 C 11.082031 -8.613281 11.035156 -8.695312 10.984375 -8.75 C 10.941406 -8.800781 10.835938 -8.828125 10.671875 -8.828125 L 8.875 -8.828125 C 8.71875 -8.828125 8.609375 -8.796875 8.546875 -8.734375 C 8.492188 -8.671875 8.457031 -8.582031 8.4375 -8.46875 L 7.328125 -0.6875 C 7.285156 -0.382812 7.1875 -0.191406 7.03125 -0.109375 C 6.882812 -0.0351562 6.625 0 6.25 0 L 1.21875 0 C 0.707031 0 0.488281 -0.304688 0.5625 -0.921875 L 3.5 -21.6875 C 3.519531 -21.90625 3.5625 -22.039062 3.625 -22.09375 C 3.695312 -22.15625 3.820312 -22.1875 4 -22.1875 L 14 -22.1875 C 16.644531 -22.1875 18.703125 -21.679688 20.171875 -20.671875 C 21.640625 -19.671875 22.375 -18.273438 22.375 -16.484375 C 22.375 -15.023438 21.945312 -13.675781 21.09375 -12.4375 C 20.25 -11.207031 19.148438 -10.320312 17.796875 -9.78125 C 17.535156 -9.675781 17.378906 -9.582031 17.328125 -9.5 C 17.273438 -9.425781 17.269531 -9.320312 17.3125 -9.1875 Z M 12.46875 -13.28125 C 13.289062 -13.28125 13.972656 -13.554688 14.515625 -14.109375 C 15.066406 -14.671875 15.34375 -15.320312 15.34375 -16.0625 C 15.34375 -16.613281 15.132812 -17.035156 14.71875 -17.328125 C 14.3125 -17.617188 13.789062 -17.765625 13.15625 -17.765625 L 10.109375 -17.765625 C 9.972656 -17.765625 9.875 -17.722656 9.8125 -17.640625 C 9.75 -17.566406 9.695312 -17.410156 9.65625 -17.171875 L 9.15625 -13.734375 L 9.15625 -13.578125 C 9.15625 -13.453125 9.175781 -13.367188 9.21875 -13.328125 C 9.269531 -13.296875 9.359375 -13.28125 9.484375 -13.28125 Z M 12.46875 -13.28125 "/></g></g></g><g fill="##333333" fill-opacity="1"><g transform="translate(23.340554, 59.583708)"><g><path d="M 20.546875 -8.578125 C 20.085938 -5.304688 18.960938 -3.007812 17.171875 -1.6875 C 15.390625 -0.363281 12.984375 0.296875 9.953125 0.296875 C 6.921875 0.296875 4.726562 -0.3125 3.375 -1.53125 C 2.019531 -2.757812 1.34375 -4.582031 1.34375 -7 C 1.34375 -7.65625 1.414062 -8.503906 1.5625 -9.546875 L 3.265625 -21.6875 C 3.285156 -21.90625 3.328125 -22.039062 3.390625 -22.09375 C 3.460938 -22.15625 3.585938 -22.1875 3.765625 -22.1875 L 9.453125 -22.1875 C 9.628906 -22.1875 9.769531 -22.101562 9.875 -21.9375 C 9.988281 -21.769531 10.023438 -21.585938 9.984375 -21.390625 L 8.1875 -8.46875 C 8.113281 -7.820312 8.078125 -7.390625 8.078125 -7.171875 C 8.078125 -6.203125 8.296875 -5.503906 8.734375 -5.078125 C 9.171875 -4.660156 9.816406 -4.453125 10.671875 -4.453125 C 11.773438 -4.453125 12.71875 -4.804688 13.5 -5.515625 C 14.289062 -6.222656 14.796875 -7.351562 15.015625 -8.90625 L 16.8125 -21.6875 C 16.832031 -21.90625 16.875 -22.039062 16.9375 -22.09375 C 17.007812 -22.15625 17.132812 -22.1875 17.3125 -22.1875 L 21.796875 -22.1875 C 21.984375 -22.1875 22.128906 -22.101562 22.234375 -21.9375 C 22.347656 -21.769531 22.382812 -21.585938 22.34375 -21.390625 Z M 20.546875 -8.578125 "/></g></g></g><g fill="##333333" fill-opacity="1"><g transform="translate(45.110129, 59.583708)"><g><path d="M 22.78125 -22.1875 C 23.0625 -22.1875 23.179688 -22.03125 23.140625 -21.71875 L 20.125 -0.359375 C 20.101562 -0.222656 20.046875 -0.128906 19.953125 -0.078125 C 19.867188 -0.0234375 19.726562 0 19.53125 0 L 15.4375 0 C 15.289062 0 15.164062 -0.0390625 15.0625 -0.125 C 14.96875 -0.21875 14.851562 -0.375 14.71875 -0.59375 L 7.984375 -11.75 C 7.921875 -11.851562 7.863281 -11.90625 7.8125 -11.90625 C 7.6875 -11.90625 7.613281 -11.773438 7.59375 -11.515625 L 6.046875 -0.5625 C 6.023438 -0.320312 5.96875 -0.164062 5.875 -0.09375 C 5.78125 -0.03125 5.597656 0 5.328125 0 L 1.015625 0 C 0.640625 0 0.476562 -0.257812 0.53125 -0.78125 L 3.5 -21.6875 C 3.519531 -21.90625 3.566406 -22.039062 3.640625 -22.09375 C 3.722656 -22.15625 3.875 -22.1875 4.09375 -22.1875 L 8.96875 -22.1875 C 9.1875 -22.1875 9.359375 -22.128906 9.484375 -22.015625 C 9.617188 -21.910156 9.757812 -21.738281 9.90625 -21.5 L 15.734375 -11.578125 C 15.828125 -11.410156 15.925781 -11.328125 16.03125 -11.328125 C 16.09375 -11.328125 16.144531 -11.363281 16.1875 -11.4375 C 16.238281 -11.507812 16.273438 -11.601562 16.296875 -11.71875 L 17.703125 -21.734375 C 17.722656 -21.941406 17.769531 -22.066406 17.84375 -22.109375 C 17.925781 -22.160156 18.078125 -22.1875 18.296875 -22.1875 Z M 22.78125 -22.1875 "/></g></g></g><g fill="##333333" fill-opacity="1"><g transform="translate(67.866509, 59.583708)"><g><path d="M 22.78125 -22.1875 C 23.0625 -22.1875 23.179688 -22.03125 23.140625 -21.71875 L 20.125 -0.359375 C 20.101562 -0.222656 20.046875 -0.128906 19.953125 -0.078125 C 19.867188 -0.0234375 19.726562 0 19.53125 0 L 15.4375 0 C 15.289062 0 15.164062 -0.0390625 15.0625 -0.125 C 14.96875 -0.21875 14.851562 -0.375 14.71875 -0.59375 L 7.984375 -11.75 C 7.921875 -11.851562 7.863281 -11.90625 7.8125 -11.90625 C 7.6875 -11.90625 7.613281 -11.773438 7.59375 -11.515625 L 6.046875 -0.5625 C 6.023438 -0.320312 5.96875 -0.164062 5.875 -0.09375 C 5.78125 -0.03125 5.597656 0 5.328125 0 L 1.015625 0 C 0.640625 0 0.476562 -0.257812 0.53125 -0.78125 L 3.5 -21.6875 C 3.519531 -21.90625 3.566406 -22.039062 3.640625 -22.09375 C 3.722656 -22.15625 3.875 -22.1875 4.09375 -22.1875 L 8.96875 -22.1875 C 9.1875 -22.1875 9.359375 -22.128906 9.484375 -22.015625 C 9.617188 -21.910156 9.757812 -21.738281 9.90625 -21.5 L 15.734375 -11.578125 C 15.828125 -11.410156 15.925781 -11.328125 16.03125 -11.328125 C 16.09375 -11.328125 16.144531 -11.363281 16.1875 -11.4375 C 16.238281 -11.507812 16.273438 -11.601562 16.296875 -11.71875 L 17.703125 -21.734375 C 17.722656 -21.941406 17.769531 -22.066406 17.84375 -22.109375 C 17.925781 -22.160156 18.078125 -22.1875 18.296875 -22.1875 Z M 22.78125 -22.1875 "/></g></g></g><g fill="##333333" fill-opacity="1"><g transform="translate(90.62289, 59.583708)"><g><path d="M 3.5 -21.6875 C 3.519531 -21.90625 3.5625 -22.039062 3.625 -22.09375 C 3.695312 -22.15625 3.820312 -22.1875 4 -22.1875 L 20.28125 -22.1875 C 20.570312 -22.1875 20.71875 -22.007812 20.71875 -21.65625 C 20.71875 -21.53125 20.707031 -21.441406 20.6875 -21.390625 L 20.1875 -17.90625 C 20.144531 -17.675781 20.070312 -17.515625 19.96875 -17.421875 C 19.875 -17.328125 19.695312 -17.28125 19.4375 -17.28125 L 10.171875 -17.28125 C 9.992188 -17.28125 9.859375 -17.242188 9.765625 -17.171875 C 9.671875 -17.109375 9.613281 -16.96875 9.59375 -16.75 L 9.21875 -14 L 9.1875 -13.78125 C 9.1875 -13.6875 9.207031 -13.625 9.25 -13.59375 C 9.300781 -13.5625 9.398438 -13.546875 9.546875 -13.546875 L 15.1875 -13.546875 C 15.382812 -13.546875 15.515625 -13.503906 15.578125 -13.421875 C 15.640625 -13.347656 15.648438 -13.222656 15.609375 -13.046875 L 15.078125 -9.125 C 15.054688 -8.957031 15.015625 -8.847656 14.953125 -8.796875 C 14.890625 -8.753906 14.769531 -8.734375 14.59375 -8.734375 L 8.828125 -8.734375 C 8.679688 -8.734375 8.578125 -8.695312 8.515625 -8.625 C 8.460938 -8.550781 8.414062 -8.425781 8.375 -8.25 L 7.953125 -5.296875 L 7.953125 -5.140625 C 7.953125 -4.984375 8.023438 -4.90625 8.171875 -4.90625 L 18.125 -4.90625 C 18.320312 -4.90625 18.453125 -4.863281 18.515625 -4.78125 C 18.578125 -4.707031 18.585938 -4.5625 18.546875 -4.34375 L 18.03125 -0.484375 C 17.988281 -0.296875 17.925781 -0.164062 17.84375 -0.09375 C 17.769531 -0.03125 17.613281 0 17.375 0 L 1.28125 0 C 1.019531 0 0.828125 -0.0507812 0.703125 -0.15625 C 0.585938 -0.269531 0.53125 -0.4375 0.53125 -0.65625 L 0.5625 -0.921875 Z M 3.5 -21.6875 "/></g></g></g><g fill="##333333" fill-opacity="1"><g transform="translate(110.687978, 59.583708)"><g><path d="M 19.953125 -0.8125 C 19.984375 -0.707031 20 -0.585938 20 -0.453125 C 20 -0.148438 19.8125 0 19.4375 0 L 13.640625 0 C 13.421875 0 13.25 -0.0507812 13.125 -0.15625 C 13.007812 -0.269531 12.921875 -0.476562 12.859375 -0.78125 L 11.125 -8.5 C 11.082031 -8.613281 11.035156 -8.695312 10.984375 -8.75 C 10.941406 -8.800781 10.835938 -8.828125 10.671875 -8.828125 L 8.875 -8.828125 C 8.71875 -8.828125 8.609375 -8.796875 8.546875 -8.734375 C 8.492188 -8.671875 8.457031 -8.582031 8.4375 -8.46875 L 7.328125 -0.6875 C 7.285156 -0.382812 7.1875 -0.191406 7.03125 -0.109375 C 6.882812 -0.0351562 6.625 0 6.25 0 L 1.21875 0 C 0.707031 0 0.488281 -0.304688 0.5625 -0.921875 L 3.5 -21.6875 C 3.519531 -21.90625 3.5625 -22.039062 3.625 -22.09375 C 3.695312 -22.15625 3.820312 -22.1875 4 -22.1875 L 14 -22.1875 C 16.644531 -22.1875 18.703125 -21.679688 20.171875 -20.671875 C 21.640625 -19.671875 22.375 -18.273438 22.375 -16.484375 C 22.375 -15.023438 21.945312 -13.675781 21.09375 -12.4375 C 20.25 -11.207031 19.148438 -10.320312 17.796875 -9.78125 C 17.535156 -9.675781 17.378906 -9.582031 17.328125 -9.5 C 17.273438 -9.425781 17.269531 -9.320312 17.3125 -9.1875 Z M 12.46875 -13.28125 C 13.289062 -13.28125 13.972656 -13.554688 14.515625 -14.109375 C 15.066406 -14.671875 15.34375 -15.320312 15.34375 -16.0625 C 15.34375 -16.613281 15.132812 -17.035156 14.71875 -17.328125 C 14.3125 -17.617188 13.789062 -17.765625 13.15625 -17.765625 L 10.109375 -17.765625 C 9.972656 -17.765625 9.875 -17.722656 9.8125 -17.640625 C 9.75 -17.566406 9.695312 -17.410156 9.65625 -17.171875 L 9.15625 -13.734375 L 9.15625 -13.578125 C 9.15625 -13.453125 9.175781 -13.367188 9.21875 -13.328125 C 9.269531 -13.296875 9.359375 -13.28125 9.484375 -13.28125 Z M 12.46875 -13.28125 "/></g></g></g><g fill="##333333" fill-opacity="1"><g transform="translate(132.78649, 59.583708)"><g><path d="M 16.125 -16.515625 C 15.0625 -17.429688 13.691406 -17.890625 12.015625 -17.890625 C 11.023438 -17.890625 10.234375 -17.726562 9.640625 -17.40625 C 9.054688 -17.082031 8.765625 -16.625 8.765625 -16.03125 C 8.765625 -15.332031 9.363281 -14.800781 10.5625 -14.4375 L 15.34375 -12.890625 C 16.9375 -12.367188 18.117188 -11.691406 18.890625 -10.859375 C 19.671875 -10.035156 20.0625 -9 20.0625 -7.75 C 20.0625 -6.070312 19.601562 -4.625 18.6875 -3.40625 C 17.769531 -2.1875 16.519531 -1.265625 14.9375 -0.640625 C 13.351562 -0.015625 11.570312 0.296875 9.59375 0.296875 C 7.320312 0.296875 5.394531 -0.0703125 3.8125 -0.8125 C 2.226562 -1.5625 1.078125 -2.597656 0.359375 -3.921875 C 0.234375 -4.203125 0.171875 -4.359375 0.171875 -4.390625 C 0.171875 -4.515625 0.265625 -4.632812 0.453125 -4.75 L 3.625 -6.703125 C 3.78125 -6.796875 3.945312 -6.84375 4.125 -6.84375 C 4.40625 -6.84375 4.664062 -6.695312 4.90625 -6.40625 C 5.445312 -5.800781 5.914062 -5.347656 6.3125 -5.046875 C 6.707031 -4.753906 7.203125 -4.519531 7.796875 -4.34375 C 8.398438 -4.175781 9.203125 -4.09375 10.203125 -4.09375 C 11.140625 -4.09375 11.910156 -4.25 12.515625 -4.5625 C 13.117188 -4.875 13.421875 -5.382812 13.421875 -6.09375 C 13.421875 -6.8125 12.816406 -7.351562 11.609375 -7.71875 L 7.203125 -9.0625 C 5.691406 -9.519531 4.515625 -10.238281 3.671875 -11.21875 C 2.835938 -12.195312 2.421875 -13.34375 2.421875 -14.65625 C 2.421875 -16.1875 2.867188 -17.550781 3.765625 -18.75 C 4.660156 -19.945312 5.859375 -20.867188 7.359375 -21.515625 C 8.867188 -22.160156 10.503906 -22.484375 12.265625 -22.484375 C 14.117188 -22.484375 15.765625 -22.160156 17.203125 -21.515625 C 18.648438 -20.867188 19.734375 -20.066406 20.453125 -19.109375 C 20.609375 -18.890625 20.6875 -18.710938 20.6875 -18.578125 C 20.6875 -18.429688 20.617188 -18.320312 20.484375 -18.25 L 17.046875 -16.03125 C 16.941406 -15.945312 16.828125 -15.941406 16.703125 -16.015625 C 16.585938 -16.085938 16.46875 -16.175781 16.34375 -16.28125 C 16.226562 -16.394531 16.15625 -16.472656 16.125 -16.515625 Z M 16.125 -16.515625 "/></g></g></g><g fill="##333333" fill-opacity="1"><g transform="translate(67.146407, 29.74994)"><g><path d="M 19.953125 -0.8125 C 19.984375 -0.707031 20 -0.585938 20 -0.453125 C 20 -0.148438 19.8125 0 19.4375 0 L 13.640625 0 C 13.421875 0 13.25 -0.0507812 13.125 -0.15625 C 13.007812 -0.269531 12.921875 -0.476562 12.859375 -0.78125 L 11.125 -8.5 C 11.082031 -8.613281 11.035156 -8.695312 10.984375 -8.75 C 10.941406 -8.800781 10.835938 -8.828125 10.671875 -8.828125 L 8.875 -8.828125 C 8.71875 -8.828125 8.609375 -8.796875 8.546875 -8.734375 C 8.492188 -8.671875 8.457031 -8.582031 8.4375 -8.46875 L 7.328125 -0.6875 C 7.285156 -0.382812 7.1875 -0.191406 7.03125 -0.109375 C 6.882812 -0.0351562 6.625 0 6.25 0 L 1.21875 0 C 0.707031 0 0.488281 -0.304688 0.5625 -0.921875 L 3.5 -21.6875 C 3.519531 -21.90625 3.5625 -22.039062 3.625 -22.09375 C 3.695312 -22.15625 3.820312 -22.1875 4 -22.1875 L 14 -22.1875 C 16.644531 -22.1875 18.703125 -21.679688 20.171875 -20.671875 C 21.640625 -19.671875 22.375 -18.273438 22.375 -16.484375 C 22.375 -15.023438 21.945312 -13.675781 21.09375 -12.4375 C 20.25 -11.207031 19.148438 -10.320312 17.796875 -9.78125 C 17.535156 -9.675781 17.378906 -9.582031 17.328125 -9.5 C 17.273438 -9.425781 17.269531 -9.320312 17.3125 -9.1875 Z M 12.46875 -13.28125 C 13.289062 -13.28125 13.972656 -13.554688 14.515625 -14.109375 C 15.066406 -14.671875 15.34375 -15.320312 15.34375 -16.0625 C 15.34375 -16.613281 15.132812 -17.035156 14.71875 -17.328125 C 14.3125 -17.617188 13.789062 -17.765625 13.15625 -17.765625 L 10.109375 -17.765625 C 9.972656 -17.765625 9.875 -17.722656 9.8125 -17.640625 C 9.75 -17.566406 9.695312 -17.410156 9.65625 -17.171875 L 9.15625 -13.734375 L 9.15625 -13.578125 C 9.15625 -13.453125 9.175781 -13.367188 9.21875 -13.328125 C 9.269531 -13.296875 9.359375 -13.28125 9.484375 -13.28125 Z M 12.46875 -13.28125 "/></g></g></g><g fill="##333333" fill-opacity="1"><g transform="translate(89.244913, 29.74994)"><g><path d="M 10.765625 0.296875 C 8.796875 0.296875 7.097656 -0.0820312 5.671875 -0.84375 C 4.242188 -1.613281 3.148438 -2.707031 2.390625 -4.125 C 1.628906 -5.539062 1.25 -7.21875 1.25 -9.15625 C 1.25 -9.988281 1.300781 -10.722656 1.40625 -11.359375 C 1.726562 -13.597656 2.4375 -15.554688 3.53125 -17.234375 C 4.625 -18.921875 6.023438 -20.21875 7.734375 -21.125 C 9.453125 -22.03125 11.367188 -22.484375 13.484375 -22.484375 C 15.421875 -22.484375 17.101562 -22.085938 18.53125 -21.296875 C 19.957031 -20.515625 21.046875 -19.398438 21.796875 -17.953125 C 22.554688 -16.515625 22.9375 -14.828125 22.9375 -12.890625 C 22.9375 -12.054688 22.882812 -11.328125 22.78125 -10.703125 C 22.46875 -8.472656 21.765625 -6.53125 20.671875 -4.875 C 19.585938 -3.21875 18.191406 -1.941406 16.484375 -1.046875 C 14.785156 -0.148438 12.878906 0.296875 10.765625 0.296875 Z M 10.953125 -4.359375 C 12.304688 -4.359375 13.359375 -4.894531 14.109375 -5.96875 C 14.867188 -7.050781 15.421875 -8.820312 15.765625 -11.28125 C 15.921875 -12.488281 16 -13.472656 16 -14.234375 C 16 -15.523438 15.789062 -16.457031 15.375 -17.03125 C 14.957031 -17.601562 14.28125 -17.890625 13.34375 -17.890625 C 11.976562 -17.890625 10.90625 -17.3125 10.125 -16.15625 C 9.351562 -15.007812 8.789062 -13.160156 8.4375 -10.609375 C 8.269531 -9.441406 8.1875 -8.5 8.1875 -7.78125 C 8.1875 -6.539062 8.398438 -5.660156 8.828125 -5.140625 C 9.265625 -4.617188 9.972656 -4.359375 10.953125 -4.359375 Z M 10.953125 -4.359375 "/></g></g></g><g fill="##333333" fill-opacity="1"><g transform="translate(111.074123, 29.74994)"><g><path d="M -0.125 0 C -0.363281 0 -0.484375 -0.0976562 -0.484375 -0.296875 C -0.484375 -0.453125 -0.375 -0.769531 -0.15625 -1.25 L 9.984375 -21.65625 C 10.109375 -21.875 10.253906 -22.015625 10.421875 -22.078125 C 10.585938 -22.148438 10.820312 -22.1875 11.125 -22.1875 L 17.015625 -22.1875 C 17.253906 -22.1875 17.421875 -22.101562 17.515625 -21.9375 C 17.617188 -21.769531 17.703125 -21.535156 17.765625 -21.234375 L 22.09375 -0.875 C 22.113281 -0.8125 22.125 -0.71875 22.125 -0.59375 C 22.125 -0.195312 21.96875 0 21.65625 0 L 15.796875 0 C 15.515625 0 15.320312 -0.21875 15.21875 -0.65625 L 14.53125 -4.03125 C 14.507812 -4.132812 14.472656 -4.207031 14.421875 -4.25 C 14.378906 -4.289062 14.285156 -4.3125 14.140625 -4.3125 L 7.859375 -4.3125 C 7.722656 -4.3125 7.613281 -4.28125 7.53125 -4.21875 C 7.457031 -4.15625 7.378906 -4.054688 7.296875 -3.921875 L 5.5 -0.296875 C 5.4375 -0.179688 5.359375 -0.101562 5.265625 -0.0625 C 5.179688 -0.0195312 5.039062 0 4.84375 0 Z M 13.34375 -9.390625 C 13.675781 -9.390625 13.796875 -9.585938 13.703125 -9.984375 L 12.625 -14.984375 C 12.601562 -15.179688 12.53125 -15.28125 12.40625 -15.28125 C 12.332031 -15.28125 12.242188 -15.191406 12.140625 -15.015625 L 9.65625 -9.875 C 9.59375 -9.75 9.5625 -9.644531 9.5625 -9.5625 C 9.5625 -9.445312 9.679688 -9.390625 9.921875 -9.390625 Z M 13.34375 -9.390625 "/></g></g></g><g fill="##333333" fill-opacity="1"><g transform="translate(134.966828, 29.74994)"><g><path d="M 1.4375 0 C 1.132812 0 0.90625 -0.0976562 0.75 -0.296875 C 0.601562 -0.492188 0.550781 -0.753906 0.59375 -1.078125 L 3.46875 -21.625 C 3.488281 -21.863281 3.546875 -22.015625 3.640625 -22.078125 C 3.742188 -22.148438 3.9375 -22.1875 4.21875 -22.1875 L 11.6875 -22.1875 C 14.019531 -22.1875 16.015625 -21.785156 17.671875 -20.984375 C 19.328125 -20.191406 20.578125 -19.085938 21.421875 -17.671875 C 22.273438 -16.253906 22.703125 -14.640625 22.703125 -12.828125 C 22.703125 -10.296875 22.140625 -8.054688 21.015625 -6.109375 C 19.898438 -4.171875 18.332031 -2.664062 16.3125 -1.59375 C 14.289062 -0.53125 11.953125 0 9.296875 0 Z M 10.109375 -4.6875 C 11.921875 -4.6875 13.296875 -5.484375 14.234375 -7.078125 C 15.171875 -8.679688 15.640625 -10.726562 15.640625 -13.21875 C 15.640625 -14.59375 15.316406 -15.648438 14.671875 -16.390625 C 14.023438 -17.128906 13.132812 -17.5 12 -17.5 L 10.234375 -17.5 C 9.867188 -17.5 9.65625 -17.296875 9.59375 -16.890625 L 8.015625 -5.265625 L 8.015625 -5.078125 C 8.015625 -4.816406 8.144531 -4.6875 8.40625 -4.6875 Z M 10.109375 -4.6875 "/></g></g></g><g fill="##f4b120" fill-opacity="1"><g transform="translate(159.122212, 50.975513)"><g><path d="M 1.234375 8.53125 C 0.722656 8.53125 0.34375 8.335938 0.09375 7.953125 C -0.144531 7.578125 -0.226562 7.097656 -0.15625 6.515625 L 6.78125 -42.765625 C 6.84375 -43.253906 6.941406 -43.550781 7.078125 -43.65625 C 7.222656 -43.757812 7.535156 -43.8125 8.015625 -43.8125 L 12.828125 -43.8125 C 13.203125 -43.8125 13.507812 -43.671875 13.75 -43.390625 C 14 -43.117188 14.085938 -42.828125 14.015625 -42.515625 L 6.9375 7.90625 C 6.894531 8.1875 6.820312 8.359375 6.71875 8.421875 C 6.613281 8.492188 6.390625 8.53125 6.046875 8.53125 Z M 1.234375 8.53125 "/></g></g></g><g fill="##f4b120" fill-opacity="1"><g transform="translate(171.792997, 50.975513)"><g><path d="M 1.234375 8.53125 C 0.722656 8.53125 0.34375 8.335938 0.09375 7.953125 C -0.144531 7.578125 -0.226562 7.097656 -0.15625 6.515625 L 6.78125 -42.765625 C 6.84375 -43.253906 6.941406 -43.550781 7.078125 -43.65625 C 7.222656 -43.757812 7.535156 -43.8125 8.015625 -43.8125 L 12.828125 -43.8125 C 13.203125 -43.8125 13.507812 -43.671875 13.75 -43.390625 C 14 -43.117188 14.085938 -42.828125 14.015625 -42.515625 L 6.9375 7.90625 C 6.894531 8.1875 6.820312 8.359375 6.71875 8.421875 C 6.613281 8.492188 6.390625 8.53125 6.046875 8.53125 Z M 1.234375 8.53125 "/></g></g></g></g></g></svg>
                </a>
                <p class="rr-footer-tagline">#VARIABLES.rrFooterText.tagline#</p>
                <p class="rr-footer-description">#VARIABLES.rrFooterText.description#</p>
                <div class="rr-footer-community">
                    <span>#VARIABLES.rrFooterText.follow#</span>
                    <div class="rr-footer-social" role="group" aria-label="#encodeForHTMLAttribute(VARIABLES.rrFooterText.socialLabel)#">
                        <a href="https://www.instagram.com/roadrunners.run/" target="_blank" rel="noopener noreferrer" aria-label="Instagram"><i class="fa-brands fa-instagram" aria-hidden="true"></i></a>
                        <a href="https://www.strava.com/clubs/weareroadrunners/" target="_blank" rel="noopener noreferrer" aria-label="Strava"><i class="fa-brands fa-strava" aria-hidden="true"></i></a>
                        <a href="https://whatsapp.com/channel/0029VaAE7vc2975GuUCHIK0K" target="_blank" rel="noopener noreferrer" aria-label="#encodeForHTMLAttribute(REQUEST.t('common.header.whatsappChannel'))#"><i class="fa-brands fa-whatsapp" aria-hidden="true"></i></a>
                    </div>
                </div>
            </div>
            <nav class="rr-footer-navigation" aria-label="#encodeForHTMLAttribute(VARIABLES.rrFooterText.navigationLabel)#">
                <cfloop array="#VARIABLES.rrFooterGroups#" index="VARIABLES.rrFooterGroup">
                    <div class="rr-footer-group">
                        <h2>#VARIABLES.rrFooterText[VARIABLES.rrFooterGroup.title]#</h2>
                        <ul>
                            <cfloop array="#VARIABLES.rrFooterGroup.links#" index="VARIABLES.rrFooterLink">
                                <li><a href="#encodeForHTMLAttribute(VARIABLES.rrFooterLink.href)#">#VARIABLES.rrFooterText[VARIABLES.rrFooterLink.label]#</a></li>
                            </cfloop>
                        </ul>
                    </div>
                </cfloop>
            </nav>
        </div>
        <div class="rr-footer-ecosystem">
            <div class="rr-footer-ecosystem-copy">
                <span>#VARIABLES.rrFooterText.ecosystemLabel#</span>
                <p>#VARIABLES.rrFooterText.ecosystem#</p>
            </div>
            <div class="rr-footer-products">
                <a href="https://openresults.run/" target="_blank" rel="noopener noreferrer">Open Results</a>
                <a href="https://perfil.run/" target="_blank" rel="noopener noreferrer">Perfil.run</a>
                <a href="https://gorunners.roadrunners.run/" target="_blank" rel="noopener noreferrer">Go Runners</a>
                <a href="https://business.roadrunners.run/" target="_blank" rel="noopener noreferrer">Run Pro</a>
            </div>
        </div>
        <div class="rr-footer-bottom">
            <div class="rr-footer-legal">
                <a class="rr-footer-runnerhub-logo" href="https://runnerhub.run/" target="_blank" rel="noopener noreferrer" aria-label="RunnerHub Inteligência Esportiva">
                    <img src="/assets/runnerhub_logo.png" width="370" height="88" loading="lazy" decoding="async" alt=""/>
                </a>
                <span>&copy; #year(now())# RunnerHub Inteligência Esportiva. #VARIABLES.rrFooterText.rights#</span>
            </div>
            <button class="rr-footer-top" type="button" onclick="window.scrollTo({top:0,behavior:window.matchMedia('(prefers-reduced-motion: reduce)').matches?'auto':'smooth'})">#VARIABLES.rrFooterText.top# <i class="fa-solid fa-arrow-up" aria-hidden="true"></i></button>
        </div>
        <cfif structKeyExists(REQUEST, "Usuario") AND REQUEST.Usuario.logado AND BooleanFormat(REQUEST.Usuario.is_admin) AND structKeyExists(VARIABLES, "codPagina")>
            <small class="rr-footer-page-code">#encodeForHTML(VARIABLES.codPagina)#</small>
        </cfif>
    </div>
</footer>
<button type="button" onclick="topFunction()" id="scrollTop" title="#encodeForHTMLAttribute(VARIABLES.rrFooterText.backToTop)#" aria-label="#encodeForHTMLAttribute(VARIABLES.rrFooterText.top)#"><i class="fa-solid fa-chevron-up" aria-hidden="true"></i></button>
</cfoutput>

<cfinclude template="../modal/modal_beta.cfm"/>
<cfinclude template="../analytics/privacy_controls.cfm"/>
<cfif CGI.HTTP_HOST CONTAINS "dev.">
    <cfinclude template="debug_panel.cfm"/>
</cfif>
