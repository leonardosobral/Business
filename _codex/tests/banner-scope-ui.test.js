const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
test('scope selection requires an item; ALL permits empty values', () => {
 const file = path.resolve(__dirname, '../../assets/js/portal-banners.js');
 assert.ok(fs.existsSync(file), 'banner UI behavior is available');
 const ui = require(file);
 assert.equal(ui.selectionValid('SELECTED', []), false);
 assert.equal(ui.selectionValid('SELECTED', ['SC']), true);
 assert.equal(ui.selectionValid('ALL', []), true);
 assert.equal(ui.selectionValid('broken', ['SC']), false);
});
test('preview reports real decoded dimensions and releases object URLs', async () => {
 const ui = require('../../assets/js/portal-banners.js');
 const released=[];
 const result=await ui.inspectPreview({size:42}, {createObjectURL:()=> 'blob:preview',revokeObjectURL:u=>released.push(u)}, async url => ({width:300,height:250}));
 assert.deepEqual(result, {url:'blob:preview',width:300,height:250});
 await assert.rejects(ui.inspectPreview({size:11*1024*1024}, {}, async()=>({})), /10 MiB/);
 await assert.rejects(ui.inspectPreview({size:1}, {createObjectURL:()=> 'blob:bad',revokeObjectURL:u=>released.push(u)}, async()=>({width:10000,height:10000})), /40 megapixels/);
 assert.deepEqual(released,['blob:bad']);
});
test('clearing file input restores the saved image preview', async () => {
 const ui=require('../../assets/js/portal-banners.js');
 const handlers={};
 const input={dataset:{bannerUpload:'desktop'},files:[],setCustomValidity(){},addEventListener:(type,cb)=>handlers[type]=cb};
 const preview={src:'https://example.org/saved.png',hidden:false};
 const mode={value:'ALL',setCustomValidity(){},addEventListener(){}};
 const form={elements:{banner_pages_mode:mode,banner_regions_mode:mode},querySelectorAll:selector=>selector==='[data-banner-upload]'?[input]:[],querySelector:selector=>selector.includes('preview')?preview:{}};
 ui.init(form);
 preview.src='blob:previous';
 await handlers.change();
 assert.equal(preview.src,'https://example.org/saved.png');
 assert.equal(preview.hidden,false);
});
