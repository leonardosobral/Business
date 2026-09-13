<cfscript>
function fixtureHttpRequestData(boolean includeBody=true) { return REQUEST.fixtureHttp; }
function check(required boolean condition, required string label) {
    if (!arguments.condition) throw(type="AssertionFailed", message=arguments.label);
}
function runCase(required string method, required string body, struct headers={}, boolean configured=true, boolean withApiKey=false) {
    REQUEST.fixtureMethod = arguments.method;
    REQUEST.fixtureHttp = {content=arguments.body, headers=arguments.headers};
    REQUEST.fixtureResponse = {};
    REQUEST.fixtureConfig = arguments.configured ? {cronSecrets={business_internal='fixture-only-hmac-secret'}} : {};
    if (arguments.withApiKey) REQUEST.fixtureConfig.openAiApiKey = 'fixture-only-api-key';
    try { include 'api/eventos/jobs/rewrite-descriptions.cfm'; }
    catch (FixtureResponse done) { return REQUEST.fixtureResponse; }
    throw(type='AssertionFailed', message='Endpoint must return a JSON response');
}
function signedHeaders(required string body, numeric offsetMinutes=0, string signingSecret='fixture-only-hmac-secret') {
    var timestamp = dateTimeFormat(dateAdd('n', arguments.offsetMinutes, now()), "yyyy-mm-dd'T'HH:nn:ssXXX");
    return {
        'X-RR-Handoff-Timestamp'=timestamp,
        'X-RR-Handoff-Signature'=lCase(hmac(timestamp & '.' & arguments.body, arguments.signingSecret, 'HmacSHA256', 'UTF-8'))
    };
}
cases = [
    {method='GET', body='{}', headers={}, code=405, status='method_not_allowed'},
    {method='POST', body='{}', headers={}, code=401, status='unauthorized'},
    {method='POST', body='{}', headers={'Authorization'='Bearer fixture-only-hmac-secret'}, code=401, status='unauthorized'},
    {method='POST', body='{}', headers=signedHeaders('{}', -6), code=401, status='unauthorized'},
    {method='POST', body='{}', headers=signedHeaders('{}', 6), code=401, status='unauthorized'},
    {method='POST', body='{}', headers=signedHeaders('{}', 0, 'wrong-secret'), code=401, status='unauthorized'},
    {method='POST', body='{"dryRun":false}', headers=signedHeaders('{}'), code=401, status='unauthorized'},
    {method='POST', body='[1]', headers=signedHeaders('[1]'), code=400, status='validation_error'},
    {method='POST', body='{bad}', headers=signedHeaders('{bad}'), code=400, status='invalid_json'},
    {method='POST', body='{"limit":2}', headers=signedHeaders('{"limit":2}'), code=400, status='validation_error'},
    {method='POST', body='{"eventId":0}', headers=signedHeaders('{"eventId":0}'), code=400, status='validation_error'},
    {method='POST', body='{"eventId":1.5}', headers=signedHeaders('{"eventId":1.5}'), code=400, status='validation_error'},
    {method='POST', body='{"dryRun":"maybe"}', headers=signedHeaders('{"dryRun":"maybe"}'), code=400, status='validation_error'},
    {method='POST', body='{"dryRun":"false"}', headers=signedHeaders('{"dryRun":"false"}'), code=400, status='validation_error'},
    {method='POST', body='{"dryRun":null}', headers=signedHeaders('{"dryRun":null}'), code=400, status='validation_error'},
    {method='POST', body='{"limit":null}', headers=signedHeaders('{"limit":null}'), code=400, status='validation_error'},
    {method='POST', body='{"eventId":null}', headers=signedHeaders('{"eventId":null}'), code=400, status='validation_error'},
    {method='POST', body='{"model":"caller-model"}', headers=signedHeaders('{"model":"caller-model"}'), code=400, status='validation_error'},
    {method='POST', body='{"eventId":{}}', headers=signedHeaders('{"eventId":{}}'), code=400, status='validation_error'},
    {method='POST', body='{}', headers=signedHeaders('{}'), code=503, status='configuration_error'},
    {method='POST', body='{"dryRun":false,"eventId":1,"limit":1}', headers=signedHeaders('{"dryRun":false,"eventId":1,"limit":1}'), code=503, status='configuration_error'}
];
for (scenario in cases) {
    result = runCase(scenario.method, scenario.body, scenario.headers);
    check(result.code EQ scenario.code, 'HTTP status ' & serializeJSON(scenario) & ': ' & serializeJSON(result));
    check(result.payload.status EQ scenario.status, 'Response status ' & serializeJSON(scenario));
}
result = runCase('POST', '{}', {}, false);
check(result.code EQ 503 AND result.payload.status EQ 'configuration_error', 'Missing HMAC configuration is explicit');
writeOutput('Endpoint guards passed: 22' & chr(10));
include 'integration.cfm';
</cfscript>
