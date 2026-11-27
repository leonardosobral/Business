<cfscript>
if (createObject("java","java.lang.System").getenv("RUNNERHUB_OFFLINE_CFML_TESTS") != "1") abort;
function check(ok,label) {
    if (!ok) throw(type="Test.Assertion",message=label);
    request.brevoChecks++;
}
function rejects(work,code) {
    try {
        work();
    } catch (Brevo.Marketing e) {
        check(compare(e.message,code)==0,"expected " & code & ", got " & e.message);
        return;
    }
    throw(type="Test.Assertion",message="missing error " & code);
}
function calls(method,path) {
    var count=0;
    for (var call in request.brevoCalls) if(call.method==method && call.path==path) count++;
    return count;
}
function member(email,blocked=false) {
    return {email=email,emailBlacklisted=blocked};
}
request.brevoChecks=0;
request.brevoCalls=[];
token=repeatString("x",32);
settings={apiKey="fixture",senderId=3,folderId=5,webhookToken=token};
batchName="selo-atleta-20261127-lote-01";
address="runner@example.org";
existing="existing@example.org";
blocked="optout@example.org";
outside="outside@example.org";
listPath="/contacts/lists/7/contacts";
fixture={members={},folder=5,segments=[],sender=3,draftStatus="draft",hook={},failStatus=0,failPath="",badId=false,
    omitProcess=false,omitBlacklist=false,subject="Um ano de Atleta Verificado por R$ 9,90"};
fixture.members[address]=member(address);
fixture.members[blocked]=member(blocked,true);
fixture.members[outside]=member(outside);
request.brevoFixture=fixture;
request.brevoBatchName=batchName;
request.brevoExisting=existing;
request.brevoListPath=listPath;
provider=function(method,path,body) {
    var fixture=request.brevoFixture;
    var batchName=request.brevoBatchName;
    var existing=request.brevoExisting;
    var listPath=request.brevoListPath;
    arrayAppend(request.brevoCalls,{method=method,path=path,body=duplicate(body)});
    if (path==fixture.failPath) return {status=fixture.failStatus,data={message="PRIVATE"}};
    if (path=="/webhooks?type=marketing") return {status=200,data={webhooks=structIsEmpty(fixture.hook)?[]:[fixture.hook]}};
    if (path=="/webhooks/6" && method=="PUT") { fixture.hook.auth=duplicate(body.auth); return {status=204,data={}}; }
    if (path=="/webhooks") {
        fixture.hook=duplicate(body); fixture.hook.id=6;
        return {status=201,data={id=6}};
    }
    if (path=="/senders") return {status=200,data={senders=[{id=3,email="offers@example.org",active=true}]}};
    if (path=="/contacts/folders/5") return {status=200,data={id=5}};
    if (path=="/contacts/lists") return {status=201,data=fixture.badId?{}:{id=7}};
    if (path=="/contacts/lists/7") return {status=200,data={id=7,name=batchName,folderId=fixture.folder,dynamicList=false}};
    if (path=="/contacts/import") return {status=202,data=fixture.omitProcess?{}:{processId=11}};
    if (path=="/processes/11") return {status=200,data={id=11,name="IMPORTUSER",status="completed"}};
    if (path==listPath & "?limit=500&offset=0") {
        var rows=[];
        for (var key in fixture.members) arrayAppend(rows,fixture.members[key]);
        return {status=200,data={count=arrayLen(rows),contacts=rows}};
    }
    if (path==listPath & "/add") {
        for (var email in body.emails) {
            if (email==existing) fixture.members[existing]={email=existing,emailBlacklisted=false};
        }
        return {status=201,data={contacts={success=[existing]}}};
    }
    if (path==listPath & "/remove") {
        for (var email in body.emails) structDelete(fixture.members,email);
        return {status=201,data={contacts={}}};
    }
    if (path=="/emailCampaigns") return {status=201,data={id=9}};
    if (path=="/emailCampaigns/9?statistics=globalStats&excludeHtmlContent=true")
        return {status=200,data={id=9,name=batchName,sender={id=fixture.sender},type="classic",subject=fixture.subject,status=fixture.draftStatus,
            recipients={lists=[7],exclusionLists=[],segments=fixture.segments},statistics={globalStats={sent=8,delivered=7,uniqueClicks=3}}}};
    if (path=="/emailCampaigns/9/sendNow") return {status=204,data={}};
    throw(type="Test.UnexpectedRequest",message=method & " " & path);
};

