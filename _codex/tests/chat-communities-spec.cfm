<!--- Run only through a loopback-only runner with chatTestRoot pointing at the candidate.
      All fixtures are rolled back. Notification transport is replaced, not eligibility or SQL. --->
<cfinclude template="#VARIABLES.chatTestRoot#/includes/backend/backend_chat_groups.cfm"/>
<cfscript>
failures=[]; tests=0; notificationCount=0;
function expect(required boolean condition, required string label) {
    tests++;
    if (!arguments.condition) arrayAppend(failures,arguments.label);
}
function rrChatOpenUrl(required string kind, required numeric itemId, required numeric userId, string event="", numeric groupId=0) { return "/test/"; }
function rrNotificationsDispatch(required struct payload, numeric timeoutSeconds=25) { notificationCount++; return {success=true}; }
function resetEligibility() {
    structDelete(REQUEST,"rrChatSpecialRefreshCache");
    structDelete(REQUEST,"rrChatSpecialEligibleAccess");
}
function rejected(required any operation) {
    try { arguments.operation(); return false; } catch (any e) { return findNoCase("Permission",e.type)>0 || findNoCase("Forbidden",e.type)>0 || findNoCase("Validation",e.type)>0; }
}
try {
    open=rrChatSpecialNormalizePolicy({audience="open",criteria=[]});
    expect(open.audience EQ "open" && !arrayLen(open.criteria),"open community accepts no prerequisites");
} catch (any e) { expect(false,"open community accepts no prerequisites: " & e.message); }
expect(rejected(function(){rrChatSpecialNormalizePolicy({criteria=[]});}),"missing prerequisites never silently become open");
expect(rejected(function(){rrChatSpecialNormalizePolicy({criteria=[{type="challenge",code="x' OR true --"}]});}),"unsafe challenge code is rejected");
legacy=rrChatSpecialNormalizePolicy({operator="any",criteria=[{type="profile",verified=true},{type="badge",badge_codes=["MARATONISTA"]}]});
expect(legacy.operator EQ "any" && arrayLen(legacy.criteria) EQ 2,"legacy compound criteria survive normalization");

