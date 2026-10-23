component output=false {
 variables.enabled=true;variables.reservations=0;
 public void function pause(){variables.enabled=false;}
 public void function resume(){variables.enabled=true;}
 public struct function settings(){return {enabled=variables.enabled};}
 public struct function aiAvailability(numeric limit=1000){return {allowed=true,reason="ok",retryAfter=0};}
 public struct function reserveAI(numeric limit=1000){variables.reservations++;return {allowed=true};}
 public void function completeAI(required struct reply){}
}
