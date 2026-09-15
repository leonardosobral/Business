<cfapplication name="helpdesk_offline_fixture" sessionmanagement="true">
<cfscript>
VARIABLES.helpdeskCanManage=true;
VARIABLES.helpdeskTablesReady=true;
function check(required boolean condition,required string message) { if (!arguments.condition) throw(message=arguments.message); }
svc=createObject('component','helpdesk.includes.HelpdeskWorkspace');
f=svc.filters({busca="  50%_! O'Reilly  ",status="invalido",setor="1 OR 1=1",fila="meus",pagina="-1",ordem="DROP TABLE"});
check(f.status EQ "" AND f.setor EQ 0 AND f.pagina EQ 1 AND f.ordem EQ "prioridade","Input allowlists");
p=svc.plan(f,42);
check(p.params.busca.value EQ "%50!%!_!! O'Reilly%","Literal search escaping");
check(NOT find("O'Reilly",p.sql) AND p.params.responsavel.value EQ 42,"Parameterized search and own sectors");
check(find("cliente_respondeu",p.order) GT 0,"Returned tickets first");
p=svc.plan(svc.filters({status='resolvido',setor='2',fila='sem_atualizacao',ordem='antigos'}),42);
check(find('48 hours',p.sql) GT 0 AND p.params.status.value EQ 'resolvido' AND p.params.setor.value EQ 2,"Combined filters");
check(p.order EQ 'cham.created_at ASC, cham.id_chamado ASC',"Deterministic ordering");
url.ticket_id=101;url.busca='Teste & exemplo';
</cfscript>
<cfinclude template="helpdesk/includes/workspace-init.cfm">
<cfscript>
SESSION.helpdeskAICsrf='test-only-no-real-token';
qHelpdeskAdmins=queryNew('id,name','integer,varchar',[{id=42,name='Atendente de teste'}]);
qHelpdeskSetores=queryNew('id_setor,nome_setor,descricao_setor,id_usuario_responsavel,nome_responsavel,ativo','integer,varchar,varchar,integer,varchar,bit',[{id_setor=1,nome_setor='Suporte ao atleta',descricao_setor='Dados sintéticos de teste',id_usuario_responsavel=42,nome_responsavel='Atendente de teste',ativo=true}]);
qHelpdeskSetorEdit=queryNew('id_setor,nome_setor,descricao_setor,id_usuario_responsavel,ativo');
qHelpdeskChamados=queryNew('id_chamado,protocolo,assunto,status,id_setor,created_at,updated_at,nome_usuario,email_usuario,nome_setor,nome_responsavel,mensagens,sem_atualizacao','integer,varchar,varchar,varchar,integer,timestamp,timestamp,varchar,varchar,varchar,varchar,integer,bit');
for (i=1;i LTE 6;i++) queryAddRow(qHelpdeskChamados,{id_chamado=100+i,protocolo='HD-TESTE-' & i,assunto=i EQ 1 ? 'Resultado da corrida não aparece' : 'Exemplo de chamado ' & i,status=listGetAt('cliente_respondeu,aberto,em_atendimento,aguardando_cliente,resolvido,fechado',i),id_setor=1,created_at=dateAdd('d',-5,now()),updated_at=dateAdd('d',-2,now()),nome_usuario='Usuário de teste',email_usuario='teste@example.invalid',nome_setor='Suporte ao atleta',nome_responsavel='Atendente de teste',mensagens=3,sem_atualizacao=i LTE 4});
qHelpdeskTicketEdit=queryNew('id_chamado,protocolo,assunto,status,id_setor,created_at,updated_at,nome_usuario,email_usuario,nome_setor,nome_responsavel,revision,last_message_id','integer,varchar,varchar,varchar,integer,timestamp,timestamp,varchar,varchar,varchar,varchar,varchar,integer',[{id_chamado=101,protocolo='HD-TESTE-1',assunto='Resultado da corrida não aparece',status='cliente_respondeu',id_setor=1,created_at=dateAdd('d',-5,now()),updated_at=now(),nome_usuario='Usuário de teste',email_usuario='teste@example.invalid',nome_setor='Suporte ao atleta',nome_responsavel='Atendente de teste',revision='2026-09-14 10:00:00.000000',last_message_id=2}]);
qHelpdeskMensagens=queryNew('id_mensagem,id_usuario,mensagem,created_at,is_admin,nome_usuario,email_usuario','integer,integer,varchar,timestamp,bit,varchar,varchar',[{id_mensagem=1,id_usuario=100,mensagem='Olá, não encontrei o resultado da corrida no meu perfil. Como posso conferir?',created_at=dateAdd('d',-2,now()),is_admin=false,nome_usuario='Usuário de teste',email_usuario='teste@example.invalid'},{id_mensagem=2,id_usuario=42,mensagem='Você pode informar a edição da prova? <script>alert(1)</script>',created_at=now(),is_admin=true,nome_usuario='Atendente de teste',email_usuario='atendente@example.invalid'}]);
hdData={total=26,page=1,pages=2,stats=queryNew('total,pendentes,em_atendimento,aguardando_cliente,encerrados,sem_atualizacao','integer,integer,integer,integer,integer,integer',[{total=26,pendentes=8,em_atendimento=6,aguardando_cliente=4,encerrados=8,sem_atualizacao=3}])};
</cfscript>
<!doctype html><html lang="pt-br"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Helpdesk · teste sintético local</title><link rel="stylesheet" href="/assets/css/mdb.min.css"><link rel="stylesheet" href="/assets/css/business-ui.css"><link rel="stylesheet" href="/assets/fontawesome/css/all.min.css"></head><body data-mdb-theme="dark" style="background:#141b25;padding:24px"><p>Ambiente de teste · dados fictícios · não conectado à produção</p><cfinclude template="helpdesk/includes/workspace.cfm"></body></html>
