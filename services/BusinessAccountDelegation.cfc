component output=false {
    public any function init(required string datasource,boolean enabled=false) {
        if(!len(trim(datasource))) throw(type="BusinessDelegation.Validation",message="An explicit datasource is required");
        variables.datasource=arguments.datasource;variables.enabled=arguments.enabled;
        variables.store=createObject('component','services.accountDelegation.Store').init(datasource);
        variables.policy=createObject('component','services.accountDelegation.Policy');
        variables.invitations=createObject('component','services.accountDelegation.Invitations').init(datasource,variables.store,variables.policy);
        variables.accounts=createObject('component','services.accountDelegation.Accounts').init(datasource,variables.store,variables.policy);
        variables.workspace=createObject('component','services.accountDelegation.Workspace').init(variables.store,variables.policy);
        return this;
    }
    public struct function createRelationshipInvite(required struct identity,required numeric clientId,required numeric managerId,required array capabilities) { requireReady();return variables.invitations.createRelationshipInvite(argumentCollection=arguments); }
    public struct function requestRelationship(required struct identity,required numeric managerId,required string clientReference,required array capabilities) { requireReady();return variables.invitations.requestRelationship(argumentCollection=arguments); }
    public struct function decideRelationship(required struct identity,required numeric relationshipId,required numeric expectedVersion,required string decision,required array capabilities) { requireReady();return variables.invitations.decideRelationship(argumentCollection=arguments); }
    public struct function changeRelationship(required struct identity,required numeric relationshipId,required numeric expectedVersion,required string action,required array capabilities) { requireReady();return variables.invitations.changeRelationship(argumentCollection=arguments); }
    public struct function assignMember(required struct identity,required numeric relationshipId,required numeric membershipId,required numeric expectedVersion,required array capabilities) { requireReady();return variables.invitations.assignMember(argumentCollection=arguments); }
    public struct function removeAssignment(required struct identity,required numeric assignmentId,required numeric expectedVersion) { requireReady();return variables.invitations.removeAssignment(argumentCollection=arguments); }
    public struct function createClient(required struct identity,required numeric managerId,required struct fields,required array capabilities) { requireReady();return variables.accounts.createClient(argumentCollection=arguments); }
    public struct function updatePendingClient(required struct identity,required numeric relationshipId,required numeric expectedVersion,required struct fields) { requireReady();return variables.accounts.updatePendingClient(argumentCollection=arguments); }
    public struct function reviewCreatedClient(required struct identity,required numeric registrationId,required numeric expectedVersion,required string decision,required array capabilities) { requireReady();return variables.accounts.reviewCreatedClient(argumentCollection=arguments); }
    public struct function inviteOwner(required struct identity,required numeric relationshipId,required numeric expectedVersion,required string email) { requireReady();return variables.accounts.inviteOwner(argumentCollection=arguments); }
    public struct function inspectInvite(required struct identity,required string token) { requireReady();return variables.accounts.inspectInvite(argumentCollection=arguments); }
    public struct function acceptOwner(required struct identity,required string token,required numeric expectedVersion) { requireReady();return variables.accounts.acceptOwner(argumentCollection=arguments); }
    public struct function rejectOwner(required struct identity,required string token,required numeric expectedVersion) { requireReady();return variables.accounts.rejectOwner(argumentCollection=arguments); }
    public struct function listClients(required struct identity,required numeric managerId,struct filters={}) {requireReady();return variables.workspace.listClients(argumentCollection=arguments);}
    public struct function listTeam(required struct identity,required numeric managerId,struct filters={}) {requireReady();return variables.workspace.listTeam(argumentCollection=arguments);}
    public struct function listInvites(required struct identity,required numeric managerId,struct filters={}) {requireReady();return variables.workspace.listInvites(argumentCollection=arguments);}
    public struct function listAudit(required struct identity,required numeric managerId,struct filters={}) {requireReady();return variables.workspace.listAudit(argumentCollection=arguments);}
    public array function listClientManagers(required struct identity,required numeric clientId) {requireReady();return variables.workspace.listClientManagers(argumentCollection=arguments);}
    public struct function configureManager(required struct identity,required numeric accountId,required boolean enabled,required string classification,required numeric expectedVersion) {requireReady();return variables.workspace.configureManager(argumentCollection=arguments);}
    private void function requireReady() {
        if(!variables.enabled || !variables.store.schemaReady()) variables.policy.fail('Unavailable','Account delegation is unavailable');
    }
    public array function listAccess(required struct identity) {
        var actorId=variables.policy.identifier(structKeyExists(identity,'id')?identity.id:0);
        var actor=variables.store.actor(actorId);
        if(structIsEmpty(actor)) variables.policy.fail('Forbidden','Identity is inactive');
        var delegated=variables.enabled && variables.store.schemaReady();
        var result=variables.store.selections(actorId,delegated,actor.is_admin);
        for(var option in result) option.selectionKey=variables.policy.selectionKey(option.selection);
        return result;
    }
    public struct function resolve(required struct identity,required struct selection) {
        var s=variables.policy.selection(selection);
        var actorId=variables.policy.identifier(structKeyExists(identity,'id')?identity.id:0);
        if(s.accessMode=='DELEGATED') requireReady();
        var actor=variables.store.actor(actorId);
        if(structIsEmpty(actor)) variables.policy.fail('Forbidden','Identity is inactive');
        var account=variables.store.account(s.accountId);
        if(structIsEmpty(account) || account.status!='ATIVA') variables.policy.fail('Forbidden','Account is unavailable');
        var ctx={actorId=actorId,accountId=s.accountId,accessMode=s.accessMode,managerAccountId=s.managerAccountId,relationshipId=s.relationshipId,
            versions={managerVersion=0,relationshipVersion=0,assignmentVersion=0,membershipId=0},capabilities=[],selectionKey=variables.policy.selectionKey(s)};
        if(s.accessMode=='INTERNAL_SIMULATION') {
            if(!actor.is_admin) variables.policy.fail('Forbidden','Internal simulation requires administrator');
            ctx.capabilities=variables.policy.catalog();return ctx;
        }
        var member=variables.store.membership(actorId,s.accessMode=='DELEGATED'?s.managerAccountId:s.accountId);
        if(structIsEmpty(member) || member.status!='ATIVO') variables.policy.fail('Forbidden','Direct membership is inactive');
        ctx.versions.membershipId=member.id_conta_usuario;
        if(s.accessMode=='DIRECT') {
            ctx.capabilities=variables.policy.directCapabilities(member.papel,variables.store.directGrants(s.accountId,member.papel),actor.is_admin);return ctx;
        }
        if(!listFind('OWNER,ADMIN,OPERADOR,VISUALIZADOR',member.papel)) variables.policy.fail('Forbidden','Role is ineligible for delegation');
        var managerAccount=variables.store.account(s.managerAccountId);var manager=variables.store.manager(s.managerAccountId);
        var relationship=variables.store.relationship(s.relationshipId);
        if(structIsEmpty(managerAccount) || managerAccount.status!='ATIVA' || structIsEmpty(manager) || !manager.habilitada
            || structIsEmpty(relationship) || relationship.status!='ATIVO' || relationship.id_conta_gestora!=s.managerAccountId || relationship.id_conta_cliente!=s.accountId) variables.policy.fail('Forbidden','Delegated relationship is inactive');
        var assignment=variables.store.assignment(s.relationshipId,member.id_conta_usuario);
        if(structIsEmpty(assignment) || assignment.status!='ATIVO') variables.policy.fail('Forbidden','Team assignment is inactive');
        ctx.versions.managerVersion=manager.version;ctx.versions.relationshipVersion=relationship.version;ctx.versions.assignmentVersion=assignment.version;
        ctx.capabilities=variables.policy.capabilities(variables.store.grants(s.relationshipId),variables.store.grants(s.relationshipId,assignment.id_equipe),member.papel);
        return ctx;
    }
    public boolean function has(required struct context,required string capability) {
        return structKeyExists(context,'capabilities') && isArray(context.capabilities) && arrayFind(context.capabilities,capability)>0;
    }
    public string function formToken(required struct context,required string seed) { return variables.policy.formToken(context,seed); }
    public void function verifyForm(required struct context,required struct posted,required string seed) { variables.policy.verifyForm(context,posted,seed); }
    public any function withMutation(required struct context,required string capability,required struct expected,required struct resource,required any work) {
        if(structKeyExists(context,'accessMode') && context.accessMode=='DELEGATED' && !variables.enabled) variables.policy.fail('Unavailable','Account delegation is unavailable');
        variables.policy.stamp(context);variables.policy.assertExpected(context,expected);
        if(!isCustomFunction(work)) variables.policy.fail('Validation','Mutation callback required');
        // Auditing is required even for direct/internal callers of this new transaction boundary.
        if(!variables.store.schemaReady()) variables.policy.fail('Unavailable','Mutation audit schema is unavailable');
        var accounts=[context.accountId];if(context.managerAccountId!=0) arrayAppend(accounts,context.managerAccountId);
        var result='';
        transaction isolation='read_committed' {
            variables.store.lockScope(accounts,[context.actorId]);
            var fresh=resolve({id=context.actorId},context);
            variables.policy.assertExpected(fresh,expected);
            if(!has(fresh,capability)) variables.policy.fail('Forbidden','Capability is not granted');
            variables.store.assertResource(fresh,resource);
            // Internal callback only: issue every query on datasource; do no network I/O under locks.
            fresh.datasource=variables.datasource;
            if(left(capability,4)=='ads.') variables.store.setAdsContext(fresh);
            result=work(fresh);
            variables.store.audit(fresh,capability,resource);
        }
        return result;
    }
}
