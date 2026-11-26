component output=false {
    public any function init(string datasource='runner_dba') {
        variables.ds=datasource;
        variables.study=new estudos.includes.StudyAccess().init(datasource);
        return this;
    }
    private query function db(required string sql,struct params={}) {
        var q=queryExecute(sql,params,{datasource=variables.ds,timeout=15});
        return isNull(local.q)?queryNew(''):q;
    }
    private struct function p(required any value,string type='cf_sql_varchar') {return {value=value,cfsqltype=type};}
    private struct function user(required any actorId,boolean admin=false) {
        // Reuse the library's verified personal identity and live user-status checks.
        var u=variables.study.dashboard(actorId).user;
        if(admin && !u.is_admin) throw(type='StudyAccess.Access',message='Acesso exclusivo para administradores.');
        return u;
    }
    private string function document(required string value) {
        if(len(value)>30 || reFind('[^0-9./\-\s]',value)) throw(type='StudyAccess.Validation',message='Confira o CNPJ.');
        var d=reReplace(value,'[^0-9]','','all');
        if(len(d)!=14 || reFind('^([0-9])\1{13}$',d)) throw(type='StudyAccess.Validation',message='Confira o CNPJ completo.');
        for(var n=12;n<=13;n++) {
            var weight=n-7;var total=0;
            for(var i=1;i<=n;i++) {total+=val(mid(d,i,1))*weight;weight--;if(weight<2) weight=9;}
            var remainder=total mod 11;var digit=remainder<2?0:11-remainder;
            if(val(mid(d,n+1,1))!=digit) throw(type='StudyAccess.Validation',message='Confira os dígitos do CNPJ.');
        }
        return d;
    }
    private struct function company(string cnpj='',string companyId='') {
        if(len(companyId) && !reFind('^[1-9][0-9]{0,17}$',companyId)) throw(type='StudyAccess.Validation',message='Confira a empresa selecionada.');
        var byId=len(companyId)>0;
        var q=db("SELECT c.id_conta,c.nome_conta,coalesce(c.documento,'') AS documento,c.documento_pendente,p.logo_path,p.dados::text AS dados
            FROM estudo.primeiro_acesso_empresas e JOIN public.tb_contas c USING(id_conta)
            JOIN public.tb_conta_perfis_publicos p USING(id_conta)
            WHERE e.ativo AND p.origem='ABRACEO' AND c.tipo_titular='PJ'
              AND c.status IN ('PENDENTE','ATIVA') AND " & (byId?'c.id_conta=:id':'c.documento=:doc'),
            byId?{id=p(companyId,'cf_sql_bigint')}:{doc=p(cnpj)});
        if(!q.recordCount) throw(type='StudyAccess.Missing',message='Não encontramos um pré-cadastro disponível. Confira o CNPJ ou solicite a revisão do convite pela biblioteca.');
        var source=deserializeJSON(q.dados[1]);
        var result={'id_conta':toString(q.id_conta[1]),'nome_empresa':q.nome_conta[1],'cnpj':q.documento[1],'documento_pendente':q.documento_pendente[1],'logo':''};
        if(reFind('^/assets/contas/abraceo/[a-z0-9-]+\.(jpg|png)$',q.logo_path[1])) result.logo=q.logo_path[1];
        var fields={'razao_social':'razao_social_pesquisada','nome_fantasia':'nome_fantasia_cadastral','email_publico':'email_publico','telefone_publico':'telefone_publico','site':'site_revisado','endereco':'endereco_cadastral','bairro':'bairro_cadastral','cidade':'municipio_cadastral','uf':'uf_cadastral','cep':'cep_cadastral'};
        for(var key in fields) result[key]=structKeyExists(source,fields[key])?source[fields[key]]:'';
        return result;
    }
    private void function available() {
        var q=db("SELECT c.id FROM estudo.campanhas c JOIN estudo.produtos p ON p.id=c.produto_id
            WHERE c.codigo='abraceo-primeiro-acesso' AND c.status='ACTIVE'
              AND (c.inicio_em IS NULL OR c.inicio_em<=clock_timestamp())
              AND (c.fim_em IS NULL OR c.fim_em>clock_timestamp())
              AND p.codigo='previa-2026-q3' AND p.status='ACTIVE' AND p.publicacao_id IS NOT NULL");
        if(!q.recordCount) throw(type='StudyAccess.Access',message='O primeiro acesso à prévia está temporariamente indisponível.');
    }
    public struct function lookup(required any actorId,required string mode,required string value) {
        var u=user(actorId);available();
        var modeName=uCase(mode);var target='';var targetId='';
        if(modeName=='CNPJ') target=document(value);
        else if(modeName=='VOUCHER') {
            var code=uCase(trim(value));
            if(!reFind('^BQ26-[A-F0-9]{32}$',code)) throw(type='StudyAccess.Validation',message='Informe o código completo do voucher.');
            var q=db("SELECT c.id_conta FROM estudo.vouchers v JOIN estudo.primeiro_acesso_convites x ON x.voucher_id=v.id
                JOIN public.tb_contas c ON c.id_conta=x.id_conta JOIN estudo.campanhas camp ON camp.id=v.campanha_id
                WHERE v.codigo_hash=:h AND v.email_destinatario=:email AND camp.codigo='abraceo-primeiro-acesso'
                  AND ((v.status='READY' AND v.expira_em>clock_timestamp())
                    OR (v.status='REDEEMED' AND v.resgatado_por=:u AND EXISTS(SELECT 1 FROM estudo.acessos a WHERE a.voucher_id=v.id AND a.status='ACTIVE')))",
                {h=p(lCase(hash(code,'SHA-256','UTF-8'))),email=p(u.email),u=p(u.id,'cf_sql_bigint')});
            if(!q.recordCount) throw(type='StudyAccess.Access',message='Voucher indisponível para este e-mail. Entre com o e-mail do convite ou use o CNPJ.');
            targetId=toString(q.id_conta[1]);
        } else throw(type='StudyAccess.Validation',message='Escolha CNPJ ou voucher.');
        return {'company':company(target,targetId),'representative':{'name':u.name,'email':u.email},'mode':modeName};
    }
    private void function audit(required any actorId,required string action,required string entity,required any entityId,struct details={}) {
        db('INSERT INTO estudo.auditoria_comercial(ator_id,acao,entidade,entidade_id,detalhes) VALUES(:u,:a,:e,:i,CAST(:d AS jsonb))',
            {u=p(actorId,'cf_sql_bigint'),a=p(action),e=p(entity),i=p(entityId,'cf_sql_bigint'),d=p(serializeJSON(details),'cf_sql_longvarchar')});
    }
    private struct function cnpjGrant(required struct u) {
        // Caller holds the user row lock. Both new and nominal READY invitations are
        // redeemed by explicit CNPJ declaration under the same campaign rules.
        var q=db("SELECT v.id,v.status,v.resgatado_por,(v.expira_em>clock_timestamp()) AS valid
            FROM estudo.vouchers v JOIN estudo.campanhas c ON c.id=v.campanha_id
            WHERE c.codigo='abraceo-primeiro-acesso' AND v.email_destinatario=:email ORDER BY v.id DESC LIMIT 1 FOR UPDATE OF v",{email=p(u.email)});
        var camp=db("SELECT c.id,c.produto_id FROM estudo.campanhas c JOIN estudo.produtos p ON p.id=c.produto_id
            WHERE c.codigo='abraceo-primeiro-acesso' AND c.status='ACTIVE' AND c.beneficio_percentual=0
              AND (c.inicio_em IS NULL OR c.inicio_em<=clock_timestamp()) AND (c.fim_em IS NULL OR c.fim_em>clock_timestamp())
              AND p.codigo='previa-2026-q3' AND p.status='ACTIVE' AND p.publicacao_id IS NOT NULL FOR SHARE OF c,p");
        if(!camp.recordCount) throw(type='StudyAccess.Access',message='A prévia não está disponível para novo acesso.');
        var voucherId=0;
        if(q.recordCount) {
            voucherId=q.id[1];
            if(q.status[1]=='REVOKED') throw(type='StudyAccess.Access',message='Este acesso foi revogado. Procure a equipe do Business.');
            if(q.status[1]=='REDEEMED') {
                var existing=db("SELECT id,status FROM estudo.acessos WHERE voucher_id=:v AND usuario_id=:u",{v=p(voucherId,'cf_sql_bigint'),u=p(u.id,'cf_sql_bigint')});
                if(!existing.recordCount || existing.status[1]!='ACTIVE') throw(type='StudyAccess.Access',message='Este acesso não está disponível. Procure a equipe do Business.');
                return {'id':toString(existing.id[1])};
            }
            if(!q.valid[1]) throw(type='StudyAccess.Access',message='Seu convite expirou. Solicite a renovação à equipe do Business.');
        } else {
            // No reusable plaintext code is persisted or returned for the CNPJ route.
            var secret='BQ26-' & uCase(left(binaryEncode(binaryDecode(generateSecretKey('AES',256),'base64'),'hex'),32));
            var created=db("INSERT INTO estudo.vouchers(campanha_id,codigo_hash,email_destinatario,expira_em,criado_por,nota)
                VALUES(:c,:h,:email,clock_timestamp()+interval '1 day',:u,'Primeiro acesso por CNPJ e autodeclaração; sem acesso operacional')
                RETURNING id",{c=p(camp.id[1],'cf_sql_bigint'),h=p(lCase(hash(secret,'SHA-256','UTF-8'))),email=p(u.email),u=p(u.id,'cf_sql_bigint')});
            voucherId=created.id[1];
        }
        db("UPDATE estudo.vouchers SET status='REDEEMED',resgatado_por=:u,resgatado_em=clock_timestamp() WHERE id=:v AND status='READY'",{u=p(u.id,'cf_sql_bigint'),v=p(voucherId,'cf_sql_bigint')});
        var grant=db('INSERT INTO estudo.acessos(usuario_id,produto_id,voucher_id) VALUES(:u,:p,:v) RETURNING id',
            {u=p(u.id,'cf_sql_bigint'),p=p(camp.produto_id[1],'cf_sql_bigint'),v=p(voucherId,'cf_sql_bigint')});
        audit(u.id,'CNPJ_PREVIEW_GRANT','voucher',voucherId,{'access_id':toString(grant.id[1])});
        return {'id':toString(grant.id[1])};
    }
    public struct function confirm(required any actorId,required string mode,required string value,required string role,required boolean declared,string corrections='') {
        var u=user(actorId);
        if(!declared) throw(type='StudyAccess.Validation',message='Confirme que representa a empresa para continuar.');
        if(!len(trim(role)) || len(role)>80 || len(corrections)>1000) throw(type='StudyAccess.Validation',message='Informe sua função (até 80 caracteres) e correções de até 1.000 caracteres.');
        var result={};
        transaction {
            db('SELECT id FROM public.tb_usuarios WHERE id=:u FOR UPDATE',{u=p(u.id,'cf_sql_bigint')});
            u=user(actorId);
            var selection=lookup(actorId,mode,value);var c=selection.company;
            var eligible=db("SELECT c.id_conta FROM estudo.primeiro_acesso_empresas e JOIN public.tb_contas c USING(id_conta)
                WHERE e.id_conta=:id AND e.ativo AND c.status IN ('ATIVA','PENDENTE') FOR SHARE OF e,c",{id=p(c.id_conta,'cf_sql_bigint')});
            if(!eligible.recordCount) throw(type='StudyAccess.Access',message='Este pré-cadastro não está disponível.');
            var previous=db('SELECT r.id,a.status FROM estudo.primeiro_acesso_representantes r JOIN estudo.acessos a ON a.id=r.acesso_id WHERE r.id_conta=:c AND r.usuario_id=:u',
                {c=p(c.id_conta,'cf_sql_bigint'),u=p(u.id,'cf_sql_bigint')});
            if(previous.recordCount && previous.status[1]!='ACTIVE') throw(type='StudyAccess.Access',message='Este acesso foi revogado. Procure a equipe do Business.');
            var access=uCase(mode)=='VOUCHER'?variables.study.redeem(actorId,value).access:cnpjGrant(u);
            var saved=db("INSERT INTO estudo.primeiro_acesso_representantes(id_conta,usuario_id,acesso_id,metodo,nome,email,funcao,observacoes)
                VALUES(:c,:u,:a,:m,:n,:e,:f,:o) ON CONFLICT(id_conta,usuario_id) DO NOTHING RETURNING id",
                {c=p(c.id_conta,'cf_sql_bigint'),u=p(u.id,'cf_sql_bigint'),a=p(access.id,'cf_sql_bigint'),m=p(uCase(mode)),n=p(left(u.name,200)),e=p(u.email),f=p(trim(role)),o=p(trim(corrections))});
            if(saved.recordCount) audit(u.id,'REPRESENTATIVE_DECLARED','first_access',saved.id[1],{'account_id':c.id_conta,'method':uCase(mode),'version':'abraceo-20261011-v1'});
            result={'status':'ACTIVE','company':c.nome_empresa,'reader_url':'/estudos/leitor/?ano=2026','operational_access_granted':false};
        }
        return result;
    }
    public struct function adminIssue(required any actorId,required string cnpj,required string email,required string expiresOn,string companyId='') {
        user(actorId,true);
        if(len(trim(companyId)) && len(trim(cnpj))) throw(type='StudyAccess.Validation',message='Selecione a empresa uma única vez.');
        var c=len(trim(companyId))?company('',trim(companyId)):company(document(cnpj));available();var result={};
        transaction {
            var campaign=db("SELECT id FROM estudo.campanhas WHERE codigo='abraceo-primeiro-acesso'");
            result=variables.study.adminCreateVoucher(actorId,campaign.id[1],email,expiresOn,'Primeiro acesso ABRACEO · conta ' & c.id_conta);
            db('INSERT INTO estudo.primeiro_acesso_convites(voucher_id,id_conta) VALUES(:v,:c)',{v=p(result.voucher.id,'cf_sql_bigint'),c=p(c.id_conta,'cf_sql_bigint')});
            audit(actorId,'COMPANY_VOUCHER','voucher',result.voucher.id,{'account_id':c.id_conta});
        }
        return result;
    }
    public struct function overview(required any actorId) {
        var u=user(actorId);var result={'user':u,'companies':[],'representatives':[]};
        if(u.is_admin) {
            var companies=db("SELECT c.id_conta,coalesce(c.documento,'') AS documento,c.nome_conta FROM estudo.primeiro_acesso_empresas e JOIN public.tb_contas c USING(id_conta) WHERE e.ativo AND c.status IN ('PENDENTE','ATIVA') ORDER BY c.nome_conta");
            for(var c in companies) arrayAppend(result.companies,{'id_conta':toString(c.id_conta),'cnpj':c.documento,'name':c.nome_conta});
            var claims=db('SELECT r.id,r.nome,r.email,r.funcao,r.metodo,r.observacoes,c.nome_conta,a.status FROM estudo.primeiro_acesso_representantes r JOIN public.tb_contas c USING(id_conta) JOIN estudo.acessos a ON a.id=r.acesso_id ORDER BY r.id DESC LIMIT 200');
            for(var r in claims) arrayAppend(result.representatives,{'id':toString(r.id),'name':r.nome,'email':r.email,'role':r.funcao,'method':r.metodo,'corrections':r.observacoes,'company':r.nome_conta,'status':r.status});
        }
        return result;
    }
}
