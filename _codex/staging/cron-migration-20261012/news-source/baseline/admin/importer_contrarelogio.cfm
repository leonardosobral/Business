<cfscript>
feedImporterConfig = {
    execution_mode_key = "contrarelogioImporterExecutionMode",
    response_key = "contrarelogioImporterResponse",
    importer_key = "contrarelogio_feed",
    source_name = "Contra Relógio",
    content_type_name = "Contra Relógio",
    feed_url = "https://contrarelogio.com.br/feed/",
    base_url = "https://contrarelogio.com.br/",
    admin_path = "/admin/importer_contrarelogio",
    page_title = "Importador Contra Relógio",
    source_kind = "wordpress",
    sitemap_url = "",
    sitemap_items_per_page = 10,
    default_responsible_editor_id = 6,
    author_email_domain = "contrarelogio.import.runnerhub.local",
    audit_suffix = "contrarelogio",
    media_repair_url_fragment = "contrarelogio.com.br/wp-content/uploads/",
    use_persisted_session = true,
    require_source_publication_date = true,
    mapping_description = "Canal local fixo: <strong>Contra Relógio</strong>. O autor é identificado notícia a notícia pelo <code>dc:creator</code> do feed. Quando o autor não existir localmente, o sistema cria um usuário do tipo <strong>autor</strong> vinculado ao editor responsável definido abaixo. O padrão atual é a usuária <strong>Fernanda Paradizo</strong> (ID 6, <code>feparadizo@gmail.com</code>). A primeira categoria do feed entra como categoria principal; todas as categorias do feed entram também como tags para não perder contexto temático. A data <code>pubDate</code> é gravada como data de publicação da plataforma. A origem, GUID, autor de origem e metadados do feed ficam registrados para deduplicação e auditoria."
};

if (structKeyExists(request, "feedImporterConfig") AND isStruct(request.feedImporterConfig)) {
    structAppend(feedImporterConfig, request.feedImporterConfig, true);
}

executionModeKey = feedImporterConfig.execution_mode_key;
responseKey = feedImporterConfig.response_key;
isApiExecution = structKeyExists(request, executionModeKey) AND request[executionModeKey] EQ "api";
hasAccess = (
    structKeyExists(session, "user")
    AND structKeyExists(session.user, "role")
    AND session.user.role EQ "admin"
);

if (NOT hasAccess AND NOT isApiExecution) {
    location(url="/admin/login", addtoken=false);
}

function textOrFallback(value, string fallback="") {
    if (isNull(arguments.value)) {
        return arguments.fallback;
    }

    local.textValue = trim(arguments.value & "");
    if (!len(local.textValue) OR local.textValue EQ "null") {
        return arguments.fallback;
    }

    return local.textValue;
}

function extractGeneratedId(resultSet) {
    if (isQuery(arguments.resultSet) AND structKeyExists(arguments.resultSet, "id") AND arguments.resultSet.recordCount) {
        return val(arguments.resultSet.id[1]);
    }

    if (isStruct(arguments.resultSet) AND structKeyExists(arguments.resultSet, "generatedKey")) {
        return val(arguments.resultSet.generatedKey);
    }

    return 0;
}

function buildSlugBase(required string sourceText) {
    var slugBase = lCase(trim(arguments.sourceText));

    slugBase = replaceList(
        slugBase,
        "á,à,â,ã,ä,å,é,è,ê,ë,í,ì,î,ï,ó,ò,ô,õ,ö,ú,ù,û,ü,ç,ñ,ý,ÿ,æ,œ",
        "a,a,a,a,a,a,e,e,e,e,i,i,i,i,o,o,o,o,o,u,u,u,u,c,n,y,y,ae,oe"
    );
    slugBase = reReplace(slugBase, "[^a-z0-9]+", "-", "all");
    slugBase = reReplace(slugBase, "^-+|-+$", "", "all");

    return len(slugBase) ? slugBase : "conteudo";
}

function buildUniqueSlug(required any db, required string sourceText, numeric currentId=0) {
    var slugBase = buildSlugBase(arguments.sourceText);
    var candidate = slugBase;
    var suffix = 2;
    var lookup = "";

    while (true) {
        lookup = arguments.db.q("
          SELECT id
          FROM news.tb_content
          WHERE slug = :slug
            AND id <> :id
          LIMIT 1
        ", {
          slug: {value=candidate, cfsqltype="cf_sql_varchar"},
          id: {value=arguments.currentId, cfsqltype="cf_sql_integer"}
        });

        if (!lookup.recordCount) {
            return candidate;
        }

        candidate = slugBase & "-" & suffix;
        suffix = suffix + 1;
    }
}

function loadImporterLocalConfig() {
    return createObject("component", "inc.content_local_config").loadConfig();
}

function getContraRelogioRequestSettings() {
    var localConfig = loadImporterLocalConfig();
    var configuredCookie = "";
    var configuredUserAgent = "";
    var configuredAccept = "";
    var configuredAcceptLanguage = "";
    var configuredRetryCount = 0;
    var configuredRetryDelayMs = 0;

    if (isStruct(localConfig)) {
        if (structKeyExists(localConfig, "contraRelogioFeedCookie")) {
            configuredCookie = trim(localConfig.contraRelogioFeedCookie ?: "");
        }
        if (structKeyExists(localConfig, "contraRelogioFeedUserAgent")) {
            configuredUserAgent = trim(localConfig.contraRelogioFeedUserAgent ?: "");
        }
        if (structKeyExists(localConfig, "contraRelogioFeedAccept")) {
            configuredAccept = trim(localConfig.contraRelogioFeedAccept ?: "");
        }
        if (structKeyExists(localConfig, "contraRelogioFeedAcceptLanguage")) {
            configuredAcceptLanguage = trim(localConfig.contraRelogioFeedAcceptLanguage ?: "");
        }
        if (structKeyExists(localConfig, "contraRelogioFeedRetryCount")) {
            configuredRetryCount = val(localConfig.contraRelogioFeedRetryCount ?: 0);
        }
        if (structKeyExists(localConfig, "contraRelogioFeedRetryDelayMs")) {
            configuredRetryDelayMs = val(localConfig.contraRelogioFeedRetryDelayMs ?: 0);
        }
    }

    if (!len(configuredUserAgent)) {
        configuredUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36";
    }

    if (!len(configuredAccept)) {
        configuredAccept = "application/rss+xml, application/xml, text/xml;q=0.9, */*;q=0.8";
    }

    if (!len(configuredAcceptLanguage)) {
        configuredAcceptLanguage = "pt-BR,pt;q=0.9,en-US;q=0.8,en;q=0.7";
    }

    if (configuredRetryCount LTE 0) {
        configuredRetryCount = 3;
    } else if (configuredRetryCount GT 10) {
        configuredRetryCount = 10;
    }

    if (configuredRetryDelayMs LTE 0) {
        configuredRetryDelayMs = 5000;
    } else if (configuredRetryDelayMs GT 60000) {
        configuredRetryDelayMs = 60000;
    }

    return {
        cookie = configuredCookie,
        userAgent = configuredUserAgent,
        accept = configuredAccept,
        acceptLanguage = configuredAcceptLanguage,
        retryCount = configuredRetryCount,
        retryDelayMs = configuredRetryDelayMs
    };
}

function pauseMilliseconds(numeric delayMs = 0) {
    var normalizedDelay = val(arguments.delayMs);

    if (normalizedDelay GT 0) {
        createObject("java", "java.lang.Thread").sleep(javaCast("long", normalizedDelay));
    }
}

function shouldUseContraRelogioSession(string requestUrl = "") {
    var normalizedUrl = lCase(trim(arguments.requestUrl));

    if (!variables.feedImporterConfig.use_persisted_session) {
        return false;
    }

    return findNoCase("https://contrarelogio.com.br/", normalizedUrl) EQ 1
        OR findNoCase("http://contrarelogio.com.br/", normalizedUrl) EQ 1
        OR findNoCase("https://www.contrarelogio.com.br/", normalizedUrl) EQ 1
        OR findNoCase("http://www.contrarelogio.com.br/", normalizedUrl) EQ 1;
}

function decodeHtmlEntities(string rawValue="") {
    var textValue = trim(arguments.rawValue);
    var hashChar = chr(35);

    if (!len(textValue)) {
        return textValue;
    }

    textValue = replaceNoCase(textValue, "&amp;", "&", "all");
    textValue = replaceNoCase(textValue, "&quot;", chr(34), "all");
    textValue = replaceNoCase(textValue, "&apos;", chr(39), "all");
    textValue = replaceNoCase(textValue, "&nbsp;", " ", "all");
    textValue = replaceNoCase(textValue, "&hellip;", "...", "all");
    textValue = replaceNoCase(textValue, "&ndash;", "-", "all");
    textValue = replaceNoCase(textValue, "&mdash;", "-", "all");
    textValue = replaceNoCase(textValue, "&lsquo;", chr(39), "all");
    textValue = replaceNoCase(textValue, "&rsquo;", chr(39), "all");
    textValue = replaceNoCase(textValue, "&ldquo;", chr(34), "all");
    textValue = replaceNoCase(textValue, "&rdquo;", chr(34), "all");
    textValue = replaceNoCase(textValue, "&lt;", "<", "all");
    textValue = replaceNoCase(textValue, "&gt;", ">", "all");
    textValue = replaceNoCase(textValue, "&aacute;", "á", "all");
    textValue = replaceNoCase(textValue, "&eacute;", "é", "all");
    textValue = replaceNoCase(textValue, "&iacute;", "í", "all");
    textValue = replaceNoCase(textValue, "&oacute;", "ó", "all");
    textValue = replaceNoCase(textValue, "&uacute;", "ú", "all");
    textValue = replaceNoCase(textValue, "&atilde;", "ã", "all");
    textValue = replaceNoCase(textValue, "&otilde;", "õ", "all");
    textValue = replaceNoCase(textValue, "&acirc;", "â", "all");
    textValue = replaceNoCase(textValue, "&ecirc;", "ê", "all");
    textValue = replaceNoCase(textValue, "&ocirc;", "ô", "all");
    textValue = replaceNoCase(textValue, "&ccedil;", "ç", "all");
    textValue = replaceNoCase(textValue, "&Aacute;", "Á", "all");
    textValue = replaceNoCase(textValue, "&Eacute;", "É", "all");
    textValue = replaceNoCase(textValue, "&Iacute;", "Í", "all");
    textValue = replaceNoCase(textValue, "&Oacute;", "Ó", "all");
    textValue = replaceNoCase(textValue, "&Uacute;", "Ú", "all");
    textValue = replaceNoCase(textValue, "&Atilde;", "Ã", "all");
    textValue = replaceNoCase(textValue, "&Otilde;", "Õ", "all");
    textValue = replaceNoCase(textValue, "&Acirc;", "Â", "all");
    textValue = replaceNoCase(textValue, "&Ecirc;", "Ê", "all");
    textValue = replaceNoCase(textValue, "&Ocirc;", "Ô", "all");
    textValue = replaceNoCase(textValue, "&Ccedil;", "Ç", "all");
    textValue = replaceNoCase(textValue, "&" & hashChar & "038;", "&", "all");
    textValue = replaceNoCase(textValue, "&" & hashChar & "8211;", "-", "all");
    textValue = replaceNoCase(textValue, "&" & hashChar & "8212;", "-", "all");
    textValue = replaceNoCase(textValue, "&" & hashChar & "8216;", chr(39), "all");
    textValue = replaceNoCase(textValue, "&" & hashChar & "8217;", chr(39), "all");
    textValue = replaceNoCase(textValue, "&" & hashChar & "8220;", chr(34), "all");
    textValue = replaceNoCase(textValue, "&" & hashChar & "8221;", chr(34), "all");
    textValue = replaceNoCase(textValue, "&" & hashChar & "8230;", "...", "all");
    textValue = replaceNoCase(textValue, "&" & hashChar & "124;", "|", "all");
    textValue = replaceNoCase(textValue, "&" & hashChar & "039;", chr(39), "all");
    textValue = replaceNoCase(textValue, "&" & hashChar & "39;", chr(39), "all");

    return textValue;
}

function stripHtmlTags(string rawValue="") {
    var textValue = reReplace(arguments.rawValue, "<[^>]+>", " ", "all");
    textValue = decodeHtmlEntities(textValue);
    textValue = reReplace(textValue, "\s+", " ", "all");
    return trim(textValue);
}

function sanitizeUploadFileName(required string originalFileName) {
    var normalized = trim(arguments.originalFileName);
    var baseName = "";
    var extension = "";
    var safeBaseName = "";

    if (!len(normalized)) {
        return "arquivo";
    }

    extension = listLast(normalized, ".");
    if (len(extension) AND listLen(normalized, ".") GT 1) {
        baseName = left(normalized, len(normalized) - len(extension) - 1);
    } else {
        baseName = normalized;
        extension = "";
    }

    safeBaseName = buildSlugBase(baseName);
    extension = lCase(trim(extension));
    extension = reReplace(extension, "[^a-z0-9]+", "", "all");

    if (len(extension)) {
        return safeBaseName & "." & extension;
    }

    return safeBaseName;
}

function buildUniqueUploadName(required string directoryPath, required string originalFileName) {
    var safeName = sanitizeUploadFileName(arguments.originalFileName);
    var extension = listLast(safeName, ".");
    var baseName = "";
    var candidate = safeName;
    var suffix = 1;

    if (len(extension) AND listLen(safeName, ".") GT 1) {
        baseName = left(safeName, len(safeName) - len(extension) - 1);
    } else {
        baseName = safeName;
        extension = "";
    }

    while (fileExists(arguments.directoryPath & "/" & candidate)) {
        if (len(extension)) {
            candidate = baseName & "-" & suffix & "." & extension;
        } else {
            candidate = baseName & "-" & suffix;
        }
        suffix = suffix + 1;
    }

    return candidate;
}

function moveUploadedFileToSafeName(required string directoryPath, required string currentFileName, required string targetFileName) {
    var currentPath = arguments.directoryPath & "/" & arguments.currentFileName;
    var targetPath = arguments.directoryPath & "/" & arguments.targetFileName;
    var tempName = "";
    var tempPath = "";
    var sourcePath = currentPath;

    if (compare(arguments.currentFileName, arguments.targetFileName) EQ 0) {
        return;
    }

    if (compareNoCase(arguments.currentFileName, arguments.targetFileName) EQ 0) {
        tempName = "__upload_tmp__" & createUUID() & "__" & arguments.targetFileName;
        tempPath = arguments.directoryPath & "/" & tempName;
        fileMove(currentPath, tempPath);
        sourcePath = tempPath;
    }

    fileCopy(sourcePath, targetPath);

    if (fileExists(sourcePath) AND compare(sourcePath, targetPath) NEQ 0) {
        fileDelete(sourcePath);
    }

    if (fileExists(currentPath) AND compare(currentPath, targetPath) NEQ 0) {
        fileDelete(currentPath);
    }

    if (NOT fileExists(targetPath)) {
        throw(message="Não foi possível gravar o arquivo com o nome final seguro.");
    }
}

function resolveUploadDirectory() {
    var configuredDir = "";
    var currentHost = "";
    var currentDirectory = getDirectoryFromPath(getCurrentTemplatePath());
    var projectRoot = reReplace(currentDirectory, "[\\/]admin[\\/]*$", "/", "one");
    var fallbackDir = projectRoot & "public/uploads";
    var productionUploadDir = "/var/www/conteudo.roadrunners.run/public/uploads";

    if (structKeyExists(cgi, "http_host")) {
        currentHost = lCase(trim(cgi.http_host & ""));
    }

    if (structKeyExists(application, "uploadDir")) {
        configuredDir = trim(application.uploadDir & "");
    }

    if (currentHost EQ "conteudo.roadrunners.run" OR currentHost EQ "www.conteudo.roadrunners.run") {
        configuredDir = productionUploadDir;
    } else if (
        !len(configuredDir)
        OR findNoCase("/publico/uploads", configuredDir) EQ 1
        OR findNoCase("/public/uploads", configuredDir) EQ 1
    ) {
        configuredDir = fallbackDir;
    }

    application.uploadDir = configuredDir;
    application.uploadBaseUrl = "/public/uploads";
    return configuredDir;
}

function fileNameFromUrl(required string rawUrl) {
    var normalizedUrl = decodeHtmlEntities(arguments.rawUrl);
    var cleanUrl = listFirst(normalizedUrl, "?");
    var fileName = listLast(cleanUrl, "/");

    if (!len(trim(fileName))) {
        fileName = "arquivo-remoto";
    }

    return fileName;
}

function stripTrackingParams(required string rawUrl) {
    var normalizedUrl = decodeHtmlEntities(arguments.rawUrl);
    return listFirst(normalizedUrl, "?");
}

function mediaKeyFromUrl(string rawUrl = "") {
    var normalizedUrl = stripTrackingParams(arguments.rawUrl);
    var fileName = lCase(trim(listLast(normalizedUrl, "/")));

    if (!len(fileName)) {
        fileName = lCase(trim(normalizedUrl));
    }

    return fileName;
}

function normalizePersonName(string rawName="") {
    var normalized = lCase(trim(arguments.rawName));

    normalized = replaceList(
        normalized,
        "á,à,â,ã,ä,å,é,è,ê,ë,í,ì,î,ï,ó,ò,ô,õ,ö,ú,ù,û,ü,ç,ñ,ý,ÿ,æ,œ",
        "a,a,a,a,a,a,e,e,e,e,i,i,i,i,o,o,o,o,o,u,u,u,u,c,n,y,y,ae,oe"
    );
    normalized = reReplace(normalized, "\s+", " ", "all");

    return trim(normalized);
}

