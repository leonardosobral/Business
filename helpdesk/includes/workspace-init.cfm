<cfif NOT structKeyExists(VARIABLES,"helpdeskCanManage") OR NOT VARIABLES.helpdeskCanManage><cfheader statuscode="403"/><cfabort/></cfif>
<cfscript>
hdService=createObject("component","helpdesk.includes.HelpdeskWorkspace");
hdFilters=hdService.filters(URL);
hdError="";
hdLibraryError="";
hdReplies=createObject('component','helpdesk.includes.HelpdeskReplies').init();
hdReplyLibrary={items=[],revision=''};
try{hdReplyLibrary=hdReplies.list();}catch(any unavailable){hdLibraryError='Não foi possível carregar as respostas rápidas. Recarregue a página; suas respostas anteriores foram preservadas.';}
helpdeskAdminHandled=false;
if (!structKeyExists(SESSION,"helpdeskCsrf")) SESSION.helpdeskCsrf=lCase(hash(generateSecretKey("AES",256),"SHA-256"));
function hdUrl(struct changes={}) {
  var values=duplicate(VARIABLES.hdFilters);
  if(val(URL.respostas ?: 0) EQ 1 AND !val(arguments.changes.ticket_novo ?: 0) AND reFind('^[0-9]{1,9}$',URL.ticket_id ?: '')) values.ticket_id=val(URL.ticket_id);
  structAppend(values,arguments.changes,true);
  var pairs=[];
  for (var key in ["busca","status","setor","fila","ordem","pagina","ticket_id","ticket_novo","setor_id","setor_novo","gestao","salvo","respostas","resposta_id"]) {
    if (structKeyExists(values,key) AND len(values[key] & "") AND values[key] NEQ "0") arrayAppend(pairs,encodeForURL(key) & "=" & encodeForURL(values[key] & ""));
  }
  return "./?" & arrayToList(pairs,"&");
}
function hdStatus(required string value) {
  var labels={aberto="Aberto",cliente_respondeu="Usuário respondeu",em_atendimento="Em atendimento",aguardando_cliente="Aguardando usuário",resolvido="Resolvido",fechado="Fechado"};
  return labels[arguments.value] ?: arguments.value;
}
function hdAge(required any value) {
  var minutes=max(0,dateDiff("n",arguments.value,now()));
  if (minutes LT 1) return "agora";
  if (minutes LT 60) return "há " & minutes & " min";
  if (minutes LT 1440) return "há " & int(minutes/60) & " h";
  return "há " & int(minutes/1440) & " dias";
}
</cfscript>
