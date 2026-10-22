component extends="services.geocoding.LocationStore" output=false {
    variables.pause=true;
    public void function allowCalls(){variables.pause=false;}
    public void function bindWork(required numeric id){variables.fixtureWorkId=id;}
    public numeric function seed(numeric limit=5){return 0;}
    public struct function claim(numeric id=0){return super.claim(variables.fixtureWorkId);}
    public struct function settings(){return {enabled=true,validatedFingerprint=lCase(hash("fixture-only","SHA-256")),dailyLimit=2000};}
    public struct function acquireWorker(){variables.fixtureBatchToken=createUUID();return {allowed=true,token=variables.fixtureBatchToken};}
    public boolean function workerValid(required string token){return structKeyExists(variables,"fixtureBatchToken") AND variables.fixtureBatchToken EQ token;}
    public boolean function releaseWorker(required string token){structDelete(variables,"fixtureBatchToken");return true;}
    public struct function cacheGet(required struct lookup){return {found=false};}
    public void function cachePut(required struct lookup,required array results){}
    public struct function reserveAI(numeric limit=1000){return {allowed=true,reason="fixture",retryAfter=300};}
    public struct function aiAvailability(numeric limit=1000){return {allowed=true,reason="ok",retryAfter=0};}
    public struct function reserveCall(required numeric limit){if(variables.pause){variables.pause=false;return {allowed=false,reason="provider_cooldown",retryAfter=1};}return {allowed=true,token="fixture"};}
    public boolean function completeCall(required string token,required string code,numeric seconds=0,string fingerprint=""){return true;}
}
