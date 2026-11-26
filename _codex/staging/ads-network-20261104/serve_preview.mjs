import http from 'node:http';import {readFileSync} from 'node:fs';
const server=http.createServer((req,res)=>{const name=req.url.split('?')[0];if(!['/sites.html','/spots.html','/install.html'].includes(name)){res.writeHead(404);return res.end();}res.setHeader('Content-Type','text/html; charset=utf-8');res.end(readFileSync(new URL('./preview'+name,import.meta.url)));});
server.listen(0,'127.0.0.1',()=>console.log(JSON.stringify({pid:process.pid,started:new Date().toISOString(),port:server.address().port})));
for(const sig of ['SIGTERM','SIGINT'])process.on(sig,()=>server.close(()=>process.exit(0)));
