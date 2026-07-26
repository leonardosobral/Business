<!DOCTYPE html>
<html lang="pt-br">

<cfprocessingdirective pageencoding="utf-8"/>

<cfset VARIABLES.theme = "dark"/>
<cfset VARIABLES.template = "/administracao/config-check/"/>

<cfinclude template="../../includes/backend/backend_login.cfm"/>
<cfinclude template="../../includes/backend/require_admin_dev.cfm"/>

<cfset VARIABLES.configCheckLocalConfig = {}/>
<cfset VARIABLES.configCheckLocalPath = expandPath("/config/business.local.cfm")/>
<cfset VARIABLES.configCheckLocalExists = fileExists(VARIABLES.configCheckLocalPath)/>

<cfif VARIABLES.configCheckLocalExists>
  <cfinclude template="../../config/business.local.cfm"/>
  <cfif isDefined("businessLocalConfig") AND isStruct(businessLocalConfig)>
    <cfset VARIABLES.configCheckLocalConfig = duplicate(businessLocalConfig)/>
  <cfelseif structKeyExists(VARIABLES, "businessLocalConfig") AND isStruct(VARIABLES.businessLocalConfig)>
    <cfset VARIABLES.configCheckLocalConfig = duplicate(VARIABLES.businessLocalConfig)/>
  </cfif>
</cfif>

<cfscript>
function configCheckMask(any rawValue) {
    var valueText = "";

    if (isNull(arguments.rawValue)) {
        return "ausente";
    }

    if (!isSimpleValue(arguments.rawValue)) {
        return isStruct(arguments.rawValue) ? structCount(arguments.rawValue) & " campo(s)" : "valor composto";
    }

    valueText = trim(arguments.rawValue & "");
    if (!len(valueText)) {
        return "vazio";
    }

    return "configurado · " & len(valueText) & " chars · sha256:" & left(lCase(hash(valueText, "SHA-256")), 12);
}

function configCheckStructValue(required struct source, required string keyName) {
    if (structKeyExists(arguments.source, arguments.keyName) AND !isNull(arguments.source[arguments.keyName])) {
        return arguments.source[arguments.keyName];
    }

    return "";
}

function configCheckEnvValue(required any environment, required string keyName) {
    if (structKeyExists(arguments.environment, arguments.keyName) AND !isNull(arguments.environment[arguments.keyName])) {
        return trim(arguments.environment[arguments.keyName] & "");
    }

    return "";
}

function configCheckApplicationValue(required string pathName) {
    var pathParts = listToArray(arguments.pathName, ".");
    var currentValue = APPLICATION;
    var partIndex = 0;

    if (!arrayLen(pathParts)) {
        return "";
    }

    if (lCase(pathParts[1]) EQ "application") {
        arrayDeleteAt(pathParts, 1);
    }

    for (partIndex = 1; partIndex <= arrayLen(pathParts); partIndex++) {
        if (isStruct(currentValue) AND structKeyExists(currentValue, pathParts[partIndex]) AND !isNull(currentValue[pathParts[partIndex]])) {
            currentValue = currentValue[pathParts[partIndex]];
        } else {
            return "";
        }
    }

    return currentValue;
}

function configCheckSourceLabel(required any environment, required struct localConfig, required string keyName, required string envName, string applicationPath = "") {
    var applicationValue = "";

    if (len(arguments.envName) AND len(configCheckEnvValue(arguments.environment, arguments.envName))) {
        return "env";
    }

    if (structKeyExists(arguments.localConfig, arguments.keyName) AND !isNull(arguments.localConfig[arguments.keyName]) AND len(trim(arguments.localConfig[arguments.keyName] & ""))) {
        return "business.local.cfm";
    }

    applicationValue = len(arguments.applicationPath) ? configCheckApplicationValue(arguments.applicationPath) : "";
    if (len(arguments.applicationPath) AND isSimpleValue(applicationValue) AND len(trim(applicationValue & ""))) {
        return "application/default";
    }

    return "ausente";
}

