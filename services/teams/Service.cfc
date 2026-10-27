component output=false {
    variables.ds='runner_dba';variables.schema='rr_teams';
    public any function init(string datasource='runner_dba',string schema='rr_teams') {
        if(!reFind('^[a-z][a-z0-9_]{0,60}$',schema))throw(type='Teams.Validation',message='Esquema inválido.');
        variables.ds=datasource;variables.schema=schema;return this;
    }
    private any function q(required string sql,struct params={}) {
        var bound={};for(var key in params)bound[key]=isStruct(params[key])?params[key]:{value=params[key],cfsqltype=listFindNoCase('id,user,team,actor,athlete,subjectId,offset,limit,version',key)?'cf_sql_bigint':'cf_sql_varchar'};
        return queryExecute(replace(sql,'{s}',variables.schema,'all'),bound,{datasource=variables.ds,timeout=15});
    }
    private struct function first(required query rows) {var row={};if(rows.recordCount)for(var k in listToArray(rows.columnList))row[k]=isNull(rows[k][1])?'':rows[k][1];return row;}
    private numeric function ident(required any value) {if(!isSimpleValue(value)||!reFind('^[1-9][0-9]{0,14}$',trim(value & '')))throw(type='Teams.Validation',message='Identificador inválido.');return val(value);}
    private void function invalid(required string message) {throw(type='Teams.Validation',message=message);}
    private void function forbidden() {throw(type='Teams.Forbidden',message='Você não tem permissão para esta operação.');}
    private string function field(required struct data,required string key,numeric size=255,boolean mandatory=false) {
        var value=structKeyExists(data,key)?data[key]:'';if(!isSimpleValue(value))invalid('Campo inválido: ' & key);
        value=trim(value & '');if(len(value)>size || (mandatory && !len(value)))invalid('Preencha corretamente: ' & key & '.');return value;
    }
    public boolean function ready() {
        return q("SELECT count(*)=12 ready FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname=:schema AND c.relname IN ('team','admin','athlete_clock','membership','exclusion','admin_invite','recruit_invite','audit','funnel','notice','mail_outbox','schema_version') AND c.relkind='r'",{schema=variables.schema}).ready[1];
    }
    public struct function actor(required any userId) {
        var user=first(q('SELECT u.id,u.name,u.email,coalesce(u.is_admin,false) is_admin,coalesce(u.is_dev,false) is_dev FROM public.tb_usuarios u LEFT JOIN public.tb_usuarios_gestao g ON g.id_usuario=u.id WHERE u.id=:id AND coalesce(g.ativo,true) AND NOT coalesce(g.excluido,false)',{id=ident(userId)}));
        if(structIsEmpty(user))forbidden();return user;
    }
    private struct function authority(required any userId,required any teamId,boolean write=false,boolean owner=false) {
        var user=actor(userId);var team=first(q('SELECT t.*,a.role FROM {s}.team t LEFT JOIN {s}.admin a ON a.team_id=t.id_team AND a.user_id=:user WHERE t.id_team=:team',{user=user.id,team=ident(teamId)}));
        if(structIsEmpty(team))forbidden();if(user.is_admin){team.role='GLOBAL';return team;}
        if(!len(team.role) || (write && !listFind('OWNER,ADMIN',team.role)) || (owner && team.role!='OWNER'))forbidden();
        return team;
    }
    private struct function adminPolicy(required string role) {
        var roles=role=='GLOBAL'?'OWNER,ADMIN,VIEWER':(role=='OWNER'?'ADMIN,VIEWER':(role=='ADMIN'?'VIEWER':''));
        return {roles=roles,canEdit=listFind('GLOBAL,OWNER',role)>0,canRemove=listFind('GLOBAL,OWNER',role)>0};
    }
    private void function checkAdminGrant(required struct access,required string role) {
        if(!listFind(adminPolicy(access.role).roles,role))forbidden();
    }
    private void function checkPendingAdminGrant(required struct access,required string email) {
        if(access.role=='ADMIN'&&q("SELECT 1 FROM {s}.admin_invite WHERE team_id=:team AND lower(email)=lower(:email) AND role='ADMIN' AND accepted_at IS NULL AND revoked_at IS NULL AND expires_at>CURRENT_TIMESTAMP",{team=access.id_team,email=email}).recordCount)forbidden();
    }
    private void function audit(required numeric actorId,required numeric teamId,required string event,numeric subjectId=0,string detail='') {
        q('INSERT INTO {s}.audit(actor_id,team_id,event,subject_id,detail) VALUES(:actor,NULLIF(:team,0),:event,NULLIF(:subjectId,0),:detail)',{actor=actorId,team=teamId,event=event,subjectId=subjectId,detail=left(detail,1600)});
    }
    private void function notice(required numeric userId,required string message) {q('INSERT INTO {s}.notice(user_id,message) VALUES(:user,:message)',{user=userId,message=left(message,500)});}
    private void function funnel(required numeric userId,required numeric teamId,required string event) {q('INSERT INTO {s}.funnel(user_id,team_id,event) VALUES(:user,NULLIF(:team,0),:event)',{user=userId,team=teamId,event=event});}
    private void function queueMail(required string destination,required string recipient,required string subject,required string body) {
        q('INSERT INTO {s}.mail_outbox(destination,recipient_name,subject,body) VALUES(:to,:name,:subject,:body)',{to=destination,name=left(recipient,200),subject=left(subject,200),body=body});
    }
    public boolean function validDocument(required string value) {
        var d=reReplace(value,'[^0-9]','','all');if(!listFind('11,14',len(d)) || reFind('^([0-9])\1+$',d))return false;
        if(len(d)==11){for(var n=9;n<=10;n++){var sum=0;for(var i=1;i<=n;i++)sum+=val(mid(d,i,1))*(n+2-i);var digit=(sum*10) MOD 11;if(digit==10)digit=0;if(digit!=val(mid(d,n+1,1)))return false;}}
        else {for(var n=12;n<=13;n++){var sum=0;var weight=n-7;for(var i=1;i<=n;i++){sum+=val(mid(d,i,1))*weight;weight--;if(weight<2)weight=9;}var rest=sum MOD 11;var digit=rest<2?0:11-rest;if(digit!=val(mid(d,n+1,1)))return false;}}
        return true;
    }
    private struct function fields(required struct data) {
        var limits={name=160,type=20,document=20,ownerName=200,technicalName=200,cref=30,crefUf=2,email=255,phone=30,whatsapp=30,city=100,uf=2,attendance=15,description=1600,website=500};var out={};
        for(var key in limits)out[key]=field(data,key,limits[key],!listFindNoCase('description,website',key));
        out.type=uCase(out.type);out.attendance=uCase(out.attendance);out.uf=uCase(out.uf);out.crefUf=uCase(out.crefUf);out.email=lCase(out.email);out.document=reReplace(out.document,'[^0-9]','','all');
        out.phone=reReplace(out.phone,'[^0-9]','','all');out.whatsapp=reReplace(out.whatsapp,'[^0-9]','','all');out.cref=uCase(out.cref);
        if(!validDocument(out.document))invalid('Informe um CPF ou CNPJ válido.');
        if(!listFind('TREINADOR,ASSESSORIA,CLUBE,ACADEMIA,GRUPO,EMPRESA',out.type))invalid('Tipo de Team inválido.');
        if(!listFind('PRESENCIAL,ONLINE,AMBOS',out.attendance))invalid('Selecione a modalidade de atendimento.');
        var states='AC,AL,AP,AM,BA,CE,DF,ES,GO,MA,MT,MS,MG,PA,PB,PR,PE,PI,RJ,RN,RS,RO,RR,SC,SP,SE,TO';
        if(!listFind(states,out.uf)||!listFind(states,out.crefUf))invalid('Selecione uma UF válida.');
        if(!isValid('email',out.email)||reFind('[\r\n]',out.email))invalid('Informe um email comercial válido.');
        if(!reFind('^[0-9]{10,13}$',out.phone)||!reFind('^[0-9]{10,13}$',out.whatsapp))invalid('Informe telefone e WhatsApp com DDD.');
        if(!reFind('^[0-9]{3,10}[A-Z0-9 /-]{0,19}$',out.cref))invalid('Informe o número completo do CREF.');
        if(len(out.website) && !reFindNoCase('^https://[a-z0-9][a-z0-9.-]+(?::[0-9]{1,5})?(/[^\s]*)?$',out.website))invalid('O site deve começar com https://.');
        return out;
    }
    public numeric function register(required any userId,required struct data) {
        return createTeam(actor(userId),data,false);
    }
    public numeric function registerGlobal(required any userId,required struct data) {
        var user=actor(userId);if(!user.is_admin)forbidden();
        return createTeam(user,data,true);
    }
    private numeric function createTeam(required struct user,required struct data,required boolean manual) {
        var f=fields(data);var id=0;
        transaction {
            q('SELECT id FROM public.tb_usuarios WHERE id=:id FOR UPDATE',{id=user.id});
            if(!manual && q("SELECT count(*) n FROM {s}.team WHERE requested_by=:user AND created_at>CURRENT_TIMESTAMP-interval '1 day'",{user=user.id}).n[1]>=5)invalid('Limite diário de solicitações atingido.');
            if(q('SELECT 1 FROM {s}.team WHERE document=:document AND lower(name)=lower(:name)',f).recordCount)invalid('Já existe uma solicitação para este Team e documento.');
            f.actor=user.id;
            id=q('INSERT INTO {s}.team(name,type,document,owner_name,technical_name,cref,cref_uf,email,phone,whatsapp,city,uf,attendance,description,website,requested_by) VALUES(:name,:type,:document,:ownerName,:technicalName,:cref,:crefUf,:email,:phone,:whatsapp,:city,:uf,:attendance,:description,:website,:actor) RETURNING id_team',f).id_team[1];
            var slug=lCase(reReplace(f.name,'[^a-zA-Z0-9]+','-','all'));slug=reReplace(slug,'(^-+|-+$)','','all');if(!len(slug))slug='team';slug=left(slug,150) & '-' & id;
            q('UPDATE {s}.team SET slug=:slug WHERE id_team=:id',{slug=slug,id=id});
            if(!manual)q("INSERT INTO {s}.admin(team_id,user_id,role) VALUES(:team,:user,'OWNER')",{team=id,user=user.id});
            audit(user.id,id,manual?'TEAM_REGISTER_MANUAL':'TEAM_REGISTER');
        }return id;
    }
    public void function updateTeam(required any userId,required any teamId,required struct data,required any version) {
        var f=fields(data);var access=authority(userId,teamId,true);var expected=ident(version);
        transaction {
            var old=first(q('SELECT * FROM {s}.team WHERE id_team=:id FOR UPDATE',{id=access.id_team}));
            authority(userId,teamId,true);if(old.version!=expected)invalid('O cadastro foi atualizado por outra pessoa. Recarregue a página.');
            if(listFind('SUSPENDED,ARCHIVED',old.status))invalid('Solicite ao RR a revisão deste cadastro.');
            if(q('SELECT 1 FROM {s}.team WHERE document=:document AND lower(name)=lower(:name) AND id_team<>:id',{document=f.document,name=f.name,id=old.id_team}).recordCount)invalid('Já existe um Team com estes dados.');
            var critical=compare(old.document,f.document)!=0 || compare(old.owner_name,f.ownerName)!=0 || compare(old.technical_name,f.technicalName)!=0 || compare(old.cref,f.cref)!=0 || compare(old.cref_uf,f.crefUf)!=0 || compare(old.name,f.name)!=0;
            f.status=(critical || listFind('CHANGES,REJECTED',old.status))?'PENDING':old.status;f.id=old.id_team;
            q('UPDATE {s}.team SET name=:name,type=:type,document=:document,owner_name=:ownerName,technical_name=:technicalName,cref=:cref,cref_uf=:crefUf,email=:email,phone=:phone,whatsapp=:whatsapp,city=:city,uf=:uf,attendance=:attendance,description=:description,website=:website,status=:status,updated_at=CURRENT_TIMESTAMP,version=version+1 WHERE id_team=:id',f);
            if(critical)q('UPDATE {s}.team SET cref_verified_at=NULL,cref_evidence='''' WHERE id_team=:id',{id=old.id_team});
            audit(userId,old.id_team,'TEAM_UPDATE',0,critical?'Dados críticos enviados para revisão.':'Dados de apresentação atualizados.');
        }
    }
    public void function review(required any userId,required any teamId,required string decision,required numeric expectedVersion,string note='',string evidence='') {
        var user=actor(userId);if(!user.is_admin)forbidden();var id=ident(teamId);var action=uCase(decision);
        var statuses={APPROVE='ACTIVE',CHANGES='CHANGES',REJECT='REJECTED',SUSPEND='SUSPENDED',ARCHIVE='ARCHIVED'};
        if(!structKeyExists(statuses,action))invalid('Decisão inválida.');
        if(len(note)>1600 || len(evidence)>1600)invalid('Texto de revisão muito longo.');
        if(action=='APPROVE' && !len(trim(evidence)))invalid('Registre a evidência de verificação do CREF ativo.');
        if(action!='APPROVE' && !len(trim(note)))invalid('Informe o motivo da decisão.');
        transaction {
            var team=first(q('SELECT * FROM {s}.team WHERE id_team=:id FOR UPDATE',{id=id}));if(structIsEmpty(team))forbidden();
            if(team.version!=ident(expectedVersion))invalid('O cadastro mudou desde sua consulta. Recarregue e confira novamente o CREF antes de decidir.');
            q('UPDATE {s}.team SET status=:status,reviewed_by=:user,reviewed_at=CURRENT_TIMESTAMP,review_note=:note,updated_at=CURRENT_TIMESTAMP,version=version+1 WHERE id_team=:id',{status=statuses[action],user=user.id,note=trim(note),id=id});
            if(action=='APPROVE'){
                q('UPDATE {s}.team SET cref_evidence=:evidence,cref_verified_at=CURRENT_TIMESTAMP WHERE id_team=:id',{evidence=trim(evidence),id=id});
                var referrals=q('UPDATE {s}.recruit_invite SET approved_team_id=:team WHERE lower(destination)=lower(:email) AND channel=''EMAIL'' AND approved_team_id IS NULL RETURNING requested_by',{team=id,email=team.email});
                for(var ref in referrals)notice(ref.requested_by,team.name & ' já está no Road Runners Teams. Acesse Teams para confirmar sua adesão.');
            }
            if(listFind('SUSPEND,ARCHIVE',action)){
                var removed=q("UPDATE {s}.membership SET ended_at=CURRENT_TIMESTAMP,end_reason=:reason,ended_by=:user WHERE team_id=:id AND ended_at IS NULL RETURNING user_id",{reason='TEAM_' & statuses[action],user=user.id,id=id});
                for(var row in removed)notice(row.user_id,'Seu vínculo com ' & team.name & ' foi encerrado pela plataforma. Você pode escolher outro Team.');
            }
            var owners=q('SELECT user_id FROM {s}.admin WHERE team_id=:id AND role=''OWNER''',{id=id});
            for(var owner in owners)notice(owner.user_id,'Cadastro de ' & team.name & ': ' & statuses[action] & '. ' & note);
            audit(user.id,id,'TEAM_' & action,0,trim(note) & (len(evidence)?' Evidência: ' & trim(evidence):''));
        }
    }
    public query function publicTeams(string search='',string uf='',string type='',numeric page=1) {
        var params={term='%' & left(trim(search),100) & '%',uf=uCase(left(uf,2)),type=uCase(left(type,20)),offset=(max(1,min(10000,int(page)))-1)*24};
        return q("SELECT id_team,slug,name,type,city,uf,attendance,description,count(*) OVER() total_count FROM {s}.team WHERE status='ACTIVE' AND (name ILIKE :term OR city ILIKE :term) AND (:uf='' OR uf=:uf) AND (:type='' OR type=:type) ORDER BY lower(name),id_team LIMIT 24 OFFSET :offset",params);
    }
    public struct function publicTeam(required string slug) {return first(q("SELECT id_team,slug,name,type,city,uf,attendance,description,website,technical_name,cref,cref_uf FROM {s}.team WHERE slug=:slug AND status='ACTIVE'",{slug=left(slug,200)}));}
    public struct function affiliation(required any userId) {return first(q("SELECT t.name,t.slug FROM {s}.membership m JOIN {s}.team t ON t.id_team=m.team_id WHERE m.user_id=:user AND m.ended_at IS NULL AND t.status='ACTIVE'",{user=ident(userId)}));}
    public struct function state(required any userId) {
        var user=actor(userId);var row=first(q("SELECT m.team_id,t.name,t.slug,m.started_at FROM {s}.membership m JOIN {s}.team t ON t.id_team=m.team_id WHERE m.user_id=:user AND m.ended_at IS NULL",{user=user.id}));
        var clock=first(q("SELECT to_char(next_change_at AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY HH24:MI') next_at,next_change_at>CURRENT_TIMESTAMP blocked FROM {s}.athlete_clock WHERE user_id=:user",{user=user.id}));
        var latest=first(q('SELECT end_reason FROM {s}.membership WHERE user_id=:user ORDER BY id_membership DESC LIMIT 1',{user=user.id}));
        var waived=!structIsEmpty(latest) && listFind('TEAM_SUSPENDED,TEAM_ARCHIVED',latest.end_reason)>0;
        return {teamId=structIsEmpty(row)?0:row.team_id,name=structIsEmpty(row)?'':row.name,slug=structIsEmpty(row)?'':row.slug,nextChangeAt=structIsEmpty(clock)?'':clock.next_at,blocked=!structIsEmpty(clock)&&clock.blocked&&!waived};
    }
    private void function lockAthlete(required numeric userId) {
        q('INSERT INTO {s}.athlete_clock(user_id) VALUES(:user) ON CONFLICT(user_id) DO NOTHING',{user=userId});
        q('SELECT user_id FROM {s}.athlete_clock WHERE user_id=:user FOR UPDATE',{user=userId});
    }
    public void function join(required any userId,required any teamId,required boolean consent) {
        var user=actor(userId);var id=ident(teamId);if(!consent)invalid('Confirme o vínculo e o compartilhamento dos dados esportivos.');
        transaction {
            lockAthlete(user.id);var team=first(q('SELECT id_team,status,name FROM {s}.team WHERE id_team=:id FOR UPDATE',{id=id}));
            if(structIsEmpty(team)||team.status!='ACTIVE')invalid('Este Team não está disponível para adesão.');
            var current=state(user.id);if(current.teamId==id)return;
            if(current.blocked)invalid('Sua próxima troca estará disponível em ' & current.nextChangeAt & ' (Brasília).');
            if(q('SELECT 1 FROM {s}.exclusion WHERE user_id=:user AND team_id=:team',{user=user.id,team=id}).recordCount)invalid('Solicite ao responsável do Team a liberação para retornar.');
            q("UPDATE {s}.membership SET ended_at=CURRENT_TIMESTAMP,end_reason='SWITCH',ended_by=:user WHERE user_id=:user AND ended_at IS NULL",{user=user.id});
            q('INSERT INTO {s}.membership(team_id,user_id) VALUES(:team,:user)',{team=id,user=user.id});
            q("UPDATE {s}.athlete_clock SET next_change_at=CURRENT_TIMESTAMP+interval '14 days' WHERE user_id=:user",{user=user.id});
            funnel(user.id,id,'JOIN');audit(user.id,id,'ATHLETE_JOIN',user.id);notice(user.id,'Você agora representa ' & team.name & '.');
        }
    }
    public void function recordReturn(required any userId) {
        var user=actor(userId);
        transaction {
            lockAthlete(user.id);var current=state(user.id);if(!current.teamId)return;
            if(!q("SELECT 1 FROM {s}.funnel WHERE user_id=:user AND team_id=:team AND event='RETURN' AND created_at>=date_trunc('day',CURRENT_TIMESTAMP)",{user=user.id,team=current.teamId}).recordCount)funnel(user.id,current.teamId,'RETURN');
        }
    }
    public void function leave(required any userId) {
        var user=actor(userId);
        transaction {
            lockAthlete(user.id);var current=state(user.id);if(current.teamId==0)return;
            q("UPDATE {s}.membership SET ended_at=CURRENT_TIMESTAMP,end_reason='LEFT',ended_by=:user WHERE user_id=:user AND ended_at IS NULL",{user=user.id});
            funnel(user.id,current.teamId,'LEAVE');audit(user.id,current.teamId,'ATHLETE_LEAVE',user.id);
        }
    }
    public void function removeAthlete(required any userId,required any teamId,required any athleteId) {
        var access=authority(userId,teamId,true);var athlete=ident(athleteId);
        transaction {
            lockAthlete(athlete);authority(userId,teamId,true);
            var removed=q("UPDATE {s}.membership SET ended_at=CURRENT_TIMESTAMP,end_reason='REMOVED',ended_by=:actor WHERE user_id=:athlete AND team_id=:team AND ended_at IS NULL RETURNING id_membership",{actor=userId,athlete=athlete,team=access.id_team});
            if(!removed.recordCount)invalid('Este atleta não está vinculado ao Team.');
            q('INSERT INTO {s}.exclusion(team_id,user_id,removed_by) VALUES(:team,:athlete,:actor) ON CONFLICT(team_id,user_id) DO UPDATE SET removed_by=EXCLUDED.removed_by,created_at=CURRENT_TIMESTAMP',{team=access.id_team,athlete=athlete,actor=userId});
            notice(athlete,'O responsável de ' & access.name & ' encerrou seu vínculo. O prazo anterior para troca continua valendo.');
            funnel(athlete,access.id_team,'REMOVED');audit(userId,access.id_team,'ATHLETE_REMOVE',athlete);
        }
    }
    public void function unblockAthlete(required any userId,required any teamId,required any athleteId) {var access=authority(userId,teamId,true);transaction {q('DELETE FROM {s}.exclusion WHERE team_id=:team AND user_id=:user',{team=access.id_team,user=ident(athleteId)});audit(userId,access.id_team,'ATHLETE_UNBLOCK',athleteId);}}
    public struct function globalTeams(required any userId,string search='',string status='',string type='',string uf='',numeric page=1) {
        var user=actor(userId);if(!user.is_admin)forbidden();
        var filters={term='%' & left(trim(search),100) & '%',status=uCase(trim(status)),type=uCase(trim(type)),uf=uCase(trim(uf))};
        if(len(filters.status)&&!listFind('PENDING,ACTIVE,CHANGES,REJECTED,SUSPENDED,ARCHIVED',filters.status))invalid('Situação inválida.');
        if(len(filters.type)&&!listFind('TREINADOR,ASSESSORIA,CLUBE,ACADEMIA,GRUPO,EMPRESA',filters.type))invalid('Tipo de Team inválido.');
        if(len(filters.uf)&&!listFind('AC,AL,AP,AM,BA,CE,DF,ES,GO,MA,MT,MS,MG,PA,PB,PR,PE,PI,RJ,RN,RS,RO,RR,SC,SP,SE,TO',filters.uf))invalid('UF inválida.');
        var whereSql=" WHERE (t.name ILIKE :term OR t.city ILIKE :term) AND (:status='' OR t.status=:status) AND (:type='' OR t.type=:type) AND (:uf='' OR t.uf=:uf)";
        var total=q('SELECT count(*) n FROM {s}.team t' & whereSql,filters).n[1];var pages=max(1,ceiling(total/25));var currentPage=min(pages,max(1,int(page)));
        filters.offset=(currentPage-1)*25;
        var teams=q("SELECT t.*,(SELECT count(*) FROM {s}.membership m WHERE m.team_id=t.id_team AND m.ended_at IS NULL) athletes FROM {s}.team t" & whereSql & " ORDER BY CASE t.status WHEN 'PENDING' THEN 0 WHEN 'CHANGES' THEN 1 ELSE 2 END,t.created_at DESC,t.id_team DESC LIMIT 25 OFFSET :offset",filters);
        var stats=first(q("SELECT count(*) total,count(*) FILTER(WHERE status='ACTIVE') active,count(*) FILTER(WHERE status='PENDING') pending,count(*) FILTER(WHERE status='CHANGES') changes,count(*) FILTER(WHERE status='SUSPENDED') suspended,(SELECT count(*) FROM {s}.membership WHERE ended_at IS NULL) athletes FROM {s}.team"));
        return {teams=teams,stats=stats,total=total,page=currentPage,pages=pages};
    }
    public query function ownedTeams(required any userId,string search='',numeric page=1) {
        var user=actor(userId);
        return q("SELECT t.*,a.role,count(*) OVER() total_count FROM {s}.team t JOIN {s}.admin a ON a.team_id=t.id_team AND a.user_id=:user WHERE (t.name ILIKE :term OR t.city ILIKE :term) ORDER BY CASE WHEN t.status='PENDING' THEN 0 ELSE 1 END,t.created_at DESC,t.id_team DESC LIMIT 24 OFFSET :offset",{user=user.id,term='%' & left(trim(search),100) & '%',offset=(max(1,min(10000,int(page)))-1)*24});
    }
    public query function myTeams(required any userId,string search='',numeric page=1) {
        var user=actor(userId);var sql='SELECT t.*,a.role,count(*) OVER() total_count FROM {s}.team t LEFT JOIN {s}.admin a ON a.team_id=t.id_team AND a.user_id=:user WHERE (t.name ILIKE :term OR t.city ILIKE :term)';
        if(!user.is_admin)sql&=' AND a.user_id=:user';return q(sql & ' ORDER BY CASE WHEN t.status=''PENDING'' THEN 0 ELSE 1 END,t.created_at DESC LIMIT 24 OFFSET :offset',{user=user.id,term='%' & left(trim(search),100) & '%',offset=(max(1,min(10000,int(page)))-1)*24});
    }
    public struct function workspace(required any userId,required any teamId,string search='',numeric page=1) {
        var access=authority(userId,teamId);var params={team=access.id_team,term='%' & left(trim(search),100) & '%',offset=(max(1,min(10000,int(page)))-1)*25};
        var athletes=q("SELECT m.user_id,u.name,m.started_at,to_char(m.started_at AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY') joined_on,p.tag,count(*) OVER() total_count FROM {s}.membership m JOIN public.tb_usuarios u ON u.id=m.user_id LEFT JOIN LATERAL (SELECT tag FROM public.tb_paginas WHERE id_usuario_cadastro=u.id ORDER BY id_pagina LIMIT 1) p ON true WHERE m.team_id=:team AND m.ended_at IS NULL AND u.name ILIKE :term ORDER BY lower(u.name),m.user_id LIMIT 25 OFFSET :offset",params);
        var results=queryNew('user_id,name,id_evento,nome_evento,tag,data_final,percurso,tempo_total,pace');
        if(access.status=='ACTIVE')results=q("SELECT m.user_id,u.name,e.id_evento,e.nome_evento,e.tag,e.data_final,r.percurso,r.tempo_total,r.pace FROM {s}.membership m JOIN public.tb_usuarios u ON u.id=m.user_id JOIN public.tb_resultados r ON r.id_usuario=m.user_id JOIN public.tb_evento_corridas e ON e.id_evento=r.id_evento WHERE m.team_id=:team AND m.ended_at IS NULL AND r.status_final<3 AND u.name ILIKE :term ORDER BY e.data_final DESC,r.id_resultado DESC LIMIT 25 OFFSET :offset",params);
        var stats=first(q("SELECT (SELECT count(*) FROM {s}.membership WHERE team_id=:team AND ended_at IS NULL) athletes,(SELECT count(*) FROM {s}.membership WHERE team_id=:team AND started_at>CURRENT_TIMESTAMP-interval '30 days') joins,(SELECT count(*) FROM {s}.membership WHERE team_id=:team AND ended_at>CURRENT_TIMESTAMP-interval '30 days') exits,(SELECT count(*) FROM {s}.recruit_invite WHERE approved_team_id=:team) referrals",{team=access.id_team}));
        var acquisition=first(q("WITH acquired AS (SELECT f.user_id,f.created_at,u.fonte_lead FROM {s}.funnel f JOIN public.tb_usuarios u ON u.id=f.user_id WHERE f.team_id=:team AND f.event='JOIN' AND NOT EXISTS(SELECT 1 FROM {s}.funnel older WHERE older.user_id=f.user_id AND older.event='JOIN' AND older.id_event<f.id_event)) SELECT count(*) FILTER(WHERE fonte_lead='rr_teams') new_users,count(*) FILTER(WHERE fonte_lead IS DISTINCT FROM 'rr_teams') existing_users,count(*) FILTER(WHERE acquired.created_at<=CURRENT_TIMESTAMP-interval '30 days') retention_eligible,count(*) FILTER(WHERE acquired.created_at<=CURRENT_TIMESTAMP-interval '30 days' AND EXISTS(SELECT 1 FROM {s}.funnel ret WHERE ret.user_id=acquired.user_id AND ret.team_id=:team AND ret.event='RETURN' AND ret.created_at>=acquired.created_at+interval '30 days')) retained_users FROM acquired",{team=access.id_team}));
        structAppend(stats,acquisition,true);
        return {team=access,role=access.role,adminPolicy=adminPolicy(access.role),athletes=athletes,results=results,stats=stats,
            admins=q('SELECT a.user_id,u.name,u.email,a.role FROM {s}.admin a JOIN public.tb_usuarios u ON u.id=a.user_id WHERE team_id=:team ORDER BY a.role,u.name',{team=access.id_team}),
            invites=q('SELECT id_invite,email,role,expires_at,accepted_at,revoked_at FROM {s}.admin_invite WHERE team_id=:team ORDER BY id_invite DESC LIMIT 30',{team=access.id_team}),
            exclusions=q('SELECT e.user_id,u.name FROM {s}.exclusion e JOIN public.tb_usuarios u ON u.id=e.user_id WHERE team_id=:team ORDER BY e.created_at DESC LIMIT 50',{team=access.id_team}),
            audit=q('SELECT event,created_at,detail FROM {s}.audit WHERE team_id=:team ORDER BY id_audit DESC LIMIT 30',{team=access.id_team})};
    }
    public query function adminCandidates(required any userId,required any teamId,string search='') {
        var access=authority(userId,teamId,true);
        var term=left(trim(search),100);var idSearch=reFind('^[1-9][0-9]{0,14}$',term)>0;
        if(len(term)<2&&!idSearch)return queryNew('id,name,email');
        return q("SELECT u.id,u.name,u.email FROM public.tb_usuarios u WHERE NOT EXISTS(SELECT 1 FROM public.tb_usuarios_gestao g WHERE g.id_usuario=u.id AND (NOT coalesce(g.ativo,true) OR coalesce(g.excluido,false))) AND NOT EXISTS(SELECT 1 FROM {s}.admin a WHERE a.team_id=:team AND a.user_id=u.id) AND (u.id=:subjectId OR u.name ILIKE :term OR u.email ILIKE :term) ORDER BY CASE WHEN u.id=:subjectId THEN 0 ELSE 1 END,lower(u.name),u.id LIMIT 25",{team=access.id_team,subjectId=idSearch?val(term):0,term='%' & term & '%'});
    }
    public void function addExistingAdmin(required any userId,required any teamId,required any memberId,required string role) {
        var user=actor(userId);var id=ident(teamId);var member=ident(memberId);var selected=uCase(trim(role));
        if(!listFind('OWNER,ADMIN,VIEWER',selected))invalid('Selecione um papel válido para o Team.');
        transaction {
            q('SELECT id_team FROM {s}.team WHERE id_team=:team FOR UPDATE',{team=id});
            var access=authority(user.id,id,true);checkAdminGrant(access,selected);var person=actor(member);checkPendingAdminGrant(access,person.email);
            if(q('SELECT 1 FROM {s}.admin WHERE team_id=:team AND user_id=:user',{team=id,user=person.id}).recordCount)invalid('Este usuário já faz parte da equipe administrativa.');
            if(len(person.email))q('UPDATE {s}.admin_invite SET revoked_at=CURRENT_TIMESTAMP WHERE team_id=:team AND lower(email)=lower(:email) AND accepted_at IS NULL AND revoked_at IS NULL',{team=id,email=person.email});
            q('INSERT INTO {s}.admin(team_id,user_id,role) VALUES(:team,:user,:role)',{team=id,user=person.id,role=selected});
            audit(user.id,id,'ADMIN_ADD',person.id,'Papel atribuído: ' & (selected=='OWNER'?'Titular':(selected=='ADMIN'?'Administrador':'Consulta')));
        }
    }
    public void function changeAdminRole(required any userId,required any teamId,required any memberId,required string role,required string expectedRole) {
        var user=actor(userId);var id=ident(teamId);var member=ident(memberId);var selected=uCase(trim(role));var expected=uCase(trim(expectedRole));
        if(!listFind('OWNER,ADMIN,VIEWER',selected)||!listFind('OWNER,ADMIN,VIEWER',expected))invalid('Selecione um papel válido para o Team.');
        transaction {
            q('SELECT id_team FROM {s}.team WHERE id_team=:id FOR UPDATE',{id=id});
            var access=authority(user.id,id,true,true);checkAdminGrant(access,selected);
            var person=first(q('SELECT a.role,u.email FROM {s}.admin a JOIN public.tb_usuarios u ON u.id=a.user_id WHERE a.team_id=:team AND a.user_id=:user',{team=id,user=member}));
            if(structIsEmpty(person))invalid('Este usuário não faz parte da equipe administrativa.');
            if(access.role!='GLOBAL'&&person.role=='OWNER')forbidden();
            if(person.role!=expected)invalid('O papel foi alterado por outra pessoa. Recarregue a página antes de salvar.');
            if(person.role==selected)return;
            if(person.role=='OWNER'&&q("SELECT count(*) n FROM {s}.admin WHERE team_id=:team AND role='OWNER'",{team=id}).n[1]<=1)invalid('O último titular não pode ser rebaixado. Adicione outro titular antes de alterar este papel.');
            if(len(person.email))q('UPDATE {s}.admin_invite SET revoked_at=CURRENT_TIMESTAMP WHERE team_id=:team AND lower(email)=lower(:email) AND accepted_at IS NULL AND revoked_at IS NULL',{team=id,email=person.email});
            var changed=q('UPDATE {s}.admin SET role=:role WHERE team_id=:team AND user_id=:user AND role=:expected RETURNING user_id',{role=selected,team=id,user=member,expected=expected});
            if(!changed.recordCount)invalid('O papel foi alterado por outra pessoa. Recarregue a página antes de salvar.');
            var labels={OWNER='Titular',ADMIN='Administrador',VIEWER='Consulta'};
            audit(user.id,id,'ADMIN_ROLE_CHANGE',member,'Papel alterado de ' & labels[person.role] & ' para ' & labels[selected] & '.');
        }
    }
    public struct function inviteAdmin(required any userId,required any teamId,required string email,required string role) {
        var access=authority(userId,teamId,true);var recipient=lCase(trim(email));var selected=uCase(role);
        if(!isValid('email',recipient)||len(recipient)>255||reFind('[\r\n]',recipient))invalid('Email inválido.');if(!listFind('ADMIN,VIEWER',selected))invalid('Papel inválido.');
        checkAdminGrant(access,selected);
        var token=lCase(hash(generateSecretKey('AES',256),'SHA-256')) & lCase(hash(generateSecretKey('AES',256),'SHA-256'));
        transaction {
            q('SELECT id_team FROM {s}.team WHERE id_team=:id FOR UPDATE',{id=access.id_team});access=authority(userId,teamId,true);checkAdminGrant(access,selected);
            if(q('SELECT 1 FROM {s}.admin a JOIN public.tb_usuarios u ON u.id=a.user_id WHERE a.team_id=:team AND lower(u.email)=lower(:email)',{team=access.id_team,email=recipient}).recordCount)invalid('Esta pessoa já faz parte da equipe. Use a alteração de papel para ajustar o acesso.');
            checkPendingAdminGrant(access,recipient);
            if(q("SELECT count(*) n FROM {s}.admin_invite WHERE team_id=:team AND created_at>CURRENT_TIMESTAMP-interval '1 day'",{team=access.id_team}).n[1]>=20)invalid('Limite diário de convites atingido.');
            q('UPDATE {s}.admin_invite SET revoked_at=CURRENT_TIMESTAMP WHERE team_id=:team AND email=:email AND accepted_at IS NULL AND revoked_at IS NULL',{team=access.id_team,email=recipient});
            q('INSERT INTO {s}.admin_invite(team_id,email,role,token_hash,created_by) VALUES(:team,:email,:role,:token,:user)',{team=access.id_team,email=recipient,role=selected,token=lCase(hash(token,'SHA-256')),user=userId});audit(userId,access.id_team,'ADMIN_INVITE');
            var link='https://business.roadrunners.run/teams/convites/?token=' & token;
            queueMail(recipient,recipient,'Convite para administrar ' & left(access.name,130),'<p>Você recebeu um convite para a equipe administrativa de <strong>' & encodeForHTML(access.name) & '</strong>.</p><p><a href="' & encodeForHTMLAttribute(link) & '">Revisar e aceitar convite</a></p><p>Use este mesmo email para entrar. O convite expira em sete dias e não filia seu perfil de atleta ao Team.</p>');
        }return {token=token,email=recipient,teamName=access.name};
    }
    public void function acceptAdmin(required any userId,required string token) {
        var user=actor(userId);if(!reFind('^[a-f0-9]{128}$',token))invalid('Convite inválido ou expirado.');
        transaction {
            // Team -> invitation -> admin: same order as direct grants and invitation creation.
            var reference=first(q('SELECT team_id FROM {s}.admin_invite WHERE token_hash=:hash',{hash=lCase(hash(token,'SHA-256'))}));
            if(structIsEmpty(reference))invalid('Convite inválido ou expirado.');
            var team=first(q('SELECT status FROM {s}.team WHERE id_team=:id FOR UPDATE',{id=reference.team_id}));
            var invite=first(q('SELECT * FROM {s}.admin_invite WHERE token_hash=:hash FOR UPDATE',{hash=lCase(hash(token,'SHA-256'))}));
            if(structIsEmpty(invite)||len(invite.accepted_at & '')||len(invite.revoked_at & '')||dateCompare(invite.expires_at,now())<=0||compareNoCase(invite.email,user.email)!=0)invalid('Convite inválido, expirado ou destinado a outro email.');
            if(structIsEmpty(team)||invite.team_id!=reference.team_id||!listFind('ACTIVE,PENDING,CHANGES',team.status))invalid('O Team está indisponível.');
            q('INSERT INTO {s}.admin(team_id,user_id,role) VALUES(:team,:user,:role) ON CONFLICT(team_id,user_id) DO UPDATE SET role=CASE WHEN {s}.admin.role=''OWNER'' THEN ''OWNER'' ELSE EXCLUDED.role END',{team=invite.team_id,user=user.id,role=invite.role});
            q('UPDATE {s}.admin_invite SET accepted_by=:user,accepted_at=CURRENT_TIMESTAMP WHERE id_invite=:id',{user=user.id,id=invite.id_invite});audit(user.id,invite.team_id,'ADMIN_ACCEPT');funnel(user.id,invite.team_id,'ADMIN_ACCEPT');
        }
    }
    public void function revokeInvite(required any userId,required any teamId,required any inviteId) {
        var id=ident(teamId);var invite=ident(inviteId);
        transaction {
            q('SELECT id_team FROM {s}.team WHERE id_team=:id FOR UPDATE',{id=id});var access=authority(userId,id,true);
            var target=first(q('SELECT role FROM {s}.admin_invite WHERE id_invite=:id AND team_id=:team',{id=invite,team=id}));if(structIsEmpty(target))forbidden();checkAdminGrant(access,target.role);
            var revoked=q('UPDATE {s}.admin_invite SET revoked_at=CURRENT_TIMESTAMP WHERE id_invite=:id AND team_id=:team AND accepted_at IS NULL AND revoked_at IS NULL RETURNING id_invite',{id=invite,team=id});
            if(revoked.recordCount)audit(userId,id,'ADMIN_INVITE_REVOKE');
        }
    }
    public void function removeAdmin(required any userId,required any teamId,required any memberId) {
        var access=authority(userId,teamId,true,true);var member=ident(memberId);
        transaction {
            q('SELECT id_team FROM {s}.team WHERE id_team=:team FOR UPDATE',{team=access.id_team});access=authority(userId,teamId,true,true);
            var target=first(q('SELECT role FROM {s}.admin WHERE team_id=:team AND user_id=:user',{team=access.id_team,user=member}));if(structIsEmpty(target))forbidden();if(access.role!='GLOBAL'&&target.role=='OWNER')forbidden();
            if(target.role=='OWNER' && q('SELECT count(*) n FROM {s}.admin WHERE team_id=:team AND role=''OWNER''',{team=access.id_team}).n[1]<=1)invalid('O último titular não pode ser removido.');
            q('DELETE FROM {s}.admin WHERE team_id=:team AND user_id=:user',{team=access.id_team,user=member});audit(userId,access.id_team,'ADMIN_REMOVE',member);
        }
    }
    public struct function recruit(required any userId,required string teamName,required string channel,required string destination) {
        var user=actor(userId);var name=trim(teamName);var method=uCase(channel);var to=trim(destination);
        if(!len(name)||len(name)>160||!listFind('EMAIL,WHATSAPP',method))invalid('Informe o nome do Team e o canal do convite.');
        if(method=='EMAIL'){to=lCase(to);if(!isValid('email',to)||len(to)>255||reFind('[\r\n]',to))invalid('Informe um email válido.');}
        else {to=reReplace(to,'[^0-9]','','all');if(len(to)==10||len(to)==11)to='55' & to;if(!reFind('^[0-9]{12,13}$',to))invalid('Informe WhatsApp com DDD.');}
        transaction {
            q('SELECT id FROM public.tb_usuarios WHERE id=:id FOR UPDATE',{id=user.id});
            q('SELECT pg_advisory_xact_lock(hashtextextended(:key,0))',{key=variables.schema & ':recruit:' & to});
            if(q("SELECT count(*) n FROM {s}.recruit_invite WHERE requested_by=:user AND created_at>CURRENT_TIMESTAMP-interval '1 day'",{user=user.id}).n[1]>=5)invalid('Você pode enviar até cinco convites por dia.');
            if(q("SELECT 1 FROM {s}.recruit_invite WHERE destination=:to AND created_at>CURRENT_TIMESTAMP-interval '7 days'",{to=to}).recordCount)invalid('Este contato já recebeu um convite nos últimos sete dias.');
            var invite=q('INSERT INTO {s}.recruit_invite(requested_by,team_name,channel,destination) VALUES(:user,:name,:channel,:to) RETURNING id_invite',{user=user.id,name=name,channel=method,to=to}).id_invite[1];
            funnel(user.id,0,'INVITE');audit(user.id,0,'RECRUIT_INVITE');
            if(method=='EMAIL')queueMail(to,name,'Seu grupo no Road Runners Teams','<p>' & encodeForHTML(user.name) & ' convidou ' & encodeForHTML(name) & ' para o Road Runners Teams.</p><p>Cadastre seu Team para reunir atletas e acompanhar os resultados de provas no RR. O cadastro exige responsável técnico com CREF ativo e análise da plataforma.</p><p><a href="https://business.roadrunners.run/teams/cadastro/">Conhecer e cadastrar o Team</a></p><p>Este convite foi solicitado por um usuário do RR. Ele não cria uma conta nem vincula atletas automaticamente.</p>');
        }return {id=invite,channel=method,destination=to,sender=user.name,teamName=name};
    }
    public query function notices(required any userId) {actor(userId);return q('SELECT id_notice,message,created_at FROM {s}.notice WHERE user_id=:user ORDER BY id_notice DESC LIMIT 10',{user=userId});}
}
