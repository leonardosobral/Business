<cfsetting requesttimeout="900" showdebugoutput="false">
<cfscript>
isApiExecution = structKeyExists(request, "sixCommEmailImporterExecutionMode")
  AND request.sixCommEmailImporterExecutionMode EQ "api";
reimportContentId = val(structKeyExists(form, "reimport_content_id") ? form.reimport_content_id : 0);
reimportMode = reimportContentId GT 0;
reimportTarget = {};
reimportMessageId = "";
hasAccess = (
  structKeyExists(session, "user")
  AND structKeyExists(session.user, "role")
  AND session.user.role EQ "admin"
);

if (!hasAccess AND !isApiExecution) {
  location(url="/admin/login", addtoken=false);
}

include "/inc/csrf.cfm";

function configText(required struct configData, required string keyName, string fallback = "") {
  if (!structKeyExists(arguments.configData, arguments.keyName) OR isNull(arguments.configData[arguments.keyName])) {
    return arguments.fallback;
  }
  return trim(arguments.configData[arguments.keyName] & "");
}

function truthy(value) {
  if (isBoolean(arguments.value)) {
    return arguments.value;
  }
  return listFindNoCase("1,true,t,yes,on", trim(arguments.value & "")) GT 0;
}

function lockWasAcquired(required query lockResult) {
  if (!arguments.lockResult.recordCount) {
    return false;
  }
  return truthy(arguments.lockResult.acquired[1]);
}

db = createObject("component", "inc.db");
configService = createObject("component", "inc.sixcomm_mail_config");
gmailClient = createObject("component", "inc.sixcomm_gmail_api");
configLoadError = "";
try { mailConfig = configService.loadConfig(); }
catch (any configError) {
  mailConfig = {};
  configLoadError = "Não foi possível carregar a configuração. Verifique o banco e cadastre novamente a senha de aplicativo.";
}
mailServer = "pop.gmail.com";
mailPort = 995;
mailUsername = "recent:contato@runnerhub.run";
mailPassword = configText(mailConfig, "sixCommMailPassword", "");
mailPasswordSource = configText(mailConfig, "sixCommMailPasswordSource", "none");
allowedImageHosts = lCase(configText(mailConfig, "sixCommAllowedImageHosts", "s3.us-east-1.wasabisys.com"));
configuredMaxRows = val(configText(mailConfig, "sixCommMailMaxRows", "5"));
configuredMaxRows = min(max(configuredMaxRows, 1), 5);
configuredScanRows = val(configText(mailConfig, "sixCommMailScanRows", "200"));
configuredScanRows = min(max(configuredScanRows, 25), 500);
pageAlertHtml = len(configLoadError) ? '<div class="alert alert-warning">' & encodeForHTML(configLoadError) & '</div>' : "";
importResponse = {};
shouldFetchMailbox = false;
mailFetchError = "";
mailMessages = queryNew("date,from,messagenumber,messageid,subject,body,textbody,htmlbody,header,attachmentfiles");
attachmentDirectory = "";
tempStorage = createObject("component", "inc.sixcomm_temp_storage");
lockAcquired = false;
lockKey = "sixcomm_email";
lockOwner = createUUID();
importer = createObject("component", "inc.sixcomm_email_importer");
popClient = createObject("component", "inc.sixcomm_pop_client");
gmailStatus = gmailClient.connectionStatus();
mailTransport = gmailStatus.connected ? "gmail_api" : "pop";
messageNumbers = [];
mailboxMessageCount = 0;
scanWindow = {startRow=1, maxRows=0};

if (!isApiExecution AND structKeyExists(session, "sixCommGmailFlash") AND isStruct(session.sixCommGmailFlash)) {
  flashType = listFindNoCase("success,warning,danger,info", session.sixCommGmailFlash.type ?: "")
    ? session.sixCommGmailFlash.type
    : "info";
  pageAlertHtml = '<div class="alert alert-' & flashType & '">' & encodeForHTML(session.sixCommGmailFlash.message ?: "") & '</div>';
  structDelete(session, "sixCommGmailFlash");
}

if (!isApiExecution AND cgi.request_method EQ "POST" AND trim(form.action ?: "") EQ "disconnect_gmail") {
  try {
    checkCsrf(trim(form.csrf ?: ""));
    gmailClient.disconnect();
    gmailStatus = gmailClient.connectionStatus();
    mailTransport = "pop";
    pageAlertHtml = '<div class="alert alert-success">A autorização da Gmail API foi removida deste sistema.</div>';
  } catch (any disconnectError) {
    pageAlertHtml = '<div class="alert alert-danger">Não foi possível remover a autorização do Gmail.</div>';
  }
}

