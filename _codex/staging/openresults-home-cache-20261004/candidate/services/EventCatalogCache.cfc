component output=false {
 public any function init(required any source,numeric ttlSeconds=1800,numeric retrySeconds=60) {
  variables.source=arguments.source;variables.ttl=max(1,arguments.ttlSeconds);variables.retry=max(1,arguments.retrySeconds);
  variables.snapshot={};variables.expiresAt=now();variables.retryAt=now();variables.refreshing=false;
  variables.lockName='OREventCatalog-' & createUUID();variables.referenceKey='__orCatalog' & replace(createUUID(),'-','','all');
  return this;
 }
 public struct function get() {
  var result={};var launch=false;
  lock name=variables.lockName type='readonly' timeout=2 {result=duplicate(variables.snapshot);}
  if(structIsEmpty(result)) {
   // A cold application loads once, rather than serving an empty catalogue or starting duplicate queries.
   lock name=(variables.lockName & '-cold') type='exclusive' timeout=30 {
    lock name=variables.lockName type='exclusive' timeout=2 {
     launch=structIsEmpty(variables.snapshot) && !variables.refreshing && now() GTE variables.retryAt;
     if(launch)variables.refreshing=true;
    }
    if(launch)refresh();
    lock name=variables.lockName type='readonly' timeout=2 {result=duplicate(variables.snapshot);}
   }
   return result;
  }
  lock name=variables.lockName type='exclusive' timeout=2 {
   if(!variables.refreshing && now() GTE variables.expiresAt && now() GTE variables.retryAt){variables.refreshing=true;launch=true;}
  }
  if(launch) {
   try {
    // CFTHREAD duplicates CFC attributes; resolve the original instance from APPLICATION.
    APPLICATION[variables.referenceKey]=this;
    thread name=('ORCatalogRefresh' & replace(createUUID(),'-','','all')) cacheKey=variables.referenceKey {
     try {APPLICATION[attributes.cacheKey].refresh();}
     finally {structDelete(APPLICATION,attributes.cacheKey);}
    }
   } catch(any launchError){structDelete(APPLICATION,variables.referenceKey);failed();}
  }
  return result;
 }
 public void function refresh() {
  try {
   var data=variables.source.fetch();
   if(!isStruct(data) || !structKeyExists(data,'events') || !isQuery(data.events)
    || !structKeyExists(data,'cities') || !isStruct(data.cities)
    || !structKeyExists(data.cities,'cities') || !isArray(data.cities.cities)
    || !structKeyExists(data.cities,'recent') || !isArray(data.cities.recent)
    || !structKeyExists(data.cities,'popular') || !isArray(data.cities.popular)
    || !structKeyExists(data,'totalResults') || !isQuery(data.totalResults) || data.totalResults.recordCount!=1)
    throw(message='Invalid event catalogue snapshot');
   lock name=variables.lockName type='exclusive' timeout=2 {
    variables.snapshot=data;variables.expiresAt=dateAdd('s',variables.ttl,now());variables.retryAt=variables.expiresAt;variables.refreshing=false;
   }
  } catch(any refreshError){failed();}
 }
 private void function failed() {
  lock name=variables.lockName type='exclusive' timeout=2 {
   variables.retryAt=dateAdd('s',variables.retry,now());variables.refreshing=false;
  }
 }
}
