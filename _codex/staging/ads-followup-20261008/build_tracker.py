from pathlib import Path
import hashlib
p=Path(__file__).parent;c=p/'candidate/RoadRunners';s=(p/'baseline/rr-audience.js').read_text()
s=s.replace('var visitor, session;','var visitor, session;\n    var googleLiveClicks = new Set();')
anchor="            emit('outbound_click', 'live_registration:' + id, { contentType: 'event', contentId: id });\n            flush();"
assert s.count(anchor)==1
s=s.replace(anchor,"""            emit('outbound_click', 'live_registration:' + id, { contentType: 'event', contentId: id });
            // The partner checkout is untracked: this is an outbound intent, never a purchase.
            // Existing gtag owns consent and transport. Do not load another Google tag or send URLs/identities.
            var googleKey = session.id + ':' + id;
            if (config.context.environment === 'prod' && config.context.isInternal === false
                && typeof window.gtag === 'function' && !googleLiveClicks.has(googleKey)) {
                try {
                    window.gtag('event', 'rr_live_registration_outbound', { send_to: 'G-7MYGVTEDZV', transport_type: 'beacon' });
                    googleLiveClicks.add(googleKey);
                } catch (_) { /* Google failure must not interrupt navigation or first-party measurement. */ }
            }
            flush();""")
t=c/'assets/js/rr-audience.js';t.parent.mkdir(parents=True,exist_ok=True);t.write_text(s)
h=hashlib.sha256(s.encode()).hexdigest()[:12]
s=(p/'baseline/bootstrap.cfm').read_text();import re
s,n=re.subn(r'/assets/js/rr-audience.js\?v=[a-zA-Z0-9]+','/assets/js/rr-audience.js?v='+h,s);assert n==1
t=c/'includes/analytics/bootstrap.cfm';t.parent.mkdir(parents=True,exist_ok=True);t.write_text(s)
test=Path('../RoadRunners/_codex/tests/audience-live-registration.test.js').read_text().replace("path.resolve(__dirname, '../../assets/js/rr-audience.js')","path.resolve(__dirname, 'candidate/RoadRunners/assets/js/rr-audience.js')")
test+='''
function googleHarness(options={}) { const h=harness(options); h.calls=[]; h.win.gtag=(...args)=>h.calls.push(args); Object.assign(h.win.RoadRunnersAudienceConfig.context,{environment:'prod',isInternal:false}); return h; }
test('Google gets one non-monetary intent per race/session while first-party transport stays intact',()=>{
 const h=googleHarness();h.run();click(h,registration());click(h,registration());
 assert.equal(h.calls.length,1);assert.equal(h.calls[0][1],'rr_live_registration_outbound');
 assert.deepEqual(JSON.parse(JSON.stringify(h.calls[0][2])),{send_to:'G-7MYGVTEDZV',transport_type:'beacon'});
 assert.equal(outbound(h).length,1);click(h,registration('305'));assert.equal(h.calls.length,2);
});
test('Google excludes beta/internal/refused/invalid clicks and its failures do not break collection',()=>{
 for(const options of [{gpc:true},{storage:{'rr-audience-opt-out':'1'}}]){const h=googleHarness(options);h.run();click(h,registration());assert.equal(h.calls.length,0);}
 for(const config of [{environment:'beta'},{isInternal:true}]){const h=googleHarness();Object.assign(h.win.RoadRunnersAudienceConfig.context,config);h.run();click(h,registration());assert.equal(h.calls.length,0);}
 const h=googleHarness();h.run();click(h,registration('3','https://evil.test/'));assert.equal(h.calls.length,0);
 h.event('rr-audience-preference',{detail:{allowed:false}});click(h,registration());assert.equal(h.calls.length,0);
 const bad=googleHarness();bad.win.gtag=()=>{throw Error('blocked')};bad.run();assert.doesNotThrow(()=>click(bad,registration()));assert.equal(outbound(bad).length,1);
});
'''
(p/'tracker.test.cjs').write_text(test)
print('Tracker and bootstrap candidates ready')
