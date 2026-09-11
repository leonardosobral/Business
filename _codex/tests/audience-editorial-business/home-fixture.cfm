<cfsetting showdebugoutput="false" requesttimeout="30"/>
<cfscript>
VARIABLES.businessEffectiveIsAdmin = true;
VARIABLES.audienceUnavailable = false;
VARIABLES.audienceReady = true;
VARIABLES.audienceEnvironment = "prod";
VARIABLES.audienceDays = 7;
VARIABLES.audienceUf = "";
VARIABLES.audienceUfList = "AC,SC,SP,--";
VARIABLES.audienceFamily = "";
VARIABLES.audienceFamilies = "home,search,news_detail,videos";
VARIABLES.audienceDevice = "";
VARIABLES.audienceDimension = "market";
VARIABLES.audienceIncludeInternal = false;
VARIABLES.audienceSummary = {
    "pageviews"=12,"active_pages"=12,"visitors"=8,"sessions"=9,"engaged_sessions"=4,
    "opportunities"=6,"renders"=4,"slot_views"=3,"ad_renders"=2,"ad_views"=1,
    "unknown_location"=0,"unknown_market"=0,
    "first_event"=dateAdd("d",-6,now()),"last_received"=now()
};
VARIABLES.audienceRetention = {"state"="never","lastSuccess"="","hasMore"=false};

function audienceCount(value) { return numberFormat(val(arguments.value), "__,___,___,___"); }
function audienceLabel(required string value) {
    var labels = {"home"="Home","search"="Busca","news_detail"="Notícia — detalhe",
        "videos"="Vídeos — lista","news"="Notícia","video"="Vídeo","event"="Evento",
        "profile"="Perfil","MOBILE"="Mobile","DESKTOP"="Desktop"};
    return structKeyExists(labels, arguments.value) ? labels[arguments.value] : arguments.value;
}
function audienceDate(value) {
    return isDate(arguments.value) ? dateTimeFormat(arguments.value,"dd/mm HH:nn","America/Sao_Paulo") : "—";
}
function audienceRate(numerator, denominator) {
    return val(arguments.denominator) GT 0
        ? numberFormat(100 * val(arguments.numerator) / val(arguments.denominator),"0.0") & "%"
        : "—";
}

audDaily = queryNew("day,pageviews,opportunities,slot_views,ad_views","date,integer,integer,integer,integer");
queryAddRow(audDaily,{"day"=dateAdd("d",-1,now()),"pageviews"=5,"opportunities"=2,"slot_views"=1,"ad_views"=0});
queryAddRow(audDaily,{"day"=now(),"pageviews"=7,"opportunities"=4,"slot_views"=2,"ad_views"=1});
audRegions = queryNew("audience_uf,active_pages,visitors,opportunities,slot_views,ad_views","varchar,integer,integer,integer,integer,integer");
queryAddRow(audRegions,{"audience_uf"="SC","active_pages"=8,"visitors"=5,"opportunities"=4,"slot_views"=2,"ad_views"=1});
queryAddRow(audRegions,{"audience_uf"="SP","active_pages"=4,"visitors"=3,"opportunities"=2,"slot_views"=1,"ad_views"=0});

audInventory = queryNew("slot_key,placement_key,page_family,device_class,opportunities,requests,served,renders,ad_renders,slot_views,ad_views,filled_slots,house_slots,empty_slots,pending_slots,unavailable_slots,errors","varchar,varchar,varchar,varchar,integer,integer,integer,integer,integer,integer,integer,integer,integer,integer,integer,integer,integer");
queryAddRow(audInventory,{"slot_key"="home-feed","placement_key"="feed","page_family"="home","device_class"="MOBILE","opportunities"=6,"requests"=4,"served"=3,"renders"=3,"ad_renders"=2,"slot_views"=3,"ad_views"=1,"filled_slots"=2,"house_slots"=1,"empty_slots"=2,"pending_slots"=1,"unavailable_slots"=0,"errors"=0});

