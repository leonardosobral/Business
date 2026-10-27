component {
 variables.done=false;variables.content='';variables.suppressed='';variables.blocked=false;
 public numeric function generateAgendaAdded(){return 2;}
 public numeric function generateAgendaReminders(){return 3;}
 public numeric function generatePublishedResults(){return 4;}
 public numeric function generateBrasilGiganteReminders(){return 5;}
 public struct function claimNext(){if(variables.done)return {};variables.done=true;return {id_vicky_notificacao_fila=1,id_vicky_notificacao_template=2,id_usuario=142,channel='web',reference_type='brasil_gigante_event',payload={event_name='Aracaju',event_tag='aracaju',event_date='2026-10-31'}};}
 public struct function template(numeric id){return {content='**Mais uma etapa está chegando**' & chr(10) & chr(10) & 'Lembre-se de reconhecer seus resultados nas etapas já concluídas e manter o seu perfil atualizado.',rule_code='brasil_gigante_d7',provider_template_name='atualize_cbg'};}
 public struct function brasilGiganteDeliveryState(struct job){return {eligible=!variables.blocked,deferred=false};}
 public void function block(){variables.blocked=true;}
 public numeric function webConversation(numeric userId){return 20;}
 public void function insertWebMessage(numeric conversationId,string content,numeric queueId){variables.content=arguments.content;}
 public void function complete(numeric id,string providerId){}
 public void function fail(numeric id,string code){throw(message='Unexpected failure: ' & arguments.code);}
 public void function suppress(numeric id,string code){variables.suppressed=arguments.code;}
 public string function savedContent(){return variables.content;}
 public string function suppression(){return variables.suppressed;}
}
