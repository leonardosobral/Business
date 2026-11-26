component output=false {
    variables.ds="runner_dba";

    public struct function categories() {
        return {elite="Atleta de elite",influencer="Influencer / criador",imprensa="Imprensa",parceiro="Parceiro",equipe="Equipe",cortesia="Cortesia",outro="Outro motivo",nao_informado="Motivo não informado"};
    }

    public string function selectionCategories() {
        // Keep the existing editor usable while the additive migration is pending.
        if(!structKeyExists(variables,"eliteReady")) {
            var q=queryExecute("SELECT EXISTS (SELECT 1 FROM pg_catalog.pg_constraint
                WHERE conrelid=to_regclass('rr_verified.admin_classifications')
                AND conname='admin_classifications_category_check' AND contype='c'
                AND position('''elite''' in pg_get_constraintdef(oid))>0) AS ready",{},{datasource=variables.ds});
            variables.eliteReady=q.ready;
        }
        return (variables.eliteReady ? "elite," : "") & "influencer,imprensa,parceiro,equipe,cortesia,outro";
    }

    public boolean function classificationReady() {
        var q=queryExecute("SELECT to_regclass('rr_verified.admin_classifications') IS NOT NULL
            AND to_regprocedure('rr_verified.classify_permanent_badge(integer,text,text,integer,bigint)') IS NOT NULL AS ready",{}, {datasource=variables.ds});
        return q.ready;
    }

    private string function sourceSql() {
        // Product ownership remains with Road Runners. Status comes from profile_status.
        return "WITH sources AS (
            SELECT pg.id_pagina AS profile_id,'manual'::text AS kind,'active'::text AS source_state,
                   ''::text AS order_id,NULL::integer AS amount_cents,
                   (SELECT min(g.starts_at) FROM rr_verified.grants g WHERE g.profile_id=pg.id_pagina AND g.origin='legacy') AS starts_at,
                   NULL::timestamptz AS ends_at
              FROM public.tb_paginas pg WHERE pg.verificado IS TRUE OR EXISTS (
                SELECT 1 FROM rr_verified.grants g WHERE g.profile_id=pg.id_pagina AND g.origin='legacy'
                AND NOT EXISTS (SELECT 1 FROM rr_verified.legacy_reclassifications r WHERE r.profile_id=g.profile_id))
            UNION ALL
            SELECT c.profile_id,CASE WHEN c.product_code='todosantodiaupg' THEN 'upgrade' ELSE 'vip' END,
                   c.state,c.provider_order_id,c.amount_cents,c.paid_at,c.ends_at FROM rr_verified.challenge_orders c
            UNION ALL
            SELECT o.profile_id,'annual',CASE WHEN g.revoked_at IS NOT NULL THEN 'refunded' ELSE o.state END,
                   coalesce(o.provider_order_id,''),o.amount_cents,coalesce(g.starts_at,o.paid_at),g.ends_at
              FROM rr_verified.orders o LEFT JOIN rr_verified.grants g ON g.order_id=o.id AND g.origin='paid'
        ), candidates AS (SELECT DISTINCT profile_id FROM sources),
        confirmed_registrations AS (
            SELECT DISTINCT pu.id_pagina AS profile_id,d.produto AS product_code,d.data_inscricao AS registered_at,
                coalesce(nullif(trim(d.num_pedido),''),'') AS order_ref,
                coalesce(d.obs_pedido,'') ~* '(cancelad|estorn)' AS cancellation_note
            FROM public.tb_paginas_usuarios pu JOIN public.desafios d ON d.id_usuario=pu.id_usuario
            WHERE pu.id_usuario>0 AND d.desafio='todosantodia' AND d.status='C'
                AND d.produto IN ('todosantodiavip','todosantodiaupg')
        ), vip_reviews AS (
            SELECT DISTINCT ON(entity_id) entity_id,details->>'reason' AS reason_code,
                details->>'status'='pending' AS review_pending
            FROM crm_interno.audit WHERE action='verified.vip_review' ORDER BY entity_id,id DESC
        ), user_links AS (
            SELECT DISTINCT c.profile_id,pu.id_usuario AS user_id FROM candidates c
            JOIN public.tb_paginas_usuarios pu ON pu.id_pagina=c.profile_id WHERE pu.id_usuario>0
        ), challenge_facts AS (
            SELECT u.profile_id,count(*) AS registrations,
                bool_or(d.desafio='todosantodia' AND d.produto IN ('todosantodiavip','todosantodiaupg') AND d.status IS DISTINCT FROM 'C') AS vip_unconfirmed,
                bool_or(d.produto='inscricao365vip' AND d.status='C') AS historic_vip,
                bool_or(d.desafio='todosantodia' AND d.produto='todosantodia' AND d.status='C') AS basic_confirmed
            FROM user_links u JOIN public.desafios d ON d.id_usuario=u.user_id GROUP BY u.profile_id
        ), legacy_facts AS (
            SELECT u.profile_id,count(*) AS registrations,bool_or(d.produto='inscricao365vip' AND d.status='C') AS historic_vip
            FROM user_links u JOIN public.desafio_cna d ON d.id_usuario=u.user_id GROUP BY u.profile_id
        ) ";
    }

    public struct function overview(struct filters={}) {
        var ready=classificationReady();
        var params={};
        var where=" WHERE 1=1 ";
        var status=arguments.filters.status ?: "active";
        var origin=arguments.filters.origin ?: "";
        var evidence=lcase(trim(arguments.filters.evidence ?: ""));
        var search=left(trim(arguments.filters.search ?: ""),120);
        var page=max(1,int(val(arguments.filters.page ?: 1)));
        var classification=ready ? "LEFT JOIN LATERAL (SELECT category,reason,revision FROM rr_verified.admin_classifications WHERE profile_id=pg.id_pagina ORDER BY revision DESC LIMIT 1) cl ON true" : "LEFT JOIN LATERAL (SELECT 'nao_informado'::text AS category,''::text AS reason,0::bigint AS revision) cl ON true";
        var base=sourceSql() & ", profile_data AS MATERIALIZED (
            SELECT pg.id_pagina AS profile_id,coalesce(nullif(pg.nome,''),u.name,'Perfil sem nome') AS name,
                   coalesce(pg.tag,'') AS tag,coalesce(u.email,'') AS email,coalesce(u.id,0) AS user_id,
                   coalesce(u.is_admin,false) AS is_admin,coalesce(u.is_dev,false) AS is_dev,coalesce(u.is_partner,false) AS is_partner,
                   st.active,st.permanent,st.status,
                   coalesce(cf.vip_unconfirmed,false) AS evidence_vip_unconfirmed,
                   coalesce(cf.historic_vip,false) OR coalesce(lf.historic_vip,false) AS evidence_historic_vip,
                   coalesce(cf.basic_confirmed,false) AS evidence_basic,
                   coalesce(cf.registrations,0)+coalesce(lf.registrations,0)=0 AS evidence_none,
                   length(trim(coalesce(pg.descricao,'')))>0 AS evidence_bio,
                   (coalesce(pg.instagram_publico,false) AND length(trim(coalesce(pg.instagram,'')))>0) AS evidence_social,
                   coalesce(vr.review_pending,false) AS vip_review_pending,coalesce(vr.reason_code,'') AS vip_review_reason,
                   coalesce(to_char((st.valid_until-interval '1 second') AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY'),'') AS valid_until,
                   coalesce(cl.category,'nao_informado') AS category,coalesce(cl.reason,'') AS reason,coalesce(cl.revision,0) AS revision,
                   EXISTS (SELECT 1 FROM sources x WHERE x.profile_id=pg.id_pagina AND x.kind='vip' AND x.source_state='paid' AND x.starts_at<=now() AND x.ends_at>now()) AS vip,
                   EXISTS (SELECT 1 FROM sources x WHERE x.profile_id=pg.id_pagina AND x.kind='upgrade' AND x.source_state='paid' AND x.starts_at<=now() AND x.ends_at>now()) AS upgrade,
                   EXISTS (SELECT 1 FROM sources x WHERE x.profile_id=pg.id_pagina AND x.kind='annual' AND x.source_state='paid' AND x.starts_at<=now() AND x.ends_at>now()) AS annual,
                   EXISTS (SELECT 1 FROM sources x WHERE x.profile_id=pg.id_pagina AND x.source_state='refunded') AS has_refund,
                   EXISTS (SELECT 1 FROM confirmed_registrations x WHERE x.profile_id=pg.id_pagina AND x.product_code='todosantodiavip') AS registered_vip,
                   EXISTS (SELECT 1 FROM confirmed_registrations x WHERE x.profile_id=pg.id_pagina AND x.product_code='todosantodiaupg') AS registered_upgrade,
                   EXISTS (SELECT 1 FROM confirmed_registrations x WHERE x.profile_id=pg.id_pagina AND x.cancellation_note) AS registration_alert,
                   EXISTS (SELECT 1 FROM confirmed_registrations x WHERE x.profile_id=pg.id_pagina AND NOT EXISTS (
                     SELECT 1 FROM rr_verified.challenge_orders co WHERE co.profile_id=x.profile_id AND (co.product_code=x.product_code OR x.product_code='todosantodiavip' AND co.product_code='todosantodiaupg'))) AS registration_review
              FROM candidates c JOIN public.tb_paginas pg ON pg.id_pagina=c.profile_id
              CROSS JOIN LATERAL rr_verified.profile_status(pg.id_pagina) st
              LEFT JOIN LATERAL (SELECT usr.id,usr.name,usr.email,usr.is_admin,usr.is_dev,usr.is_partner
                FROM public.tb_paginas_usuarios pu JOIN public.tb_usuarios usr ON usr.id=pu.id_usuario
                WHERE pu.id_pagina=pg.id_pagina ORDER BY (usr.id=pg.id_usuario_cadastro) DESC NULLS LAST,usr.id LIMIT 1) u ON true
              LEFT JOIN vip_reviews vr ON vr.entity_id=pg.id_pagina::text
              LEFT JOIN challenge_facts cf ON cf.profile_id=pg.id_pagina
              LEFT JOIN legacy_facts lf ON lf.profile_id=pg.id_pagina
              " & classification & "), profiles AS MATERIALIZED (
                SELECT *,permanent AND category='nao_informado' AND NOT
                    (registered_vip OR registered_upgrade OR vip OR upgrade OR annual) AS needs_classification,
                    registration_review AND vip_review_pending AS vip_review,
                    registration_review AND NOT vip_review_pending AS reconciliation_pending
                FROM profile_data) ";
        if(status=="active")where&=" AND active ";
        else if(status=="inactive")where&=" AND NOT active ";
        else if(status=="unclassified")where&=" AND needs_classification ";
        else if(status=="reconcile")where&=" AND reconciliation_pending ";
        else if(status=="divergent")where&=" AND vip_review ";
        if(listFind("vip_unconfirmed,historic_vip,basic,none,bio,social",evidence))where&=" AND evidence_" & evidence & " ";
        if(len(origin)) {
            if(listFind("vip,upgrade,annual",origin))where&=" AND " & origin & " ";
            else if(origin=="manual")where&=" AND permanent ";
            else if(origin=="refunded")where&=" AND has_refund ";
            else if(origin=="registered_vip")where&=" AND (registered_vip OR registered_upgrade) ";
            else if(origin=="nao_informado")where&=" AND needs_classification ";
            else if(structKeyExists(categories(),origin)) {where&=" AND permanent AND category=:category ";params.category={value=origin,cfsqltype="cf_sql_varchar"};}
        }
        if(len(search)) {
            where&=" AND (unaccent(name) ILIKE unaccent(:search) ESCAPE '!' OR unaccent(email) ILIKE unaccent(:search) ESCAPE '!' OR tag ILIKE :search ESCAPE '!' OR profile_id::text=:exact OR user_id::text=:exact) ";
            params.search={value="%" & replace(replace(replace(search,"!","!!","all"),"%","!%","all"),"_","!_","all") & "%",cfsqltype="cf_sql_varchar"};
            params.exact={value=search,cfsqltype="cf_sql_varchar"};
        }
        var rules=[];
        for(var flag in ["admin","dev","partner"])if(arguments.filters[flag] ?: false)arrayAppend(rules,"is_" & flag);
        if(len(arguments.filters.desafio ?: "") OR len(arguments.filters.produto ?: "")) {
            var challengeRule="EXISTS (SELECT 1 FROM desafios d WHERE d.id_usuario=profiles.user_id";
            for(var field in ["desafio","produto"])if(len(arguments.filters[field] ?: "")) {
                challengeRule&=" AND d." & field & "=:" & field;
                params[field]={value=arguments.filters[field],cfsqltype="cf_sql_varchar"};
            }
            arrayAppend(rules,challengeRule & ")");
        }
        if(arrayLen(rules))where&=" AND (" & arrayToList(rules,(arguments.filters.logic ?: "any")=="all" ? " AND " : " OR ") & ")";
        params.page={value=page,cfsqltype="cf_sql_integer"};
        var result=queryExecute(base & ", filtered AS MATERIALIZED (SELECT * FROM profiles" & where & "),
            summary AS (SELECT count(*) FILTER(WHERE active) AS active,count(*) FILTER(WHERE permanent) AS permanent,
                count(*) FILTER(WHERE active AND NOT permanent) AS annual,
                count(*) FILTER(WHERE needs_classification) AS unclassified,
                count(*) FILTER(WHERE reconciliation_pending) AS reconcile,
                count(*) FILTER(WHERE vip_review) AS divergent,
                count(*) FILTER(WHERE needs_classification AND evidence_vip_unconfirmed) AS pending_vip_unconfirmed,
                count(*) FILTER(WHERE needs_classification AND evidence_historic_vip) AS pending_historic_vip,
                count(*) FILTER(WHERE needs_classification AND evidence_basic) AS pending_basic,
                count(*) FILTER(WHERE needs_classification AND evidence_none) AS pending_none,
                count(*) FILTER(WHERE needs_classification AND evidence_bio) AS pending_bio,
                count(*) FILTER(WHERE needs_classification AND evidence_social) AS pending_social,
                count(*) FILTER(WHERE NOT active) AS inactive FROM profiles),
            counts AS (SELECT count(*) AS total,greatest(1,ceil(count(*)/40.0))::integer AS pages FROM filtered),
            paging AS (SELECT total,pages,least(:page,pages) AS page FROM counts)
            SELECT (SELECT row_to_json(summary)::text FROM summary) AS totals_json,paging.total,paging.pages,paging.page,
                coalesce((SELECT json_agg(r)::text FROM (SELECT * FROM filtered ORDER BY upper(name),profile_id
                    LIMIT 40 OFFSET (SELECT (page-1)*40 FROM paging)) r),'[]') AS rows_json
            FROM paging",params,{datasource=variables.ds});
        var output={rows=deserializeJSON(result.rows_json),totals=deserializeJSON(result.totals_json),total=result.total,
            page=result.page,pages=result.pages,ready=ready};
        var profileIds=[];for(var profile in output.rows)arrayAppend(profileIds,profile.profile_id);
        output.context=contextForProfiles(profileIds);
        return output;
    }

    public struct function detail(required numeric profileId) {
        var p={id={value=int(arguments.profileId),cfsqltype="cf_sql_integer"}};
        var profile=queryExecute("SELECT pg.id_pagina AS profile_id,coalesce(pg.nome,'Perfil sem nome') AS name,coalesce(pg.tag,'') AS tag,
            s.active,s.permanent,s.status,coalesce(to_char((s.valid_until-interval '1 second') AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY'),'') AS valid_until
            FROM public.tb_paginas pg CROSS JOIN LATERAL rr_verified.profile_status(pg.id_pagina) s WHERE pg.id_pagina=:id",p,{datasource=variables.ds,returntype="array"});
        if(!arrayLen(profile))return {};
        var result={profile=profile[1],history=[],current={revision=0,category="nao_informado",reason=""}};
        result.sources=queryExecute(sourceSql() & "SELECT kind,source_state,order_id,coalesce(amount_cents,0) AS amount_cents,
            coalesce(to_char(starts_at AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY HH24:MI'),'') AS paid_at,
            coalesce(to_char((ends_at-interval '1 second') AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY'),'') AS ends_at,
            (kind='manual' OR (source_state='paid' AND starts_at<=now() AND ends_at>now())) AS active
            FROM sources WHERE profile_id=:id ORDER BY starts_at DESC NULLS LAST,kind,order_id",p,{datasource=variables.ds,returntype="array"});
        // Registration identifies the relationship, not payment date or entitlement duration.
        result.registrations=queryExecute(sourceSql() & "SELECT product_code,
            coalesce(to_char(registered_at,'DD/MM/YYYY HH24:MI'),'') AS registered_at,order_ref,cancellation_note,
            EXISTS (SELECT 1 FROM rr_verified.challenge_orders co WHERE co.profile_id=r.profile_id AND (co.product_code=r.product_code OR r.product_code='todosantodiavip' AND co.product_code='todosantodiaupg')) AS reconciled
            FROM confirmed_registrations r WHERE profile_id=:id ORDER BY registered_at DESC,product_code",p,{datasource=variables.ds,returntype="array"});
        result.vipReview=queryExecute(sourceSql() & "SELECT reason_code FROM vip_reviews WHERE entity_id=CAST(:id AS text) AND review_pending
            AND EXISTS (SELECT 1 FROM confirmed_registrations r WHERE r.profile_id=:id AND NOT EXISTS (
                SELECT 1 FROM rr_verified.challenge_orders co WHERE co.profile_id=r.profile_id AND
                (co.product_code=r.product_code OR r.product_code='todosantodiavip' AND co.product_code='todosantodiaupg')))",p,{datasource=variables.ds,returntype="array"});
        if(classificationReady()) {
            result.history=queryExecute("SELECT c.revision,c.category,c.reason,coalesce(u.name,'Administrador') AS actor,
                to_char(c.recorded_at AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY HH24:MI') AS recorded_at
                FROM rr_verified.admin_classifications c LEFT JOIN public.tb_usuarios u ON u.id=c.actor_id
                WHERE c.profile_id=:id ORDER BY c.revision DESC",p,{datasource=variables.ds,returntype="array"});
            if(arrayLen(result.history))result.current=result.history[1];
        }
        var context=contextForProfiles([arguments.profileId]);
        result.context=context[arguments.profileId & ""];
        return result;
    }

    private string function contextProductLabel(required string code,required string fallback) {
        var labels={todosantodia="Todo Santo Dia · Anuidade Básica",todosantodiavip="Todo Santo Dia · Anuidade VIP",todosantodiaupg="Todo Santo Dia · Upgrade para VIP",inscricao365="Desafio 365 · Inscrição",inscricao365vip="Desafio 365 · VIP",inscricao366="Desafio 366 · Inscrição"};
        return labels[arguments.code] ?: arguments.fallback;
    }

    // Context supports a human decision; none of these queries grants or classifies a badge.
    public struct function contextForProfiles(required array profileIds) {
        var output={};var ids=[];
        if(arrayLen(arguments.profileIds)>100)throw(type="VerifiedAdmin.Validation",message="Consulta de contexto muito ampla.");
        for(var id in arguments.profileIds) {
            if(!isValid("integer",id) OR id<1)throw(type="VerifiedAdmin.Validation",message="Perfil inválido.");
            if(!structKeyExists(output,id & "")) {
                arrayAppend(ids,id);output[id & ""]={profile={},accounts=[],registrations=[],legacy=[],payments=[]};
            }
        }
        if(!arrayLen(ids))return output;
        var p={ids={value=arrayToList(ids),cfsqltype="cf_sql_integer",list=true}};
        var users="WITH users AS (SELECT DISTINCT id_pagina AS profile_id,id_usuario AS user_id FROM public.tb_paginas_usuarios WHERE id_usuario>0 AND id_pagina IN (:ids)) ";
        var rows=queryExecute("SELECT id_pagina AS profile_id,coalesce(cidade,'') AS city,coalesce(uf,'') AS state,
            left(coalesce(descricao,''),2000) AS bio,coalesce(profissional,false) AS professional,
            CASE WHEN instagram_publico THEN coalesce(instagram,'') ELSE '' END AS instagram
            FROM public.tb_paginas WHERE id_pagina IN (:ids)",p,{datasource=variables.ds,returntype="array"});
        for(var row in rows)output[row.profile_id & ""].profile=row;
        rows=queryExecute(users & "SELECT u.profile_id,t.id AS user_id,to_char(t.data_criacao,'DD/MM/YYYY') AS created_at,
            coalesce(t.is_admin,false) AS is_admin,coalesce(t.is_dev,false) AS is_dev,coalesce(t.is_partner,false) AS is_partner,
            left(coalesce(t.assessoria,''),180) AS coaching
            FROM users u JOIN public.tb_usuarios t ON t.id=u.user_id ORDER BY t.id",p,{datasource=variables.ds,returntype="array"});
        for(var row in rows)arrayAppend(output[row.profile_id & ""].accounts,row);
        rows=queryExecute(users & "SELECT u.profile_id,coalesce(d.desafio,'') AS challenge_code,coalesce(d.produto,'') AS product_code,
            coalesce(e.titulo,d.desafio,'Desafio') AS challenge_name,coalesce(pr.nome_produto,d.produto,'Inscrição') AS product_name,
            coalesce(d.status,'') AS status,coalesce(to_char(d.data_inscricao,'DD/MM/YYYY HH24:MI'),'') AS registered_at,
            coalesce(d.num_pedido,'') AS order_ref,
            CASE WHEN coalesce(d.obs_pedido,'') ~* '(cancelad|estorn)' THEN 'Há anotação de cancelamento ou estorno.'
                 WHEN coalesce(d.obs_pedido,'') ~* 'upgrade' THEN 'Há anotação de upgrade.' ELSE '' END AS note
            FROM users u JOIN public.desafios d ON d.id_usuario=u.user_id
            LEFT JOIN LATERAL(SELECT titulo FROM public.desafios_eventos WHERE tag=d.desafio ORDER BY id_desafio LIMIT 1) e ON true
            LEFT JOIN LATERAL(SELECT nome_produto FROM public.desafios_produtos WHERE codigo_produto=d.produto ORDER BY (desafio=d.desafio) DESC NULLS LAST,id_produto LIMIT 1) pr ON true
            ORDER BY u.profile_id,d.data_inscricao DESC NULLS LAST,d.desafio,d.produto",p,{datasource=variables.ds,returntype="array"});
        for(var row in rows){row.product_name=contextProductLabel(row.product_code,row.challenge_name & " · " & row.product_name);arrayAppend(output[row.profile_id & ""].registrations,row);}
        rows=queryExecute(users & "SELECT u.profile_id,coalesce(d.produto,'') AS product_code,
            coalesce(pr.nome_produto,d.produto,'Inscrição') AS product_name,coalesce(d.status,'') AS status,
            coalesce(to_char(d.data_inscricao,'DD/MM/YYYY HH24:MI'),'') AS registered_at,coalesce(d.num_pedido,'') AS order_ref
            FROM users u JOIN public.desafio_cna d ON d.id_usuario=u.user_id
            LEFT JOIN LATERAL(SELECT nome_produto FROM public.desafios_produtos WHERE codigo_produto=d.produto ORDER BY id_produto LIMIT 1) pr ON true
            ORDER BY u.profile_id,d.data_inscricao DESC NULLS LAST,d.produto",p,{datasource=variables.ds,returntype="array"});
        for(var row in rows){row.product_name=contextProductLabel(row.product_code,row.product_name);arrayAppend(output[row.profile_id & ""].legacy,row);}
        rows=queryExecute(users & ", events AS (
            SELECT u.profile_id,t.json_transacao->'data'->>'id' AS order_id,
                t.json_transacao->'data'->'items'->0->>'code' AS product_code,
                bool_or(t.status_atual='order.paid') AS paid_event,
                bool_or(t.status_atual='order.canceled' OR t.json_transacao->'data'->>'status'='canceled') AS cancellation_event,
                bool_or(t.status_atual='order.payment_failed' OR t.json_transacao->'data'->>'status'='failed') AS failed_event,
                max(t.data_ultima_alteracao) AS last_event
            FROM users u JOIN public.tb_transacoes t ON t.id_usuario=u.user_id
            WHERE t.origem_transacao='pagarme' AND t.json_transacao->'data'->>'id' ~ '^or_[A-Za-z0-9]+$'
                AND t.json_transacao->'data'->'items'->0->>'code' IN ('todosantodia','todosantodiavip','todosantodiaupg','inscricao365','inscricao365vip','inscricao366')
            GROUP BY u.profile_id,t.json_transacao->'data'->>'id',t.json_transacao->'data'->'items'->0->>'code')
            SELECT e.*,coalesce(pr.nome_produto,e.product_code) AS product_name,
                coalesce(to_char(e.last_event,'DD/MM/YYYY HH24:MI'),'') AS recorded_at,
                CASE WHEN s.classification=a.classification AND s.status=s.classification AND s.status IN ('confirmed','refunded')
                    AND s.product_code=e.product_code AND a.product_code=e.product_code AND a.last_verified_at IS NOT NULL THEN s.status ELSE '' END AS reconciled_status,
                coalesce(to_char(a.last_verified_at AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY HH24:MI'),'') AS verified_at
            FROM events e LEFT JOIN crm_interno.conversion_order_state s ON s.source='pagarme' AND s.account_scope='roadrunners' AND s.order_key=e.order_id
            LEFT JOIN crm_interno.pagarme_order_audit a ON a.provider_order_id=e.order_id
            LEFT JOIN LATERAL(SELECT nome_produto FROM public.desafios_produtos WHERE codigo_produto=e.product_code ORDER BY id_produto LIMIT 1) pr ON true
            ORDER BY e.profile_id,e.last_event DESC NULLS LAST,e.order_id",p,{datasource=variables.ds,returntype="array"});
        for(var row in rows){row.product_name=contextProductLabel(row.product_code,row.product_name);arrayAppend(output[row.profile_id & ""].payments,row);}
        return output;
    }

    public void function classify(required numeric profileId,required string category,required string reason,required numeric actorId,required numeric revision) {
        if(!structKeyExists(categories(),arguments.category) OR len(trim(arguments.reason))<5 OR len(trim(arguments.reason))>2000)
            throw(type="VerifiedAdmin.Validation",message="Escolha uma categoria e informe um motivo de 5 a 2.000 caracteres.");
        queryExecute("SELECT rr_verified.classify_permanent_badge(:profile,:category,:reason,:actor,:revision)",{
            profile={value=int(arguments.profileId),cfsqltype="cf_sql_integer"},category={value=arguments.category,cfsqltype="cf_sql_varchar"},
            reason={value=trim(arguments.reason),cfsqltype="cf_sql_varchar"},actor={value=int(arguments.actorId),cfsqltype="cf_sql_integer"},
            revision={value=arguments.revision,cfsqltype="cf_sql_bigint"}},{datasource=variables.ds});
    }

    public array function quickSelection(required string selection) {
        var entries=[];
        var seen={};
        var tokens=listToArray(arguments.selection,",",true);
        if(arrayLen(tokens)<1 OR arrayLen(tokens)>40)
            throw(type="VerifiedAdmin.Validation",message="Selecione de 1 a 40 pessoas desta página.");
        for(var token in tokens) {
            if(!reFind("^[1-9][0-9]{0,8}:[0-9]{1,18}$",token))
                throw(type="VerifiedAdmin.Validation",message="Seleção inválida. Atualize a lista e selecione novamente.");
            var id=listFirst(token,":");
            if(structKeyExists(seen,id))throw(type="VerifiedAdmin.Validation",message="Uma pessoa foi selecionada mais de uma vez.");
            seen[id]=true;
            arrayAppend(entries,{profileId=int(id),revision=listLast(token,":")});
        }
        // Consistent lock order prevents two overlapping batches from deadlocking.
        arraySort(entries,function(a,b){return a.profileId-b.profileId;});
        return entries;
    }

    public string function quickReason(required string category,string note="") {
        var labels=categories();
        var noteText=trim(arguments.note);
        if(!structKeyExists(labels,arguments.category) OR arguments.category=="nao_informado")
            throw(type="VerifiedAdmin.Validation",message="Escolha o motivo da concessão.");
        if(len(noteText)>1800)throw(type="VerifiedAdmin.Validation",message="Use até 1.800 caracteres na observação.");
        if(arguments.category=="outro" AND !len(noteText))
            throw(type="VerifiedAdmin.Validation",message="Descreva o motivo ao escolher Outro motivo.");
        return labels[arguments.category] & (len(noteText) ? " — " & noteText : "");
    }

    public numeric function classifyQuick(required string selection,required string category,string note="",required numeric actorId) {
        var entries=quickSelection(arguments.selection);
        var reason=quickReason(arguments.category,arguments.note);
        transaction {
            for(var entry in entries)
                classify(entry.profileId,arguments.category,reason,arguments.actorId,entry.revision);
        }
        return arrayLen(entries);
    }
}
