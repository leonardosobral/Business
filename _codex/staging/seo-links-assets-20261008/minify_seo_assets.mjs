// Build-only tool; source files remain authoritative. Never publish this script.
import fs from 'node:fs/promises';
import path from 'node:path';
import {createRequire} from 'node:module';
import {createHash} from 'node:crypto';
const args=process.argv.slice(2);
if(args.length!==3) throw new Error('Usage: node minify_seo_assets.mjs <source-root> <output-root> <esbuild-package-path>');
const [sourceRoot,outputRoot,packagePath]=args.map(p=>path.resolve(p));
const esbuild=createRequire(import.meta.url)(packagePath);
if(esbuild.version!=='0.28.2') throw new Error('Use pinned esbuild 0.28.2');
const inputs=['assets/css/cores.css','assets/css/rr-audience-privacy.css','assets/css/runnerhub-footer.css','assets/js/rr-audience-privacy.js','assets/js/runnerhub-entry-prompts.js','assets/js/runner-apps-menu-lazy.js','assets/js/runnerhub-event-filters.js','assets/js/runnerhub-busca-page.js','assets/js/event-location-mapbox.js','assets/js/event-route-mapbox.js','assets/css/runnerhub-institutional.css','assets/css/event-location-mapbox.css','assets/css/event-route-mapbox.css','assets/js/rr-audience.js','assets/css/runnerhub-home.css','assets/css/runnerhub-estado-cidades.css','assets/js/runnerhub-state-filter.js','assets/js/runnerhub-estado-cidades.js'];
const manifest=[];
const sha=t=>createHash('sha256').update(t).digest('hex');
for(const source of inputs){
 const original=await fs.readFile(path.join(sourceRoot,source),'utf8');
 const loader=path.extname(source).slice(1);
 const options={loader,charset:'utf8',legalComments:'inline',minifyIdentifiers:false,minifySyntax:false,...(loader==='js'?{target:'es2017'}:{})};
 const result=await esbuild.transform(original,{...options,minifyWhitespace:true});
 if(result.warnings.length) throw new Error(source+': '+JSON.stringify(result.warnings));
 // Check stable compiler roundtrip; validate behavior with the existing fixtures before release.
 const before=await esbuild.transform(original,{...options,minifyWhitespace:true});
 const after=await esbuild.transform(result.code,{...options,minifyWhitespace:true});
 if(before.code!==after.code) throw new Error(source+': compiler roundtrip changed');
 const target=source.replace(/\.(css|js)$/,'.min.$1');
 await fs.mkdir(path.dirname(path.join(outputRoot,target)),{recursive:true});
 await fs.writeFile(path.join(outputRoot,target),result.code);
 manifest.push({source,target,source_sha256:sha(original),output_sha256:sha(result.code),before_bytes:Buffer.byteLength(original),after_bytes:Buffer.byteLength(result.code),compiler_roundtrip_stable:true});
}
console.log(JSON.stringify({esbuild:esbuild.version,options:'whitespace only; identifiers and syntax preserved',files:manifest},null,2));
