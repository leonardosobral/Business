<cfif getBaseTemplatePath() EQ getCurrentTemplatePath()>
    <cfheader statuscode="403" statustext="Forbidden"/><cfabort/>
</cfif>
<cfinclude template="../includes/backend/require_admin.cfm"/>
<cfscript>
VARIABLES.inscricaoSchemaReady = new services.EventRegistrationAvailabilityService().isSchemaReady();
VARIABLES.inscricaoStored = {};
if (qEvento.recordCount AND listFindNoCase(qEvento.columnList, "inscricao_disponibilidade")) {
    try { VARIABLES.inscricaoStored = deserializeJSON(qEvento.inscricao_disponibilidade & ""); }
    catch (any invalidMetadata) { VARIABLES.inscricaoStored = {}; }
}
if (isNull(VARIABLES.inscricaoStored) OR !isStruct(VARIABLES.inscricaoStored)) VARIABLES.inscricaoStored = {};
VARIABLES.inscricaoStatus = structKeyExists(VARIABLES.inscricaoStored, "status") AND isSimpleValue(VARIABLES.inscricaoStored.status)
    AND listFind("open,sold_out,preorder,closed", VARIABLES.inscricaoStored.status) ? VARIABLES.inscricaoStored.status : "unknown";
VARIABLES.inscricaoSource = structKeyExists(VARIABLES.inscricaoStored, "source_url") AND isSimpleValue(VARIABLES.inscricaoStored.source_url) ? VARIABLES.inscricaoStored.source_url : "";
VARIABLES.inscricaoCurrent = new services.EventRegistrationAvailability().evaluate(
    metadata=VARIABLES.inscricaoStored, registrationUrl=qEvento.url_inscricao & "", eventStatus=qEvento.status_evento & "", endDate=qEvento.data_final
);
VARIABLES.inscricaoLabels = {unknown="Não confirmadas", open="Abertas", sold_out="Vagas esgotadas", preorder="Pré-venda disponível", closed="Encerradas"};
</cfscript>
<div class="tab-pane fade <cfif URL.sessao EQ 'inscricoes'>show active</cfif>" id="ex1-tabs-7" role="tabpanel" aria-labelledby="ex1-tab-7" tabindex="0">
    <h6>Disponibilidade das inscrições</h6>
    <p class="small text-muted">Verifique a fonte oficial antes de confirmar. A confirmação vale por 24 horas e precisa corresponder ao link de inscrição cadastrado em Dados.</p>
    <cfif len(VARIABLES.inscricaoError)><div class="alert alert-danger" role="alert"><cfoutput>#encodeForHTML(VARIABLES.inscricaoError)#</cfoutput></div></cfif>
    <cfif VARIABLES.inscricaoSaved><div class="alert alert-success" role="status">Status das inscrições salvo.</div></cfif>
    <cfif NOT VARIABLES.inscricaoSchemaReady>
        <div class="alert alert-warning">A confirmação de inscrições estará disponível após a atualização do banco de dados.</div>
    <cfelseif qEvento.recordCount>
        <div class="mb-3">
            <cfif VARIABLES.inscricaoCurrent.confirmed>
                <span class="badge badge-success">Confirmadas: <cfoutput>#VARIABLES.inscricaoLabels[VARIABLES.inscricaoCurrent.status]#</cfoutput></span>
            <cfelseif VARIABLES.inscricaoStatus NEQ 'unknown'>
                <span class="badge badge-warning">Confirmação sem validade</span>
                <p class="small mt-2 mb-0">O prazo venceu, o link mudou ou o evento foi encerrado/cancelado. Verifique novamente para publicar o status.</p>
            <cfelse>
                <span class="badge badge-secondary">Disponibilidade não confirmada</span>
            </cfif>
            <cfif structKeyExists(VARIABLES.inscricaoStored, 'checked_at') AND isSimpleValue(VARIABLES.inscricaoStored.checked_at) AND isNumeric(VARIABLES.inscricaoStored.checked_at)>
                <cfset VARIABLES.inscricaoCheckedDate = createObject('java','java.util.Date').init(javaCast('long', VARIABLES.inscricaoStored.checked_at*1000))/>
                <p class="small text-muted mt-2 mb-0">Última verificação: <cfoutput>#dateTimeFormat(VARIABLES.inscricaoCheckedDate, 'dd/mm/yyyy HH:nn')#</cfoutput> (horário do servidor).</p>
            </cfif>
        </div>
        <p class="small">Link de inscrição: <cfoutput>#encodeForHTML(qEvento.url_inscricao & '')#</cfoutput></p>
        <form method="post" id="registrationAvailabilityForm">
            <label for="registrationAvailabilityStatus" class="form-label">Status verificado</label>
            <select name="status" id="registrationAvailabilityStatus" class="form-select mb-3">
                <cfoutput><cfloop list="unknown,open,sold_out,preorder,closed" index="inscricaoOption"><option value="#inscricaoOption#" <cfif VARIABLES.inscricaoStatus EQ inscricaoOption>selected</cfif>>#VARIABLES.inscricaoLabels[inscricaoOption]#</option></cfloop></cfoutput>
            </select>
            <label for="registrationAvailabilitySource" class="form-label">URL da fonte oficial</label>
            <input type="url" class="form-control mb-2" name="source_url" id="registrationAvailabilitySource" maxlength="2048" placeholder="https://" value="<cfoutput>#encodeForHTMLAttribute(VARIABLES.inscricaoSource)#</cfoutput>"/>
            <p class="small text-muted">Use a página do organizador ou da plataforma de inscrições. Pré-venda significa que já é possível reservar/comprar; esgotadas significa que as vagas acabaram.</p>
            <div class="form-check mb-3">
                <input type="checkbox" class="form-check-input" id="registrationAvailabilityConfirmed" name="confirmed" value="1"/>
                <label for="registrationAvailabilityConfirmed" class="form-check-label">Verifiquei o status na fonte oficial agora.</label>
            </div>
            <input type="hidden" name="action" value="confirmar_inscricao_disponibilidade"/>
            <input type="hidden" name="id_evento" value="<cfoutput>#val(qEvento.id_evento)#</cfoutput>"/>
            <input type="hidden" name="registration_url" value="<cfoutput>#encodeForHTMLAttribute(qEvento.url_inscricao & '')#</cfoutput>"/>
            <input type="hidden" name="inscricao_csrf" value="<cfoutput>#encodeForHTMLAttribute(csrfGenerateToken('event-registration-availability'))#</cfoutput>"/>
            <button type="submit" class="btn btn-primary w-100">Salvar status das inscrições</button>
        </form>
        <script>
        document.addEventListener('DOMContentLoaded', function () {
            const status = document.getElementById('registrationAvailabilityStatus');
            function updateRequirements() {
                const needsConfirmation = status.value !== 'unknown';
                document.getElementById('registrationAvailabilitySource').required = needsConfirmation;
                document.getElementById('registrationAvailabilityConfirmed').required = needsConfirmation;
            }
            status.addEventListener('change', updateRequirements);
            updateRequirements();
        });
        </script>
    </cfif>
</div>
