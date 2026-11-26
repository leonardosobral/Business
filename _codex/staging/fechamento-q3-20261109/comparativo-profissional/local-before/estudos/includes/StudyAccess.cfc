component output=false {
    public any function init(string datasource="runner_dba") {
        variables.ds=arguments.datasource;
        return this;
    }
    private query function db(required string sql,struct params={}) {
        var result=queryExecute(arguments.sql,arguments.params,{datasource=variables.ds,timeout=15});
        return isNull(local.result)?queryNew(""):local.result;
    }
    private struct function p(required any value,string type="cf_sql_varchar") {return {value=arguments.value,cfsqltype=arguments.type};}
    private struct function idp(required any value) {
        if(!isSimpleValue(value) || !reFind("^[1-9][0-9]{0,17}$",toString(value)))
            throw(type="StudyAccess.Validation",message="Identificador inválido.");
        return p(toString(value),"cf_sql_bigint");
    }
    private void function limitText(required string value,required numeric maximum,boolean nonempty=false) {
        if(len(value)>maximum || (nonempty && !len(trim(value))))
            throw(type="StudyAccess.Validation",message="Informe um texto de até " & maximum & " caracteres.");
    }
    private array function rows(required query data) {
        var out=[];
        for(var i=1;i<=data.recordCount;i++) {
            var item={};
            for(var key in listToArray(data.columnList)) {
                var lower=lCase(key);
                item[lower]=isNull(data[key][i])?"":data[key][i];
                if(lower=="id" || right(lower,3)=="_id" || listFind("usuario_id,criado_por,resgatado_por,revogado_por,decidido_por,atualizado_por",lower)) item[lower]=toString(item[lower]);
            }
            arrayAppend(out,item);
        }
        return out;
    }
    private struct function one(required query data) {
        var items=rows(data);
        if(!arrayLen(items)) throw(type="StudyAccess.Missing",message="Registro não encontrado.");
        return items[1];
    }
    private struct function actor(required any actorId,boolean admin=false) {
        idp(actorId);
        // A selected company, delegated operator or posted user id never establishes this identity.
        if(!structKeyExists(REQUEST,"businessIdentity") || !isStruct(REQUEST.businessIdentity)
            || !structKeyExists(REQUEST.businessIdentity,"id") || compare(toString(REQUEST.businessIdentity.id),toString(actorId))!=0
            || !structKeyExists(REQUEST.businessIdentity,"version") || REQUEST.businessIdentity.version!=1
            || !structKeyExists(REQUEST.businessIdentity,"sub") || !len(REQUEST.businessIdentity.sub)
            || !structKeyExists(REQUEST.businessIdentity,"email"))
            throw(type="StudyAccess.Access",message="Entre novamente com sua conta para continuar.");
        var statusReady=db("SELECT to_regclass('public.tb_usuarios_gestao') IS NOT NULL AS present").present[1];
        var sql="SELECT u.id,coalesce(u.name,'') AS name,lower(btrim(u.email)) AS email,coalesce(u.is_admin,false) AS is_admin FROM public.tb_usuarios u ";
        if(statusReady) sql &= "LEFT JOIN public.tb_usuarios_gestao g ON g.id_usuario=u.id ";
        sql &= "WHERE u.id=:id ";
        if(statusReady) sql &= "AND coalesce(g.ativo,true)=true AND coalesce(g.excluido,false)=false ";
        var q=db(sql,{id=idp(actorId)});
        if(!q.recordCount || compareNoCase(trim(q.email[1]),trim(REQUEST.businessIdentity.email))!=0)
            throw(type="StudyAccess.Access",message="Esta conta não está disponível para acessar o estudo. Entre novamente ou procure o suporte.");
        var result=one(q);
        result["is_admin"]=result.is_admin ? true : false;
        if(admin && !result.is_admin) throw(type="StudyAccess.Access",message="Acesso exclusivo para administradores.");
        return result;
    }
    private void function audit(required any actorId,required string action,required string entity,required any entityId,struct details={}) {
        db("INSERT INTO estudo.auditoria_comercial(ator_id,acao,entidade,entidade_id,detalhes) VALUES(:a,:action,:entity,:id,CAST(:details AS jsonb))",
            {a=idp(actorId),action=p(action),entity=p(entity),id=idp(entityId),details=p(serializeJSON(details),"cf_sql_longvarchar")});
    }
    private struct function accessResult(required any voucherId) {
        var grant=one(db("SELECT a.id,a.produto_id,p.codigo AS produto_codigo,p.titulo,a.status,CAST(a.concedido_em AS text) AS concedido_em FROM estudo.acessos a JOIN estudo.produtos p ON p.id=a.produto_id WHERE a.voucher_id=:v",{v=idp(voucherId)}));
        var benefits=rows(db("SELECT b.id,b.produto_id,p.codigo AS produto_codigo,b.percentual,b.status FROM estudo.beneficios b JOIN estudo.produtos p ON p.id=b.produto_id WHERE b.acesso_id=:a",{a=idp(grant.id)}));
        return {"access":grant,"benefit":arrayLen(benefits)?benefits[1]:{}};
    }
    public struct function dashboard(required any actorId) {
        var user=actor(actorId);
        var params={u=idp(actorId),admin=p(user.is_admin,"cf_sql_bit")};
        var products=rows(db("SELECT p.id,p.codigo,p.titulo,p.tipo,p.ano,p.status,CAST(p.periodo_inicio AS text) AS periodo_inicio,CAST(p.periodo_fim AS text) AS periodo_fim,
            (p.status='ACTIVE' AND p.publicacao_id IS NOT NULL AND (:admin OR EXISTS(SELECT 1 FROM estudo.acessos a WHERE a.usuario_id=:u AND a.produto_id=p.id AND a.status='ACTIVE'))) AS can_read
            FROM estudo.produtos p ORDER BY p.id",params));
        for(var product in products) product["allowed"]=product.can_read;
        return {"user":user,"products":products,
            "accesses":rows(db("SELECT a.id,a.produto_id,p.codigo AS produto_codigo,p.titulo,a.status,CAST(a.concedido_em AS text) AS concedido_em FROM estudo.acessos a JOIN estudo.produtos p ON p.id=a.produto_id WHERE a.usuario_id=:u ORDER BY a.id DESC",{u=idp(actorId)})),
            "requests":rows(db("SELECT id,kind,empresa,perfil,mensagem,status,CAST(criado_em AS text) AS criado_em FROM estudo.solicitacoes WHERE usuario_id=:u ORDER BY id DESC",{u=idp(actorId)})),
            "interests":rows(db("SELECT id,kind,status,CAST(atualizado_em AS text) AS atualizado_em FROM estudo.interesses WHERE usuario_id=:u ORDER BY id",{u=idp(actorId)})),
            "benefits":rows(db("SELECT b.id,b.produto_id,p.codigo AS produto_codigo,b.percentual,b.status FROM estudo.beneficios b JOIN estudo.produtos p ON p.id=b.produto_id WHERE b.usuario_id=:u ORDER BY b.id DESC",{u=idp(actorId)}))};
    }
    public struct function read(required any actorId,string productCode="previa-2026-q3") {
        var user=actor(actorId);
        if(!reFind("^[a-z0-9-]{3,60}$",productCode)) throw(type="StudyAccess.Validation",message="Estudo inválido.");
        // Apply the editorial scope after the access check, without changing the frozen
        // publication or the DBA's notebook. JSONB preserves numeric precision and nulls.
        var sourceSQL="SELECT p.id,p.codigo,p.titulo,p.tipo,p.ano,p.publicacao_id,w.payload
            FROM estudo.produtos p JOIN estudo.web_publicacoes w ON w.id=p.publicacao_id AND w.ano=p.ano
            WHERE p.codigo=:code AND p.status='ACTIVE'
            AND (:admin OR EXISTS(SELECT 1 FROM estudo.acessos a WHERE a.usuario_id=:u AND a.produto_id=p.id AND a.status='ACTIVE'))";
        var readSQL="SELECT id,codigo,titulo,tipo,ano,publicacao_id,CAST(payload AS text) AS payload_json FROM (" & sourceSQL & ") authorized";
        if(productCode=="previa-2026-q3") readSQL="WITH authorized AS (" & sourceSQL & "), selected AS (
            SELECT a.*,
                (SELECT coalesce(jsonb_agg(
                    CASE WHEN s->>'id'='maratonas_destaques' THEN s || jsonb_build_object('valores',
                        (SELECT jsonb_agg(v ORDER BY vo) FROM jsonb_array_elements(s->'valores') WITH ORDINALITY AS vals(v,vo)
                         WHERE v->>'rotulo' IN ('Top 10 soma','Mulheres')))
                    ELSE s END ORDER BY so),'[]'::jsonb)
                 FROM jsonb_array_elements(a.payload->'series') WITH ORDINALITY AS all_series(s,so)
                 WHERE s->>'id' !~ '^(inscricoes_|cna_|maratonas_revisao_|performance_42k_)'
                   AND s->>'id' NOT IN ('maratonas_cadastro','variacoes_a_z')) AS selected_series
            FROM authorized a
        ), delivery AS (
            SELECT s.*,
                (SELECT coalesce(jsonb_agg(c ORDER BY co),'[]'::jsonb)
                 FROM jsonb_array_elements(s.payload->'comparacoes') WITH ORDINALITY AS comparisons(c,co)
                 WHERE s.selected_series @> jsonb_build_array(jsonb_build_object('id',c->>'serie'))
                   AND (c->>'serie'<>'maratonas_destaques' OR c->>'categoria' IN ('Top 10 soma','Mulheres'))) AS selected_comparisons
            FROM selected s
        ) SELECT id,codigo,titulo,tipo,ano,publicacao_id,CAST(payload || jsonb_build_object(
            'series',selected_series,
            'comparacoes',selected_comparisons,
            'conciliacao',(SELECT coalesce(jsonb_object_agg(status,n),'{}'::jsonb) FROM (
                SELECT c->>'status' AS status,count(*) AS n FROM jsonb_array_elements(selected_comparisons) c
                WHERE c->>'status' IS NOT NULL GROUP BY c->>'status') counts),
            'meta',(payload->'meta') - ARRAY['inscricoes','inscricoes_geral','maratonas_revisao','maratonas_cadastro','maratonas_referencia_externa','notebook_fontes']
                || jsonb_build_object('escopo_editorial',jsonb_build_object(
                    'versao','q3-20261010-v1','produto',codigo,'publicacao_fonte',publicacao_id,
                    'criterio','Prévia profissional Jan–Set com recortes revisados. Consultas e congelamentos originais preservados no notebook.',
                    'temas_anuais_previstos',jsonb_build_array('Preços de inscrição, categorias, kits e lotes','Ritmo nacional dos 42 km e faixas de desempenho','Calendário completo de janeiro a dezembro'),
                    'ressalva','Temas previstos para a edição anual, sujeitos à revisão das fontes. Não integram os números nem as exportações desta prévia.'))
            ) AS text) AS payload_json FROM delivery";
        // Read bounded pieces: the datasource may cap a text column at 64,000
        // characters. Keep authorization and all pieces in the same DB snapshot.
        readSQL="WITH document AS MATERIALIZED (" & readSQL & ")
            SELECT d.id,d.codigo,d.titulo,d.tipo,d.ano,d.publicacao_id,
                char_length(d.payload_json) AS payload_length,
                substring(d.payload_json FROM piece.offset_char FOR 16000) AS payload_json
            FROM document d CROSS JOIN LATERAL
                generate_series(1,char_length(d.payload_json),16000) AS piece(offset_char)
            ORDER BY piece.offset_char";
        var q=db(readSQL,{code=p(productCode),u=idp(actorId),admin=p(user.is_admin,"cf_sql_bit")});
        if(!q.recordCount) throw(type="StudyAccess.Access",message="Você ainda não tem acesso a este estudo.");
        var pieces=[];
        for(var row=1;row<=q.recordCount;row++) arrayAppend(pieces,q.payload_json[row]);
        var payload=arrayToList(pieces,"");
        if(len(payload)!=q.payload_length[1] || !isJSON(payload))
            throw(type="StudyAccess.Payload",message="Não foi possível carregar o estudo completo. Tente novamente.");
        var product=one(q);structDelete(product,"payload_json");structDelete(product,"payload_length");
        return {"product":product,"publication_id":product.publicacao_id,"payload_json":payload};
    }
    public struct function ensureAnnualBenefit(required any actorId,required any accessId) {
        actor(actorId);idp(accessId);
        var result={"benefit":{}};
        transaction {
            // Match redemption/revocation lock order: voucher, then access/campaign.
            var voucher=db("SELECT v.id FROM estudo.vouchers v JOIN estudo.acessos a ON a.voucher_id=v.id
                WHERE a.id=:a AND a.usuario_id=:u FOR UPDATE OF v",{a=idp(accessId),u=idp(actorId)});
            if(!voucher.recordCount) throw(type="StudyAccess.Access",message="Este acesso não está disponível para esta conta.");
            var source=db("SELECT a.id,a.voucher_id,c.id AS campaign_id,c.codigo AS campaign_code,c.beneficio_percentual,c.beneficio_produto_id,
                preview.ano AS preview_year,annual.tipo AS annual_type,annual.ano AS annual_year
                FROM estudo.acessos a JOIN estudo.vouchers v ON v.id=a.voucher_id
                JOIN estudo.campanhas c ON c.id=v.campanha_id AND c.produto_id=a.produto_id
                JOIN estudo.produtos preview ON preview.id=a.produto_id
                LEFT JOIN estudo.produtos annual ON annual.id=c.beneficio_produto_id
                WHERE a.id=:a AND a.usuario_id=:u AND a.status='ACTIVE' AND v.status='REDEEMED' AND v.resgatado_por=:u
                  AND preview.tipo='PREVIA' FOR SHARE OF a,c",{a=idp(accessId),u=idp(actorId)});
            if(!source.recordCount) throw(type="StudyAccess.Access",message="O resgate deste convite não está ativo para esta conta.");
            var origin=one(source);
            if(origin.beneficio_percentual==50 && (origin.annual_type!='ANUAL' || origin.annual_year!=origin.preview_year))
                throw(type="StudyAccess.Conflict",message="O benefício anual precisa ser conferido pela equipe do Business.");
            var current=db("SELECT b.id,b.usuario_id,b.produto_id,p.codigo AS produto_codigo,b.percentual,b.status
                FROM estudo.beneficios b JOIN estudo.produtos p ON p.id=b.produto_id WHERE b.acesso_id=:a",{a=idp(accessId)});
            if(current.recordCount) {
                var existing=one(current);
                if(existing.usuario_id!=toString(actorId) || (origin.beneficio_percentual==50 && existing.produto_id!=origin.beneficio_produto_id))
                    throw(type="StudyAccess.Conflict",message="O benefício deste convite precisa ser conferido pela equipe do Business.");
                // A repeated redemption must never reactivate a revoked benefit.
                result["benefit"]=existing;
            } else if(origin.beneficio_percentual==50) {
                var inserted=db("INSERT INTO estudo.beneficios(usuario_id,produto_id,acesso_id,percentual)
                    VALUES(:u,:p,:a,50) ON CONFLICT(acesso_id) DO NOTHING RETURNING id",
                    {u=idp(actorId),p=idp(origin.beneficio_produto_id),a=idp(accessId)});
                if(inserted.recordCount) audit(actorId,"ANNUAL_EARLY_PURCHASE_BENEFIT","benefit",inserted.id[1],
                    {"access_id":toString(accessId),"voucher_id":origin.voucher_id,"campaign":origin.campaign_code,"percent":50,"kind":"EARLY_PURCHASE"});
                result["benefit"]=one(db("SELECT b.id,b.usuario_id,b.produto_id,p.codigo AS produto_codigo,b.percentual,b.status
                    FROM estudo.beneficios b JOIN estudo.produtos p ON p.id=b.produto_id WHERE b.acesso_id=:a",{a=idp(accessId)}));
            }
        }
        return result;
    }
    public struct function redeem(required any actorId,required string code) {
        actor(actorId);
        var normalized=uCase(trim(code));
        if(!reFind("^BQ26-[A-F0-9]{32}$",normalized)) throw(type="StudyAccess.Validation",message="Confira o código completo do convite.");
        var result={};
        transaction {
            var user=actor(actorId);
            // Voucher first, then campaign: the same order is used by revocation.
            var vouchers=db("SELECT id,campanha_id,email_destinatario,status,resgatado_por,(expira_em>clock_timestamp()) AS valid FROM estudo.vouchers WHERE codigo_hash=:h FOR UPDATE",
                {h=p(lCase(hash(normalized,"SHA-256","UTF-8")))});
            if(!vouchers.recordCount || compareNoCase(vouchers.email_destinatario[1],user.email)!=0)
                throw(type="StudyAccess.Access",message="Voucher indisponível para esta conta. Use o e-mail informado no convite.");
            var voucher=one(vouchers);
            if(voucher.status=="REDEEMED" && toString(voucher.resgatado_por)==toString(actorId)) {
                result=accessResult(voucher.id);
                if(result.access.status!="ACTIVE") throw(type="StudyAccess.Access",message="O acesso deste convite foi revogado.");
                ensureAnnualBenefit(actorId,result.access.id);
                result=accessResult(voucher.id);
            } else {
                if(voucher.status!="READY" || !voucher.valid) throw(type="StudyAccess.Access",message="Este convite não está disponível ou já expirou.");
                var campaign=one(db("SELECT c.id,c.produto_id,c.beneficio_percentual,c.beneficio_produto_id,
                    (c.status='ACTIVE' AND (c.inicio_em IS NULL OR c.inicio_em<=clock_timestamp()) AND (c.fim_em IS NULL OR c.fim_em>clock_timestamp()) AND p.status='ACTIVE' AND p.publicacao_id IS NOT NULL) AS available
                    FROM estudo.campanhas c JOIN estudo.produtos p ON p.id=c.produto_id WHERE c.id=:id FOR SHARE OF c,p",{id=idp(voucher.campanha_id)}));
                if(!campaign.available) throw(type="StudyAccess.Access",message="A campanha deste convite ainda não está disponível para resgate.");
                db("UPDATE estudo.vouchers SET status='REDEEMED',resgatado_por=:u,resgatado_em=clock_timestamp() WHERE id=:v",{u=idp(actorId),v=idp(voucher.id)});
                var grant=one(db("INSERT INTO estudo.acessos(usuario_id,produto_id,voucher_id) VALUES(:u,:p,:v) RETURNING id",
                    {u=idp(actorId),p=idp(campaign.produto_id),v=idp(voucher.id)}));
                ensureAnnualBenefit(actorId,grant.id);
                audit(actorId,"REDEEM","voucher",voucher.id,{"access_id":grant.id,"benefit_percent":campaign.beneficio_percentual});
                result=accessResult(voucher.id);
            }
        }
        return result;
    }
    public struct function requestAccess(required any actorId,string company="",string role="",string message="",string kind="PROFISSIONAL") {
        actor(actorId);limitText(company,160,true);limitText(role,80,true);limitText(message,2000,true);
        if(!listFind("PROFISSIONAL,EDITORIAL",kind)) throw(type="StudyAccess.Validation",message="Tipo de solicitação inválido.");
        var result={};
        transaction {
            actor(actorId);
            var inserted=db("INSERT INTO estudo.solicitacoes(usuario_id,produto_id,kind,empresa,perfil,mensagem)
                SELECT :u,id,:k,:company,:role,:message FROM estudo.produtos WHERE codigo='previa-2026-q3'
                ON CONFLICT(usuario_id,produto_id) DO NOTHING RETURNING id",
                {u=idp(actorId),k=p(kind),company=p(trim(company)),role=p(trim(role)),message=p(trim(message))});
            result=one(db("SELECT s.id,s.kind,s.empresa,s.perfil,s.mensagem,s.status,CAST(s.criado_em AS text) AS criado_em FROM estudo.solicitacoes s JOIN estudo.produtos p ON p.id=s.produto_id WHERE s.usuario_id=:u AND p.codigo='previa-2026-q3'",{u=idp(actorId)}));
            if(inserted.recordCount) audit(actorId,"REQUEST_ACCESS","request",result.id,{"kind":kind});
        }
        return {"request":result};
    }
    public struct function interest(required any actorId,string kind="ANUAL",boolean enabled=true) {
        actor(actorId);
        if(!listFind("ANUAL,EDITORIAL",kind)) throw(type="StudyAccess.Validation",message="Preferência inválida.");
        var result={};
        transaction {
            actor(actorId);
            result=one(db("INSERT INTO estudo.interesses(usuario_id,kind,status) VALUES(:u,:k,:s)
                ON CONFLICT(usuario_id,kind) DO UPDATE SET status=excluded.status,atualizado_em=clock_timestamp()
                RETURNING id,kind,status,CAST(atualizado_em AS text) AS atualizado_em",
                {u=idp(actorId),k=p(kind),s=p(enabled?"ACTIVE":"WITHDRAWN")}));
            audit(actorId,"INTEREST","interest",result.id,{"kind":kind,"enabled":enabled});
        }
        return {"interest":result};
    }

    // Launch validations share the existing immutable commercial audit, independently
    // of notebook queries, grants, voucher campaigns and legal contract acceptance.
    private array function launchStepDefinitions() {
        return [
            {"key":"organizar","date":"09 NOV · SEG","title":"Fechar e organizar","description":"Validar recorte e peças, nomear responsáveis e selecionar leitores e criadores."},
            {"key":"piloto","date":"10–11 NOV · TER–QUA","title":"Pilotar o acesso","description":"Testar login, voucher e leitura com 5–10 leitores. Conferir convites e posts."},
            {"key":"contrato-abraceo","date":"ATÉ 12 NOV · QUI","title":"Aprovar contrato com a ABRACEO","description":"Concluir a revisão e obter a aprovação das partes para o contrato e a comunicação da parceria."},
            {"key":"liberacao","date":"12 NOV · QUI","title":"Conferir e liberar","description":"Resolver bloqueios e conferir links, peças, destinatários, contrato e comunicação antes de divulgar."},
            {"key":"lancamento","date":"13 NOV · SEX","title":"Colocar na rua","description":"Publicar post principal e stories, disponibilizar o kit e realizar a primeira onda de convites autorizados."},
            {"key":"continuidade","date":"14–20 NOV","title":"Dar continuidade","description":"Acompanhar dúvidas, feedback, entrevistas, pautas e reviews que surgirem."},
            {"key":"venda-anual","date":"NOV–DEZ","title":"Preparar a venda","description":"Validar oferta, licença e relacionamento. Testar o checkout antes do recesso."},
            {"key":"edicao-anual","date":"06 / 11 JAN 2027 · PROPOSTA","title":"Antecipado / geral","description":"Confirmar datas e oferta da edição anual. Preço e desconto seguem em validação comercial."}
        ];
    }
    private struct function launchChecklistState() {
        var steps=launchStepDefinitions();
        var latest=db("SELECT DISTINCT ON (a.detalhes->>'step') a.id,a.detalhes->>'step' AS step,
            coalesce((a.detalhes->>'completed')::boolean,false) AS completed,coalesce(u.name,'Administrador') AS author,
            to_char(a.criado_em AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY HH24:MI') AS changed_at
            FROM estudo.auditoria_comercial a JOIN public.tb_usuarios u ON u.id=a.ator_id
            WHERE a.entidade='launch_checklist' AND a.acao='LAUNCH_STEP_VALIDATION'
              AND a.entidade_id=(SELECT id FROM estudo.produtos WHERE codigo='previa-2026-q3')
              AND a.detalhes->>'release'='2026-q3-20261113'
            ORDER BY a.detalhes->>'step',a.id DESC");
        var known={};
        for(var i=1;i<=latest.recordCount;i++) known[latest.step[i]]={"version":toString(latest.id[i]),"completed":latest.completed[i]?true:false,"author":latest.author[i],"changed_at":latest.changed_at[i]};
        var details=db("SELECT DISTINCT ON (a.detalhes->>'step') a.id,a.detalhes->>'step' AS step,
            coalesce(a.detalhes->>'responsible','') AS responsible,coalesce(a.detalhes->>'notes','') AS notes,
            coalesce(u.name,'Administrador') AS author,
            to_char(a.criado_em AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY HH24:MI') AS changed_at
            FROM estudo.auditoria_comercial a JOIN public.tb_usuarios u ON u.id=a.ator_id
            WHERE a.entidade='launch_checklist' AND a.acao='LAUNCH_STEP_DETAILS'
              AND a.entidade_id=(SELECT id FROM estudo.produtos WHERE codigo='previa-2026-q3')
              AND a.detalhes->>'release'='2026-q3-20261113'
            ORDER BY a.detalhes->>'step',a.id DESC");
        var knownDetails={};
        for(var j=1;j<=details.recordCount;j++) knownDetails[details.step[j]]={"details_version":toString(details.id[j]),"responsible":details.responsible[j],"notes":details.notes[j],"details_author":details.author[j],"details_changed_at":details.changed_at[j]};
        var completed=0;
        for(var step in steps) {
            var state=structKeyExists(known,step.key)?known[step.key]:{"version":"0","completed":false,"author":"","changed_at":""};
            structAppend(step,state,true);
            var detailsState=structKeyExists(knownDetails,step.key)?knownDetails[step.key]:{"details_version":"0","responsible":"","notes":"","details_author":"","details_changed_at":""};
            structAppend(step,detailsState,true);
            if(step.completed) completed++;
        }
        return {"release":"2026-q3-20261113","steps":steps,"completed":completed,"total":arrayLen(steps)};
    }
    public struct function adminLaunchChecklist(required any actorId) {
        actor(actorId,true);
        return launchChecklistState();
    }
    public struct function adminValidateLaunchStep(required any actorId,required string stepKey,required boolean completed,required string expectedVersion) {
        actor(actorId,true);
        var allowed=false;
        for(var definition in launchStepDefinitions()) if(compare(definition.key,stepKey)==0) allowed=true;
        if(!allowed || !reFind("^(0|[1-9][0-9]{0,17})$",expectedVersion)) throw(type="StudyAccess.Validation",message="Etapa ou versão inválida.");
        transaction {
            actor(actorId,true);
            db("SELECT pg_advisory_xact_lock(20261113,hashtext(:step))",{step=p(stepKey)});
            var current=launchChecklistState();var prior={};
            for(var step in current.steps) if(compare(step.key,stepKey)==0) prior=step;
            if(compare(prior.version,expectedVersion)!=0) throw(type="StudyAccess.Conflict",message="Outro administrador atualizou esta etapa. Confira o estado atual antes de validar novamente.");
            if(prior.completed!=completed) {
                var product=one(db("SELECT id FROM estudo.produtos WHERE codigo='previa-2026-q3'"));
                audit(actorId,"LAUNCH_STEP_VALIDATION","launch_checklist",product.id,
                    {"release":"2026-q3-20261113","step":stepKey,"completed":completed,"previous_version":prior.version});
            }
            var result=launchChecklistState();
        }
        return result;
    }

    public struct function adminUpdateLaunchStepDetails(required any actorId,required string stepKey,required string responsible,required string notes,required string expectedVersion) {
        actor(actorId,true);
        limitText(responsible,120);limitText(notes,2000);
        var allowed=false;
        for(var definition in launchStepDefinitions()) if(compare(definition.key,stepKey)==0) allowed=true;
        if(!allowed || !reFind("^(0|[1-9][0-9]{0,17})$",expectedVersion)) throw(type="StudyAccess.Validation",message="Etapa ou versão inválida.");
        var owner=trim(responsible);var observations=trim(notes);
        transaction {
            actor(actorId,true);
            db("SELECT pg_advisory_xact_lock(20261113,hashtext(:step))",{step=p(stepKey)});
            var current=launchChecklistState();var prior={};
            for(var step in current.steps) if(compare(step.key,stepKey)==0) prior=step;
            if(compare(prior.details_version,expectedVersion)!=0) throw(type="StudyAccess.Conflict",message="Outro administrador alterou as informações desta etapa. Seu rascunho foi preservado; confira a versão salva abaixo.");
            if(compare(prior.responsible,owner)!=0 || compare(prior.notes,observations)!=0) {
                var product=one(db("SELECT id FROM estudo.produtos WHERE codigo='previa-2026-q3'"));
                audit(actorId,"LAUNCH_STEP_DETAILS","launch_checklist",product.id,
                    {"release":"2026-q3-20261113","step":stepKey,"responsible":owner,"notes":observations,"previous_version":prior.details_version});
            }
            var result=launchChecklistState();
        }
        return result;
    }

    public struct function adminOverview(required any actorId) {
        actor(actorId,true);
        return {"campaigns":rows(db("SELECT c.id,c.codigo,c.titulo,c.status,c.version,c.beneficio_percentual,p.codigo AS produto_codigo FROM estudo.campanhas c JOIN estudo.produtos p ON p.id=c.produto_id ORDER BY c.id")),
            "vouchers":rows(db("SELECT v.id,v.campanha_id,c.titulo AS campanha,v.email_destinatario,v.status,v.solicitacao_id,v.resgatado_por,CAST(v.expira_em AS text) AS expira_em,(v.expira_em<=clock_timestamp()) AS expired,CAST(v.criado_em AS text) AS criado_em FROM estudo.vouchers v JOIN estudo.campanhas c ON c.id=v.campanha_id ORDER BY v.id DESC LIMIT 200")),
            "requests":rows(db("SELECT s.id,s.usuario_id,u.name AS name,u.email,s.kind,s.empresa,s.perfil,s.mensagem,s.status,CAST(s.criado_em AS text) AS criado_em FROM estudo.solicitacoes s JOIN public.tb_usuarios u ON u.id=s.usuario_id ORDER BY CASE WHEN s.status='PENDING' THEN 0 ELSE 1 END,s.id DESC LIMIT 200")),
            "accesses":rows(db("SELECT a.id,a.usuario_id,u.name AS name,u.email,a.produto_id,p.titulo,a.status,a.voucher_id,CAST(a.concedido_em AS text) AS concedido_em FROM estudo.acessos a JOIN public.tb_usuarios u ON u.id=a.usuario_id JOIN estudo.produtos p ON p.id=a.produto_id ORDER BY a.id DESC LIMIT 200")),
            "metrics":one(db("SELECT (SELECT count(*) FROM estudo.solicitacoes WHERE status='PENDING') AS pending_requests,(SELECT count(*) FROM estudo.vouchers WHERE status='READY' AND expira_em>clock_timestamp()) AS ready_vouchers,(SELECT count(DISTINCT usuario_id) FROM estudo.acessos WHERE status='ACTIVE') AS active_readers,(SELECT count(DISTINCT usuario_id) FROM estudo.interesses WHERE kind='ANUAL' AND status='ACTIVE') AS annual_interests"))};
    }
    public struct function adminCampaign(required any actorId,required any campaignId,required string status,required numeric expectedVersion,required string note) {
        actor(actorId,true);idp(campaignId);limitText(note,1000,true);
        if(!listFind("ACTIVE,PAUSED",status) || expectedVersion<1 || expectedVersion!=int(expectedVersion)) throw(type="StudyAccess.Validation",message="Estado ou versão da campanha inválidos.");
        var result={};
        transaction {
            actor(actorId,true);
            var changed=db("UPDATE estudo.campanhas SET status=:s,version=version+1,atualizado_por=:a,atualizado_em=clock_timestamp() WHERE id=:id AND version=:v AND status<>'CLOSED' RETURNING id,codigo,status,version",
                {s=p(status),a=idp(actorId),id=idp(campaignId),v=p(expectedVersion,"cf_sql_integer")});
            if(!changed.recordCount) throw(type="StudyAccess.Conflict",message="A campanha mudou. Atualize a tela antes de continuar.");
            result=one(changed);audit(actorId,"CAMPAIGN_STATUS","campaign",campaignId,{"status":status,"note":trim(note),"version":result.version});
        }
        return {"campaign":result};
    }
    public struct function adminCreateVoucher(required any actorId,required any campaignId,required string email,required string expiresOn,string note="",any requestId=0) {
        actor(actorId,true);idp(campaignId);limitText(note,1000);
        var recipient=lCase(trim(email));
        if(len(recipient)>254 || !new services.EmailAddress().isValidAddress(recipient)) throw(type="StudyAccess.Validation",message="Informe um e-mail válido para o convite.");
        if(!reFind("^20[0-9]{2}-[0-9]{2}-[0-9]{2}$",expiresOn) || !isDate(expiresOn)) throw(type="StudyAccess.Validation",message="Informe uma data de expiração válida.");
        if(toString(requestId)!="0") idp(requestId);
        var code="BQ26-" & uCase(left(binaryEncode(binaryDecode(generateSecretKey("AES",256),"base64"),"hex"),32));
        var voucher={};
        transaction {
            actor(actorId,true);
            var campaign=one(db("SELECT id,produto_id,status FROM estudo.campanhas WHERE id=:id FOR SHARE",{id=idp(campaignId)}));
            if(campaign.status!="ACTIVE") throw(type="StudyAccess.Conflict",message="Ative a campanha antes de emitir um convite.");
            var expiration=one(db("SELECT (CAST((CAST(:d AS date)+1) AS timestamp) AT TIME ZONE 'America/Sao_Paulo')>clock_timestamp() AS valid",{d=p(expiresOn)}));
            if(!expiration.valid) throw(type="StudyAccess.Validation",message="O prazo de resgate já terminou.");
            if(toString(requestId)!="0") {
                var requested=one(db("SELECT s.id,s.produto_id,s.usuario_id,s.status,lower(btrim(u.email)) AS email FROM estudo.solicitacoes s JOIN public.tb_usuarios u ON u.id=s.usuario_id WHERE s.id=:id FOR UPDATE OF s",{id=idp(requestId)}));
                if(requested.status!="PENDING" || requested.produto_id!=campaign.produto_id || compareNoCase(requested.email,recipient)!=0)
                    throw(type="StudyAccess.Conflict",message="O pedido não está pendente ou o e-mail não corresponde ao solicitante.");
            }
            var created=db("INSERT INTO estudo.vouchers(campanha_id,solicitacao_id,codigo_hash,email_destinatario,expira_em,criado_por,nota)
                VALUES(:c,NULLIF(CAST(:r AS bigint),0),:hash,:email,CAST((CAST(:expires AS date)+1) AS timestamp) AT TIME ZONE 'America/Sao_Paulo',:a,:note)
                ON CONFLICT DO NOTHING RETURNING id,campanha_id,email_destinatario,status,CAST(expira_em AS text) AS expira_em",
                {c=idp(campaignId),r=p(requestId,"cf_sql_bigint"),hash=p(lCase(hash(code,"SHA-256","UTF-8"))),email=p(recipient),expires=p(expiresOn),a=idp(actorId),note=p(trim(note))});
            if(!created.recordCount) throw(type="StudyAccess.Conflict",message="Já existe um convite para este e-mail e campanha ou para este pedido. Para reemitir, revogue o convite anterior e emita sem vincular o mesmo pedido.");
            voucher=one(created);
            if(toString(requestId)!="0") db("UPDATE estudo.solicitacoes SET status='INVITED',decidido_por=:a,decidido_em=clock_timestamp(),nota=:n WHERE id=:id",{a=idp(actorId),n=p(trim(note)),id=idp(requestId)});
            audit(actorId,"CREATE_VOUCHER","voucher",voucher.id,{"campaign_id":toString(campaignId),"request_id":toString(requestId),"expires_on":expiresOn});
        }
        return {"voucher":voucher,"code_once":code};
    }
    public struct function adminDeclineRequest(required any actorId,required any requestId,required string note) {
        actor(actorId,true);idp(requestId);limitText(note,1000,true);var result={};
        transaction {
            actor(actorId,true);
            result=one(db("SELECT id,status FROM estudo.solicitacoes WHERE id=:id FOR UPDATE",{id=idp(requestId)}));
            if(result.status=="INVITED") throw(type="StudyAccess.Conflict",message="O pedido já recebeu um convite. Revogue o voucher para cancelar esse acesso.");
            if(result.status=="PENDING") {
                result=one(db("UPDATE estudo.solicitacoes SET status='DECLINED',decidido_por=:a,decidido_em=clock_timestamp(),nota=:n WHERE id=:id RETURNING id,status",{a=idp(actorId),n=p(trim(note)),id=idp(requestId)}));
                audit(actorId,"DECLINE_REQUEST","request",requestId,{"note":trim(note)});
            }
        }
        return {"request":result};
    }
    private void function revokeGrant(required any actorId,required any accessId,required string note) {
        var changed=db("UPDATE estudo.acessos SET status='REVOKED',revogado_em=clock_timestamp(),revogado_por=:u,motivo=:n WHERE id=:a AND status='ACTIVE' RETURNING id",
            {u=idp(actorId),n=p(trim(note)),a=idp(accessId)});
        if(changed.recordCount) {
            db("UPDATE estudo.beneficios SET status='REVOKED',revogado_em=clock_timestamp(),revogado_por=:u WHERE acesso_id=:a AND status='ELIGIBLE'",{u=idp(actorId),a=idp(accessId)});
            audit(actorId,"REVOKE_ACCESS","access",accessId,{"note":trim(note)});
        }
    }
    public struct function adminRevokeVoucher(required any actorId,required any voucherId,required string note) {
        actor(actorId,true);idp(voucherId);limitText(note,1000,true);var result={};
        transaction {
            actor(actorId,true);
            result=one(db("SELECT id,status FROM estudo.vouchers WHERE id=:id FOR UPDATE",{id=idp(voucherId)}));
            if(result.status!="REVOKED") {
                result=one(db("UPDATE estudo.vouchers SET status='REVOKED',revogado_em=clock_timestamp(),revogado_por=:u WHERE id=:id RETURNING id,status",{u=idp(actorId),id=idp(voucherId)}));
                var grants=rows(db("SELECT id FROM estudo.acessos WHERE voucher_id=:v FOR UPDATE",{v=idp(voucherId)}));
                for(var grant in grants) revokeGrant(actorId,grant.id,note);
                audit(actorId,"REVOKE_VOUCHER","voucher",voucherId,{"note":trim(note)});
            }
        }
        return {"voucher":result};
    }
    public struct function adminRevokeAccess(required any actorId,required any accessId,required string note) {
        actor(actorId,true);idp(accessId);limitText(note,1000,true);var result={};
        transaction {
            actor(actorId,true);
            // Keep the voucher -> access lock order used by redeem and voucher revocation.
            var target=one(db("SELECT voucher_id FROM estudo.acessos WHERE id=:id",{id=idp(accessId)}));
            db("SELECT id FROM estudo.vouchers WHERE id=:id FOR UPDATE",{id=idp(target.voucher_id)});
            one(db("SELECT id FROM estudo.acessos WHERE id=:id FOR UPDATE",{id=idp(accessId)}));
            revokeGrant(actorId,accessId,note);
            result=one(db("SELECT id,status FROM estudo.acessos WHERE id=:id",{id=idp(accessId)}));
        }
        return {"access":result};
    }
}
