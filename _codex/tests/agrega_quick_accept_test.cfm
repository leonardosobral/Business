<cfif fileExists(expandPath('quick_accept.cfm'))><cfinclude template="quick_accept.cfm" /></cfif>
<cfscript>
checks=[];
if (!structKeyExists(variables,"agregaReviewAcceptSuggestion")) {
 writeOutput(serializeJSON([{test="Aceitar sugestão cria e vincula em uma transação",passed=false,reason="A ação combinada ainda não existe."}]));
} else {
 function fixture() {
  queryExecute("CREATE TEMP TABLE tb_agrega_eventos (id_agrega_evento serial PRIMARY KEY,nome_evento_agregado varchar(256) NOT NULL,tipo_agregacao varchar(24),tag varchar,id_tema integer,divisao varchar,ordem integer) ON COMMIT DROP");
  queryExecute("CREATE TEMP TABLE tb_evento_corridas (id_evento integer PRIMARY KEY,id_agrega_evento integer,ativo boolean NOT NULL DEFAULT true) ON COMMIT DROP");
  queryExecute("CREATE TEMP TABLE tb_evento_agrega_review_groups (id_evento_agrega_review_group bigint PRIMARY KEY,group_key varchar(128),status varchar,candidate_count integer,suggested_id_agrega_evento integer,reviewed_by bigint,reviewed_at timestamp,review_note text,data_atualizacao timestamp) ON COMMIT DROP");
  queryExecute("CREATE TEMP TABLE tb_evento_agrega_review_candidates (id_evento_agrega_review_candidate bigint PRIMARY KEY,id_evento_agrega_review_group bigint,id_evento integer,id_agrega_evento_atual integer,status varchar,reviewed_by bigint,reviewed_at timestamp,review_note text,data_atualizacao timestamp) ON COMMIT DROP");
  queryExecute("INSERT INTO pg_temp.tb_evento_corridas (id_evento) VALUES (101),(102)");
  queryExecute("INSERT INTO pg_temp.tb_evento_agrega_review_groups VALUES (1,'edicoes-v1:101:102','review',2,NULL,NULL,NULL,'critério original',now())");
  queryExecute("INSERT INTO pg_temp.tb_evento_agrega_review_candidates (id_evento_agrega_review_candidate,id_evento_agrega_review_group,id_evento,status) VALUES (11,1,101,'active'),(12,1,102,'active')");
 }
 // Real SQL against session-local temporary tables. No production sequences or event rows are touched.
 transaction {
  fixture();
  r=agregaReviewAcceptSuggestion(1,"  Corrida da Cidade  ",999,"101,102");
  q=queryExecute("SELECT a.nome_evento_agregado,a.tipo_agregacao,a.id_tema,a.divisao,a.ordem,(SELECT count(*) FROM pg_temp.tb_evento_corridas WHERE id_agrega_evento=a.id_agrega_evento) linked,(SELECT count(*) FROM pg_temp.tb_evento_agrega_review_candidates WHERE status='applied' AND reviewed_by=999) audited,(SELECT status FROM pg_temp.tb_evento_agrega_review_groups WHERE id_evento_agrega_review_group=1) state FROM pg_temp.tb_agrega_eventos a");
  arrayAppend(checks,{test="Cria e vincula as duas provas com auditoria",passed=q.recordCount==1 AND q.linked[1]==2 AND q.audited[1]==2 AND q.state[1]=="applied" AND q.nome_evento_agregado[1]=="Corrida da Cidade" AND q.tipo_agregacao[1]=="corrida" AND q.id_tema[1]==1 AND q.divisao[1]=="distancia" AND q.ordem[1]==300});
  r2=agregaReviewAcceptSuggestion(1,"Corrida da Cidade",999,"101,102");
  q=queryExecute("SELECT count(*) n FROM pg_temp.tb_agrega_eventos");
  arrayAppend(checks,{test="Envio repetido não duplica nem reaplica",passed=r2.alreadyApplied AND q.n[1]==1});
  transaction action="rollback";
 }
 for (testCase in ["blank","long","existing_name","already_linked","inactive","changed_pair","third_candidate","ignored","manual","suggested","candidate_ignored","late_failure"]) {
  failed=false;message="";
  try {
   transaction {
    fixture(); name="Corrida da Cidade";expected="101,102";
    switch (testCase) {
     case "blank": name="  ";break;
     case "long": name=repeatString("a",257);break;
     case "existing_name": queryExecute("INSERT INTO pg_temp.tb_agrega_eventos (nome_evento_agregado) VALUES ('corrida da cidade')");break;
     case "already_linked": queryExecute("UPDATE pg_temp.tb_evento_corridas SET id_agrega_evento=25 WHERE id_evento=102");break;
     case "inactive": queryExecute("UPDATE pg_temp.tb_evento_corridas SET ativo=false WHERE id_evento=102");break;
     case "changed_pair": expected="101,103";break;
     case "third_candidate": queryExecute("INSERT INTO pg_temp.tb_evento_corridas VALUES (103,NULL,true)");queryExecute("INSERT INTO pg_temp.tb_evento_agrega_review_candidates (id_evento_agrega_review_candidate,id_evento_agrega_review_group,id_evento,status) VALUES (13,1,103,'active')");break;
     case "ignored": queryExecute("UPDATE pg_temp.tb_evento_agrega_review_groups SET status='ignored'");break;
     case "manual": queryExecute("UPDATE pg_temp.tb_evento_agrega_review_groups SET group_key='manual:101:102'");break;
     case "suggested": queryExecute("UPDATE pg_temp.tb_evento_agrega_review_groups SET suggested_id_agrega_evento=20");break;
     case "candidate_ignored": queryExecute("UPDATE pg_temp.tb_evento_agrega_review_candidates SET status='ignored' WHERE id_evento=102");break;
     case "late_failure": queryExecute("ALTER TABLE pg_temp.tb_evento_corridas ADD CONSTRAINT reject_link CHECK (id_agrega_evento IS NULL)");break;
    }
    agregaReviewAcceptSuggestion(1,name,999,expected);
    transaction action="rollback";
   }
  } catch (any e) { failed=true;message=e.message; }
  arrayAppend(checks,{test=testCase,passed=failed,message=message});
 }
 writeOutput(serializeJSON(checks));
}
</cfscript>
