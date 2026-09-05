const test = require('node:test');
const assert = require('node:assert/strict');
const M = require('../../administracao/agenda/assets/calendar-model.js');

test('month grid includes complete Monday–Sunday weeks, including adjacent months', () => {
  assert.deepEqual(M.range('2026-09-05','month'), {from:'2026-08-31',until:'2026-10-05'});
  assert.deepEqual(M.range('2021-02-12','month'), {from:'2021-02-01',until:'2021-03-01'});
});
test('week and list boundaries handle year transitions and leap years', () => {
  assert.deepEqual(M.range('2027-01-01','week'), {from:'2026-12-28',until:'2027-01-04'});
  assert.deepEqual(M.range('2024-02-29','list'), {from:'2024-02-01',until:'2024-03-01'});
  assert.equal(M.move('2026-01-31','month',1),'2026-02-01');
});
test('all-day end is exclusive and spans multiple days without timezone conversion', () => {
  const e={start:{date:'2026-09-05'},end:{date:'2026-09-07'}};
  assert.equal(M.onDay(e,'2026-09-04'),false);
  assert.equal(M.onDay(e,'2026-09-05'),true);
  assert.equal(M.onDay(e,'2026-09-06'),true);
  assert.equal(M.onDay(e,'2026-09-07'),false);
});
test('timed events use Brasília regardless of the browser timezone, with midnight-exclusive end', () => {
  const e={start:{dateTime:'2026-09-06T01:00:00Z'},end:{dateTime:'2026-09-06T03:00:00Z'}};
  assert.equal(M.local(e.start.dateTime),'2026-09-05T22:00');
  assert.equal(M.onDay(e,'2026-09-05'),true);
  assert.equal(M.onDay(e,'2026-09-06'),false);
  assert.equal(M.onDay({...e,status:'cancelled'},'2026-09-05'),false);
});
test('historical timezone offsets are resolved by the IANA timezone', () => {
  assert.equal(M.local('2018-12-01T12:00:00Z'),'2018-12-01T10:00');
  assert.equal(M.local('2026-12-01T12:00:00Z'),'2026-12-01T09:00');
});
