<!--- Loopback-only runner; real registration/membership SQL, all changes rolled back. --->
<cfif NOT structKeyExists(URL,"cold")>
    <cfinclude template="#VARIABLES.chatTestRoot#/includes/backend/backend_chat_special_groups.cfm"/>
</cfif>
<cfscript>
tests=0; failures=[];
function expect(required boolean condition, required string label) {
    tests++; if (!arguments.condition) arrayAppend(failures,arguments.label);
}
function membership(required numeric gid, required numeric uid) {
    return queryExecute("SELECT status,bloqueado_moderacao FROM tb_chat_grupo_membro WHERE id_chat_grupo=:g AND id_usuario=:u",{g={value=arguments.gid,cfsqltype="cf_sql_bigint"},u={value=arguments.uid,cfsqltype="cf_sql_integer"}},{datasource="runner_dba"});
}
servicePath=VARIABLES.circuitTestRoot & "/cbg-includes/challenge_signup.cfm";
expect(fileExists(expandPath(servicePath)),"registration persistence immediately synchronizes channel membership, without chat access");
</cfscript>
<cfif fileExists(expandPath(servicePath))>
    <cfinclude template="#servicePath#"/>
    <cfscript>
    subjects=queryExecute("SELECT u.id FROM tb_usuarios u LEFT JOIN tb_usuarios_gestao ug ON ug.id_usuario=u.id WHERE coalesce(u.is_admin,false)=false AND coalesce(ug.ativo,true)=true AND coalesce(ug.excluido,false)=false AND NOT EXISTS (SELECT 1 FROM tb_resultados r WHERE r.id_usuario=u.id) AND NOT EXISTS (SELECT 1 FROM desafios d WHERE d.id_usuario=u.id AND (d.produto='circuitobrasilgigante' OR d.desafio='circuitobrasilgigante')) ORDER BY u.id LIMIT 2",{},{datasource="runner_dba"});
    actor=queryExecute("SELECT id FROM tb_usuarios WHERE is_admin=true ORDER BY id LIMIT 1",{},{datasource="runner_dba"}).id;
    expect(subjects.recordCount EQ 2,"fresh subjects exist for rollback-only circuit signup");
    uid=subjects.id[1]; outsider=subjects.id[2]; fixtureCode="codex_bg_" & lCase(replace(createUUID(),"-","","all"));
    transaction {
        try {
            fixtureGroups={};
            for (kind in ["active","manual","draft","paused","confirmed","unrelated","removed","left","rejected","compound","any"]) {
                gid=queryExecute("INSERT INTO tb_chat_grupo (slug,nome,modo,acesso,id_dono,status) VALUES (:slug,'Codex rollback Brasil Gigante','channel','free',:actor,'active') RETURNING id_chat_grupo",{slug={value=fixtureCode & "_" & kind,cfsqltype="cf_sql_varchar"},actor={value=actor,cfsqltype="cf_sql_integer"}},{datasource="runner_dba"}).id_chat_grupo;
                fixtureGroups[kind]=gid;
                rule={audience="rules",operator="all",criteria=[{type="challenge",code=kind EQ "unrelated" ? fixtureCode : "circuitobrasilgigante",confirmed_only=kind EQ "confirmed"}]};
                if (listFind("compound,any",kind)) arrayAppend(rule.criteria,{type="challenge",code=fixtureCode & "_missing"});
                if (kind EQ "any") rule.operator="any";
                queryExecute("INSERT INTO tb_chat_grupo_especial (id_chat_grupo,codigo,nome_normalizado,regra,associacao_automatica,status,criado_por,atualizado_por) VALUES (:g,:code,:code,CAST(:rule AS jsonb),:automatic,:status,:actor,:actor)",{g={value=gid,cfsqltype="cf_sql_bigint"},code={value=fixtureCode & "_" & kind,cfsqltype="cf_sql_varchar"},rule={value=serializeJSON(rule),cfsqltype="cf_sql_longvarchar"},automatic={value=kind NEQ "manual",cfsqltype="cf_sql_bit"},status={value=listFind("draft,paused",kind) ? kind : "active",cfsqltype="cf_sql_varchar"},actor={value=actor,cfsqltype="cf_sql_integer"}},{datasource="runner_dba"});
                if (listFind("removed,left,rejected",kind)) queryExecute("INSERT INTO tb_chat_grupo_membro (id_chat_grupo,id_usuario,status,bloqueado_moderacao) VALUES (:g,:u,:status,:blocked)",{g={value=gid,cfsqltype="cf_sql_bigint"},u={value=uid,cfsqltype="cf_sql_integer"},status={value=kind,cfsqltype="cf_sql_varchar"},blocked={value=kind EQ "removed",cfsqltype="cf_sql_bit"}},{datasource="runner_dba"});
            }
            rrChatSpecialRefreshUser(uid,fixtureGroups.active,false);
            expect(!membership(fixtureGroups.active,uid).recordCount,"no signup means no automatic membership");
            saved=bgSaveChallengeRegistration(uid,{codex_marker="first",provas="fixture"});
            expect(saved.recordCount EQ 1 && saved.produto EQ "circuitobrasilgigante" && saved.status EQ "I","existing circuit persistence and unconfirmed signup status are preserved");
            expect(membership(fixtureGroups.active,uid).recordCount EQ 1 && membership(fixtureGroups.active,uid).status EQ "active","new signup joins active channel immediately, even after cached pre-signup check");
            expect(!membership(fixtureGroups.active,outsider).recordCount,"signup cannot enroll another user");
            for (kind in ["manual","draft","paused","confirmed","unrelated","compound"]) expect(!membership(fixtureGroups[kind],uid).recordCount,"signup respects " & kind & " channel policy");
            expect(membership(fixtureGroups.removed,uid).status EQ "removed" && membership(fixtureGroups.removed,uid).bloqueado_moderacao,"signup respects moderation removal");
            expect(membership(fixtureGroups.left,uid).status EQ "left","signup respects voluntary departure");
            expect(membership(fixtureGroups.rejected,uid).status EQ "rejected","signup respects rejection even without moderation flag");
            expect(membership(fixtureGroups.any,uid).status EQ "active","signup respects any-criterion eligibility");
            savedAgain=bgSaveChallengeRegistration(uid,{codex_marker="second"});
            expect(savedAgain.recordCount EQ 1 && deserializeJSON(savedAgain.body).codex_marker EQ "second","repeat signup updates circuit payload");
            expect(membership(fixtureGroups.active,uid).recordCount EQ 1,"repeat signup does not duplicate membership");
            queryExecute("UPDATE desafios SET status='C' WHERE id_usuario=:u AND produto='circuitobrasilgigante'",{u={value=uid,cfsqltype="cf_sql_integer"}},{datasource="runner_dba"});
            bgSaveChallengeRegistration(uid,{codex_marker="confirmed"});
            expect(membership(fixtureGroups.confirmed,uid).recordCount EQ 1,"updated confirmed signup re-evaluates confirmed-only policy");
            expect(!membership(fixtureGroups.compound,uid).recordCount,"signup does not bypass additional prerequisites");
            invalidRejected=false;
            try { bgSaveChallengeRegistration(0,{codex_marker="invalid"}); } catch (any e) { invalidRejected=true; }
            expect(invalidRejected,"invalid user is rejected before registration write");
            // Execute the unmodified POST prefix extracted from both real step templates.
            // Presentation queries use a different datasource and cannot share this rollback.
            include VARIABLES.circuitTestRoot & "/cbg-includes/i18n.cfm";
            qPerfil={tag_prefix="atleta",tag="codex-fixture",id_pagina=0,name="Codex fixture",aka="",assessoria="",ano_nascimento="1990"};
            COOKIE.id=outsider;
            FORM.action="confirmar_desafio";
            FORM.nome_completo="Codex rollback fixture";
            flowRoot=VARIABLES.circuitPostTestRoot & (structKeyExists(URL,"baselineflows") ? "/baseline" : "/circuit");
            for (step in ["cadastro/flow/validacao_step.cfm","inscricao/validacao.cfm"]) {
                queryExecute("DELETE FROM tb_chat_grupo_membro WHERE id_chat_grupo=:g AND id_usuario=:u",{g={value=fixtureGroups.active,cfsqltype="cf_sql_bigint"},u={value=outsider,cfsqltype="cf_sql_integer"}},{datasource="runner_dba"});
                VARIABLES.template="/cadastro/";
                savecontent variable="renderedStep" { include flowRoot & "/" & step & ".signup-spec.cfm"; }
                expect(membership(fixtureGroups.active,outsider).recordCount EQ 1,"POST branch in " & step & " enrolls user immediately after registration");
            }
            structDelete(COOKIE,"id");
            structDelete(FORM,"action");
            structDelete(FORM,"nome_completo");
        } catch (any e) { expect(false,"registration fixture flow: " & e.message & " " & e.detail & " " & serializeJSON(e.tagContext)); }
        transaction action="rollback";
    }
    </cfscript>
</cfif>
<cfscript>
cfcontent(type="application/json; charset=utf-8",reset=true);
writeOutput(serializeJSON({ok=!arrayLen(failures),tests=tests,failures=failures,rolled_back=true}));
</cfscript>
