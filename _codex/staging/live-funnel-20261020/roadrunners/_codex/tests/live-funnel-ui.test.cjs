const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const script = path.resolve(__dirname, '../../assets/js/rr-live-funnel-ui.js');
function harness(writeText) {
    const listeners = {}, events = [], status = {textContent: ''};
    const input = {value:'ROADRUNNERS', selected:false, focus(){}, select(){this.selected=true;}, setSelectionRange(){this.selected=true;}};
    const section = {querySelector: selector => selector === '[data-live-coupon-code]' ? input : status};
    const button = {hidden:true, disabled:false, dataset:{liveCouponCopy:'304'}, closest:()=>section};
    const cards = ['campinas-sp','campinas-mg','rio-de-janeiro-rj'].map(city => ({dataset:{liveCity:city},hidden:false}));
    const count = {textContent:''};
    const filter = {value:'',matches:selector=>selector==='[data-live-city-select]',options:[{value:''},{value:'campinas-sp'},{value:'campinas-mg'},{value:'rio-de-janeiro-rj'}]};
    const controls = {hidden:true};
    const browser = {querySelector(selector){return {'[data-live-city-select]':filter,'[data-live-city-controls]':controls,'[data-live-city-count]':count}[selector];},querySelectorAll(){return cards;}};
    filter.closest=()=>browser;
    const document = {readyState:'complete',querySelectorAll(selector){return selector === '[data-live-coupon-copy]' ? [button] : [browser];},addEventListener(type,cb){listeners[type]=cb;},dispatchEvent(event){events.push(event.detail);}};
    const window = {dispatchEvent:event=>events.push(event.detail),navigator: writeText ? {clipboard:{writeText}} : {},CustomEvent:class {constructor(type,options){this.type=type;this.detail=options.detail;}}};
    if(fs.existsSync(script)) vm.runInNewContext(fs.readFileSync(script,'utf8'),{window,document});
    return {button,input,status,cards,count,filter,controls,events,click:()=>listeners.click?.({target:{closest:()=>button}}),change:()=>listeners.change?.({target:filter})};
}
test('copy waits for clipboard success and reports the event identity without the code',async()=>{
    let resolve; const h=harness(()=>new Promise(r=>resolve=r));
    h.click(); assert.equal(h.button.disabled,true); assert.equal(h.events.length,0);
    resolve(); await new Promise(setImmediate);
    assert.match(h.status.textContent,/copiado/i); assert.equal(h.button.disabled,false);
    assert.deepEqual(JSON.parse(JSON.stringify(h.events)),[{action:'coupon_copy_success',eventId:'304'}]);
});
test('clipboard rejection or unavailable API selects the existing code and permits retry',async()=>{
    for(const writer of [undefined,()=>Promise.reject(new Error('blocked')),()=>{throw new Error('blocked');}]){
        const h=harness(writer); h.click(); await new Promise(setImmediate);
        assert.equal(h.input.selected,true); assert.equal(h.button.disabled,false);
        assert.match(h.status.textContent,/copie/i);
        assert.deepEqual(JSON.parse(JSON.stringify(h.events)),[{action:'coupon_copy_error',eventId:'304'}]);
    }
});
test('all cities start visible; choosing a city distinguishes homonyms and All restores the full list',()=>{
    const h=harness(); assert.equal(h.controls.hidden,false); assert.equal(h.cards.filter(c=>!c.hidden).length,3); assert.equal(h.events.length,0);
    h.filter.value='campinas-mg'; h.change();
    assert.deepEqual(h.cards.map(c=>c.hidden),[true,false,true]); assert.match(h.count.textContent,/1/);
    h.filter.value=''; h.change(); assert.equal(h.cards.filter(c=>!c.hidden).length,3);
    assert.deepEqual(JSON.parse(JSON.stringify(h.events)),[{action:'city_select',citySlug:'campinas-mg'},{action:'city_select',citySlug:'all'}]);
});
