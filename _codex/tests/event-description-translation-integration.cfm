<cfscript>
function resetTranslationFixture() {
    resetFixture();
    fixtureSql("UPDATE public.tb_evento_corridas SET descricao='Descrição portuguesa A. Largada às 07:00 para 5 km.'");
}
function translationCounts() {
    include 'api/eventos/jobs/queue.cfm';
    return fixtureSql(eventDescriptionQueueSql() & 'SELECT language,queue_status,count(*) AS total FROM work GROUP BY language,queue_status ORDER BY language,queue_status',
        {event_id={value=0,cfsqltype='cf_sql_integer'},language={value='auto',cfsqltype='cf_sql_varchar'}});
}
resetTranslationFixture();
result = invokeFixture('{"language":"en"}');
check(result.code EQ 200 AND result.payload.dryRun AND result.payload.results[1].language EQ 'en' AND result.payload.results[1].status EQ 'preview', 'Translation dryRun returns target-language preview');
check(fixtureSql('SELECT * FROM public.tb_evento_descricao_translations').recordCount EQ 0 AND fixtureSql('SELECT descricao_en IS NULL AS untouched FROM public.tb_evento_corridas').untouched[1], 'Translation dryRun has no audit or target mutation');

resetTranslationFixture();
result = invokeFixture('{"dryRun":false,"language":"en"}');
check(result.code EQ 200 AND result.payload.updated EQ 1 AND result.payload.results[1].language EQ 'en', 'English translation is published');
audit = fixtureSql('SELECT *,description_before IS NULL AS was_null FROM public.tb_evento_descricao_translations');
event = fixtureSql('SELECT * FROM public.tb_evento_corridas');
check(audit.recordCount EQ 1 AND audit.was_null[1] AND audit.language[1] EQ 'en' AND audit.source_text[1] EQ event.descricao[1], 'Translation audit preserves NULL and exact Portuguese source');
check(fixtureSql('SELECT finished_at > created_at AS later FROM public.tb_evento_descricao_translations').later[1], 'Completion timestamp records the end instead of transaction-start time');
check(fixtureSql("SELECT (descricao_traducoes_meta->'en'->>'source_hash')=md5(descricao) AND (descricao_traducoes_meta->'en'->>'description_hash')=md5(descricao_en) AS valid FROM public.tb_evento_corridas").valid[1], 'English metadata binds exact Portuguese source and exact published English');
check(fixtureSql('SELECT metadata_before IS NULL AS absent FROM public.tb_evento_descricao_translations').absent[1], 'Audit preserves previously absent language metadata');
englishMetadata = fixtureSql("SELECT CAST(descricao_traducoes_meta->'en' AS text) AS metadata FROM public.tb_evento_corridas").metadata[1];
check(event.descricao_original[1] EQ fixtureSource AND event.categorias[1] EQ '5 km' AND event.descricao_en[1] EQ audit.description_after[1], 'Translation changes only its target field');
result = invokeFixture('{"dryRun":false,"language":"en"}');
check(result.payload.selected EQ 0 AND REQUEST.fixtureProviderCalls EQ 1, 'Repeated translation does not spend provider calls');

result = invokeFixture('{"dryRun":false}');
check(result.payload.results[1].language EQ 'es' AND result.payload.updated EQ 1, 'Auto completes Spanish after English');
check(fixtureSql("SELECT CAST(descricao_traducoes_meta->'en' AS text) AS metadata FROM public.tb_evento_corridas").metadata[1] EQ englishMetadata, 'Publishing Spanish preserves English metadata');
check(fixtureSql("SELECT (descricao_traducoes_meta->'es'->>'source_hash')=md5(descricao) AND (descricao_traducoes_meta->'es'->>'description_hash')=md5(descricao_es) AS valid FROM public.tb_evento_corridas").valid[1], 'Spanish metadata binds its own published field');
result = invokeFixture('{"dryRun":false}');
check(result.payload.selected EQ 0 AND REQUEST.fixtureProviderCalls EQ 2, 'Auto leaves completed event idle');

