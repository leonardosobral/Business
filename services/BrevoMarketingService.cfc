component output=false {
    variables.webhookUrl = "https://business.roadrunners.run/api/brevo-marketing-events.cfm";
    variables.events = ["delivered","opened","click","softBounce","hardBounce","spam","unsubscribed"];
    variables.subject = "Black Friday Road Runners: 1 ano de Atleta Verificado por R$ 9,90";

    public any function init(struct config, any transport) {
        var names = {"apiKey"="RR_BREVO_API_KEY","senderId"="RR_BREVO_SENDER_ID","folderId"="RR_BREVO_FOLDER_ID","webhookToken"="RR_BREVO_WEBHOOK_TOKEN"};
        variables.settingNames = names;
        variables.settings = {};
        if (structKeyExists(arguments,"config")) {
            variables.settings = duplicate(arguments.config);
        } else {
            var businessLocalConfig = {};
            if (fileExists(getDirectoryFromPath(getCurrentTemplatePath()) & "../config/business.local.cfm")) {
                variables.businessLocalConfig = {};
                include "../config/business.local.cfm";
                structAppend(businessLocalConfig,variables.businessLocalConfig,true);
                structDelete(variables,"businessLocalConfig");
            }
            var environment = createObject("java","java.lang.System").getenv();
            for (var key in names) {
                var privateKey = "brevo" & key;
                if (structKeyExists(environment,names[key]) && len(trim(environment[names[key]]))) {
                    variables.settings[key] = trim(environment[names[key]]);
                } else if (structKeyExists(businessLocalConfig,privateKey)) {
                    variables.settings[key] = trim(businessLocalConfig[privateKey]);
                }
            }
        }
        if (structKeyExists(arguments,"transport")) variables.transport = arguments.transport;
        variables.addresses = new EmailAddress();
        return this;
    }

    public struct function readiness() {
        var missing = [];
        for (var key in variables.settingNames) {
            var value = structKeyExists(variables.settings,key) ? variables.settings[key] : "";
            var valid = isSimpleValue(value) && len(trim(value)) && !reFind("[[:cntrl:]]",value);
            if (key == "senderId" || key == "folderId") valid = valid && validId(value);
            if (key == "webhookToken") valid = valid && len(value) >= 32;
            if (!valid) arrayAppend(missing,variables.settingNames[key]);
        }
        return {configured=arrayIsEmpty(missing),missing=missing};
    }

    private boolean function validId(required any value) {
        return isSimpleValue(value) && reFind("^[1-9][0-9]{0,15}$",toString(value)) > 0;
    }

    private numeric function resourceId(required any value) {
        if (!validId(value)) fail("brevo_invalid_input");
        return javaCast("long",value);
    }

    private numeric function configuredId(required string key) {
        if (!structKeyExists(variables.settings,key) || !validId(variables.settings[key])) fail("brevo_setup_incomplete");
        return resourceId(variables.settings[key]);
    }

    private void function fail(required string code) {
        throw(type="Brevo.Marketing",message=code);
    }

    // Only this method talks to Brevo. A fixture can replace the transport without a network call.
    private struct function exchange(required string method, required string path, struct body={}) {
        if (structKeyExists(variables,"transport")) return variables.transport(method,path,body);
        var response = {};
        cfhttp(method=method,url="https://api.brevo.com/v3" & path,timeout=10,throwOnError=false,redirect=false,result="local.response",charset="utf-8") {
            cfhttpparam(type="header",name="api-key",value=variables.settings.apiKey);
            cfhttpparam(type="header",name="accept",value="application/json");
            if (structCount(body)) {
                cfhttpparam(type="header",name="Content-Type",value="application/json; charset=utf-8");
                cfhttpparam(type="body",value=serializeJSON(body));
            }
        }
        var raw = structKeyExists(response,"fileContent") ? toString(response.fileContent) : "";
        return {status=val(response.statusCode),data=isJSON(raw) ? deserializeJSON(raw) : {}};
    }

    private struct function api(required string method,required string path,required numeric expected,struct body={},boolean ambiguous=false) {
        if (!readiness().configured) fail("brevo_setup_incomplete");
        var result = {};
        try {
            result = exchange(method,path,body);
        } catch (any transportError) {
            fail(ambiguous ? "brevo_write_unknown" : "brevo_unavailable");
        }
        var status = structKeyExists(result,"status") ? val(result.status) : 0;
        var data = structKeyExists(result,"data") && isStruct(result.data) ? result.data : {};
        if (status == expected) return data;
        if ((status == 400 || status == 404) && structKeyExists(data,"code") && data.code == "document_not_found"
            && method == "GET" && path == "/webhooks?type=marketing") return {webhooks=[]};
        if (status == 401 || status == 403) fail("brevo_auth_failed");
        if (status == 429) fail("brevo_rate_limited");
        if (status == 402 || (structKeyExists(data,"code") && data.code == "not_enough_credits")) fail("brevo_insufficient_credits");
        if (!status || status == 408 || status >= 500 || (status >= 200 && status < 300))
            fail(ambiguous ? "brevo_write_unknown" : "brevo_unavailable");
        // A duplicate/sent/processing response can mean an earlier dispatch reached the provider.
        if (ambiguous && structKeyExists(data,"code") && listFindNoCase("duplicate_request,campaign_sent,campaign_processing,Request already processed",data.code)) fail("brevo_write_unknown");
        fail("brevo_rejected");
    }

    private numeric function createdId(required struct result,string key="id") {
        if (!structKeyExists(result,key) || !validId(result[key])) fail("brevo_write_unknown");
        return resourceId(result[key]);
    }

    private struct function registeredWebhook(required string token) {
        var result = api("GET","/webhooks?type=marketing",200);
        if (!structKeyExists(result,"webhooks") || !isArray(result.webhooks)) fail("brevo_invalid_response");
        var match = {found=false,verified=false,id=0,authReported=false,tokenCompared=false};
        for (var hook in result.webhooks) {
            if (!isStruct(hook) || !structKeyExists(hook,"url") || compare(hook.url,variables.webhookUrl)) continue;
            if (match.found) fail("brevo_webhook_conflict");
            match.found = true;
            if (!structKeyExists(hook,"id") || !validId(hook.id)) fail("brevo_invalid_response");
            match.id = hook.id;
            var usable = structKeyExists(hook,"type") && hook.type == "marketing" && structKeyExists(hook,"events") && isArray(hook.events)
                && (!structKeyExists(hook,"channel") || hook.channel == "email")
                && (!structKeyExists(hook,"batched") || (isBoolean(hook.batched) && !hook.batched))
                && (!structKeyExists(hook,"disabled") || (isBoolean(hook.disabled) && !hook.disabled))
                && (!structKeyExists(hook,"active") || (isBoolean(hook.active) && hook.active));
            if (usable) {
                for (var eventName in variables.events) {
                    if (!arrayFindNoCase(hook.events,eventName)) usable = false;
                }
            }
            if (structKeyExists(hook,"auth") && isStruct(hook.auth)) {
                match.authReported = true;
                usable = usable && structKeyExists(hook.auth,"type") && hook.auth.type == "bearer";
                if (structKeyExists(hook.auth,"token") && len(hook.auth.token) && !find("***",hook.auth.token)) {
                    match.tokenCompared = true;
                    usable = usable && compare(hook.auth.token,token) == 0;
                }
            }
            match.verified = usable;
        }
        return match;
    }

    public struct function verifySetup() {
        var setup = {ready=false,senderVerified=false,folderVerified=false,webhookVerified=false,senderEmail="",webhookId=0,webhookAuthReported=false,webhookTokenCompared=false};
        if (!readiness().configured) return setup;
        var senders = api("GET","/senders",200);
        if (!structKeyExists(senders,"senders") || !isArray(senders.senders)) fail("brevo_invalid_response");
        for (var sender in senders.senders) {
            if (!structKeyExists(sender,"id") || sender.id != variables.settings.senderId) continue;
            setup.senderVerified = structKeyExists(sender,"active") && isBoolean(sender.active) && sender.active
                && structKeyExists(sender,"email") && variables.addresses.isValidAddress(sender.email);
            if (setup.senderVerified) setup.senderEmail = sender.email;
        }
        var folder = api("GET","/contacts/folders/" & configuredId("folderId"),200);
        setup.folderVerified = structKeyExists(folder,"id") && folder.id == variables.settings.folderId;
        var hook = registeredWebhook(variables.settings.webhookToken);
        setup.webhookVerified = hook.verified;
        setup.webhookAuthReported = hook.authReported;
        setup.webhookTokenCompared = hook.tokenCompared;
        setup.webhookId = hook.id;
        setup.ready = setup.senderVerified && setup.folderVerified && setup.webhookVerified;
        return setup;
    }

    public numeric function registerWebhook() {
        if (!readiness().configured) fail("brevo_setup_incomplete");
        var token = variables.settings.webhookToken;
        var hook = registeredWebhook(token);
        if (hook.verified) {
            // The list API may omit or redact auth. Explicit registration reapplies the known bearer to this same hook.
            if (!hook.tokenCompared) api("PUT","/webhooks/" & resourceId(hook.id),204,{"auth"={"type"="bearer","token"=token}});
            return hook.id;
        }
        if (hook.found) fail("brevo_webhook_conflict");
        return createdId(api("POST","/webhooks",201,{"url"=variables.webhookUrl,"type"="marketing","channel"="email","batched"=false,
            "events"=variables.events,"auth"={"type"="bearer","token"=token},"description"="Road Runners | CRM de ofertas"},true));
    }

    private string function checkedName(required string name) {
        if (!len(trim(name)) || len(name)>100 || reFind("[[:cntrl:]]",name)) fail("brevo_invalid_input");
        return name;
    }

    public numeric function createList(required string name) {
        return createdId(api("POST","/contacts/lists",201,{"name"=checkedName(name),"folderId"=configuredId("folderId")},true));
    }

    private struct function addressSet(required array emails) {
        if (arrayLen(emails)>200) fail("brevo_invalid_input");
        var addresses = {};
        for (var address in emails) {
            if (!isSimpleValue(address) || !variables.addresses.isValidAddress(trim(address))) fail("brevo_invalid_input");
            var normalized = lCase(trim(address));
            addresses[normalized] = normalized;
        }
        return addresses;
    }

    public numeric function importContacts(required numeric listId,required array emails) {
        var set = addressSet(emails);
        var contacts = [];
        for (var address in set) arrayAppend(contacts,{"email"=set[address]});
        if (arrayIsEmpty(contacts)) fail("brevo_invalid_input");
        // Skip changes to existing contacts, consent groups and blocklists. List membership is handled independently.
        return createdId(api("POST","/contacts/import",202,{"listIds"=[resourceId(listId)],"jsonBody"=contacts,"disableNotification"=true,"updateExistingContacts"=false},true),"processId");
    }

    public string function processStatus(required numeric processId) {
        var result = api("GET","/processes/" & resourceId(processId),200);
        if (!structKeyExists(result,"id") || result.id != processId || !structKeyExists(result,"status")
            || !structKeyExists(result,"name") || result.name != "IMPORTUSER") fail("brevo_invalid_response");
        switch (result.status) {
            case "queued": return "queued";
            case "processing": case "in_process": return "running";
            case "completed": return "completed";
            case "cancelled": case "failed": return "failed";
        }
        fail("brevo_invalid_response");
    }

    private string function listPath(required string name,required numeric listId) {
        var path = "/contacts/lists/" & resourceId(listId);
        var data = api("GET",path,200);
        if (!structKeyExists(data,"name") || compare(data.name,checkedName(name)) || !structKeyExists(data,"id") || data.id != listId
            || !structKeyExists(data,"folderId") || data.folderId != variables.settings.folderId
            || (structKeyExists(data,"dynamicList") && (!isBoolean(data.dynamicList) || data.dynamicList))) fail("brevo_audience_changed");
        return path & "/contacts";
    }

    private boolean function isSuppressed(required struct contact) {
        if (!structKeyExists(contact,"emailBlacklisted") || !isBoolean(contact.emailBlacklisted)) fail("brevo_invalid_response");
        if (contact.emailBlacklisted) return true;
        if (structKeyExists(contact,"listUnsubscribed")) {
            if (!isArray(contact.listUnsubscribed)) fail("brevo_invalid_response");
            if (arrayLen(contact.listUnsubscribed)) return true;
        }
        if (structKeyExists(contact,"consentGroups")) {
            if (!isArray(contact.consentGroups)) fail("brevo_invalid_response");
            for (var group in contact.consentGroups) {
                if (!isStruct(group) || !structKeyExists(group,"status") || group.status != "subscribed") return true;
            }
        }
        return false;
    }

    private struct function members(required string path) {
        var page = api("GET",path & "?limit=500&offset=0",200);
        if (!structKeyExists(page,"contacts") || !isArray(page.contacts) || !structKeyExists(page,"count") || !isNumeric(page.count)
            || page.count != arrayLen(page.contacts) || page.count > 500) fail("brevo_audience_changed");
        var rows = {};
        for (var contact in page.contacts) {
            if (!isStruct(contact) || !structKeyExists(contact,"email") || !variables.addresses.isValidAddress(contact.email)) fail("brevo_audience_changed");
            var email = lCase(contact.email);
            if (structKeyExists(rows,email)) fail("brevo_audience_changed");
            rows[email] = {email=email,suppressed=isSuppressed(contact)};
        }
        return rows;
    }

    public struct function syncList(required string name,required numeric listId,required array emails) {
        var wanted = addressSet(emails);
        var path = listPath(name,listId);
        var rows = members(path);
        var missing = [];
        var exclude = [];
        for (var email in wanted) {
            if (!structKeyExists(rows,email)) arrayAppend(missing,wanted[email]);
        }
        if (arrayLen(missing)) {
            // Membership only, including existing contacts an import deliberately did not update.
            try {
                api("POST",path & "/add",201,{"emails"=missing});
            } catch (Brevo.Marketing addError) {
                // When no missing address exists at Brevo, the bulk add may reject the whole request.
                // The subsequent complete list read determines membership even after partial success.
                if (addError.message != "brevo_rejected") rethrow;
            }
            rows = members(path);
        }
        for (var email in rows) {
            if (!structKeyExists(wanted,email) || rows[email].suppressed) arrayAppend(exclude,rows[email].email);
        }
        if (arrayLen(exclude)) {
            api("POST",path & "/remove",201,{"emails"=exclude});
            rows = members(path);
        }
        for (var email in rows) {
            if (!structKeyExists(wanted,email) || rows[email].suppressed) fail("brevo_audience_changed");
        }
        var result = {eligible=[],suppressed=[]};
        for (var email in wanted) arrayAppend(structKeyExists(rows,email) ? result.eligible : result.suppressed,wanted[email]);
        return result;
    }

    public numeric function createDraft(required string name,required numeric listId) {
        var filename = getDirectoryFromPath(getCurrentTemplatePath()) & "../docs/campanhas/selo-atleta-2026-11-27-brevo.html";
        var html = fileRead(filename,"utf-8");
        if (!find('href="{{ unsubscribe }}"',html) || !find("utm_campaign=selo-atleta-20261127",html)) fail("brevo_template_invalid");
        return createdId(api("POST","/emailCampaigns",201,{"name"=checkedName(name),"subject"=variables.subject,
            "previewText"="Um ano inteiro. Pelo preço de um mês. R$ 9,90 por 12 meses, em um único pagamento por Pix ou cartão.",
            "htmlContent"=html,"sender"={"id"=configuredId("senderId")},
            "utmSource"="brevo","utmMedium"="email","utmCampaign"="seloatleta20261127",
            "recipients"={"listIds"=[resourceId(listId)]}},true));
    }

    public struct function campaign(required numeric campaignId) {
        var data = api("GET","/emailCampaigns/" & resourceId(campaignId) & "?statistics=globalStats&excludeHtmlContent=true",200);
        if (!structKeyExists(data,"id") || data.id != campaignId || !structKeyExists(data,"name") || !structKeyExists(data,"status")
            || !structKeyExists(data,"recipients") || !isStruct(data.recipients) || !structKeyExists(data.recipients,"lists") || !isArray(data.recipients.lists)) fail("brevo_invalid_response");
        var onlyLists = true;
        for (var key in ["exclusionLists","segments","excludedSegments"]) {
            if (structKeyExists(data.recipients,key) && (!isArray(data.recipients[key]) || arrayLen(data.recipients[key]))) onlyLists = false;
        }
        var stats = {};
        if (structKeyExists(data,"statistics") && isStruct(data.statistics) && structKeyExists(data.statistics,"globalStats") && isStruct(data.statistics.globalStats)) {
            for (var key in ["sent","delivered","uniqueViews","uniqueClicks","clickers","unsubscriptions","hardBounces","softBounces","complaints","appleMppOpens"]) {
                if (structKeyExists(data.statistics.globalStats,key) && isNumeric(data.statistics.globalStats[key])) stats[key] = val(data.statistics.globalStats[key]);
            }
        }
        return {id=data.id,name=data.name,status=data.status,listIds=data.recipients.lists,onlyLists=onlyLists,statistics=stats,
            senderId=structKeyExists(data,"sender") && isStruct(data.sender) && structKeyExists(data.sender,"id") ? data.sender.id : 0,
            subject=structKeyExists(data,"subject") ? data.subject : "",type=structKeyExists(data,"type") ? data.type : ""};
    }

    public boolean function verifyDraftAudience(required numeric campaignId,required string name,required numeric listId,required array eligibleEmails) {
        var expected = addressSet(eligibleEmails);
        if (structIsEmpty(expected)) fail("brevo_audience_changed");
        var draft = campaign(campaignId);
        if (draft.status != "draft" || compare(draft.name,checkedName(name)) || draft.senderId != variables.settings.senderId
            || draft.type != "classic" || compare(draft.subject,variables.subject) || !draft.onlyLists || arrayLen(draft.listIds) != 1 || draft.listIds[1] != listId)
            fail("brevo_draft_changed");
        var rows = members(listPath(name,listId));
        if (structCount(rows) != structCount(expected)) fail("brevo_audience_changed");
        for (var email in expected) {
            if (!structKeyExists(rows,email) || rows[email].suppressed) fail("brevo_audience_changed");
        }
        return true;
    }

    // The worker calls this immediately after its final local authorization and dispatch checkpoint.
    public boolean function sendValidated(required numeric campaignId) {
        api("POST","/emailCampaigns/" & resourceId(campaignId) & "/sendNow",204,{},true);
        return true;
    }
    public boolean function sendNow(required numeric campaignId,required string name,required numeric listId,required array eligibleEmails) {
        verifyDraftAudience(campaignId,name,listId,eligibleEmails);
        return sendValidated(campaignId);
    }
}
