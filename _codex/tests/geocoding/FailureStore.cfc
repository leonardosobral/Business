component output=false {
    variables.finished=0;variables.deferred=0;
    public boolean function isReady(){return true;}
    public struct function settings(){return {enabled=true,validatedFingerprint=lCase(hash("fixture-only","SHA-256")),dailyLimit=1};}
    public struct function providerState(){return {cooldown=0};}
    public struct function acquireWorker(){return {allowed=true,token="fixture"};}
    public boolean function workerValid(required string token){return token EQ "fixture";}
    public boolean function releaseWorker(required string token){return true;}
    public numeric function seed(numeric limit=5){return 0;}
    public struct function claim(){return {id=1,id_evento=1,lease_token="fixture",source_snapshot="not JSON"};}
    public struct function finish(required struct work,required struct result,required string actor){if(result.status EQ "error")variables.finished++;return {id=1,id_evento=1,status=result.status};}
    public void function defer(required struct work,numeric seconds=60){variables.deferred++;}
    public struct function counts(){return {finished=variables.finished,deferred=variables.deferred};}
}
