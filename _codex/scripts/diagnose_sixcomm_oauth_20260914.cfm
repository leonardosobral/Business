<cfsetting showdebugoutput="false">
<cfscript>
// Temporary runtime diagnostic. No database writes or mailbox reads.
if (NOT structKeyExists(request, 'sixCommDiagnosticAuthorized') OR NOT request.sixCommDiagnosticAuthorized) {
  cfheader(statuscode=403);
  abort;
}
try {
  cfg = {};
  for (line in listToArray(fileRead('/var/www/conteudo.roadrunners.run/config/content.local.cfm'), chr(10))) {
    sep = find('=', line);
    if (sep GT 1) {
      key = trim(left(line, sep - 1));
      raw = reReplace(trim(mid(line, sep + 1, len(line))), ',\s*$', '', 'one');
      if (left(raw,1) EQ chr(34) AND right(raw,1) EQ chr(34)) cfg[key] = mid(raw,2,len(raw)-2);
    }
  }
  stored = queryExecute("SELECT setting_key, setting_value FROM news.tb_runtime_settings WHERE setting_key IN ('sixCommGmailClientId','sixCommGmailClientSecret','sixCommGmailRedirectUri','sixCommGmailRefreshTokenEncrypted','sixCommGmailEmail')", {}, {datasource='runner_dba'});
  report = {database_read=true, overrides={}};
  for (row in stored) {
    key = row.setting_key;
    if (listFindNoCase('sixCommGmailClientId,sixCommGmailClientSecret,sixCommGmailRedirectUri',key)) {
      report.overrides[key] = {nonempty=len(trim(row.setting_value)) GT 0, matches_file=structKeyExists(cfg,key) AND compare(cfg[key],row.setting_value) EQ 0};
    }
    cfg[key] = row.setting_value;
  }
  report.saved_mailbox_matches = (cfg.sixCommGmailEmail ?: '') EQ 'contato@runnerhub.run';
  if (structKeyExists(payloadData, 'candidate') AND isStruct(payloadData.candidate)) {
    cfg.sixCommGmailClientId = payloadData.candidate.clientId;
    cfg.sixCommGmailClientSecret = payloadData.candidate.clientSecret;
    report.candidate = 'existing_content_google_login_client';
  }
  parts = listToArray(cfg.sixCommGmailRefreshTokenEncrypted ?: '', ':');
  report.saved_token_present = arrayLen(parts) EQ 4;
  if (report.saved_token_present) {
    authenticated = parts[3] & ':' & parts[4];
    mac = lCase(hmac(authenticated,'sixcomm-authentication|' & cfg.importerHandoffSecret,'HmacSHA256','UTF-8'));
    report.token_mac_valid = createObject('java','java.security.MessageDigest').isEqual(charsetDecode(mac,'UTF-8'),charsetDecode(parts[2],'UTF-8'));
    if (report.token_mac_valid) {
      aesKey = toBase64(binaryDecode(hash('sixcomm-encryption|' & cfg.importerHandoffSecret,'SHA-256'),'hex'));
      refresh = decrypt(parts[4],aesKey,'AES/CBC/PKCS5Padding','Base64',binaryDecode(parts[3],'Base64'));
      cfhttp(method='post',url='https://oauth2.googleapis.com/token',result='response',timeout='20') {
        cfhttpparam(type='formField',name='client_id',value=cfg.sixCommGmailClientId);
        cfhttpparam(type='formField',name='client_secret',value=cfg.sixCommGmailClientSecret);
        cfhttpparam(type='formField',name='refresh_token',value=refresh);
        cfhttpparam(type='formField',name='grant_type',value='refresh_token');
      }
      report.token_http = val(response.statusCode);
      payload = isJSON(response.fileContent) ? deserializeJSON(response.fileContent) : {};
      providerError = isSimpleValue(payload.error ?: '') ? (payload.error ?: '') : '';
      report.token_error = listFindNoCase('invalid_client,invalid_grant,unauthorized_client,invalid_request',providerError) ? providerError : 'other_or_none';
      report.access_token_returned = len(payload.access_token ?: '') GT 0;
    }
  }
  writeOutput('SIXCOMM_DIAG ' & serializeJSON(report) & chr(10));
} catch (any failure) {
  writeOutput('SIXCOMM_DIAG ' & serializeJSON({diagnostic_failed=true,type=failure.type}) & chr(10));
}
</cfscript>