function buildAuthorImportEmail(required string displayName) {
    var emailBase = buildSlugBase(arguments.displayName);
    return emailBase & "@" & variables.feedImporterConfig.author_email_domain;
}

function extractTagValue(required string sourceXml, required string tagName) {
    var cdataMatches = reMatchNoCase("<" & arguments.tagName & "[^>]*><!\[CDATA\[[\s\S]*?\]\]></" & arguments.tagName & ">", arguments.sourceXml);
    var plainMatches = "";
    var rawTag = "";

    if (arrayLen(cdataMatches)) {
        rawTag = cdataMatches[1];
        return reReplaceNoCase(rawTag, "^<[^>]+><!\[CDATA\[([\s\S]*?)\]\]></[^>]+>$", "\1", "one");
    }

    plainMatches = reMatchNoCase("<" & arguments.tagName & "[^>]*>[\s\S]*?</" & arguments.tagName & ">", arguments.sourceXml);
    if (arrayLen(plainMatches)) {
        rawTag = plainMatches[1];
        rawTag = reReplaceNoCase(rawTag, "^<[^>]+>([\s\S]*?)</[^>]+>$", "\1", "one");
        return decodeHtmlEntities(rawTag);
    }

    return "";
}

function extractCategories(required string itemXml) {
    var categories = [];
    var rawMatches = reMatchNoCase("<category[^>]*>[\s\S]*?</category>", arguments.itemXml);
    var matchValue = "";
    var cleanedValue = "";

    for (matchValue in rawMatches) {
        cleanedValue = reReplaceNoCase(matchValue, "^<category[^>]*>([\s\S]*?)</category>$", "\1", "one");
        cleanedValue = reReplaceNoCase(cleanedValue, "^<!\[CDATA\[([\s\S]*?)\]\]>$", "\1", "one");
        cleanedValue = decodeHtmlEntities(cleanedValue);
        cleanedValue = trim(cleanedValue);

        if (len(cleanedValue) AND !findArrayValueNoCase(categories, cleanedValue)) {
            arrayAppend(categories, cleanedValue);
        }
    }

    return categories;
}

function findArrayValueNoCase(required array values, required string targetValue) {
    var idx = 0;

    for (idx = 1; idx <= arrayLen(arguments.values); idx = idx + 1) {
        if (compareNoCase(arguments.values[idx], arguments.targetValue) EQ 0) {
            return idx;
        }
    }

    return 0;
}

function extractMediaUrl(required string itemXml) {
    var matches = reMatchNoCase("<media:content[^>]+url=""[^""]+""[^>]*>", arguments.itemXml);

    if (arrayLen(matches)) {
        return decodeHtmlEntities(reReplaceNoCase(matches[1], '^<media:content[^>]+url="([^"]+)".*$', "\1", "one"));
    }

    matches = reMatchNoCase('<enclosure\b[^>]*\burl="[^"]+"[^>]*>', arguments.itemXml);
    if (arrayLen(matches)) {
        return decodeHtmlEntities(reReplaceNoCase(matches[1], '^<enclosure\b[^>]*\burl="([^"]+)".*$', "\1", "one"));
    }

    return "";
}

function extractMetadataImageUrl(string htmlContent = "") {
    var metaTags = reMatchNoCase('<meta\b[^>]*>', arguments.htmlContent);
    var metaTag = "";
    var contentMatches = [];

    for (metaTag in metaTags) {
        if (!reFindNoCase('(property|name)\s*=\s*["''](?:og:image(?::secure_url)?|twitter:image)["'']', metaTag)) {
            continue;
        }

        contentMatches = reMatchNoCase('content\s*=\s*"([^"]+)"', metaTag);
        if (arrayLen(contentMatches)) {
            return decodeHtmlEntities(reReplaceNoCase(contentMatches[1], '^content\s*=\s*"([^"]+)".*$', "\1", "one"));
        }

        contentMatches = reMatchNoCase("content\s*=\s*'([^']+)'", metaTag);
        if (arrayLen(contentMatches)) {
            return decodeHtmlEntities(reReplaceNoCase(contentMatches[1], "^content\s*=\s*'([^']+)'.*$", "\1", "one"));
        }
    }

    return "";
}

function extractImageSourceFromTag(required string imageTag) {
    var attributePatterns = [
        '\bdata-pin-media="([^"]+)"',
        "\bdata-pin-media='([^']+)'",
        '\bsrc="([^"]+)"',
        "\bsrc='([^']+)'",
        '\bdata-src="([^"]+)"',
        "\bdata-src='([^']+)'",
        '\bdata-lazy-src="([^"]+)"',
        "\bdata-lazy-src='([^']+)'"
    ];
    var attributePattern = "";
    var matches = "";

    for (attributePattern in attributePatterns) {
        matches = reMatchNoCase(attributePattern, arguments.imageTag);
        if (arrayLen(matches)) {
            return decodeHtmlEntities(reReplaceNoCase(matches[1], '^[^=]+=["'']([^"''>]+).*$', "\1", "one"));
        }
    }

    return "";
}

function resolveRemoteUrl(string rawUrl = "", string baseUrl = "") {
    var candidateUrl = trim(decodeHtmlEntities(arguments.rawUrl));
    var resolvedUrl = "";
    var baseUri = "";
    var effectiveBaseUrl = len(trim(arguments.baseUrl)) ? arguments.baseUrl : variables.feedImporterConfig.base_url;

    if (!len(candidateUrl)) {
        return "";
    }

    if (reFindNoCase("^https?://", candidateUrl)) {
        return candidateUrl;
    }

    if (left(candidateUrl, 2) EQ "//") {
        return "https:" & candidateUrl;
    }

    try {
        baseUri = createObject("java", "java.net.URI").init(effectiveBaseUrl);
        resolvedUrl = baseUri.resolve(candidateUrl).toString();
        return trim(resolvedUrl);
    } catch (any resolveError) {}

    if (left(candidateUrl, 1) EQ "/") {
        try {
            baseUri = createObject("java", "java.net.URI").init(variables.feedImporterConfig.base_url);
            return baseUri.resolve(candidateUrl).toString();
        } catch (any fallbackResolveError) {}
    }

    return candidateUrl;
}

function absolutizeImageAttributes(string htmlContent = "", string baseUrl = "") {
    var resultHtml = arguments.htmlContent;
    var imageTags = reMatchNoCase('<img\b[^>]*>', arguments.htmlContent);
    var imageTag = "";
    var originalValue = "";
    var absoluteValue = "";
    var attributePattern = "";
    var attributePatterns = [
        '\bdata-pin-media="([^"]+)"',
        "\bdata-pin-media='([^']+)'",
        '\bsrc="([^"]+)"',
        "\bsrc='([^']+)'",
        '\bdata-src="([^"]+)"',
        "\bdata-src='([^']+)'",
        '\bdata-lazy-src="([^"]+)"',
        "\bdata-lazy-src='([^']+)'"
    ];

    for (imageTag in imageTags) {
        for (attributePattern in attributePatterns) {
            if (reFindNoCase(attributePattern, imageTag)) {
                originalValue = reReplaceNoCase(imageTag, ".*" & attributePattern & ".*", "\1", "one");
                absoluteValue = resolveRemoteUrl(originalValue, arguments.baseUrl);

                if (len(absoluteValue) AND absoluteValue NEQ originalValue) {
                    resultHtml = replaceNoCase(resultHtml, originalValue, absoluteValue, "all");
                }
            }
        }
    }

    return resultHtml;
}

function extractFirstImageUrl(string htmlContent="") {
    var normalizedHtml = trim(arguments.htmlContent);
    var matches = "";
    var imageTag = "";
    var imageUrl = "";

    if (!len(normalizedHtml)) {
        return "";
    }

    matches = reMatchNoCase('<img\b[^>]*>', normalizedHtml);
    for (imageTag in matches) {
        imageTag = trim(imageTag);
        if (len(imageTag)) {
            imageUrl = extractImageSourceFromTag(imageTag);
            if (len(imageUrl)) {
                return imageUrl;
            }
        }
    }

    return "";
}

function normalizeComparableMediaUrl(string rawUrl="") {
    var normalizedUrl = trim(decodeHtmlEntities(arguments.rawUrl));

    if (!len(normalizedUrl)) {
        return "";
    }

    normalizedUrl = stripTrackingParams(normalizedUrl);
    return lCase(trim(normalizedUrl));
}

function storeUploadedManualMediaFiles(required numeric authorId, required any db) {
    var uploadFieldName = "manual_feed_images";
    var requestContentType = lCase(trim(cgi.content_type ?: ""));
    var uploadDirectory = resolveUploadDirectory();
    var uploadedFiles = [];
    var uploadedFile = {};
    var safeFileName = "";
    var inserted = "";
    var originalFileName = "";
    var normalizedKey = "";
    var fileUrl = "";
    var result = {
        by_url = {},
        by_filename = {},
        total = 0
    };

    if (findNoCase("multipart/form-data", requestContentType) EQ 0) {
        return result;
    }

    if (!directoryExists(uploadDirectory)) {
        directoryCreate(uploadDirectory);
    }

    try {
        uploadedFiles = fileUploadAll(uploadDirectory, uploadFieldName, "image/*,.jpg,.jpeg,.png,.gif,.webp,.svg,.bmp,.avif", false);
    } catch (any uploadError) {
        if (findNoCase(uploadFieldName, textOrFallback(uploadError.message, "")) GT 0 OR findNoCase("No files", textOrFallback(uploadError.message, "")) GT 0) {
            return result;
        }

        rethrow;
    }

    if (!isArray(uploadedFiles)) {
        return result;
    }

    for (uploadedFile in uploadedFiles) {
        if (!isStruct(uploadedFile)) {
            continue;
        }

        originalFileName = textOrFallback(uploadedFile.clientFile ?: "", textOrFallback(uploadedFile.serverFile ?: "", "arquivo"));
        safeFileName = buildUniqueUploadName(uploadDirectory, originalFileName);
        moveUploadedFileToSafeName(uploadDirectory, uploadedFile.serverFile, safeFileName);
        fileUrl = "/public/uploads/" & safeFileName;

        inserted = arguments.db.q("
          INSERT INTO news.tb_media (filename, orig_name, mime_type, size_bytes, url_public, author_id)
          VALUES (:fn, :orig, :mime, :size, :url, :uid)
          RETURNING id
        ", {
          fn:   {value=safeFileName, cfsqltype="cf_sql_varchar"},
          orig: {value=originalFileName, cfsqltype="cf_sql_varchar"},
          mime: {value=textOrFallback(uploadedFile.contentType ?: "application/octet-stream", "application/octet-stream"), cfsqltype="cf_sql_varchar"},
          size: {value=val(uploadedFile.fileSize ?: 0), cfsqltype="cf_sql_integer"},
          url:  {value=fileUrl, cfsqltype="cf_sql_varchar"},
          uid:  {value=arguments.authorId, cfsqltype="cf_sql_integer"}
        });

        normalizedKey = mediaKeyFromUrl(originalFileName);
        if (len(normalizedKey)) {
            result.by_filename[normalizedKey] = {
                media_id = extractGeneratedId(inserted),
                url_public = fileUrl,
                original_name = originalFileName
            };
        }

        normalizedKey = mediaKeyFromUrl(fileUrl);
        if (len(normalizedKey)) {
            result.by_url[normalizedKey] = {
                media_id = extractGeneratedId(inserted),
                url_public = fileUrl,
                original_name = originalFileName
            };
        }

        result.total = result.total + 1;
    }

    return result;
}

function stripLeadingFeaturedImageBlock(string htmlContent="", string remoteMediaUrl="", string localMediaUrl="") {
    var originalHtml = arguments.htmlContent;
    var trimmedHtml = trim(arguments.htmlContent);
    var normalizedRemoteUrl = normalizeComparableMediaUrl(arguments.remoteMediaUrl);
    var normalizedLocalUrl = normalizeComparableMediaUrl(arguments.localMediaUrl);
    var leadingPatterns = [
        '^(?:\s|<!--[\s\S]*?-->)*<figure\b[\s\S]*?</figure>',
        '^(?:\s|<!--[\s\S]*?-->)*<p\b[\s\S]*?</p>',
        '^(?:\s|<!--[\s\S]*?-->)*<div\b[\s\S]*?</div>',
        '^(?:\s|<!--[\s\S]*?-->)*<img\b[^>]*>'
    ];
    var pattern = "";
    var matches = [];
    var leadingBlock = "";
    var blockImageUrl = "";

    if (!len(trimmedHtml)) {
        return originalHtml;
    }

    if (!len(normalizedRemoteUrl) AND !len(normalizedLocalUrl)) {
        return originalHtml;
    }

    for (pattern in leadingPatterns) {
        matches = reMatchNoCase(pattern, trimmedHtml);
        if (!arrayLen(matches)) {
            continue;
        }

        leadingBlock = matches[1];
        blockImageUrl = normalizeComparableMediaUrl(extractFirstImageUrl(leadingBlock));

        if (
            len(blockImageUrl)
            AND (
                (len(normalizedRemoteUrl) AND blockImageUrl EQ normalizedRemoteUrl)
                OR (len(normalizedLocalUrl) AND blockImageUrl EQ normalizedLocalUrl)
            )
        ) {
            return trim(reReplaceNoCase(trimmedHtml, pattern, "", "one"));
        }

        return originalHtml;
    }

    return originalHtml;
}

function processImportedBodyImages(required string htmlContent, required numeric authorId, required any db, string sourcePageUrl = "", struct uploadedMediaMap = {}) {
    var result = {
        html = arguments.htmlContent,
        media_map = {}
    };
    var sourceHtml = absolutizeImageAttributes(arguments.htmlContent, arguments.sourcePageUrl);
    var imageMatches = "";
    var imageTag = "";
    var remoteUrl = "";
    var normalizedRemoteUrl = "";
    var downloadResult = {};
    var localUrl = "";
    var mapKey = "";

    if (!len(trim(sourceHtml))) {
        return result;
    }

    imageMatches = reMatchNoCase('<img\b[^>]*>', sourceHtml);

    for (imageTag in imageMatches) {
        remoteUrl = extractImageSourceFromTag(imageTag);
        normalizedRemoteUrl = trim(remoteUrl);
        mapKey = lCase(normalizedRemoteUrl);

        if (!len(normalizedRemoteUrl) OR !reFindNoCase("^https?://", normalizedRemoteUrl)) {
            continue;
        }

        if (!structKeyExists(result.media_map, mapKey)) {
            if (
                isStruct(arguments.uploadedMediaMap)
                AND structKeyExists(arguments.uploadedMediaMap, "by_filename")
                AND isStruct(arguments.uploadedMediaMap.by_filename)
                AND structKeyExists(arguments.uploadedMediaMap.by_filename, mediaKeyFromUrl(normalizedRemoteUrl))
            ) {
                result.media_map[mapKey] = arguments.uploadedMediaMap.by_filename[mediaKeyFromUrl(normalizedRemoteUrl)];
            }
        }

        if (
            !structKeyExists(result.media_map, mapKey)
            AND isStruct(arguments.uploadedMediaMap)
            AND structKeyExists(arguments.uploadedMediaMap, "by_url")
            AND isStruct(arguments.uploadedMediaMap.by_url)
            AND structKeyExists(arguments.uploadedMediaMap.by_url, mediaKeyFromUrl(normalizedRemoteUrl))
        ) {
            result.media_map[mapKey] = arguments.uploadedMediaMap.by_url[mediaKeyFromUrl(normalizedRemoteUrl)];
        }

        if (!structKeyExists(result.media_map, mapKey)) {
            try {
                downloadResult = downloadRemoteMedia(normalizedRemoteUrl, arguments.authorId, arguments.db);
                if (structKeyExists(downloadResult, "success") AND downloadResult.success) {
                    result.media_map[mapKey] = {
                        media_id = val(downloadResult.media_id),
                        url_public = downloadResult.url_public
                    };
                }
            } catch (any downloadError) {}
        }

        if (structKeyExists(result.media_map, mapKey) AND structKeyExists(result.media_map[mapKey], "url_public")) {
            localUrl = result.media_map[mapKey].url_public;
            result.html = replaceNoCase(result.html, 'src="' & remoteUrl & '"', 'src="' & localUrl & '"', "all");
            result.html = replaceNoCase(result.html, "src='" & remoteUrl & "'", "src='" & localUrl & "'", "all");
            result.html = replaceNoCase(result.html, 'data-src="' & remoteUrl & '"', 'src="' & localUrl & '"', "all");
            result.html = replaceNoCase(result.html, "data-src='" & remoteUrl & "'", "src='" & localUrl & "'", "all");
            result.html = replaceNoCase(result.html, 'data-lazy-src="' & remoteUrl & '"', 'src="' & localUrl & '"', "all");
            result.html = replaceNoCase(result.html, "data-lazy-src='" & remoteUrl & "'", "src='" & localUrl & "'", "all");
            result.html = replaceNoCase(result.html, 'data-pin-media="' & remoteUrl & '"', 'src="' & localUrl & '"', "all");
            result.html = replaceNoCase(result.html, "data-pin-media='" & remoteUrl & "'", "src='" & localUrl & "'", "all");
        }
    }

    result.html = reReplaceNoCase(result.html, '\s+srcset="[^"]*"', "", "all");
    result.html = reReplaceNoCase(result.html, "\s+srcset='[^']*'", "", "all");
    result.html = reReplaceNoCase(result.html, '\s+sizes="[^"]*"', "", "all");
    result.html = reReplaceNoCase(result.html, "\s+sizes='[^']*'", "", "all");

    return result;
}