audContent = queryNew("content_type,content_id,page_path,pageviews,opens,visitors,card_views,exposed_visitors,video_starts,video_completions,depth_25,depth_50,depth_75,depth_100,active_ms","varchar,varchar,varchar,integer,integer,integer,integer,integer,integer,integer,integer,integer,integer,integer,integer");
queryAddRow(audContent,{"content_type"="news","content_id"="card-sem-abertura","page_path"="","pageviews"=0,"opens"=0,"visitors"=0,"card_views"=2,"exposed_visitors"=1,"video_starts"=0,"video_completions"=0,"depth_25"=0,"depth_50"=0,"depth_75"=0,"depth_100"=0,"active_ms"=0});
queryAddRow(audContent,{"content_type"="news","content_id"="noticia-com-profundidade","page_path"="/noticias/noticia-com-profundidade/","pageviews"=2,"opens"=2,"visitors"=1,"card_views"=1,"exposed_visitors"=1,"video_starts"=0,"video_completions"=0,"depth_25"=2,"depth_50"=2,"depth_75"=1,"depth_100"=1,"active_ms"=65000});
queryAddRow(audContent,{"content_type"="news","content_id"="noticia-legada","page_path"="/noticias/noticia-legada/","pageviews"=1,"opens"=1,"visitors"=1,"card_views"=0,"exposed_visitors"=0,"video_starts"=0,"video_completions"=0,"depth_25"=0,"depth_50"=0,"depth_75"=0,"depth_100"=0,"active_ms"=40000});
queryAddRow(audContent,{"content_type"="video","content_id"="video-42","page_path"="/videos/","pageviews"=1,"opens"=1,"visitors"=1,"card_views"=1,"exposed_visitors"=1,"video_starts"=1,"video_completions"=0,"depth_25"=0,"depth_50"=0,"depth_75"=0,"depth_100"=0,"active_ms"=0});
for (fixtureIndex=5; fixtureIndex LTE 101; fixtureIndex++) {
    queryAddRow(audContent,{"content_type"="event","content_id"="evento-fixture-" & fixtureIndex,"page_path"="/eventos/fixture/","pageviews"=1,"opens"=1,"visitors"=1,"card_views"=0,"exposed_visitors"=0,"video_starts"=0,"video_completions"=0,"depth_25"=0,"depth_50"=0,"depth_75"=0,"depth_100"=0,"active_ms"=0});
}

audAcquisition = queryNew("source,medium,campaign,creative,active_pages,visitors,sessions,engaged_sessions,active_ms","varchar,varchar,varchar,varchar,integer,integer,integer,integer,integer");
queryAddRow(audAcquisition,{"source"="direct","medium"="(none)","campaign"="","creative"="","active_pages"=12,"visitors"=8,"sessions"=9,"engaged_sessions"=4,"active_ms"=105000});
audCoverage = queryNew("page_family,pageviews,pages_with_slots,opportunities,slot_views,last_received","varchar,integer,integer,integer,integer,timestamp");
queryAddRow(audCoverage,{"page_family"="home","pageviews"=5,"pages_with_slots"=3,"opportunities"=6,"slot_views"=3,"last_received"=now()});

VARIABLES.audienceQueries = {
    "daily"=audDaily,"regions"=audRegions,"inventory"=audInventory,
    "content"=audContent,"acquisition"=audAcquisition,"coverage"=audCoverage
};
</cfscript>
<!doctype html>
<html lang="pt-br">
<head>
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1"/>
    <title>Fixture local — audiência editorial</title>
    <link rel="stylesheet" href="/assets/css/mdb.min.css"/>
    <link rel="stylesheet" href="/assets/css/business-ui.css"/>
</head>
<body data-mdb-theme="dark" class="bg-dark-subtle">
    <div class="alert alert-info rounded-0 mb-0" role="status"><strong>Fixture local sintética.</strong> Layout para QA; não representa dados nem instrumentação de produção.</div>
    <main class="container-fluid px-4 py-4"><cfinclude template="portal/audiencia/home.cfm"/></main>
    <script src="/assets/js/mdb.umd.min.js"></script>
</body>
</html>

