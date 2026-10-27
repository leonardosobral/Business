import {createRequire} from 'node:module';
import {readFile,writeFile} from 'node:fs/promises';
import path from 'node:path';
const require=createRequire(import.meta.url);
const esbuild=require(process.argv[3] || '/private/tmp/rr-regionais-pace-tools/node_modules/esbuild');
if(esbuild.version!=='0.28.2')throw new Error('Use esbuild 0.28.2');
const root=process.argv[2];if(!root)throw new Error('Usage: node build.mjs <source root> [esbuild package]');
for(const name of ['assets/js/runnerhub-event-filters.js','assets/js/runnerhub-estado-cidades.js','assets/js/runnerhub-regional-period.js','assets/css/runnerhub-regionais.css']){
 const input=await readFile(path.join(root,name),'utf8'),loader=path.extname(name).slice(1);
 const options={loader,minifyWhitespace:true,minifyIdentifiers:false,minifySyntax:false,legalComments:'inline',...(loader==='js'?{target:'es2017'}:{})};
 const result=await esbuild.transform(input,options);
 if(result.warnings.length)throw new Error(JSON.stringify(result.warnings));
 await writeFile(path.join(root,name.replace(/\.(js|css)$/,'.min.$1')),result.code);
 console.log(name+': '+Buffer.byteLength(input)+' → '+Buffer.byteLength(result.code)+' bytes');
}