function cleanupImportedBodyHtml(string htmlContent="") {
    var cleanedHtml = trim(arguments.htmlContent);

    if (!len(cleanedHtml)) {
        return "";
    }

    cleanedHtml = reReplaceNoCase(cleanedHtml, "<p>\s*The post <a[\s\S]*?</p>", "", "all");
    cleanedHtml = reReplaceNoCase(cleanedHtml, "<p><a class=""a2a_button_[\s\S]*?</p>", "", "all");
    cleanedHtml = reReplaceNoCase(cleanedHtml, "<a class=""a2a_[^""]+""[\s\S]*?</a>", "", "all");
    cleanedHtml = reReplaceNoCase(cleanedHtml, "<div class=""addtoany_[^""]+""[\s\S]*?</div>", "", "all");
    cleanedHtml = trim(cleanedHtml);

    return cleanedHtml;
}

function buildExcerptFromDescription(string descriptionHtml="", string fallbackHtml="") {
    var cleanedHtml = trim(arguments.descriptionHtml);
    var textValue = "";

    if (!len(cleanedHtml)) {
        cleanedHtml = trim(arguments.fallbackHtml);
    }

    cleanedHtml = reReplaceNoCase(cleanedHtml, "<p>\s*The post <a[\s\S]*?</p>", "", "all");
    textValue = stripHtmlTags(cleanedHtml);

    return textValue;
}

function parseRssPubDate(string rawDate="") {
    var normalizedDate = trim(arguments.rawDate);
    var parsePatterns = [
        "EEE, dd MMM yyyy HH:mm:ss Z",
        "EEE, dd MMM yyyy HH:mm:ss z",
        "yyyy-MM-dd'T'HH:mm:ss.SSSX",
        "yyyy-MM-dd'T'HH:mm:ssX",
        "yyyy-MM-dd'T'HH:mm:ss.SSSXXX",
        "yyyy-MM-dd'T'HH:mm:ssXXX"
    ];
    var parsePattern = "";
    var formatter = "";
    var locale = "";

    if (!len(normalizedDate)) {
        return "";
    }

    locale = createObject("java", "java.util.Locale").ENGLISH;
    for (parsePattern in parsePatterns) {
        try {
            formatter = createObject("java", "java.text.SimpleDateFormat").init(parsePattern, locale);
            formatter.setLenient(false);
            return formatter.parse(normalizedDate);
        } catch (any ignoredPatternError) {}
    }

    try {
        if (isDate(normalizedDate)) {
            return parseDateTime(normalizedDate);
        }
    } catch (any ignoredFallbackError) {
    }

    return "";
}

function ensureContentImportTable(required any db) {
    arguments.db.q("
      CREATE TABLE IF NOT EXISTS news.tb_content_imports (
        id SERIAL PRIMARY KEY,
        importer_key TEXT NOT NULL,
        source_name TEXT NOT NULL,
        source_key TEXT NOT NULL,
        source_url TEXT,
        source_guid TEXT,
        source_hash TEXT,
        source_author TEXT,
        content_id INTEGER REFERENCES news.tb_content(id) ON DELETE SET NULL,
        imported_at TIMESTAMP NOT NULL DEFAULT now(),
        updated_at TIMESTAMP NOT NULL DEFAULT now(),
        detail_json JSONB
      )
    ");

    arguments.db.q("
      CREATE UNIQUE INDEX IF NOT EXISTS idx_tb_content_imports_unique_source
      ON news.tb_content_imports (importer_key, source_key)
    ");

    arguments.db.q("
      CREATE INDEX IF NOT EXISTS idx_tb_content_imports_content_id
      ON news.tb_content_imports (content_id)
    ");
}

function ensureContentType(required any db, required string contentTypeName) {
    var normalizedName = trim(arguments.contentTypeName);
    var lookup = "";
    var inserted = "";

    lookup = arguments.db.q("
      SELECT id
      FROM news.tb_content_types
      WHERE lower(name) = :name
      LIMIT 1
    ", {
      name: {value=lCase(normalizedName), cfsqltype="cf_sql_varchar"}
    });

    if (lookup.recordCount) {
        return val(lookup.id[1]);
    }

    inserted = arguments.db.q("
      INSERT INTO news.tb_content_types (name, slug)
      VALUES (:name, :slug)
      RETURNING id
    ", {
      name: {value=normalizedName, cfsqltype="cf_sql_varchar"},
      slug: {value=buildSlugBase(normalizedName), cfsqltype="cf_sql_varchar"}
    });

    return extractGeneratedId(inserted);
}

function ensureCategory(required any db, required string categoryName) {
    var normalizedName = trim(arguments.categoryName);
    var lookup = "";
    var inserted = "";

    if (!len(normalizedName)) {
        return 0;
    }

    lookup = arguments.db.q("
      SELECT id
      FROM news.tb_categories
      WHERE lower(name) = :name
      LIMIT 1
    ", {
      name: {value=lCase(normalizedName), cfsqltype="cf_sql_varchar"}
    });

    if (lookup.recordCount) {
        return val(lookup.id[1]);
    }

    inserted = arguments.db.q("
      INSERT INTO news.tb_categories (name, slug)
      VALUES (:name, :slug)
      RETURNING id
    ", {
      name: {value=normalizedName, cfsqltype="cf_sql_varchar"},
      slug: {value=buildSlugBase(normalizedName), cfsqltype="cf_sql_varchar"}
    });

    return extractGeneratedId(inserted);
}

function syncContentTags(required any db, required numeric contentId, required array tagNames) {
    var normalizedTags = [];
    var seenTags = {};
    var tagName = "";
    var tagSlug = "";
    var existingTag = "";
    var insertedTag = "";
    var tagId = 0;
    var tagData = {};

    arguments.db.q("
      DELETE FROM news.tb_content_tags
      WHERE content_id = :content_id
    ", {
      content_id: {value=arguments.contentId, cfsqltype="cf_sql_integer"}
    });

    for (tagName in arguments.tagNames) {
        tagName = trim(tagName);
        tagSlug = buildSlugBase(tagName);

        if (!len(tagName) OR structKeyExists(seenTags, tagSlug)) {
            continue;
        }

        seenTags[tagSlug] = true;
        arrayAppend(normalizedTags, {
            name = tagName,
            slug = tagSlug
        });
    }

    for (tagData in normalizedTags) {
        existingTag = arguments.db.q("
          SELECT id
          FROM news.tb_tags
          WHERE slug = :slug
          LIMIT 1
        ", {
          slug: {value=tagData.slug, cfsqltype="cf_sql_varchar"}
        });

        if (existingTag.recordCount) {
            tagId = val(existingTag.id[1]);
        } else {
            insertedTag = arguments.db.q("
              INSERT INTO news.tb_tags (name, slug)
              VALUES (:name, :slug)
              RETURNING id
            ", {
              name: {value=tagData.name, cfsqltype="cf_sql_varchar"},
              slug: {value=tagData.slug, cfsqltype="cf_sql_varchar"}
            });
            tagId = extractGeneratedId(insertedTag);
        }

        if (tagId GT 0) {
            arguments.db.q("
              INSERT INTO news.tb_content_tags (content_id, tag_id)
              VALUES (:content_id, :tag_id)
            ", {
              content_id: {value=arguments.contentId, cfsqltype="cf_sql_integer"},
              tag_id: {value=tagId, cfsqltype="cf_sql_integer"}
            });
        }
    }
}

function ensureImportedAuthor(required any db, required any auth, required numeric operatorUserId, required string displayName, required numeric responsibleEditorId) {
    var normalizedName = trim(arguments.displayName);
    var normalizedLookupName = normalizePersonName(normalizedName);
    var normalizedFallbackEmail = lCase(trim(buildAuthorImportEmail(normalizedName)));
    var lookup = "";
    var lookupByEmail = "";
    var allUsers = "";
    var candidateName = "";
    var candidateUserId = 0;
    var insertResult = "";
    var salt = "";
    var passHash = "";
    var passwordSeed = createUUID() & createUUID() & "Aa1";
    var audit = "";
    var emailCandidate = normalizedFallbackEmail;
    var emailSuffix = 2;

    if (!len(normalizedName)) {
        return 0;
    }

    if (arguments.responsibleEditorId LTE 0) {
        cfthrow(message="Selecione um editor responsável padrão para autores novos de " & variables.feedImporterConfig.source_name & ".");
    }

    allUsers = arguments.db.q("
      SELECT id, display_name
      FROM news.tb_users
      ORDER BY id ASC
    ");

    for (local.i = 1; local.i <= allUsers.recordCount; local.i = local.i + 1) {
        candidateName = normalizePersonName(textOrFallback(allUsers.display_name[local.i], ""));
        if (len(candidateName) AND candidateName EQ normalizedLookupName) {
            candidateUserId = val(allUsers.id[local.i]);
            return candidateUserId;
        }
    }

    lookupByEmail = arguments.db.q("
      SELECT id
      FROM news.tb_users
      WHERE lower(email) = :email
      LIMIT 1
    ", {
      email: {value=emailCandidate, cfsqltype="cf_sql_varchar"}
    });

    while (lookupByEmail.recordCount) {
        emailCandidate = buildSlugBase(normalizedName) & "-" & emailSuffix & "@" & variables.feedImporterConfig.author_email_domain;
        emailSuffix = emailSuffix + 1;
        lookupByEmail = arguments.db.q("
          SELECT id
          FROM news.tb_users
          WHERE lower(email) = :email
          LIMIT 1
        ", {
          email: {value=emailCandidate, cfsqltype="cf_sql_varchar"}
        });
    }

    salt = arguments.auth.generateSalt();
    passHash = arguments.auth.pbkdf2Hash(passwordSeed, salt);

    insertResult = arguments.db.q("
      INSERT INTO news.tb_users (email, display_name, pass_hash, salt, role, is_active, responsible_editor_id)
      VALUES (:email, :display_name, :pass_hash, :salt, :role, :is_active, :responsible_editor_id)
      RETURNING id
    ", {
      email: {value=emailCandidate, cfsqltype="cf_sql_varchar"},
      display_name: {value=normalizedName, cfsqltype="cf_sql_varchar"},
      pass_hash: {value=passHash, cfsqltype="cf_sql_varchar"},
      salt: {value=salt, cfsqltype="cf_sql_varchar"},
      role: {value="autor", cfsqltype="cf_sql_varchar"},
      is_active: {value=true, cfsqltype="cf_sql_bit"},
      responsible_editor_id: {value=arguments.responsibleEditorId, cfsqltype="cf_sql_integer"}
    });

    try {
        audit = createObject("component", "inc.audit");
        audit.record(arguments.operatorUserId, "user.create", "news.tb_users", extractGeneratedId(insertResult), {
            display_name = normalizedName,
            email = emailCandidate,
            role = "autor",
            is_active = true,
            responsible_editor_id = arguments.responsibleEditorId,
            via = variables.feedImporterConfig.audit_suffix & "_importer"
        });
    } catch (any auditError) {}

    return extractGeneratedId(insertResult);
}

function buildImportSourceKey(string guidValue="", string sourceUrl="", string titleValue="", string publishedValue="") {
    if (len(trim(arguments.guidValue))) {
        return hash("guid|" & trim(arguments.guidValue), "SHA-256");
    }

    if (len(trim(arguments.sourceUrl))) {
        return hash("url|" & trim(arguments.sourceUrl), "SHA-256");
    }

    return hash("title|" & trim(arguments.titleValue) & "|" & trim(arguments.publishedValue), "SHA-256");
}

function usesSemanticSourceFingerprint() {
    return compareNoCase(variables.feedImporterConfig.importer_key, "contrarelogio_feed") EQ 0;
}

function sourceFingerprintVersion() {
    if (!usesSemanticSourceFingerprint()) {
        return 1;
    }

    return createObject("component", "inc.import_source_fingerprint").version();
}

function buildSourceHash(required struct itemData) {
    if (usesSemanticSourceFingerprint()) {
        return createObject("component", "inc.import_source_fingerprint").build(arguments.itemData);
    }

    return hash(
        serializeJSON({
            title = itemData.title,
            source_url = itemData.source_url,
            published_at = itemData.published_at_raw,
            categories = itemData.categories,
            excerpt = itemData.excerpt_text,
            body_html = itemData.body_html,
            media_url = itemData.media_url
        }, "struct", false),
        "SHA-256"
    );
}

function baselineSourceFingerprint(
    required any db,
    required numeric existingImportId,
    required string sourceFingerprint,
    required numeric fingerprintVersion
) {
    arguments.db.q("
      UPDATE news.tb_content_imports
         SET detail_json = COALESCE(detail_json, '{}'::jsonb)
             || jsonb_build_object(
                  'source_fingerprint', CAST(:source_fingerprint AS text),
                  'source_fingerprint_version', :fingerprint_version
                )
       WHERE id = :id
    ", {
      id: {value=arguments.existingImportId, cfsqltype="cf_sql_integer"},
      source_fingerprint: {value=arguments.sourceFingerprint, cfsqltype="cf_sql_varchar"},
      fingerprint_version: {value=arguments.fingerprintVersion, cfsqltype="cf_sql_integer"}
    });
}

function parseFeedItems(required string xmlPayload) {
    var items = [];
    var itemBlocks = reMatchNoCase("<item>[\s\S]*?</item>", arguments.xmlPayload);
    var itemBlock = "";
    var rawCategories = [];
    var rawDescription = "";
    var rawBodyHtml = "";
    var publishedAtRaw = "";
    var parsedPublishedAt = "";
    var cleanedBodyHtml = "";

    for (itemBlock in itemBlocks) {
        rawDescription = extractTagValue(itemBlock, "description");
        rawBodyHtml = extractTagValue(itemBlock, "content:encoded");
        publishedAtRaw = trim(extractTagValue(itemBlock, "pubDate"));
        parsedPublishedAt = parseRssPubDate(publishedAtRaw);
        rawCategories = extractCategories(itemBlock);
        cleanedBodyHtml = cleanupImportedBodyHtml(rawBodyHtml);

        arrayAppend(items, {
            title = decodeHtmlEntities(extractTagValue(itemBlock, "title")),
            source_url = stripTrackingParams(extractTagValue(itemBlock, "link")),
            source_guid = decodeHtmlEntities(extractTagValue(itemBlock, "guid")),
            source_author = decodeHtmlEntities(extractTagValue(itemBlock, "dc:creator")),
            published_at_raw = publishedAtRaw,
            published_at = parsedPublishedAt,
            excerpt_text = buildExcerptFromDescription(rawDescription, cleanedBodyHtml),
            body_html = cleanedBodyHtml,
            description_html = rawDescription,
            media_url = resolveRemoteUrl(
                textOrFallback(extractMediaUrl(itemBlock), extractFirstImageUrl(cleanedBodyHtml)),
                stripTrackingParams(extractTagValue(itemBlock, "link"))
            ),
            categories = rawCategories
        });
    }

    return items;
}

function extractWixBlogPosting(string htmlContent = "") {
    var result = {};
    var scriptBlocks = reMatchNoCase('<script\b[^>]*type=["'']application/ld\+json["''][^>]*>[\s\S]*?</script>', arguments.htmlContent);
    var scriptBlock = "";
    var jsonText = "";
    var jsonData = {};
    var candidates = [];
    var candidate = {};

    for (scriptBlock in scriptBlocks) {
        jsonText = reReplaceNoCase(scriptBlock, '^<script\b[^>]*>([\s\S]*?)</script>$', "\1", "one");
        if (!isJSON(jsonText)) {
            continue;
        }

        try {
            jsonData = deserializeJSON(jsonText);
            candidates = isArray(jsonData) ? jsonData : [jsonData];

            for (candidate in candidates) {
                if (isStruct(candidate) AND compareNoCase(textOrFallback(candidate["@type"] ?: "", ""), "BlogPosting") EQ 0) {
                    return candidate;
                }
            }
        } catch (any jsonLdError) {}
    }

    return result;
}

function extractWixArticleBody(string htmlContent = "") {
    var sections = reMatchNoCase('<section\b[^>]*data-hook=["'']post-description["''][^>]*>[\s\S]*?</section>', arguments.htmlContent);
    var bodyHtml = "";
    var imageTags = [];
    var imageTag = "";
    var pinnedMatches = [];
    var pinnedUrl = "";
    var normalizedImageTag = "";

    if (!arrayLen(sections)) {
        return "";
    }

    bodyHtml = reReplaceNoCase(sections[1], '^<section\b[^>]*>([\s\S]*?)</section>$', "\1", "one");
    bodyHtml = reReplaceNoCase(bodyHtml, '<(?:script|style|noscript|button|svg)\b[\s\S]*?</(?:script|style|noscript|button|svg)>', "", "all");
    bodyHtml = reReplaceNoCase(bodyHtml, '</?(?:span|wow-image)\b[^>]*>', "", "all");
    bodyHtml = reReplaceNoCase(bodyHtml, '\s+(?:class|style|id|dir|role|tabindex|draggable|contenteditable|aria-[a-z0-9_-]+|data-(?!pin-media)[a-z0-9_-]+)=(?:"[^"]*"|''[^'']*'')', "", "all");
    bodyHtml = reReplaceNoCase(bodyHtml, '<div\b[^>]*>\s*</div>', "", "all");
    bodyHtml = reReplaceNoCase(bodyHtml, '<p\b[^>]*>\s*</p>', "", "all");
    bodyHtml = reReplaceNoCase(bodyHtml, '\s+on[a-z]+=(?:"[^"]*"|''[^'']*'')', "", "all");

    imageTags = reMatchNoCase('<img\b[^>]*>', bodyHtml);
    for (imageTag in imageTags) {
        pinnedMatches = reMatchNoCase('\bdata-pin-media=(?:"[^"]+"|''[^'']+'')', imageTag);
        if (!arrayLen(pinnedMatches)) {
            continue;
        }

        pinnedUrl = decodeHtmlEntities(reReplaceNoCase(pinnedMatches[1], '^data-pin-media=["'']([^"'']+)["'']$', "\1", "one"));
        normalizedImageTag = reReplaceNoCase(imageTag, '\s+data-pin-media=(?:"[^"]*"|''[^'']*'')', "", "all");
        if (reFindNoCase('\bsrc=(?:"[^"]*"|''[^'']*'')', normalizedImageTag)) {
            normalizedImageTag = reReplaceNoCase(normalizedImageTag, '\bsrc=(?:"[^"]*"|''[^'']*'')', 'src="' & pinnedUrl & '"', "one");
        } else {
            normalizedImageTag = replace(normalizedImageTag, ">", ' src="' & pinnedUrl & '">', "one");
        }
        bodyHtml = replace(bodyHtml, imageTag, normalizedImageTag, "one");
    }

    return cleanupImportedBodyHtml(trim(bodyHtml));
}