emptyService=new services.BrevoMarketingService(config={},transport=provider);
check(!emptyService.readiness().configured && arrayLen(emptyService.readiness().missing)==4,"missing settings");
check(!emptyService.verifySetup().ready && !arrayLen(request.brevoCalls),"no traffic without settings");
rejects(function(){emptyService.createList(batchName);},"brevo_setup_incomplete");
service=new services.BrevoMarketingService(config=settings,transport=provider);
check(service.readiness().configured && !service.verifySetup().ready,"missing webhook");
check(service.registerWebhook()==6 && service.registerWebhook()==6 && calls("POST","/webhooks")==1,"idempotent register");
setup=service.verifySetup();
check(setup.ready && setup.webhookTokenCompared && !find(token,serializeJSON(setup)),"sanitized setup");
arrayDeleteAt(fixture.hook.events,1);
rejects(function(){service.registerWebhook();},"brevo_webhook_conflict");
check(!service.verifySetup().ready,"missing mandatory event");
arrayAppend(fixture.hook.events,"delivered");
fixture.hook.auth.token="another-test-value";
check(!service.verifySetup().ready,"wrong bearer");
fixture.hook.auth.token=token;
fromPrivateConfig=new services.BrevoMarketingService(transport=provider);
check(fromPrivateConfig.readiness().configured && fromPrivateConfig.verifySetup().ready,"private settings and environment override");
structDelete(fixture.hook,"auth");
check(service.verifySetup().ready && !service.verifySetup().webhookAuthReported,"auth omission explicitly reported");
check(service.registerWebhook()==6 && calls("PUT","/webhooks/6")==1 && calls("POST","/webhooks")==1,"redacted bearer reapplied on same webhook");
check(service.createList(batchName)==7,"list");
fixture.badId=true;
rejects(function(){service.createList(batchName);},"brevo_write_unknown");
fixture.badId=false;
check(service.importContacts(7,[address,existing,blocked])==11,"import process ID");
payload=request.brevoCalls[arrayLen(request.brevoCalls)].body;
json=serializeJSON(payload);
check(find('"jsonBody"',json) && find('"listIds"',json) && find('"updateExistingContacts":false',json) &&
    !findNoCase("blacklist",json) && !findNoCase("consentGroup",json) && !findNoCase("attributes",json),"no contact reactivation/overwrite");
check(arrayLen(payload.jsonBody)==3 && structCount(payload.jsonBody[1])==1 && structKeyExists(payload.jsonBody[1],"email"),"email only");
check(service.processStatus(11)=="completed","async import");
fixture.omitProcess=true;
rejects(function(){service.importContacts(7,[address]);},"brevo_write_unknown");
fixture.omitProcess=false;
fixture.folder=12;
rejects(function(){service.syncList(batchName,7,[address]);},"brevo_audience_changed");
check(calls("POST",listPath & "/remove")==0,"other folder untouched");
fixture.folder=5;
fixture.members["listout@example.org"]={email="listout@example.org",emailBlacklisted=false,listUnsubscribed=[10]};
fixture.members["groupout@example.org"]={email="groupout@example.org",emailBlacklisted=false,consentGroups=[{id=4,status="unsubscribed"}]};
result=service.syncList(batchName,7,[address,existing,blocked,"invalidimport@example.org","listout@example.org","groupout@example.org"]);
check(arrayLen(result.eligible)==2 && arrayLen(result.suppressed)==4,"remote and local suppression");
check(calls("POST",listPath & "/add")==1 && calls("POST",listPath & "/remove")==1 && structCount(fixture.members)==2,"bulk writes only");
check(service.createDraft(batchName,7)==9,"draft");
payload=request.brevoCalls[arrayLen(request.brevoCalls)].body;
check(compare(payload.subject,fixture.subject)==0,"exact commercial draft subject");
check(!structKeyExists(payload,"scheduledAt") && !structKeyExists(payload,"templateId") && payload.sender.id==3 && payload.recipients.listIds[1]==7
    && find("{{ unsubscribe }}",payload.htmlContent) && find("utm_source=brevo",payload.htmlContent) && !find("mailchimp",payload.htmlContent),"native marketing format");
