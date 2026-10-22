component extends="BoundedAIStore" output=false {
    variables.blocked=false;variables.workIds=[];
    public void function bindMany(required array ids){variables.workIds=ids;super.bindWork(ids[1]);super.allowCalls();}
    public void function blockAI(){variables.blocked=true;}
    public struct function aiAvailability(numeric limit=1000){return variables.blocked ? {allowed=false,reason="ai_cooldown",retryAfter=3600} : {allowed=true,reason="ok",retryAfter=0};}
    public struct function claim(numeric id=0){for(var workId in variables.workIds){var work=new services.geocoding.LocationStore().claim(workId);if(!structIsEmpty(work))return work;}return {};}
}