function extractWixCategories(string htmlContent = "") {
    var categories = [];
    var categoryBlocks = reMatchNoCase('<ul\b[^>]*aria-label=["'']Post categories["''][^>]*>[\s\S]*?</ul>', arguments.htmlContent);
    var categoryHtml = arrayLen(categoryBlocks) ? categoryBlocks[1] : "";
    var links = reMatchNoCase('<a\b[^>]*href=["''][^"'']*/materias/categories/[^"'']+["''][^>]*>[\s\S]*?</a>', categoryHtml);
    var linkHtml = "";
    var categoryName = "";

    for (linkHtml in links) {
        categoryName = stripHtmlTags(linkHtml);
        if (len(categoryName) AND !findArrayValueNoCase(categories, categoryName)) {
            arrayAppend(categories, categoryName);
        }
    }

    return categories;
}

function parseWixSitemapItems(required string xmlPayload) {
    var items = [];
    var urlBlocks = reMatchNoCase('<url>[\s\S]*?</url>', arguments.xmlPayload);
    var urlBlock = "";
    var sourceUrl = "";
    var lastModified = "";
    var mediaUrl = "";

    for (urlBlock in urlBlocks) {
        sourceUrl = stripTrackingParams(extractTagValue(urlBlock, "loc"));
        if (!len(sourceUrl) OR findNoCase("/post/", sourceUrl) EQ 0) {
            continue;
        }

        lastModified = extractTagValue(urlBlock, "lastmod");
        mediaUrl = extractTagValue(urlBlock, "image:loc");
        arrayAppend(items, {
            title = "",
            source_url = sourceUrl,
            source_guid = sourceUrl,
            source_author = "",
            published_at_raw = lastModified,
            published_at = "",
            excerpt_text = "",
            body_html = "",
            description_html = "",
            media_url = resolveRemoteUrl(mediaUrl, sourceUrl),
            categories = [],
            sitemap_last_modified = lastModified
        });
    }

    arraySort(items, function(itemA, itemB) {
        return compare(textOrFallback(itemB.sitemap_last_modified, ""), textOrFallback(itemA.sitemap_last_modified, ""));
    });

    return items;
}

function applyWixArticleHtml(required struct itemData, required string htmlContent) {
    var item = duplicate(arguments.itemData);
    var posting = extractWixBlogPosting(arguments.htmlContent);
    var authorData = {};
    var imageData = {};
    var publishedRaw = "";
    var wixCategories = [];
    var titleMatches = reMatchNoCase('<h1\b[^>]*data-hook=["'']post-title["''][^>]*>[\s\S]*?</h1>', arguments.htmlContent);

    if (arrayLen(titleMatches)) {
        item.title = textOrFallback(stripHtmlTags(titleMatches[1]), item.title);
    }

    item.body_html = extractWixArticleBody(arguments.htmlContent);

    if (isStruct(posting) AND structCount(posting)) {
        if (!len(item.title)) {
            item.title = textOrFallback(posting.headline ?: "", item.title);
        }
        item.excerpt_text = textOrFallback(posting.description ?: "", item.excerpt_text);
        if (!isDate(item.published_at)) {
            publishedRaw = textOrFallback(posting.datePublished ?: "", item.published_at_raw);
            item.published_at_raw = publishedRaw;
            item.published_at = parseRssPubDate(publishedRaw);
        }

        if (structKeyExists(posting, "author") AND isStruct(posting.author)) {
            authorData = posting.author;
            item.source_author = textOrFallback(authorData.name ?: "", item.source_author);
        }

        if (structKeyExists(posting, "image")) {
            if (isStruct(posting.image)) {
                imageData = posting.image;
                item.media_url = resolveRemoteUrl(textOrFallback(imageData.url ?: "", item.media_url), item.source_url);
            } else {
                item.media_url = resolveRemoteUrl(textOrFallback(posting.image, item.media_url), item.source_url);
            }
        }
    }

    if (!isDate(item.published_at) AND len(item.published_at_raw)) {
        item.published_at = parseRssPubDate(item.published_at_raw);
    }

    if (!len(item.media_url)) {
        item.media_url = resolveRemoteUrl(extractMetadataImageUrl(arguments.htmlContent), item.source_url);
    }

    wixCategories = extractWixCategories(arguments.htmlContent);
    if (!arrayLen(item.categories) AND arrayLen(wixCategories)) {
        item.categories = wixCategories;
    }

    item.body_html = absolutizeImageAttributes(item.body_html, item.source_url);
    return item;
}

function normalizeManualFeedPayload(string rawPayload = "") {
    var normalizedPayload = trim(arguments.rawPayload);

    if (!len(normalizedPayload)) {
        return "";
    }

    normalizedPayload = replace(normalizedPayload, chr(13) & chr(10), chr(10), "all");
    normalizedPayload = replace(normalizedPayload, chr(13), chr(10), "all");

    return normalizedPayload;
}

function buildImportErrorMessage(required any err) {
    var messageParts = [];
    var finalMessage = "";

    if (structKeyExists(arguments.err, "message") AND len(trim(arguments.err.message & ""))) {
        arrayAppend(messageParts, trim(arguments.err.message & ""));
    }

    if (structKeyExists(arguments.err, "detail") AND len(trim(arguments.err.detail & ""))) {
        arrayAppend(messageParts, trim(arguments.err.detail & ""));
    }

    if (structKeyExists(arguments.err, "sqlState") AND len(trim(arguments.err.sqlState & ""))) {
        arrayAppend(messageParts, "SQLSTATE " & trim(arguments.err.sqlState & ""));
    }

    finalMessage = arrayToList(messageParts, " | ");
    if (!len(finalMessage)) {
        finalMessage = "Falha ao importar este item.";
    }

    return finalMessage;
}

function responseHeaderValue(required struct responseHeader, required string headerName) {
    var lookupName = "";

    for (lookupName in arguments.responseHeader) {
        if (compareNoCase(lookupName, arguments.headerName) EQ 0) {
            return textOrFallback(arguments.responseHeader[lookupName], "");
        }
    }

    return "";
}

function isCloudflareChallengeResponse(struct responseHeader = {}, string responseBody = "") {
    var mitigatedValue = "";
    var serverValue = "";
    var bodySample = lCase(left(trim(arguments.responseBody), 1200));

    if (isStruct(arguments.responseHeader)) {
        mitigatedValue = lCase(trim(responseHeaderValue(arguments.responseHeader, "cf-mitigated")));
        serverValue = lCase(trim(responseHeaderValue(arguments.responseHeader, "server")));
    }

    if (mitigatedValue EQ "challenge") {
        return true;
    }

    if (findNoCase("cloudflare", serverValue) GT 0 AND (
        findNoCase("just a moment", bodySample) GT 0
        OR findNoCase("cf-challenge", bodySample) GT 0
        OR findNoCase("challenge-platform", bodySample) GT 0
        OR findNoCase("enable javascript and cookies to continue", bodySample) GT 0
    )) {
        return true;
    }

    return false;
}

function looksLikeXmlFeed(string payload = "") {
    var normalizedPayload = lCase(trim(arguments.payload));

    if (!len(normalizedPayload)) {
        return false;
    }

    return left(normalizedPayload, 5) EQ "<?xml"
        OR findNoCase("<rss", normalizedPayload) GT 0
        OR findNoCase("<feed", normalizedPayload) GT 0;
}

