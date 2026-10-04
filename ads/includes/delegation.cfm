<cfscript>
function adsDelegationContext() {
    return structKeyExists(REQUEST,'businessAccessContext') ? REQUEST.businessAccessContext : {};
}
function adsDelegationValidate(required struct posted,required string capability) {
    var context=adsDelegationContext();
    if(structIsEmpty(context)) return context;
    if(context.accessMode!='DELEGATED' AND !structKeyExists(posted,'business_access_token')) return {};
    var service=createObject('component','services.BusinessAccountDelegation').init('runnerhub',structKeyExists(APPLICATION,'businessAccountDelegationEnabled') AND APPLICATION.businessAccountDelegationEnabled);
    var policy=createObject('component','services.accountDelegation.Policy');
    service.verifyForm(context,policy.postedContext(posted),SESSION.businessDelegationFormSeed);
    var fresh=service.resolve({id=context.actorId},context);
    policy.assertExpected(fresh,context);
    if(!service.has(fresh,capability)) policy.fail('Forbidden','Capability not granted');
    return fresh;
}
function adsDelegationMutation(required struct posted,required string capability,required struct resource,required any work,struct state={}) {
    var context=adsDelegationValidate(posted,capability);
    var callback=work; var callbackState=state;
    var bound=function(fresh){return callback(fresh,callbackState);};
    if(structIsEmpty(context)) { transaction { return bound({datasource='runnerhub'}); } }
    return createObject('component','services.BusinessAccountDelegation').init('runnerhub',structKeyExists(APPLICATION,'businessAccountDelegationEnabled') AND APPLICATION.businessAccountDelegationEnabled)
        .withMutation(context,capability,context,resource,bound);
}
</cfscript>
