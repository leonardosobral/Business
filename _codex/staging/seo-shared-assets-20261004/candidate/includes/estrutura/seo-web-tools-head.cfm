<!---FORCE SCALE 1--->
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">

<!--- ASSET VERSIONS --->
<cfset VARIABLES.coresMinCssVersion = "20261004seo"/>
<cfset VARIABLES.coresCssVersion = "20260724a"/>
<cfset VARIABLES.mdbAssetVersion = "20260806a"/>
<cfparam name="VARIABLES.rrSharedAssetBaseUrl" default=""/>
<cfset VARIABLES.rrSharedAssetBaseUrl = reReplace(trim(VARIABLES.rrSharedAssetBaseUrl & ""), "/+$", "")/>

<!--- FONT AWESOME --->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@7.2.0/css/all.min.css" />

<!--- BOOTSTRAP ICONS --->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.13.1/font/bootstrap-icons.min.css" />

<!--- GOOGLE FONTS ROBOTO --->
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap" />

<!--- MDB ESSENTIAL --->
<link rel="stylesheet" href="<cfoutput>#VARIABLES.rrSharedAssetBaseUrl#</cfoutput>/assets/css/mdb.min.css?version=<cfoutput>#VARIABLES.mdbAssetVersion#</cfoutput>" />

<!--- MDB PLUGINS --->
<link rel="stylesheet" href="<cfoutput>#VARIABLES.rrSharedAssetBaseUrl#</cfoutput>/assets/plugins/css/all.min.css?version=<cfoutput>#VARIABLES.mdbAssetVersion#</cfoutput>" />

<!--- CSS --->
<link rel="stylesheet" href="<cfoutput>#VARIABLES.rrSharedAssetBaseUrl#</cfoutput>/assets/css/cores.min.css?version=<cfoutput>#VARIABLES.coresMinCssVersion#</cfoutput>"/>
<!---<link rel="stylesheet" href="https://roadrunners.run/assets/css/cores.min.css?version=<cfoutput>#VARIABLES.coresMinCssVersion#</cfoutput>"/>--->
<!---<link rel="stylesheet" href="https://roadrunners.run/assets/css/mapa.min.css?version=20240228"/>--->

<!---FORCE BROWSER ON MOBILE--->
<script>
    document.addEventListener("DOMContentLoaded", function () {
        var ua = navigator.userAgent || navigator.vendor || window.opera;
        var isInstagram = /Instagram/i.test(ua);
        var isFacebook = /FBAN|FBAV|FB_IAB|FBIOS/i.test(ua);
        var isAndroid = /Android/i.test(ua);
        var isiOS = /iPhone|iPad|iPod|Macintosh/i.test(ua) && ('ontouchend' in document);
        var isInAppWebView = /wv|WebView/i.test(ua) || isInstagram || isFacebook;

        if (!isInAppWebView) return;

        var url = window.location.href;

        if (isAndroid) {
            var intentUrl = "intent://" + url.replace(/^https?:\/\//, "") +
                    "#Intent;scheme=https;package=com.android.chrome;end";
            window.location.href = intentUrl;
            setTimeout(function(){ window.location.href = url; }, 1200);
        } else if (isiOS) {
            // Em iOS, exiba instrução amigável (evita pop-up bloqueado)
            setTimeout(function(){
                alert("Para continuar, toque em ••• e escolha 'Abrir no navegador (Safari)'.");
            }, 500);
        }
    });
</script>


<!--- GOOGLE LOGIN --->

<script src="https://apis.google.com/js/platform.js" async defer></script>

<!--- GOOGLE TAG MANAGER --->
<script>(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
'https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
})(window,document,'script','dataLayer','GTM-P892QN37');</script>

<!--- GOOGLE TAG (GTAG.JS) --->
<script async src="https://www.googletagmanager.com/gtag/js?id=<cfoutput>#APPLICATION.ga#</cfoutput>"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());

  gtag('config', '<cfoutput>#APPLICATION.ga#</cfoutput>');
</script>

<!--- VERIFICACAO AWIN --->
<meta name="verification" content="38854b6ad1b847b47c8b8f6fa023f0ab" />

<!--- META PIXEL CODE --->
<script>
    !function(f,b,e,v,n,t,s)
    {if(f.fbq)return;n=f.fbq=function(){n.callMethod?
            n.callMethod.apply(n,arguments):n.queue.push(arguments)};
        if(!f._fbq)f._fbq=n;n.push=n;n.loaded=!0;n.version='2.0';
        n.queue=[];t=b.createElement(e);t.async=!0;
        t.src=v;s=b.getElementsByTagName(e)[0];
        s.parentNode.insertBefore(t,s)}(window, document,'script',
            'https://connect.facebook.net/en_US/fbevents.js');
    fbq('init', '308580355012403');
    fbq('track', 'PageView');
</script>
<noscript><img height="1" width="1" style="display:none"
               src="https://www.facebook.com/tr?id=308580355012403&ev=PageView&noscript=1"
/></noscript>

<!--- MANYCHAT --->
<script src="//widget.manychat.com/1025666_f7eaa.js" defer="defer"></script>
<script src="https://mccdn.me/assets/js/widget.js" defer="defer"></script>
