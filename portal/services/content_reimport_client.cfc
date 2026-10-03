component output="false" {
  variables.baseUrl = "";
  variables.secret = "";

  public any function init(required string baseUrl, required string secret) {
    variables.baseUrl = reReplace(trim(arguments.baseUrl), "/+$", "", "all");
    variables.secret = trim(arguments.secret);
    return this;
  }

  public struct function buildRequest(required numeric contentId, string timestamp = "") {
    var safeContentId = int(arguments.contentId);
    var timestampValue = len(trim(arguments.timestamp))
      ? trim(arguments.timestamp)
      : dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss");
    var body = "";

    if (safeContentId LTE 0) throw(type="ContentReimport.InvalidContent", message="Conteúdo inválido.");
    if (!len(variables.baseUrl) OR !len(variables.secret)) {
      throw(type="ContentReimport.Configuration", message="A integração com o News não está configurada.");
    }

    body = serializeJSON({content_id=safeContentId}, "struct", false);
    return {
      endpoint = variables.baseUrl & "/api/admin/importers/reimport.cfm",
      body = body,
      timestamp = timestampValue,
      signature = lCase(hmac(timestampValue & "." & body, variables.secret, "HmacSHA256", "UTF-8"))
    };
  }

  public struct function parseResponse(required numeric statusCode, required string rawBody) {
    var payload = {};
    var message = "O News retornou uma resposta inválida para a reimportação.";
    if (isJSON(arguments.rawBody)) {
      payload = deserializeJSON(arguments.rawBody);
      if (isStruct(payload)) {
        message = left(trim(payload.message ?: payload.error ?: message), 500);
        return {
          success = arguments.statusCode GTE 200 AND arguments.statusCode LT 300 AND (payload.success ?: false),
          status = trim(payload.status ?: (arguments.statusCode GTE 200 AND arguments.statusCode LT 300 ? "completed" : "failed")),
          message = message,
          payload = payload
        };
      }
    }
    return {success=false, status="invalid_response", message=message, payload={}};
  }
}