function configCheckSecretSource(required struct localConfig, required string secretRef) {
    if (structKeyExists(arguments.localConfig, "cronSecrets")
        AND isStruct(arguments.localConfig.cronSecrets)
        AND structKeyExists(arguments.localConfig.cronSecrets, arguments.secretRef)
        AND len(trim(arguments.localConfig.cronSecrets[arguments.secretRef] & ""))) {
        return "business.local.cfm";
    }

    if (structKeyExists(APPLICATION, "cronJobs")
        AND isStruct(APPLICATION.cronJobs)
        AND structKeyExists(APPLICATION.cronJobs, "secrets")
        AND isStruct(APPLICATION.cronJobs.secrets)
        AND structKeyExists(APPLICATION.cronJobs.secrets, arguments.secretRef)
        AND len(trim(APPLICATION.cronJobs.secrets[arguments.secretRef] & ""))) {
        return "APPLICATION em memoria";
    }

    return "ausente";
}

function configCheckSecretValue(required struct localConfig, required string secretRef) {
    if (structKeyExists(arguments.localConfig, "cronSecrets")
        AND isStruct(arguments.localConfig.cronSecrets)
        AND structKeyExists(arguments.localConfig.cronSecrets, arguments.secretRef)) {
        return arguments.localConfig.cronSecrets[arguments.secretRef];
    }

    if (structKeyExists(APPLICATION, "cronJobs")
        AND isStruct(APPLICATION.cronJobs)
        AND structKeyExists(APPLICATION.cronJobs, "secrets")
        AND isStruct(APPLICATION.cronJobs.secrets)
        AND structKeyExists(APPLICATION.cronJobs.secrets, arguments.secretRef)) {
        return APPLICATION.cronJobs.secrets[arguments.secretRef];
    }

    return "";
}

function configCheckCfScriptString(required string rawValue) {
    var escapedValue = replace(arguments.rawValue, "##", "####", "all");

    escapedValue = replace(escapedValue, "'", "''", "all");

    return "'" & escapedValue & "'";
}

function configCheckBuildBusinessLocalFile(required struct configData) {
    var jsonText = serializeJSON(arguments.configData);

    return "<cfscript>" & chr(10)
        & "businessLocalConfig = deserializeJSON(" & configCheckCfScriptString(jsonText) & ");" & chr(10)
        & "</cfscript>" & chr(10);
}

function configCheckWriteRecoveryFile(required string fileContent) {
    var recoveryDirectory = getTempDirectory();
    var recoveryPath = "";

    if (right(recoveryDirectory, 1) NEQ "/" AND right(recoveryDirectory, 1) NEQ chr(92)) {
        recoveryDirectory &= "/";
    }

    recoveryPath = recoveryDirectory & "business.local.recovered-" & dateTimeFormat(now(), "yyyymmddHHnnss") & ".cfm";
    fileWrite(recoveryPath, arguments.fileContent, "utf-8");

    return recoveryPath;
}

