component extends="services.geocoding.Store" output=false {
    public numeric function seed(numeric limit=5){return 0;}
    public struct function claim(numeric id=0){return super.claim(variables.fixtureWorkId);}
    public void function bindWork(required numeric id){variables.fixtureWorkId=id;}
    // Synthetic pipeline tests must not compete with the live production batch.
    // Real database/HTTP exclusivity is covered by acceleration/concurrency modes.
    public struct function acquireWorker(){variables.fixtureBatchToken=createUUID();return {allowed=true,token=variables.fixtureBatchToken};}
    public boolean function workerValid(required string token){return structKeyExists(variables,"fixtureBatchToken") AND variables.fixtureBatchToken EQ token;}
    public boolean function releaseWorker(required string token){if(!workerValid(token))return false;structDelete(variables,"fixtureBatchToken");return true;}
}