function upsertContentImportRecord(
    required any db,
    required string importerKey,
    required string sourceName,
    required string sourceKey,
    string sourceUrl="",
    string sourceGuid="",
    string sourceHash="",
    string sourceAuthor="",
    numeric contentId=0,
    struct detailData={},
    numeric existingImportId=0
) {
    var params = {
      importer_key: {value=arguments.importerKey, cfsqltype="cf_sql_varchar"},
      source_name: {value=arguments.sourceName, cfsqltype="cf_sql_varchar"},
      source_key: {value=arguments.sourceKey, cfsqltype="cf_sql_varchar"},
      source_url: {value=arguments.sourceUrl, cfsqltype="cf_sql_varchar", null=(NOT len(trim(arguments.sourceUrl)))},
      source_guid: {value=arguments.sourceGuid, cfsqltype="cf_sql_varchar", null=(NOT len(trim(arguments.sourceGuid)))},
      source_hash: {value=arguments.sourceHash, cfsqltype="cf_sql_varchar", null=(NOT len(trim(arguments.sourceHash)))},
      source_author: {value=arguments.sourceAuthor, cfsqltype="cf_sql_varchar", null=(NOT len(trim(arguments.sourceAuthor)))},
      content_id: {value=arguments.contentId, cfsqltype="cf_sql_integer", null=(arguments.contentId LTE 0)},
      detail_json: {value=serializeJSON(arguments.detailData, "struct", false), cfsqltype="cf_sql_longvarchar"}
    };

    if (arguments.existingImportId GT 0) {
        params.id = {value=arguments.existingImportId, cfsqltype="cf_sql_integer"};
        arguments.db.q("
          UPDATE news.tb_content_imports
             SET source_name = :source_name,
                 source_key = :source_key,
                 source_url = :source_url,
                 source_guid = :source_guid,
                 source_hash = :source_hash,
                 source_author = :source_author,
                 content_id = :content_id,
                 detail_json = CAST(:detail_json AS jsonb)
                   || jsonb_strip_nulls(jsonb_build_object(
                        'ai_summary', detail_json->'ai_summary',
                        'source_archived_at', CASE
                          WHEN length(btrim(COALESCE(detail_json->>'source_description_html', ''))) >= 240
                            THEN detail_json->'source_archived_at'
                          ELSE NULL
                        END,
                        'source_description_html', CASE
                          WHEN length(btrim(COALESCE(detail_json->>'source_description_html', ''))) >= 240
                            THEN to_jsonb(detail_json->>'source_description_html')
                          ELSE NULL
                        END
                      )),
                 updated_at = now()
           WHERE id = :id
        ", params);
    } else {
        arguments.db.q("
          INSERT INTO news.tb_content_imports (
            importer_key, source_name, source_key, source_url, source_guid, source_hash, source_author, content_id, detail_json
          )
          VALUES (
            :importer_key, :source_name, :source_key, :source_url, :source_guid, :source_hash, :source_author, :content_id, CAST(:detail_json AS jsonb)
          )
        ", params);
    }
}
</cfscript>

<cfsetting requesttimeout="900">

<cfinclude template="/inc/csrf.cfm">

<cffunction name="fetchWixSitemapPage" returntype="struct" output="false">
    <cfargument name="pageNumber" type="numeric" required="true">
    <cfset var httpResult = {}>
    <cfset var statusCode = 0>
    <cfset var allItems = []>
    <cfset var pageItems = []>
    <cfset var pageSize = max(1, val(feedImporterConfig.sitemap_items_per_page))>
    <cfset var startIndex = ((arguments.pageNumber - 1) * pageSize) + 1>
    <cfset var endIndex = 0>
    <cfset var itemIndex = 0>
    <cfset var requestSettings = getContraRelogioRequestSettings()>

    <cfif NOT structKeyExists(request, "feedImporterSitemapCache") OR NOT isArray(request.feedImporterSitemapCache)>
        <cfhttp url="#feedImporterConfig.sitemap_url#" method="get" result="httpResult" redirect="true" timeout="45" useragent="#requestSettings.userAgent#">
            <cfhttpparam type="header" name="Accept" value="application/xml,text/xml;q=0.9,*/*;q=0.8">
            <cfhttpparam type="header" name="Accept-Language" value="#requestSettings.acceptLanguage#">
        </cfhttp>
        <cfset statusCode = val(listFirst(textOrFallback(httpResult.statusCode, "0"), " "))>

        <cfif statusCode LT 200 OR statusCode GTE 300>
            <cfreturn {
                success = false,
                status_code = statusCode,
                error_message = "Não foi possível carregar o sitemap retroativo.",
                url = feedImporterConfig.sitemap_url,
                items = []
            }>
        </cfif>

        <cfset request.feedImporterSitemapCache = parseWixSitemapItems(httpResult.fileContent & "")>
    </cfif>

    <cfset allItems = request.feedImporterSitemapCache>
    <cfif startIndex LTE arrayLen(allItems)>
        <cfset endIndex = min(arrayLen(allItems), startIndex + pageSize - 1)>
        <cfloop index="itemIndex" from="#startIndex#" to="#endIndex#">
            <cfset arrayAppend(pageItems, duplicate(allItems[itemIndex]))>
        </cfloop>
    </cfif>

    <cfreturn {
        success = true,
        status_code = 200,
        error_message = "",
        url = feedImporterConfig.sitemap_url,
        items = pageItems
    }>
</cffunction>

<cffunction name="hydrateFeedItemFromArticle" returntype="struct" output="false">
    <cfargument name="itemData" type="struct" required="true">
    <cfset var item = duplicate(arguments.itemData)>
    <cfset var httpResult = {}>
    <cfset var statusCode = 0>
    <cfset var requestSettings = getContraRelogioRequestSettings()>

    <cfif compareNoCase(feedImporterConfig.source_kind, "wix") NEQ 0 OR len(trim(item.body_html))>
        <cfreturn item>
    </cfif>

    <cfif NOT len(trim(item.source_url))>
        <cfreturn item>
    </cfif>

    <cfhttp url="#item.source_url#" method="get" result="httpResult" redirect="true" timeout="45" useragent="#requestSettings.userAgent#">
        <cfhttpparam type="header" name="Accept" value="text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8">
        <cfhttpparam type="header" name="Accept-Language" value="#requestSettings.acceptLanguage#">
        <cfhttpparam type="header" name="Cache-Control" value="no-cache">
    </cfhttp>
    <cfset statusCode = val(listFirst(textOrFallback(httpResult.statusCode, "0"), " "))>

    <cfif statusCode LT 200 OR statusCode GTE 300>
        <cfthrow message="A página original retornou HTTP #statusCode#." type="FeedImporter.ArticleFetchFailed">
    </cfif>

    <cfreturn applyWixArticleHtml(item, httpResult.fileContent & "")>
</cffunction>

<cffunction name="fetchFeedPage" returntype="struct" output="false">
    <cfargument name="feedUrl" type="string" required="true">
    <cfargument name="pageNumber" type="numeric" required="true">
    <cfargument name="useSitemap" type="boolean" required="false" default="false">
    <cfset var requestUrl = arguments.feedUrl>
    <cfset var separator = "?">
    <cfset var httpResult = {}>
    <cfset var statusCode = 0>
    <cfset var statusMessage = "">
    <cfset var responseBody = "">
    <cfset var responseHeader = {}>
    <cfset var contentType = "">
    <cfset var requestSettings = getContraRelogioRequestSettings()>
    <cfset var challengeMessage = "">
    <cfset var attemptNumber = 1>
    <cfset var maxAttempts = requestSettings.retryCount>
    <cfset var shouldRetry = false>

    <cfif arguments.useSitemap AND compareNoCase(feedImporterConfig.source_kind, "wix") EQ 0>
        <cfreturn fetchWixSitemapPage(arguments.pageNumber)>
    </cfif>

    <cfif find("?", requestUrl)>
        <cfset separator = "&">
    </cfif>

    <cfif arguments.pageNumber GT 1 AND compareNoCase(feedImporterConfig.source_kind, "wix") NEQ 0>
        <cfset requestUrl &= separator & "paged=" & arguments.pageNumber>
    </cfif>

    <cfloop condition="attemptNumber LTE maxAttempts">
        <cfset httpResult = {}>
        <cfset statusCode = 0>
        <cfset statusMessage = "">
        <cfset responseBody = "">
        <cfset responseHeader = {}>
        <cfset contentType = "">
        <cfset shouldRetry = false>

        <cfhttp url="#requestUrl#" method="get" result="httpResult" redirect="true" timeout="30" useragent="#requestSettings.userAgent#">
            <cfhttpparam type="header" name="Accept" value="#requestSettings.accept#">
            <cfhttpparam type="header" name="Accept-Language" value="#requestSettings.acceptLanguage#">
            <cfhttpparam type="header" name="Cache-Control" value="no-cache">
            <cfhttpparam type="header" name="Pragma" value="no-cache">
            <cfhttpparam type="header" name="Upgrade-Insecure-Requests" value="1">
            <cfhttpparam type="header" name="Sec-Fetch-Dest" value="document">
            <cfhttpparam type="header" name="Sec-Fetch-Mode" value="navigate">
            <cfhttpparam type="header" name="Sec-Fetch-Site" value="none">
            <cfhttpparam type="header" name="Sec-Fetch-User" value="?1">
            <cfif shouldUseContraRelogioSession(requestUrl) AND len(requestSettings.cookie)>
                <cfhttpparam type="header" name="Cookie" value="#requestSettings.cookie#">
            </cfif>
        </cfhttp>

        <cfset statusCode = val(listFirst(textOrFallback(httpResult.statusCode, "0"), " "))>
        <cfset responseBody = textOrFallback(httpResult.fileContent, "")>
        <cfif structKeyExists(httpResult, "responseHeader") AND isStruct(httpResult.responseHeader)>
            <cfset responseHeader = httpResult.responseHeader>
            <cfset contentType = lCase(trim(listFirst(responseHeaderValue(responseHeader, "Content-Type"), ";")))>
        </cfif>
        <cfif structKeyExists(httpResult, "errorDetail") AND len(trim(httpResult.errorDetail & ""))>
            <cfset statusMessage = trim(httpResult.errorDetail & "")>
        <cfelseif structKeyExists(httpResult, "statusText") AND len(trim(httpResult.statusText & ""))>
            <cfset statusMessage = trim(httpResult.statusText & "")>
        <cfelseif structKeyExists(httpResult, "statusCode") AND len(trim(httpResult.statusCode & ""))>
            <cfset statusMessage = trim(httpResult.statusCode & "")>
        </cfif>

        <cfif isCloudflareChallengeResponse(responseHeader, responseBody)>
            <cfset shouldRetry = attemptNumber LT maxAttempts>
            <cfif shouldRetry>
                <cfset pauseMilliseconds(requestSettings.retryDelayMs)>
                <cfset attemptNumber = attemptNumber + 1>
                <cfcontinue>
            </cfif>

            <cfset challengeMessage = "Feed bloqueado pela Cloudflare. A origem retornou um challenge HTML em vez do RSS XML.">
            <cfif feedImporterConfig.use_persisted_session>
                <cfif !len(trim(requestSettings.cookie))>
                    <cfset challengeMessage &= " A sessão persistida ainda não foi configurada na tela administrativa da Contra Relógio.">
                <cfelse>
                    <cfset challengeMessage &= " A sessão persistida configurada não foi aceita ou expirou; renove o cookie salvo na tela administrativa da Contra Relógio.">
                </cfif>
            <cfelse>
                <cfset challengeMessage &= " A fonte não possui sessão administrativa configurada para este conector.">
            </cfif>
            <cfset challengeMessage &= " Foram feitas " & maxAttempts & " tentativa(s), com espera de " & requestSettings.retryDelayMs & " ms entre elas.">
            <cfset challengeMessage &= " É preciso liberar tecnicamente o acesso do servidor/importador ao /feed/ ou renovar a sessão válida.">
            <cfreturn {
                success = false,
                status_code = (statusCode GT 0 ? statusCode : 403),
                url = requestUrl,
                content = responseBody,
                error_message = challengeMessage
            }>
        </cfif>

        <cfif statusCode GTE 200 AND statusCode LT 300 AND NOT looksLikeXmlFeed(responseBody)>
            <cfset shouldRetry = attemptNumber LT maxAttempts>
            <cfif shouldRetry>
                <cfset pauseMilliseconds(requestSettings.retryDelayMs)>
                <cfset attemptNumber = attemptNumber + 1>
                <cfcontinue>
            </cfif>

            <cfreturn {
                success = false,
                status_code = statusCode,
                url = requestUrl,
                content = responseBody,
                error_message = "A URL do feed respondeu com conteúdo que não é RSS/XML válido" & (len(contentType) ? " (" & contentType & ")" : "") & " após " & maxAttempts & " tentativa(s)."
            }>
        </cfif>

        <cfbreak>
    </cfloop>

    <cfreturn {
        success = statusCode GTE 200 AND statusCode LT 300,
        status_code = statusCode,
        url = requestUrl,
        content = responseBody,
        error_message = statusMessage
    }>
</cffunction>

<cffunction name="fetchArticleFeaturedMediaUrl" returntype="string" output="false">
    <cfargument name="articleUrl" type="string" required="true">
    <cfset var normalizedArticleUrl = trim(arguments.articleUrl)>
    <cfset var requestSettings = getContraRelogioRequestSettings()>
    <cfset var httpResult = {}>
    <cfset var statusCode = 0>
    <cfset var responseBody = "">
    <cfset var responseHeader = {}>
    <cfset var extractedUrl = "">

    <cfif NOT len(normalizedArticleUrl) OR NOT reFindNoCase("^https?://", normalizedArticleUrl)>
        <cfreturn "">
    </cfif>

    <cftry>
        <cfhttp url="#normalizedArticleUrl#" method="get" result="httpResult" redirect="true" timeout="30" useragent="#requestSettings.userAgent#">
            <cfhttpparam type="header" name="Accept" value="text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8">
            <cfhttpparam type="header" name="Accept-Language" value="#requestSettings.acceptLanguage#">
            <cfif shouldUseContraRelogioSession(normalizedArticleUrl) AND len(requestSettings.cookie)>
                <cfhttpparam type="header" name="Cookie" value="#requestSettings.cookie#">
            </cfif>
        </cfhttp>

        <cfset statusCode = val(listFirst(textOrFallback(httpResult.statusCode, "0"), " "))>
        <cfset responseBody = textOrFallback(httpResult.fileContent, "")>
        <cfif structKeyExists(httpResult, "responseHeader") AND isStruct(httpResult.responseHeader)>
            <cfset responseHeader = httpResult.responseHeader>
        </cfif>

        <cfif statusCode LT 200 OR statusCode GTE 300 OR isCloudflareChallengeResponse(responseHeader, responseBody)>
            <cfreturn "">
        </cfif>

        <cfset extractedUrl = extractMetadataImageUrl(responseBody)>
        <cfreturn resolveRemoteUrl(extractedUrl, normalizedArticleUrl)>
        <cfcatch type="any">
            <cfreturn "">
        </cfcatch>
    </cftry>
</cffunction>

<cffunction name="downloadRemoteMedia" returntype="struct" output="false">
    <cfargument name="mediaUrl" type="string" required="true">
    <cfargument name="authorId" type="numeric" required="true">
    <cfargument name="db" required="true">
    <cfset var normalizedMediaUrl = trim(arguments.mediaUrl)>
    <cfset var uploadDirectory = resolveUploadDirectory()>
    <cfset var tempDirectory = getTempDirectory()>
    <cfset var tempFileName = createUUID() & ".bin">
    <cfset var tempFilePath = tempDirectory & tempFileName>
    <cfset var httpResult = {}>
    <cfset var statusCode = 0>
    <cfset var originalFileName = fileNameFromUrl(normalizedMediaUrl)>
    <cfset var safeFileName = "">
    <cfset var targetPath = "">
    <cfset var inserted = "">
    <cfset var mimeType = "application/octet-stream">
    <cfset var fileInfo = {}>
    <cfset var fileSize = 0>
    <cfset var tempFileInfo = {}>
    <cfset var tempFileSize = 0>
    <cfset var contentLength = 0>
    <cfset var requestSettings = getContraRelogioRequestSettings()>

    <cfif NOT len(normalizedMediaUrl)>
        <cfreturn { success = false, media_id = 0, url_public = "", message = "URL de mídia vazia." }>
    </cfif>

    <cfif NOT directoryExists(uploadDirectory)>
        <cfset directoryCreate(uploadDirectory)>
    </cfif>

    <cfhttp url="#normalizedMediaUrl#" method="get" path="#tempDirectory#" file="#tempFileName#" result="httpResult" redirect="true" timeout="45" useragent="#requestSettings.userAgent#">
        <cfhttpparam type="header" name="Accept" value="image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8">
        <cfhttpparam type="header" name="Accept-Language" value="#requestSettings.acceptLanguage#">
        <cfhttpparam type="header" name="Cache-Control" value="no-cache">
        <cfhttpparam type="header" name="Pragma" value="no-cache">
        <cfhttpparam type="header" name="Sec-Fetch-Dest" value="image">
        <cfhttpparam type="header" name="Sec-Fetch-Mode" value="no-cors">
        <cfhttpparam type="header" name="Sec-Fetch-Site" value="same-origin">
        <cfhttpparam type="header" name="Referer" value="#feedImporterConfig.base_url#">
        <cfif shouldUseContraRelogioSession(normalizedMediaUrl) AND len(requestSettings.cookie)>
            <cfhttpparam type="header" name="Cookie" value="#requestSettings.cookie#">
        </cfif>
    </cfhttp>
    <cfset statusCode = val(listFirst(textOrFallback(httpResult.statusCode, "0"), " "))>

    <cfif structKeyExists(httpResult, "responseHeader") AND isStruct(httpResult.responseHeader) AND structKeyExists(httpResult.responseHeader, "Content-Type")>
        <cfset mimeType = lCase(trim(listFirst(httpResult.responseHeader["Content-Type"], ";")))>
    </cfif>

    <cfif fileExists(tempFilePath)>
        <cfset tempFileInfo = getFileInfo(tempFilePath)>
        <cfset tempFileSize = val(tempFileInfo.size ?: 0)>
    </cfif>
    <cfif structKeyExists(httpResult, "responseHeader") AND isStruct(httpResult.responseHeader) AND structKeyExists(httpResult.responseHeader, "Content-Length")>
        <cfset contentLength = val(httpResult.responseHeader["Content-Length"])>
    </cfif>

    <cfif statusCode LT 200
        OR statusCode GTE 300
        OR NOT fileExists(tempFilePath)
        OR tempFileSize LTE 0
        OR (contentLength GT 0 AND tempFileSize LT contentLength)
        OR (left(mimeType, 6) NEQ "image/" AND mimeType NEQ "application/octet-stream")>
        <cfif fileExists(tempFilePath)>
            <cfset fileDelete(tempFilePath)>
        </cfif>
        <cfreturn {
            success = false,
            media_id = 0,
            url_public = "",
            message = "Não foi possível baixar uma imagem válida da origem" & (len(mimeType) ? " (" & mimeType & ")" : "") & "."
        }>
    </cfif>

    <cfset safeFileName = buildUniqueUploadName(uploadDirectory, originalFileName)>
    <cfset targetPath = uploadDirectory & "/" & safeFileName>
    <cfset fileCopy(tempFilePath, targetPath)>
    <cfset fileDelete(tempFilePath)>
    <cfset fileInfo = getFileInfo(targetPath)>

    <cfif structKeyExists(fileInfo, "size")>
        <cfset fileSize = val(fileInfo.size)>
    </cfif>

    <cfif fileSize LTE 0 OR fileSize NEQ tempFileSize>
        <cfif fileExists(targetPath)>
            <cfset fileDelete(targetPath)>
        </cfif>
        <cfreturn {
            success = false,
            media_id = 0,
            url_public = "",
            message = "A imagem baixada não foi gravada integralmente no armazenamento local."
        }>
    </cfif>

    <cfset inserted = arguments.db.q("
      INSERT INTO news.tb_media (filename, orig_name, mime_type, size_bytes, url_public, author_id)
      VALUES (:fn, :orig, :mime, :size, :url, :uid)
      RETURNING id
    ", {
      fn:   {value=safeFileName, cfsqltype="cf_sql_varchar"},
      orig: {value=originalFileName, cfsqltype="cf_sql_varchar"},
      mime: {value=mimeType, cfsqltype="cf_sql_varchar"},
      size: {value=fileSize, cfsqltype="cf_sql_integer"},
      url:  {value="/public/uploads/" & safeFileName, cfsqltype="cf_sql_varchar"},
      uid:  {value=arguments.authorId, cfsqltype="cf_sql_integer"}
    })>

    <cfreturn {
        success = true,
        media_id = extractGeneratedId(inserted),
        url_public = "/public/uploads/" & safeFileName,
        message = ""
    }>
</cffunction>

<cffunction name="localMediaFileIsUsable" returntype="boolean" output="false">
    <cfargument name="mediaUrl" type="string" required="true">
    <cfargument name="expectedSize" type="numeric" required="false" default="0">
    <cfset var normalizedUrl = trim(arguments.mediaUrl)>
    <cfset var relativeUrl = "">
    <cfset var fileName = "">
    <cfset var filePath = "">
    <cfset var fileInfo = {}>
    <cfset var actualSize = 0>

    <cfif findNoCase("/public/uploads/", normalizedUrl) EQ 0>
        <cfreturn true>
    </cfif>

    <cfset relativeUrl = reReplaceNoCase(normalizedUrl, "^.*?/public/uploads/", "", "one")>
    <cfset relativeUrl = listFirst(relativeUrl, "?" & chr(35))>
    <cfset fileName = listLast(relativeUrl, "/")>
    <cfif NOT len(fileName) OR fileName NEQ relativeUrl>
        <cfreturn false>
    </cfif>

    <cfset filePath = resolveUploadDirectory() & "/" & fileName>
    <cfif NOT fileExists(filePath)>
        <cfreturn false>
    </cfif>

    <cfset fileInfo = getFileInfo(filePath)>
    <cfset actualSize = val(fileInfo.size ?: 0)>
    <cfif actualSize LTE 0>
        <cfreturn false>
    </cfif>

    <cfreturn arguments.expectedSize LTE 0 OR actualSize EQ arguments.expectedSize>
</cffunction>

<cffunction name="importedMediaNeedsRepair" returntype="boolean" output="false">
    <cfargument name="bodyHtml" type="string" required="false" default="">
    <cfargument name="featuredMediaUrl" type="string" required="false" default="">
    <cfargument name="featuredMediaSize" type="numeric" required="false" default="0">
    <cfset var localUrls = []>
    <cfset var localUrl = "">

    <cfif len(trim(arguments.featuredMediaUrl)) AND NOT localMediaFileIsUsable(arguments.featuredMediaUrl, arguments.featuredMediaSize)>
        <cfreturn true>
    </cfif>

    <cfset localUrls = reMatchNoCase('/public/uploads/[^"''<>\s?]+', arguments.bodyHtml)>
    <cfloop array="#localUrls#" index="localUrl">
        <cfif NOT localMediaFileIsUsable(localUrl)>
            <cfreturn true>
        </cfif>
    </cfloop>

    <cfreturn false>
</cffunction>

<cfscript>
db = createObject("component", "inc.db");
auth = createObject("component", "inc.auth");
feedUrl = feedImporterConfig.feed_url;
fixedContentTypeName = feedImporterConfig.content_type_name;
importerKey = feedImporterConfig.importer_key;
sourceName = feedImporterConfig.source_name;
defaultResponsibleEditorUserId = val(feedImporterConfig.default_responsible_editor_id);
currentUserId = structKeyExists(session, "user") AND structKeyExists(session.user, "id") ? val(session.user.id) : 0;
hasFeaturedMediaSupport = db.columnExists("news", "tb_content", "featured_media_id");
hasResponsibleEditorSupport = db.columnExists("news", "tb_users", "responsible_editor_id");
editorsQ = db.q("
  SELECT id, COALESCE(display_name, email) AS name
  FROM news.tb_users
  WHERE role = 'editor'
    AND is_active = true
  ORDER BY COALESCE(display_name, email) ASC
");

importMode = "latest";
importStatus = "review";
downloadFeaturedMedia = true;
maxPages = 0;
startPage = 1;
pagesPerRun = 10;
rawFeedXml = "";
reimportContentId = val(structKeyExists(form, "reimport_content_id") ? form.reimport_content_id : 0);
reimportMode = reimportContentId GT 0;
reimportMatched = false;
reimportService = "";
reimportTarget = {};
manualFeedImagesUploaded = 0;
defaultResponsibleEditorId = defaultResponsibleEditorUserId;
results = [];
summary = {
    created = 0,
    updated = 0,
    skipped = 0,
    errors = 0,
    processed = 0,
    pages = 0
};
pageAlertHtml = "";
fatalErrorMessage = "";
featuredMediaInsertColumnSql = "";
featuredMediaInsertValueSql = "";
retroactiveSelected = "";
latestSelected = "";
publishedSelected = "";
draftSelected = "";
reviewSelected = "";
downloadFeaturedMediaChecked = "";
responsibleEditorOptionsHtml = '<option value="">Selecione um editor</option>';
responsibleEditorHelpText = hasResponsibleEditorSupport
    ? "Obrigatório para autores novos criados automaticamente a partir do feed."
    : "A coluna responsible_editor_id ainda não existe no banco. Rode a migração antes de usar a criação automática de autores.";
responsibleEditorDisabledAttr = hasResponsibleEditorSupport ? "" : " disabled";

if (hasFeaturedMediaSupport) {
    featuredMediaInsertColumnSql = "featured_media_id, ";
    featuredMediaInsertValueSql = ":featured_media_id, ";
}

if (cgi.request_method EQ "POST") {
    try {
        if (!isApiExecution) {
            checkCsrf(form.csrf);
        }

        importMode = lCase(trim(structKeyExists(form, "import_mode") ? form.import_mode : "latest"));
        importStatus = lCase(trim(structKeyExists(form, "import_status") ? form.import_status : "review"));
        downloadFeaturedMedia = structKeyExists(form, "download_featured_media") AND form.download_featured_media EQ "1";
        maxPages = val(structKeyExists(form, "max_pages") ? form.max_pages : 0);
        startPage = val(structKeyExists(form, "start_page") ? form.start_page : 1);
        pagesPerRun = val(structKeyExists(form, "pages_per_run") ? form.pages_per_run : 10);
        defaultResponsibleEditorId = val(structKeyExists(form, "default_responsible_editor_id") ? form.default_responsible_editor_id : defaultResponsibleEditorUserId);
        rawFeedXml = normalizeManualFeedPayload(structKeyExists(form, "raw_feed_xml") ? form.raw_feed_xml : "");

        if (!listFindNoCase("retroactive,latest", importMode)) {
            cfthrow(message="Modo de importação inválido.");
        }

        if (len(rawFeedXml) AND !looksLikeXmlFeed(rawFeedXml)) {
            cfthrow(message="O conteúdo colado no Plano B não parece um RSS/XML válido.");
        }

        if (!listFindNoCase("published,draft,review", importStatus)) {
            cfthrow(message="Status de importação inválido.");
        }

        if (startPage LTE 0) {
            startPage = 1;
        }

        if (pagesPerRun LTE 0) {
            pagesPerRun = 10;
        } else if (pagesPerRun GT 100) {
            pagesPerRun = 100;
        }

        if (!hasResponsibleEditorSupport) {
            cfthrow(message="A coluna responsible_editor_id ainda não existe no banco. Rode a migração antes de usar este importador.");
        }

        if (defaultResponsibleEditorId LTE 0) {
            cfthrow(message="Selecione um editor responsável padrão para autores novos de " & sourceName & ".");
        }

        defaultResponsibleEditorQ = db.q("
          SELECT id
          FROM news.tb_users
          WHERE id = :id
            AND role = 'editor'
            AND is_active = true
          LIMIT 1
        ", {
          id: {value=defaultResponsibleEditorId, cfsqltype="cf_sql_integer"}
        });

        if (!defaultResponsibleEditorQ.recordCount) {
            cfthrow(message="Selecione um editor responsável válido para os autores novos.");
        }

        targetContentTypeId = ensureContentType(db, fixedContentTypeName);
        if (reimportMode) {
            reimportService = createObject("component", "inc.content_reimport_service").init(db);
            reimportTarget = reimportService.loadTarget(reimportContentId);
            if (!reimportTarget.found OR !reimportTarget.supported OR reimportTarget.importerKey NEQ importerKey) {
                cfthrow(message="O conteúdo informado não pertence ao importador " & sourceName & ".");
            }
            importMode = "retroactive";
            rawFeedXml = "";
            startPage = 1;
            pagesPerRun = 1000;
            maxPages = 1000;
        }
        channelPublicationPolicyService = createObject("component","inc.channel_publication_policy");
        channelPublicationPolicy = channelPublicationPolicyService.load(targetContentTypeId);

        if (targetContentTypeId LTE 0) {
            cfthrow(message="Não foi possível preparar o canal " & sourceName & ".");
        }

        if (importMode EQ "latest") {
            maxPages = 1;
            startPage = 1;
            pagesPerRun = 1;
        } else if (maxPages LTE 0) {
            maxPages = startPage + pagesPerRun - 1;
        } else {
            maxPages = min(maxPages, startPage + pagesPerRun - 1);
        }

        importIsPublished = importStatus EQ "published";
        importEditorialStatus = importStatus EQ "review" ? "review" : "draft";
        if (importIsPublished) {
            importEditorialStatus = "published";
        }

        uploadedManualMedia = {
            by_url = {},
            by_filename = {},
            total = 0
        };
        if (NOT isApiExecution AND len(rawFeedXml)) {
            uploadedManualMedia = storeUploadedManualMediaFiles(currentUserId, db);
        }
        manualFeedImagesUploaded = structKeyExists(uploadedManualMedia, "total") ? val(uploadedManualMedia.total) : 0;

        if (len(rawFeedXml)) {
            pageItems = parseFeedItems(rawFeedXml);

            if (!arrayLen(pageItems)) {
                cfthrow(message="O conteúdo colado no Plano B não trouxe itens <item> utilizáveis.");
            }

            summary.pages = 1;

            for (feedItem in pageItems) {
                summary.processed = summary.processed + 1;

                try {
                    feedItem = hydrateFeedItemFromArticle(feedItem);
                } catch (any articleError) {
                    arrayAppend(results, {
                        title = textOrFallback(feedItem.title, "Sem título"),
                        action = "Erro",
                        message = buildImportErrorMessage(articleError),
                        source_url = textOrFallback(feedItem.source_url, "")
                    });
                    summary.errors = summary.errors + 1;
                    continue;
                }

                if (feedImporterConfig.require_source_publication_date AND !isDate(feedItem.published_at)) {
                    arrayAppend(results, {
                        title = textOrFallback(feedItem.title, "Sem título"),
                        action = "Erro",
                        message = "A data de publicação original não pôde ser interpretada; o conteúdo não foi importado com a data atual.",
                        source_url = textOrFallback(feedItem.source_url, "")
                    });
                    summary.errors = summary.errors + 1;
                    continue;
                }

                if (!len(trim(feedItem.title)) OR !len(trim(feedItem.body_html))) {
                    arrayAppend(results, {
                        title = textOrFallback(feedItem.title, "Sem título"),
                        action = "Erro",
                        message = "Item ignorado por não ter título ou corpo útil.",
                        source_url = textOrFallback(feedItem.source_url, "")
                    });
                    summary.errors = summary.errors + 1;
                    continue;
                }

                if (downloadFeaturedMedia AND !len(trim(feedItem.media_url))) {
                    feedItem.media_url = fetchArticleFeaturedMediaUrl(feedItem.source_url);
                }

                sourceKey = buildImportSourceKey(feedItem.source_guid, feedItem.source_url, feedItem.title, feedItem.published_at_raw);
                sourceHash = buildSourceHash(feedItem);
                existingImport = db.q("
                  SELECT i.id, i.content_id, i.source_hash,
                         COALESCE(i.detail_json->>'source_fingerprint', '') AS existing_source_fingerprint,
                         COALESCE(i.detail_json->>'source_fingerprint_version', '') AS existing_source_fingerprint_version,
                         c.id AS existing_content_id,
                         COALESCE(c.published, false) AS existing_published,
                         COALESCE(c.editorial_status, CASE WHEN c.published THEN 'published' ELSE 'draft' END) AS existing_editorial_status,
                         COALESCE(c.body_html, '') AS existing_body_html,
                         c.published_at AS existing_published_at,
                         " & (hasFeaturedMediaSupport ? "COALESCE(c.featured_media_id, 0)" : "0") & " AS existing_featured_media_id,
                         " & (hasFeaturedMediaSupport ? "COALESCE(existing_media.url_public, '')" : "''") & " AS existing_featured_media_url,
                         " & (hasFeaturedMediaSupport ? "COALESCE(existing_media.size_bytes, 0)" : "0") & " AS existing_featured_media_size
                  FROM news.tb_content_imports i
                  LEFT JOIN news.tb_content c ON c.id = i.content_id
                  " & (hasFeaturedMediaSupport ? "LEFT JOIN news.tb_media existing_media ON existing_media.id = c.featured_media_id" : "") & "
                  WHERE i.importer_key = :importer_key
                    AND (
                      i.source_key = :source_key
                      OR (:source_url <> '' AND i.source_url = :source_url)
                      OR (:source_guid <> '' AND i.source_guid = :source_guid)
                      OR (:source_hash <> '' AND i.source_hash = :source_hash)
                    )
                  ORDER BY
                    CASE
                      WHEN i.source_key = :source_key THEN 0
                      WHEN (:source_guid <> '' AND i.source_guid = :source_guid) THEN 1
                      WHEN (:source_url <> '' AND i.source_url = :source_url) THEN 2
                      WHEN (:source_hash <> '' AND i.source_hash = :source_hash) THEN 3
                      ELSE 4
                    END,
                    i.id DESC
                  LIMIT 1
                ", {
                  importer_key: {value=importerKey, cfsqltype="cf_sql_varchar"},
                  source_key: {value=sourceKey, cfsqltype="cf_sql_varchar"},
                  source_url: {value=textOrFallback(feedItem.source_url, ""), cfsqltype="cf_sql_varchar"},
                  source_guid: {value=textOrFallback(feedItem.source_guid, ""), cfsqltype="cf_sql_varchar"},
                  source_hash: {value=textOrFallback(sourceHash, ""), cfsqltype="cf_sql_varchar"}
                });

                if (existingImport.recordCount) {
                    if (val(existingImport.existing_content_id[1] ?: 0) LTE 0) {
                        db.q("
                          DELETE FROM news.tb_content_imports
                          WHERE id = :id
                        ", {
                          id: {value=val(existingImport.id[1]), cfsqltype="cf_sql_integer"}
                        });
                    } else {
                        existingImportId = val(existingImport.id[1]);
                        contentId = val(existingImport.existing_content_id[1]);
                        previousSourceHash = textOrFallback(existingImport.source_hash[1], "");
                        previousSourceFingerprint = textOrFallback(existingImport.existing_source_fingerprint[1], "");
                        previousSourceFingerprintVersion = val(existingImport.existing_source_fingerprint_version[1] ?: 0);
                        mediaRepairRequired = downloadFeaturedMedia AND (
                            (len(trim(feedItem.media_url)) AND val(existingImport.existing_featured_media_id[1] ?: 0) LTE 0)
                            OR (len(feedImporterConfig.media_repair_url_fragment) AND findNoCase(feedImporterConfig.media_repair_url_fragment, textOrFallback(existingImport.existing_body_html[1], "")) GT 0)
                            OR importedMediaNeedsRepair(
                                textOrFallback(existingImport.existing_body_html[1], ""),
                                textOrFallback(existingImport.existing_featured_media_url[1], ""),
                                val(existingImport.existing_featured_media_size[1] ?: 0)
                            )
                        );
                        publicationDateRepairRequired = isDate(feedItem.published_at) AND (
                            !isDate(existingImport.existing_published_at[1])
                            OR abs(dateDiff("s", existingImport.existing_published_at[1], feedItem.published_at)) GT 1
                        );
                        sourceHashMatches = usesSemanticSourceFingerprint()
                            ? (
                                previousSourceFingerprintVersion EQ sourceFingerprintVersion()
                                AND len(previousSourceFingerprint)
                                AND previousSourceFingerprint EQ sourceHash
                              )
                            : (len(previousSourceHash) AND previousSourceHash EQ sourceHash);

                        if (
                            usesSemanticSourceFingerprint()
                            AND (
                                previousSourceFingerprintVersion NEQ sourceFingerprintVersion()
                                OR NOT len(previousSourceFingerprint)
                            )
                            AND NOT mediaRepairRequired
                            AND NOT publicationDateRepairRequired
                        ) {
                            baselineSourceFingerprint(
                                db = db,
                                existingImportId = existingImportId,
                                sourceFingerprint = sourceHash,
                                fingerprintVersion = sourceFingerprintVersion()
                            );
                            sourceHashMatches = true;
                        }

                        if (
                            sourceHashMatches
                            AND importStatus EQ "review"
                            AND NOT existingImport.existing_published[1]
                            AND lCase(textOrFallback(existingImport.existing_editorial_status[1], "draft")) EQ "draft"
                            AND NOT mediaRepairRequired
                            AND NOT publicationDateRepairRequired
                        ) {
                            db.q("
                              UPDATE news.tb_content
                              SET editorial_status = 'review',
                                  published = false,
                                  is_featured = false,
                                  updated_at = now()
                              WHERE id = :content_id
                            ", {
                              content_id: {value=contentId, cfsqltype="cf_sql_integer"}
                            });

                            arrayAppend(results, {
                                title = feedItem.title,
                                action = "Atualizado",
                                message = "Conteúdo existente enviado para a fila de curadoria.",
                                source_url = feedItem.source_url
                            });
                            summary.updated = summary.updated + 1;
                            continue;
                        }

                        if (sourceHashMatches AND NOT mediaRepairRequired AND NOT publicationDateRepairRequired) {
                            arrayAppend(results, {
                                title = feedItem.title,
                                action = "Ignorado",
                                message = "Já importado anteriormente e sem alterações na fonte.",
                                source_url = feedItem.source_url
                            });
                            summary.skipped = summary.skipped + 1;
                            continue;
                        }
                    }
                }

                primaryCategoryName = arrayLen(feedItem.categories) ? feedItem.categories[1] : "";
                targetCategoryId = ensureCategory(db, primaryCategoryName);
                targetTagNames = feedItem.categories;
                featuredMediaId = 0;
                featuredMediaResult = { success = false, media_id = 0, url_public = "", message = "" };
                contentId = 0;
                existingImportId = 0;
                updateMode = false;
                targetAuthorName = textOrFallback(feedItem.source_author, "Redação");
                targetAuthorId = ensureImportedAuthor(db, auth, currentUserId, targetAuthorName, defaultResponsibleEditorId);
                bodyImportResult = {
                    html = feedItem.body_html,
                    media_map = {}
                };
                normalizedBodyMediaUrlKey = "";
                contentSlug = "";
                currentContentQ = "";
                currentPublished = importIsPublished;
                currentEditorialStatus = importEditorialStatus;
                currentIsFeatured = false;
                currentFeaturedMediaId = 0;

                if (targetAuthorId LTE 0) {
                    cfthrow(message="Não foi possível preparar o autor local " & targetAuthorName & ".");
                }

                if (existingImport.recordCount AND val(existingImport.existing_content_id[1] ?: 0) GT 0) {
                    updateMode = true;
                    existingImportId = val(existingImport.id[1]);
                    contentId = val(existingImport.existing_content_id[1]);
                    currentContentQ = db.q("
                      SELECT slug, published, editorial_status, is_featured" & (hasFeaturedMediaSupport ? ", COALESCE(featured_media_id, 0) AS featured_media_id" : "") & "
                      FROM news.tb_content
                      WHERE id = :id
                      LIMIT 1
                    ", {
                      id: {value=contentId, cfsqltype="cf_sql_integer"}
                    });

                    if (!currentContentQ.recordCount) {
                        cfthrow(message="O conteúdo local vinculado à importação não foi encontrado.");
                    }

                    contentSlug = textOrFallback(currentContentQ.slug[1], "");
                    currentPublished = currentContentQ.published[1];
                    currentEditorialStatus = textOrFallback(currentContentQ.editorial_status[1], currentPublished ? "published" : "draft");
                    currentIsFeatured = currentContentQ.is_featured[1];
                    if (hasFeaturedMediaSupport) {
                        currentFeaturedMediaId = val(currentContentQ.featured_media_id[1] ?: 0);
                    }
                } else {
                    contentSlug = buildUniqueSlug(db, feedItem.title);
                }

                bodyImportResult = channelPublicationPolicy.sourceMediaAllowed ? processImportedBodyImages(feedItem.body_html, targetAuthorId, db, feedItem.source_url, uploadedManualMedia) : {html=channelPublicationPolicyService.sanitizeImportedHtml(feedItem.body_html,channelPublicationPolicy),media_map={}};
                feedItem.body_html = bodyImportResult.html;

                if (channelPublicationPolicy.sourceMediaAllowed AND downloadFeaturedMedia AND hasFeaturedMediaSupport AND len(trim(feedItem.media_url))) {
                    normalizedBodyMediaUrlKey = lCase(trim(feedItem.media_url));

                    if (
                        structKeyExists(bodyImportResult, "media_map")
                        AND isStruct(bodyImportResult.media_map)
                        AND structKeyExists(bodyImportResult.media_map, normalizedBodyMediaUrlKey)
                    ) {
                        featuredMediaId = val(bodyImportResult.media_map[normalizedBodyMediaUrlKey].media_id);
                        featuredMediaResult = {
                            success = (featuredMediaId GT 0),
                            media_id = featuredMediaId,
                            url_public = bodyImportResult.media_map[normalizedBodyMediaUrlKey].url_public,
                            message = ""
                        };
                    } else if (
                        isStruct(uploadedManualMedia)
                        AND structKeyExists(uploadedManualMedia, "by_filename")
                        AND isStruct(uploadedManualMedia.by_filename)
                        AND structKeyExists(uploadedManualMedia.by_filename, mediaKeyFromUrl(feedItem.media_url))
                    ) {
                        featuredMediaId = val(uploadedManualMedia.by_filename[mediaKeyFromUrl(feedItem.media_url)].media_id);
                        featuredMediaResult = {
                            success = (featuredMediaId GT 0),
                            media_id = featuredMediaId,
                            url_public = uploadedManualMedia.by_filename[mediaKeyFromUrl(feedItem.media_url)].url_public,
                            message = ""
                        };
                    } else {
                        try {
                            featuredMediaResult = downloadRemoteMedia(feedItem.media_url, targetAuthorId, db);
                            if (featuredMediaResult.success) {
                                featuredMediaId = val(featuredMediaResult.media_id);
                            }
                        } catch (any mediaImportError) {
                            featuredMediaId = 0;
                        }
                    }
                }

                if (updateMode AND featuredMediaId LTE 0 AND hasFeaturedMediaSupport) {
                    featuredMediaId = currentFeaturedMediaId;
                }

                if (featuredMediaId GT 0) {
                    feedItem.body_html = stripLeadingFeaturedImageBlock(
                        feedItem.body_html,
                        feedItem.media_url,
                        featuredMediaResult.url_public
                    );
                }

                insertSql = "
                  INSERT INTO news.tb_content (
                    slug, title, excerpt, body_html, published, editorial_status, is_featured, "
                    & featuredMediaInsertColumnSql
                    & "published_at, author_id, content_type_id, category_id
                  )
                  VALUES (
                    :slug, :title, :excerpt, :body_html, :published, :editorial_status, :is_featured, "
                    & featuredMediaInsertValueSql
                    & ":published_at, :author_id, :content_type_id, :category_id
                  )
                  RETURNING id
                ";
                insertParams = {
                  slug: {value=contentSlug, cfsqltype="cf_sql_varchar"},
                  title: {value=feedItem.title, cfsqltype="cf_sql_varchar"},
                  excerpt: {value=feedItem.excerpt_text, cfsqltype="cf_sql_longvarchar", null=(NOT len(trim(feedItem.excerpt_text)))},
                  body_html: {value=feedItem.body_html, cfsqltype="cf_sql_longvarchar"},
                  published: {value=(updateMode ? currentPublished : importIsPublished), cfsqltype="cf_sql_bit"},
                  editorial_status: {value=(updateMode ? currentEditorialStatus : importEditorialStatus), cfsqltype="cf_sql_varchar"},
                  is_featured: {value=(updateMode ? currentIsFeatured : false), cfsqltype="cf_sql_bit"},
                  published_at: {value=feedItem.published_at, cfsqltype="cf_sql_timestamp", null=(NOT isDate(feedItem.published_at))},
                  author_id: {value=targetAuthorId, cfsqltype="cf_sql_integer"},
                  content_type_id: {value=targetContentTypeId, cfsqltype="cf_sql_integer"},
                  category_id: {value=targetCategoryId, cfsqltype="cf_sql_integer", null=(targetCategoryId LTE 0)}
                };

                if (hasFeaturedMediaSupport) {
                    insertParams.featured_media_id = {value=featuredMediaId, cfsqltype="cf_sql_integer", null=(featuredMediaId LTE 0)};
                }

                try {
                    transaction {
                        if (updateMode) {
                            updateSql = "
                              UPDATE news.tb_content
                                 SET title = :title,
                                     excerpt = :excerpt,
                                     body_html = :body_html,
                                     " & (hasFeaturedMediaSupport ? "featured_media_id = :featured_media_id," : "") & "
                                     published_at = :published_at,
                                     author_id = :author_id,
                                     content_type_id = :content_type_id,
                                     category_id = :category_id,
                                     updated_at = now()
                               WHERE id = :id
                            ";
                            updateParams = duplicate(insertParams);
                            updateParams.id = {value=contentId, cfsqltype="cf_sql_integer"};
                            structDelete(updateParams, "slug");
                            structDelete(updateParams, "published");
                            structDelete(updateParams, "editorial_status");
                            structDelete(updateParams, "is_featured");
                            db.q(updateSql, updateParams);
                        } else {
                            insertResult = db.q(insertSql, insertParams);
                            contentId = extractGeneratedId(insertResult);

                            if (contentId LTE 0) {
                                cfthrow(message="Não foi possível obter o ID do conteúdo importado.");
                            }
                        }

                        syncContentTags(db, contentId, targetTagNames);

                        upsertContentImportRecord(
                            db = db,
                            importerKey = importerKey,
                            sourceName = sourceName,
                            sourceKey = sourceKey,
                            sourceUrl = feedItem.source_url,
                            sourceGuid = feedItem.source_guid,
                            sourceHash = sourceHash,
                            sourceAuthor = feedItem.source_author,
                            contentId = contentId,
                            detailData = {
                                source_url = feedItem.source_url,
                                source_guid = feedItem.source_guid,
                                source_author = feedItem.source_author,
                                source_pubdate = feedItem.published_at_raw,
                                source_published_at = isDate(feedItem.published_at) ? dateTimeFormat(feedItem.published_at, "yyyy-mm-dd HH:nn:ss") : "",
                                source_categories = feedItem.categories,
                                source_description_html = feedItem.description_html,
                                source_media_url = feedItem.media_url,
                                source_fingerprint = sourceHash,
                                source_fingerprint_version = sourceFingerprintVersion(),
                                local_author_name = targetAuthorName,
                                local_author_id = targetAuthorId,
                                default_responsible_editor_id = defaultResponsibleEditorId,
                                import_mode = "manual_feed",
                                import_status = importStatus,
                                featured_media_downloaded = featuredMediaResult.success,
                                synced_at = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss")
                            },
                            existingImportId = existingImportId
                        );
                    }

                    try {
                        audit = createObject("component", "inc.audit");
                        audit.record(currentUserId, (updateMode ? "content.sync_update_" & feedImporterConfig.audit_suffix : "content.import_" & feedImporterConfig.audit_suffix), "news.tb_content", contentId, {
                            source_url = feedItem.source_url,
                            source_guid = feedItem.source_guid,
                            source_author = feedItem.source_author,
                            local_author_name = targetAuthorName,
                            local_author_id = targetAuthorId,
                            content_type_id = targetContentTypeId,
                            category_name = primaryCategoryName,
                            imported_status = importStatus,
                            source_hash = sourceHash,
                            source_mode = "manual_feed"
                        });
                    } catch (any auditError) {}

                    arrayAppend(results, {
                        title = feedItem.title,
                        action = (updateMode ? "Atualizado" : "Importado"),
                        message = (updateMode ? "Conteúdo atualizado a partir do feed colado manualmente." : "Conteúdo criado com sucesso a partir do feed colado manualmente."),
                        source_url = feedItem.source_url,
                        source_media_url = feedItem.media_url,
                        featured_media_id = featuredMediaId,
                        media_status = (featuredMediaId GT 0 ? "linked" : (len(trim(feedItem.media_url)) ? "download_failed" : "not_provided")),
                        localized_body_images = (structKeyExists(bodyImportResult, "media_map") AND isStruct(bodyImportResult.media_map) ? structCount(bodyImportResult.media_map) : 0)
                    });
                    if (updateMode) {
                        summary.updated = summary.updated + 1;
                    } else {
                        summary.created = summary.created + 1;
                    }
                } catch (any itemError) {
                    arrayAppend(results, {
                        title = feedItem.title,
                        action = "Erro",
                        message = buildImportErrorMessage(itemError),
                        source_url = feedItem.source_url
                    });
                    summary.errors = summary.errors + 1;
                }
            }
        } else {
            for (feedPage = startPage; feedPage <= maxPages; feedPage = feedPage + 1) {
                pageFetch = fetchFeedPage(feedUrl, feedPage, importMode EQ "retroactive");

                if (!pageFetch.success) {
                    arrayAppend(results, {
                        title = "Página " & feedPage,
                        action = "Erro",
                        message = "Falha ao carregar o feed: " & textOrFallback(pageFetch.error_message, "HTTP " & pageFetch.status_code),
                        source_url = textOrFallback(pageFetch.url, feedUrl)
                    });
                    summary.errors = summary.errors + 1;
                    break;
                }

                pageItems = structKeyExists(pageFetch, "items") AND isArray(pageFetch.items)
                    ? pageFetch.items
                    : parseFeedItems(pageFetch.content);

                if (!arrayLen(pageItems)) {
                    break;
                }

                summary.pages = summary.pages + 1;

                for (feedItem in pageItems) {
                summary.processed = summary.processed + 1;

                candidateSourceKey = buildImportSourceKey(feedItem.source_guid, feedItem.source_url, feedItem.title, feedItem.published_at_raw);
                if (reimportMode AND !reimportService.matches(reimportTarget, candidateSourceKey, feedItem.source_url, feedItem.source_guid)) {
                    continue;
                }
                if (reimportMode) reimportMatched = true;

                try {
                    feedItem = hydrateFeedItemFromArticle(feedItem);
                } catch (any articleError) {
                    arrayAppend(results, {
                        title = textOrFallback(feedItem.title, "Sem título"),
                        action = "Erro",
                        message = buildImportErrorMessage(articleError),
                        source_url = textOrFallback(feedItem.source_url, "")
                    });
                    summary.errors = summary.errors + 1;
                    continue;
                }

                if (feedImporterConfig.require_source_publication_date AND !isDate(feedItem.published_at)) {
                    arrayAppend(results, {
                        title = textOrFallback(feedItem.title, "Sem título"),
                        action = "Erro",
                        message = "A data de publicação original não pôde ser interpretada; o conteúdo não foi importado com a data atual.",
                        source_url = textOrFallback(feedItem.source_url, "")
                    });
                    summary.errors = summary.errors + 1;
                    continue;
                }

                if (!len(trim(feedItem.title)) OR !len(trim(feedItem.body_html))) {
                    arrayAppend(results, {
                        title = textOrFallback(feedItem.title, "Sem título"),
                        action = "Erro",
                        message = "Item ignorado por não ter título ou corpo útil.",
                        source_url = textOrFallback(feedItem.source_url, "")
                    });
                    summary.errors = summary.errors + 1;
                    continue;
                }

                if (downloadFeaturedMedia AND !len(trim(feedItem.media_url))) {
                    feedItem.media_url = fetchArticleFeaturedMediaUrl(feedItem.source_url);
                }

                sourceKey = buildImportSourceKey(feedItem.source_guid, feedItem.source_url, feedItem.title, feedItem.published_at_raw);
                sourceHash = buildSourceHash(feedItem);
                existingImport = db.q("
                  SELECT i.id, i.content_id, i.source_hash,
                         COALESCE(i.detail_json->>'source_fingerprint', '') AS existing_source_fingerprint,
                         COALESCE(i.detail_json->>'source_fingerprint_version', '') AS existing_source_fingerprint_version,
                         c.id AS existing_content_id,
                         COALESCE(c.published, false) AS existing_published,
                         COALESCE(c.editorial_status, CASE WHEN c.published THEN 'published' ELSE 'draft' END) AS existing_editorial_status,
                         COALESCE(c.body_html, '') AS existing_body_html,
                         c.published_at AS existing_published_at,
                         " & (hasFeaturedMediaSupport ? "COALESCE(c.featured_media_id, 0)" : "0") & " AS existing_featured_media_id,
                         " & (hasFeaturedMediaSupport ? "COALESCE(existing_media.url_public, '')" : "''") & " AS existing_featured_media_url,
                         " & (hasFeaturedMediaSupport ? "COALESCE(existing_media.size_bytes, 0)" : "0") & " AS existing_featured_media_size
                  FROM news.tb_content_imports i
                  LEFT JOIN news.tb_content c ON c.id = i.content_id
                  " & (hasFeaturedMediaSupport ? "LEFT JOIN news.tb_media existing_media ON existing_media.id = c.featured_media_id" : "") & "
                  WHERE i.importer_key = :importer_key
                    AND (
                      i.source_key = :source_key
                      OR (:source_url <> '' AND i.source_url = :source_url)
                      OR (:source_guid <> '' AND i.source_guid = :source_guid)
                      OR (:source_hash <> '' AND i.source_hash = :source_hash)
                    )
                  ORDER BY
                    CASE
                      WHEN i.source_key = :source_key THEN 0
                      WHEN (:source_guid <> '' AND i.source_guid = :source_guid) THEN 1
                      WHEN (:source_url <> '' AND i.source_url = :source_url) THEN 2
                      WHEN (:source_hash <> '' AND i.source_hash = :source_hash) THEN 3
                      ELSE 4
                    END,
                    i.id DESC
                  LIMIT 1
                ", {
                  importer_key: {value=importerKey, cfsqltype="cf_sql_varchar"},
                  source_key: {value=sourceKey, cfsqltype="cf_sql_varchar"},
                  source_url: {value=textOrFallback(feedItem.source_url, ""), cfsqltype="cf_sql_varchar"},
                  source_guid: {value=textOrFallback(feedItem.source_guid, ""), cfsqltype="cf_sql_varchar"},
                  source_hash: {value=textOrFallback(sourceHash, ""), cfsqltype="cf_sql_varchar"}
                });

                if (existingImport.recordCount) {
                    if (val(existingImport.existing_content_id[1] ?: 0) LTE 0) {
                        db.q("
                          DELETE FROM news.tb_content_imports
                          WHERE id = :id
                        ", {
                          id: {value=val(existingImport.id[1]), cfsqltype="cf_sql_integer"}
                        });
                    } else {
                        existingImportId = val(existingImport.id[1]);
                        contentId = val(existingImport.existing_content_id[1]);
                        previousSourceHash = textOrFallback(existingImport.source_hash[1], "");
                        previousSourceFingerprint = textOrFallback(existingImport.existing_source_fingerprint[1], "");
                        previousSourceFingerprintVersion = val(existingImport.existing_source_fingerprint_version[1] ?: 0);
                        mediaRepairRequired = downloadFeaturedMedia AND (
                            (len(trim(feedItem.media_url)) AND val(existingImport.existing_featured_media_id[1] ?: 0) LTE 0)
                            OR (len(feedImporterConfig.media_repair_url_fragment) AND findNoCase(feedImporterConfig.media_repair_url_fragment, textOrFallback(existingImport.existing_body_html[1], "")) GT 0)
                            OR importedMediaNeedsRepair(
                                textOrFallback(existingImport.existing_body_html[1], ""),
                                textOrFallback(existingImport.existing_featured_media_url[1], ""),
                                val(existingImport.existing_featured_media_size[1] ?: 0)
                            )
                        );
                        publicationDateRepairRequired = isDate(feedItem.published_at) AND (
                            !isDate(existingImport.existing_published_at[1])
                            OR abs(dateDiff("s", existingImport.existing_published_at[1], feedItem.published_at)) GT 1
                        );
                        sourceHashMatches = usesSemanticSourceFingerprint()
                            ? (
                                previousSourceFingerprintVersion EQ sourceFingerprintVersion()
                                AND len(previousSourceFingerprint)
                                AND previousSourceFingerprint EQ sourceHash
                              )
                            : (len(previousSourceHash) AND previousSourceHash EQ sourceHash);

                        if (
                            NOT reimportMode
                            AND usesSemanticSourceFingerprint()
                            AND (
                                previousSourceFingerprintVersion NEQ sourceFingerprintVersion()
                                OR NOT len(previousSourceFingerprint)
                            )
                            AND NOT mediaRepairRequired
                            AND NOT publicationDateRepairRequired
                        ) {
                            baselineSourceFingerprint(
                                db = db,
                                existingImportId = existingImportId,
                                sourceFingerprint = sourceHash,
                                fingerprintVersion = sourceFingerprintVersion()
                            );
                            sourceHashMatches = true;
                        }

                        if (
                            NOT reimportMode
                            AND
                            sourceHashMatches
                            AND importStatus EQ "review"
                            AND NOT existingImport.existing_published[1]
                            AND lCase(textOrFallback(existingImport.existing_editorial_status[1], "draft")) EQ "draft"
                            AND NOT mediaRepairRequired
                            AND NOT publicationDateRepairRequired
                        ) {
                            db.q("
                              UPDATE news.tb_content
                              SET editorial_status = 'review',
                                  published = false,
                                  is_featured = false,
                                  updated_at = now()
                              WHERE id = :content_id
                            ", {
                              content_id: {value=contentId, cfsqltype="cf_sql_integer"}
                            });

                            arrayAppend(results, {
                                title = feedItem.title,
                                action = "Atualizado",
                                message = "Conteúdo existente enviado para a fila de curadoria.",
                                source_url = feedItem.source_url
                            });
                            summary.updated = summary.updated + 1;
                            continue;
                        }

                        if (NOT reimportMode AND sourceHashMatches AND NOT mediaRepairRequired AND NOT publicationDateRepairRequired) {
                            arrayAppend(results, {
                                title = feedItem.title,
                                action = "Ignorado",
                                message = "Já importado anteriormente e sem alterações na fonte.",
                                source_url = feedItem.source_url
                            });
                            summary.skipped = summary.skipped + 1;
                            continue;
                        }
                    }
                }

                if (reimportMode AND (!existingImport.recordCount OR val(existingImport.existing_content_id[1] ?: 0) NEQ reimportContentId)) {
                    cfthrow(message="O vínculo do conteúdo solicitado não corresponde ao item localizado na fonte.");
                }

                primaryCategoryName = arrayLen(feedItem.categories) ? feedItem.categories[1] : "";
                targetCategoryId = ensureCategory(db, primaryCategoryName);
                targetTagNames = feedItem.categories;
                featuredMediaId = 0;
                featuredMediaResult = { success = false, media_id = 0, url_public = "", message = "" };
                contentId = 0;
                existingImportId = 0;
                updateMode = false;
                targetAuthorName = textOrFallback(feedItem.source_author, "Redação");
                targetAuthorId = ensureImportedAuthor(db, auth, currentUserId, targetAuthorName, defaultResponsibleEditorId);
                bodyImportResult = {
                    html = feedItem.body_html,
                    media_map = {}
                };
                normalizedBodyMediaUrlKey = "";
                contentSlug = "";
                currentContentQ = "";
                currentPublished = importIsPublished;
                currentEditorialStatus = importEditorialStatus;
                currentIsFeatured = false;
                currentFeaturedMediaId = 0;

                if (targetAuthorId LTE 0) {
                    cfthrow(message="Não foi possível preparar o autor local " & targetAuthorName & ".");
                }

                if (existingImport.recordCount AND val(existingImport.existing_content_id[1] ?: 0) GT 0) {
                    updateMode = true;
                    existingImportId = val(existingImport.id[1]);
                    contentId = val(existingImport.existing_content_id[1]);
                    currentContentQ = db.q("
                      SELECT slug, published, editorial_status, is_featured" & (hasFeaturedMediaSupport ? ", COALESCE(featured_media_id, 0) AS featured_media_id" : "") & "
                      FROM news.tb_content
                      WHERE id = :id
                      LIMIT 1
                    ", {
                      id: {value=contentId, cfsqltype="cf_sql_integer"}
                    });

                    if (!currentContentQ.recordCount) {
                        cfthrow(message="O conteúdo local vinculado à importação não foi encontrado.");
                    }

                    contentSlug = textOrFallback(currentContentQ.slug[1], "");
                    currentPublished = currentContentQ.published[1];
                    currentEditorialStatus = textOrFallback(currentContentQ.editorial_status[1], currentPublished ? "published" : "draft");
                    currentIsFeatured = currentContentQ.is_featured[1];
                    if (hasFeaturedMediaSupport) {
                        currentFeaturedMediaId = val(currentContentQ.featured_media_id[1] ?: 0);
                    }
                } else {
                    contentSlug = buildUniqueSlug(db, feedItem.title);
                }

                bodyImportResult = channelPublicationPolicy.sourceMediaAllowed ? processImportedBodyImages(feedItem.body_html, targetAuthorId, db, feedItem.source_url, {}) : {html=channelPublicationPolicyService.sanitizeImportedHtml(feedItem.body_html,channelPublicationPolicy),media_map={}};
                feedItem.body_html = bodyImportResult.html;

                if (channelPublicationPolicy.sourceMediaAllowed AND downloadFeaturedMedia AND hasFeaturedMediaSupport AND len(trim(feedItem.media_url))) {
                    normalizedBodyMediaUrlKey = lCase(trim(feedItem.media_url));

                    if (
                        structKeyExists(bodyImportResult, "media_map")
                        AND isStruct(bodyImportResult.media_map)
                        AND structKeyExists(bodyImportResult.media_map, normalizedBodyMediaUrlKey)
                    ) {
                        featuredMediaId = val(bodyImportResult.media_map[normalizedBodyMediaUrlKey].media_id);
                        featuredMediaResult = {
                            success = (featuredMediaId GT 0),
                            media_id = featuredMediaId,
                            url_public = bodyImportResult.media_map[normalizedBodyMediaUrlKey].url_public,
                            message = ""
                        };
                    } else {
                        try {
                            featuredMediaResult = downloadRemoteMedia(feedItem.media_url, targetAuthorId, db);
                            if (featuredMediaResult.success) {
                                featuredMediaId = val(featuredMediaResult.media_id);
                            }
                        } catch (any mediaImportError) {
                            featuredMediaId = 0;
                        }
                    }
                }

                if (updateMode AND featuredMediaId LTE 0 AND hasFeaturedMediaSupport) {
                    featuredMediaId = currentFeaturedMediaId;
                }

                if (featuredMediaId GT 0) {
                    feedItem.body_html = stripLeadingFeaturedImageBlock(
                        feedItem.body_html,
                        feedItem.media_url,
                        featuredMediaResult.url_public
                    );
                }

                insertSql = "
                  INSERT INTO news.tb_content (
                    slug, title, excerpt, body_html, published, editorial_status, is_featured, "
                    & featuredMediaInsertColumnSql
                    & "published_at, author_id, content_type_id, category_id
                  )
                  VALUES (
                    :slug, :title, :excerpt, :body_html, :published, :editorial_status, :is_featured, "
                    & featuredMediaInsertValueSql
                    & ":published_at, :author_id, :content_type_id, :category_id
                  )
                  RETURNING id
                ";
                insertParams = {
                  slug: {value=contentSlug, cfsqltype="cf_sql_varchar"},
                  title: {value=feedItem.title, cfsqltype="cf_sql_varchar"},
                  excerpt: {value=feedItem.excerpt_text, cfsqltype="cf_sql_longvarchar", null=(NOT len(trim(feedItem.excerpt_text)))},
                  body_html: {value=feedItem.body_html, cfsqltype="cf_sql_longvarchar"},
                  published: {value=(updateMode ? currentPublished : importIsPublished), cfsqltype="cf_sql_bit"},
                  editorial_status: {value=(updateMode ? currentEditorialStatus : importEditorialStatus), cfsqltype="cf_sql_varchar"},
                  is_featured: {value=(updateMode ? currentIsFeatured : false), cfsqltype="cf_sql_bit"},
                  published_at: {value=feedItem.published_at, cfsqltype="cf_sql_timestamp", null=(NOT isDate(feedItem.published_at))},
                  author_id: {value=targetAuthorId, cfsqltype="cf_sql_integer"},
                  content_type_id: {value=targetContentTypeId, cfsqltype="cf_sql_integer"},
                  category_id: {value=targetCategoryId, cfsqltype="cf_sql_integer", null=(targetCategoryId LTE 0)}
                };

                if (hasFeaturedMediaSupport) {
                    insertParams.featured_media_id = {value=featuredMediaId, cfsqltype="cf_sql_integer", null=(featuredMediaId LTE 0)};
                }

                try {
                    transaction {
                        if (updateMode) {
                            updateSql = "
                              UPDATE news.tb_content
                                 SET title = :title,
                                     excerpt = :excerpt,
                                     body_html = :body_html,
                                     " & (hasFeaturedMediaSupport ? "featured_media_id = :featured_media_id," : "") & "
                                     published_at = :published_at,
                                     author_id = :author_id,
                                     content_type_id = :content_type_id,
                                     category_id = :category_id,
                                     updated_at = now()
                               WHERE id = :id
                            ";
                            updateParams = duplicate(insertParams);
                            updateParams.id = {value=contentId, cfsqltype="cf_sql_integer"};
                            structDelete(updateParams, "slug");
                            structDelete(updateParams, "published");
                            structDelete(updateParams, "editorial_status");
                            structDelete(updateParams, "is_featured");
                            db.q(updateSql, updateParams);
                        } else {
                            insertResult = db.q(insertSql, insertParams);
                            contentId = extractGeneratedId(insertResult);

                            if (contentId LTE 0) {
                                cfthrow(message="Não foi possível obter o ID do conteúdo importado.");
                            }
                        }

                        syncContentTags(db, contentId, targetTagNames);

                        upsertContentImportRecord(
                            db = db,
                            importerKey = importerKey,
                            sourceName = sourceName,
                            sourceKey = sourceKey,
                            sourceUrl = feedItem.source_url,
                            sourceGuid = feedItem.source_guid,
                            sourceHash = sourceHash,
                            sourceAuthor = feedItem.source_author,
                            contentId = contentId,
                            detailData = {
                                source_url = feedItem.source_url,
                                source_guid = feedItem.source_guid,
                                source_author = feedItem.source_author,
                                source_pubdate = feedItem.published_at_raw,
                                source_published_at = isDate(feedItem.published_at) ? dateTimeFormat(feedItem.published_at, "yyyy-mm-dd HH:nn:ss") : "",
                                source_categories = feedItem.categories,
                                source_description_html = feedItem.description_html,
                                source_media_url = feedItem.media_url,
                                source_fingerprint = sourceHash,
                                source_fingerprint_version = sourceFingerprintVersion(),
                                local_author_name = targetAuthorName,
                                local_author_id = targetAuthorId,
                                default_responsible_editor_id = defaultResponsibleEditorId,
                                import_mode = importMode,
                                import_status = importStatus,
                                featured_media_downloaded = featuredMediaResult.success,
                                synced_at = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss")
                            },
                            existingImportId = existingImportId
                        );
                    }

                    try {
                        audit = createObject("component", "inc.audit");
                        audit.record(currentUserId, (updateMode ? "content.sync_update_" & feedImporterConfig.audit_suffix : "content.import_" & feedImporterConfig.audit_suffix), "news.tb_content", contentId, {
                            source_url = feedItem.source_url,
                            source_guid = feedItem.source_guid,
                            source_author = feedItem.source_author,
                            local_author_name = targetAuthorName,
                            local_author_id = targetAuthorId,
                            content_type_id = targetContentTypeId,
                            category_name = primaryCategoryName,
                            imported_status = importStatus,
                            source_hash = sourceHash
                        });
                    } catch (any auditError) {}

                    arrayAppend(results, {
                        title = feedItem.title,
                        action = (updateMode ? "Atualizado" : "Importado"),
                        message = (updateMode ? "Conteúdo atualizado porque a fonte mudou." : "Conteúdo criado com sucesso."),
                        source_url = feedItem.source_url,
                        source_media_url = feedItem.media_url,
                        featured_media_id = featuredMediaId,
                        media_status = (featuredMediaId GT 0 ? "linked" : (len(trim(feedItem.media_url)) ? "download_failed" : "not_provided")),
                        localized_body_images = (structKeyExists(bodyImportResult, "media_map") AND isStruct(bodyImportResult.media_map) ? structCount(bodyImportResult.media_map) : 0)
                    });
                    if (updateMode) {
                        summary.updated = summary.updated + 1;
                    } else {
                        summary.created = summary.created + 1;
                    }
                } catch (any itemError) {
                    arrayAppend(results, {
                        title = feedItem.title,
                        action = "Erro",
                        message = buildImportErrorMessage(itemError),
                        source_url = feedItem.source_url
                    });
                    summary.errors = summary.errors + 1;
                }
            }
            if (reimportMatched) break;
        }
        }

        if (reimportMode AND !reimportMatched) {
            cfthrow(message="O item solicitado não foi localizado na fonte de " & sourceName & ".");
        }

        pageAlertHtml = '<div class="alert alert-success border mb-4">'
            & '<strong>Importação concluída.</strong> '
            & 'Criados: ' & summary.created & ' | Atualizados: ' & summary.updated & ' | Ignorados: ' & summary.skipped & ' | Erros: ' & summary.errors & ' | Páginas lidas: ' & summary.pages
            & (len(rawFeedXml) ? ' | Origem: feed colado manualmente | Imagens locais enviadas: ' & manualFeedImagesUploaded : ' | Faixa executada: ' & startPage & ' até ' & maxPages)
            & '</div>';
    } catch (any e) {
        errorMessage = "Não foi possível concluir a importação.";
        if (structKeyExists(e, "message") AND len(trim(e.message & ""))) {
            errorMessage = e.message;
        }
        fatalErrorMessage = errorMessage;
        pageAlertHtml = '<div class="alert alert-danger border mb-4">'
            & encodeForHTML(errorMessage)
            & '</div>';
    }
}