resetTranslationFixture();
originalPortuguese = fixtureSql('SELECT descricao FROM public.tb_evento_corridas').descricao[1];
invokeFixture('{"dryRun":false,"language":"en"}');
firstEnglish = fixtureSql('SELECT descricao_en FROM public.tb_evento_corridas').descricao_en[1];
fixtureSql("UPDATE public.tb_evento_corridas SET descricao='Descrição portuguesa B. Largada às 08:00 para 10 km.'");
result = invokeFixture('{"dryRun":false,"language":"en"}');
check(result.payload.updated EQ 1 AND !result.payload.results[1].reused AND REQUEST.fixtureProviderCalls EQ 2, 'New Portuguese source refreshes cron-owned translation');
check(fixtureSql('SELECT descricao_en FROM public.tb_evento_corridas').descricao_en[1] NEQ firstEnglish, 'New source produces its own translated text');
check(fixtureSql("SELECT metadata_before->>'source_hash' AS source_hash FROM public.tb_evento_descricao_translations ORDER BY id DESC LIMIT 1").source_hash[1] EQ lCase(hash(originalPortuguese,'MD5','UTF-8')), 'Audit snapshots the previous language metadata for guarded rollback');
fixtureSql('UPDATE public.tb_evento_corridas SET descricao=:source',{source={value=originalPortuguese,cfsqltype='cf_sql_longvarchar'}});
result = invokeFixture('{"dryRun":false,"language":"en"}');
check(result.payload.updated EQ 1 AND result.payload.results[1].reused AND REQUEST.fixtureProviderCalls EQ 2 AND fixtureSql('SELECT descricao_en FROM public.tb_evento_corridas').descricao_en[1] EQ firstEnglish, 'Source A-B-A reuses validated A output without another provider request');
check(fixtureSql("SELECT descricao_traducoes_meta->'en'->>'source_hash'=md5(descricao) AS valid FROM public.tb_evento_corridas").valid[1], 'Cache reuse updates metadata to returned source A');
check(fixtureSql('SELECT reused_from_id FROM public.tb_evento_descricao_translations ORDER BY id DESC LIMIT 1').reused_from_id[1] EQ 1, 'Reuse records the original validation audit');

fixtureSql('UPDATE public.tb_evento_corridas SET descricao_en=NULL');
result = invokeFixture('{"language":"en"}');
check(result.code EQ 200 AND result.payload.results[1].reused AND REQUEST.fixtureProviderCalls EQ 2, 'Cleared translation has a no-cost cached preview');
result = invokeFixture('{"dryRun":false,"language":"en"}');
check(result.payload.updated EQ 1 AND result.payload.results[1].reused AND REQUEST.fixtureProviderCalls EQ 2, 'Cleared translation can be restored from cache');

fixtureSql("UPDATE public.tb_evento_corridas SET descricao_en='Manual English',descricao='Nova descrição portuguesa.'");
result = invokeFixture('{"dryRun":false,"language":"en"}');
check(result.payload.selected EQ 0 AND fixtureSql('SELECT descricao_en FROM public.tb_evento_corridas').descricao_en[1] EQ 'Manual English', 'Manual edit after cron output is preserved when source changes');

resetTranslationFixture();
fixtureSql("UPDATE public.tb_evento_corridas SET descricao_en='Existing manual English'");
result = invokeFixture('{"dryRun":false,"language":"en"}');
check(result.payload.selected EQ 0 AND REQUEST.fixtureProviderCalls EQ 0, 'Pre-existing manual translation has no inferred cron ownership');

resetTranslationFixture();
REQUEST.fixtureProviderMode='changed-source';
result = invokeFixture('{"dryRun":false,"language":"en"}');
check(result.payload.skipped EQ 1 AND fixtureSql('SELECT descricao_en IS NULL AS untouched FROM public.tb_evento_corridas').untouched[1], 'Portuguese edit during translation prevents stale output publication');
check(fixtureSql('SELECT status FROM public.tb_evento_descricao_translations').status[1] EQ 'source_changed', 'Source race is audited');
check(fixtureSql('SELECT descricao_traducoes_meta IS NULL AS untouched FROM public.tb_evento_corridas').untouched[1], 'Failed source CAS does not publish metadata');

