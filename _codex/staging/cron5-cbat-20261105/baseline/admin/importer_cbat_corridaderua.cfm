<cfscript>
isApiExecution = structKeyExists(request, "cbatImporterExecutionMode") AND request.cbatImporterExecutionMode EQ "api";
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

    if (!arrayLen(matches)) {
        return "";
    }

    return decodeHtmlEntities(reReplaceNoCase(matches[1], '^<media:content[^>]+url="([^"]+)".*$', "\1", "one"));
}

function extractFirstImageUrl(string htmlContent="") {
    var normalizedHtml = trim(arguments.htmlContent);
    var matches = "";

    if (!len(normalizedHtml)) {
        return "";
    }

    matches = reMatchNoCase('<img[^>]+src="([^"]+)"', normalizedHtml);
    if (!arrayLen(matches)) {
        return "";
    }

    return decodeHtmlEntities(reReplaceNoCase(matches[1], '^<img[^>]+src="([^"]+)".*$', "\1", "one"));
}

function normalizeComparableMediaUrl(string rawUrl="") {
    var normalizedUrl = trim(decodeHtmlEntities(arguments.rawUrl));

    if (!len(normalizedUrl)) {
        return "";
    }

    normalizedUrl = stripTrackingParams(normalizedUrl);
    return lCase(trim(normalizedUrl));
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

function processImportedBodyImages(required string htmlContent, required numeric authorId, required any db) {
    var result = {
        html = arguments.htmlContent,
        media_map = {}
    };
    var sourceHtml = arguments.htmlContent;
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

    imageMatches = reMatchNoCase('<img\b[^>]*\bsrc="([^"]+)"[^>]*>', sourceHtml);

    for (imageTag in imageMatches) {
        remoteUrl = reReplaceNoCase(imageTag, '^<img\b[^>]*\bsrc="([^"]+)".*$', "\1", "one");
        remoteUrl = decodeHtmlEntities(remoteUrl);
        normalizedRemoteUrl = trim(remoteUrl);
        mapKey = lCase(normalizedRemoteUrl);

        if (!len(normalizedRemoteUrl) OR !reFindNoCase("^https?://", normalizedRemoteUrl)) {
            continue;
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
    var formatter = "";
    var locale = "";

    if (!len(normalizedDate)) {
        return "";
    }

    try {
        locale = createObject("java", "java.util.Locale").ENGLISH;
        formatter = createObject("java", "java.text.SimpleDateFormat").init("EEE, dd MMM yyyy HH:mm:ss Z", locale);
        formatter.setLenient(true);
        return formatter.parse(normalizedDate);
    } catch (any parseError) {
        try {
            if (isDate(normalizedDate)) {
                return parseDateTime(normalizedDate);
            }
        } catch (any ignoredError) {}
    }

    return "";
}

function ensureContentImportTable(required any db) {
    // Avoid DDL on provisioned databases whose datasource restricts schema changes.
    if (!arguments.db.relationExists("news", "tb_content_imports")) {
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
    }

    // Avoid DDL on provisioned databases whose datasource restricts schema changes.
    if (!arguments.db.relationExists("news", "idx_tb_content_imports_unique_source")) {
      arguments.db.q("
        CREATE UNIQUE INDEX IF NOT EXISTS idx_tb_content_imports_unique_source
        ON news.tb_content_imports (importer_key, source_key)
      ");
    }

    // Avoid DDL on provisioned databases whose datasource restricts schema changes.
    if (!arguments.db.relationExists("news", "idx_tb_content_imports_content_id")) {
      arguments.db.q("
        CREATE INDEX IF NOT EXISTS idx_tb_content_imports_content_id
        ON news.tb_content_imports (content_id)
      ");
    }
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

function ensureAuthor(required any db, required any auth, required numeric operatorUserId, required string displayName, string fallbackEmail="") {
    var normalizedName = trim(arguments.displayName);
    var normalizedLookupName = normalizePersonName(normalizedName);
    var normalizedFallbackEmail = lCase(trim(arguments.fallbackEmail));
    var lookup = "";
    var emailLookup = "";
    var allUsers = "";
    var candidateName = "";
    var candidateUserId = 0;
    var insertResult = "";
    var salt = "";
    var passHash = "";
    var passwordSeed = createUUID() & createUUID() & "Aa1";
    var audit = "";

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

    if (!len(normalizedFallbackEmail)) {
        normalizedFallbackEmail = buildSlugBase(normalizedName) & ".import@runnerhub.local";
    }

    emailLookup = arguments.db.q("
      SELECT id
      FROM news.tb_users
      WHERE lower(email) = :email
      LIMIT 1
    ", {
      email: {value=normalizedFallbackEmail, cfsqltype="cf_sql_varchar"}
    });

    if (emailLookup.recordCount) {
        return val(emailLookup.id[1]);
    }

    salt = arguments.auth.generateSalt();
    passHash = arguments.auth.pbkdf2Hash(passwordSeed, salt);

    insertResult = arguments.db.q("
      INSERT INTO news.tb_users (email, display_name, pass_hash, salt, role, is_active)
      VALUES (:email, :display_name, :pass_hash, :salt, :role, :is_active)
      RETURNING id
    ", {
      email: {value=normalizedFallbackEmail, cfsqltype="cf_sql_varchar"},
      display_name: {value=normalizedName, cfsqltype="cf_sql_varchar"},
      pass_hash: {value=passHash, cfsqltype="cf_sql_varchar"},
      salt: {value=salt, cfsqltype="cf_sql_varchar"},
      role: {value="editor", cfsqltype="cf_sql_varchar"},
      is_active: {value=false, cfsqltype="cf_sql_bit"}
    });

    try {
        audit = createObject("component", "inc.audit");
        audit.record(arguments.operatorUserId, "user.create", "news.tb_users", extractGeneratedId(insertResult), {
            display_name = normalizedName,
            email = normalizedFallbackEmail,
            role = "editor",
            is_active = false,
            via = "cbat_corridaderua_importer"
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

function buildSourceHash(required struct itemData) {
    return hash(
        serializeJSON({
            source_id = itemData.source_id,
            title = itemData.title,
            source_url = itemData.source_url,
            published_at = itemData.published_at_raw,
            updated_at = itemData.updated_at_raw,
            categories = itemData.categories,
            excerpt = itemData.excerpt_text,
            body_html = itemData.body_html,
            media_url = itemData.media_url
        }, "struct", false),
        "SHA-256"
    );
}

function extractFirstMatch(required string sourceText, required string regexPattern, numeric groupIndex=1) {
    var matchData = reFindNoCase(arguments.regexPattern, arguments.sourceText, 1, true);
    var groupOffset = arguments.groupIndex + 1;

    if (
        isStruct(matchData)
        AND structKeyExists(matchData, "pos")
        AND arrayLen(matchData.pos) GTE groupOffset
        AND matchData.pos[groupOffset] GT 0
    ) {
        return mid(arguments.sourceText, matchData.pos[groupOffset], matchData.len[groupOffset]);
    }

    return "";
}

function parseBrazilianDate(required string rawValue) {
    var normalized = trim(arguments.rawValue);
    var parts = [];

    if (!reFind("^\d{2}/\d{2}/\d{4}$", normalized)) {
        return "";
    }

    parts = listToArray(normalized, "/");
    return createDateTime(val(parts[3]), val(parts[2]), val(parts[1]), 0, 0, 0);
}

function parseUnixTimestampValue(any rawValue="") {
    var timestampValue = val(arguments.rawValue);

    if (timestampValue LTE 0) {
        return "";
    }

    return dateAdd("s", timestampValue, createDateTime(1970, 1, 1, 0, 0, 0));
}

function buildCbatArticleUrl(required any sourceId, required string titleValue) {
    return "https://cbat.org.br/noticia/" & val(arguments.sourceId) & "/" & buildSlugBase(arguments.titleValue);
}

function parseCbatListItems(required struct payloadData) {
    var items = [];
    var rawItems = [];
    var rawItem = "";
    var itemData = {};
    var categoryName = "";

    if (structKeyExists(arguments.payloadData, "items") AND isArray(arguments.payloadData.items)) {
        rawItems = arguments.payloadData.items;
    }

    for (rawItem in rawItems) {
        categoryName = "";
        if (structKeyExists(rawItem, "idColuna") AND isStruct(rawItem.idColuna) AND structKeyExists(rawItem.idColuna, "nome")) {
            categoryName = decodeHtmlEntities(textOrFallback(rawItem.idColuna.nome, ""));
        }

        if (!len(categoryName)) {
            categoryName = "Corrida de Rua";
        }

        itemData = {
            source_id = val(rawItem.id ?: 0),
            title = decodeHtmlEntities(textOrFallback(rawItem.titulo ?: "", "")),
            source_url = buildCbatArticleUrl(rawItem.id ?: 0, textOrFallback(rawItem.titulo ?: "", "")),
            source_guid = "cbat-noticia-" & val(rawItem.id ?: 0),
            source_author = "CBAt",
            published_at_raw = textOrFallback(rawItem.created_at ?: "", ""),
            published_at = parseUnixTimestampValue(rawItem.created_at ?: 0),
            updated_at_raw = "",
            updated_at = "",
            excerpt_text = stripHtmlTags(textOrFallback(rawItem.resumo ?: "", "")),
            body_html = "",
            description_html = textOrFallback(rawItem.resumo ?: "", ""),
            media_url = stripTrackingParams(textOrFallback(rawItem.urlFotoCapa ?: "", "")),
            categories = [categoryName]
        };

        arrayAppend(items, itemData);
    }

    return items;
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

<cffunction name="fetchFeedPage" returntype="struct" output="false">
    <cfargument name="feedUrl" type="string" required="true">
    <cfargument name="pageNumber" type="numeric" required="true">
    <cfargument name="categoryId" type="numeric" required="true">
    <cfset var requestUrl = arguments.feedUrl
        & "?sort=-created_at"
        & "&expand=idColuna"
        & "&colunas=id,titulo,created_at,resumo,id_coluna,foto_capa,id_estabelecimento,flag_destaque,id_esporte"
        & "&page=" & arguments.pageNumber
        & "&id_coluna=" & arguments.categoryId>
    <cfset var httpResult = {}>
    <cfset var statusCode = 0>
    <cfset var statusMessage = "">
    <cfset var responseContent = "">
    <cfset var payloadData = {}>
    <cfset var totalPages = 0>

    <cfhttp url="#requestUrl#" method="get" result="httpResult" redirect="true" timeout="30" useragent="RoadRunnersPressImporter/1.0" />
    <cfset statusCode = val(listFirst(textOrFallback(httpResult.statusCode, "0"), " "))>
    <cfif structKeyExists(httpResult, "errorDetail") AND len(trim(httpResult.errorDetail & ""))>
        <cfset statusMessage = trim(httpResult.errorDetail & "")>
    <cfelseif structKeyExists(httpResult, "statusText") AND len(trim(httpResult.statusText & ""))>
        <cfset statusMessage = trim(httpResult.statusText & "")>
    <cfelseif structKeyExists(httpResult, "statusCode") AND len(trim(httpResult.statusCode & ""))>
        <cfset statusMessage = trim(httpResult.statusCode & "")>
    </cfif>

    <cfset responseContent = textOrFallback(httpResult.fileContent, "")>
    <cfif statusCode GTE 200 AND statusCode LT 300 AND isJSON(responseContent)>
        <cfset payloadData = deserializeJSON(responseContent)>
        <cfif structKeyExists(payloadData, "_meta") AND isStruct(payloadData._meta) AND structKeyExists(payloadData._meta, "page_count")>
            <cfset totalPages = val(payloadData._meta.page_count)>
        </cfif>
    </cfif>

    <cfreturn {
        success = statusCode GTE 200 AND statusCode LT 300,
        status_code = statusCode,
        url = requestUrl,
        content = responseContent,
        payload = payloadData,
        total_pages = totalPages,
        error_message = statusMessage
    }>
</cffunction>

<cffunction name="fetchArticleDetail" returntype="struct" output="false">
    <cfargument name="articleUrl" type="string" required="true">
    <cfargument name="fallbackCategory" type="string" required="false" default="Corrida de Rua">
    <cfargument name="fallbackMediaUrl" type="string" required="false" default="">
    <cfset var httpResult = {}>
    <cfset var statusCode = 0>
    <cfset var statusMessage = "">
    <cfset var htmlContent = "">
    <cfset var bodyHtml = "">
    <cfset var excerptHtml = "">
    <cfset var modifiedRaw = "">
    <cfset var categoryName = "">
    <cfset var mediaUrl = "">

    <cfhttp url="#arguments.articleUrl#" method="get" result="httpResult" redirect="true" timeout="30" useragent="RoadRunnersPressImporter/1.0" />
    <cfset statusCode = val(listFirst(textOrFallback(httpResult.statusCode, "0"), " "))>
    <cfif structKeyExists(httpResult, "errorDetail") AND len(trim(httpResult.errorDetail & ""))>
        <cfset statusMessage = trim(httpResult.errorDetail & "")>
    <cfelseif structKeyExists(httpResult, "statusText") AND len(trim(httpResult.statusText & ""))>
        <cfset statusMessage = trim(httpResult.statusText & "")>
    <cfelseif structKeyExists(httpResult, "statusCode") AND len(trim(httpResult.statusCode & ""))>
        <cfset statusMessage = trim(httpResult.statusCode & "")>
    </cfif>

    <cfset htmlContent = textOrFallback(httpResult.fileContent, "")>
    <cfif statusCode GTE 200 AND statusCode LT 300>
        <cfset excerptHtml = extractFirstMatch(htmlContent, '<div class="mt-6"><p class="text-lg">([\s\S]*?)</p></div>')>
        <cfset bodyHtml = extractFirstMatch(htmlContent, '<div class="noticia-corpo content">([\s\S]*?)</div></div><div></div><div class="space-y-2">')>
        <cfset modifiedRaw = extractFirstMatch(htmlContent, '<meta property="article:modified_time" content="([^"]*)"')>
        <cfset categoryName = decodeHtmlEntities(extractFirstMatch(htmlContent, '<p>categoria</p><p>([^<]+)</p>'))>
        <cfset mediaUrl = stripTrackingParams(extractFirstMatch(htmlContent, '<meta property="og:image" content="([^"]*)"'))>
    </cfif>

    <cfreturn {
        success = statusCode GTE 200 AND statusCode LT 300 AND len(trim(bodyHtml)),
        status_code = statusCode,
        url = arguments.articleUrl,
        error_message = statusMessage,
        excerpt_text = buildExcerptFromDescription(excerptHtml, bodyHtml),
        body_html = cleanupImportedBodyHtml(bodyHtml),
        updated_at_raw = modifiedRaw,
        updated_at = len(trim(modifiedRaw)) ? parseBrazilianDate(modifiedRaw) : "",
        media_url = len(trim(mediaUrl)) ? mediaUrl : arguments.fallbackMediaUrl,
        categories = [len(trim(categoryName)) ? categoryName : arguments.fallbackCategory]
    }>
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

    <cfif NOT len(normalizedMediaUrl)>
        <cfreturn { success = false, media_id = 0, url_public = "", message = "URL de mídia vazia." }>
    </cfif>

    <cfif NOT directoryExists(uploadDirectory)>
        <cfset directoryCreate(uploadDirectory)>
    </cfif>

    <cfhttp url="#normalizedMediaUrl#" method="get" path="#tempDirectory#" file="#tempFileName#" result="httpResult" redirect="true" timeout="45" useragent="RoadRunnersPressImporter/1.0" />
    <cfset statusCode = val(listFirst(textOrFallback(httpResult.statusCode, "0"), " "))>

    <cfif statusCode LT 200 OR statusCode GTE 300 OR NOT fileExists(tempFilePath)>
        <cfif fileExists(tempFilePath)>
            <cfset fileDelete(tempFilePath)>
        </cfif>
        <cfreturn {
            success = false,
            media_id = 0,
            url_public = "",
            message = "Não foi possível baixar a imagem de capa."
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

    <cfif structKeyExists(httpResult, "responseHeader") AND isStruct(httpResult.responseHeader) AND structKeyExists(httpResult.responseHeader, "Content-Type")>
        <cfset mimeType = trim(listFirst(httpResult.responseHeader["Content-Type"], ";"))>
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

<cfscript>
db = createObject("component", "inc.db");
auth = createObject("component", "inc.auth");
feedUrl = "https://cbat.org.br/noticias?categoria=corrida-de-rua";
feedApiUrl = "https://cbat.org.br/api/noticias";
fixedAuthorName = "CBAt";
fixedAuthorFallbackEmail = "cbat.import@runnerhub.local";
fixedContentTypeName = "CBAt";
fixedSourceName = "CBAt";
cbatCategoryId = 7;
currentUserId = structKeyExists(session, "user") AND structKeyExists(session.user, "id") ? val(session.user.id) : 0;
hasFeaturedMediaSupport = db.columnExists("news", "tb_content", "featured_media_id");

importMode = "latest";
importStatus = "review";
downloadFeaturedMedia = true;
maxPages = 0;
reimportContentId = val(structKeyExists(form, "reimport_content_id") ? form.reimport_content_id : 0);
reimportMode = reimportContentId GT 0;
reimportMatched = false;
reimportService = "";
reimportTarget = {};
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

        if (!listFindNoCase("retroactive,latest", importMode)) {
            cfthrow(message="Modo de importação inválido.");
        }

        if (!listFindNoCase("published,draft,review", importStatus)) {
            cfthrow(message="Status de importação inválido.");
        }

        ensureContentImportTable(db);
        if (reimportMode) {
            reimportService = createObject("component", "inc.content_reimport_service").init(db);
            reimportTarget = reimportService.loadTarget(reimportContentId);
            if (!reimportTarget.found OR !reimportTarget.supported OR reimportTarget.importerKey NEQ "cbat_corridaderua") {
                cfthrow(message="O conteúdo informado não pertence ao importador CBAt.");
            }
            importMode = "retroactive";
            maxPages = 1000;
        }
        targetAuthorId = ensureAuthor(db, auth, currentUserId, fixedAuthorName, fixedAuthorFallbackEmail);
        targetContentTypeId = ensureContentType(db, fixedContentTypeName);
        channelPublicationPolicyService = createObject("component","inc.channel_publication_policy");
        channelPublicationPolicy = channelPublicationPolicyService.load(targetContentTypeId);

        if (targetAuthorId LTE 0) {
            cfthrow(message="Não foi possível preparar o autor local fixo CBAt.");
        }

        if (targetContentTypeId LTE 0) {
            cfthrow(message="Não foi possível preparar o canal CBAt.");
        }

        if (importMode EQ "latest") {
            maxPages = 1;
        } else if (maxPages LTE 0) {
            maxPages = 1000;
        }

        importIsPublished = importStatus EQ "published";
        importEditorialStatus = importStatus EQ "review" ? "review" : "draft";
        if (importIsPublished) {
            importEditorialStatus = "published";
        }

        for (feedPage = 1; feedPage <= maxPages; feedPage = feedPage + 1) {
            pageFetch = fetchFeedPage(feedApiUrl, feedPage, cbatCategoryId);

            if (!pageFetch.success) {
                arrayAppend(results, {
                    title = "Página " & feedPage,
                    action = "Erro",
                    message = "Falha ao carregar a listagem da CBAt: " & textOrFallback(pageFetch.error_message, "HTTP " & pageFetch.status_code),
                    source_url = textOrFallback(pageFetch.url, feedUrl)
                });
                summary.errors = summary.errors + 1;
                break;
            }

            pageItems = parseCbatListItems(pageFetch.payload);

            if (!arrayLen(pageItems)) {
                break;
            }

            summary.pages = summary.pages + 1;

            if (importMode EQ "retroactive" AND pageFetch.total_pages GT 0 AND pageFetch.total_pages LT maxPages) {
                maxPages = pageFetch.total_pages;
            }

            for (feedItem in pageItems) {
                summary.processed = summary.processed + 1;

                if (reimportMode) {
                    candidateSourceKey = buildImportSourceKey(feedItem.source_guid, feedItem.source_url, feedItem.title, feedItem.published_at_raw);
                    if (!reimportService.matches(reimportTarget, candidateSourceKey, feedItem.source_url, feedItem.source_guid)) {
                        continue;
                    }
                    reimportMatched = true;
                }

                detailFetch = fetchArticleDetail(
                    articleUrl = feedItem.source_url,
                    fallbackCategory = (arrayLen(feedItem.categories) ? feedItem.categories[1] : "Corrida de Rua"),
                    fallbackMediaUrl = feedItem.media_url
                );

                if (!detailFetch.success) {
                    arrayAppend(results, {
                        title = textOrFallback(feedItem.title, "Sem título"),
                        action = "Erro",
                        message = "Falha ao carregar a notícia na CBAt: " & textOrFallback(detailFetch.error_message, "HTTP " & detailFetch.status_code),
                        source_url = textOrFallback(feedItem.source_url, "")
                    });
                    summary.errors = summary.errors + 1;
                    continue;
                }

                feedItem.excerpt_text = detailFetch.excerpt_text;
                feedItem.body_html = detailFetch.body_html;
                feedItem.updated_at_raw = detailFetch.updated_at_raw;
                feedItem.updated_at = detailFetch.updated_at;
                feedItem.media_url = detailFetch.media_url;
                feedItem.categories = detailFetch.categories;

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

                sourceKey = buildImportSourceKey(feedItem.source_guid, feedItem.source_url, feedItem.title, feedItem.published_at_raw);
                sourceHash = buildSourceHash(feedItem);
                existingImport = db.q("
                  SELECT i.id, i.content_id, i.source_hash, c.id AS existing_content_id,
                         COALESCE(c.published, false) AS existing_published,
                         COALESCE(c.editorial_status, CASE WHEN c.published THEN 'published' ELSE 'draft' END) AS existing_editorial_status
                  FROM news.tb_content_imports i
                  LEFT JOIN news.tb_content c ON c.id = i.content_id
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
                  importer_key: {value="cbat_corridaderua", cfsqltype="cf_sql_varchar"},
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

                        if (
                            NOT reimportMode
                            AND
                            len(previousSourceHash)
                            AND previousSourceHash EQ sourceHash
                            AND importStatus EQ "review"
                            AND NOT existingImport.existing_published[1]
                            AND lCase(textOrFallback(existingImport.existing_editorial_status[1], "draft")) EQ "draft"
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

                        if (NOT reimportMode AND len(previousSourceHash) AND previousSourceHash EQ sourceHash) {
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

                existingContentFallback = db.q("
                  SELECT id
                  FROM news.tb_content
                  WHERE author_id = :author_id
                    AND content_type_id = :content_type_id
                    AND title = :title
                    AND (
                      (:published_at_is_null = true AND published_at IS NULL)
                      OR published_at = :published_at
                    )
                  ORDER BY id DESC
                  LIMIT 1
                ", {
                  author_id: {value=targetAuthorId, cfsqltype="cf_sql_integer"},
                  content_type_id: {value=targetContentTypeId, cfsqltype="cf_sql_integer"},
                  title: {value=feedItem.title, cfsqltype="cf_sql_varchar"},
                  published_at_is_null: {value=(NOT isDate(feedItem.published_at)), cfsqltype="cf_sql_bit"},
                  published_at: {value=feedItem.published_at, cfsqltype="cf_sql_timestamp", null=(NOT isDate(feedItem.published_at))}
                });

                if (existingContentFallback.recordCount) {
                    contentId = val(existingContentFallback.id[1]);

                    try {
                        upsertContentImportRecord(
                            db = db,
                            importerKey = "cbat_corridaderua",
                            sourceName = fixedSourceName,
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
                                source_updated_at = feedItem.updated_at_raw,
                                source_categories = feedItem.categories,
                                source_description_html = feedItem.description_html,
                                source_media_url = feedItem.media_url,
                                import_mode = importMode,
                                import_status = importStatus,
                                dedupe_repaired = true
                            }
                        );
                    } catch (any ignoredRepairError) {}

                    arrayAppend(results, {
                        title = feedItem.title,
                        action = "Ignorado",
                        message = "Conteúdo já existia na plataforma. O vínculo de importação foi reaproveitado.",
                        source_url = feedItem.source_url
                    });
                    summary.skipped = summary.skipped + 1;
                    continue;
                }

                primaryCategoryName = arrayLen(feedItem.categories) ? feedItem.categories[1] : "";
                targetCategoryId = ensureCategory(db, primaryCategoryName);
                targetTagNames = feedItem.categories;
                featuredMediaId = 0;
                featuredMediaResult = { success = false, media_id = 0, url_public = "", message = "" };
                contentId = 0;
                existingImportId = 0;
                updateMode = false;
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
                sourceUpdatedAt = isDate(feedItem.updated_at) ? feedItem.updated_at : feedItem.published_at;

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

                bodyImportResult = channelPublicationPolicy.sourceMediaAllowed ? processImportedBodyImages(feedItem.body_html, targetAuthorId, db) : {html=channelPublicationPolicyService.sanitizeImportedHtml(feedItem.body_html,channelPublicationPolicy),media_map={}};
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
                    & "published_at, updated_at, author_id, content_type_id, category_id
                  )
                  VALUES (
                    :slug, :title, :excerpt, :body_html, :published, :editorial_status, :is_featured, "
                    & featuredMediaInsertValueSql
                    & ":published_at, :updated_at, :author_id, :content_type_id, :category_id
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
                  updated_at: {value=sourceUpdatedAt, cfsqltype="cf_sql_timestamp", null=(NOT isDate(sourceUpdatedAt))},
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
                                     updated_at = :updated_at,
                                     author_id = :author_id,
                                     content_type_id = :content_type_id,
                                     category_id = :category_id
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
                            importerKey = "cbat_corridaderua",
                            sourceName = fixedSourceName,
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
                                source_updated_at = feedItem.updated_at_raw,
                                source_categories = feedItem.categories,
                                source_description_html = feedItem.description_html,
                                source_media_url = feedItem.media_url,
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
                        audit.record(currentUserId, (updateMode ? "content.sync_update_cbat_corridaderua" : "content.import_cbat_corridaderua"), "news.tb_content", contentId, {
                            source_url = feedItem.source_url,
                            source_guid = feedItem.source_guid,
                            source_author = feedItem.source_author,
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
                        source_url = feedItem.source_url
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

        if (reimportMode AND !reimportMatched) {
            cfthrow(message="O item solicitado não foi localizado na fonte da CBAt.");
        }

        pageAlertHtml = '<div class="alert alert-success border mb-4">'
            & '<strong>Importação concluída.</strong> '
            & 'Criados: ' & summary.created & ' | Atualizados: ' & summary.updated & ' | Ignorados: ' & summary.skipped & ' | Erros: ' & summary.errors & ' | Páginas lidas: ' & summary.pages
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
    request.cbatImporterResponse = {
        success = (len(trim(fatalErrorMessage)) EQ 0 AND summary.errors EQ 0),
        status = (len(trim(fatalErrorMessage)) ? "failed" : (summary.errors GT 0 ? "completed_with_errors" : "completed")),
        importer_key = "cbat_corridaderua",
        source_name = fixedSourceName,
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
          <h2 class="h3 mb-2">Importador: CBAt Corrida de Rua</h2>
          <p class="text-body-secondary mb-0">Conector dedicado à listagem <code>' & encodeForHTML(feedUrl) & '</code>, com coleta via API pública da CBAt, deduplicação por origem e varredura retroativa paginada.</p>
        </div>
        <div class="admin-page-actions">
          <a class="btn btn-outline-secondary" href="/admin/importers">Voltar para importadores</a>
        </div>
      </div>

      <div class="alert alert-light border mb-4">
        <div class="fw-semibold mb-2">Mapeamento automático atual</div>
        <div class="small text-body-secondary">
          Autor local fixo: <strong>CBAt</strong>. Canal local fixo: <strong>CBAt</strong>. A categoria <strong>Corrida de Rua</strong> entra como categoria principal e também como tag para preservar o contexto editorial. A data da API da CBAt é gravada como publicação, e a data <code>article:modified_time</code> da página é gravada como atualização quando disponível. A capa usa <code>og:image</code> da notícia. A origem, GUID, autor de origem e metadados da página ficam registrados para deduplicação, auditoria e sincronização futura.
        </div>
      </div>

      ' & pageAlertHtml & '

      <form method="post" action="/admin/importer_cbat_corridaderua" class="vstack gap-4">
        ' & csrfField() & '
        <div class="row g-3">
          <div class="col-12 col-xl-4">
            <label class="form-label">Modo de importação</label>
            <select class="form-select" name="import_mode">
              <option value="retroactive"' & retroactiveSelected & '>Retroativo completo</option>
              <option value="latest"' & latestSelected & '>Apenas página atual da listagem</option>
            </select>
            <div class="form-text">Padrão atual: apenas a página atual da listagem da CBAt.</div>
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
            <div class="form-text">Use <code>0</code> para varrer tudo no modo retroativo, respeitando o total de páginas informado pela API da CBAt, com proteção interna de até 1000 páginas.</div>
          </div>
          <div class="col-12 col-xl-8">
            <label class="form-label d-block">Imagem de capa</label>
            <div class="form-check mt-2">
              <input class="form-check-input" type="checkbox" id="downloadFeaturedMediaField" name="download_featured_media" value="1"' & downloadFeaturedMediaChecked & '>
              <label class="form-check-label" for="downloadFeaturedMediaField">Baixar para a mídia local quando possível</label>
            </div>
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
        title: "Importador CBAt Corrida de Rua",
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