check(find("Um ano inteiro.",payload.htmlContent) && find("Pelo preço",payload.htmlContent) && find("R$&nbsp;99,90",payload.htmlContent)
    && find("Um ano inteiro. Pelo preço de um mês.",payload.previewText),"published hotsite offer and preview");
check(find("Um Perfil.run com a sua cara",payload.htmlContent) && find("Até 30 links com métricas",payload.htmlContent)
    && find("Acesso antecipado ao Go Runners",payload.htmlContent) && find("Teste os novos recursos antes do público geral",payload.htmlContent)
    && find("O ponto de encontro da corrida.",payload.htmlContent),"hotsite benefits and brand");
check(!reFindNoCase("<(iframe|form|button|script)[ >]",payload.htmlContent) && find("utm_content=compra",payload.htmlContent)
    && !find("utm_content=oferta_final",payload.htmlContent)
    && find("selo-atleta-2026-11-27/perfil.jpg",payload.htmlContent),"compatible imagery and tracked checkout links");
check(!structKeyExists(payload,"tag") && find("utm_campaign=selo-atleta-20261127",payload.htmlContent),"campaign attribution without optional Brevo tags");
check(payload.utmSource=="brevo" && payload.utmMedium=="email" && payload.utmCampaign=="seloatleta20261127","provider tracking identifies the commercial offer");
check(service.campaign(9).statistics.uniqueClicks==3,"aggregate");
fixture.subject="Black Friday Road Runners: 1 ano de Atleta Verificado por R$ 9,90";
rejects(function(){service.verifyDraftAudience(9,batchName,7,result.eligible);},"brevo_draft_changed");
fixture.subject=payload.subject;
fixture.segments=[27];
rejects(function(){service.sendNow(9,batchName,7,result.eligible);},"brevo_draft_changed");
fixture.segments=[];
fixture.sender=12;
rejects(function(){service.sendNow(9,batchName,7,result.eligible);},"brevo_draft_changed");
fixture.sender=3;
fixture.members[outside]=member(outside);
rejects(function(){service.sendNow(9,batchName,7,result.eligible);},"brevo_audience_changed");
structDelete(fixture.members,outside);
fixture.members[address].emailBlacklisted=true;
rejects(function(){service.sendNow(9,batchName,7,result.eligible);},"brevo_audience_changed");
structDelete(fixture.members[address],"emailBlacklisted");
rejects(function(){service.sendNow(9,batchName,7,result.eligible);},"brevo_invalid_response");
fixture.members[address].emailBlacklisted=false;
check(!calls("POST","/emailCampaigns/9/sendNow"),"preflight blocks all sends");
check(service.verifyDraftAudience(9,batchName,7,result.eligible) && !calls("POST","/emailCampaigns/9/sendNow"),"read-only draft validation");
beforeDispatch=arrayLen(request.brevoCalls);
check(service.sendValidated(9) && calls("POST","/emailCampaigns/9/sendNow")==1 && arrayLen(request.brevoCalls)==beforeDispatch+1,"single dispatch call");
fixture.failPath="/emailCampaigns/9/sendNow"; fixture.failStatus=503;
rejects(function(){service.sendNow(9,batchName,7,result.eligible);},"brevo_write_unknown");
check(calls("POST",fixture.failPath)==2,"no automatic retry");
fixture.failPath="/contacts/lists"; fixture.failStatus=429;
rejects(function(){service.createList(batchName);},"brevo_rate_limited");
fixture.failStatus=401;
rejects(function(){service.createList(batchName);},"brevo_auth_failed");
writeOutput("BREVO_MARKETING_SERVICE_OK " & request.brevoChecks);
</cfscript>
