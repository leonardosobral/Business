const test=require('node:test');const assert=require('node:assert/strict');const vm=require('node:vm');const fs=require('node:fs');
function setup(){
 const make=(value='')=>({value,textContent:'',hidden:false,disabled:false,listeners:{},classList:{toggle(){}},addEventListener(n,fn){this.listeners[n]=fn;},dispatchEvent(event){this.listeners[event.type]?.(event);form.listeners[event.type]?.(event);},focus(){},setAttribute(){},removeAttribute(){},querySelectorAll(){return [];}});
 const form=make(),editor=make('Rascunho atual'),feedback=make(),count=make(),picker=make('custom'),mode=make('publica'),noteButton=make(),replyButton=make();picker.selectedOptions=[{dataset:{text:'Modelo editado\nLinha 2'}}];
 const title=make(),visibility=make(),publicPanel=make();publicPanel.querySelectorAll=()=>[replyButton];
 const selectors={'[name="ticket_mensagem"]':editor,'[data-hd-feedback]':feedback,'[data-hd-count]':count,'[data-hd-template]':picker,'[data-hd-insert]':make(),'[name="message_kind"]:checked':mode,'[data-hd-note-button]':noteButton,'[data-hd-editor-title]':title,'[data-hd-visibility]':visibility};
 form.querySelector=s=>selectors[s];form.querySelectorAll=s=>s==='[data-hd-public-panel]'?[publicPanel]:[];
 const doc={querySelector:s=>s==='[data-hd-reply]'?form:null,querySelectorAll:()=>[]};const win={addEventListener(){},confirm(){return true;}};
 vm.runInNewContext(fs.readFileSync('helpdesk/assets/workspace.js','utf8'),{document:doc,window:win,Event:class{constructor(type){this.type=type;}}});
 return {form,editor,feedback,mode,noteButton,replyButton,publicPanel,insert:selectors['[data-hd-insert]']};
}
test('insere modelo editável sem substituir rascunho nem enviar',()=>{const s=setup();s.insert.listeners.click();assert.equal(s.editor.value,'Rascunho atual\n\nModelo editado\nLinha 2');assert.match(s.feedback.textContent,/Revise/);});
test('modo interno oculta e desabilita envio público',()=>{const s=setup();s.mode.value='nota';s.form.listeners.change();assert.equal(s.publicPanel.hidden,true);assert.equal(s.replyButton.disabled,true);assert.equal(s.noteButton.disabled,false);});
test('modo interno bloqueia submit público mesmo por Enter',()=>{const s=setup();s.mode.value='nota';let prevented=false;s.form.listeners.submit({submitter:{value:'responder_ticket'},preventDefault(){prevented=true;}});assert.equal(prevented,true);});
test('modelo grande não destrói rascunho',()=>{const s=setup();s.editor.value='x'.repeat(12000);s.insert.listeners.click();assert.equal(s.editor.value.length,12000);assert.match(s.feedback.textContent,/12.000/);});