if (!isApiExecution AND cgi.request_method EQ "POST" AND trim(form.action ?: "") EQ "save_config") {
  try {
    checkCsrf(trim(form.csrf ?: ""));
    submittedPassword = reReplace(trim(form.mail_password ?: ""), "\s+", "", "all");
    submittedMaxRows = min(max(val(form.max_rows ?: configuredMaxRows), 1), 5);
    configService.saveSettings(submittedPassword, submittedMaxRows);
    mailConfig = configService.loadConfig();
    mailPassword = configText(mailConfig, "sixCommMailPassword", "");
    mailPasswordSource = configText(mailConfig, "sixCommMailPasswordSource", "none");
    configuredMaxRows = min(max(val(configText(mailConfig, "sixCommMailMaxRows", submittedMaxRows)), 1), 5);
    pageAlertHtml = mailPasswordSource EQ "environment"
      ? '<div class="alert alert-warning">A senha foi salva, mas <code>SIXCOMM_MAIL_PASSWORD</code> está definida no ambiente e continua tendo precedência.</div>'
      : '<div class="alert alert-success">Configuração da caixa SixComm salva. A senha não é exibida nesta tela.</div>';
  } catch (any configError) {
    pageAlertHtml = '<div class="alert alert-danger">Não foi possível salvar a configuração. Verifique IMPORTER_HANDOFF_SECRET e o acesso ao banco.</div>';
  }
}

if (isApiExecution) {
  requestedMaxRows = val(form.max_messages ?: configuredMaxRows);
  configuredMaxRows = min(max(requestedMaxRows, 1), 5);
  shouldFetchMailbox = true;
} else if (cgi.request_method EQ "POST" AND trim(form.action ?: "") EQ "run_import") {
  try {
    checkCsrf(trim(form.csrf ?: ""));
    shouldFetchMailbox = true;
  } catch (any csrfError) {
    pageAlertHtml = '<div class="alert alert-danger">Sessão inválida. Recarregue a página e tente novamente.</div>';
  }
}

if (shouldFetchMailbox AND reimportMode) {
  try {
    reimportTarget = createObject("component", "inc.content_reimport_service").init(db).loadTarget(reimportContentId);
    if (!reimportTarget.found OR !reimportTarget.supported OR reimportTarget.importerKey NEQ "sixcomm_email") {
      throw(message="O conteúdo informado não pertence ao importador SixComm.");
    }
    reimportMessageId = trim(reimportTarget.sourceGuid ?: "");
    if (!len(reimportMessageId)) {
      throw(message="O vínculo SixComm não possui o Message-ID necessário para a reimportação.");
    }
    if (mailTransport NEQ "gmail_api") {
      throw(message="A reimportação individual da SixComm requer a conexão ativa com a Gmail API.");
    }
    configuredMaxRows = 1;
  } catch (any targetError) {
    mailFetchError = targetError.message ?: "Não foi possível preparar a reimportação SixComm.";
    shouldFetchMailbox = false;
  }
}

if (shouldFetchMailbox) {
  if (replace(mailUsername, "recent:", "", "one") NEQ "contato@runnerhub.run") {
    mailFetchError = "A caixa configurada precisa ser contato@runnerhub.run.";
    shouldFetchMailbox = false;
  } else if (mailTransport EQ "pop" AND !len(mailPassword)) {
    mailFetchError = "Conecte a Gmail API no painel. O fallback POP também está indisponível porque não há senha de aplicativo configurada.";
    shouldFetchMailbox = false;
  }
}

if (shouldFetchMailbox) {
  try {
    importer.prepareStorage(db);
    db.q("CREATE TABLE IF NOT EXISTS news.tb_importer_locks (lock_key TEXT PRIMARY KEY, owner TEXT NOT NULL, expires_at TIMESTAMPTZ NOT NULL)");
    lockResult = db.q("INSERT INTO news.tb_importer_locks(lock_key,owner,expires_at) VALUES (:lock_key,:owner,now()+interval '20 minutes') ON CONFLICT(lock_key) DO UPDATE SET owner=EXCLUDED.owner,expires_at=EXCLUDED.expires_at WHERE news.tb_importer_locks.expires_at < now() RETURNING true AS acquired", {
      lock_key: {value=lockKey, cfsqltype="cf_sql_varchar"},
      owner: {value=lockOwner, cfsqltype="cf_sql_varchar"}
    });
    lockAcquired = lockWasAcquired(lockResult);
    if (!lockAcquired) {
      mailFetchError = "O importador SixComm já está em execução.";
      shouldFetchMailbox = false;
    }
  } catch (any lockError) {
    mailFetchError = "Não foi possível preparar o importador. Verifique as tabelas, as permissões e os IDs editoriais 5/8/3.";
    shouldFetchMailbox = false;
  }
}