configCheckEnvironment = createObject("java", "java.lang.System").getenv();
configCheckExpectedKeys = [
    { label = "Evento API token", key = "eventoApiToken", env = "RR_EVENTO_API_TOKEN", app = "APPLICATION.eventoApiToken" },
    { label = "Mandrill username", key = "mandrillUsername", env = "RR_MANDRILL_USERNAME", app = "" },
    { label = "Mandrill password", key = "mandrillPassword", env = "RR_MANDRILL_PASSWORD", app = "" },
    { label = "Push public key", key = "pushPublicKey", env = "RR_PUSH_PUBLIC_KEY", app = "APPLICATION.pwaPush.publicKey" },
    { label = "Push private key", key = "pushPrivateKey", env = "RR_PUSH_PRIVATE_KEY", app = "APPLICATION.pwaPush.privateKey" },
    { label = "Push subject", key = "pushSubject", env = "RR_PUSH_SUBJECT", app = "APPLICATION.pwaPush.subject" },
    { label = "Notification dispatch URL", key = "notificationDispatchUrl", env = "RR_NOTIFICATION_DISPATCH_URL", app = "APPLICATION.notificationDispatch.url" },
    { label = "Notification dispatch secret", key = "notificationDispatchSecret", env = "RR_HANDOFF_SECRET", app = "APPLICATION.notificationDispatch.secret" },
    { label = "Notification timeout", key = "notificationDispatchTimeoutSeconds", env = "RR_PUSH_DISPATCH_TIMEOUT_SECONDS", app = "APPLICATION.notificationDispatch.timeoutSeconds" },
    { label = "UptimeRobot API key", key = "uptimeRobotApiKey", env = "UPTIMEROBOT_API_KEY", app = "APPLICATION.uptimeRobot.apiKey" },
    { label = "Cron runner token", key = "cronRunnerToken", env = "RR_BUSINESS_CRON_RUNNER_TOKEN", app = "APPLICATION.cronJobs.runnerToken" },
    { label = "Cron timeout", key = "cronDefaultTimeoutSeconds", env = "RR_BUSINESS_CRON_TIMEOUT_SECONDS", app = "APPLICATION.cronJobs.defaultTimeoutSeconds" }
];
configCheckExpectedSecrets = listToArray("road_runners_handoff,business_internal,runnerhub_update_feed,runnerhub_youtube,runnerhub_ticketsports,runnerhub_foco_eventos");
configCheckActionNotice = "";
configCheckActionError = "";

if (structKeyExists(FORM, "acao") AND FORM.acao EQ "persistir_cron_memory") {
    try {
        configCheckConfigToPersist = duplicate(VARIABLES.configCheckLocalConfig);
        configCheckBackupPath = VARIABLES.configCheckLocalPath & ".bak-" & dateTimeFormat(now(), "yyyymmddHHnnss");
        configCheckFileContent = "";

        if (!structKeyExists(APPLICATION, "cronJobs") OR !isStruct(APPLICATION.cronJobs)) {
            throw(message = "APPLICATION.cronJobs nao esta carregado.");
        }

        if (structKeyExists(APPLICATION.cronJobs, "runnerToken") AND len(trim(APPLICATION.cronJobs.runnerToken & ""))) {
            configCheckConfigToPersist.cronRunnerToken = trim(APPLICATION.cronJobs.runnerToken & "");
        }

        if (structKeyExists(APPLICATION.cronJobs, "defaultTimeoutSeconds") AND val(APPLICATION.cronJobs.defaultTimeoutSeconds) GT 0) {
            configCheckConfigToPersist.cronDefaultTimeoutSeconds = val(APPLICATION.cronJobs.defaultTimeoutSeconds);
        }

        configCheckConfigToPersist.cronSecrets = structKeyExists(configCheckConfigToPersist, "cronSecrets")
            AND isStruct(configCheckConfigToPersist.cronSecrets)
            ? duplicate(configCheckConfigToPersist.cronSecrets)
            : {};

        if (structKeyExists(APPLICATION.cronJobs, "secrets") AND isStruct(APPLICATION.cronJobs.secrets)) {
            for (secretRef in APPLICATION.cronJobs.secrets) {
                if (isSimpleValue(APPLICATION.cronJobs.secrets[secretRef]) AND len(trim(APPLICATION.cronJobs.secrets[secretRef] & ""))) {
                    configCheckConfigToPersist.cronSecrets[secretRef] = trim(APPLICATION.cronJobs.secrets[secretRef] & "");
                }
            }
        }

        if (!structCount(configCheckConfigToPersist.cronSecrets)) {
            throw(message = "Nenhum cron secret encontrado em APPLICATION para persistir.");
        }

        configCheckFileContent = configCheckBuildBusinessLocalFile(configCheckConfigToPersist);

        if (fileExists(VARIABLES.configCheckLocalPath)) {
            try {
                fileCopy(VARIABLES.configCheckLocalPath, configCheckBackupPath);
            } catch (any configCheckBackupError) {
                configCheckRecoveredPath = configCheckWriteRecoveryFile(configCheckFileContent);
                throw(message = "Backup falhou e nada foi gravado em config. Arquivo recuperado gerado em " & configCheckRecoveredPath & ". Erro original: " & configCheckBackupError.message);
            }
        }

        try {
            fileWrite(VARIABLES.configCheckLocalPath, configCheckFileContent, "utf-8");
        } catch (any configCheckWriteError) {
            configCheckRecoveredPath = configCheckWriteRecoveryFile(configCheckFileContent);
            throw(message = "Backup criado, mas a gravacao do arquivo local falhou. Arquivo recuperado gerado em " & configCheckRecoveredPath & ". Erro original: " & configCheckWriteError.message);
        }

        VARIABLES.configCheckLocalConfig = duplicate(configCheckConfigToPersist);
        VARIABLES.configCheckLocalExists = true;
        configCheckActionNotice = "Cron salvo em business.local.cfm com backup em " & configCheckBackupPath & ".";
    } catch (any configCheckPersistError) {
        configCheckActionError = configCheckPersistError.message;
    }
}

