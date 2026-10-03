const test = require('node:test');
const assert = require('node:assert/strict');
let manager;
try { manager = require('../../administracao/chat/grupos-especiais/assets/manager.js'); } catch (_) {}
function policy(data) { assert.ok(manager, 'community form policy builder is not implemented'); return manager.buildPolicy(data); }
test('open audience cannot retain hidden restrictions', () => {
  assert.deepEqual(policy({source:'open',officialEvent:42}), {audience:'open',operator:'all',criteria:[],official_event_id:42});
});
test('challenge uses confirmed enrollment rather than achievements', () => {
  assert.deepEqual(policy({source:'challenge',reference:'todosantodia'}).criteria,[{type:'challenge',code:'todosantodia',confirmed_only:true}]);
});
test('circuit subscription does not require race results', () => {
  assert.deepEqual(policy({source:'circuit',reference:'circuitobrasilgigante'}).criteria,[{type:'challenge',code:'circuitobrasilgigante',confirmed_only:true}]);
});
test('training uses the actual roster, not the calendar', () => {
  assert.deepEqual(policy({source:'training',reference:'41703'}).criteria,[{type:'event_registration',event_ids:[41703],training_only:true}]);
});
test('event association is independent of enrollment rule', () => {
  const p=policy({source:'event',reference:'41703',officialEvent:'41703'});
  assert.equal(p.official_event_id,41703);
  assert.deepEqual(p.criteria,[{type:'event_registration',event_ids:[41703],training_only:false}]);
});
test('circuit stages use enrollment rather than finishing results', () => {
  assert.deepEqual(policy({source:'circuit_stages',reference:'brasil-gigante'}).criteria,[{type:'circuit_registration',aggregator_tag:'brasil-gigante'}]);
});
test('legacy compound policies are preserved', () => {
  const legacy={operator:'all',criteria:[{type:'challenge',code:'circuitobrasilgigante'},{type:'validated_result',aggregator_tag:'brasil-gigante',distance:42,min_count:1}]};
  assert.deepEqual(policy({source:'advanced',legacy}).criteria,legacy.criteria);
});
test('missing and malformed event IDs cannot produce an empty audience rule', () => {
  assert.throws(()=>policy({source:'event',reference:''}),/Selecione/);
  assert.throws(()=>policy({source:'training',reference:'1 OR true'}),/Selecione/);
});
test('list search combines mode and status filters', () => {
  assert.ok(manager, 'community filters are not implemented');
  const c={nome:'Canal do Corre Supra',modo:'channel',status:'active'};
  assert.equal(manager.matchesCommunity(c,{term:'SUPRA',mode:'channel',status:'active'}),true);
  assert.equal(manager.matchesCommunity(c,{term:'Supra',mode:'chat',status:'active'}),false);
  assert.equal(manager.matchesCommunity(c,{term:'Supra',mode:'channel',status:'paused'}),false);
});
