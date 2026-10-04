"""Exercise the actual Apache rewrite rules with a local CGI echo of decoded parameters.
No production traffic, app login, database, third-party package or server configuration change.
"""
import grp,pwd,json,os,socket,subprocess,sys,tempfile,time,unittest,urllib.error,urllib.parse,urllib.request
from pathlib import Path

SOURCE=Path(os.environ.get('SEO_ROUTE_SOURCE','_codex/staging/seo-routes-20261003/baseline/RoadRunners')).resolve()
TAGS=[
 '2026-operario\r\nnight\r\nrun',
 '2026-rock-n-run\n----nashville-2026',
 '2026-atibaia-run-fest-trail-mode-#03-socorro-pico-do-gaviao',
 '2026-atibaia-run-fest-x-chopp-germania-corre-pela-breja-#01',
 '2024-floripa-ultra-trail-run- 2024',
 'ix-encontro-dos-amigos-"correm"-por-do-sol',
 'evento&escopo=site',
 'evento+á-100%',
 'evento-comum',
 'evento%26literal',
 'evento%2fliteral',
]
class EventRoutes(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  cls.temp=tempfile.TemporaryDirectory(prefix='seo-apache-',dir='/private/tmp')
  cls.root=Path(cls.temp.name);(cls.root/'evento').mkdir()
  (cls.root/'.htaccess').write_bytes((SOURCE/'.htaccess').read_bytes())
  (cls.root/'evento/.htaccess').write_bytes((SOURCE/'evento/.htaccess').read_bytes())
  (cls.root/'evento/index.cfm').write_text('#!'+sys.executable+'\nimport os,json,urllib.parse\nprint("Content-Type: application/json; charset=utf-8\\n")\nprint(json.dumps(urllib.parse.parse_qs(os.environ.get("QUERY_STRING","")),ensure_ascii=True))\n')
  (cls.root/'evento/index.cfm').chmod(0o755)
  with socket.socket() as sock:sock.bind(('127.0.0.1',0));cls.port=sock.getsockname()[1]
  modules=['mpm_prefork','unixd','authz_core','mime','rewrite','cgi']
  config='ServerRoot "'+str(cls.root)+'"\nServerName localhost\nListen 127.0.0.1:'+str(cls.port)+'\n'
  config+='\n'.join('LoadModule '+name+'_module /usr/libexec/apache2/mod_'+name+'.so' for name in modules)+'\n'
  config+='User '+pwd.getpwuid(os.getuid()).pw_name+'\nGroup '+grp.getgrgid(os.getgid()).gr_name+'\n'
  config+='PidFile "'+str(cls.root/'httpd.pid')+'"\nErrorLog "'+str(cls.root/'error.log')+'"\nLogLevel warn\nTypesConfig /dev/null\nDocumentRoot "'+str(cls.root)+'"\n'
  config+='<Directory "'+str(cls.root)+'">\nAllowOverride All\nOptions +ExecCGI\nRequire all granted\nAddHandler cgi-script .cfm\n</Directory>\n'
  (cls.root/'httpd.conf').write_text(config)
  cls.proc=subprocess.Popen(['/usr/sbin/httpd','-f',str(cls.root/'httpd.conf'),'-DFOREGROUND'],stdout=subprocess.PIPE,stderr=subprocess.PIPE,start_new_session=True)
  for _ in range(50):
   if cls.proc.poll() is not None:raise RuntimeError(cls.proc.communicate()[1].decode()+'\n'+((cls.root/'error.log').read_text() if (cls.root/'error.log').exists() else 'no log'))
   try:
    with socket.create_connection(('127.0.0.1',cls.port),timeout=.1):break
   except OSError:time.sleep(.1)
 @classmethod
 def tearDownClass(cls):
  cls.proc.terminate();cls.proc.communicate(timeout=10);cls.temp.cleanup()
 def test_identifiers_survive_routing_in_all_languages(self):
  for prefix,lang in [('/evento/',None),('/en/event/','en'),('/es/evento/','es')]:
   for tag in TAGS:
    with self.subTest(prefix=prefix,tag=tag):
     url='http://127.0.0.1:'+str(self.port)+prefix+urllib.parse.quote(tag,safe='')+'/?tracking=seo'
     try:
      with urllib.request.urlopen(url,timeout=5) as response:result=json.loads(response.read())
     except urllib.error.HTTPError as e:
      status=e.code;e.close();self.fail('HTTP '+str(status)+' for '+prefix+repr(tag))
     self.assertEqual(result.get('tag'),[tag] if lang else [tag+'/'])
     self.assertEqual(result.get('tracking'),['seo'])
     self.assertNotIn('escopo',result)
     if lang:self.assertEqual(result.get('i18n_lang'),[lang])
 def test_identifiers_without_trailing_slash(self):
  for prefix,lang in [('/evento/',None),('/en/event/','en'),('/es/evento/','es')]:
   for tag in TAGS:
    with self.subTest(prefix=prefix,tag=tag):
     url='http://127.0.0.1:'+str(self.port)+prefix+urllib.parse.quote(tag,safe='')
     with urllib.request.urlopen(url,timeout=5) as response:result=json.loads(response.read())
     self.assertEqual(result.get('tag'),[tag])
     self.assertNotIn('escopo',result)
     if lang:self.assertEqual(result.get('i18n_lang'),[lang])
 def test_sensitive_paths_remain_forbidden(self):
  for path in ['/.env','/.git/config','/config.json','/mcp/']:
   with self.subTest(path=path):
    with self.assertRaises(urllib.error.HTTPError) as result:urllib.request.urlopen('http://127.0.0.1:'+str(self.port)+path,timeout=5)
    self.assertEqual(result.exception.code,403);result.exception.close()
if __name__=='__main__':unittest.main()