admins=queryExecute("SELECT id FROM tb_usuarios WHERE is_admin=true ORDER BY id LIMIT 2",{},{datasource="runner_dba"});
users=queryExecute("SELECT u.id FROM tb_usuarios u LEFT JOIN tb_usuarios_gestao ug ON ug.id_usuario=u.id WHERE coalesce(u.is_admin,false)=false AND coalesce(ug.ativo,true)=true AND coalesce(ug.excluido,false)=false ORDER BY u.id LIMIT 2",{},{datasource="runner_dba"});
event=queryExecute("SELECT id_evento FROM tb_evento_corridas WHERE ativo=true ORDER BY id_evento DESC LIMIT 1",{},{datasource="runner_dba"});
expect(admins.recordCount EQ 2 && users.recordCount EQ 2 && event.recordCount EQ 1,"required test subjects exist");
actor=admins.id[1]; otherAdmin=admins.id[2]; member=users.id[1]; outsider=users.id[2]; eventId=event.id_evento;
for (referenceKind in ["challenge","circuit","aggregator","training","event","admin"]) {
    try { refs=rrChatSpecialReferences(referenceKind); expect(refs.recordCount GT 0,"reference selector loads " & referenceKind); }
    catch (any e) { expect(false,"reference selector loads " & referenceKind & ": " & e.message & " " & e.detail); }
}
code="codex_test_" & lCase(replace(createUUID(),"-","","all"));
circuitRefs=rrChatSpecialReferences(kind="circuit");
expect(listFind(valueList(circuitRefs.value),"circuitobrasilgigante") GT 0,"Brasil Gigante remains selectable even without a legacy campaign catalog entry");
for (selectedCatalog in [{kind="challenge",sql="SELECT tag AS value FROM desafios_eventos WHERE ativo=true ORDER BY titulo DESC LIMIT 1"},{kind="aggregator",sql="SELECT agregador_tag AS value FROM tb_agregadores ORDER BY agregador_nome DESC LIMIT 1"}]) {
    chosen=queryExecute(selectedCatalog.sql,{},{datasource="runner_dba"});
    if (chosen.recordCount) {
        selectedRefs=rrChatSpecialReferences(kind=selectedCatalog.kind,selected=chosen.value);
        expect(selectedRefs.recordCount && selectedRefs.value[1] EQ chosen.value,"editing prioritizes selected " & selectedCatalog.kind & " before catalog pagination");
    }
}
transaction {
    try {
        params={a={value=member,cfsqltype="cf_sql_integer"},b={value=outsider,cfsqltype="cf_sql_integer"},code={value=code,cfsqltype="cf_sql_varchar"},event={value=eventId,cfsqltype="cf_sql_integer"}};
        queryExecute("INSERT INTO desafios (id_usuario,produto,desafio,status) VALUES (:a,:code,:code,'C'),(:b,:code,:code,'I')",params,{datasource="runner_dba"});
        policy={criteria=[{type="challenge",code=code,confirmed_only=true}]};
        expect(rrChatSpecialEvaluatePolicy(policy,member).eligible,"confirmed registration qualifies");
        expect(!rrChatSpecialEvaluatePolicy(policy,outsider).eligible,"unconfirmed registration does not qualify");
        try {
            queryExecute("INSERT INTO tb_inscricoes (id_usuario,id_evento) VALUES (:a,:event) ON CONFLICT (id_evento,id_usuario) DO NOTHING",params,{datasource="runner_dba"});
            registered={criteria=[{type="event_registration",event_ids=[eventId]}]};
            expect(rrChatSpecialEvaluatePolicy(registered,member).eligible,"actual event registration qualifies without calendar intent");
        } catch (any e) { expect(false,"actual event registration qualifies: " & e.message); }
        fixture=queryExecute("INSERT INTO tb_chat_grupo (slug,nome,modo,acesso,id_dono) VALUES (:slug,'Codex rollback fixture','chat','free',:actor) RETURNING id_chat_grupo",{slug={value=code,cfsqltype="cf_sql_varchar"},actor={value=actor,cfsqltype="cf_sql_integer"}},{datasource="runner_dba"});
        gid=fixture.id_chat_grupo;
        listed=rrChatSpecialAdminList();
        expect(listFind(valueList(listed.id_chat_grupo),gid) GT 0,"manager lists existing ordinary groups as well as governed communities");
        queryExecute("INSERT INTO tb_chat_grupo_especial (id_chat_grupo,codigo,nome_normalizado,regra,associacao_automatica,status,criado_por,atualizado_por) VALUES (:gid,:code,:code,CAST(:policy AS jsonb),false,'active',:actor,:actor)",{gid={value=gid,cfsqltype="cf_sql_bigint"},code={value=code,cfsqltype="cf_sql_varchar"},policy={value=serializeJSON(policy),cfsqltype="cf_sql_longvarchar"},actor={value=actor,cfsqltype="cf_sql_integer"}},{datasource="runner_dba"});
        queryExecute("INSERT INTO tb_chat_grupo_membro (id_chat_grupo,id_usuario,papel,status) VALUES (:gid,:member,'admin','active')",{gid={value=gid,cfsqltype="cf_sql_bigint"},member={value=member,cfsqltype="cf_sql_integer"}},{datasource="runner_dba"});
        resetEligibility();
        adminView=rrChatGroupGet(gid,otherAdmin);
        expect(adminView.recordCount EQ 1,"global admin opens restricted community without enrollment");
        if (adminView.recordCount) expect(adminView.viewer_can_manage && adminView.viewer_can_post,"global admin manages and posts without group role");
        regularView=rrChatGroupGet(gid,member);
        expect(regularView.recordCount EQ 1 && !regularView.viewer_can_manage,"non-global group admin cannot manage");
        expect(!rrChatGroupGet(gid,outsider).recordCount,"unqualified user cannot discover the conversation");
        expect(rejected(function(){rrChatGroupUpdate(gid,member,"Unauthorized update");}),"group role alone cannot update configuration");
        expect(rejected(function(){rrChatGroupModerate(gid,member,outsider,"approve");}),"group role alone cannot moderate participants");
        queryExecute("UPDATE desafios SET status='C' WHERE id_usuario=:b AND produto=:code",params,{datasource="runner_dba"});
        resetEligibility();
        sync=rrChatSpecialSync(gid,actor,false,"business",code & "_sync");
        expect(sync.included EQ 0,"automatic-off synchronization does not enroll anyone");
        expect(!queryExecute("SELECT 1 FROM tb_chat_grupo_membro WHERE id_chat_grupo=:gid AND id_usuario=:id",{gid={value=gid,cfsqltype="cf_sql_bigint"},id={value=outsider,cfsqltype="cf_sql_integer"}},{datasource="runner_dba"}).recordCount,"automatic-off sync does not enroll newly qualifying user");
        voluntary=rrChatGroupGet(gid,outsider);
        expect(voluntary.recordCount && !voluntary.viewer_is_member,"qualifying nonmember discovers manual-entry group");
        expect(rejected(function(){rrChatGroupMessages(gid,outsider);}),"qualifying nonmember cannot read group history");
        rrChatGroupJoin(gid,outsider); resetEligibility();
        expect(rrChatGroupGet(gid,outsider).viewer_can_post,"voluntary group entry grants conversation participation");
        rrChatGroupLeave(gid,outsider); resetEligibility();
        rrChatSpecialUpdate(actorId=actor,groupId=gid,name="Codex rollback fixture",policy=policy,automaticMembership=true);
        rrChatSpecialSync(gid,actor,false,"business",code & "_auto"); resetEligibility();
        expect(!rrChatGroupGet(gid,outsider).viewer_is_member,"automatic sync respects voluntary departure");
        expect(!queryExecute("SELECT 1 FROM tb_chat_grupo_membro WHERE id_chat_grupo=:gid AND id_usuario=:actor",{gid={value=gid,cfsqltype="cf_sql_bigint"},actor={value=actor,cfsqltype="cf_sql_integer"}},{datasource="runner_dba"}).recordCount,"global access does not require or create membership");
        try {
            created=rrChatSpecialCreate(actorId=actor,ownerId=actor,name="Codex " & code,code=code & "_create",policy=policy,status="draft",mode="channel",automaticMembership=false);
            expect(created.modo EQ "channel","manager creates a channel rather than hardcoded chat");
            expect(!created.associacao_automatica,"manager persists opt-out of automatic membership");
            expect(rrChatGroupGet(created.id_chat_grupo,otherAdmin).recordCount EQ 1,"global admin can inspect a draft");
            expect(!rrChatGroupGet(created.id_chat_grupo,member).recordCount,"draft hidden from regular participants");
            rrChatSpecialUpdate(actorId=actor,groupId=created.id_chat_grupo,name="Codex " & code,policy={audience="open",criteria=[],official_event_id=eventId},mode="channel",automaticMembership=true);
            edited=rrChatSpecialAdminGet(created.id_chat_grupo);
            expect(!edited.associacao_automatica,"open audience cannot enroll the entire platform");
            editedPolicy=isStruct(edited.regra) ? edited.regra : deserializeJSON(edited.regra);
            expect(editedPolicy.official_event_id EQ eventId,"official event link persists independently of prerequisites");
            expect(rrChatSpecialOfficialEvent(created.id_chat_grupo).recordCount EQ 1,"official event is exposed in the chat");
            rrChatSpecialSetStatus(actor,created.id_chat_grupo,"active");
            resetEligibility();
            expect(rrChatGroupGet(created.id_chat_grupo,outsider).recordCount EQ 1,"open channel can be discovered before subscribing");
            expect(rejected(function(){rrChatGroupMessages(created.id_chat_grupo,outsider);}),"unsubscribed user cannot read channel history");
            rrChatChannelSubscribe(created.id_chat_grupo,outsider);
            resetEligibility();
            joined=rrChatGroupGet(created.id_chat_grupo,outsider);
            expect(joined.viewer_is_member && !joined.viewer_can_manage && !joined.viewer_can_post,"channel subscriber reads but cannot post or manage");
            expect(rejected(function(){rrChatGroupSend(created.id_chat_grupo,outsider,"not allowed");}),"ordinary channel subscriber cannot publish through API");
            expect(rrChatGroupSend(created.id_chat_grupo,otherAdmin,"rollback test").created,"global admin publishes without subscription");
            expect(rrChatGroupMessages(created.id_chat_grupo,otherAdmin).recordCount EQ 1,"global admin reads channel without subscription");
            legacyGroup=rrChatGroupCreate(actor,"Codex legacy " & code,"","free","channel");
            legacyId=legacyGroup.id_chat_grupo;
            rrChatSpecialSetStatus(actor,legacyId,"paused");
            rrChatSpecialUpdate(actorId=actor,groupId=legacyId,name="Codex legacy " & code,policy={audience="open",criteria=[]},mode="channel",automaticMembership=false);
            expect(rrChatSpecialAdminGet(legacyId).id_chat_grupo EQ legacyId,"manager adopts a legacy channel without recreating its conversation");
            expect(rrChatSpecialAdminGet(legacyId).status EQ "paused","adoption preserves paused rather than marking legacy conversation archived");
            rrChatSpecialSetStatus(actor,legacyId,"active"); resetEligibility();
            expect(rrChatGroupGet(legacyId,outsider).recordCount EQ 1,"reactivated legacy channel becomes accessible to its audience");
        } catch (any e) { expect(false,"creation, voluntary entry and official link flow: " & e.message & " " & e.detail & " " & serializeJSON(e.tagContext)); }
        expect(rejected(function(){rrChatSpecialCreate(member,member,"Forbidden","forbidden_" & code,policy);}),"ordinary user cannot create via admin engine");
        expect(rejected(function(){rrChatGroupCreate(member,"Forbidden");}),"ordinary user cannot create via chat engine");
    } catch (any e) { expect(false,"fixture flow: " & e.message & " " & e.detail & " " & serializeJSON(e.tagContext)); }
    transaction action="rollback";
}
cfcontent(type="application/json; charset=utf-8",reset=true);
writeOutput(serializeJSON({ok=!arrayLen(failures),tests=tests,failures=failures,rolled_back=true}));
</cfscript>