configCheckLocalKeys = structKeyList(VARIABLES.configCheckLocalConfig);
configCheckApplicationCronSecrets = structKeyExists(APPLICATION, "cronJobs")
    AND isStruct(APPLICATION.cronJobs)
    AND structKeyExists(APPLICATION.cronJobs, "secrets")
    AND isStruct(APPLICATION.cronJobs.secrets)
    ? structKeyList(APPLICATION.cronJobs.secrets)
    : "";
configCheckMemoryOnlySecrets = [];

for (secretRef in configCheckExpectedSecrets) {
    configCheckLocalSecretValue = structKeyExists(VARIABLES.configCheckLocalConfig, "cronSecrets")
        AND isStruct(VARIABLES.configCheckLocalConfig.cronSecrets)
        AND structKeyExists(VARIABLES.configCheckLocalConfig.cronSecrets, secretRef)
        ? trim(VARIABLES.configCheckLocalConfig.cronSecrets[secretRef] & "")
        : "";
    configCheckAppSecretValue = structKeyExists(APPLICATION, "cronJobs")
        AND isStruct(APPLICATION.cronJobs)
        AND structKeyExists(APPLICATION.cronJobs, "secrets")
        AND isStruct(APPLICATION.cronJobs.secrets)
        AND structKeyExists(APPLICATION.cronJobs.secrets, secretRef)
        ? trim(APPLICATION.cronJobs.secrets[secretRef] & "")
        : "";

    if (!len(configCheckLocalSecretValue) AND len(configCheckAppSecretValue)) {
        arrayAppend(configCheckMemoryOnlySecrets, secretRef);
    }
}
</cfscript>

<cfset qConfigCheckCronJobs = queryNew("id_cron_job,nome,projeto,ambiente,auth_mode,secret_ref,ativo,last_status,last_http_status,last_error,next_run_at")/>
<cfset VARIABLES.configCheckCronJobsError = ""/>
<cftry>
  <cfquery name="qConfigCheckCronJobs">
    SELECT id_cron_job,
           nome,
           projeto,
           ambiente,
           auth_mode,
           coalesce(secret_ref, '') AS secret_ref,
           ativo,
           coalesce(last_status, '') AS last_status,
           last_http_status,
           coalesce(last_error, '') AS last_error,
           next_run_at
    FROM tb_cron_jobs
    WHERE auth_mode <> 'none'
       OR coalesce(secret_ref, '') <> ''
    ORDER BY ativo DESC, projeto, ambiente, nome
  </cfquery>
  <cfcatch type="any">
    <cfset VARIABLES.configCheckCronJobsError = cfcatch.message/>
  </cfcatch>
</cftry>

<cfinclude template="../../includes/estrutura/head.cfm"/>

