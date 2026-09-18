<cfif NOT listFind("127.0.0.1,::1",CGI.REMOTE_ADDR) OR CGI.REQUEST_METHOD NEQ "POST"><cfheader statuscode="404"/><cfabort/></cfif>
<cfscript>
// Synthetic regression suite: no Gmail calls, no real mailbox content.
mailTests=[];
function mailAssert(required boolean condition,required string label) {if(!arguments.condition) throw(type="AIMail.Test",message=arguments.label);arrayAppend(mailTests,arguments.label);}
function mailFixtureMessage(required string id,required string body,numeric ms=1700000000000,array labels=["INBOX","UNREAD"],string sender="Fornecedor <teste@example.com>") {
 return {id=arguments.id,threadId="fixturethread",internalDate=arguments.ms&"",labelIds=arguments.labels,payload={mimeType="text/plain",headers=[{name="From",value=arguments.sender},{name="Subject",value="Solicitação de confirmação"},{name="Message-ID",value="<"&arguments.id&"@example.com>"}],body={data=replace(replace(replace(toBase64(charsetDecode(arguments.body,"utf-8")),"+","-","all"),"/","_","all"),"=","","all")}}};
}
base=mailFixtureMessage("msg1","Confirme a quantidade até 17/09/2026 às 12:00.");
context=mailContext({messages=[base]},"contato@runnerhub.run");
mailAssert(context.source_available && context.in_inbox && arrayLen(context.messages)==1,"MIME / inbox decoded");
mailAssert(find("Confirme",context.messages[1].text)>0,"Body decoded from URL-safe base64");
read=duplicate(base);read.labelIds=["INBOX"];
mailAssert(mailContext({messages=[read]},"contato@runnerhub.run").hash==context.hash,"Read/unread does not change content hash");
archived=duplicate(base);archived.labelIds=[];
mailAssert(!mailContext({messages=[archived]},"contato@runnerhub.run").in_inbox,"Archive remains available");
deleted=duplicate(base);deleted.labelIds=["TRASH"];
mailAssert(!mailContext({messages=[deleted]},"contato@runnerhub.run").source_available,"Trash excluded from context");
sent=mailFixtureMessage("msg2","Confirmado. Obrigado.",1700000060000,["SENT"],"contato@runnerhub.run");
conversation=mailContext({messages=[base,sent]},"contato@runnerhub.run");
mailAssert(conversation.last_inbound_ms==val(base.internalDate) && arrayLen(conversation.messages)==2,"Sent context does not become a new inbound");
mailAssert(!find("alert",mailText('<script>alert(1)</script><p>Olá</p><img src="https://example.com/tracker">',true)),"HTML scripts and trackers removed");
mailAssert(!find("segredo123",mailText("senha: segredo123")),"Credentials redacted");
analysis={relevant=true,priority="high",category="operacao",summary="Fornecedor pede confirmação.",reason="Prazo explícito.",needs_response=true,needs_review=false,new_request=true,source_message_id="msg1",deadline_at="2026-09-17T12:00:00-03:00",deadline_text="17/09/2026 às 12:00",actions=[{text="Confirmar quantidade.",source_message_id="msg1"}]};
valid=mailValidateAnalysis(duplicate(analysis),context);
mailAssert(valid.deadline_valid,"Deadline requires verbatim evidence and offset");
invalid=duplicate(analysis);invalid.deadline_text="amanhã às 7h";
mailAssert(mailValidateAnalysis(invalid,context).deadline_at=="","Invented deadline discarded");
unknown=duplicate(analysis);unknown.source_message_id="unknown";rejected=false;
try{mailValidateAnalysis(unknown,context);}catch(any e){rejected=true;}
mailAssert(rejected,"Unknown source rejected");
low=duplicate(analysis);low.priority="low";low.relevant=false;
corrected=mailValidateAnalysis(low,context);mailAssert(corrected.relevant && corrected.priority=="normal" && corrected.needs_review,"Actionable low-priority output cannot disappear");
previous={state="resolved",resolved_inbound_ms=1700000000000};
mailAssert(!mailShouldReopen(analysis,context,previous),"Reprocessing same message cannot reopen");
newContext=duplicate(context);newContext.last_inbound_ms+=60000;newContext.versions[1].ms+=60000;
mailAssert(mailShouldReopen(analysis,newContext,previous),"New relevant request reopens");
thanks=duplicate(analysis);thanks.new_request=false;
mailAssert(!mailShouldReopen(thanks,newContext,previous),"Thank-you does not reopen");
uncertain=duplicate(analysis);uncertain.needs_review=true;
mailAssert(!mailShouldReopen(uncertain,newContext,previous),"Uncertain request flagged rather than auto-reopened");
wire=serializeJSON(mailWire({MixedKey={NestedValue=true}}));
mailAssert(find('"mixedkey"',wire)>0 && find('"nestedvalue"',wire)>0,"JSON API keys remain lowercase");
mailAssert(find('"additionalProperties"',serializeJSON(mailWire(mailSchema())))>0,"JSON Schema retains case-sensitive additionalProperties");
</cfscript>
