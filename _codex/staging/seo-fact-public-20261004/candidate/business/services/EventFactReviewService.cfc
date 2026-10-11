component output="false" {
    public void function authorize(required boolean isAdmin, required boolean delegated, boolean isPost=false, boolean csrfVerified=false, boolean write=false) {
        if (!isAdmin OR delegated) throw(type="FactReview.Forbidden", message="A revisão de fontes é restrita à administração interna.");
        if (write AND (!isPost OR !csrfVerified)) throw(type="FactReview.Validation", message="Reabra a aba Fontes e revisões e tente novamente.");
    }
    public numeric function identifier(required any value) {
        if (!isSimpleValue(value) OR !reFind("^[1-9][0-9]{0,9}$",value & "") OR val(value)>2147483647)
            throw(type="FactReview.Validation",message="Selecione um evento ou registro válido.");
        return val(value);
    }
    public struct function groups() {
        return {datas={label="Datas do evento",fields="data_inicial,data_final"},local={label="Local do evento",fields="cidade,estado,pais,endereco,coordenadas"},situacao={label="Situação do evento",fields="status_evento"}};
    }
    public struct function labels() {
        return {data_inicial="Início",data_final="Término",cidade="Cidade",estado="Estado",pais="País",endereco="Endereço",coordenadas="Coordenadas",status_evento="Situação",id_evento="ID do evento",id_evento_percurso="ID do percurso",nome_evento="Nome",tag="Endereço da página",categorias="Categorias",tipo_corrida="Tipo de corrida",url_hotsite="Site oficial",url_regulamento="Regulamento",url_inscricao="Inscrição",ativo="Ativo",percurso_evento="Distância",unidade_de_medida="Unidade",data_percurso="Data do percurso",hora_largada="Largada",hora_corte="Corte"};
    }
    private string function snapshotSql() {
        return "jsonb_build_object('datas',jsonb_build_object('data_inicial',data_inicial,'data_final',data_final),'local',jsonb_build_object('cidade',cidade,'estado',estado,'pais',pais,'endereco',endereco,'coordenadas',coordenadas),'situacao',jsonb_build_object('status_evento',status_evento))";
    }
    public boolean function isSchemaReady() {
        var q=queryExecute("SELECT to_regclass('public.tb_evento_fatos_revisao') IS NOT NULL AND to_regclass('public.tb_evento_fatos_historico') IS NOT NULL AS ready",{},{datasource="runner_dba"});
        return q.ready;
    }
    public string function displayValue(required struct data, required string key) {
        if (!structKeyExists(data,key) OR isNull(data[key])) return "Não informado";
        if (!isSimpleValue(data[key])) return serializeJSON(data[key]);
        if (!len(data[key] & "")) return "Não informado";
        return data[key] & "";
    }
    public struct function load(required any eventId, required boolean isAdmin, required boolean delegated) {
        authorize(isAdmin,delegated);
        var id=identifier(eventId);
        var q=queryExecute("SELECT " & snapshotSql() & " AS snapshots, to_jsonb(e)->>'conferencia_datas_publica' AS public_review, md5((" & snapshotSql() & "->'datas')::text) AS datas_hash, md5((" & snapshotSql() & "->'local')::text) AS local_hash, md5((" & snapshotSql() & "->'situacao')::text) AS situacao_hash FROM public.tb_evento_corridas e WHERE id_evento=:id",{id={value=id,cfsqltype="cf_sql_integer"}},{datasource="runner_dba"});
        if (!q.recordCount) throw(type="FactReview.Validation",message="Evento não encontrado.");
        var result={publicDateReview=q.public_review & "",snapshots=deserializeJSON(q.snapshots),versions={datas=q.datas_hash,local=q.local_hash,situacao=q.situacao_hash}};
        // JSON key casing must come from PostgreSQL, not a reserialized CF struct.
        result.reviews=queryExecute("SELECT NOT EXISTS(SELECT 1 FROM public.tb_evento_fatos_revisao newer WHERE newer.id_evento=r.id_evento AND newer.grupo=r.grupo AND newer.id_revisao>r.id_revisao) AS is_latest,r.id_revisao,r.grupo,r.fatos::text,r.fonte_url,to_char(r.registrado_em AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY HH24:MI') AS revisado,r.revogado_em IS NOT NULL AS revoked,(r.fatos=(" & snapshotSql() & "->r.grupo)) AS matches FROM public.tb_evento_fatos_revisao r JOIN public.tb_evento_corridas e ON e.id_evento=r.id_evento WHERE r.id_evento=:id AND (r.id_revisao IN (SELECT recent.id_revisao FROM public.tb_evento_fatos_revisao recent WHERE recent.id_evento=:id ORDER BY recent.id_revisao DESC LIMIT 10) OR NOT EXISTS(SELECT 1 FROM public.tb_evento_fatos_revisao newer WHERE newer.id_evento=r.id_evento AND newer.grupo=r.grupo AND newer.id_revisao>r.id_revisao)) ORDER BY r.id_revisao DESC",{id={value=id,cfsqltype="cf_sql_integer"}},{datasource="runner_dba"});
        result.history=queryExecute("SELECT id_historico,entidade,id_entidade,operacao,alteracoes::text,to_char(registrado_em AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY HH24:MI') AS registrado FROM public.tb_evento_fatos_historico WHERE id_evento=:id OR id_evento_anterior=:id ORDER BY id_historico DESC LIMIT 20",{id={value=id,cfsqltype="cf_sql_integer"}},{datasource="runner_dba"});
        return result;
    }
    public struct function validate(required struct submitted, required boolean isAdmin, required boolean delegated, required boolean isPost, required boolean csrfVerified) {
        authorize(isAdmin,delegated,isPost,csrfVerified,true);
        for(var field in ['grupo','source_url','version','request_id','confirmed']) {
            if(!structKeyExists(submitted,field) OR !isSimpleValue(submitted[field])) throw(type="FactReview.Validation",message="Preencha a fonte e confirme a conferência dos valores exibidos.");
        }
        if(!structKeyExists(groups(),submitted.grupo) OR !listFind('datas,local,situacao',submitted.grupo) OR submitted.confirmed!='1') throw(type="FactReview.Validation",message="Selecione os dados conferidos e confirme a consulta à fonte.");
        var source=trim(submitted.source_url);
        if(!new services.EventRegistrationAvailability().isSourceUrl(source)) throw(type="FactReview.Validation",message="Informe uma URL completa de fonte oficial, começando com https:// ou http://.");
        if(!reFind('^[a-f0-9]{32}$',submitted.version) OR !reFindNoCase('^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$',submitted.request_id)) throw(type="FactReview.Validation",message="Reabra a aba para conferir os dados atuais.");
        return {group=submitted.grupo,source=source,version=submitted.version,requestId=lCase(submitted.request_id)};
    }
    public void function save(required any eventId, required struct submitted, required boolean isAdmin, required boolean delegated, required boolean isPost, required boolean csrfVerified) {
        var data=validate(submitted,isAdmin,delegated,isPost,csrfVerified);var id=identifier(eventId);
        transaction {
            var q=queryExecute("SELECT (" & snapshotSql() & "->:group)::text AS snapshot,md5((" & snapshotSql() & "->:group)::text) AS version FROM public.tb_evento_corridas WHERE id_evento=:id FOR UPDATE",{id={value=id,cfsqltype="cf_sql_integer"},group={value=data.group,cfsqltype="cf_sql_varchar"}},{datasource="runner_dba"});
            if(!q.recordCount) throw(type="FactReview.Validation",message="Evento não encontrado.");
            if(compare(q.version,data.version)!=0) throw(type="FactReview.Validation",message="O cadastro mudou enquanto esta aba estava aberta. Confira os valores atualizados e consulte a fonte novamente.");
            var duplicate=queryExecute("SELECT id_evento,grupo,fonte_url,fatos::text,revogado_em IS NOT NULL AS revoked FROM public.tb_evento_fatos_revisao WHERE requisicao=CAST(:request AS uuid)",{request={value=data.requestId,cfsqltype="cf_sql_varchar"}},{datasource="runner_dba"});
            if(duplicate.recordCount) {
                if(duplicate.id_evento!=id OR compare(duplicate.grupo,data.group)!=0 OR compare(duplicate.fonte_url,data.source)!=0 OR compare(duplicate.fatos,q.snapshot)!=0 OR duplicate.revoked) throw(type="FactReview.Validation",message="Essa conferência já foi utilizada. Reabra a aba para registrar outra.");
                return;
            }
            queryExecute("INSERT INTO public.tb_evento_fatos_revisao(id_evento,grupo,fatos,fonte_url,requisicao) VALUES(:id,:group,CAST(:facts AS jsonb),:source,CAST(:request AS uuid))",{id={value=id,cfsqltype="cf_sql_integer"},group={value=data.group,cfsqltype="cf_sql_varchar"},facts={value=q.snapshot,cfsqltype="cf_sql_longvarchar"},source={value=data.source,cfsqltype="cf_sql_varchar"},request={value=data.requestId,cfsqltype="cf_sql_varchar"}},{datasource="runner_dba"});
            // A newer date review supersedes a previously published receipt, without publishing itself.
            if (data.group=="datas") queryExecute("UPDATE public.tb_evento_corridas SET conferencia_datas_publica=jsonb_build_object('version',1,'state','withdrawn') WHERE id_evento=:id AND conferencia_datas_publica IS NOT NULL",{id={value=id,cfsqltype="cf_sql_integer"}},{datasource="runner_dba"});
        }
    }
    private void function lockEvent(required numeric id) {
        var q=queryExecute("SELECT id_evento FROM public.tb_evento_corridas WHERE id_evento=:id FOR UPDATE",{id={value=id,cfsqltype="cf_sql_integer"}},{datasource="runner_dba"});
        if(!q.recordCount) throw(type="FactReview.Validation",message="Evento não encontrado.");
    }
    private void function withdrawDates(required numeric id, required numeric review) {
        queryExecute("UPDATE public.tb_evento_corridas SET conferencia_datas_publica=jsonb_build_object('version',1,'state','withdrawn') WHERE id_evento=:id AND conferencia_datas_publica->>'reviewId'=:review",{id={value=id,cfsqltype="cf_sql_integer"},review={value=review & "",cfsqltype="cf_sql_varchar"}},{datasource="runner_dba"});
    }
    public void function publishDates(required any eventId, required any reviewId, required boolean isAdmin, required boolean delegated, required boolean isPost, required boolean csrfVerified) {
        authorize(isAdmin,delegated,isPost,csrfVerified,true);
        var id=identifier(eventId);var review=identifier(reviewId);
        transaction {
            lockEvent(id);
            var q=queryExecute("SELECT r.id_revisao,r.fonte_url,(r.revogado_em IS NULL AND r.fatos=jsonb_build_object('data_inicial',e.data_inicial,'data_final',e.data_final) AND e.data_inicial IS NOT NULL AND e.data_final IS NOT NULL AND e.data_final>=e.data_inicial AND r.registrado_em<=clock_timestamp()) AS eligible FROM public.tb_evento_fatos_revisao r JOIN public.tb_evento_corridas e ON e.id_evento=r.id_evento WHERE r.id_evento=:id AND r.grupo='datas' ORDER BY r.id_revisao DESC LIMIT 1",{id={value=id,cfsqltype="cf_sql_integer"}},{datasource="runner_dba"});
            if(!q.recordCount OR q.id_revisao!=review OR !q.eligible OR !new services.EventRegistrationAvailability().isSourceUrl(q.fonte_url)) throw(type="FactReview.Validation",message="Somente a última conferência de datas, não retirada e igual ao cadastro atual, pode ser publicada. Confira a fonte novamente se os dados mudaram.");
            // Publish only the allowlisted public receipt; the private review table stays private.
            queryExecute("UPDATE public.tb_evento_corridas e SET conferencia_datas_publica=jsonb_build_object('version',1,'state','published','reviewId',r.id_revisao::text,'startDate',to_char(e.data_inicial,'YYYY-MM-DD'),'endDate',to_char(e.data_final,'YYYY-MM-DD'),'checkedAt',to_char(r.registrado_em AT TIME ZONE 'America/Sao_Paulo','YYYY-MM-DD'),'sourceUrl',r.fonte_url) FROM public.tb_evento_fatos_revisao r WHERE e.id_evento=:id AND r.id_evento=e.id_evento AND r.id_revisao=:review",{id={value=id,cfsqltype="cf_sql_integer"},review={value=review,cfsqltype="cf_sql_bigint"}},{datasource="runner_dba"});
        }
    }
    public void function unpublishDates(required any eventId, required any reviewId, required boolean isAdmin, required boolean delegated, required boolean isPost, required boolean csrfVerified) {
        authorize(isAdmin,delegated,isPost,csrfVerified,true);
        var id=identifier(eventId);var review=identifier(reviewId);
        transaction {
            lockEvent(id);
            var current=queryExecute("SELECT conferencia_datas_publica->>'state' AS state,conferencia_datas_publica->>'reviewId' AS review_id FROM public.tb_evento_corridas WHERE id_evento=:id",{id={value=id,cfsqltype="cf_sql_integer"}},{datasource="runner_dba"});
            if(current.state=="withdrawn") return;
            if(current.state!="published" OR current.review_id!=review) throw(type="FactReview.Validation",message="A publicação mudou enquanto esta aba estava aberta. Atualize a página antes de retirar a fonte atual.");
            withdrawDates(id,review);
        }
    }
    public void function revoke(required any eventId, required any reviewId, required boolean isAdmin, required boolean delegated, required boolean isPost, required boolean csrfVerified) {
        authorize(isAdmin,delegated,isPost,csrfVerified,true);
        var id=identifier(eventId);var review=identifier(reviewId);
        transaction {
            lockEvent(id);
            queryExecute("UPDATE public.tb_evento_fatos_revisao SET revogado_em=clock_timestamp() WHERE id_evento=:event AND id_revisao=:review AND revogado_em IS NULL",{event={value=id,cfsqltype="cf_sql_integer"},review={value=review,cfsqltype="cf_sql_bigint"}},{datasource="runner_dba"});
            withdrawDates(id,review);
        }
    }
}
