import fs from 'node:fs/promises';
import path from 'node:path';
import { createRequire } from 'node:module';
import { createHash } from 'node:crypto';
const root=path.dirname(new URL(import.meta.url).pathname);
const esbuild=createRequire(import.meta.url)('/private/tmp/rr-seo-assets-20261008-tools/node_modules/esbuild');
const build=JSON.parse(await fs.readFile(path.join(root,'build.json'),'utf8'));
const selected=build.files.filter(f=>['rr-audience.js','runnerhub-home.css','runnerhub-estado-cidades.css','runnerhub-state-filter.js','runnerhub-estado-cidades.js'].includes(path.basename(f.source)));
const checks=[];
for(const f of selected){
 const source=await fs.readFile(path.join(root,'baseline','rr',f.source),'utf8');
 const output=await fs.readFile(path.join(root,'candidate','rr',f.target),'utf8');
 const loader=path.extname(f.source).slice(1);
 const options={loader,charset:'utf8',legalComments:'inline',minifyWhitespace:true,minifyIdentifiers:false,minifySyntax:false,...(loader==='js'?{target:'es2017'}:{})};
 const original=await esbuild.transform(source,options);
 const generated=await esbuild.transform(output,options);
 if(original.code!==generated.code)throw new Error('Parsed program differs: '+f.source);
 if(original.warnings.length||generated.warnings.length)throw new Error('Compiler warnings: '+f.source);
 if(Buffer.byteLength(output)>=Buffer.byteLength(source))throw new Error('No size reduction: '+f.source);
 checks.push({source:f.source,normalized_program_equal:true,bytes_reduced:f.before_bytes-f.after_bytes});
}
const hashes={};
for(const f of selected){hashes[f.target]=createHash('sha256').update(await fs.readFile(path.join(root,'candidate','rr',f.target))).digest('hex');}
const receipt={esbuild:esbuild.version,checks,hashes};
await fs.writeFile(path.join(root,'build-passed.json'),JSON.stringify(receipt,null,2));
console.log(JSON.stringify({normalized_program_checks:checks.length,bytes_reduced:checks.reduce((a,b)=>a+b.bytes_reduced,0)}));
