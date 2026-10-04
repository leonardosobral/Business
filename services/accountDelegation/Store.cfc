component output=false {
    public any function init(required string datasource) {
        if (!len(trim(arguments.datasource))) throw(type="BusinessDelegationDatasource",message="An explicit datasource is required");
        variables.datasource=arguments.datasource;
        return this;
    }

    public boolean function schemaReady() {
        try {
            var objects=queryExecute("SELECT count(*) AS present FROM information_schema.tables
                WHERE table_schema='public' AND table_name IN (
                'tb_business_delegacao_schema','tb_conta_gestoras','tb_conta_gestao_vinculos',
                'tb_conta_gestao_permissoes','tb_conta_gestao_equipe','tb_conta_gestao_equipe_permissoes',
                'tb_conta_gestao_convites','tb_conta_gestao_auditoria')",{}, {datasource=variables.datasource,timeout=5});
            if (objects.present[1]!=8) return false;
            var version=queryExecute("SELECT version FROM public.tb_business_delegacao_schema WHERE version=:version",
                {version={value=1,cfsqltype="cf_sql_bigint"}}, {datasource=variables.datasource,timeout=5});
            if (!version.recordCount) return false;
            var columns=queryExecute("SELECT count(*) AS present FROM information_schema.columns
                WHERE table_schema='public' AND table_name='tb_conta_cadastro_solicitacoes'
                AND column_name IN('origem_gestora_id','gestao_vinculo_id')",{}, {datasource=variables.datasource,timeout=5});
            var functions=queryExecute("SELECT to_regprocedure('public.business_delegation_capabilities_valid(jsonb)') IS NOT NULL
                AND to_regprocedure('public.business_delegation_team_scope()') IS NOT NULL
                AND to_regprocedure('public.business_delegation_grant_catalog()') IS NOT NULL AS present",{}, {datasource=variables.datasource,timeout=5});
            var indexes=queryExecute("SELECT count(*) AS present FROM pg_catalog.pg_indexes WHERE schemaname='public'
                AND indexname IN('uq_business_delegation_owner_pending','ix_business_delegation_client',
                'ix_business_delegation_manager_pending','ix_business_delegation_member','ix_business_delegation_invitee',
                'ix_business_delegation_invite_relation','ix_business_delegation_audit_relation','ix_business_delegation_registration')",
                {}, {datasource=variables.datasource,timeout=5});
            var triggers=queryExecute("SELECT count(*) AS present FROM pg_catalog.pg_trigger t
                WHERE NOT t.tgisinternal AND t.tgenabled='O' AND t.tgtype=23 AND (
                (t.tgname='business_delegation_team_scope' AND t.tgrelid=CAST('public.tb_conta_gestao_equipe' AS regclass)
                  AND t.tgfoid=CAST('public.business_delegation_team_scope()' AS regprocedure)
                  AND t.tgattr[0]=(SELECT attnum FROM pg_attribute WHERE attrelid=t.tgrelid AND attname='id_vinculo')
                  AND t.tgattr[1]=(SELECT attnum FROM pg_attribute WHERE attrelid=t.tgrelid AND attname='id_conta_usuario'))
                OR (t.tgname='business_delegation_grant_catalog' AND t.tgrelid=CAST('public.tb_conta_gestao_permissoes' AS regclass)
                  AND t.tgfoid=CAST('public.business_delegation_grant_catalog()' AS regprocedure)
                  AND t.tgattr[0]=(SELECT attnum FROM pg_attribute WHERE attrelid=t.tgrelid AND attname='id_permissao')))",
                {}, {datasource=variables.datasource,timeout=5});
            var ownerIndex=queryExecute("SELECT EXISTS(SELECT 1 FROM pg_catalog.pg_index i
                JOIN pg_class idx ON idx.oid=i.indexrelid JOIN pg_namespace ns ON ns.oid=idx.relnamespace
                WHERE ns.nspname='public' AND idx.relname='uq_business_delegation_owner_pending'
                  AND i.indrelid=CAST('public.tb_conta_gestao_convites' AS regclass)
                  AND i.indisunique AND i.indisvalid AND i.indisready AND i.indnkeyatts=2 AND i.indnatts=2
                  AND i.indkey[0]=(SELECT attnum FROM pg_attribute WHERE attrelid=i.indrelid AND attname='id_conta')
                  AND i.indkey[1]=(SELECT attnum FROM pg_attribute WHERE attrelid=i.indrelid AND attname='tipo')
                  AND pg_get_expr(i.indpred,i.indrelid)=:predicate) AS present",
                {predicate={value="((tipo = 'TITULAR'::text) AND (status = 'PENDENTE'::text))",cfsqltype="cf_sql_varchar"}}, {datasource=variables.datasource,timeout=5});
            var containment=queryExecute("SELECT count(*) AS present FROM pg_catalog.pg_constraint c
                WHERE c.contype='f' AND c.convalidated AND c.confdeltype='c'
                  AND c.conrelid=CAST('public.tb_conta_gestao_equipe_permissoes' AS regclass) AND (
                (c.confrelid=CAST('public.tb_conta_gestao_equipe' AS regclass)
                  AND c.conkey=CAST(ARRAY[(SELECT attnum FROM pg_attribute WHERE attrelid=c.conrelid AND attname='id_equipe'),(SELECT attnum FROM pg_attribute WHERE attrelid=c.conrelid AND attname='id_vinculo')] AS smallint[])
                  AND c.confkey=CAST(ARRAY[(SELECT attnum FROM pg_attribute WHERE attrelid=c.confrelid AND attname='id_equipe'),(SELECT attnum FROM pg_attribute WHERE attrelid=c.confrelid AND attname='id_vinculo')] AS smallint[]))
                OR (c.confrelid=CAST('public.tb_conta_gestao_permissoes' AS regclass)
                  AND c.conkey=CAST(ARRAY[(SELECT attnum FROM pg_attribute WHERE attrelid=c.conrelid AND attname='id_vinculo'),(SELECT attnum FROM pg_attribute WHERE attrelid=c.conrelid AND attname='id_permissao')] AS smallint[])
                  AND c.confkey=CAST(ARRAY[(SELECT attnum FROM pg_attribute WHERE attrelid=c.confrelid AND attname='id_vinculo'),(SELECT attnum FROM pg_attribute WHERE attrelid=c.confrelid AND attname='id_permissao')] AS smallint[])))",
                {}, {datasource=variables.datasource,timeout=5});
            var membershipLink=queryExecute("SELECT EXISTS(SELECT 1 FROM pg_catalog.pg_constraint c
                WHERE c.contype='f' AND c.convalidated AND c.confdeltype='c'
                  AND c.conrelid=CAST('public.tb_conta_gestao_equipe' AS regclass)
                  AND c.confrelid=CAST('public.tb_conta_usuarios' AS regclass)
                  AND c.conkey=CAST(ARRAY[(SELECT attnum FROM pg_attribute WHERE attrelid=c.conrelid AND attname='id_conta_usuario')] AS smallint[])
                  AND c.confkey=CAST(ARRAY[(SELECT attnum FROM pg_attribute WHERE attrelid=c.confrelid AND attname='id_conta_usuario')] AS smallint[])) AS present",
                {}, {datasource=variables.datasource,timeout=5});
            return columns.present[1]==2 && functions.present[1] && indexes.present[1]==8
                && triggers.present[1]==2 && ownerIndex.present[1] && containment.present[1]==2 && membershipLink.present[1];
        } catch (any unavailable) {
            // Deployment may precede migration. A partially installed schema never grants access.
            return false;
        }
    }
    public query function execute(required string sql, struct params={}) {
        return queryExecute(arguments.sql,arguments.params,{datasource=variables.datasource,timeout=15});
    }
    private struct function idParam(required any id) { return {value=id,cfsqltype='cf_sql_bigint'}; }
    public boolean function userStatusReady() {
        return execute("SELECT to_regclass('public.tb_usuarios_gestao') IS NOT NULL AS present").present[1];
    }
    public struct function actor(required any id) {
        var sql="SELECT u.id,coalesce(u.is_admin,false) AS is_admin,coalesce(u.is_dev,false) AS is_dev FROM tb_usuarios u ";
        if(userStatusReady()) sql &= "LEFT JOIN tb_usuarios_gestao g ON g.id_usuario=u.id ";
        sql &= "WHERE u.id=:id ";
        if(userStatusReady()) sql &= "AND coalesce(g.ativo,true)=true AND coalesce(g.excluido,false)=false";
        return first(execute(sql,{id=idParam(id)}));
    }
    public struct function account(required any id) { return first(execute('SELECT id_conta,nome_conta,status FROM tb_contas WHERE id_conta=:id',{id=idParam(id)})); }
    public struct function membership(required any actorId,required any accountId) {
        return first(execute('SELECT id_conta_usuario,papel,status FROM tb_conta_usuarios WHERE id_usuario=:actor AND id_conta=:account',
            {actor=idParam(actorId),account=idParam(accountId)}));
    }
    public struct function manager(required any id) { return first(execute('SELECT id_conta,habilitada,version FROM tb_conta_gestoras WHERE id_conta=:id',{id=idParam(id)})); }
    public struct function relationship(required any id) { return first(execute('SELECT id_vinculo,id_conta_gestora,id_conta_cliente,status,version FROM tb_conta_gestao_vinculos WHERE id_vinculo=:id',{id=idParam(id)})); }
    public struct function assignment(required any relationshipId,required any membershipId) {
        return first(execute('SELECT id_equipe,status,version FROM tb_conta_gestao_equipe WHERE id_vinculo=:rel AND id_conta_usuario=:member',
            {rel=idParam(relationshipId),member=idParam(membershipId)}));
    }
    public array function grants(required any relationshipId,any assignmentId=0) {
        var sql='SELECT p.codigo FROM tb_business_permissoes p JOIN tb_conta_gestao_permissoes g ON g.id_permissao=p.id_permissao ';
        var params={rel=idParam(relationshipId)};
        if(assignmentId!=0) {sql &= 'JOIN tb_conta_gestao_equipe_permissoes e ON e.id_vinculo=g.id_vinculo AND e.id_permissao=g.id_permissao AND e.id_equipe=:assignment ';params.assignment=idParam(assignmentId);}
        return codes(execute(sql & 'WHERE g.id_vinculo=:rel AND p.ativo=true ORDER BY p.codigo',params));
    }
    public array function directGrants(required any accountId, required string role) {
        if(!execute("SELECT to_regclass('public.tb_conta_permissoes') IS NOT NULL AS present").present[1]) return [];
        return codes(execute("SELECT DISTINCT p.codigo FROM tb_business_permissoes p JOIN tb_conta_permissoes g ON g.id_permissao=p.id_permissao
            WHERE g.id_conta=:account AND g.ativo=true AND p.ativo=true
            AND (CAST(g.papel AS text)=:role OR (:role='OWNER' AND CAST(g.papel AS text)='ADMIN')) ORDER BY p.codigo",
            {account=idParam(accountId),role={value=role,cfsqltype='cf_sql_varchar'}}));
    }
    public array function selections(required any actorId, required boolean delegated,required boolean internal) {
        var result=[];
        var direct=execute("SELECT c.id_conta,c.nome_conta,m.papel FROM tb_contas c JOIN tb_conta_usuarios m ON m.id_conta=c.id_conta WHERE m.id_usuario=:actor AND m.status='ATIVO' AND c.status='ATIVA' ORDER BY c.nome_conta,c.id_conta",{actor=idParam(actorId)});
        for(var row in direct) arrayAppend(result,{selection={accountId=row.id_conta,accessMode='DIRECT',managerAccountId=0,relationshipId=0},accountName=row.nome_conta,managerName='',roleLabel=row.papel});
        if(delegated) {
            var options=execute("SELECT c.id_conta,c.nome_conta,g.id_conta AS manager_id,g.nome_conta AS manager_name,v.id_vinculo,m.papel
                FROM tb_conta_gestao_vinculos v JOIN tb_contas c ON c.id_conta=v.id_conta_cliente JOIN tb_contas g ON g.id_conta=v.id_conta_gestora
                JOIN tb_conta_gestoras config ON config.id_conta=g.id_conta
                JOIN tb_conta_usuarios m ON m.id_conta=g.id_conta JOIN tb_conta_gestao_equipe e ON e.id_vinculo=v.id_vinculo AND e.id_conta_usuario=m.id_conta_usuario
                WHERE m.id_usuario=:actor AND m.status='ATIVO' AND CAST(m.papel AS text) IN('OWNER','ADMIN','OPERADOR','VISUALIZADOR')
                AND config.habilitada=true AND c.status='ATIVA' AND g.status='ATIVA' AND v.status='ATIVO' AND e.status='ATIVO'
                ORDER BY c.nome_conta,c.id_conta,g.nome_conta,g.id_conta,v.id_vinculo",{actor=idParam(actorId)});
            for(var row in options) arrayAppend(result,{selection={accountId=row.id_conta,accessMode='DELEGATED',managerAccountId=row.manager_id,relationshipId=row.id_vinculo},accountName=row.nome_conta,managerName=row.manager_name,roleLabel=row.papel});
        }
        if(internal) for(var row in execute("SELECT id_conta,nome_conta FROM tb_contas WHERE status='ATIVA' ORDER BY nome_conta,id_conta")) arrayAppend(result,{selection={accountId=row.id_conta,accessMode='INTERNAL_SIMULATION',managerAccountId=0,relationshipId=0},accountName=row.nome_conta,managerName='',roleLabel='Simulação interna'});
        return result;
    }
    // Caller MUST own a transaction on this Store's datasource. Shared lifecycle order:
    // accounts ASC -> actors ASC -> actor status -> all memberships ASC -> manager configs ASC
    // -> relationships ASC -> assignments ASC -> catalog/grants. Account rows serialize insert/delete too.
    // Pass every account and actor touched by a command in one call, before any mutation or network I/O.
    public void function lockScope(required array accountIds,required array actorIds) {
        var policy=createObject('component','services.accountDelegation.Policy');
        var accounts=[];var actors=[];
        for(var id in accountIds) arrayAppend(accounts,policy.identifier(id));
        for(var id in actorIds) arrayAppend(actors,policy.identifier(id));
        if(!arrayLen(accounts) || !arrayLen(actors)) policy.fail('Validation','Lock scope requires accounts and actors');
        var params={accounts={value=arrayToList(accounts),list=true,cfsqltype='cf_sql_bigint'},actors={value=arrayToList(actors),list=true,cfsqltype='cf_sql_bigint'}};
        execute('SELECT id_conta FROM tb_contas WHERE id_conta IN(:accounts) ORDER BY id_conta FOR UPDATE',params);
        execute('SELECT id FROM tb_usuarios WHERE id IN(:actors) ORDER BY id FOR UPDATE',params);
        if(userStatusReady()) execute('SELECT id_usuario FROM tb_usuarios_gestao WHERE id_usuario IN(:actors) ORDER BY id_usuario FOR UPDATE',params);
        execute('SELECT id_conta_usuario FROM tb_conta_usuarios WHERE id_conta IN(:accounts) ORDER BY id_conta,id_conta_usuario FOR UPDATE',params);
        if(execute("SELECT to_regclass('public.tb_conta_gestoras') IS NOT NULL AS present").present[1]) {
            execute('SELECT id_conta FROM tb_conta_gestoras WHERE id_conta IN(:accounts) ORDER BY id_conta FOR UPDATE',params);
            execute('SELECT id_vinculo FROM tb_conta_gestao_vinculos WHERE id_conta_gestora IN(:accounts) OR id_conta_cliente IN(:accounts) ORDER BY id_vinculo FOR UPDATE',params);
            execute('SELECT e.id_equipe FROM tb_conta_gestao_equipe e JOIN tb_conta_gestao_vinculos v ON v.id_vinculo=e.id_vinculo WHERE v.id_conta_gestora IN(:accounts) OR v.id_conta_cliente IN(:accounts) ORDER BY e.id_equipe FOR UPDATE OF e',params);
            execute('SELECT p.id_permissao FROM tb_business_permissoes p ORDER BY p.id_permissao FOR SHARE');
            execute('SELECT g.id_vinculo,g.id_permissao FROM tb_conta_gestao_permissoes g JOIN tb_conta_gestao_vinculos v ON v.id_vinculo=g.id_vinculo WHERE v.id_conta_gestora IN(:accounts) OR v.id_conta_cliente IN(:accounts) ORDER BY g.id_vinculo,g.id_permissao FOR UPDATE OF g',params);
            execute('SELECT e.id_equipe,e.id_permissao FROM tb_conta_gestao_equipe_permissoes e JOIN tb_conta_gestao_vinculos v ON v.id_vinculo=e.id_vinculo WHERE v.id_conta_gestora IN(:accounts) OR v.id_conta_cliente IN(:accounts) ORDER BY e.id_equipe,e.id_permissao FOR UPDATE OF e',params);
        }
        if(execute("SELECT to_regclass('public.tb_conta_permissoes') IS NOT NULL AS present").present[1]) execute('SELECT id_conta_permissao FROM tb_conta_permissoes WHERE id_conta IN(:accounts) ORDER BY id_conta,id_conta_permissao FOR UPDATE',params);
    }
    public void function assertResource(required struct context, required struct resource) {
        var policy=createObject('component','services.accountDelegation.Policy');
        if(!structKeyExists(resource,'type') || !isSimpleValue(resource.type) || !listFind('RELATIONSHIP,ASSIGNMENT,INVITATION,ACCOUNT,CAMPAIGN,PAYMENT_INTENT,EVENT,EVENT_REQUEST',resource.type)
            || !structKeyExists(resource,'id') || !isSimpleValue(resource.id) || len(resource.id & '')>160) policy.fail('Validation','Invalid resource');
        if(resource.type=='ACCOUNT' && compare(policy.identifier(resource.id),context.accountId & '')!=0) policy.fail('NotFound','Resource unavailable');
        if(listFind('RELATIONSHIP,ASSIGNMENT,INVITATION',resource.type)) {
            var scope='';
            if(resource.type=='RELATIONSHIP') scope='SELECT id_vinculo FROM tb_conta_gestao_vinculos WHERE id_vinculo=:id AND (id_conta_cliente=:account OR id_conta_gestora=:account)';
            if(resource.type=='ASSIGNMENT') scope='SELECT e.id_equipe FROM tb_conta_gestao_equipe e JOIN tb_conta_gestao_vinculos v ON v.id_vinculo=e.id_vinculo WHERE e.id_equipe=:id AND (v.id_conta_cliente=:account OR v.id_conta_gestora=:account)';
            if(resource.type=='INVITATION') scope='SELECT id_convite FROM tb_conta_gestao_convites WHERE id_convite=:id AND id_conta=:account';
            if(context.accessMode=='DELEGATED') {
                if(resource.type=='RELATIONSHIP') scope &= ' AND id_vinculo=:relationship';
                if(resource.type=='ASSIGNMENT') scope &= ' AND v.id_vinculo=:relationship';
                if(resource.type=='INVITATION') scope &= ' AND id_vinculo=:relationship';
            }
            if(!execute(scope,{id=idParam(policy.identifier(resource.id)),account=idParam(context.accountId),relationship=idParam(context.relationshipId)}).recordCount) policy.fail('NotFound','Resource unavailable');
        }
        // Product handlers must prove campaign/payment/event ownership and product enablement
        // in work(context), using this same datasource/transaction, before the first write.
    }
    // Only called after withMutation locks, resolves and authorizes this Ads transaction.
    // SET LOCAL is bound to the same connection and expires on commit or rollback.
    public void function setAdsContext(required struct context) {
        var payload='';
        if(context.accessMode=='DELEGATED') {
            var canonical={"enabled"=true,"accessMode"="DELEGATED","actorId"=context.actorId & '',"accountId"=context.accountId & '',
                "managerAccountId"=context.managerAccountId & '',"relationshipId"=context.relationshipId & '',
                "versions"={"managerVersion"=context.versions.managerVersion & '',"relationshipVersion"=context.versions.relationshipVersion & '',
                    "assignmentVersion"=context.versions.assignmentVersion & '',"membershipId"=context.versions.membershipId & ''}};
            payload=serializeJSON(canonical);
        }
        execute("SELECT set_config('business.delegation_context',:context,true)",{context={value=payload,cfsqltype='cf_sql_varchar'}});
    }
    public boolean function paymentReceipt(required struct context,required string paymentIntentId) {
        if(!reFindNoCase('^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',paymentIntentId)) return false;
        return execute("SELECT 1 FROM ads.payment_intents p WHERE p.payment_intent_id=CAST(:id AS uuid) AND p.account_id=:account AND p.created_by=:actor
            AND EXISTS(SELECT 1 FROM public.tb_conta_gestao_auditoria a WHERE a.recurso_tipo='PAYMENT_INTENT' AND a.recurso_id=CAST(p.payment_intent_id AS text) AND a.acao='ads.credits.purchase' AND a.resultado='SUCCESS'
            AND a.id_usuario_ator=:actor AND a.id_conta_cliente=:account AND a.id_conta_gestora=:manager AND a.id_vinculo=:relationship)",
            {id={value=lCase(paymentIntentId),cfsqltype='cf_sql_varchar'},account=idParam(context.accountId),actor=idParam(context.actorId),manager=idParam(context.managerAccountId),relationship=idParam(context.relationshipId)}).recordCount==1;
    }
    public void function audit(required struct context,required string capability,required struct resource) {
        execute("INSERT INTO tb_conta_gestao_auditoria(id_usuario_ator,id_conta_gestora,id_conta_cliente,id_vinculo,acao,recurso_tipo,recurso_id,resultado)
            VALUES(:actor,NULLIF(:manager,0),:account,NULLIF(:relationship,0),:action,:type,:id,'SUCCESS')",
            {actor=idParam(context.actorId),manager=idParam(context.managerAccountId),account=idParam(context.accountId),relationship=idParam(context.relationshipId),
             action={value=capability,cfsqltype='cf_sql_varchar'},type={value=resource.type,cfsqltype='cf_sql_varchar'},id={value=resource.id,cfsqltype='cf_sql_varchar'}});
    }
    // Lifecycle readers share this Store's DSN. Caller locks the complete scope before using them to authorize.
    public struct function lifecycleRelationship(required any id) { return first(execute('SELECT * FROM tb_conta_gestao_vinculos WHERE id_vinculo=:id',{id=idParam(id)})); }
    public struct function findRelationship(required any clientId,required any managerId) {
        return first(execute('SELECT * FROM tb_conta_gestao_vinculos WHERE id_conta_cliente=:client AND id_conta_gestora=:manager',{client=idParam(clientId),manager=idParam(managerId)}));
    }
    public struct function membershipById(required any id) { return first(execute('SELECT id_conta_usuario,id_conta,id_usuario,papel,status FROM tb_conta_usuarios WHERE id_conta_usuario=:id',{id=idParam(id)})); }
    public struct function assignmentById(required any id) { return first(execute('SELECT * FROM tb_conta_gestao_equipe WHERE id_equipe=:id',{id=idParam(id)})); }
    public struct function companyContact(required any accountId,boolean ownerOnly=false) {
        var sql="SELECT u.email,m.id_usuario,m.id_conta_usuario FROM tb_conta_usuarios m JOIN tb_usuarios u ON u.id=m.id_usuario ";
        if(userStatusReady()) sql &= 'LEFT JOIN tb_usuarios_gestao g ON g.id_usuario=u.id ';
        sql &= "WHERE m.id_conta=:id AND m.status='ATIVO' AND CAST(m.papel AS text) IN('OWNER','ADMIN')
            AND (:owner=false OR CAST(m.papel AS text)='OWNER')
            AND lower(btrim(u.email)) ~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' ";
        if(userStatusReady()) sql &= 'AND coalesce(g.ativo,true)=true AND coalesce(g.excluido,false)=false ';
        sql &= "ORDER BY CASE WHEN CAST(m.papel AS text)='OWNER' THEN 0 ELSE 1 END,m.id_conta_usuario LIMIT 1";
        return first(execute(sql,{id=idParam(accountId),owner={value=ownerOnly,cfsqltype='cf_sql_boolean'}}));
    }
    public struct function pendingRelationshipInvite(required any relationshipId) {
        return first(execute("SELECT * FROM tb_conta_gestao_convites WHERE id_vinculo=:id AND tipo IN('RELACAO','AMPLIACAO') AND status='PENDENTE' ORDER BY id_convite DESC LIMIT 1 FOR UPDATE",{id=idParam(relationshipId)}));
    }
    private struct function first(required query rows) {
        var result={};
        if(rows.recordCount) for(var column in listToArray(rows.columnList)) result[column]=rows[column][1];
        return result;
    }
    private array function codes(required query rows) { var result=[];for(var row in rows) arrayAppend(result,row.codigo);return result; }
}
