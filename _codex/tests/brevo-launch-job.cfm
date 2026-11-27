<cfscript>
// Offline stateful fixtures. Never instantiate the marketing or CRM HTTP clients here.
function jobCheck(required boolean condition,required string label){
    if(!condition) throw(type='TestFailed',message=label);
}
function jobFixture(){
    var state={
        addresses=['ok@example.test','unsub@example.test','purchased@example.test'],
        claimable=true,status='queued',configured=true,verified=true,process='completed',
        pending='',calls=[],failure='',failureCode='brevo_write_unknown',
        denied='',filter=false,filteredSyncBlocked=false,confirmed=[],list_id=0,process_id=0,campaign_id=0
    };
    var result={state=state};
    var crm={};
    crm.request=function(operation,input,actor,signed){
        jobCheck(actor==0 && signed,'unsigned worker operation');
        var op=listLast(operation,'.');
        arrayAppend(state.calls,'crm.' & op);
        var data={};
        if(op=='claim'){
            data={claimed=state.claimable,status=state.status,batch_key='synthetic-batch',lease_token='synthetic-lease',
                recipients=duplicate(state.addresses),list_id=state.list_id,process_id=state.process_id,campaign_id=state.campaign_id};
        } else {
            jobCheck(input.lease_token=='synthetic-lease','missing worker lease');
            switch(op){
                case 'intent':
                    jobCheck(state.pending=='','new operation before checkpoint');
                    state.pending=input.stage;
                    break;
                case 'checkpoint':
                    if(state.failure=='checkpoint'){
                        state.status='unknown'; state.claimable=false;
                        throw(type='Fixture.Unavailable',message='lost before receipt');
                    }
                    for(var field in ['list_id','process_id','campaign_id']){
                        if(structKeyExists(input,field)) state[field]=input[field];
                    }
                    state.pending='';
                    break;
                case 'complete':
                    state.outcome=input.outcome;
                    state.reason=input.reason;
                    if(len(input.rejected_stage)){
                        jobCheck(input.rejected_stage==state.pending,'wrong refused stage');
                        state.pending='';
                    }
                    state.status=input.outcome=='retry' ? 'queued' : input.outcome;
                    state.claimable=input.outcome=='retry';
                    if(state.failure=='receipt' && input.outcome=='accepted') throw(type='Fixture.Unavailable',message='receipt lost');
                    data={status=state.status};
                    break;
                case 'authorize':
                    data={allowed=state.denied!='authorize',status='no_eligible',recipients=duplicate(input.recipients)};
                    if(state.filter){
                        jobCheck(!arrayFindNoCase(input.recipients,'unsub@example.test'),'provider opt-out crossed authorization');
                        data.recipients=['ok@example.test'];
                    }
                    break;
                case 'validate':
                    data={allowed=state.denied!='validate',status='outside_window',
                        recipients=state.filter ? ['ok@example.test'] : duplicate(state.addresses)};
                    break;
                default: throw(type='Fixture.Invalid',message=op);
            }
        }
        return {success=true,data=data};
    };
    var api={};
    var action=function(name){
        arrayAppend(state.calls,'api.' & name);
        if(state.failure==name) throw(type='Brevo.Marketing',message=state.failureCode);
    };
    api.readiness=function(){action('readiness');return {configured=state.configured};};
    api.verifySetup=function(){action('verifySetup');return {ready=state.verified};};
    api.createList=function(name){action('createList');return 81;};
    api.importContacts=function(id,emails){
        jobCheck(id==81 && arrayLen(emails)==arrayLen(state.addresses),'import cohort');
        action('importContacts');return 82;
    };
    api.processStatus=function(id){jobCheck(id==82,'process id');action('processStatus');return state.process;};
    api.createDraft=function(name,id){jobCheck(id==81,'draft list');action('createDraft');return 83;};
    api.syncList=function(name,id,emails){
        jobCheck(id==81,'sync list');action('syncList');
        var rows=duplicate(emails);
        if(state.filter){
            arrayDeleteNoCase(rows,'unsub@example.test');
            if(state.filteredSyncBlocked && arrayLen(emails)==1) rows=[];
        }
        return {eligible=rows};
    };
    api.verifyDraftAudience=function(campaign,name,id,emails){
        jobCheck(campaign==83 && id==81,'send campaign/list');
        state.confirmed=duplicate(emails);
        action('verifyDraftAudience');return true;
    };
    api.sendValidated=function(campaign){
        jobCheck(campaign==83,'campaign dispatch');
        jobCheck(arrayFind(state.calls,'api.verifyDraftAudience')>0 && arrayFind(state.calls,'crm.validate')>0,'send before validation');
        action('sendNow');return true;
    };
    result.job=new services.BrevoLaunchJob(crm,api);
    return result;
}
function readyJob(){
    var fixture=jobFixture();
    fixture.state.list_id=81;fixture.state.process_id=82;fixture.state.campaign_id=83;
    return fixture;
}
function timesCalled(required array calls,required string name){
    var count=0;
    for(var entry in calls) if(entry==name) count++;
    return count;
}

