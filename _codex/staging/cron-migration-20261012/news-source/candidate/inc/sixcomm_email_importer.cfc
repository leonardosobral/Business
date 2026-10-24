component output="false" {

  variables.importerKey = "sixcomm_email";
  variables.sourceName = "SixComm";
  variables.expectedSender = "danilo@gruposix.com.br";
  variables.expectedMailbox = "contato@runnerhub.run";
  variables.contentTypeId = 5;
  variables.authorId = 8;
  variables.categoryId = 3;
  variables.galleryStartMarker = "<!-- ROADRUNNERS_GALLERY_START -->";
  variables.galleryEndMarker = "<!-- ROADRUNNERS_GALLERY_END -->";

  public any function init(
    any database,
    string uploadDirectory = "",
    string uploadBaseUrl = "",
    boolean skipTransactions = false
  ) {
    if (structKeyExists(arguments, "database")) variables.database = arguments.database;
    if (len(arguments.uploadDirectory)) variables.uploadDirectory = arguments.uploadDirectory;
    if (len(arguments.uploadBaseUrl)) variables.uploadBaseUrl = arguments.uploadBaseUrl;
    variables.skipTransactions = arguments.skipTransactions;
    return this;
  }

  public struct function importMessages(
    required query messages,
    required string attachmentDirectory,
    string allowedImageHosts = "s3.us-east-1.wasabisys.com",
    numeric reimportContentId = 0
  ) {
    var db = structKeyExists(variables, "database") ? variables.database : createObject("component", "inc.db");
    var summary = {
      success = true,
      status = "completed",
      importer_key = variables.importerKey,
      source_name = variables.sourceName,
      processed = 0,
      created = 0,
      updated = 0,
      skipped = 0,
      ignored = 0,
      errors = 0,
      importados = 0,
      duplicados = 0,
      erros = 0,
      results = []
    };
    var rowIndex = 0;
    var messageData = {};
    var result = {};

    variables.workingDirectory = arguments.attachmentDirectory;

    ensureImportTable(db);
    validateEditorialMappings(db);

    for (rowIndex = 1; rowIndex <= arguments.messages.recordCount; rowIndex = rowIndex + 1) {
      summary.processed = summary.processed + 1;
      variables.createdFiles = [];
      try {
        if (extractEmailAddress(queryValue(arguments.messages, rowIndex, "from")) NEQ variables.expectedSender) {
          summary.ignored = summary.ignored + 1;
          continue;
        }
        messageData = buildMessageData(arguments.messages, rowIndex);
        if (variables.skipTransactions ?: false) {
          result = importMessage(
            db = db,
            messageData = messageData,
            attachmentDirectory = arguments.attachmentDirectory,
            allowedImageHosts = arguments.allowedImageHosts,
            reimportContentId = arguments.reimportContentId
          );
        } else {
          transaction {
            result = importMessage(
              db = db,
              messageData = messageData,
              attachmentDirectory = arguments.attachmentDirectory,
              allowedImageHosts = arguments.allowedImageHosts,
              reimportContentId = arguments.reimportContentId
            );
          }
        }

        arrayAppend(summary.results, result);
        if (result.action EQ "Criado") {
          summary.created = summary.created + 1;
        } else if (result.action EQ "Atualizado") {
          summary.updated = summary.updated + 1;
        } else if (result.action EQ "Ignorado") {
          summary.ignored = summary.ignored + 1;
        } else {
          summary.skipped = summary.skipped + 1;
        }
      } catch (any messageError) {
        for (var createdFile in variables.createdFiles) {
          if (fileExists(createdFile)) {
            try { fileDelete(createdFile); } catch (any ignoredCleanupError) {}
          }
        }
        summary.errors = summary.errors + 1;
        arrayAppend(summary.results, {
          title = textOrFallback(queryValue(arguments.messages, rowIndex, "subject"), "Sem assunto"),
          action = "Erro",
          error_code = messageError.type ?: "processing_error",
          message = left(messageError.type ?: "", 8) EQ "SixComm." ? messageError.message : "Falha ao processar o e-mail. Verifique banco, imagens e permissões de gravação.",
          message_id = textOrFallback(queryValue(arguments.messages, rowIndex, "messageid"), "")
        });
      }
    }

    summary.importados = summary.created + summary.updated;
    summary.duplicados = summary.skipped;
    summary.erros = summary.errors;
    summary.success = summary.errors EQ 0;
    summary.status = summary.success ? "completed" : "completed_with_errors";
    return summary;
  }

  private struct function importMessage(
    required any db,
    required struct messageData,
    required string attachmentDirectory,
    required string allowedImageHosts,
    numeric reimportContentId = 0
  ) {
    var sourceKey = "";
    var existingImport = "";
    var parsedContent = {};
    var imageSources = [];
    var storedMedia = [];
    var sourceItem = {};
    var mediaResult = {};
    var featuredMediaId = 0;
    var galleryItems = [];
    var galleryHtml = "";
    var bodyHtml = "";
    var contentSlug = "";
    var insertResult = "";
    var contentId = 0;
    var updateMode = false;
    var currentContent = "";
    var sourceHash = "";
    var detailData = {};
    var audit = "";
    var rowIndex = 0;
    var channelPublicationPolicyService = createObject("component","inc.channel_publication_policy");
    var channelPublicationPolicy = channelPublicationPolicyService.load(variables.contentTypeId);

    if (arguments.messageData.senderEmail NEQ variables.expectedSender) {
      return {
        title = textOrFallback(arguments.messageData.subject, "Sem assunto"),
        action = "Ignorado",
        message = "Remetente fora da regra SixComm.",
        message_id = arguments.messageData.messageId
      };
    }

    if (!arguments.messageData.deliveredToExpectedMailbox) {
      return {
        title = textOrFallback(arguments.messageData.subject, "Sem assunto"),
        action = "Ignorado",
        message = "A mensagem não foi entregue à caixa configurada para a importação.",
        message_id = arguments.messageData.messageId
      };
    }

    if (!arguments.messageData.dkimAuthenticated) {
      throw(type="SixComm.Authentication", message="A mensagem não possui resultado DKIM válido do Gmail para gruposix.com.br.");
    }

    if (!len(arguments.messageData.subject)) {
      throw(type="SixComm.InvalidMessage", message="O e-mail não possui assunto utilizável como título.");
    }
    if (!isDate(arguments.messageData.receivedAt)) {
      throw(type="SixComm.InvalidDate", message="Não foi possível determinar a data de recebimento do e-mail.");
    }

    sourceKey = buildSourceKey(arguments.messageData);
    existingImport = arguments.db.q("
      SELECT id, content_id
      FROM news.tb_content_imports
      WHERE importer_key = :importer_key
        AND source_key = :source_key
      LIMIT 1
    ", {
      importer_key: {value=variables.importerKey, cfsqltype="cf_sql_varchar"},
      source_key: {value=sourceKey, cfsqltype="cf_sql_varchar"}
    });

    if (existingImport.recordCount AND arguments.reimportContentId LTE 0) {
      return {
        title = arguments.messageData.subject,
        action = "Duplicado",
        message = "E-mail já importado anteriormente.",
        message_id = arguments.messageData.messageId,
        content_id = val(existingImport.content_id[1] ?: 0)
      };
    }
    if (arguments.reimportContentId GT 0) {
      if (!existingImport.recordCount OR val(existingImport.content_id[1] ?: 0) NEQ arguments.reimportContentId) {
        throw(type="SixComm.ReimportMismatch", message="O Message-ID localizado não corresponde ao conteúdo solicitado.");
      }
      updateMode = true;
      contentId = arguments.reimportContentId;
      currentContent = arguments.db.q("
        SELECT slug, COALESCE(featured_media_id, 0) AS featured_media_id
        FROM news.tb_content
        WHERE id = :id
        LIMIT 1
      ", {
        id: {value=contentId, cfsqltype="cf_sql_integer"}
      });
      if (!currentContent.recordCount) {
        throw(type="SixComm.ReimportMissing", message="O conteúdo vinculado à mensagem não foi encontrado.");
      }
    }

    parsedContent = parseEditorialContent(arguments.messageData);
    if (!len(parsedContent.bodyHtml)) {
      throw(type="SixComm.InvalidMessage", message="O e-mail não possui corpo editorial utilizável.");
    }

    imageSources = channelPublicationPolicy.sourceMediaAllowed
      ? extractEditorialImageSources(
          htmlBody = arguments.messageData.htmlBody,
          attachmentFiles = arguments.messageData.attachmentFiles,
          attachmentDirectory = arguments.attachmentDirectory
        )
      : [];

    for (sourceItem in imageSources) {
      if (sourceItem.type EQ "remote") {
        mediaResult = storeRemoteImage(
          db = arguments.db,
          sourceUrl = sourceItem.value,
          allowedImageHosts = arguments.allowedImageHosts
        );
      } else {
        mediaResult = storeLocalImage(
          db = arguments.db,
          sourcePath = sourceItem.value,
          originalName = sourceItem.name
        );
      }

      if (!mediaResult.success) {
        throw(type="SixComm.Image", message=mediaResult.message);
      }
      arrayAppend(storedMedia, mediaResult);
    }

    if (arrayLen(storedMedia)) {
      featuredMediaId = val(storedMedia[1].media_id);
    }

    if (arrayLen(storedMedia) GT 1) {
      for (rowIndex = 2; rowIndex <= arrayLen(storedMedia); rowIndex = rowIndex + 1) {
        arrayAppend(galleryItems, {
          url = storedMedia[rowIndex].url_public,
          name = storedMedia[rowIndex].original_name,
          caption = ""
        });
      }
    }

    galleryHtml = buildManagedGalleryHtml(galleryItems);
    bodyHtml = channelPublicationPolicyService.sanitizeImportedHtml(parsedContent.bodyHtml,channelPublicationPolicy);
    if (len(galleryHtml)) {
      bodyHtml &= chr(10) & galleryHtml;
    }

    contentSlug = updateMode ? currentContent.slug[1] : buildUniqueSlug(arguments.db, arguments.messageData.subject);
    if (updateMode AND featuredMediaId LTE 0) {
      featuredMediaId = val(currentContent.featured_media_id[1] ?: 0);
    }
    sourceHash = hash(
      arguments.messageData.subject & "|" &
      dateTimeFormat(arguments.messageData.receivedAt, "yyyy-mm-dd HH:nn:ss") & "|" &
      parsedContent.excerpt & "|" & parsedContent.bodyHtml,
      "SHA-256"
    );

    if (updateMode) {
      arguments.db.q("
        UPDATE news.tb_content
        SET title = :title,
            excerpt = :excerpt,
            body_html = :body_html,
            featured_media_id = :featured_media_id,
            published_at = :published_at,
            author_id = :author_id,
            content_type_id = :content_type_id,
            category_id = :category_id,
            updated_at = now()
        WHERE id = :id
      ", {
        title: {value=arguments.messageData.subject, cfsqltype="cf_sql_varchar"},
        excerpt: {value=parsedContent.excerpt, cfsqltype="cf_sql_longvarchar", null=!len(parsedContent.excerpt)},
        body_html: {value=bodyHtml, cfsqltype="cf_sql_longvarchar"},
        featured_media_id: {value=featuredMediaId, cfsqltype="cf_sql_integer", null=featuredMediaId LTE 0},
        published_at: {value=arguments.messageData.receivedAt, cfsqltype="cf_sql_timestamp"},
        author_id: {value=variables.authorId, cfsqltype="cf_sql_integer"},
        content_type_id: {value=variables.contentTypeId, cfsqltype="cf_sql_integer"},
        category_id: {value=variables.categoryId, cfsqltype="cf_sql_integer"},
        id: {value=contentId, cfsqltype="cf_sql_integer"}
      });
    } else {
      insertResult = arguments.db.q("
        INSERT INTO news.tb_content (
          slug, title, excerpt, body_html, published, editorial_status,
          is_featured, featured_media_id, published_at,
          author_id, content_type_id, category_id
        )
        VALUES (
          :slug, :title, :excerpt, :body_html, false, 'review',
          false, :featured_media_id, :published_at,
          :author_id, :content_type_id, :category_id
        )
        RETURNING id
      ", {
        slug: {value=contentSlug, cfsqltype="cf_sql_varchar"},
        title: {value=arguments.messageData.subject, cfsqltype="cf_sql_varchar"},
        excerpt: {value=parsedContent.excerpt, cfsqltype="cf_sql_longvarchar", null=!len(parsedContent.excerpt)},
        body_html: {value=bodyHtml, cfsqltype="cf_sql_longvarchar"},
        featured_media_id: {value=featuredMediaId, cfsqltype="cf_sql_integer", null=featuredMediaId LTE 0},
        published_at: {value=arguments.messageData.receivedAt, cfsqltype="cf_sql_timestamp"},
        author_id: {value=variables.authorId, cfsqltype="cf_sql_integer"},
        content_type_id: {value=variables.contentTypeId, cfsqltype="cf_sql_integer"},
        category_id: {value=variables.categoryId, cfsqltype="cf_sql_integer"}
      });
      contentId = extractGeneratedId(insertResult);

      if (contentId LTE 0) {
        throw(message="Não foi possível obter o ID do conteúdo importado.");
      }
    }

      detailData = {
        message_id = arguments.messageData.messageId,
        sender = arguments.messageData.senderEmail,
        mailbox = variables.expectedMailbox,
        received_at = dateTimeFormat(arguments.messageData.receivedAt, "yyyy-mm-dd HH:nn:ss"),
        source_published_at = dateTimeFormat(arguments.messageData.receivedAt, "yyyy-mm-dd HH:nn:ss"),
        image_count = arrayLen(storedMedia),
        featured_media_id = featuredMediaId,
        editorial_status = "review"
      };

    if (updateMode) {
      arguments.db.q("
        UPDATE news.tb_content_imports
        SET source_hash = :source_hash,
            source_author = :source_author,
            detail_json = CAST(:detail_json AS JSONB),
            updated_at = now()
        WHERE id = :id
      ", {
        source_hash: {value=sourceHash, cfsqltype="cf_sql_varchar"},
        source_author: {value=arguments.messageData.senderEmail, cfsqltype="cf_sql_varchar"},
        detail_json: {value=serializeJSON(detailData, "struct", false), cfsqltype="cf_sql_longvarchar"},
        id: {value=existingImport.id[1], cfsqltype="cf_sql_integer"}
      });
    } else {
      arguments.db.q("
        INSERT INTO news.tb_content_imports (
          importer_key, source_name, source_key, source_url, source_guid,
          source_hash, source_author, content_id, detail_json
        )
        VALUES (
          :importer_key, :source_name, :source_key, NULL, :source_guid,
          :source_hash, :source_author, :content_id, CAST(:detail_json AS JSONB)
        )
      ", {
        importer_key: {value=variables.importerKey, cfsqltype="cf_sql_varchar"},
        source_name: {value=variables.sourceName, cfsqltype="cf_sql_varchar"},
        source_key: {value=sourceKey, cfsqltype="cf_sql_varchar"},
        source_guid: {value=arguments.messageData.messageId, cfsqltype="cf_sql_varchar"},
        source_hash: {value=sourceHash, cfsqltype="cf_sql_varchar"},
        source_author: {value=arguments.messageData.senderEmail, cfsqltype="cf_sql_varchar"},
        content_id: {value=contentId, cfsqltype="cf_sql_integer"},
        detail_json: {value=serializeJSON(detailData, "struct", false), cfsqltype="cf_sql_longvarchar"}
      });
    }

    try {
      audit = createObject("component", "inc.audit");
      audit.record(variables.authorId, (updateMode ? "content.sync_update_sixcomm_email" : "content.import_sixcomm_email"), "news.tb_content", contentId, detailData);
    } catch (any ignoredAuditError) {}

    return {
      title = arguments.messageData.subject,
      action = (updateMode ? "Atualizado" : "Criado"),
      message = (updateMode ? "Conteúdo atualizado a partir do e-mail original." : "Conteúdo enviado para a curadoria."),
      message_id = arguments.messageData.messageId,
      content_id = contentId,
      images = arrayLen(storedMedia),
      published_at = dateTimeFormat(arguments.messageData.receivedAt, "yyyy-mm-dd HH:nn:ss")
    };
  }

  public struct function buildMessageData(required query messages, required numeric rowIndex) {
    var rawHeaders = textOrFallback(queryValue(arguments.messages, arguments.rowIndex, "header"), "");
    var rawFrom = textOrFallback(queryValue(arguments.messages, arguments.rowIndex, "from"), "");
    var htmlBody = textOrFallback(queryValue(arguments.messages, arguments.rowIndex, "htmlbody"), "");
    var textBody = textOrFallback(queryValue(arguments.messages, arguments.rowIndex, "textbody"), "");
    var fallbackBody = textOrFallback(queryValue(arguments.messages, arguments.rowIndex, "body"), "");
    var messageDate = queryValue(arguments.messages, arguments.rowIndex, "date");
    var messageId = normalizeMessageId(textOrFallback(queryValue(arguments.messages, arguments.rowIndex, "messageid"), ""));

    if (!len(htmlBody) AND findNoCase("<", fallbackBody)) {
      htmlBody = fallbackBody;
    }
    if (!len(textBody) AND !len(htmlBody)) {
      textBody = fallbackBody;
    }
    if (!len(messageId)) throw(type="SixComm.InvalidMessage", message="O e-mail não possui Message-ID; importação recusada para evitar duplicatas.");

    return {
      subject = normalizeWhitespace(textOrFallback(queryValue(arguments.messages, arguments.rowIndex, "subject"), "")),
      senderEmail = extractEmailAddress(rawFrom),
      messageId = messageId,
      headers = rawHeaders,
      htmlBody = htmlBody,
      textBody = textBody,
      attachmentFiles = textOrFallback(queryValue(arguments.messages, arguments.rowIndex, "attachmentfiles"), ""),
      receivedAt = parseReceivedAt(rawHeaders),
      deliveredToExpectedMailbox = headerContainsMailbox(rawHeaders, variables.expectedMailbox),
      dkimAuthenticated = hasValidSenderAuthentication(rawHeaders)
    };
  }

  public boolean function isMessageImported(required string messageId, required any db) {
    var normalizedId = normalizeMessageId(arguments.messageId);
    var sourceKey = "";
    var lookup = "";
    if (!len(normalizedId)) {
      return false;
    }
    sourceKey = hash("message-id|" & normalizedId, "SHA-256");
    lookup = arguments.db.q("
      SELECT 1
      FROM news.tb_content_imports
      WHERE importer_key = :importer_key
        AND source_key = :source_key
      LIMIT 1
    ", {
      importer_key: {value=variables.importerKey, cfsqltype="cf_sql_varchar"},
      source_key: {value=sourceKey, cfsqltype="cf_sql_varchar"}
    });
    return lookup.recordCount GT 0;
  }

  public struct function parseEditorialContent(required struct messageData) {
    var paragraphs = [];
    var paragraphBlocks = [];
    var paragraphBlock = "";
    var paragraphText = "";
    var normalizedTitle = normalizeComparison(arguments.messageData.subject);
    var titleSkipped = false;
    var excerpt = "";
    var bodyParagraphs = [];
    var textLines = [];
    var textLine = "";
    var bodyHtml = "";
    var item = "";

    if (len(arguments.messageData.htmlBody)) {
      paragraphBlocks = reMatchNoCase("<p\b[^>]*>[\s\S]*?</p>", arguments.messageData.htmlBody);
      for (paragraphBlock in paragraphBlocks) {
        paragraphText = htmlFragmentToText(paragraphBlock);
        if (len(paragraphText)) {
          arrayAppend(paragraphs, paragraphText);
        }
      }
    }

    if (!arrayLen(paragraphs) AND len(arguments.messageData.textBody)) {
      textLines = listToArray(reReplace(arguments.messageData.textBody, "\r?\n(?:[ \t]*\r?\n)+", chr(30), "all"), chr(30));
      for (textLine in textLines) {
        paragraphText = normalizeWhitespace(textLine);
        if (len(paragraphText)) {
          arrayAppend(paragraphs, paragraphText);
        }
      }
    }

    for (item in paragraphs) {
      if (isFooterParagraph(item)) {
        break;
      }
      if (!titleSkipped AND normalizeComparison(item) EQ normalizedTitle) {
        titleSkipped = true;
        continue;
      }
      if (!len(excerpt)) {
        excerpt = item;
        continue;
      }
      arrayAppend(bodyParagraphs, item);
    }

    if (!arrayLen(bodyParagraphs) AND len(excerpt)) {
      arrayAppend(bodyParagraphs, excerpt);
      excerpt = "";
    }

    for (item in bodyParagraphs) {
      bodyHtml &= '<p>' & encodeForHTML(item) & '</p>' & chr(10);
    }

    return {
      excerpt = left(excerpt, 2000),
      bodyHtml = trim(bodyHtml)
    };
  }

  public array function extractEditorialImageSources(
    string htmlBody = "",
    string attachmentFiles = "",
    required string attachmentDirectory
  ) {
    var results = [];
    var seen = {};
    var editorialHtml = arguments.htmlBody;
    var imageTags = [];
    var imageTag = "";
    var imageUrl = "";
    var attachmentNames = [];
    var attachmentName = "";
    var attachmentPath = "";
    var normalizedKey = "";

    imageTags = reMatchNoCase("<img\b[^>]*>", editorialHtml);
    for (imageTag in imageTags) {
      imageUrl = extractImageSource(imageTag);
      normalizedKey = lCase(trim(imageUrl));
      if (!len(normalizedKey) OR structKeyExists(seen, normalizedKey) OR isDecorativeImage(imageTag, imageUrl)) {
        continue;
      }
      if (reFindNoCase("^https?://", imageUrl)) {
        seen[normalizedKey] = true;
        arrayAppend(results, {type="remote", value=imageUrl, name=fileNameFromUrl(imageUrl)});
      }
    }

    attachmentNames = splitAttachmentFiles(arguments.attachmentFiles);
    for (attachmentName in attachmentNames) {
      attachmentPath = attachmentName;
      if (!fileExists(attachmentPath)) {
        attachmentPath = arguments.attachmentDirectory & "/" & attachmentName;
      }
      var canonicalRoot = createObject("java", "java.io.File").init(arguments.attachmentDirectory).getCanonicalPath() & "/";
      var canonicalFile = createObject("java", "java.io.File").init(attachmentPath).getCanonicalPath();
      if (left(canonicalFile, len(canonicalRoot)) NEQ canonicalRoot) {
        throw(type="SixComm.InvalidImage", message="Caminho de anexo inválido.");
      }
      normalizedKey = lCase(getFileFromPath(attachmentPath));
      if (!fileExists(attachmentPath) OR structKeyExists(seen, normalizedKey) OR !isSupportedImageFile(attachmentPath)) {
        continue;
      }
      seen[normalizedKey] = true;
      arrayAppend(results, {type="local", value=attachmentPath, name=getFileFromPath(attachmentPath)});
    }

    if (arrayLen(results) GT 20) throw(type="SixComm.ImageLimit", message="O e-mail excede o limite de 20 fotos.");
    return results;
  }

  private struct function storeRemoteImage(
    required any db,
    required string sourceUrl,
    required string allowedImageHosts
  ) {
    var validation = validateRemoteImageUrl(arguments.sourceUrl, arguments.allowedImageHosts);
    var tempDirectory = structKeyExists(variables, "workingDirectory") AND len(variables.workingDirectory)
      ? variables.workingDirectory & "/"
      : getTempDirectory();
    var tempFileName = createUUID() & ".bin";
    var tempFilePath = tempDirectory & tempFileName;
    var httpResult = {};
    var statusCode = 0;
    var mimeType = "application/octet-stream";
    var originalName = fileNameFromUrl(arguments.sourceUrl);
    var extension = "";

    if (!validation.success) {
      return validation;
    }

    try {
      cfhttp(
        url=arguments.sourceUrl,
        method="get",
        path=tempDirectory,
        file=tempFileName,
        result="httpResult",
        redirect=false,
        timeout=45,
        useragent="Mozilla/5.0 (compatible; RunnerHub-SixComm-Importer/1.0)"
      );
      statusCode = val(listFirst(textOrFallback(httpResult.statusCode, "0"), " "));
      if (structKeyExists(httpResult, "responseHeader") AND isStruct(httpResult.responseHeader)) {
        if (structKeyExists(httpResult.responseHeader, "Content-Type")) {
          mimeType = lCase(trim(listFirst(httpResult.responseHeader["Content-Type"], ";")));
        }
      }

      if (statusCode LT 200 OR statusCode GTE 300 OR !fileExists(tempFilePath)) {
        return {success=false, media_id=0, url_public="", message="Não foi possível baixar uma imagem do e-mail."};
      }
      if (left(mimeType, 6) NEQ "image/" AND mimeType NEQ "application/octet-stream") {
        return {success=false, media_id=0, url_public="", message="Um recurso do e-mail não é uma imagem válida."};
      }
      if (getFileInfo(tempFilePath).size GT 15728640) {
        return {success=false, media_id=0, url_public="", message="Uma imagem do e-mail excede o limite de 15 MB."};
      }

      extension = extensionForMimeType(mimeType, originalName);
      if (!len(listLast(originalName, ".")) OR originalName EQ listLast(originalName, ".")) {
        originalName = "imagem-sixcomm." & extension;
      }
      return persistImageFile(arguments.db, tempFilePath, originalName, mimeType, true);
    } catch (any imageError) {
      return {success=false, media_id=0, url_public="", message="Falha ao baixar ou salvar uma imagem do e-mail."};
    } finally {
      if (fileExists(tempFilePath)) {
        fileDelete(tempFilePath);
      }
    }
  }

  private struct function storeLocalImage(
    required any db,
    required string sourcePath,
    required string originalName
  ) {
    var mimeType = "application/octet-stream";

    if (!fileExists(arguments.sourcePath)) {
      return {success=false, media_id=0, url_public="", message="Um anexo de imagem não foi encontrado."};
    }
    if (getFileInfo(arguments.sourcePath).size GT 15728640) {
      return {success=false, media_id=0, url_public="", message="Um anexo de imagem excede o limite de 15 MB."};
    }

    try {
      mimeType = lCase(fileGetMimeType(arguments.sourcePath));
    } catch (any ignoredMimeError) {
      mimeType = mimeTypeFromExtension(arguments.originalName);
    }
    if (left(mimeType, 6) NEQ "image/") {
      return {success=false, media_id=0, url_public="", message="Um anexo não possui formato de imagem permitido."};
    }

    return persistImageFile(arguments.db, arguments.sourcePath, arguments.originalName, mimeType, false);
  }

  private struct function persistImageFile(
    required any db,
    required string sourcePath,
    required string originalName,
    required string mimeType,
    boolean moveSource = false
  ) {
    var uploadDirectory = structKeyExists(variables, "uploadDirectory")
      ? variables.uploadDirectory
      : application.uploadDir;
    var uploadBaseUrl = structKeyExists(variables, "uploadBaseUrl")
      ? variables.uploadBaseUrl
      : application.uploadBaseUrl;
    var safeFileName = buildUniqueUploadName(uploadDirectory, arguments.originalName);
    var targetPath = uploadDirectory & "/" & safeFileName;
    var inserted = "";
    var mediaId = 0;
    var fileSize = 0;

    var bytes = fileReadBinary(arguments.sourcePath);
    var signature = lCase(left(binaryEncode(bytes, "hex"), 64));
    var extension = "";
    if (left(signature, 6) EQ "ffd8ff") extension = "jpg";
    else if (left(signature, 16) EQ "89504e470d0a1a0a") extension = "png";
    else if (left(signature, 8) EQ "47494638") extension = "gif";
    else if (left(signature, 8) EQ "52494646" AND mid(signature, 17, 8) EQ "57454250") extension = "webp";
    else if (mid(signature, 9, 16) EQ "6674797061766966") extension = "avif";
    if (!len(extension)) throw(type="SixComm.InvalidImage", message="O arquivo recebido não é uma foto em formato permitido.");
    safeFileName = reReplace(safeFileName, "\.[^.]+$", "." & extension, "one");
    targetPath = uploadDirectory & "/" & safeFileName;
    arguments.mimeType = mimeTypeFromExtension(safeFileName);

    if (!directoryExists(uploadDirectory)) {
      directoryCreate(uploadDirectory);
    }
    arrayAppend(variables.createdFiles, targetPath);
    fileCopy(arguments.sourcePath, targetPath);
    fileSize = getFileInfo(targetPath).size;

    inserted = arguments.db.q("
      INSERT INTO news.tb_media (filename, orig_name, mime_type, size_bytes, url_public, author_id)
      VALUES (:filename, :original_name, :mime_type, :size_bytes, :url_public, :author_id)
      RETURNING id
    ", {
      filename: {value=safeFileName, cfsqltype="cf_sql_varchar"},
      original_name: {value=arguments.originalName, cfsqltype="cf_sql_varchar"},
      mime_type: {value=arguments.mimeType, cfsqltype="cf_sql_varchar"},
      size_bytes: {value=fileSize, cfsqltype="cf_sql_bigint"},
      url_public: {value=uploadBaseUrl & "/" & safeFileName, cfsqltype="cf_sql_varchar"},
      author_id: {value=variables.authorId, cfsqltype="cf_sql_integer"}
    });
    mediaId = extractGeneratedId(inserted);
    if (mediaId LTE 0) {
      throw(type="SixComm.Image", message="Não foi possível obter o ID da mídia importada.");
    }

    return {
      success = true,
      media_id = mediaId,
      url_public = uploadBaseUrl & "/" & safeFileName,
      original_name = arguments.originalName,
      mime_type = arguments.mimeType
    };
  }

  private struct function validateRemoteImageUrl(required string sourceUrl, required string allowedImageHosts) {
    var uri = "";
    var hostName = "";
    var allowedHosts = listToArray(lCase(arguments.allowedImageHosts));
    var allowedHost = "";
    var hostAllowed = false;

    try {
      uri = createObject("java", "java.net.URI").init(trim(arguments.sourceUrl));
      hostName = lCase(trim(uri.getHost() ?: ""));
      if ((uri.getScheme() ?: "") NEQ "https" OR !len(hostName) OR !isNull(uri.getUserInfo()) OR (uri.getPort() NEQ -1 AND uri.getPort() NEQ 443)) {
        return {success=false, media_id=0, url_public="", message="URL de imagem inválida no e-mail."};
      }
      for (allowedHost in allowedHosts) {
        allowedHost = trim(allowedHost);
        if (
          len(allowedHost)
          AND hostName EQ allowedHost
        ) {
          hostAllowed = true;
          break;
        }
      }
    } catch (any invalidUrlError) {
      return {success=false, media_id=0, url_public="", message="URL de imagem inválida no e-mail."};
    }

    if (!hostAllowed) {
      return {success=false, media_id=0, url_public="", message="O host da imagem não está autorizado para o importador SixComm: " & hostName};
    }
    return {success=true};
  }

  private void function ensureImportTable(required any db) {
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
  }

  private void function validateEditorialMappings(required any db) {
    var mapping = arguments.db.q("
      SELECT
        EXISTS (SELECT 1 FROM news.tb_content_types WHERE id = :content_type_id) AS has_content_type,
        EXISTS (SELECT 1 FROM news.tb_users WHERE id = :author_id) AS has_author,
        EXISTS (SELECT 1 FROM news.tb_categories WHERE id = :category_id) AS has_category
    ", {
      content_type_id: {value=variables.contentTypeId, cfsqltype="cf_sql_integer"},
      author_id: {value=variables.authorId, cfsqltype="cf_sql_integer"},
      category_id: {value=variables.categoryId, cfsqltype="cf_sql_integer"}
    });

    if (!mapping.recordCount OR !isTrueValue(mapping.has_content_type[1])) {
      throw(message="Canal SixComm (ID 5) não encontrado.");
    }
    if (!isTrueValue(mapping.has_author[1])) {
      throw(message="Autor Danilo Caboclo (ID 8) não encontrado.");
    }
    if (!isTrueValue(mapping.has_category[1])) {
      throw(message="Categoria Release (ID 3) não encontrada.");
    }
  }

  private string function buildManagedGalleryHtml(array galleryItems = []) {
    var html = "";
    var item = {};
    var itemName = "";

    if (!arrayLen(arguments.galleryItems)) {
      return "";
    }
    html = variables.galleryStartMarker & chr(10) & '<div class="content-gallery">' & chr(10);
    for (item in arguments.galleryItems) {
      itemName = textOrFallback(item.name, "Imagem");
      html &= '<figure class="content-gallery-item">';
      html &= '<img src="' & encodeForHTMLAttribute(item.url) & '" alt="' & encodeForHTMLAttribute(itemName) & '">';
      html &= '<figcaption>' & encodeForHTML(itemName) & '</figcaption>';
      html &= '</figure>' & chr(10);
    }
    html &= '</div>' & chr(10) & variables.galleryEndMarker;
    return html;
  }

  private string function buildSourceKey(required struct messageData) {
    return hash("message-id|" & arguments.messageData.messageId, "SHA-256");
  }

  private string function buildSlugBase(required string sourceText) {
    var slugBase = lCase(trim(arguments.sourceText));
    slugBase = replaceList(
      slugBase,
      "á,à,â,ã,ä,å,é,è,ê,ë,í,ì,î,ï,ó,ò,ô,õ,ö,ú,ù,û,ü,ç,ñ,ý,ÿ,æ,œ",
      "a,a,a,a,a,a,e,e,e,e,i,i,i,i,o,o,o,o,o,u,u,u,u,c,n,y,y,ae,oe"
    );
    slugBase = reReplace(slugBase, "[^a-z0-9]+", "-", "all");
    slugBase = reReplace(slugBase, "^-+|-+$", "", "all");
    return len(slugBase) ? slugBase : "conteudo-sixcomm";
  }

  private string function buildUniqueSlug(required any db, required string sourceText) {
    var slugBase = buildSlugBase(arguments.sourceText);
    var candidate = slugBase;
    var suffix = 2;
    var lookup = "";

    while (true) {
      lookup = arguments.db.q("SELECT id FROM news.tb_content WHERE slug = :slug LIMIT 1", {
        slug: {value=candidate, cfsqltype="cf_sql_varchar"}
      });
      if (!lookup.recordCount) {
        return candidate;
      }
      candidate = slugBase & "-" & suffix;
      suffix = suffix + 1;
    }
  }

  private string function buildUniqueUploadName(required string uploadDirectory, required string originalName) {
    var extension = lCase(listLast(arguments.originalName, "."));
    var baseName = listFirst(arguments.originalName, ".");
    var safeBaseName = buildSlugBase(baseName);
    var candidate = safeBaseName & "-" & lCase(replace(createUUID(), "-", "", "all"));

    if (!listFindNoCase("jpg,jpeg,png,gif,webp,avif", extension)) {
      extension = "jpg";
    }
    return candidate & "." & extension;
  }

  private date function parseReceivedAt(string rawHeaders = "") {
    var receivedMatches = headerValues(arguments.rawHeaders, "Received");
    var receivedValue = "";
    var semicolonPosition = 0;
    var parsedDate = "";

    if (arrayLen(receivedMatches)) {
      receivedValue = receivedMatches[1];
      semicolonPosition = find(";", receivedValue);
      if (semicolonPosition GT 0) {
        receivedValue = trim(mid(receivedValue, semicolonPosition + 1, len(receivedValue)));
        receivedValue = reReplace(receivedValue, "[ \t]+\([^)]+\)$", "", "one");
        parsedDate = parseMailDate(receivedValue);
        if (isDate(parsedDate)) {
          return parsedDate;
        }
      }
    }

    throw(type="SixComm.InvalidDate", message="Cabeçalho Received sem data de recebimento válida.");
  }

  private any function parseMailDate(string rawDate = "") {
    var patterns = ["EEE, d MMM yyyy HH:mm:ss Z", "EEE, dd MMM yyyy HH:mm:ss Z"];
    var pattern = "";
    var locale = createObject("java", "java.util.Locale").ENGLISH;
    var formatter = "";

    for (pattern in patterns) {
      try {
        formatter = createObject("java", "java.text.SimpleDateFormat").init(pattern, locale);
        formatter.setLenient(false);
        var instant = formatter.parse(trim(arguments.rawDate));
        var localFormat = createObject("java", "java.text.SimpleDateFormat").init("yyyy-MM-dd HH:mm:ss", locale);
        localFormat.setTimeZone(createObject("java", "java.util.TimeZone").getTimeZone("America/Sao_Paulo"));
        return parseDateTime(localFormat.format(instant));
      } catch (any ignoredDatePattern) {}
    }
    return "";
  }

  private boolean function headerContainsMailbox(required string rawHeaders, required string mailbox) {
    var delivered = headerValues(arguments.rawHeaders, "Delivered-To");
    if (arrayLen(delivered)) return compareNoCase(trim(delivered[1]), arguments.mailbox) EQ 0;
    var recipients = headerValues(arguments.rawHeaders, "To");
    arrayAppend(recipients, headerValues(arguments.rawHeaders, "Bcc"), true);
    for (var recipient in recipients) {
      if (extractEmailAddress(recipient) EQ arguments.mailbox) return true;
    }
    return false;
  }

  private boolean function hasValidSenderAuthentication(required string rawHeaders) {
    var headers = headerValues(arguments.rawHeaders, "Authentication-Results");
    // Gmail adds this result at delivery. Do not combine unrelated DKIM claims.
    if (!arrayLen(headers) OR compareNoCase(trim(listFirst(headers[1], ";")), "mx.google.com") NEQ 0) return false;
    for (var result in listToArray(headers[1], ";")) {
      if (reFindNoCase("^\s*dkim=pass\s", result)
        AND reFindNoCase("\bheader\.(i=[^@\s]*@|d=)gruposix\.com\.br(\s|$)", result)) return true;
    }
    return false;
  }

  private array function headerValues(required string headers, required string name) {
    var unfolded = reReplace(arguments.headers, "\r?\n[ \t]+", " ", "all");
    var values = [];
    for (var line in listToArray(replace(unfolded, chr(13), "", "all"), chr(10))) {
      if (compareNoCase(left(line, len(arguments.name) + 1), arguments.name & ":") EQ 0) {
        arrayAppend(values, trim(mid(line, len(arguments.name) + 2, len(line))));
      }
    }
    return values;
  }

  public array function pendingMessageNumbers(required query headers, required any db, numeric maxMessages = 20) {
    var numbers = [];
    for (var i = arguments.headers.recordCount; i GTE 1; i = i - 1) {
      if (extractEmailAddress(queryValue(arguments.headers, i, "from")) NEQ variables.expectedSender) continue;
      var messageId = normalizeMessageId(queryValue(arguments.headers, i, "messageid"));
      var existing = arguments.db.q("SELECT id FROM news.tb_content_imports WHERE importer_key=:key AND source_key=:source LIMIT 1", {
        key={value=variables.importerKey,cfsqltype="cf_sql_varchar"},
        source={value=buildSourceKey({messageId=messageId}),cfsqltype="cf_sql_varchar"}
      });
      if (existing.recordCount) continue;
      arrayAppend(numbers, val(queryValue(arguments.headers, i, "messagenumber")));
      if (arrayLen(numbers) GTE arguments.maxMessages) break;
    }
    return numbers;
  }

  public void function prepareStorage(required any db) {
    ensureImportTable(arguments.db);
    validateEditorialMappings(arguments.db);
  }

  private string function extractEmailAddress(string rawAddress = "") {
    var matches = reMatchNoCase("[a-z0-9.!##$%&'*+/=?^_`{|}~-]+@[a-z0-9.-]+\.[a-z]{2,}", arguments.rawAddress);
    return arrayLen(matches) EQ 1 ? lCase(trim(matches[1])) : "";
  }

  private string function normalizeMessageId(string rawMessageId = "") {
    var normalized = trim(arguments.rawMessageId);
    normalized = reReplace(normalized, "^<|>$", "", "all");
    return normalized;
  }

  private string function htmlFragmentToText(string htmlFragment = "") {
    var textValue = arguments.htmlFragment;
    textValue = reReplaceNoCase(textValue, "<br\s*/?>", " ", "all");
    textValue = reReplaceNoCase(textValue, "<[^>]+>", " ", "all");
    try {
      textValue = canonicalize(textValue, false, false);
    } catch (any ignoredCanonicalizeError) {}
    textValue = replaceNoCase(textValue, "&nbsp;", " ", "all");
    textValue = replaceNoCase(textValue, "&amp;", "&", "all");
    textValue = replaceNoCase(textValue, "&quot;", chr(34), "all");
    textValue = replaceNoCase(textValue, "&" & chr(35) & "39;", chr(39), "all");
    return normalizeWhitespace(textValue);
  }

  private string function normalizeWhitespace(string rawValue = "") {
    return trim(reReplace(arguments.rawValue, "\s+", " ", "all"));
  }

  private string function normalizeComparison(string rawValue = "") {
    var normalized = lCase(normalizeWhitespace(arguments.rawValue));
    normalized = reReplace(normalized, "[^a-z0-9áàâãäéèêëíìîïóòôõöúùûüçñ]+", " ", "all");
    return trim(reReplace(normalized, "\s+", " ", "all"));
  }

  private boolean function isFooterParagraph(required string paragraphText) {
    var normalized = lCase(normalizeWhitespace(arguments.paragraphText));
    return find("informações para imprensa", normalized) EQ 1
      OR find("informacoes para imprensa", normalized) EQ 1
      OR find("sixcomm comunicação", normalized) EQ 1
      OR find("sixcomm comunicacao", normalized) EQ 1
      OR normalized EQ "danilo caboclo"
      OR find("fone:", normalized) EQ 1;
  }

  private string function extractImageSource(required string imageTag) {
    var matches = reMatchNoCase('src=(?:"[^"]+"|''[^'']+'')', arguments.imageTag);
    var value = "";
    if (!arrayLen(matches)) {
      return "";
    }
    value = reReplaceNoCase(matches[1], '^src=["'']|["'']$', "", "all");
    value = replaceNoCase(value, "&amp;", "&", "all");
    return trim(value);
  }

  private boolean function isDecorativeImage(required string imageTag, required string imageUrl) {
    var normalized = lCase(arguments.imageUrl);
    var widthMatches = reMatchNoCase('width=["'']?[0-9]+', arguments.imageTag);
    var heightMatches = reMatchNoCase('height=["'']?[0-9]+', arguments.imageTag);
    var widthValue = arrayLen(widthMatches) ? val(reReplace(widthMatches[1], "[^0-9]", "", "all")) : 0;
    var heightValue = arrayLen(heightMatches) ? val(reReplace(heightMatches[1], "[^0-9]", "", "all")) : 0;

    return find("mail-sig", normalized) GT 0
      OR find("signature", normalized) GT 0
      OR find("tracking", normalized) GT 0
      OR find("pixel", normalized) GT 0
      OR (widthValue GT 0 AND widthValue LTE 10)
      OR (heightValue GT 0 AND heightValue LTE 10);
  }

  private array function splitAttachmentFiles(string rawFiles = "") {
    if (!len(trim(arguments.rawFiles))) {
      return [];
    }
    if (find(chr(9), arguments.rawFiles)) {
      return listToArray(arguments.rawFiles, chr(9));
    }
    return listToArray(arguments.rawFiles);
  }

  private boolean function isSupportedImageFile(required string filePath) {
    return listFindNoCase("jpg,jpeg,png,gif,webp,avif", listLast(arguments.filePath, ".")) GT 0;
  }

  private string function fileNameFromUrl(required string sourceUrl) {
    var fileName = "";
    try {
      fileName = getFileFromPath(createObject("java", "java.net.URI").init(arguments.sourceUrl).getPath());
    } catch (any ignoredUrlError) {}
    return len(fileName) ? fileName : "imagem-sixcomm.jpg";
  }

  private string function mimeTypeFromExtension(required string fileName) {
    var extension = lCase(listLast(arguments.fileName, "."));
    if (extension EQ "png") return "image/png";
    if (extension EQ "gif") return "image/gif";
    if (extension EQ "webp") return "image/webp";
    if (extension EQ "avif") return "image/avif";
    return "image/jpeg";
  }

  private string function extensionForMimeType(required string mimeType, string fallbackName = "") {
    var normalized = lCase(arguments.mimeType);
    if (normalized EQ "image/png") return "png";
    if (normalized EQ "image/gif") return "gif";
    if (normalized EQ "image/webp") return "webp";
    if (normalized EQ "image/avif") return "avif";
    if (normalized EQ "image/jpeg" OR normalized EQ "image/jpg") return "jpg";
    if (listFindNoCase("jpg,jpeg,png,gif,webp,avif", listLast(arguments.fallbackName, "."))) {
      return lCase(listLast(arguments.fallbackName, "."));
    }
    return "jpg";
  }

  private any function queryValue(required query sourceQuery, required numeric rowIndex, required string columnName) {
    if (!listFindNoCase(arguments.sourceQuery.columnList, arguments.columnName)) {
      return "";
    }
    return arguments.sourceQuery[arguments.columnName][arguments.rowIndex];
  }

  private numeric function extractGeneratedId(required any resultSet) {
    if (isQuery(arguments.resultSet) AND arguments.resultSet.recordCount AND listFindNoCase(arguments.resultSet.columnList, "id")) {
      return val(arguments.resultSet.id[1]);
    }
    if (isStruct(arguments.resultSet) AND structKeyExists(arguments.resultSet, "generatedKey")) {
      return val(arguments.resultSet.generatedKey);
    }
    return 0;
  }

  private boolean function isTrueValue(required any value) {
    if (isBoolean(arguments.value)) {
      return arguments.value;
    }
    return listFindNoCase("1,true,t,yes", textOrFallback(arguments.value, "")) GT 0;
  }

  private string function textOrFallback(value, string fallback = "") {
    if (isNull(arguments.value)) {
      return arguments.fallback;
    }
    return len(trim(arguments.value & "")) ? trim(arguments.value & "") : arguments.fallback;
  }
}
