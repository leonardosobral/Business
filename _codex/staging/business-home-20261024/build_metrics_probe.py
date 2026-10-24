"""Build a loopback-only probe from the current four exact SQL blocks. No network."""
from pathlib import Path
import base64
import hashlib
import json
import re

stage = Path(__file__).resolve().parent
source = (stage.parents[2] / 'includes/backend/business_home_metrics.cfm').read_text()
queries = {}
for name in ('audience', 'ads', 'accounts', 'users'):
    pattern = (r'// BEGIN ' + name.upper() + r' SQL\s+VARIABLES\.businessHomeSql\.'
               + name + r' = "(.*?)";\s*// END ' + name.upper() + r' SQL')
    match = re.search(pattern, source, re.S)
    if not match:
        raise SystemExit('SQL block not found: ' + name)
    queries[name] = match.group(1)
encoded = base64.b64encode(json.dumps(queries).encode()).decode()
body = '''<cfsetting showdebugoutput="false" requesttimeout="55"/><cfcontent type="application/json" reset="true"/><cfscript>
report={periods=[]};queries=deserializeJSON(toString(binaryDecode("ENCODED","base64")));opts={datasource="runnerhub",timeout=5};
for(days in [7,30]){
 period={days=days,sources={}};
 params={days={value=days,cfsqltype="cf_sql_integer"}};
 for(sourceName in ["audience","ads","accounts","users"]){
  started=getTickCount();item={loaded=false};
  try {
   transaction {
    queryExecute("SET TRANSACTION READ ONLY",{},opts);
    queryExecute("SET LOCAL statement_timeout='5s'",{},opts);
    q=queryExecute(queries[sourceName],params,opts);
    item.loaded=q.recordCount==1;if(item.loaded)item.metrics=queryGetRow(q,1);
   }
  }catch(any e){item.error_type=e.type;if(structKeyExists(e,"sqlState"))item.sqlstate=e.sqlState;}
  item.elapsed_ms=getTickCount()-started;period.sources[sourceName]=item;
 }
 arrayAppend(report.periods,period);
}
writeOutput(serializeJSON(report));</cfscript>'''.replace('ENCODED', encoded)
base = (stage / 'probe_schema_remote.py').read_text()
start = base.index("body = '''")
end = base.index('\ntry:\n', start)
base = base[:start] + 'body = ' + repr(body) + base[end:]
base = base.replace("prefix='business-home-schema-'", "prefix='business-home-metrics-'")
base = base.replace("'23'", "'53'").replace('timeout=26', 'timeout=56')
source_sha = hashlib.sha256(source.encode()).hexdigest()
base = base.replace('report.update(read_only=True, runtime_files_changed=False)',
    'report.update(read_only=True, runtime_files_changed=False, source_sha256='
    + repr(source_sha) + ', cache_disabled=True)')
(stage / 'probe_metrics_current_remote.py').write_text(base)
print(json.dumps({'source_sha256': source_sha, 'sources': list(queries)}))