<body data-mdb-theme="dark" class="bg-dark-subtle">

  <cfinclude template="../../includes/estrutura/header.cfm"/>

  <main style="margin-top: -55px;">
    <div class="container-fluid px-4">
      <section class="py-5">
        <div class="d-flex flex-column flex-lg-row justify-content-between align-items-lg-end gap-3 mb-4">
          <div>
            <div class="text-warning text-uppercase small fw-bold">Administracao</div>
            <h1 class="h3 mb-1">Diagnostico de configuracao</h1>
            <p class="text-muted mb-0">Mostra presenca, fonte, tamanho e hash curto dos valores carregados. Segredos nao sao exibidos em texto puro.</p>
          </div>
          <div class="d-flex flex-wrap gap-2">
            <a class="btn btn-outline-light btn-sm" href="/?resetApp">Recarregar APPLICATION</a>
            <a class="btn btn-warning btn-sm" href="/administracao/cron-jobs/">Cron Jobs</a>
          </div>
        </div>

        <cfif len(configCheckActionNotice)>
          <cfoutput><div class="alert alert-success">#htmlEditFormat(configCheckActionNotice)#</div></cfoutput>
        </cfif>
        <cfif len(configCheckActionError)>
          <cfoutput><div class="alert alert-danger">#htmlEditFormat(configCheckActionError)#</div></cfoutput>
        </cfif>

        <div class="row g-3 mb-4">
          <div class="col-md-4">
            <div class="card shadow-0 h-100">
              <div class="card-body">
                <div class="text-muted small text-uppercase fw-bold mb-2">Arquivo local</div>
                <div class="h5 mb-1"><cfoutput>#VARIABLES.configCheckLocalExists ? "Encontrado" : "Nao encontrado"#</cfoutput></div>
                <div class="small text-muted text-break"><cfoutput>#htmlEditFormat(VARIABLES.configCheckLocalPath)#</cfoutput></div>
              </div>
            </div>
          </div>
          <div class="col-md-4">
            <div class="card shadow-0 h-100">
              <div class="card-body">
                <div class="text-muted small text-uppercase fw-bold mb-2">Chaves no arquivo</div>
                <div class="h5 mb-1"><cfoutput>#structCount(VARIABLES.configCheckLocalConfig)#</cfoutput></div>
                <div class="small text-muted text-break"><cfoutput>#htmlEditFormat(configCheckLocalKeys)#</cfoutput></div>
              </div>
            </div>
          </div>
          <div class="col-md-4">
            <div class="card shadow-0 h-100">
              <div class="card-body">
                <div class="text-muted small text-uppercase fw-bold mb-2">Cron em memoria</div>
                <div class="h5 mb-1">
                  <cfoutput>#structKeyExists(APPLICATION, "cronJobs") AND structKeyExists(APPLICATION.cronJobs, "enabled") AND APPLICATION.cronJobs.enabled ? "Habilitado" : "Desabilitado"#</cfoutput>
                </div>
                <div class="small text-muted text-break">Secrets: <cfoutput>#htmlEditFormat(configCheckApplicationCronSecrets)#</cfoutput></div>
              </div>
            </div>
          </div>
        </div>

        <div class="card shadow-0 mb-4">
          <div class="card-body">
            <h2 class="h5 mb-3">Valores principais</h2>
            <div class="table-responsive">
              <table class="table table-sm align-middle mb-0">
                <thead>
                  <tr>
                    <th>Item</th>
                    <th>Fonte provavel</th>
                    <th>Env</th>
                    <th>business.local.cfm</th>
                    <th>APPLICATION</th>
                  </tr>
                </thead>
                <tbody>
                  <cfloop array="#configCheckExpectedKeys#" index="configItem">
                    <cfoutput>
                      <tr>
                        <td>
                          <div class="fw-semibold">#htmlEditFormat(configItem.label)#</div>
                          <div class="small text-muted">#htmlEditFormat(configItem.key)#</div>
                        </td>
                        <td>#htmlEditFormat(configCheckSourceLabel(configCheckEnvironment, VARIABLES.configCheckLocalConfig, configItem.key, configItem.env, configItem.app))#</td>
                        <td>
                          <div class="small text-muted">#htmlEditFormat(configItem.env)#</div>
                          #htmlEditFormat(configCheckMask(configCheckEnvValue(configCheckEnvironment, configItem.env)))#
                        </td>
                        <td>#htmlEditFormat(configCheckMask(configCheckStructValue(VARIABLES.configCheckLocalConfig, configItem.key)))#</td>
                        <td>
                          <cfif len(configItem.app)>
                            <div class="small text-muted">#htmlEditFormat(configItem.app)#</div>
                            #htmlEditFormat(configCheckMask(configCheckApplicationValue(configItem.app)))#
                          <cfelse>
                            <span class="text-muted">nao armazenado em APPLICATION</span>
                          </cfif>
                        </td>
                      </tr>
                    </cfoutput>
                  </cfloop>
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <div class="card shadow-0 mb-4">
          <div class="card-body">
            <h2 class="h5 mb-3">Cron secrets</h2>
            <p class="text-muted small mb-3">Estes sao os segredos esperados por jobs com <code>auth_mode = hmac_sha256</code>, bearer ou API key. O valor exibido e mascarado.</p>
            <cfif arrayLen(configCheckMemoryOnlySecrets)>
              <div class="alert alert-warning">
                <div class="d-flex flex-column flex-xl-row align-items-xl-center justify-content-between gap-3">
                  <div>
                    Existem secrets apenas em <code>APPLICATION</code>, sem valor no arquivo local:
                    <cfoutput>#htmlEditFormat(arrayToList(configCheckMemoryOnlySecrets, ", "))#</cfoutput>.
                    Isso indica memoria carregada antes da ultima alteracao do arquivo ou de um reset da aplicacao.
                  </div>
                  <form method="post" class="m-0">
                    <input type="hidden" name="acao" value="persistir_cron_memory">
                    <button type="submit" class="btn btn-warning btn-sm">Salvar cron da memoria no arquivo</button>
                  </form>
                </div>
              </div>
            </cfif>
            <div class="table-responsive">
              <table class="table table-sm align-middle mb-0">
                <thead>
                  <tr>
                    <th>secret_ref</th>
                    <th>Fonte resolvida</th>
                    <th>Valor resolvido</th>
                    <th>No arquivo local</th>
                    <th>No APPLICATION em memoria</th>
                  </tr>
                </thead>
                <tbody>
                  <cfloop array="#configCheckExpectedSecrets#" index="secretRef">
                    <cfset VARIABLES.configCheckLocalSecret = structKeyExists(VARIABLES.configCheckLocalConfig, "cronSecrets") AND isStruct(VARIABLES.configCheckLocalConfig.cronSecrets) ? configCheckStructValue(VARIABLES.configCheckLocalConfig.cronSecrets, secretRef) : ""/>
                    <cfset VARIABLES.configCheckAppSecret = structKeyExists(APPLICATION, "cronJobs") AND isStruct(APPLICATION.cronJobs) AND structKeyExists(APPLICATION.cronJobs, "secrets") AND isStruct(APPLICATION.cronJobs.secrets) ? configCheckStructValue(APPLICATION.cronJobs.secrets, secretRef) : ""/>
                    <cfoutput>
                      <tr>
                        <td class="fw-semibold">#htmlEditFormat(secretRef)#</td>
                        <td>#htmlEditFormat(configCheckSecretSource(VARIABLES.configCheckLocalConfig, secretRef))#</td>
                        <td>#htmlEditFormat(configCheckMask(configCheckSecretValue(VARIABLES.configCheckLocalConfig, secretRef)))#</td>
                        <td>#htmlEditFormat(configCheckMask(VARIABLES.configCheckLocalSecret))#</td>
                        <td>#htmlEditFormat(configCheckMask(VARIABLES.configCheckAppSecret))#</td>
                      </tr>
                    </cfoutput>
                  </cfloop>
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <div class="card shadow-0 mb-4">
          <div class="card-body">
            <h2 class="h5 mb-3">Jobs que dependem de segredo</h2>
            <p class="text-muted small mb-3">Mostra todos os jobs com <code>auth_mode</code> diferente de <code>none</code> ou com <code>secret_ref</code> preenchido.</p>
            <cfif len(VARIABLES.configCheckCronJobsError)>
              <div class="alert alert-warning mb-0">
                Nao foi possivel consultar <code>tb_cron_jobs</code>: <cfoutput>#htmlEditFormat(VARIABLES.configCheckCronJobsError)#</cfoutput>
              </div>
            <cfelseif qConfigCheckCronJobs.recordcount>
              <div class="table-responsive">
                <table class="table table-sm align-middle mb-0">
                  <thead>
                    <tr>
                      <th>Job</th>
                      <th>Auth</th>
                      <th>secret_ref</th>
                      <th>Fonte resolvida</th>
                      <th>Status</th>
                      <th>Proxima</th>
                    </tr>
                  </thead>
                  <tbody>
                    <cfoutput query="qConfigCheckCronJobs">
                      <tr>
                        <td>
                          <div class="fw-semibold">#htmlEditFormat(qConfigCheckCronJobs.nome)#</div>
                          <div class="small text-muted">###qConfigCheckCronJobs.id_cron_job# · #htmlEditFormat(qConfigCheckCronJobs.projeto)#/#htmlEditFormat(qConfigCheckCronJobs.ambiente)# · <cfif qConfigCheckCronJobs.ativo>ativo<cfelse>inativo</cfif></div>
                        </td>
                        <td>#htmlEditFormat(qConfigCheckCronJobs.auth_mode)#</td>
                        <td><cfif len(trim(qConfigCheckCronJobs.secret_ref))>#htmlEditFormat(qConfigCheckCronJobs.secret_ref)#<cfelse><span class="text-muted">sem secret_ref</span></cfif></td>
                        <td>
                          <cfif len(trim(qConfigCheckCronJobs.secret_ref))>
                            #htmlEditFormat(configCheckSecretSource(VARIABLES.configCheckLocalConfig, qConfigCheckCronJobs.secret_ref))#
                            <div class="small text-muted">#htmlEditFormat(configCheckMask(configCheckSecretValue(VARIABLES.configCheckLocalConfig, qConfigCheckCronJobs.secret_ref)))#</div>
                          <cfelse>
                            <span class="text-muted">nao aplicavel</span>
                          </cfif>
                        </td>
                        <td>
                          <cfif len(trim(qConfigCheckCronJobs.last_status))>#htmlEditFormat(qConfigCheckCronJobs.last_status)#<cfelse><span class="text-muted">sem execucao</span></cfif>
                          <cfif len(trim(qConfigCheckCronJobs.last_http_status & ""))>
                            <div class="small text-muted">HTTP #htmlEditFormat(qConfigCheckCronJobs.last_http_status)#</div>
                          </cfif>
                          <cfif len(trim(qConfigCheckCronJobs.last_error))>
                            <div class="small text-danger text-break">#htmlEditFormat(left(qConfigCheckCronJobs.last_error, 180))#</div>
                          </cfif>
                        </td>
                        <td><cfif len(trim(qConfigCheckCronJobs.next_run_at & ""))>#dateTimeFormat(qConfigCheckCronJobs.next_run_at, "dd/mm/yyyy HH:nn")#<cfelse><span class="text-muted">-</span></cfif></td>
                      </tr>
                    </cfoutput>
                  </tbody>
                </table>
              </div>
            <cfelse>
              <div class="text-muted">Nenhum job com autenticacao/secret_ref encontrado.</div>
            </cfif>
          </div>
        </div>

        <div class="alert alert-warning mb-0">
          Esta pagina deve ser temporaria. Se precisar compartilhar um print, confirme que ele mostra apenas hashes/tamanhos e nao valores crus.
        </div>
      </section>
    </div>
  </main>

  <cfinclude template="../../includes/estrutura/footer.cfm"/>

</body>
</html>
