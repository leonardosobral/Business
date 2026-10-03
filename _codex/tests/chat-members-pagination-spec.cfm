<!--- Only run behind a loopback guard. Every database fixture is rolled back. --->
<cfinclude template="#VARIABLES.chatTestRoot#/includes/backend/backend_chat_groups.cfm"/>
<cfscript>
tests=0;failures=[];
function expect(required boolean condition,required string label){tests++;if(!arguments.condition)arrayAppend(failures,arguments.label);}
function rejects(required any call){try{arguments.call();return false;}catch(any e){return findNoCase("Validation",e.type)||findNoCase("Permission",e.type)||findNoCase("Forbidden",e.type);}}
function rrChatOpenUrl(required string kind,required numeric itemId,required numeric userId,string eventType="",numeric groupId=0){return "/test/";}
function rrNotificationsDispatch(required struct payload,numeric timeoutSeconds=25){return {success=true};}
expect(structKeyExists(VARIABLES,"rrChatGroupMembersPage"),"members endpoint has a bounded page query");
if(structKeyExists(VARIABLES,"rrChatGroupMembersPage")){
    admins=queryExecute("SELECT id FROM tb_usuarios WHERE is_admin=true ORDER BY id LIMIT 1",{},{datasource="runner_dba"});actor=admins.id;
    marker="codex_members_" & lCase(replace(createUUID(),"-","","all"));
    transaction {
      try{
        fixture=queryExecute("INSERT INTO tb_chat_grupo (slug,nome,modo,acesso,id_dono) VALUES (:slug,'Pagination rollback fixture','chat','free',:owner) RETURNING id_chat_grupo",{slug={value=marker,cfsqltype="cf_sql_varchar"},owner={value=actor,cfsqltype="cf_sql_integer"}},{datasource="runner_dba"});gid=fixture.id_chat_grupo;
        queryExecute("INSERT INTO tb_chat_grupo_especial (id_chat_grupo,codigo,nome_normalizado,regra,status,associacao_automatica,criado_por,atualizado_por) VALUES (:gid,:code,:code,CAST(:policy AS jsonb),'active',false,:actor,:actor)",{gid={value=gid,cfsqltype="cf_sql_bigint"},code={value=marker,cfsqltype="cf_sql_varchar"},policy={value=serializeJSON({audience="open",criteria=[]}),cfsqltype="cf_sql_longvarchar"},actor={value=actor,cfsqltype="cf_sql_integer"}},{datasource="runner_dba"});
        ids=[];pages=[];
        for(i=1;i<=65;i++){
          displayName=i<=32 ? "Z Contact " & numberFormat(i,"00") : "A Other " & numberFormat(i,"00");
          usr=queryExecute("INSERT INTO tb_usuarios (name,email) VALUES (:name,:email) RETURNING id",{name={value=displayName,cfsqltype="cf_sql_varchar"},email={value=marker & i & "@example.invalid",cfsqltype="cf_sql_varchar"}},{datasource="runner_dba"});arrayAppend(ids,usr.id);
          profile=queryExecute("INSERT INTO tb_paginas (nome,tag,tag_prefix,id_usuario_cadastro) VALUES (:name,:tag,'atleta',:uid) RETURNING id_pagina",{name={value=displayName,cfsqltype="cf_sql_varchar"},tag={value=marker & i,cfsqltype="cf_sql_varchar"},uid={value=usr.id,cfsqltype="cf_sql_integer"}},{datasource="runner_dba"});arrayAppend(pages,profile.id_pagina);
          queryExecute("INSERT INTO tb_paginas_usuarios (id_usuario,id_pagina) VALUES (:uid,:pid)",{uid={value=usr.id,cfsqltype="cf_sql_integer"},pid={value=profile.id_pagina,cfsqltype="cf_sql_integer"}},{datasource="runner_dba"});
          queryExecute("INSERT INTO tb_chat_grupo_membro (id_chat_grupo,id_usuario,papel,status,elegibilidade_status) VALUES (:gid,:uid,:role,'active','eligible')",{gid={value=gid,cfsqltype="cf_sql_bigint"},uid={value=usr.id,cfsqltype="cf_sql_integer"},role={value=i EQ 65 ? "owner" : "member",cfsqltype="cf_sql_varchar"}},{datasource="runner_dba"});
        }
        // User 1 follows 2..32; 2 is reciprocal. User 33 follows user 1.
        for(i=2;i<=32;i++)queryExecute("INSERT INTO tb_paginas_vinculos (id_pagina_origem,id_pagina_destino,tipo_vinculo,vinculo_validado,id_usuario_cadastro) VALUES (:a,:b,1,true,:uid)",{a={value=pages[1],cfsqltype="cf_sql_integer"},b={value=pages[i],cfsqltype="cf_sql_integer"},uid={value=ids[1],cfsqltype="cf_sql_integer"}},{datasource="runner_dba"});
        for(i in [2,33,34])queryExecute("INSERT INTO tb_paginas_vinculos (id_pagina_origem,id_pagina_destino,tipo_vinculo,vinculo_validado,id_usuario_cadastro) VALUES (:a,:b,1,:valid,:uid)",{a={value=pages[i],cfsqltype="cf_sql_integer"},b={value=pages[1],cfsqltype="cf_sql_integer"},valid={value=i NEQ 34,cfsqltype="cf_sql_bit"},uid={value=ids[i],cfsqltype="cf_sql_integer"}},{datasource="runner_dba"});
        // The legacy mapping table can contain repeated user/profile associations.
        for(i in [1,2])queryExecute("INSERT INTO tb_paginas_usuarios (id_usuario,id_pagina) VALUES (:uid,:pid)",{uid={value=ids[i],cfsqltype="cf_sql_integer"},pid={value=pages[i],cfsqltype="cf_sql_integer"}},{datasource="runner_dba"});
        extraProfile=queryExecute("INSERT INTO tb_paginas (nome,tag,tag_prefix,id_usuario_cadastro) VALUES ('A misleading newer profile',:tag,'atleta',:uid) RETURNING id_pagina",{tag={value=marker & '_extra',cfsqltype="cf_sql_varchar"},uid={value=ids[2],cfsqltype="cf_sql_integer"}},{datasource="runner_dba"});
        queryExecute("INSERT INTO tb_paginas_usuarios (id_usuario,id_pagina) VALUES (:uid,:pid)",{uid={value=ids[2],cfsqltype="cf_sql_integer"},pid={value=extraProfile.id_pagina,cfsqltype="cf_sql_integer"}},{datasource="runner_dba"});
        queryExecute("INSERT INTO tb_paginas_vinculos (id_pagina_origem,id_pagina_destino,tipo_vinculo,vinculo_validado,id_usuario_cadastro) VALUES (:a,:b,1,true,:uid)",{a={value=pages[1],cfsqltype="cf_sql_integer"},b={value=extraProfile.id_pagina,cfsqltype="cf_sql_integer"},uid={value=ids[1],cfsqltype="cf_sql_integer"}},{datasource="runner_dba"});
        first=rrChatGroupMembersPage(gid,ids[1]);
        expect(first.items.recordCount EQ 30 && first.has_more && len(first.next_cursor),"initial response returns only 30 members and a continuation");
        expect(first.items.id_usuario[1] EQ ids[33],"confirmed follower comes before alphabetically earlier noncontacts");
        expect(first.items.id_usuario[2] EQ ids[2],"confirmed following contacts receive the same priority");
        expect(first.items.nome[2] EQ "Z Contact 02","multiple profiles preserve the earliest athlete profile without duplicating members");
        expect(first.items.id_usuario[30] EQ ids[30],"all early rows remain contacts across page boundary");
        second=rrChatGroupMembersPage(gid,ids[1],30,first.next_cursor);
        expect(second.items.recordCount EQ 30 && second.has_more,"second page is bounded and has a continuation");
        expect(second.items.id_usuario[1] EQ ids[31] && second.items.id_usuario[2] EQ ids[32],"remaining contacts come before owners and other noncontacts");
        third=rrChatGroupMembersPage(gid,ids[1],30,second.next_cursor);
        expect(third.items.recordCount EQ 5 && !third.has_more && !len(third.next_cursor),"final page ends without an extra download");
        seen=[];for(p in [first,second,third])for(r=1;r<=p.items.recordCount;r++)arrayAppend(seen,p.items.id_usuario[r]);
        unique={};for(uid in seen)unique[uid & ""]=true;
        expect(arrayLen(seen) EQ 65 && structCount(unique) EQ 65,"all members are reachable once, including reciprocal contacts");
        expect(first.items.is_contact[1],"contact marker matches the priority");
        expect(rrChatGroupMembersPage(gid,ids[1],999999).items.recordCount EQ 30,"oversized page requests remain bounded");
        expect(rejects(function(){rrChatGroupMembersPage(gid,ids[2],30,first.next_cursor);}),"cursor cannot be used by another viewer");
        expect(rejects(function(){rrChatGroupMembersPage(gid,ids[1],30,"invalid'");}),"malformed cursor is rejected rather than changing the query");
        before=rrChatGroupMembersPage(gid,ids[1],5);removedId=before.items.id_usuario[5];
        queryExecute("UPDATE tb_chat_grupo_membro SET status='removed' WHERE id_chat_grupo=:gid AND id_usuario=:uid",{gid={value=gid,cfsqltype="cf_sql_bigint"},uid={value=removedId,cfsqltype="cf_sql_integer"}},{datasource="runner_dba"});
        after=rrChatGroupMembersPage(gid,ids[1],5,before.next_cursor);
        expect(after.items.recordCount EQ 5 && after.items.id_usuario[1] EQ ids[6],"removing the cursor's member does not break continuation");
        queryExecute("UPDATE tb_chat_grupo SET modo='channel' WHERE id_chat_grupo=:gid",{gid={value=gid,cfsqltype="cf_sql_bigint"}},{datasource="runner_dba"});
        channelFirst=rrChatGroupMembersPage(gid,ids[1]);
        expect(structKeyExists(channelFirst,"other_members"),"channel exposes an aggregate other member count");
        if(structKeyExists(channelFirst,"other_members"))expect(channelFirst.other_members EQ 34,"other count excludes all followed active members and deduplicates legacy profiles");
        expect(channelFirst.items.recordCount EQ 30 && !channelFirst.has_more,"channel modal only returns followed members, excluding removed contacts");
        expect(channelFirst.items.id_usuario[1] EQ ids[2],"a follower who is not followed is hidden in channels");
        expect(!listFind(valueList(channelFirst.items.id_usuario),ids[1]) && !listFind(valueList(channelFirst.items.id_usuario),ids[33]) && !listFind(valueList(channelFirst.items.id_usuario),ids[34]),"self, incoming-only and unconfirmed followers are not leaked");
        channelOther=rrChatGroupMembersPage(gid,ids[2]);
        expect(channelOther.items.recordCount EQ 1 && channelOther.items.id_usuario[1] EQ ids[1],"each channel member sees their own followed subset");
        expect(rrChatGroupMembersPage(gid,actor).items.recordCount EQ 0,"even global admins see only followed channel members in the public modal");
        expect(rejects(function(){rrChatGroupMembersPage(gid,ids[1],30,first.next_cursor);}),"a group cursor cannot bypass channel privacy after the mode changes");
        channelSmall=rrChatGroupMembersPage(gid,ids[1],10);
        if(structKeyExists(channelSmall,"other_members"))expect(channelSmall.other_members EQ 34,"other count does not depend on the requested page size");
        queryExecute("DELETE FROM tb_paginas_vinculos WHERE id_pagina_origem=:a AND id_pagina_destino=:b AND tipo_vinculo=1",{a={value=pages[1],cfsqltype="cf_sql_integer"},b={value=pages[20],cfsqltype="cf_sql_integer"}},{datasource="runner_dba"});
        channelNext=rrChatGroupMembersPage(gid,ids[1],30,channelSmall.next_cursor);
        if(structKeyExists(channelNext,"other_members"))expect(channelNext.other_members EQ 35,"other count rechecks following after a relation is removed between pages");
        expect(channelNext.items.recordCount EQ 19 && !listFind(valueList(channelNext.items.id_usuario),ids[20]),"every continuation rechecks following privacy instead of trusting the cursor");
        queryExecute("UPDATE tb_chat_grupo_membro SET status='removed' WHERE id_chat_grupo=:gid AND id_usuario=:uid",{gid={value=gid,cfsqltype="cf_sql_bigint"},uid={value=ids[1],cfsqltype="cf_sql_integer"}},{datasource="runner_dba"});
        expect(rejects(function(){rrChatGroupMembersPage(gid,ids[1]);}),"an unsubscribed viewer cannot retrieve channel membership");
      }catch(any e){expect(false,"fixture flow: " & e.message & " " & e.detail & " " & serializeJSON(e.tagContext));}
      transaction action="rollback";
    }
}
cfcontent(type="application/json; charset=utf-8",reset=true);writeOutput(serializeJSON({ok=!arrayLen(failures),tests=tests,failures=failures,rolled_back=true}));
</cfscript>