resetTranslationFixture();
REQUEST.fixtureProviderMode='manual-description';
result = invokeFixture('{"dryRun":false,"language":"en"}');
check(result.payload.skipped EQ 1 AND fixtureSql('SELECT descricao_en FROM public.tb_evento_corridas').descricao_en[1] EQ 'Tradução manual.', 'Target edit during provider request wins');
check(fixtureSql('SELECT descricao_traducoes_meta IS NULL AS untouched FROM public.tb_evento_corridas').untouched[1], 'Failed target CAS does not publish metadata');
resetTranslationFixture();
REQUEST.fixtureProviderMode='null-to-empty';
result = invokeFixture('{"dryRun":false,"language":"en"}');
check(result.payload.skipped EQ 1 AND fixtureSql('SELECT descricao_en IS NOT NULL AS changed FROM public.tb_evento_corridas').changed[1], 'CAS distinguishes original NULL from newly emptied target');

resetTranslationFixture();
REQUEST.fixtureProviderMode='reject-en';
result = invokeFixture('{"dryRun":false}');
check(result.code EQ 422 AND result.payload.results[1].language EQ 'en', 'Factual rejection belongs to one language');
result = invokeFixture('{"dryRun":false}');
check(result.code EQ 200 AND result.payload.results[1].language EQ 'es' AND result.payload.updated EQ 1, 'Rejected English cannot block Spanish');
result = invokeFixture('{"dryRun":false,"language":"en"}');
check(result.payload.selected EQ 0 AND REQUEST.fixtureProviderCalls EQ 2, 'Rejected source/language is not retried');
fixtureSql("UPDATE public.tb_evento_corridas SET descricao=descricao||' Nova informação.'");
REQUEST.fixtureProviderMode='success';
result = invokeFixture('{"dryRun":false,"language":"en"}');
check(result.payload.updated EQ 1, 'Changed source has a separate rejection history');

resetTranslationFixture();
REQUEST.fixtureProviderMode='provider-error';
result = invokeFixture('{"dryRun":false,"language":"en"}');
check(result.code EQ 422 AND !find('DO_NOT_EXPOSE',serializeJSON(result)), 'Invalid provider output stays sanitized');
audit = fixtureSql("SELECT attempt_count,next_retry_at>now()+interval '4 minutes' AS delayed FROM public.tb_evento_descricao_translations ORDER BY id DESC LIMIT 1");
check(audit.attempt_count[1] EQ 1 AND audit.delayed[1], 'First provider retry waits five minutes');
result = invokeFixture('{"dryRun":false,"language":"en"}');
check(result.payload.selected EQ 0 AND REQUEST.fixtureProviderCalls EQ 1, 'Backoff prevents immediate repeated cost');
counts = translationCounts();
check(counts.queue_status[1] EQ 'waiting_retry' AND counts.queue_status[2] EQ 'ready', 'Shared counters distinguish waiting English and ready Spanish');
for (attempt in [2,3]) {
    fixtureSql("UPDATE public.tb_evento_descricao_translations SET next_retry_at=now()-interval '1 second' WHERE language='en'");
    result=invokeFixture('{"dryRun":false,"language":"en"}');
    check(result.code EQ 422, 'Retry returns invalid provider output');
}
fixtureSql("UPDATE public.tb_evento_descricao_translations SET next_retry_at=now()-interval '1 second'");
result=invokeFixture('{"dryRun":false,"language":"en"}');
check(result.payload.selected EQ 0 AND REQUEST.fixtureProviderCalls EQ 3, 'Provider outage stops after three attempts for this source/language');
counts=translationCounts();
check(counts.queue_status[1] EQ 'errors_exhausted', 'Terminal provider failure is visible in shared counters');
REQUEST.fixtureProviderMode='success';
result=invokeFixture('{"dryRun":false}');
check(result.payload.results[1].language EQ 'es' AND result.payload.updated EQ 1, 'Exhausted English attempts cannot block Spanish');

