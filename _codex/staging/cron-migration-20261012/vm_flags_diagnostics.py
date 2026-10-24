from pathlib import Path
import collections,json,os,re,shutil,subprocess,tempfile
work=Path(tempfile.mkdtemp(prefix='cron-thread-diag-',dir='/var/tmp'))
try:
 (work/'Dump.java').write_text('import com.sun.tools.attach.VirtualMachine; import sun.tools.attach.HotSpotVirtualMachine; public class Dump { public static void main(String[] a) throws Exception { VirtualMachine v=VirtualMachine.attach(a[0]); try { ((HotSpotVirtualMachine)v).executeJCmd(a[1]).transferTo(System.out); } finally {v.detach();} } }')
 cmd=['/opt/coldfusion2025/jre/bin/java','--add-exports','jdk.attach/sun.tools.attach=ALL-UNNAMED',str(work/'Dump.java'),'5563','VM.flags']
 p=subprocess.run(cmd,capture_output=True,text=True,timeout=25)
 print(json.dumps({'rc':p.returncode,'stdout':p.stdout,'stderr':p.stderr[:500]},indent=2))
finally:shutil.rmtree(work)
