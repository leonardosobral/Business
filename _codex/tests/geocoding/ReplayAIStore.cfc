component extends="services.geocoding.LocationStore" output=false {
    public void function bindWork(required numeric id){variables.fixtureWorkId=id;}
    public numeric function seed(numeric limit=5){return 0;}
    public struct function claim(numeric id=0){return super.claim(variables.fixtureWorkId);}
    public struct function settings(){return {enabled=true,validatedFingerprint=lCase(hash("fixture-only","SHA-256")),dailyLimit=2000};}
    public struct function acquireWorker(){variables.fixtureBatchToken=createUUID();return {allowed=true,token=variables.fixtureBatchToken};}
    public boolean function workerValid(required string token){return structKeyExists(variables,"fixtureBatchToken") AND variables.fixtureBatchToken EQ token;}
    public boolean function releaseWorker(required string token){return true;}
    public struct function reserveCall(required numeric limit){return {allowed=false,reason="daily_limit",retryAfter=3600};}
    public struct function reserveAI(numeric limit=1000){return {allowed=true,reason="pre_reserved",retryAfter=3600};}
    public void function resourcePut(required string key,required struct value,numeric days=1){try{super.resourcePut(key,value,days);}catch(Database failure){throw(type="Test.Failed",message="Cache encoding: " & failure.message,detail=left(failure.detail,800));}}
}
