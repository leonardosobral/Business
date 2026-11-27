component output=false {
    public string function configuredToken(){
        var env=createObject('java','java.lang.System').getenv();
        if(structKeyExists(env,'RR_BREVO_WEBHOOK_TOKEN') && len(trim(env['RR_BREVO_WEBHOOK_TOKEN'])))
            return trim(env['RR_BREVO_WEBHOOK_TOKEN']);
        var businessLocalConfig={};
        if(fileExists(expandPath('/config/business.local.cfm'))){
            variables.businessLocalConfig={};
            include '/config/business.local.cfm';
            structAppend(businessLocalConfig,variables.businessLocalConfig,true);
        }
        return structKeyExists(businessLocalConfig,'brevoWebhookToken') ? trim(businessLocalConfig.brevoWebhookToken) : '';
    }

    public boolean function ready(){
        return len(configuredToken())>=32;
    }

    public void function authenticate(required struct headers){
        verifyToken(headers,configuredToken());
    }

    public void function verifyToken(required struct headers,required string secret){
        if(len(secret)<32 || !structKeyExists(headers,'Authorization') || !isSimpleValue(headers.Authorization))
            throw(type='BrevoWebhook.Forbidden');
        var header=headers.Authorization;
        if(len(header)>4096 || compareNoCase(left(header,7),'Bearer ')!=0) throw(type='BrevoWebhook.Forbidden');
        var token=removeChars(header,1,7);
        var digest=createObject('java','java.security.MessageDigest');
        if(!digest.isEqual(charsetDecode(token,'utf-8'),charsetDecode(secret,'utf-8'))) throw(type='BrevoWebhook.Forbidden');
    }

    public array function parseEvents(required string body){
        if(len(body)>2097152) throw(type='BrevoWebhook.TooLarge');
        var firstCharacter=left(trim(body),1);
        if((firstCharacter!='{' && firstCharacter!='[') || !isJSON(body)) throw(type='BrevoWebhook.Invalid');
        var payload=deserializeJSON(body);
        if(!isStruct(payload) && !isArray(payload)) throw(type='BrevoWebhook.Invalid');
        var incoming=isArray(payload) ? payload : [payload];
        if(arrayLen(incoming)>500) throw(type='BrevoWebhook.TooLarge');
        var events=[];
        for(var item in incoming){
            if(isNull(item) || !isStruct(item) || isNull(item.event) || !isSimpleValue(item.event)) continue;
            var kind=lCase(trim(item.event));
            if(!listFind('delivered,opened,click,soft_bounce,hard_bounce,unsubscribe,spam',kind)) continue;
            if(isNull(item.camp_id) || !isSimpleValue(item.camp_id) || !reFind('^[1-9][0-9]{0,17}$',item.camp_id)) continue;
            if(isNull(item.email) || !isSimpleValue(item.email)) continue;
            var email=lCase(trim(item.email));
            if(!len(email) || len(email)>254 || !find('@',email)) continue;
            var epoch=!isNull(item.ts_event) ? item.ts_event : !isNull(item.ts) ? item.ts : '';
            if(!isSimpleValue(epoch) || !reFind('^[1-9][0-9]{0,9}$',epoch)) continue;
            arrayAppend(events,{campaign=item.camp_id,email=email,kind=kind,epoch=epoch});
        }
        return events;
    }

    public void function accept(required string body){
        var events=parseEvents(body);
        if(!arrayLen(events)) return;
        transaction {
            for(var event in events){
                queryExecute(
                    'SELECT crm_interno.record_brevo_marketing_event(:campaign,:email,:kind,:epoch)',
                    {campaign={value=event.campaign,cfsqltype='cf_sql_bigint'},email={value=event.email,cfsqltype='cf_sql_varchar'},
                     kind={value=event.kind,cfsqltype='cf_sql_varchar'},epoch={value=event.epoch,cfsqltype='cf_sql_bigint'}},
                    {datasource='runner_dba',timeout=12}
                );
            }
        }
    }
}
