<!--- Loopback-only runner; keep real queries and rollback every write. --->
<cfinclude template="#VARIABLES.chatPerfTestRoot#/includes/backend/backend_chat_groups.cfm"/>
<cfscript>
tests=0;failures=[];elapsedMs=0;items=0;
function expect(required boolean condition,required string label){tests++;if(!arguments.condition)arrayAppend(failures,arguments.label);}
function rrChatOpenUrl(required string kind,required numeric itemId,required numeric userId,string eventType="",numeric groupId=0){return "/test/";}
function rrNotificationsDispatch(required struct payload,numeric timeoutSeconds=25){return {success=true};}
large=queryExecute("SELECT g.id_chat_grupo,count(m.id_usuario) AS member_count FROM tb_chat_grupo g INNER JOIN tb_chat_grupo_membro m ON m.id_chat_grupo=g.id_chat_grupo AND m.status='active' WHERE g.modo='channel' GROUP BY g.id_chat_grupo HAVING count(m.id_usuario)>=1000 ORDER BY member_count DESC LIMIT 1",{},{datasource="runner_dba"});
actor=queryExecute("SELECT u.id FROM tb_usuarios u WHERE u.is_admin=true ORDER BY CASE WHEN EXISTS (SELECT 1 FROM tb_paginas_usuarios pu INNER JOIN tb_paginas p ON p.id_pagina=pu.id_pagina WHERE pu.id_usuario=u.id AND p.tag='protta') THEN 0 ELSE 1 END,u.id LIMIT 1",{},{datasource="runner_dba"});
expect(large.recordCount GT 0,"large-channel performance fixture is available");
if(large.recordCount){
  transaction {
    try {
      queryExecute("SET LOCAL statement_timeout='3s'",{},{datasource="runner_dba"});
      // Independent reference set: approved outgoing follows, not the production CTE.
      expected=queryExecute("SELECT DISTINCT m.id_usuario FROM tb_paginas_usuarios viewer INNER JOIN tb_paginas_vinculos link ON link.id_pagina_origem=viewer.id_pagina AND link.tipo_vinculo=1 AND link.vinculo_validado=true INNER JOIN tb_paginas_usuarios peer ON peer.id_pagina=link.id_pagina_destino INNER JOIN tb_chat_grupo_membro m ON m.id_usuario=peer.id_usuario AND m.id_chat_grupo=:gid WHERE viewer.id_usuario=:uid AND peer.id_usuario<>:uid AND m.status IN ('active','pending') AND coalesce(m.elegibilidade_status,'eligible')='eligible' AND coalesce(m.bloqueado_moderacao,false)=false",{gid={value=large.id_chat_grupo,cfsqltype="cf_sql_bigint"},uid={value=actor.id,cfsqltype="cf_sql_integer"}},{datasource="runner_dba"});
      started=getTickCount();page=rrChatGroupMembersPage(large.id_chat_grupo,actor.id);elapsedMs=getTickCount()-started;items=page.items.recordCount;
      expect(elapsedMs LT 2500,"a channel with at least 1000 members loads within 2.5 seconds");
      expect(items EQ min(30,expected.recordCount),"the optimized channel returns the expected followed subset, bounded to 30");
      onlyFollowed=true;for(row=1;row<=items;row++)if(!listFind(valueList(expected.id_usuario),page.items.id_usuario[row]))onlyFollowed=false;
      expect(onlyFollowed,"every returned channel member belongs to the independently derived followed subset");
    }catch(any e){elapsedMs=getTickCount()-started;expect(false,"large-channel lookup failed: " & e.message);}
    transaction action="rollback";
  }
}
cfcontent(type="application/json; charset=utf-8",reset=true);writeOutput(serializeJSON({ok=!arrayLen(failures),tests=tests,failures=failures,elapsed_ms=elapsedMs,items=items,member_count=large.recordCount ? large.member_count : 0,rolled_back=true}));
</cfscript>
