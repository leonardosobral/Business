const test=require('node:test');const assert=require('node:assert/strict');
const path=require('node:path');
const menu=require(process.env.MENU_MODULE || path.resolve(__dirname,'../../../assets/js/business-sidenav.js'));
function fixture(open=false){
 const attributes=new Map();const submenu={open,hasAttribute:k=>attributes.has(k),getAttribute:k=>attributes.get(k),setAttribute:(k,v)=>attributes.set(k,v),removeAttribute:k=>attributes.delete(k)};
 const links=[{textContent:'Comparador',getAttribute:()=>''},{textContent:'Filtros e cadastros',getAttribute:()=> 'comparador marcas categorias'}];
 return {submenu,item:{querySelectorAll:()=>links,querySelector:()=>submenu}};
}
test('search reaches nested catalog links and opens their parent',()=>{const {submenu,item}=fixture();assert.equal(menu.updateSearch(item,'marcas',menu.matchesMenuItem),true);assert.equal(submenu.open,true);});
test('clearing search restores collapsed state without hiding destinations permanently',()=>{const {submenu,item}=fixture();menu.updateSearch(item,'marcas',menu.matchesMenuItem);assert.equal(menu.updateSearch(item,'',menu.matchesMenuItem),true);assert.equal(submenu.open,false);});
test('nonmatching search hides the group and restores an already open group afterwards',()=>{const {submenu,item}=fixture(true);assert.equal(menu.updateSearch(item,'financeiro',menu.matchesMenuItem),false);assert.equal(submenu.open,false);menu.updateSearch(item,'',menu.matchesMenuItem);assert.equal(submenu.open,true);});