f=jobFixture();f.state.configured=false;
r=f.job.run();
jobCheck(!r.channel_available && !arrayFind(f.state.calls,'crm.claim'),'local settings gate');
f=jobFixture();f.state.claimable=false;f.state.status='outside_window';
jobCheck(f.job.run().status=='outside_window' && !arrayFind(f.state.calls,'api.verifySetup'),'outside window');
f=jobFixture();f.state.verified=false;
jobCheck(f.job.run().status=='queued' && f.state.reason=='brevo_setup_incomplete' && !arrayFind(f.state.calls,'crm.intent'),'remote settings gate');

f=jobFixture();
jobCheck(f.job.run().status=='queued' && f.state.list_id==81 && f.state.process_id==0,'checkpoint list separately');
jobCheck(f.job.run().status=='queued' && f.state.process_id==82 && f.state.campaign_id==0,'checkpoint import separately');
f.state.process='queued';
jobCheck(f.job.run().status=='queued' && f.state.reason=='import_pending' && !arrayFind(f.state.calls,'api.createDraft'),'asynchronous import');
f.state.process='completed';
jobCheck(f.job.run().status=='queued' && f.state.campaign_id==83 && !arrayFind(f.state.calls,'api.sendNow'),'draft before dispatch');
f.state.filter=true;
r=f.job.run();
jobCheck(r.status=='accepted' && r.processed==1 && arrayToList(f.state.confirmed)=='ok@example.test','suppression or purchase filtering');
jobCheck(timesCalled(f.state.calls,'api.syncList')==2 && timesCalled(f.state.calls,'api.sendNow')==1,'list reconciled once after authorization');
f.job.run();
jobCheck(timesCalled(f.state.calls,'api.sendNow')==1,'already accepted');

for(stage in ['createList','importContacts','createDraft','sendNow']){
    f=readyJob();
    if(stage=='createList') f.state.list_id=0;
    if(stage=='importContacts') f.state.process_id=0;
    if(stage=='createDraft') f.state.campaign_id=0;
    f.state.failure=stage;
    jobCheck(f.job.run().status=='unknown','ambiguous ' & stage);
    f.job.run();
    jobCheck(timesCalled(f.state.calls,'api.' & stage)==1,'repeated ' & stage);
    jobCheck(!arrayFind(f.state.calls,'crm.checkpoint'),'checkpointed ambiguous resource ' & stage);
}
f=jobFixture();f.state.failure='createList';f.state.failureCode='brevo_rate_limited';
jobCheck(f.job.run().status=='queued' && f.state.pending=='','clear explicitly refused operation');
f.state.failure='';
jobCheck(f.job.run().status=='queued' && f.state.list_id==81,'retry after provider refusal');

f=readyJob();f.state.process='failed';
jobCheck(f.job.run().status=='unknown' && f.state.reason=='import_failed' && !arrayFind(f.state.calls,'api.sendNow'),'failed import');
f=readyJob();f.state.denied='authorize';
jobCheck(f.job.run().status=='no_eligible' && !arrayFind(f.state.calls,'crm.validate') && !arrayFind(f.state.calls,'api.sendNow'),'empty final cohort');
f=readyJob();f.state.denied='validate';
jobCheck(f.job.run().status=='outside_window' && !arrayFind(f.state.calls,'api.sendNow'),'closed window before send');
f=readyJob();f.state.failure='verifyDraftAudience';f.state.failureCode='brevo_rate_limited';
jobCheck(f.job.run().status=='queued' && f.state.reason=='brevo_rate_limited','refused provider preflight must allow retry');
jobCheck(!arrayFind(f.state.calls,'crm.validate') && !arrayFind(f.state.calls,'api.sendNow'),'no reservation or delivery after refused GET');
f.state.failure='';
jobCheck(f.job.run().status=='accepted' && timesCalled(f.state.calls,'api.sendNow')==1,'resume once after refused GET');
f=readyJob();f.state.filter=true;f.state.filteredSyncBlocked=true;
jobCheck(f.job.run().status=='queued' && f.state.reason=='membership_changed' && !arrayFind(f.state.calls,'api.sendNow'),'late suppression');

for(failure in ['checkpoint','receipt']){
    f=failure=='checkpoint' ? jobFixture() : readyJob();
    f.state.failure=failure;
    raised=false;
    try{f.job.run();}catch(Fixture.Unavailable lost){raised=true;}
    jobCheck(raised,'uncertain CRM response must preserve pending state ' & failure);
    f.job.run();
    jobCheck(timesCalled(f.state.calls,failure=='checkpoint' ? 'api.createList' : 'api.sendNow')==1,'duplicate write after lost ' & failure);
}
writeOutput('BREVO_LAUNCH_JOB_CHECKS_PASSED');
</cfscript>
