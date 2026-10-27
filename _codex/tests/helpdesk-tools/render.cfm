<cfscript>
VARIABLES.helpdeskCanManage=true;VARIABLES.helpdeskTablesReady=true;
qPerfil=queryNew('id','integer',[{id=17}]);URL.pagina=1;URL.ticket_id=999;URL.respostas=0;FORM.helpdesk_action='';
include '../helpdesk/includes/workspace-init.cfm';
hdData={stats={total=0,pendentes=0,em_atendimento=0,aguardando_cliente=0,encerrados=0,sem_atualizacao=0},total=0,page=1,pages=1};
qHelpdeskChamados=queryNew('id_chamado');
qHelpdeskSetores=queryNew('id_setor,nome_setor,ativo,descricao_setor,nome_responsavel','integer,varchar,bit,varchar,varchar',[{id_setor=1,nome_setor='Atendimento',ativo=true,descricao_setor='',nome_responsavel='Equipe'}]);
qHelpdeskSetorEdit=queryNew('id_setor');qHelpdeskAdmins=queryNew('id,name');
qHelpdeskTicketEdit=queryNew('id_chamado,id_usuario,perfil_tag,perfil_tag_prefix,protocolo,status,assunto,nome_usuario,email_usuario,created_at,nome_setor,nome_responsavel,revision,last_message_id,id_setor','integer,integer,varchar,varchar,varchar,varchar,varchar,varchar,varchar,timestamp,varchar,varchar,varchar,integer,integer',[{id_chamado=999,id_usuario=999,perfil_tag='',perfil_tag_prefix='',protocolo='TESTE-PRIVADO',status='fechado',assunto='Chamado sintético',nome_usuario='Solicitante sintético',email_usuario='',created_at=now(),nome_setor='Atendimento',nome_responsavel='Equipe',revision='test',last_message_id=1,id_setor=1}]);
qHelpdeskMensagens=queryNew('id_mensagem,id_usuario,interno,is_admin,nome_usuario,created_at,mensagem','integer,integer,bit,bit,varchar,timestamp,varchar',[{id_mensagem=1,id_usuario=17,interno=true,is_admin=true,nome_usuario='Atendente sintético',created_at=now(),mensagem='<script>alert(1)</script>'&chr(10)&'Nota interna sintética'}]);
savecontent variable='page'{include '../helpdesk/includes/workspace.cfm';}
if(!find('Nota interna · Somente equipe',page) OR !find('&lt;script&gt;',page) OR find('data-helpdesk-ai',page) OR !find('data-text=',page))throw(message='Render da conversa/escape/notas/respostas falhou');
FORM.helpdesk_action='responder_ticket';FORM.message_kind='nota';FORM.ticket_mensagem='Rascunho privado preservado';hdError='Use Salvar nota interna';
savecontent variable='failedNote'{include '../helpdesk/includes/workspace.cfm';}
if(!reFind('value="nota"\s+checked',failedNote) OR !find('Rascunho privado preservado',failedNote))throw(message='Rascunho privado deve continuar marcado como nota após erro de envio público');
FORM.helpdesk_action='';FORM.message_kind='publica';hdError='';
URL.respostas=1;savecontent variable='library'{include '../helpdesk/includes/workspace.cfm';}
if(!find('Gerenciar respostas rápidas',library) OR !find('Confirmar remoção',library) OR !find('respostas_revision',library))throw(message='Biblioteca não renderizou');
if(!reFind('href="[^"\n]*ticket_id&##x3d;999[^"\n]*resposta_id&##x3d;contexto',library))throw(message='Editar modelo deve preservar o chamado selecionado');
newTicketLinks=reMatch('<a [^>]*href="[^"]*"[^>]*>Novo chamado</a>',library);
if(arrayLen(newTicketLinks) NEQ 1 OR find('ticket_id',newTicketLinks[1]))throw(message='Novo chamado não deve herdar o chamado anterior da biblioteca');
writeOutput('HELPDESK_TOOLS_RENDER_PASSED');
</cfscript>