resetTranslationFixture();
fixtureSql("INSERT INTO public.tb_evento_descricao_translations(id_evento,language,source_hash,source_text,status,model,error_code,attempt_count,finished_at) SELECT id_evento,'en',md5(descricao),descricao,'error','gpt-4.1-mini','provider_error',3,now() FROM public.tb_evento_corridas WHERE id_evento=1");
result=invokeFixture('{"dryRun":false,"language":"en"}');
check(result.code EQ 200 AND result.payload.updated EQ 1, 'Legacy generic translation provider failures return to the queue');
check(fixtureSql("SELECT attempt_count FROM public.tb_evento_descricao_translations ORDER BY id DESC LIMIT 1").attempt_count[1] EQ 1, 'Recovered legacy translation starts a fresh classified attempt series');

resetTranslationFixture();
REQUEST.fixtureProviderMode='unexpected-error';
result=invokeFixture('{"dryRun":false,"language":"en"}');
check(result.code EQ 503 AND fixtureSql('SELECT * FROM public.tb_evento_descricao_translations').recordCount EQ 0 AND fixtureSql('SELECT descricao_en IS NULL AS untouched FROM public.tb_evento_corridas').untouched[1], 'Unexpected translation error rolls back audit and target');

resetTranslationFixture();
fixtureSql("CREATE FUNCTION fixture_translation_audit_failure() RETURNS trigger LANGUAGE plpgsql AS $fn$ BEGIN IF NEW.status='updated' THEN RAISE EXCEPTION 'fixture audit persistence failed'; END IF; RETURN NEW; END $fn$");
fixtureSql('CREATE TRIGGER fixture_translation_audit_failure BEFORE UPDATE ON public.tb_evento_descricao_translations FOR EACH ROW EXECUTE FUNCTION fixture_translation_audit_failure()');
result=invokeFixture('{"dryRun":false,"language":"en"}');
check(result.code EQ 503 AND fixtureSql('SELECT * FROM public.tb_evento_descricao_translations').recordCount EQ 0, 'Failure after target UPDATE rolls back running audit');
check(fixtureSql('SELECT descricao_en IS NULL AND descricao_traducoes_meta IS NULL AS untouched FROM public.tb_evento_corridas').untouched[1], 'Text and metadata roll back together when final audit persistence fails');
fixtureSql('DROP TRIGGER fixture_translation_audit_failure ON public.tb_evento_descricao_translations');
fixtureSql('DROP FUNCTION fixture_translation_audit_failure()');

resetTranslationFixture();
fixtureSql("UPDATE public.tb_evento_corridas SET data_final=current_date-1,data_inicial=current_date-1");
fixtureSql("INSERT INTO public.tb_evento_corridas(id_evento,descricao_original,data_inicial,data_final) VALUES (2,:source,current_date,current_date)",{source={value=fixtureSource,cfsqltype='cf_sql_longvarchar'}});
result=invokeFixture('{"dryRun":false}');
check(result.payload.results[1].id EQ 2 AND result.payload.results[1].language EQ 'pt-BR', 'Future event precedes unfinished translations of past event');
result=invokeFixture('{"dryRun":false}');
check(result.payload.results[1].id EQ 2 AND result.payload.results[1].language EQ 'en', 'Auto completes the selected future event in PT then English');

resetTranslationFixture();
fixtureSql('ALTER TABLE public.tb_evento_corridas DROP COLUMN descricao_es');
result=invokeFixture('{"dryRun":false,"language":"en"}');
check(result.code EQ 503 AND result.payload.status EQ 'schema_required' AND REQUEST.fixtureProviderCalls EQ 0, 'Partial translation migration cannot start provider requests');
fixtureSql('ALTER TABLE public.tb_evento_corridas ADD COLUMN descricao_es text');
fixtureSql('ALTER TABLE public.tb_evento_corridas DROP COLUMN descricao_traducoes_meta');
result=invokeFixture('{"dryRun":false,"language":"en"}');
check(result.code EQ 503 AND result.payload.status EQ 'schema_required' AND REQUEST.fixtureProviderCalls EQ 0, 'Missing metadata migration prevents publishing unverifiable translations');
fixtureSql('ALTER TABLE public.tb_evento_corridas ADD COLUMN descricao_traducoes_meta jsonb');
writeOutput('Translation database flow passed: 16' & chr(10));
include 'batch-integration.cfm';
</cfscript>