resultRowsHtml = "";
resultsTableHtml = "";
for (resultItem in results) {
    resultBadgeClass = "editorial-status-badge--review";
    sourceUrlHtml = '<span class="text-body-secondary">-</span>';

    if (resultItem.action EQ "Importado" OR resultItem.action EQ "Atualizado") {
        resultBadgeClass = "editorial-status-badge--published";
    } else if (resultItem.action EQ "Ignorado") {
        resultBadgeClass = "editorial-status-badge--draft";
    }

    if (len(trim(resultItem.source_url))) {
        sourceUrlHtml = '<a href="' & encodeForHTMLAttribute(resultItem.source_url) & '" target="_blank" rel="noopener">Abrir fonte</a>';
    }

    resultRowsHtml &= '<tr>';
    resultRowsHtml &= '<td>' & encodeForHTML(resultItem.title) & '</td>';
    resultRowsHtml &= '<td><span class="badge ' & resultBadgeClass & '">' & encodeForHTML(resultItem.action) & '</span></td>';
    resultRowsHtml &= '<td>' & encodeForHTML(resultItem.message) & '</td>';
    resultRowsHtml &= '<td>' & sourceUrlHtml & '</td>';
    resultRowsHtml &= '</tr>';
}

if (importMode EQ "retroactive") {
    retroactiveSelected = " selected";
} else if (importMode EQ "latest") {
    latestSelected = " selected";
}