if (shouldFetchMailbox AND mailTransport EQ "pop") {
  try {
    mailboxStats = popClient.getStats(
      server = mailServer,
      port = mailPort,
      username = mailUsername,
      password = mailPassword,
      timeoutMs = 15000
    );
    mailboxMessageCount = mailboxStats.messageCount;
    scanWindow = popClient.buildScanWindow(mailboxMessageCount, configuredScanRows);
  } catch (any mailboxError) {
    mailFetchError = left(mailboxError.type ?: "", 12) EQ "SixComm.Pop."
      ? mailboxError.message
      : "Não foi possível consultar a caixa SixComm por uma falha interna do cliente POP.";
    shouldFetchMailbox = false;
  }
}

if (shouldFetchMailbox) {
  try {
    attachmentDirectory = tempStorage.createWorkingDirectory();
  } catch (any attachmentDirectoryError) {
    mailFetchError = findNoCase("SixComm.Storage.", attachmentDirectoryError.type ?: "") EQ 1
      ? attachmentDirectoryError.message
      : "Não foi possível preparar o diretório temporário para os anexos SixComm.";
    shouldFetchMailbox = false;
  }
}

if (shouldFetchMailbox AND mailTransport EQ "gmail_api") {
  try {
    gmailFetch = gmailClient.fetchMessages(
      maxMessages = configuredMaxRows,
      scanRows = configuredScanRows,
      attachmentDirectory = attachmentDirectory,
      db = db,
      importer = importer,
      messageId = reimportMessageId
    );
    mailMessages = gmailFetch.messages;
    mailboxMessageCount = gmailFetch.mailboxMessageCount;
    scanWindow = {startRow=1, maxRows=gmailFetch.scannedCount};
  } catch (any gmailError) {
    mailFetchError = findNoCase("SixComm.Gmail.", gmailError.type ?: "") EQ 1
      ? gmailError.message
      : "Não foi possível consultar a caixa SixComm pela Gmail API.";
    shouldFetchMailbox = false;
  }
}
</cfscript>

<cfif shouldFetchMailbox AND mailTransport EQ "pop" AND scanWindow.maxRows GT 0>
  <cftry>
    <cfpop
      server="#mailServer#"
      port="#mailPort#"
      username="#mailUsername#"
      password="#mailPassword#"
      action="getHeaderOnly"
      name="mailHeaders"
      secure="yes"
      timeout="45"
      startRow="#scanWindow.startRow#"
      maxRows="#scanWindow.maxRows#"
      debug="no">
    <cfset messageNumbers = importer.pendingMessageNumbers(mailHeaders, db, configuredMaxRows)>
    <cfif arrayLen(messageNumbers)>
      <cfpop server="#mailServer#" port="#mailPort#" username="#mailUsername#" password="#mailPassword#"
        action="getAll" name="mailMessages" secure="yes" timeout="45" debug="no"
        messageNumber="#arrayToList(messageNumbers)#" attachmentPath="#attachmentDirectory#" generateUniqueFilenames="yes">
    </cfif>
    <cfcatch type="any">
      <cfset mailFetchError = "Falha ao ler a caixa SixComm. Verifique POP, senha de aplicativo e acesso do servidor à porta 995.">
    </cfcatch>
  </cftry>
</cfif>

<cfscript>
if (shouldFetchMailbox AND !len(mailFetchError)) {
  if (reimportMode AND (!isQuery(mailMessages) OR mailMessages.recordCount EQ 0)) {
    mailFetchError = "O e-mail original vinculado ao conteúdo não foi localizado na Gmail API.";
  }
}

if (shouldFetchMailbox AND !len(mailFetchError)) {
  try {
    importer = createObject("component", "inc.sixcomm_email_importer");
    importResponse = importer.importMessages(
      messages = mailMessages,
      attachmentDirectory = attachmentDirectory,
      allowedImageHosts = allowedImageHosts,
      reimportContentId = reimportContentId
    );
  } catch (any importError) {
    mailFetchError = "Falha ao importar os e-mails SixComm. Verifique as tabelas e permissões de gravação de imagens.";
  }
}

if (lockAcquired) {
  try {
    db.q("DELETE FROM news.tb_importer_locks WHERE lock_key=:lock_key AND owner=:owner", {
      lock_key: {value=lockKey, cfsqltype="cf_sql_varchar"},
      owner: {value=lockOwner, cfsqltype="cf_sql_varchar"}
    });
  } catch (any ignoredUnlockError) {}
}

