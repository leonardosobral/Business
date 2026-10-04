// Focused process-boundary tests. Every helper cleanup targets a recorded private fixture cluster/PID.
import assert from 'node:assert/strict';
import {mkdtempSync,mkdirSync,symlinkSync,writeFileSync,readFileSync,existsSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawn,spawnSync} from 'node:child_process';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'../../..');
const realBin=process.env.BUSINESS_DELEGATION_PG_BIN||'/opt/homebrew/opt/postgresql@16/bin';
const scratch=mkdtempSync(resolve(tmpdir(),'delegation-cleanup-check-'));
const alive=pid=>{try{process.kill(pid,0);return true;}catch{return false;}};
const delay=ms=>new Promise(done=>setTimeout(done,ms));
async function until(check,label){for(let i=0;i<300;i++){if(check())return;await delay(50);}throw Error(label);}
async function scenario(mode,signal){
 const bin=resolve(scratch,mode);mkdirSync(bin);const trace=resolve(bin,'owned.json');
 for(const executable of ['initdb','createdb','psql'])symlinkSync(resolve(realBin,executable),resolve(bin,executable));
 writeFileSync(resolve(bin,'pg_ctl'),`#!${process.execPath}
 const {spawnSync}=require('node:child_process'); const {readFileSync,writeFileSync}=require('node:fs');
 const args=process.argv.slice(2),data=args[args.indexOf('-D')+1];
 if(${JSON.stringify(mode)}==='shutdown-failure'&&args.includes('stop'))process.exit(94);
 const result=spawnSync(${JSON.stringify(resolve(realBin,'pg_ctl'))},args,{encoding:'utf8'});
 process.stdout.write(result.stdout||'');process.stderr.write(result.stderr||'');
 if(args.includes('start')&&result.status===0){const lines=readFileSync(data+'/postmaster.pid','utf8').split('\\n');writeFileSync(${JSON.stringify(trace)},JSON.stringify({data,pid:Number(lines[0]),port:Number(lines[3]),socket:lines[4]}));if(!${JSON.stringify(mode)}.startsWith('interrupt'))process.exit(93);}
 process.exit(result.status??1);
 `,{mode:0o700});
 let output='',owned,javaPids=[];
 const child=spawn(process.execPath,[resolve(root,'_codex/scripts/test_account_delegation.mjs'),'--suite','schema'],{cwd:root,env:{...process.env,BUSINESS_DELEGATION_PG_BIN:bin},stdio:['ignore','pipe','pipe']});
 child.stdout.on('data',chunk=>output+=chunk);child.stderr.on('data',chunk=>output+=chunk);
 const completed=new Promise(done=>child.on('close',(code,termSignal)=>done({code,termSignal})));
 try {
  await until(()=>existsSync(trace),'owned cluster never started');owned=JSON.parse(readFileSync(trace,'utf8'));
  if(signal){
   await until(()=>output.includes('PASS schema SQL'),'schema setup did not reach CFML');
   await until(()=>{const ps=spawnSync('/usr/bin/pgrep',['-P',String(child.pid)],{encoding:'utf8'});javaPids=ps.stdout.trim().split(/\s+/).filter(Boolean).map(Number);return javaPids.length>0;},'CFML JVM did not start');
   child.kill(signal);
  }
  const result=await Promise.race([completed,new Promise((_,reject)=>{const timer=setTimeout(()=>reject(Error('harness did not exit')),20000);timer.unref();})]);
  if(mode==='shutdown-failure'){
   assert.equal(result.code,1);assert.equal(alive(owned.pid),true);assert.equal(existsSync(owned.data+'/postmaster.pid'),true);
   assert.match(output,/Cleanup failed; inspect/);assert.equal(existsSync(resolve(owned.data,'../postgres.log')),true);
   console.log('PASS failed shutdown preserves private cluster diagnostics (PID '+owned.pid+', '+owned.data+')');
  }else{
   assert.equal(alive(owned.pid),false,'owned PostgreSQL survived '+mode+' '+signal);
   assert.equal(result.code,signal==='SIGINT'?130:signal==='SIGTERM'?143:1,output);
   assert.equal(existsSync(resolve(owned.socket,'.s.PGSQL.'+owned.port)),false,'owned socket survived');
   for(const pid of javaPids)assert.equal(alive(pid),false,'owned CFML JVM survived interruption');
   console.log((signal?'PASS '+signal+' during real CFML stops owned JVM/PID/socket':'PASS failed start acknowledgement stops privately owned cluster')+' (PID '+owned.pid+', socket '+resolve(owned.socket,'.s.PGSQL.'+owned.port)+')');
  }
 }finally{
  if(alive(child.pid)){child.kill('SIGKILL');await completed;}
  for(const pid of javaPids)if(alive(pid))process.kill(pid,'SIGTERM');
  if(owned&&alive(owned.pid))spawnSync(resolve(realBin,'pg_ctl'),['-D',owned.data,'-m','fast','-w','stop'],{encoding:'utf8',timeout:30000});
  if(owned&&!alive(owned.pid))rmSync(resolve(owned.data,'..'),{recursive:true,force:true});
 }
}
try{await scenario('interrupt','SIGTERM');await scenario('interrupt-int','SIGINT');await scenario('failed-start');await scenario('shutdown-failure');}
finally{rmSync(scratch,{recursive:true,force:true});}
