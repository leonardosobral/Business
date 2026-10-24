from pathlib import Path
import re,difflib,hashlib,json
base=Path(__file__).parent/'news-source'
source=base/'baseline'
candidate=base/'candidate'
helper='''  public boolean function relationExists(required string schemaName, required string relationName, struct opts = {}) {
    var lookup = q("
      SELECT to_regclass(quote_ident(:schema_name) || '.' || quote_ident(:relation_name)) IS NOT NULL AS found
    ", {
      schema_name = {value=arguments.schemaName, cfsqltype="cf_sql_varchar"},
      relation_name = {value=arguments.relationName, cfsqltype="cf_sql_varchar"}
    }, arguments.opts);
    return lookup.found[1];
  }

'''
s=(source/'inc/db.cfc').read_text()
assert s.count('  public boolean function columnExists')==1
(candidate/'inc/db.cfc').write_text(s.replace('  public boolean function columnExists',helper+'  public boolean function columnExists'))
expected={'inc/content_local_config.cfc':1,'inc/sixcomm_email_importer.cfc':2,'admin/importer_sixcomm_email.cfm':1,'admin/importer_contrarelogio.cfm':3,'admin/importer_corridanoar.cfm':4,'admin/importer_cbat_corridaderua.cfm':3}
pattern=re.compile(r'(?m)^(?P<indent>[ \t]*)(?P<db>(?:arguments\.)?db)\.q\("\s*CREATE (?:UNIQUE )?(?:TABLE|INDEX) IF NOT EXISTS (?:news\.)?(?P<name>[a-z_]+)\b[\s\S]*?"\);')
for name,count in expected.items():
 s=(source/name).read_text()
 def wrap(m):
  indent=m['indent'];stmt=m[0]
  return indent+'// Avoid DDL on provisioned databases whose datasource restricts schema changes.\n'+indent+'if (!'+m['db']+'.relationExists("news", "'+m['name']+'")) {\n'+'\n'.join('  '+line for line in stmt.splitlines())+'\n'+indent+'}'
 edited,n=pattern.subn(wrap,s)
 assert n==count,(name,n,count)
 (candidate/name).write_text(edited)
manifest={}
diffs=[]
for path in sorted(source.rglob('*')):
 if not path.is_file():continue
 name=path.relative_to(source).as_posix();after=candidate/name
 manifest[name]={'before':hashlib.sha256(path.read_bytes()).hexdigest(),'after':hashlib.sha256(after.read_bytes()).hexdigest()}
 diffs.extend(difflib.unified_diff(path.read_text().splitlines(True),after.read_text().splitlines(True),fromfile='before/'+name,tofile='after/'+name))
(base/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
(base/'patch.diff').write_text(''.join(diffs))
print(json.dumps({'files':len(manifest),'ddl_guards':sum(expected.values())}))
