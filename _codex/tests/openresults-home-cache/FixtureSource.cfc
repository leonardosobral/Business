component {
 this.calls=createObject('java','java.util.concurrent.atomic.AtomicInteger').init(0);
 this.mode='good';this.delay=450;
 public struct function fetch(){
  this.calls.incrementAndGet();sleep(this.delay);
  if(this.mode=='fail')throw(message='Synthetic failure');
  if(this.mode=='invalid')return {events='invalid'};
  return {events=queryNew('id_evento','integer',[{id_evento=2}]),cities={cities=[],recent=[],popular=[]},totalResults=queryNew('total','integer',[{total=42}])};
 }
}
