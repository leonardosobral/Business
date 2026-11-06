component output="false" {

  public struct function loadConfig() {
    var contentLocalConfig = loadFileConfig();
    var storedSettings = {};
    var keyName = "";

    storedSettings = loadDatabaseSettings();
    for (keyName in storedSettings) {
      contentLocalConfig[keyName] = storedSettings[keyName];
    }

    return contentLocalConfig;
  }

  public struct function loadFileConfig() {
    var result = parseConfigFile(getConfigPath());
    var system = createObject("java", "java.lang.System");
    var fallbackPath = trim(system.getenv("GOOGLE_OAUTH_FALLBACK_CONFIG") ?: "");
    var fallbackConfig = {};
    var oauthKey = "";

    if (!len(fallbackPath)) {
      fallbackPath = "/var/lib/runnerhub-secrets/content-google-oauth.local.cfm";
    }

    if (fileExists(fallbackPath)) {
      fallbackConfig = parseConfigFile(fallbackPath);
      for (oauthKey in listToArray("googleOAuthClientId,googleOAuthClientSecret,googleOAuthRedirectUri")) {
        if (
          (!structKeyExists(result, oauthKey) OR !len(trim(result[oauthKey] & "")))
          AND structKeyExists(fallbackConfig, oauthKey)
          AND len(trim(fallbackConfig[oauthKey] & ""))
        ) {
          result[oauthKey] = fallbackConfig[oauthKey];
        }
      }
    }

    return result;
  }

  private struct function parseConfigFile(required string configPath) {
    var result = {};
    var allowedKeys = "importerHandoffSecret,openAiApiKey,newsTtsEnabled,weeklyDigestModel,weeklyDigestEnabled,weeklyDigestSecret,articleSummaryEnabled,articleSummaryModel,articleSummaryWorkerSecret,articleSummaryMaxAttempts,googleOAuthClientId,googleOAuthClientSecret,googleOAuthRedirectUri,sixCommGmailClientId,sixCommGmailClientSecret,sixCommGmailRedirectUri,rrInternalBase,sixCommMailPassword,sixCommMailMaxRows,sixCommMailScanRows,sixCommAllowedImageHosts,contraRelogioFeedCookie,contraRelogioFeedUserAgent,contraRelogioFeedAcceptLanguage,contraRelogioFeedRetryCount,contraRelogioFeedRetryDelayMs";
    var sourceText = "";
    var sourceLine = "";
    var separatorPosition = 0;
    var keyName = "";
    var rawValue = "";

    if (!fileExists(arguments.configPath)) {
      return result;
    }

    sourceText = replace(fileRead(arguments.configPath, "UTF-8"), chr(13), "", "all");
    for (sourceLine in listToArray(sourceText, chr(10))) {
      separatorPosition = find("=", sourceLine);
      if (separatorPosition LTE 1) {
        continue;
      }

      keyName = trim(left(sourceLine, separatorPosition - 1));
      if (!listFindNoCase(allowedKeys, keyName)) {
        continue;
      }

      rawValue = trim(mid(sourceLine, separatorPosition + 1, len(sourceLine)));
      rawValue = reReplace(rawValue, ",\s*$", "", "one");
      if (len(rawValue) GTE 2 AND left(rawValue, 1) EQ chr(34) AND right(rawValue, 1) EQ chr(34)) {
        result[keyName] = replace(mid(rawValue, 2, len(rawValue) - 2), chr(34) & chr(34), chr(34), "all");
      } else if (listFindNoCase("true,false", rawValue)) {
        result[keyName] = rawValue EQ "true";
      } else if (isNumeric(rawValue)) {
        result[keyName] = val(rawValue);
      }
    }

    return result;
  }

  public void function saveConfig(required struct configData) {
    var normalizedConfig = normalizeConfig(arguments.configData);
    saveDatabaseSettings(normalizedConfig);
  }

  public string function maskCookieHeader(string rawCookie = "") {
    var cookieValue = trim(arguments.rawCookie);
    var cookieParts = [];
    var maskedParts = [];
    var cookiePart = "";
    var cookieName = "";
    var cookieRawValue = "";

    if (NOT len(cookieValue)) {
      return "";
    }

    cookieParts = listToArray(cookieValue, ";");

    for (cookiePart in cookieParts) {
      cookiePart = trim(cookiePart);
      if (NOT len(cookiePart) OR find("=", cookiePart) LTE 0) {
        continue;
      }

      cookieName = trim(listFirst(cookiePart, "="));
      cookieRawValue = trim(listRest(cookiePart, "="));

      if (NOT len(cookieRawValue)) {
        arrayAppend(maskedParts, cookieName & "=<vazio>");
      } else if (len(cookieRawValue) LTE 10) {
        arrayAppend(maskedParts, cookieName & "=" & repeatString("*", len(cookieRawValue)));
      } else {
        arrayAppend(
          maskedParts,
          cookieName & "=" & left(cookieRawValue, 4) & repeatString("*", max(len(cookieRawValue) - 8, 4)) & right(cookieRawValue, 4)
        );
      }
    }

    return arrayToList(maskedParts, "; ");
  }

  private string function getConfigPath() {
    return getDirectoryFromPath(getCurrentTemplatePath()) & "../config/content.local.cfm";
  }

  private any function getDb() {
    return createObject("component", "inc.db");
  }

  private void function ensureSettingsTable() {
    var db = getDb();

    // Avoid DDL on provisioned databases whose datasource restricts schema changes.
    if (!db.relationExists("news", "tb_runtime_settings")) {
      db.q("
        CREATE TABLE IF NOT EXISTS news.tb_runtime_settings (
          setting_key TEXT PRIMARY KEY,
          setting_value TEXT,
          updated_at TIMESTAMP NOT NULL DEFAULT now()
        )
      ");
    }
  }

  private struct function loadDatabaseSettings() {
    var db = getDb();
    var result = {};
    var lookup = "";
    var index = 0;

    ensureSettingsTable();

    lookup = db.q("
      SELECT setting_key, setting_value
      FROM news.tb_runtime_settings
    ");

    for (index = 1; index <= lookup.recordCount; index = index + 1) {
      result[trim(lookup.setting_key[index] & "")] = lookup.setting_value[index];
    }

    return result;
  }

  private void function saveDatabaseSettings(required struct configData) {
    var db = getDb();
    var keyName = "";
    var settingValue = "";

    ensureSettingsTable();

    for (keyName in arguments.configData) {
      settingValue = arguments.configData[keyName];

      db.q("
        INSERT INTO news.tb_runtime_settings (setting_key, setting_value, updated_at)
        VALUES (:setting_key, :setting_value, now())
        ON CONFLICT (setting_key)
        DO UPDATE SET
          setting_value = EXCLUDED.setting_value,
          updated_at = now()
      ", {
        setting_key: { value = keyName, cfsqltype = "cf_sql_varchar" },
        setting_value: { value = settingValue & "", cfsqltype = "cf_sql_longvarchar", null = isNull(settingValue) }
      });
    }
  }

  private struct function normalizeConfig(required struct configData) {
    var normalized = {};
    var keyName = "";

    for (keyName in arguments.configData) {
      normalized[keyName] = arguments.configData[keyName];
    }

    return normalized;
  }
}
