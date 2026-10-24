"""Focused link regression; synthetic fixtures and real runtime via private CF only."""
import http.cookiejar,json,pathlib,unittest,urllib.request,urllib.parse
from html.parser import HTMLParser
BASE='http://127.0.0.1:18500/codex-comparador-20261016/business/'
class Links(HTMLParser):
 def __init__(self):super().__init__();self.urls=[]
 def handle_starttag(self,tag,attrs):
  if tag=='a':self.urls.extend(urllib.parse.unquote(v) for k,v in attrs if k=='href' and v.startswith('https://comparador.roadrunners.run/'))
class PublicLinkTests(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  cls.client=urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))
  cls.client.open(BASE+'harness/login.cfm',urllib.parse.urlencode({'role':'admin'}).encode(),timeout=30).read()
 def urls(self,product):
  parser=Links();parser.feed(self.client.open(BASE+'administracao/comparador/index.cfm?id='+str(product),timeout=30).read().decode());return parser.urls
 def test_legacy_empty_slug_has_no_public_link(self):self.assertEqual(self.urls(904900),[])
 def test_missing_category_has_no_public_link(self):self.assertEqual(self.urls(904901),[])
 def test_missing_brand_has_no_public_link(self):self.assertEqual(self.urls(904902),[])
 def test_complete_published_product_keeps_public_link(self):self.assertEqual(self.urls(900004),['https://comparador.roadrunners.run/cameras/camera-d/'])
if __name__=='__main__':
 suite=unittest.defaultTestLoader.loadTestsFromTestCase(PublicLinkTests);result=unittest.TextTestRunner(verbosity=2).run(suite)
 path=pathlib.Path(__file__).resolve().parents[2]/'docs/2026-10-16_comparador_public_link_evidence.json'
 path.write_text(json.dumps({'tests':result.testsRun,'failed':len(result.failures)+len(result.errors),'passed':result.testsRun-len(result.failures)-len(result.errors)},indent=2)+'\n')
 raise SystemExit(not result.wasSuccessful())
