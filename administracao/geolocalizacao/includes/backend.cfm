<cfif compareNoCase(getBaseTemplatePath(),getCurrentTemplatePath()) EQ 0><cfheader statuscode="403"><cfabort></cfif>
<cfscript>
cfheader(name="Cache-Control",value="private, no-store");cfheader(name="X-Robots-Tag",value="noindex, nofollow");
VARIABLES.geoPolicy=new services.geocoding.Policy();
VARIABLES.geoDelegated=structKeyExists(REQUEST,"businessAccessContext") AND REQUEST.businessAccessContext.accessMode EQ "DELEGATED";
VARIABLES.geoCanAdmin=isDefined("qPerfil") AND qPerfil.recordCount AND !isNull(qPerfil.is_admin) AND listFindNoCase("true,t,1,yes,sim",trim(qPerfil.is_admin & "")) GT 0 AND !VARIABLES.geoDelegated;
if(isDefined("VARIABLES.businessEffectiveIsAdmin")) VARIABLES.geoCanAdmin=VARIABLES.geoCanAdmin AND listFindNoCase("true,t,1,yes,sim",trim(VARIABLES.businessEffectiveIsAdmin & "")) GT 0;
if(!VARIABLES.geoCanAdmin){cfheader(statuscode=403);writeOutput("Acesso restrito a administradores globais.");abort;}
if(!listFind("GET,POST",CGI.request_method)){cfheader(statuscode=405);cfheader(name="Allow",value="GET, POST");abort;}
param name="URL.aba" default="fila";param name="URL.pagina" default="1";param name="URL.busca" default="";
param name="URL.status" default="todos";param name="URL.periodo" default="proximos";param name="URL.uf" default="";param name="URL.id" default="";param name="URL.resultado" default="";
param name="URL.qualidade" default="all";param name="URL.horizonte" default="all";
param name="URL.etapa" default="";
if(!isSimpleValue(URL.etapa) OR (len(URL.etapa) AND !reFind("^(field|target|legacy)-[1-9][0-9]{0,3}$",URL.etapa))){cfheader(statuscode=400);writeOutput("Etapa inválida.");abort;}
for(VARIABLES.geoParam in ["aba","pagina","busca","status","periodo","uf","id","qualidade","horizonte"])if(!isSimpleValue(URL[VARIABLES.geoParam]) OR len(URL[VARIABLES.geoParam] & "") GT 120){cfheader(statuscode=400);writeOutput("Filtros inválidos.");abort;}
if(!listFind("fila,revisao,cidades,historico,radar,configuracoes",URL.aba) OR !reFind("^[1-9][0-9]{0,3}$",URL.pagina)
    OR !listFind("todos,pending,running,city_suggestion,needs_review,insufficient_data,error,errors_exhausted,conflict,rejected,invalid",URL.status)
    OR !listFind("proximos,todos,historicos",URL.periodo) OR !listFind("all,confirmed,legacy,suspicious,absent",URL.qualidade) OR !listFind("all,30,90,later",URL.horizonte)
    OR (len(URL.uf) AND !reFind("^[A-Z]{2}$",URL.uf)) OR (len(URL.id) AND !reFind("^[1-9][0-9]{0,14}$",URL.id))){cfheader(statuscode=400);writeOutput("Filtros inválidos.");abort;}
