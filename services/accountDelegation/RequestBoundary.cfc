component output=false {
    public any function init(required string datasource, boolean enabled=false) {
        variables.enabled=enabled;
        variables.policy=createObject('component','services.accountDelegation.Policy');
        variables.service=createObject('component','services.BusinessAccountDelegation').init(datasource,enabled);
        variables.store=createObject('component','services.accountDelegation.Store').init(datasource);
        return this;
    }
    public void function ensureSeed(required struct state) {
        if(!structKeyExists(state,'businessDelegationFormSeed') || !isSimpleValue(state.businessDelegationFormSeed) || len(state.businessDelegationFormSeed)<32)
            state.businessDelegationFormSeed=lCase(hash(generateSecretKey('AES',256),'SHA-256'));
    }
    private string function selectionStamp(required struct state) {
        if(structKeyExists(state,'businessAccessSelectionInvalid') && state.businessAccessSelectionInvalid) return 'CHOOSE_AGAIN';
        if(structKeyExists(state,'businessAccessSelection')) return variables.policy.selectionKey(state.businessAccessSelection);
        return 'UNSELECTED';
    }
    public struct function selectionFields(required struct state) {
        ensureSeed(state);
        var stamp=selectionStamp(state);
        return {business_selection_expected=stamp,business_selection_csrf=lCase(hmac('select:' & stamp,state.businessDelegationFormSeed,'HmacSHA256','UTF-8'))};
    }
    // Called only after the legacy selector has validated and stored an explicit choice.
    // Never clear a failed/delegated selection through this compatibility path.
    public void function clearLegacySelection(required struct state) {
        if(structKeyExists(state,'businessAccessSelectionInvalid') && state.businessAccessSelectionInvalid) variables.policy.fail('Forbidden','Choose an available access explicitly');
        if(structKeyExists(state,'businessAccessSelection')) {
            var previous=variables.policy.normalizeSelection(state.businessAccessSelection);
            if(previous.accessMode=='DELEGATED') variables.policy.fail('Forbidden','Delegated selection requires the canonical selector');
            structDelete(state,'businessAccessSelection',false);
        }
    }
    private void function invalidate(required struct state) {
        for(var key in ['businessAccessSelection','businessActiveAccountId','businessSimulatedAccountId','businessAccountSelectionConfirmed']) structDelete(state,key,false);
        state.businessAccessSelectionInvalid=true;
    }
    public struct function handle(required struct identity,required struct state,required string targetPath,required string method,required struct query,required struct form,string pathInfo='',string rawQuery='',string rawBody='',boolean multipartValid=true) {
        var result={status=200,context={},invalid=false,route={allowed=true,capability='',action=''},selectionChanged=false,selectionRequired=false};
        var recovery=listFind('/selecionar-conta/,/selecionar-conta/index.cfm,/logout.cfm,/convites/,/convites/index.cfm',targetPath)>0;
        var selector=listFind('/selecionar-conta/,/selecionar-conta/index.cfm',targetPath)>0;
        var hasSelection=structKeyExists(state,'businessAccessSelection');
        var invalid=structKeyExists(state,'businessAccessSelectionInvalid') && state.businessAccessSelectionInvalid;
        var restricted=invalid || (hasSelection && (!isStruct(state.businessAccessSelection) || !structKeyExists(state.businessAccessSelection,'accessMode') || state.businessAccessSelection.accessMode=='DELEGATED'));
        var signedForm=structKeyExists(arguments.form,'business_access_token');
        if(!variables.enabled && !restricted && !signedForm && !hasSelection) return result;
        var recoveryAllowed=recovery;
        if(recovery) {
            try {recoveryAllowed=multipartValid && !len(pathInfo) && variables.policy.uniqueParameters(rawQuery) && variables.policy.uniqueParameters(rawBody) && variables.policy.routePolicy(targetPath,method,arguments.query,arguments.form).allowed;}
            catch(any malformedRecovery) {recoveryAllowed=false;}
        }
        // Invitation receiver is a recovery route even for a still-valid direct selection.
        // Refuse global actions before Application.cfc can process them.
        if(listFind('/convites/,/convites/index.cfm',targetPath) && !recoveryAllowed) {result.status=403;return result;}
        if(structIsEmpty(identity)) {if(restricted) {invalidate(state);result.status=recoveryAllowed?200:403;result.invalid=true;}return result;}
        ensureSeed(state);
        if(selector && uCase(method)=='POST') {
            try {
                if(!multipartValid || len(pathInfo) || !variables.policy.uniqueParameters(rawQuery) || !variables.policy.uniqueParameters(rawBody) || !variables.policy.routePolicy(targetPath,method,arguments.query,arguments.form).allowed) variables.policy.fail('Forbidden','Ambiguous request');
                var fields=selectionFields(state);
                for(var key in fields) if(!structKeyExists(arguments.form,key) || !isSimpleValue(arguments.form[key])) variables.policy.fail('Forbidden','Selection token required');
                if(compare(fields.business_selection_expected,arguments.form.business_selection_expected)!=0) variables.policy.fail('Conflict','Selection changed in another tab');
                if(!createObject('java','java.security.MessageDigest').isEqual(charsetDecode(fields.business_selection_csrf,'UTF-8'),charsetDecode(arguments.form.business_selection_csrf & '','UTF-8'))) variables.policy.fail('Forbidden','Selection token invalid');
                // The unscoped internal workspace is real DIRECT admin, not an operational client context.
                if(structKeyExists(arguments.form,'accountId') && isSimpleValue(arguments.form.accountId) && arguments.form.accountId=='0' && structKeyExists(arguments.form,'accessMode') && isSimpleValue(arguments.form.accessMode) && arguments.form.accessMode=='DIRECT') {
                    if(variables.policy.identifier(structKeyExists(arguments.form,'managerAccountId')?arguments.form.managerAccountId:0,true)!='0' || variables.policy.identifier(structKeyExists(arguments.form,'relationshipId')?arguments.form.relationshipId:0,true)!='0') variables.policy.fail('Validation','Mixed access paths');
                    var actor=variables.store.actor(variables.policy.identifier(identity.id));
                    if(structIsEmpty(actor) || !actor.is_admin) variables.policy.fail('Forbidden','Internal access required');
                    for(var key in ['businessAccessSelection','businessAccessSelectionInvalid','businessActiveAccountId','businessSimulatedAccountId']) structDelete(state,key,false);
                    state.businessAccountSelectionConfirmed=true;result.selectionChanged=true;return result;
                }
                try {
                    var selection=variables.policy.normalizeSelection(arguments.form);
                    result.context=variables.service.resolve(identity,selection);
                } catch(any badSelection) {invalidate(state);result.invalid=true;rethrow;}
                state.businessAccessSelection=selection;structDelete(state,'businessAccessSelectionInvalid',false);
                structDelete(state,'businessActiveAccountId',false);structDelete(state,'businessSimulatedAccountId',false);
                if(selection.accessMode=='DIRECT') state.businessActiveAccountId=selection.accountId;
                if(selection.accessMode=='INTERNAL_SIMULATION') state.businessSimulatedAccountId=selection.accountId;
                state.businessAccountSelectionConfirmed=true;result.selectionChanged=true;return result;
            } catch(any selectionError) {result.context={};result.status=selectionError.type=='BusinessDelegation.Conflict'?409:403;return result;}
        }
        if(invalid) {result.invalid=true;result.status=recoveryAllowed?200:403;return result;}
        if(!hasSelection) {
            // Adopt only an existing explicit legacy selection. Fresh/pending/direct-admin paths stay legacy.
            if(structKeyExists(state,'businessSimulatedAccountId')) state.businessAccessSelection={accountId=state.businessSimulatedAccountId,accessMode='INTERNAL_SIMULATION',managerAccountId=0,relationshipId=0};
            else if(structKeyExists(state,'businessActiveAccountId')) state.businessAccessSelection={accountId=state.businessActiveAccountId,accessMode='DIRECT',managerAccountId=0,relationshipId=0};
            else {
                if(signedForm) {result.status=409;return result;}
                var actor=variables.store.actor(variables.policy.identifier(identity.id));
                if(!structIsEmpty(actor) && !actor.is_admin) {
                    var options=variables.service.listAccess(identity);
                    if(arrayLen(options)>1 || (arrayLen(options)==1 && options[1].selection.accessMode=='DELEGATED')) result.selectionRequired=true;
                    else if(arrayLen(options)==1 && options[1].selection.accessMode=='DIRECT') {
                        state.businessAccessSelection=options[1].selection;
                        state.businessActiveAccountId=options[1].selection.accountId;
                        hasSelection=true;
                    }
                }
                if(!hasSelection) return result;
            }
        }
        try {result.context=variables.service.resolve(identity,state.businessAccessSelection);}
        catch(any unavailable) {invalidate(state);result.context={};result.invalid=true;result.status=recoveryAllowed?200:403;return result;}
        if(result.context.accessMode!='DELEGATED') {
            if(signedForm && uCase(method)=='POST') {
                try {if(!multipartValid) variables.policy.fail('Forbidden','Ambiguous multipart fields');variables.service.verifyForm(result.context,variables.policy.postedContext(arguments.form),state.businessDelegationFormSeed);}
                catch(any staleDirectForm) {result.status=staleDirectForm.type=='BusinessDelegation.Conflict'?409:403;}
            }
            return result;
        }
        try {
            if(!multipartValid || len(pathInfo) || !variables.policy.uniqueParameters(rawQuery) || !variables.policy.uniqueParameters(rawBody)) variables.policy.fail('Forbidden','Ambiguous request');
            result.route=variables.policy.routePolicy(targetPath,method,arguments.query,arguments.form);
            if(!result.route.allowed) variables.policy.fail('Forbidden','Route unavailable for delegated access');
            // Check the rendered context first: a stale form must never become a mutation on the new client.
            if(uCase(method)=='POST' && !selector) variables.service.verifyForm(result.context,variables.policy.postedContext(arguments.form),state.businessDelegationFormSeed);
            if(len(result.route.capability) && !variables.service.has(result.context,result.route.capability)) {
                var ownReceipt=false;
                if(result.route.capability=='ads.payments.view' && uCase(method)=='GET' && variables.service.has(result.context,'ads.credits.purchase')) {
                    var paymentPage=listFind('/ads/,/ads/index.cfm',targetPath) && structKeyExists(arguments.query,'view') && arguments.query.view=='payments';
                    var paymentId=structKeyExists(arguments.query,'payment')?arguments.query.payment:'';
                    ownReceipt=(paymentPage && !len(paymentId)) || ((paymentPage || targetPath=='/api/ads/payments/status.cfm') && variables.store.paymentReceipt(result.context,paymentId));
                }
                if(!ownReceipt) variables.policy.fail('Forbidden','Capability not granted');
            }
        } catch(any denial) {result.status=denial.type=='BusinessDelegation.Conflict'?409:403;}
        return result;
    }
}
