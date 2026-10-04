component output=false {
    public array function catalog() {
        return ['ads.campaigns.view','ads.campaigns.manage','ads.payments.view','ads.credits.purchase','events.view','events.manage','events.links.request'];
    }
    public string function identifier(required any value, boolean allowZero=false) {
        if (!isSimpleValue(value) || !reFind('^[0-9]{1,19}$',value & '')) fail('Validation','Invalid scalar identifier');
        var canonical=reReplace(value & '','^0+(?=[0-9])','');
        var integer=createObject('java','java.math.BigInteger').init(canonical);
        if (integer.compareTo(createObject('java','java.math.BigInteger').init('9223372036854775807'))>0 || (!allowZero && canonical=='0')) fail('Validation','Invalid identifier range');
        return canonical;
    }
    public struct function selection(required struct input) {
        for (var key in ['accountId','accessMode']) if (!structKeyExists(input,key)) fail('Validation','Missing selection');
        if (!isSimpleValue(input.accessMode) || !listFind('DIRECT,DELEGATED,INTERNAL_SIMULATION',input.accessMode)) fail('Validation','Invalid access mode');
        var result={accountId=identifier(input.accountId),accessMode=input.accessMode,
            managerAccountId=identifier(structKeyExists(input,'managerAccountId')?input.managerAccountId:0,true),
            relationshipId=identifier(structKeyExists(input,'relationshipId')?input.relationshipId:0,true)};
        if (result.accessMode=='DELEGATED') {
            if (result.managerAccountId=='0' || result.relationshipId=='0' || result.managerAccountId==result.accountId) fail('Validation','Incomplete delegated selection');
        } else if (result.managerAccountId!='0' || result.relationshipId!='0') fail('Validation','Mixed access paths');
        return result;
    }
    public string function selectionKey(required struct input) {
        var s=selection(input);
        return toBase64(s.accessMode & ':' & s.accountId & ':' & s.managerAccountId & ':' & s.relationshipId,'UTF-8');
    }
    public array function expand(required array granted) {
        var result=[];
        for(var cap in catalog()) if(arrayFind(granted,cap)) arrayAppend(result,cap);
        if(arrayFind(result,'ads.campaigns.manage') && !arrayFind(result,'ads.campaigns.view')) arrayAppend(result,'ads.campaigns.view');
        if((arrayFind(result,'events.manage') || arrayFind(result,'events.links.request')) && !arrayFind(result,'events.view')) arrayAppend(result,'events.view');
        return result;
    }
    public array function capabilities(required array clientGrants, required array member, required string role) {
        var left=expand(arguments.clientGrants);var memberCaps=expand(member);var result=[];
        if(!listFind('OWNER,ADMIN,OPERADOR,VISUALIZADOR',role)) return result;
        for(var cap in catalog()) if(arrayFind(left,cap) && arrayFind(memberCaps,cap)
            && (role!='VISUALIZADOR' || right(cap,5)=='.view')) arrayAppend(result,cap);
        if(!arrayFind(result,'ads.campaigns.view')) {
            arrayDelete(result,'ads.payments.view');arrayDelete(result,'ads.credits.purchase');
        }
        return result;
    }
    public array function directCapabilities(required string role, required array grants, boolean realInternalAdmin=false) {
        // Existing Ads access.cfm authority: direct roles remain independent of newly seeded catalog rows.
        var result=capabilities(grants,grants,role);
        for(var cap in ['ads.campaigns.view','ads.campaigns.manage','ads.payments.view','ads.credits.purchase']) arrayDelete(result,cap);
        if(listFind('OWNER,ADMIN,OPERADOR,VISUALIZADOR',role)) arrayAppend(result,'ads.campaigns.view');
        if(listFind('OWNER,ADMIN,OPERADOR',role)) arrayAppend(result,'ads.campaigns.manage');
        if(listFind('OWNER,ADMIN',role)) {arrayAppend(result,'ads.payments.view');arrayAppend(result,'ads.credits.purchase');}
        // Only DIRECT resolution supplies current DB is_admin; delegated grants never enter here.
        if(realInternalAdmin) for(var cap in ['ads.campaigns.view','ads.campaigns.manage','ads.payments.view','ads.credits.purchase'])
            if(!arrayFind(result,cap)) arrayAppend(result,cap);
        return result;
    }
    public string function stamp(required struct context) {
        var s=selection(context);
        if(!structKeyExists(context,'actorId') || !structKeyExists(context,'versions') || !isStruct(context.versions)) fail('Validation','Missing context versions');
        var parts=[identifier(context.actorId),s.accountId,s.accessMode,s.managerAccountId,s.relationshipId];
        for(var key in ['managerVersion','relationshipVersion','assignmentVersion','membershipId']) {
            if(!structKeyExists(context.versions,key)) fail('Validation','Missing version');
            arrayAppend(parts,identifier(context.versions[key],true));
        }
        return arrayToList(parts,':');
    }
    public void function assertExpected(required struct context, required struct expected) {
        if(compare(stamp(context),stamp(expected))!=0) fail('Conflict','The selected access or its grants changed');
    }
    public string function formToken(required struct context, required string seed) {
        if(len(seed)<32) fail('Validation','Session form seed is required');
        return lCase(hmac(stamp(context),seed,'HmacSHA256','UTF-8'));
    }
    public void function verifyForm(required struct context, required struct posted, required string seed) {
        assertExpected(context,posted);
        if(!structKeyExists(posted,'formToken') || !isSimpleValue(posted.formToken) || !reFind('^[a-f0-9]{64}$',posted.formToken)) fail('Validation','Invalid form token');
        var expected=formToken(context,seed);
        if(!createObject('java','java.security.MessageDigest').isEqual(charsetDecode(expected,'UTF-8'),charsetDecode(posted.formToken,'UTF-8'))) fail('Forbidden','Invalid form token');
    }
    public void function fail(required string kind,required string message) { throw(type='BusinessDelegation.' & kind,message=message); }
    public struct function normalizeSelection(required struct posted) { return selection(posted); }
    public struct function formFields(required struct context, required string token) {
        var fields={business_access_token=token};
        for(var key in ['actorId','accountId','accessMode','managerAccountId','relationshipId']) fields['business_access_' & key]=context[key];
        for(var key in ['managerVersion','relationshipVersion','assignmentVersion','membershipId']) fields['business_access_' & key]=context.versions[key];
        return fields;
    }
    public struct function postedContext(required struct form) {
        var posted={versions={}};
        for(var key in ['actorId','accountId','accessMode','managerAccountId','relationshipId','managerVersion','relationshipVersion','assignmentVersion','membershipId','token']) {
            var field='business_access_' & key;
            if(!structKeyExists(arguments.form,field) || !isSimpleValue(arguments.form[field])) fail('Validation','Missing scalar form context');
            if(key=='token') posted.formToken=arguments.form[field];
            else if(listFind('managerVersion,relationshipVersion,assignmentVersion,membershipId',key)) posted.versions[key]=arguments.form[field];
            else posted[key]=arguments.form[field];
        }
        stamp(posted);return posted;
    }
    public boolean function uniqueParameters(required string encoded) {
        var seen={};
        for(var pair in listToArray(encoded,'&')) {
            var key=lCase(urlDecode(listFirst(pair,'='),'UTF-8'));
            if(structKeyExists(seen,key)) return false;
            seen[key]=true;
        }
        return true;
    }
    public boolean function multipartFieldsValid(required string targetPath, required string method, required struct form, required array parts) {
        if(!arrayLen(parts)) return false;
        var fields={};
        for(var part in parts) {
            if(!structKeyExists(part,'name') || !isSimpleValue(part.name) || !reFind('^[A-Za-z][A-Za-z0-9_]{0,127}$',part.name)) return false;
            var key=lCase(part.name);
            if(!structKeyExists(fields,key)) fields[key]={count=0,file=false};
            fields[key].count++;
            if(structKeyExists(part,'isFile') && part.isFile) fields[key].file=true;
        }
        for(var key in fields) if(fields[key].count>1) {
            // These two existing banner checkbox collections are intentional repetitions.
            // Every context/action/ordinary scalar remains unique, including equal duplicates.
            if(!listFind('/portal/banners/,/portal/banners/index.cfm',lCase(targetPath)) || method!='POST'
                || !structKeyExists(arguments.form,'paid_banner_action') || !isSimpleValue(arguments.form.paid_banner_action) || arguments.form.paid_banner_action!='save'
                || !listFind('banner_pages,banner_regions',key) || fields[key].file || !structKeyExists(arguments.form,key) || !isSimpleValue(arguments.form[key])) return false;
            var values=listToArray(arguments.form[key] & '',',',true);
            if(arrayLen(values)!=fields[key].count) return false;
            var catalog=key=='banner_pages'?'home,search,state,event,athlete':'AC,AL,AP,AM,BA,CE,DF,ES,GO,MA,MT,MS,MG,PA,PB,PR,PE,PI,RJ,RN,RS,RO,RR,SC,SP,SE,TO';
            var seen={};
            for(var value in values) {
                if(!listFind(catalog,value) || structKeyExists(seen,value)) return false;
                seen[value]=true;
            }
        }
        return true;
    }
    public struct function routePolicy(required string targetPath, required string method, required struct query, required struct form) {
        var denied={allowed=false,capability='',action=''};
        var path=lCase(targetPath);var verb=uCase(method);var actionKey='';var action='';var cap='';
        if(!listFind('GET,POST',verb) || find('\\',path) || find('%',path) || find('//',path) || find('..',path)) return denied;
        // Classify the real endpoint and all action channels before a module can read data.
        var actionKeys='action,acao,ads_v1_action,paid_banner_action,evento_solicitacao_action,business_delegation_action';
        for(var source in [arguments.query,arguments.form]) for(var key in source) {
            if(!isSimpleValue(source[key])) return denied;
            if(reFindNoCase('(^id_|_id$|^business_access_|^accountId$|^managerAccountId$|^relationshipId$|^accessMode$|^expectedVersion$|^method$|^view$|^section$|^mode$|^tab$)',key) && find(',',source[key] & '')) return denied;
            if(listFindNoCase('resetApp,notificacao,business_account_context_id,banner_novo,banner_editar',key)) return denied;
            if(listFindNoCase(actionKeys,key) || reFindNoCase('(^|_)action$',key)) {
                if(structKeyExists(arguments.query,key) || len(actionKey) || !len(trim(source[key] & '')) || find(',',source[key] & '')) return denied;
                actionKey=lCase(key);action=source[key] & '';
            }
        }
        if(verb=='GET' && len(actionKey)) return denied;
        if(listFind('/,/index.cfm',path)) {if(verb!='GET') return denied;}
        else if(listFind('/logout.cfm',path)) {if(verb!='GET' || len(actionKey)) return denied;}
        else if(listFind('/selecionar-conta/,/selecionar-conta/index.cfm',path)) {if(len(actionKey)) return denied;action='select';}
        else if(listFind('/convites/,/convites/index.cfm',path)) {
            if(verb=='GET') {for(var receiverKey in arguments.query) if(lCase(receiverKey)!='token') return denied;}
            else if(!structIsEmpty(arguments.query)) return denied;
            if(verb=='POST' && (actionKey!='action' || !listFind('accept,reject',action))) return denied;
        }
        else if(listFind('/gestao-clientes/,/gestao-clientes/index.cfm',path)) {
            // Lifecycle adapters check direct company authority. New actions require explicit classification.
            if(verb=='POST') {
                if(actionKey!='business_delegation_action' || !listFind('create_relationship_invite,request_relationship,decide_relationship,change_relationship,assign_member,remove_assignment,create_client,update_pending_client,invite_owner,accept_owner',action)) return denied;
            }
        }
        else if(path=='/ads/canonical/index.cfm') {if(verb!='GET' || len(actionKey)) return denied;cap='ads.campaigns.view';}
        else if(listFind('/ads/,/ads/index.cfm',path)) {
            cap='ads.campaigns.view';
            if(structKeyExists(arguments.query,'view')) {
                if(!listFind('overview,campaigns,campaign-detail,payments,history',arguments.query.view)) return denied;
                if(arguments.query.view=='payments') cap='ads.payments.view';
                if(arguments.query.view=='history' && structKeyExists(arguments.query,'history') && arguments.query.history=='legacy') return denied;
            }
            if(structKeyExists(arguments.query,'payment') && len(arguments.query.payment)) cap='ads.payments.view';
            if(verb=='POST') {
                if(actionKey!='ads_v1_action') return denied;
                if(listFind('save_campaign,prepare_campaign_edit,submit_campaign_review,change_campaign_status',action)) cap='ads.campaigns.manage';
                else if(action=='create_payment_checkout') cap='ads.credits.purchase';
                else return denied;
            }
        }
        else if(listFind('/portal/banners/,/portal/banners/index.cfm',path)) {
            cap='ads.campaigns.view';
            if((structKeyExists(arguments.query,'view') && arguments.query.view!='paid') || (structKeyExists(arguments.form,'view') && arguments.form.view!='paid') || structKeyExists(arguments.form,'acao')) return denied;
            if(verb=='POST') {if(actionKey!='paid_banner_action' || !listFind('save,submit,prepare,pause,end,resume',action)) return denied;cap='ads.campaigns.manage';}
        }
        else if(path=='/api/ads/payments/status.cfm') {
            if(verb!='GET') return denied;cap='ads.payments.view';action='payment_status';
        }
        else if(listFind('/eventos/,/eventos/index.cfm',path)) {
            cap='events.view';
            if(verb=='POST') {
                if(actionKey=='evento_solicitacao_action' && action=='solicitar') cap='events.links.request';
                else if(actionKey=='action' && listFind('editar_evento_basico,editar_evento_fornecedores,editar_evento_competition_id,editar_evento_descricao,editar_evento_percursos,salvar_evento_percurso',action)) cap='events.manage';
                else return denied;
            }
        } else return denied;
        return {allowed=true,capability=cap,action=action};
    }
}