if (importStatus EQ "published") {
    publishedSelected = " selected";
} else if (importStatus EQ "draft") {
    draftSelected = " selected";
} else if (importStatus EQ "review") {
    reviewSelected = " selected";
}

if (downloadFeaturedMedia) {
    downloadFeaturedMediaChecked = " checked";
}

responsibleEditorOptionsHtml = '<option value="">Selecione um editor</option>';
for (local.editorIndex = 1; local.editorIndex <= editorsQ.recordCount; local.editorIndex = local.editorIndex + 1) {
    responsibleEditorOptionsHtml &= '<option value="' & editorsQ.id[local.editorIndex] & '"'
        & (defaultResponsibleEditorId EQ editorsQ.id[local.editorIndex] ? ' selected' : '')
        & '>' & encodeForHTML(editorsQ.name[local.editorIndex]) & '</option>';
}

if (arrayLen(results)) {
    resultsTableHtml = '
      <div class="card card-soft mt-4">
        <div class="card-body p-0">
          <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
              <thead class="table-light">
                <tr>
                  <th>Título</th>
                  <th>Ação</th>
                  <th>Mensagem</th>
                  <th>Fonte</th>
                </tr>
              </thead>
              <tbody>
                ' & resultRowsHtml & '
              </tbody>
            </table>
          </div>
        </div>
      </div>
    ';
}