tempStorage.cleanup(attachmentDirectory);

if (len(mailFetchError)) {
  importResponse = {
    success = false,
    status = (findNoCase("já está em execução", mailFetchError) ? "locked" : "failed"),
    importer_key = "sixcomm_email",
    source_name = "SixComm",
    processed = 0,
    created = 0,
    updated = 0,
    skipped = 0,
    ignored = 0,
    errors = 1,
    importados = 0,
    duplicados = 0,
    erros = 1,
    message = mailFetchError,
    results = []
  };
}

if (structCount(importResponse)) {
  importResponse.transport = mailTransport;
  importResponse.mailbox_message_count = mailboxMessageCount;
}

if (isApiExecution) {
  request.sixCommEmailImporterResponse = importResponse;
} else if (structCount(importResponse)) {
  if (importResponse.success) {
    pageAlertHtml = '<div class="alert alert-success">Importação concluída: ' & importResponse.created & ' criada(s), ' & importResponse.skipped & ' duplicada(s) e ' & importResponse.ignored & ' ignorada(s).</div>';
  } else {
    pageAlertHtml = '<div class="alert alert-danger">' & encodeForHTML(importResponse.message ?: "A importação terminou com erros.") & '</div>';
  }
}

resultsHtml = "";
if (!isApiExecution AND structKeyExists(importResponse, "results") AND isArray(importResponse.results) AND arrayLen(importResponse.results)) {
  resultsHtml = '<div class="card mt-4"><div class="card-body"><h3 class="h5">Resultado</h3><div class="table-responsive"><table class="table align-middle"><thead><tr><th>Notícia</th><th>Ação</th><th>Detalhe</th></tr></thead><tbody>';
  for (resultItem in importResponse.results) {
    resultsHtml &= '<tr><td>' & encodeForHTML(resultItem.title ?: "Sem assunto") & '</td><td>' & encodeForHTML(resultItem.action ?: "-") & '</td><td>' & encodeForHTML(resultItem.message ?: "") & '</td></tr>';
  }
  resultsHtml &= '</tbody></table></div></div></div>';
}