VARIABLES.geoTab=URL.aba;VARIABLES.geoPage=val(URL.pagina);VARIABLES.geoSearch=trim(URL.busca);VARIABLES.geoStatus=URL.status;VARIABLES.geoPeriod=URL.periodo;VARIABLES.geoUf=URL.uf;
VARIABLES.geoRadarPage=VARIABLES.geoPage;VARIABLES.geoRadarSearch=VARIABLES.geoSearch;VARIABLES.geoRadarQuality=URL.qualidade;VARIABLES.geoRadarHorizon=URL.horizonte;VARIABLES.geoRadarUf=VARIABLES.geoUf;
VARIABLES.geoNotice="";VARIABLES.geoError="";VARIABLES.geoReady=false;VARIABLES.geoConfigured=false;VARIABLES.geoKeyValidated=false;
if(isSimpleValue(URL.resultado) AND listFind("approve,reject",URL.resultado))VARIABLES.geoNotice=URL.resultado EQ "approve" ? "Local aprovado. Auditoria registrada; próxima proposta aberta." : "Sugestão descartada. Auditoria registrada; próxima proposta aberta.";
VARIABLES.geoStats={missing=0,queued=0,review=0,suggestions=0,analyzed=0,applied=0,calls=0};VARIABLES.geoSettings={enabled=false,dailyLimit=1000};VARIABLES.geoState={cooldown=0};
VARIABLES.geoRows=queryNew("id_evento,nome_evento,cidade,estado,endereco,status,work_id,starts");VARIABLES.geoHasNext=false;VARIABLES.geoSelected={};VARIABLES.geoDecision={};VARIABLES.geoMayApprove=false;
VARIABLES.geoRadarReady=false;VARIABLES.geoRadarStats={total=0,mapped=0,coveragePercent=0,confirmed=0,legacy=0,suspicious=0,absent=0,next30=0,next90=0,later=0,measuredAt=""};VARIABLES.geoRadarStates=queryNew("state_code,eligible_total,mapped_total,coverage_percent,confirmed_total,legacy_total,suspicious_total,absent_total");VARIABLES.geoRadarRows=queryNew("id_evento,nome_evento,starts,ends,cidade,estado,quality,review_reason,geocoding_status,changed_at");VARIABLES.geoRadarHasNext=false;
VARIABLES.geoNextReview=0;VARIABLES.geoReviewBase="?aba=" & (VARIABLES.geoTab EQ "cidades" ? "cidades" : "revisao") & "&periodo=" & VARIABLES.geoPeriod & "&busca=" & encodeForURL(VARIABLES.geoSearch) & "&uf=" & VARIABLES.geoUf;
VARIABLES.geoReasonLabels={city_only="Somente a cidade foi identificada.",geographic_conflict="Cidade, UF ou país não correspondem.",low_confidence="Confiança insuficiente ou ausente.",ambiguous_candidates="Há mais de um local possível.",building_not_confirmed="O número ou a precisão do imóvel não foram confirmados.",street_conflict="A rua retornada é diferente da informada.",venue_name_conflict="O nome do local não foi confirmado.",multiple_start_locations="Há locais de largada conflitantes nas fontes.",catalog_conflict="A cidade cadastrada conflita com seu código municipal.",location_undefined="O local está a definir.",insufficient_precision="O resultado não tem precisão de local ou imóvel.",not_found="Nenhuma localização foi encontrada.",source_changed="O cadastro mudou durante o processamento.",specific_location_confirmed="Local específico confirmado.",no_location_data="Faltam dados para localizar o evento."};
structAppend(VARIABLES.geoReasonLabels,{no_official_source="Não há página oficial ou de inscrição vinculada ao cadastro.",edition_not_confirmed="A fonte não confirmou o nome e a data desta edição da prova.",start_location_not_explicit="Não há local de largada explícito na fonte consultada.",pdf_text_unavailable="O PDF não possui texto extraível ou não pôde ser lido; nenhuma localização foi presumida.",robots_disallowed="A fonte não permite a coleta automática ou não foi possível confirmar essa permissão.",source_unavailable="A fonte está temporariamente indisponível; há novas tentativas limitadas.",source_time_budget="A pesquisa continuará em outra execução, dentro do tempo permitido."},true);
</cfscript>
<cfinclude template="../../../services/geocoding/config.cfm">
<cfscript>
VARIABLES.geoConfigured=len(VARIABLES.geoConfig.apiKey) GT 0;VARIABLES.geoStore=new services.geocoding.Store();VARIABLES.geoWorker=new services.geocoding.Worker(VARIABLES.geoConfig);
VARIABLES.geoAIReady=false;VARIABLES.geoAIStats={calls=0};
VARIABLES.geoGuided=false;VARIABLES.geoReviewTasks=[];VARIABLES.geoReviewTask={};VARIABLES.geoReviewQueue=queryNew("work_id,id_evento,nome_evento,cidade,estado,starts,total");VARIABLES.geoReviewTotal=0;VARIABLES.geoReviewSkipped=0;VARIABLES.geoReviewDone=0;VARIABLES.geoReviewStale=false;
VARIABLES.geoEditPosted=false;VARIABLES.geoEditValue="";VARIABLES.geoEditTaskKey="";VARIABLES.geoEditRevision="";VARIABLES.geoEditObsolete=false;
try {
    VARIABLES.geoAIStore=new services.geocoding.LocationStore();VARIABLES.geoAIReady=VARIABLES.geoAIStore.aiReady();VARIABLES.geoRadarReady=VARIABLES.geoAIStore.radarReady();
    if(VARIABLES.geoAIReady){VARIABLES.geoStore=VARIABLES.geoAIStore;VARIABLES.geoWorker=new services.geocoding.LocationWorker(VARIABLES.geoConfig);VARIABLES.geoAIStats=VARIABLES.geoStore.aiStats();}
    VARIABLES.geoReady=VARIABLES.geoStore.isReady();
    VARIABLES.geoGuided=VARIABLES.geoAIReady AND VARIABLES.geoTab EQ "revisao";
    if(VARIABLES.geoGuided){
        VARIABLES.geoGuide=new services.geocoding.ReviewGuide();
        VARIABLES.geoReviewScope=lCase(hash(serializeJSON([VARIABLES.geoSearch,VARIABLES.geoPeriod,VARIABLES.geoUf]),"SHA-256"));
        lock scope="session" type="exclusive" timeout=3 {
            if(!structKeyExists(SESSION,"geoReviewFlow") OR SESSION.geoReviewFlow.scope NEQ VARIABLES.geoReviewScope)SESSION.geoReviewFlow={scope=VARIABLES.geoReviewScope,skipped=[],decisions=0,notice=""};
            if(len(SESSION.geoReviewFlow.notice)){VARIABLES.geoNotice=SESSION.geoReviewFlow.notice;SESSION.geoReviewFlow.notice="";}
        }
        VARIABLES.geoGuideContinue=function(required numeric id,boolean record=false){
            if(record){lock scope="session" type="exclusive" timeout=3 {SESSION.geoReviewFlow.decisions++;SESSION.geoReviewFlow.notice="Decisão salva. A próxima pendência foi aberta automaticamente.";}}
            var next=VARIABLES.geoGuide.continuation(VARIABLES.geoStore,id,VARIABLES.geoSearch,VARIABLES.geoPeriod,VARIABLES.geoUf,SESSION.geoReviewFlow.skipped);
            location(url=VARIABLES.geoGuide.link(VARIABLES.geoSearch,VARIABLES.geoPeriod,VARIABLES.geoUf,next.id,next.key),addtoken=false,statuscode=303);
        };
    }
    if(CGI.request_method EQ "POST") {
        VARIABLES.geoPolicy.authorize(VARIABLES.geoCanAdmin,VARIABLES.geoDelegated,true,structKeyExists(FORM,"csrf") AND isSimpleValue(FORM.csrf) AND csrfVerifyToken(FORM.csrf,"event-geocoding"));
        if(!VARIABLES.geoReady)throw(type="Geocoding.Validation",message="A migração deste módulo ainda não foi instalada.");
        if(!structKeyExists(FORM,"action") OR !isSimpleValue(FORM.action))throw(type="Geocoding.Validation",message="Ação inválida.");
        VARIABLES.geoActor=REQUEST.businessIdentity.id & "";
        VARIABLES.geoGuidedPost=VARIABLES.geoGuided AND structKeyExists(FORM,"guided") AND isSimpleValue(FORM.guided) AND FORM.guided EQ "1";
        if(listFind("skip_review,resume_reviews",FORM.action)){
            if(!VARIABLES.geoGuidedPost)throw(type="Geocoding.Validation",message="Reabra a revisão rápida para continuar.");
            if(FORM.action EQ "resume_reviews"){lock scope="session" type="exclusive" timeout=3 {SESSION.geoReviewFlow.skipped=[];SESSION.geoReviewFlow.notice="Eventos adiados retornaram à sua sequência. Nenhum cadastro foi alterado.";}VARIABLES.geoGuideContinue(0);}
            if(!structKeyExists(FORM,"id"))throw(type="Geocoding.Validation",message="Evento inválido.");
            VARIABLES.geoSkipId=VARIABLES.geoStore.identifier(FORM.id);VARIABLES.geoSkipWork=VARIABLES.geoStore.detail(VARIABLES.geoSkipId);
            if(structIsEmpty(VARIABLES.geoSkipWork))throw(type="Geocoding.Validation",message="Esta proposta não está mais disponível. Reabra a sequência.");
            lock scope="session" type="exclusive" timeout=3 {
                if(arrayLen(SESSION.geoReviewFlow.skipped) GTE 500)throw(type="Geocoding.Validation",message="Retome os eventos adiados antes de pular outros.");
                if(!arrayFind(SESSION.geoReviewFlow.skipped,VARIABLES.geoSkipWork.id_evento))arrayAppend(SESSION.geoReviewFlow.skipped,VARIABLES.geoSkipWork.id_evento);
                SESSION.geoReviewFlow.notice="Evento adiado apenas nesta sessão. Nenhum dado foi alterado; use Retomar adiados para voltar a ele.";
            }
            VARIABLES.geoGuideContinue(VARIABLES.geoSkipId);
        } else if(FORM.action EQ "enqueue") {
            if(!structKeyExists(FORM,"ids") OR !isSimpleValue(FORM.ids) OR len(FORM.ids) GT 400)throw(type="Geocoding.Validation",message="Selecione até 20 eventos.");
            VARIABLES.geoIds=listToArray(FORM.ids);VARIABLES.geoQueued=VARIABLES.geoStore.enqueue(VARIABLES.geoIds,VARIABLES.geoActor);
            VARIABLES.geoNotice=arrayLen(VARIABLES.geoQueued) & " evento(s) enfileirado(s). Nenhuma consulta foi executada nesta ação.";
            if(VARIABLES.geoGuidedPost){SESSION.geoReviewFlow.notice="Nova análise agendada. Nenhum dado do evento foi alterado nesta ação.";VARIABLES.geoGuideContinue(0);}
        } else if(FORM.action EQ "save_settings") {
            if(!structKeyExists(FORM,"daily_limit") OR !isSimpleValue(FORM.daily_limit) OR !isNumeric(FORM.daily_limit))throw(type="Geocoding.Validation",message="Informe um limite diário válido.");
            VARIABLES.geoEnabled=structKeyExists(FORM,"enabled") AND isSimpleValue(FORM.enabled) AND FORM.enabled EQ "1";
            VARIABLES.geoStore.saveSettings(VARIABLES.geoEnabled,val(FORM.daily_limit),VARIABLES.geoWorker.fingerprint());
            VARIABLES.geoNotice=VARIABLES.geoEnabled ? "Preenchimento automático habilitado. Confira também a ativação do job no gerenciador de Cron Jobs." : "Preenchimento automático pausado. Nenhum outro job foi alterado.";
        } else if(FORM.action EQ "test_connection") {
            VARIABLES.geoTest=VARIABLES.geoWorker.testConnection();
            if(VARIABLES.geoTest.success)VARIABLES.geoNotice=VARIABLES.geoTest.message;else VARIABLES.geoError=VARIABLES.geoTest.message;
        } else if(FORM.action EQ "correct_field") {
            if(!VARIABLES.geoGuidedPost OR !structKeyExists(FORM,"id") OR !structKeyExists(FORM,"attribute") OR !structKeyExists(FORM,"revision") OR !isSimpleValue(FORM.revision) OR !structKeyExists(FORM,"confirmed") OR !isSimpleValue(FORM.confirmed) OR FORM.confirmed NEQ "1" OR !structKeyExists(FORM,"edited_value") OR !isSimpleValue(FORM.edited_value))throw(type="Geocoding.Validation",message="Reabra e confirme a correção deste campo.");
            VARIABLES.geoEditId=VARIABLES.geoStore.identifier(FORM.id);VARIABLES.geoEditIndex=VARIABLES.geoStore.identifier(FORM.attribute);
            VARIABLES.geoEditPosted=true;VARIABLES.geoEditValue=left(FORM.edited_value,10000);VARIABLES.geoEditTaskKey="field-" & VARIABLES.geoEditIndex;VARIABLES.geoEditRevision=FORM.revision;
            VARIABLES.geoStore.correctField(VARIABLES.geoEditId,VARIABLES.geoEditIndex,FORM.edited_value,VARIABLES.geoActor,FORM.revision);
            VARIABLES.geoGuideContinue(VARIABLES.geoEditId,true);
        } else if(listFind("approve_field,reject_field",FORM.action)) {
            if(!VARIABLES.geoAIReady OR !structKeyExists(FORM,"id") OR !structKeyExists(FORM,"attribute") OR !structKeyExists(FORM,"revision") OR !structKeyExists(FORM,"confirmed") OR !isSimpleValue(FORM.confirmed) OR FORM.confirmed NEQ "1" OR !isSimpleValue(FORM.revision))throw(type="Geocoding.Validation",message="Reabra e confirme a revisão deste campo.");
            VARIABLES.geoReviewed=VARIABLES.geoStore.reviewField(VARIABLES.geoStore.identifier(FORM.id),VARIABLES.geoStore.identifier(FORM.attribute),FORM.action EQ "approve_field" ? "approve" : "reject",VARIABLES.geoActor,FORM.revision);
            if(VARIABLES.geoGuidedPost)VARIABLES.geoGuideContinue(val(FORM.id),true);
            location(url=VARIABLES.geoReviewBase & "&id=" & val(FORM.id) & "##geo-panel-fields",addtoken=false,statuscode=303);
        } else if(listFind("approve_target,reject_target",FORM.action)) {
            if(!VARIABLES.geoAIReady OR !structKeyExists(FORM,"id") OR !structKeyExists(FORM,"target") OR !structKeyExists(FORM,"revision") OR !structKeyExists(FORM,"confirmed") OR !isSimpleValue(FORM.confirmed) OR FORM.confirmed NEQ "1" OR !isSimpleValue(FORM.revision))throw(type="Geocoding.Validation",message="Reabra e confirme a revisão deste local.");
            VARIABLES.geoReviewed=VARIABLES.geoStore.reviewTarget(VARIABLES.geoStore.identifier(FORM.id),VARIABLES.geoStore.identifier(FORM.target),FORM.action EQ "approve_target" ? "approve" : "reject",VARIABLES.geoActor,FORM.revision);
            if(VARIABLES.geoGuidedPost)VARIABLES.geoGuideContinue(val(FORM.id),true);
            location(url=VARIABLES.geoReviewBase & "&id=" & val(FORM.id),addtoken=false,statuscode=303);
        } else if(listFind("approve,reject",FORM.action)) {
            if(!structKeyExists(FORM,"id") OR !structKeyExists(FORM,"confirmed") OR !isSimpleValue(FORM.confirmed) OR FORM.confirmed NEQ "1")throw(type="Geocoding.Validation",message="Confirme a revisão.");
            if(structKeyExists(FORM,"reason") AND !isSimpleValue(FORM.reason))throw(type="Geocoding.Validation",message="Observação inválida.");
            if(!structKeyExists(FORM,"revision") OR !isSimpleValue(FORM.revision))throw(type="Geocoding.Validation",message="Reabra os detalhes da proposta antes de revisar.");
            VARIABLES.geoReviewed=VARIABLES.geoStore.review(VARIABLES.geoStore.identifier(FORM.id),FORM.action,VARIABLES.geoActor,structKeyExists(FORM,"reason") ? FORM.reason : "",FORM.revision);
            if(VARIABLES.geoGuidedPost)VARIABLES.geoGuideContinue(val(FORM.id),true);
            VARIABLES.geoNextReview=VARIABLES.geoStore.nextReview(val(FORM.id),VARIABLES.geoTab EQ "cidades" ? "cidades" : "revisao",VARIABLES.geoSearch,VARIABLES.geoPeriod,VARIABLES.geoUf);
            location(url=VARIABLES.geoReviewBase & (VARIABLES.geoNextReview GT 0 ? "&id=" & VARIABLES.geoNextReview : "") & "&resultado=" & FORM.action,addtoken=false,statuscode=303);
        } else throw(type="Geocoding.Validation",message="Ação inválida.");
    }
}catch(Geocoding.Denied denied){cfheader(statuscode=403);VARIABLES.geoError=denied.message;}
catch(Geocoding.Validation invalid){VARIABLES.geoError=invalid.message;}
catch(any unavailable){VARIABLES.geoError="Não foi possível concluir a ação agora. Reabra a proposta para conferir o estado atual.";}
// Rehydrate after a rejected POST too: a stale revision is not an empty queue.
try {
    if(VARIABLES.geoReady) {
        VARIABLES.geoStats=VARIABLES.geoStore.overview();VARIABLES.geoSettings=VARIABLES.geoStore.settings();VARIABLES.geoState=VARIABLES.geoStore.providerState();
        VARIABLES.geoKeyValidated=VARIABLES.geoConfigured AND VARIABLES.geoSettings.validatedFingerprint EQ VARIABLES.geoWorker.fingerprint();
        if(VARIABLES.geoTab EQ "radar" AND VARIABLES.geoRadarReady) {
            VARIABLES.geoRadarStats=VARIABLES.geoAIStore.radarCoverage();VARIABLES.geoRadarStates=VARIABLES.geoAIStore.radarCoverageByState();VARIABLES.geoRadarRows=VARIABLES.geoAIStore.radarCoveragePage(VARIABLES.geoRadarPage,VARIABLES.geoRadarSearch,VARIABLES.geoRadarQuality,VARIABLES.geoRadarHorizon,VARIABLES.geoRadarUf);VARIABLES.geoRadarHasNext=VARIABLES.geoRadarRows.recordCount GT 20;
        } else if(!VARIABLES.geoGuided AND !listFind("configuracoes,radar",VARIABLES.geoTab))VARIABLES.geoRows=VARIABLES.geoStore.page(VARIABLES.geoTab,VARIABLES.geoPage,VARIABLES.geoSearch,VARIABLES.geoStatus,VARIABLES.geoPeriod,VARIABLES.geoUf);
        VARIABLES.geoHasNext=VARIABLES.geoRows.recordCount GT 20;
        VARIABLES.geoSelectedId=val(URL.id);
        if(VARIABLES.geoEditPosted)VARIABLES.geoSelectedId=VARIABLES.geoEditId;
        if(!VARIABLES.geoSelectedId AND VARIABLES.geoGuided AND len(VARIABLES.geoError) AND structKeyExists(FORM,"id") AND isSimpleValue(FORM.id) AND reFind("^[1-9][0-9]{0,14}$",FORM.id))VARIABLES.geoSelectedId=val(FORM.id);
        if(VARIABLES.geoGuided){
            VARIABLES.geoReviewQueue=VARIABLES.geoGuide.queue(VARIABLES.geoSearch,VARIABLES.geoPeriod,VARIABLES.geoUf,SESSION.geoReviewFlow.skipped);
            VARIABLES.geoReviewTotal=VARIABLES.geoReviewQueue.recordCount ? VARIABLES.geoReviewQueue.total[1] : 0;VARIABLES.geoReviewSkipped=arrayLen(SESSION.geoReviewFlow.skipped);VARIABLES.geoReviewDone=SESSION.geoReviewFlow.decisions;
            if(!VARIABLES.geoSelectedId AND VARIABLES.geoReviewQueue.recordCount)VARIABLES.geoSelectedId=VARIABLES.geoReviewQueue.work_id[1];
        }
        if(VARIABLES.geoSelectedId GT 0) {
            if(!VARIABLES.geoGuided)VARIABLES.geoNextReview=VARIABLES.geoStore.nextReview(VARIABLES.geoSelectedId,VARIABLES.geoTab EQ "cidades" ? "cidades" : "revisao",VARIABLES.geoSearch,VARIABLES.geoPeriod,VARIABLES.geoUf);
            VARIABLES.geoSelected=VARIABLES.geoStore.detail(VARIABLES.geoSelectedId);
            if(VARIABLES.geoEditPosted)VARIABLES.geoEditObsolete=structIsEmpty(VARIABLES.geoSelected) OR VARIABLES.geoSelected.proposal_revision & "" NEQ VARIABLES.geoEditRevision;
            if(!structIsEmpty(VARIABLES.geoSelected)) {
                VARIABLES.geoDecision=deserializeJSON(VARIABLES.geoSelected.decision & "");VARIABLES.geoCurrent=VARIABLES.geoStore.event(VARIABLES.geoSelected.id_evento);
                VARIABLES.geoSelectedSource=deserializeJSON(VARIABLES.geoSelected.source_snapshot & "");
                if((VARIABLES.geoSelectedSource.version ?: 0) EQ 3 AND !structKeyExists(VARIABLES.geoDecision,"targets")){VARIABLES.geoDecision.targets=[];VARIABLES.geoDecision.model=VARIABLES.geoConfig.aiModel;}
                VARIABLES.geoMayApprove=VARIABLES.geoSelected.status EQ "needs_review" AND structKeyExists(VARIABLES.geoDecision,"candidate") AND VARIABLES.geoPolicy.specificCandidate(VARIABLES.geoPolicy.snapshot(VARIABLES.geoCurrent),VARIABLES.geoDecision.candidate)
                    AND VARIABLES.geoPolicy.sourceHash(VARIABLES.geoPolicy.snapshot(VARIABLES.geoCurrent)) EQ VARIABLES.geoSelected.source_hash;
                if(VARIABLES.geoGuided){
                    VARIABLES.geoReviewTasks=VARIABLES.geoGuide.tasks(VARIABLES.geoSelected,VARIABLES.geoDecision,VARIABLES.geoCurrent,VARIABLES.geoMayApprove);
                    VARIABLES.geoReviewTask=VARIABLES.geoGuide.active(VARIABLES.geoReviewTasks,VARIABLES.geoEditPosted AND VARIABLES.geoSelectedId EQ VARIABLES.geoEditId ? VARIABLES.geoEditTaskKey : URL.etapa);
                    VARIABLES.geoReviewStale=VARIABLES.geoGuide.isStale(VARIABLES.geoStore,VARIABLES.geoSelected,VARIABLES.geoCurrent);
                }
            }
        }
    }
}catch(Geocoding.Denied denied){cfheader(statuscode=403);VARIABLES.geoError=denied.message;}
catch(Geocoding.Validation invalid){VARIABLES.geoError=invalid.message;}
catch(any unavailable){VARIABLES.geoError="Não foi possível consultar a geolocalização agora. Nenhuma alteração foi confirmada por esta tela.";}
</cfscript>
