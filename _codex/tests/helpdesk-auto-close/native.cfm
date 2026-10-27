<cfscript>
checks=0;
function check(required boolean yes,required string name){if(!yes)throw(type='Test.Failed',message=name);checks++;}
service=new services.HelpdeskAutoClose();
fixtures="WITH tb_helpdesk_chamados(id_chamado,id_usuario,status,updated_at) AS (VALUES
 (1,10,'aguardando_cliente',localtimestamp),(2,10,'em_atendimento',localtimestamp),(3,10,'fechado',localtimestamp),(4,10,'resolvido',localtimestamp),(5,10,'aberto',localtimestamp),(6,10,'cliente_respondeu',localtimestamp),(7,10,'aguardando_cliente',localtimestamp),(8,10,'aguardando_cliente',localtimestamp),(9,10,'aguardando_cliente',localtimestamp),(10,20,'aguardando_cliente',localtimestamp),(11,10,'aberto',localtimestamp),(12,10,'aberto',localtimestamp),(13,10,'aberto',localtimestamp),(14,10,'aberto',localtimestamp),(15,10,'desconhecido',localtimestamp)),
tb_usuarios(id,is_admin) AS (VALUES (10,false),(20,true)),
tb_helpdesk_mensagens(id_mensagem,id_chamado,id_usuario,mensagem,interno,created_at) AS (VALUES
 (1,1,20,'Resposta',false,localtimestamp-interval '49 hours'),
 (2,2,20,'Resposta',false,localtimestamp-interval '49 hours'),
 (3,3,20,'Resposta',false,localtimestamp-interval '49 hours'),
 (4,4,20,'Resposta',false,localtimestamp-interval '49 hours'),
 (5,5,20,'Resposta',false,localtimestamp-interval '48 hours'),
 (6,6,10,'Resposta do cliente',false,localtimestamp-interval '49 hours'),
 (7,7,20,'Resposta',false,localtimestamp-interval '49 hours'),
 (8,7,10,'Nova resposta do cliente',false,localtimestamp-interval '1 hour'),
 (9,8,20,'Resposta',false,localtimestamp-interval '49 hours'),
 (10,8,20,'Nota interna',true,localtimestamp-interval '1 hour'),
 (11,9,20,'Resposta',false,localtimestamp-interval '1 hour'),
 (12,10,20,'Solicitante também admin',false,localtimestamp-interval '49 hours'),
 (20,12,20,'Equipe primeiro',false,localtimestamp-interval '49 hours'),
 (21,12,10,'Cliente por último no mesmo instante',false,localtimestamp-interval '49 hours'),
 (22,13,10,'Cliente primeiro',false,localtimestamp-interval '49 hours'),
 (23,13,20,'Equipe por último no mesmo instante',false,localtimestamp-interval '49 hours'),
 (24,14,20,:message,false,localtimestamp-interval '49 hours'),
 (25,15,20,'Estado não reconhecido',false,localtimestamp-interval '49 hours')) ";
q=queryExecute(fixtures & service.candidatesSql(false),{limit={value=50,cfsqltype='cf_sql_integer'},message={value=service.message(),cfsqltype='cf_sql_longvarchar'}},{datasource='runner_dba'});
check(valueList(q.id_chamado) EQ '1,4,8,13','Somente resposta pública da equipe >48h; empate por id, aviso automático e estados protegidos respeitados');
q=queryExecute(fixtures & service.candidatesSql(false),{limit={value=1,cfsqltype='cf_sql_integer'},message={value=service.message(),cfsqltype='cf_sql_longvarchar'}},{datasource='runner_dba'});check(q.recordCount EQ 1 AND q.id_chamado EQ 1,'Lote limitado e ordem determinística');
writeOutput('HELPDESK_CLOSE_NATIVE_PASSED ' & checks);
</cfscript>