if (isApiExecution) {
    request[responseKey] = {
        success = (len(trim(fatalErrorMessage)) EQ 0 AND summary.errors EQ 0),
        status = (len(trim(fatalErrorMessage)) ? "failed" : (summary.errors GT 0 ? "completed_with_errors" : "completed")),
        importer_key = importerKey,
        source_name = sourceName,
        importados = summary.created + summary.updated,
        duplicados = summary.skipped,
        erros = summary.errors,
        created = summary.created,
        updated = summary.updated,
        skipped = summary.skipped,
        processed = summary.processed,
        pages = summary.pages,
        fatal_error = fatalErrorMessage,
        results = results
    };
} else {
pageBody = '
  <div class="card card-soft">
    <div class="card-body p-4">
      <div class="admin-page-header mb-4">
        <div>
          <h2 class="h3 mb-2">Importador: ' & encodeForHTML(sourceName) & '</h2>
          <p class="text-body-secondary mb-0">Conector dedicado ao feed <code>' & encodeForHTML(feedUrl) & '</code>, com deduplicação por origem e varredura retroativa paginada.</p>
        </div>
        <div class="admin-page-actions">
          <a class="btn btn-outline-secondary" href="/admin/importers">Voltar para importadores</a>
        </div>
      </div>

      <div class="alert alert-light border mb-4">
        <div class="fw-semibold mb-2">Mapeamento automático atual</div>
        <div class="small text-body-secondary">
          ' & feedImporterConfig.mapping_description & '
        </div>
      </div>

      ' & pageAlertHtml & '

      <form method="post" action="' & encodeForHTMLAttribute(feedImporterConfig.admin_path) & '" enctype="multipart/form-data" class="vstack gap-4">
        ' & csrfField() & '
        <div class="row g-3">
          <div class="col-12 col-xl-4">
            <label class="form-label">Modo de importação</label>
            <select class="form-select" name="import_mode">
              <option value="retroactive"' & retroactiveSelected & '>Retroativo completo</option>
              <option value="latest"' & latestSelected & '>Apenas página atual do feed</option>
            </select>
            <div class="form-text">Padrão atual: apenas a página atual do feed.</div>
          </div>
          <div class="col-12 col-xl-4">
            <label class="form-label">Status ao importar</label>
            <select class="form-select" name="import_status">
              <option value="review"' & reviewSelected & '>Pendente de curadoria</option>
              <option value="published"' & publishedSelected & '>Publicado</option>
              <option value="draft"' & draftSelected & '>Rascunho</option>
            </select>
            <div class="form-text">Padrão: pendente de curadoria e invisível no portal público.</div>
          </div>
          <div class="col-12 col-xl-4">
            <label class="form-label">Limite de páginas</label>
            <input class="form-control" type="number" min="0" name="max_pages" value="' & maxPages & '">
            <div class="form-text">Use <code>0</code> para usar apenas a janela definida abaixo.</div>
          </div>
          <div class="col-12 col-xl-4">
            <label class="form-label">Página inicial</label>
            <input class="form-control" type="number" min="1" name="start_page" value="' & startPage & '">
            <div class="form-text">Para retroativo, comece em 1 e avance em blocos.</div>
          </div>
          <div class="col-12 col-xl-4">
            <label class="form-label">Páginas por execução</label>
            <input class="form-control" type="number" min="1" max="100" name="pages_per_run" value="' & pagesPerRun & '">
            <div class="form-text">Ajuda a evitar timeout em importações longas.</div>
          </div>
          <div class="col-12 col-xl-8">
            <label class="form-label">Editor responsável padrão para autores novos</label>
            <select class="form-select" name="default_responsible_editor_id"' & responsibleEditorDisabledAttr & '>
              ' & responsibleEditorOptionsHtml & '
            </select>
            <div class="form-text">' & encodeForHTML(responsibleEditorHelpText) & '</div>
          </div>
          <div class="col-12 col-xl-4">
            <label class="form-label d-block">Imagem de capa</label>
            <div class="form-check mt-2">
              <input class="form-check-input" type="checkbox" id="downloadFeaturedMediaField" name="download_featured_media" value="1"' & downloadFeaturedMediaChecked & '>
              <label class="form-check-label" for="downloadFeaturedMediaField">Baixar para a mídia local quando possível</label>
            </div>
          </div>
          <div class="col-12">
            <label class="form-label">Plano B: colar manualmente o RSS/XML do feed</label>
            <textarea class="form-control" name="raw_feed_xml" rows="12" placeholder="Cole aqui o conteúdo completo do feed RSS/XML quando o acesso remoto estiver bloqueado pela origem.">' & encodeForHTML(rawFeedXml) & '</textarea>
            <div class="form-text">Se este campo estiver preenchido, o importador ignora a busca remota do feed e passa a importar a partir do XML colado. O download das imagens continua remoto quando disponível.</div>
          </div>
          <div class="col-12">
            <label class="form-label">Plano B complementar: enviar imagens locais para evitar hotlinking</label>
            <input class="form-control" type="file" name="manual_feed_images" multiple accept="image/*">
            <div class="form-text">Envie aqui as imagens baixadas do conteúdo manual. O importador tenta associá-las automaticamente pelos nomes de arquivo das URLs encontradas no RSS colado, gravando tudo em <code>/public/uploads</code>.</div>
          </div>
        </div>

        <div class="d-flex flex-wrap gap-2">
          <button class="btn btn-primary" type="submit">Executar importação</button>
          <a class="btn btn-outline-secondary" href="/admin/importers">Cancelar</a>
        </div>
      </form>

      ' & resultsTableHtml & '
    </div>
  </div>
';
}
</cfscript>

<cfif NOT isApiExecution>
    <cfoutput>
    #renderLayout({
        title: feedImporterConfig.page_title,
        body: pageBody
    })#
    </cfoutput>
</cfif>

<cffunction name="renderLayout" returntype="string" output="false">
    <cfargument name="args" type="struct" required="true">
    <cfset request.layoutArgs = duplicate(arguments.args)>
    <cfsavecontent variable="html">
        <cfinclude template="/inc/layout.cfm">
    </cfsavecontent>
    <cfset structDelete(request, "layoutArgs")>
    <cfreturn html>
</cffunction>
