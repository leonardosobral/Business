component output=false {
    public any function init(required any crm, required any provider) {
        variables.crm = arguments.crm;
        variables.provider = arguments.provider;
        return this;
    }

    private struct function domain(required string operation, struct input={}) {
        var response = variables.crm.request("brevo." & operation,input,0,true);
        if (!response.success || !structKeyExists(response,"data") || !isStruct(response.data))
            throw(type="Brevo.Job",message="crm_unavailable");
        return response.data;
    }

    private struct function summary(required string state,numeric processed=0) {
        return {success=true,channel_available=true,status=state,processed=processed};
    }

    private struct function finish(required string token,required string outcome,string reason="",string rejectedStage="") {
        return domain("complete",{lease_token=token,outcome=outcome,reason=reason,rejected_stage=rejectedStage});
    }

    // Checkpoint exactly one non-idempotent provider operation per scheduler invocation.
    private struct function createResource(required struct batch,required string name,required string stage,required string field) {
        var token = batch.lease_token;
        domain("intent",{lease_token=token,stage=stage});
        var id = 0;
        try {
            switch (stage) {
                case "creating_list": id=variables.provider.createList(name); break;
                case "importing": id=variables.provider.importContacts(batch.list_id,batch.recipients); break;
                case "creating_campaign": id=variables.provider.createDraft(name,batch.list_id); break;
            }
        } catch (any e) {
            // Retry only an explicit refusal (or a local pre-request validation failure).
            var refused = e.type=="Brevo.Marketing" && listFind("brevo_auth_failed,brevo_rate_limited,brevo_insufficient_credits,brevo_rejected,brevo_template_invalid,brevo_invalid_input,brevo_setup_incomplete",e.message);
            var resolved=finish(token,refused?"retry":"unknown",refused?e.message:"brevo_write_unknown",refused?stage:"");
            return summary(resolved.status);
        }
        // An unknown checkpoint response must leave the intent recoverable. Never repeat the external write here.
        var change = {lease_token=token};
        change[field] = id;
        domain("checkpoint",change);
        return summary(finish(token,"retry","provider_resource_ready").status);
    }

    private boolean function sameAddresses(required array first,required array second) {
        if (arrayLen(first)!=arrayLen(second)) return false;
        var expected={};
        for (var email in first) expected[lCase(email)]=true;
        for (var email in second) {
            if (!structKeyExists(expected,lCase(email))) return false;
            structDelete(expected,lCase(email));
        }
        return structIsEmpty(expected);
    }

    public struct function run() {
        if (!variables.provider.readiness().configured)
            return {success=true,channel_available=false,processed=0,reason="brevo_setup_incomplete"};
        var batch=domain("claim");
        if (!batch.claimed) return summary(batch.status);
        var token=batch.lease_token;
        var name="Road Runners - " & batch.batch_key;
        // When a signed CRM write has an uncertain outcome, let its own lease reconcile it.
        var phase="read";
        try {
            if (!variables.provider.verifySetup().ready) return summary(finish(token,"retry","brevo_setup_incomplete").status);
            if (!batch.list_id) {
                phase="checkpoint";return createResource(batch,name,"creating_list","list_id");
            }
            if (!batch.process_id) {
                phase="checkpoint";return createResource(batch,name,"importing","process_id");
            }
            var process=variables.provider.processStatus(batch.process_id);
            if (process=="failed") return summary(finish(token,"unknown","import_failed").status);
            if (process!="completed") return summary(finish(token,"retry","import_pending").status);
            if (!batch.campaign_id) {
                phase="checkpoint";return createResource(batch,name,"creating_campaign","campaign_id");
            }
            var remote=variables.provider.syncList(name,batch.list_id,batch.recipients);
            var review=domain("authorize",{lease_token=token,recipients=remote.eligible});
            if (!review.allowed) return summary(review.status);
            if (!sameAddresses(remote.eligible,review.recipients)) {
                remote=variables.provider.syncList(name,batch.list_id,review.recipients);
                if (!sameAddresses(remote.eligible,review.recipients))
                    return summary(finish(token,"retry","membership_changed").status);
            }
            variables.provider.verifyDraftAudience(batch.campaign_id,name,batch.list_id,review.recipients);
            phase="final_validation";
            var dispatch=domain("validate",{lease_token=token});
            if (!dispatch.allowed) return summary(dispatch.status);
            phase="send";
            if (!sameAddresses(dispatch.recipients,review.recipients))
                return summary(finish(token,"unknown","membership_changed").status);
            variables.provider.sendValidated(batch.campaign_id);
            phase="receipt";
            var receipt=finish(token,"accepted");
            return summary(receipt.status,arrayLen(dispatch.recipients));
        } catch (any problem) {
            if (phase=="send") return summary(finish(token,"unknown","send_unconfirmed").status);
            if (phase!="read") rethrow;
            var reason=problem.type=="Brevo.Marketing" && reFind("^brevo_[a-z_]{1,60}$",problem.message) ? problem.message : "provider_unavailable";
            return summary(finish(token,"retry",reason).status);
        }
    }
}
