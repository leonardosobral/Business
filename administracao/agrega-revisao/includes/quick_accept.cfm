<cfprocessingdirective pageencoding="utf-8" />
<cfscript>
// All writes belong to one transaction: a failed link must not leave an orphan aggregator.
function agregaReviewAcceptSuggestion(required numeric groupId, required string aggregatorName, required numeric reviewerId, required string expectedEventIds) {
    var name = trim(arguments.aggregatorName);
    var opts = {datasource="runner_dba", timeout=10};
    var params = {groupId={value=arguments.groupId,cfsqltype="cf_sql_bigint"}};
    var group = queryNew("id");
    var candidates = queryNew("id");
    var existing = queryNew("id");
    var inserted = queryNew("id");
    var updated = queryNew("id");
    var nameLock = queryNew("acquired");
    var row = 0;
    var eventIds = "";
    var aggregateId = 0;
    var note = "Sugestão aceita na listagem: agregador criado e as duas edições vinculadas.";
    if (arguments.groupId LTE 0 OR arguments.reviewerId LTE 0) {
        throw(type="AgregaReview.Validation", message="Revisão ou administrador inválido.");
    }
    if (!len(name) OR len(name) GT 256) {
        throw(type="AgregaReview.Validation", message="Informe um nome de agregador entre 1 e 256 caracteres.");
    }
    if (!reFind("^[0-9]+,[0-9]+$", arguments.expectedEventIds)) {
        throw(type="AgregaReview.Validation", message="O par mudou. Atualize a lista ou abra a revisão detalhada.");
    }
    transaction {
        group = queryExecute("SELECT group_key,status,candidate_count,suggested_id_agrega_evento FROM tb_evento_agrega_review_groups WHERE id_evento_agrega_review_group=:groupId FOR UPDATE", params, opts);
        if (!group.recordCount) {
            throw(type="AgregaReview.Validation", message="Grupo de revisão não encontrado.");
        }
        if (group.status[1] EQ "applied") {
            return {alreadyApplied=true,idAgregaEvento=val(group.suggested_id_agrega_evento[1])};
        }
        if (group.status[1] NEQ "review" OR left(group.group_key[1],11) NEQ "edicoes-v1:"
            OR val(group.candidate_count[1]) NEQ 2 OR val(group.suggested_id_agrega_evento[1]) GT 0) {
            throw(type="AgregaReview.Validation", message="Este grupo precisa da revisão detalhada. Nenhum vínculo foi alterado.");
        }
        candidates = queryExecute("SELECT c.id_evento,c.status,e.id_agrega_evento,e.ativo FROM tb_evento_agrega_review_candidates c INNER JOIN tb_evento_corridas e ON e.id_evento=c.id_evento WHERE c.id_evento_agrega_review_group=:groupId ORDER BY e.id_evento FOR UPDATE OF c,e", params, opts);
        eventIds = valueList(candidates.id_evento);
        if (candidates.recordCount NEQ 2 OR listSort(eventIds,"numeric") NEQ listSort(arguments.expectedEventIds,"numeric")) {
            throw(type="AgregaReview.Validation", message="As provas deste grupo mudaram. Atualize a lista ou abra a revisão detalhada.");
        }
        for (row=1;row LTE candidates.recordCount;row++) {
            if (candidates.status[row] NEQ "active" OR !candidates.ativo[row] OR val(candidates.id_agrega_evento[row]) GT 0) {
                throw(type="AgregaReview.Validation", message="Uma das provas já foi vinculada ou deixou de estar disponível. Abra a revisão detalhada.");
            }
        }
        params.name = {value=name,cfsqltype="cf_sql_varchar"};
        // Cooperates with the detail form to serialize creation of the same name.
        nameLock = queryExecute("SELECT pg_try_advisory_xact_lock(hashtext('business.agrega-review.name'),hashtext(lower(btrim(:name)))) AS acquired", {name=params.name}, opts);
        if (!nameLock.acquired[1]) {
            throw(type="AgregaReview.Validation", message="Este nome está sendo processado em outra revisão. Tente novamente.");
        }
        existing = queryExecute("SELECT id_agrega_evento FROM tb_agrega_eventos WHERE lower(trim(nome_evento_agregado))=lower(trim(:name)) LIMIT 1", {name=params.name}, opts);
        if (existing.recordCount) {
            throw(type="AgregaReview.Validation", message="Já existe um agregador com esse nome. Use Revisar este par para escolher o existente ou ajuste o nome.");
        }
        inserted = queryExecute("INSERT INTO tb_agrega_eventos (nome_evento_agregado,tipo_agregacao,tag,id_tema,divisao,ordem) VALUES (:name,'corrida',NULL,1,'distancia',300) RETURNING id_agrega_evento", {name=params.name}, opts);
        aggregateId = val(inserted.id_agrega_evento[1]);
        params.aggregateId = {value=aggregateId,cfsqltype="cf_sql_integer"};
        params.ids = {value=eventIds,cfsqltype="cf_sql_integer",list=true};
        params.reviewerId = {value=arguments.reviewerId,cfsqltype="cf_sql_bigint"};
        params.note = {value=note,cfsqltype="cf_sql_longvarchar"};
        updated = queryExecute("UPDATE tb_evento_corridas SET id_agrega_evento=:aggregateId WHERE id_evento IN (:ids) AND id_agrega_evento IS NULL AND ativo=true RETURNING id_evento", {aggregateId=params.aggregateId,ids=params.ids}, opts);
        if (updated.recordCount NEQ 2) {
            throw(type="AgregaReview.Validation", message="Não foi possível vincular as duas provas. Nenhuma alteração foi salva.");
        }
        queryExecute("UPDATE tb_evento_agrega_review_candidates SET status='applied',reviewed_by=:reviewerId,reviewed_at=now(),review_note=:note,data_atualizacao=now() WHERE id_evento_agrega_review_group=:groupId AND status='active'", {groupId=params.groupId,reviewerId=params.reviewerId,note=params.note}, opts);
        queryExecute("UPDATE tb_evento_agrega_review_groups SET status='applied',suggested_id_agrega_evento=:aggregateId,reviewed_by=:reviewerId,reviewed_at=now(),review_note=concat_ws(chr(10),nullif(review_note,''),:note),data_atualizacao=now() WHERE id_evento_agrega_review_group=:groupId", {groupId=params.groupId,aggregateId=params.aggregateId,reviewerId=params.reviewerId,note=params.note}, opts);
    }
    return {alreadyApplied=false,idAgregaEvento=aggregateId};
}
</cfscript>
