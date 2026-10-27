<cfscript>
VARIABLES.userAcquisitionMetrics=new services.UserAcquisitionMetrics();VARIABLES.userAcquisitionDays=30;VARIABLES.userAcquisition=VARIABLES.userAcquisitionMetrics.load(30);VARIABLES.userAcquisitionReady=true;
VARIABLES.userManagerPage=1;VARIABLES.userManagerSearch="";VARIABLES.userManagerStatus="ativos";VARIABLES.userManagerRole="todos";
savecontent variable="panel"{include "../administracao/usuarios/includes/acquisition.cfm";}
writeOutput('<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Aquisição de usuários — prévia</title><link rel="stylesheet" href="/mdb.min.css"></head><body data-mdb-theme="dark" style="background:rgb(32,32,32);color:rgb(235,235,235)"><main style="max-width:1080px;margin:32px auto;padding:16px;--um-accent:rgb(250,177,32);--um-border:rgba(255,255,255,.09);--um-surface:rgba(255,255,255,.035)">' & panel & '</main></body></html>');
writeOutput("<!-- USER_ACQUISITION_PREVIEW_PASSED -->");
</cfscript>
