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
test('guest input accepts a pasted list, normalizes and deduplicates without silently losing invalid addresses', () => {
  assert.deepEqual(M.parseGuests('Ana <ANA@example.com>; bob@example.com\nana@example.com'), ['ana@example.com','bob@example.com']);
  assert.throws(()=>M.parseGuests('ana@example.com, inválido'), /inválido/i);
  assert.throws(()=>M.parseGuests('a@@example.com'), /inválido/i);
  assert.throws(()=>M.parseGuests(Array.from({length:101},(_,i)=>`p${i}@example.com`).join(',')), /100/);
});
test('meeting links are HTTPS only and prefer video entry points over legacy hangoutLink', () => {
  assert.equal(M.meeting({conferenceData:{entryPoints:[{entryPointType:'phone',uri:'tel:123'},{entryPointType:'video',uri:'https://meet.google.com/abc-defg-hij'}]},hangoutLink:'https://meet.google.com/other'}),'https://meet.google.com/abc-defg-hij');
  assert.equal(M.meeting({hangoutLink:'javascript:alert(1)'}),'');
  assert.equal(M.meeting({location:'https://meet.google.com/abc-defg-hij'}),'https://meet.google.com/abc-defg-hij');
  assert.equal(M.meeting({location:'https://example.com/venue'}),'');
  assert.equal(M.https('https://user:password@example.com/'), '');
});
test('RSVP counts exclude organizers and label unknown responses as pending', () => {
  assert.deepEqual(M.responses([{email:'host@example.com',organizer:true,responseStatus:'accepted'},{email:'a@example.com',responseStatus:'accepted'},{email:'b@example.com',responseStatus:'tentative'},{email:'c@example.com',responseStatus:'declined'},{email:'d@example.com',responseStatus:'new'}]), {total:4,accepted:1,tentative:1,declined:1,needsAction:1});
});
test('duration respects exclusive all-day ends and search includes guests and organizer', () => {
  assert.equal(M.duration({start:{date:'2026-10-10'},end:{date:'2026-10-12'}}),'2 dias');
  assert.equal(M.duration({start:{dateTime:'2026-10-10T09:00:00-03:00'},end:{dateTime:'2026-10-10T10:30:00-03:00'}}),'1h 30min');
  assert.equal(M.matches({summary:'Reunião',attendees:[{email:'ana@example.com',displayName:'Ana'}]},'ana@example'),true);
  assert.equal(M.matches({organizer:{email:'host@example.com'}},'host@'),true);
});
