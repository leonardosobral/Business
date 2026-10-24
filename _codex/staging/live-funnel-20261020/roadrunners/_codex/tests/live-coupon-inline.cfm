<cfscript>
inlineEnv=createObject("java","java.lang.System").getenv();
if (!inlineEnv.containsKey("RUNNERHUB_OFFLINE_CFML_TESTS") || inlineEnv.get("RUNNERHUB_OFFLINE_CFML_TESTS") != "1") abort;
function check(required boolean ok, required string label) { if (!arguments.ok) throw(type="LiveCouponTestFailure",message=arguments.label); }
qCupom=queryNew("condicoes","varchar",[{condicoes="15%"}]);
qEvento=queryNew("id_evento","integer",[{id_evento=304}]);
qLiveInlineCoupon=queryNew("cupom,curl,condicoes","varchar,varchar,varchar",[{cupom='ROADRUNNERS',curl='https://www.appliveexperience.com.br/evento/live/?a=1&b=2',condicoes='15%'}]);
html="";
if (fileExists(getDirectoryFromPath(getCurrentTemplatePath()) & 'evento/parts/live_coupon.cfm')) {
    savecontent variable="html" {include 'evento/parts/live_coupon.cfm';}
}
check(find('data-live-coupon-view="304"',html)>0,'coupon is rendered inline with event identity');
check(find('readonly',html)>0 && find('value="ROADRUNNERS"',html)>0,'coupon is selectable without JavaScript');
check(find('data-audience-live-registration="304"',html)>0 && find('href="https://www.appliveexperience.com.br/evento/live/?a=1',canonicalize(html,false,false))>0,'registration uses a real link and preserves the analytics marker');
check(findNoCase('checkout',html)>0 && !findNoCase('aplicado',html),'the code must be entered at checkout');
fileWrite(getDirectoryFromPath(getCurrentTemplatePath()) & 'coupon.html','<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><link rel="stylesheet" href="/assets/css/mdb.min.css"><body><main style="max-width:620px;margin:24px auto;padding:12px">' & html & '</main></body></html>','UTF-8');
qLiveInlineCoupon.cupom[1]='"><script>alert(1)</script>';
qCupom.condicoes[1]='<img src=x onerror=alert(1)>';
savecontent variable="html" {include 'evento/parts/live_coupon.cfm';}
check(!find('<script>alert(1)</script>',html) && !find('<img src=x',html),'coupon values are escaped in their HTML contexts');
writeOutput('PASS: inline coupon output, selectable code, direct registration and encoding.');
</cfscript>
