from pathlib import Path
import collections,json,os,re,shutil,subprocess,tempfile
work=Path(tempfile.mkdtemp(prefix='cron-thread-diag-',dir='/var/tmp'))
try:
 (work/'Dump.java').write_text('import com.sun.tools.attach.VirtualMachine; import sun.tools.attach.HotSpotVirtualMachine; public class Dump { public static void main(String[] a) throws Exception { VirtualMachine v=VirtualMachine.attach(a[0]); try { ((HotSpotVirtualMachine)v).executeJCmd("Thread.print").transferTo(System.out); } finally {v.detach();} } }')
 cmd=['/opt/coldfusion2025/jre/bin/java','--add-exports','jdk.attach/sun.tools.attach=ALL-UNNAMED',str(work/'Dump.java'),'5563']
 p=subprocess.run(cmd,capture_output=True,text=True,timeout=25)
 blocks=re.split(r'(?m)^"',p.stdout)
 groups=collections.Counter();cf=[]
 for b in blocks:
  if 'ajp-' not in b[:180]:continue
  frames=[l.strip() for l in b.splitlines() if l.strip().startswith('at ')];groups[tuple(frames[:8])]+=1
  cf.extend(l for l in frames if '/var/www/' in l)
 print(json.dumps({'acceptor_blocks':[b[:6000] for b in blocks if 'Acceptor' in b or 'acceptor' in b],'rc':p.returncode,'stderr':p.stderr[:1000],'thread_groups':[{'count':n,'top_stack':list(k)} for k,n in groups.most_common(8)],'cf_frames':dict(collections.Counter(cf).most_common(20))},indent=2))
finally:shutil.rmtree(work)