if (!isApiExecution) {
  passwordSourceLabel = mailPasswordSource EQ "environment"
    ? "variável de ambiente"
    : (mailPasswordSource EQ "admin_encrypted" ? "painel, cifrada" : (mailPasswordSource EQ "local_file" ? "arquivo local" : "não configurada"));
  passwordStatus = len(mailPassword)
    ? '<span class="badge text-bg-success">Senha configurada: ' & encodeForHTML(passwordSourceLabel) & '</span>'
    : '<span class="badge text-bg-warning">Senha não configurada</span>';
  gmailStatusBadge = gmailStatus.connected
    ? '<span class="badge text-bg-success">Conectado: ' & encodeForHTML(gmailStatus.email) & '</span>'
    : (gmailStatus.configured
      ? '<span class="badge text-bg-warning">Não conectado</span>'
      : '<span class="badge text-bg-danger">OAuth não configurado</span>');
  gmailClientDetails = len(trim(gmailStatus.clientId ?: ""))
    ? '<div class="small mt-3"><div class="text-body-secondary mb-1">Client ID usado pelo importador</div><code class="user-select-all text-break">' & encodeForHTML(gmailStatus.clientId) & '</code><div class="form-text">O Client ID identifica o aplicativo e pode ser usado na pesquisa do Google Admin; ele não é o Client Secret.</div>'
      & (len(trim(gmailStatus.projectNumber ?: ""))
        ? '<a class="btn btn-sm btn-outline-secondary mt-2" href="https://console.cloud.google.com/apis/library/gmail.googleapis.com?project=' & encodeForURL(gmailStatus.projectNumber) & '" target="_blank" rel="noopener">Ativar Gmail API neste projeto</a>'
        : '')
      & '</div>'
    : '';
  pageBody = '
    <div class="card card-soft">
      <div class="card-body p-4">
        <div class="admin-page-header mb-4">
          <div>
            <h2 class="h3 mb-2">Importador de e-mail SixComm</h2>
            <p class="text-body-secondary mb-0">Importa releases autenticados enviados por <code>danilo@gruposix.com.br</code> para <code>contato@runnerhub.run</code>.</p>
          </div>
        </div>
        ' & pageAlertHtml & '
        <div class="alert alert-light border">
          <strong>Mapeamento fixo:</strong> canal SixComm (ID 5), autor Danilo Caboclo (ID 8), categoria Release (ID 3) e status Pendente de curadoria. A primeira foto vira capa; as demais formam a galeria ao final da notícia.
        </div>
        <div class="row g-4">
          <div class="col-12 col-xl-7">
            <div class="border rounded-4 p-4 h-100">
              <h3 class="h5 mb-3">Executar importação</h3>
              <p class="text-body-secondary">Busca pela Gmail API as mensagens SixComm ainda não importadas nos últimos 30 dias, incluindo tentativas que falharam. O acesso usa HTTPS e funciona sem liberar a porta POP 995.</p>
              <form method="post" action="/admin/importer_sixcomm_email">
                ' & csrfField() & '
                <input type="hidden" name="action" value="run_import">
                <button class="btn btn-primary" type="submit"' & (!gmailStatus.connected AND !len(mailPassword) ? ' disabled' : '') & '>Verificar caixa agora</button>
              </form>
            </div>
          </div>
          <div class="col-12 col-xl-5">
            <div class="border rounded-4 p-4 h-100">
              <div class="d-flex justify-content-between align-items-center gap-3 mb-3">
                <h3 class="h5 mb-0">Gmail API</h3>
                ' & gmailStatusBadge & '
              </div>
              <p class="small text-body-secondary">Autorize somente a leitura da caixa <code>contato@runnerhub.run</code>. O refresh token fica cifrado no servidor e permite a execução automática do cron.</p>
              ' & gmailClientDetails & '
              ' & (gmailStatus.connected ? '
                <form method="post" action="/admin/importer_sixcomm_email">
                  ' & csrfField() & '
                  <input type="hidden" name="action" value="disconnect_gmail">
                  <button class="btn btn-outline-danger" type="submit">Desconectar Gmail</button>
                </form>' : '
                <a class="btn btn-outline-primary" href="/admin/sixcomm_gmail_auth">Conectar conta Google</a>') & '
              ' & (!gmailStatus.configured ? '<div class="alert alert-warning small mt-3 mb-0">O cliente OAuth do Google ou <code>IMPORTER_HANDOFF_SECRET</code> ainda não está configurado neste ambiente.</div>' : '') & '
            </div>
          </div>
          <div class="col-12">
            <details class="border rounded-4 p-4">
              <summary class="fw-semibold">Fallback POP legado</summary>
              <div class="d-flex justify-content-between align-items-center gap-3 my-3">
                <div class="small text-body-secondary"><code>pop.gmail.com:995</code> · <code>recent:contato@runnerhub.run</code></div>
                ' & passwordStatus & '
              </div>
              <p class="small text-body-secondary">Este caminho só é usado quando a Gmail API não está conectada e depende de a hospedagem liberar saída TCP na porta 995.</p>
              <form method="post" action="/admin/importer_sixcomm_email" class="vstack gap-3">
                ' & csrfField() & '
                <input type="hidden" name="action" value="save_config">
                <div>
                  <label class="form-label" for="mail_password">Senha de aplicativo do Google</label>
                  <input class="form-control" id="mail_password" name="mail_password" type="password" autocomplete="new-password" placeholder="Deixe vazio para manter a atual">
                  <div class="form-text">A senha é cifrada antes de ser armazenada. Use uma senha de aplicativo exclusiva desta integração.</div>
                  ' & (mailPasswordSource EQ "environment" ? '<div class="form-text text-warning"><code>SIXCOMM_MAIL_PASSWORD</code> está ativa e substitui o valor salvo neste formulário.</div>' : '') & '
                </div>
                <div>
                  <label class="form-label" for="max_rows">Máximo de mensagens por execução</label>
                  <input class="form-control" id="max_rows" name="max_rows" type="number" min="1" max="5" value="' & configuredMaxRows & '">
                  <div class="form-text">Lotes pequenos evitam o timeout de 100 segundos da Cloudflare. As próximas execuções continuam pelas mensagens ainda não importadas.</div>
                </div>
                <button class="btn btn-outline-primary" type="submit">Salvar configuração</button>
              </form>
            </details>
          </div>
        </div>
        ' & resultsHtml & '
      </div>
    </div>';
}
</cfscript>

<cfif NOT isApiExecution>
  <cfoutput>#renderLayout({title="Importador SixComm", body=pageBody})#</cfoutput>
</cfif>

<cffunction name="renderLayout" returntype="string" output="false">
  <cfargument name="args" type="struct" required="true">
  <cfset request.layoutArgs = duplicate(arguments.args)>
  <cfsavecontent variable="html"><cfinclude template="/inc/layout.cfm"></cfsavecontent>
  <cfset structDelete(request, "layoutArgs")>
  <cfreturn html>
</cffunction>
