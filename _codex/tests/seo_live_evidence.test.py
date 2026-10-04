import importlib.util,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('evidence',ROOT/'_codex/scripts/seo_live_evidence.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class Descriptions(unittest.TestCase):
 def page(self,text,lang='en',status=200,url='https://roadrunners.run/en/event/test/'):
  return m.description_observation('<head><link rel="canonical" href="'+url+'"></head><div class="event-info-copy"><div lang="'+lang+'">'+text+'</div></div>',url,status,url)
 def test_extracts_description_only_and_ignores_hidden_content(self):
  o=m.description_observation('<head><title>English shell</title></head><div lang="en">Shell</div><div class="event-info-copy"><div lang="en">Race <b>10 km</b><script>attack</script><span hidden>secret</span><br> Sunday</div></div>', 'https://roadrunners.run/en/event/test/',200,'https://roadrunners.run/en/event/test/')
  self.assertEqual(o['description_lang'],'en');self.assertEqual(o['description_chars'],17);self.assertNotIn('Race',str({k:v for k,v in o.items() if k!='description_hash'}));self.assertEqual(o['description_hash'],m.text_hash('Race 10 km Sunday'))
 def test_translation_compares_corresponding_original(self):
  pt=self.page('Corrida de 10 km','pt-BR');en=self.page('10 km race')
  self.assertEqual(m.translation_status(pt,en,'en'),'pass')
  self.assertEqual(m.translation_status(pt,self.page('Corrida de 10 km','pt-BR'),'en'),'warning')
  self.assertEqual(m.translation_status(pt,self.page('Corrida de 10 km'),'en'),'warning')
 def test_missing_original_or_marker_is_unknown(self):
  pt=self.page('');en=self.page('10 km race')
  self.assertEqual(m.translation_status(pt,en,'en'),'unknown')
  missing=m.description_observation('<html lang="en"><p>English chrome</p></html>',en['url'],200,en['url'])
  self.assertEqual(m.translation_status(self.page('Corrida','pt-BR'),missing,'en'),'unknown')
 def test_duplicate_regions_and_redirects_are_not_passes(self):
  u='https://roadrunners.run/en/event/test/'
  duplicate=m.description_observation('<div class="event-info-copy"><div lang="en">Race</div><div lang="en">Other</div></div>',u,200,u)
  self.assertEqual(m.translation_status(self.page('Corrida','pt-BR'),duplicate,'en'),'unknown')
  bad=m.description_observation('<div class="event-info-copy"><div lang="en">Race</div></div>',u,200,'https://roadrunners.run/login/')
  self.assertEqual(m.translation_status(self.page('Corrida','pt-BR'),bad,'en'),'error')
 def test_http_failure_is_error(self):self.assertEqual(m.translation_status(self.page('Corrida','pt-BR'),self.page('fail',status=503),'en'),'error')
 def test_visible_nested_language_conflict_cannot_pass(self):
  original=self.page('Corrida em Salvador','pt-BR');target=self.page('<div lang="pt-BR">Corrida sábado em São Paulo</div>')
  self.assertTrue(target['description_lang_conflict']);self.assertEqual(m.translation_status(original,target,'en'),'unknown')
  source=self.page('<span lang="en">English source fragment</span>','pt-BR')
  self.assertEqual(m.translation_status(source,self.page('Race Sunday'),'en'),'unknown')
 def test_same_or_hidden_nested_language_does_not_create_conflict(self):
  o=self.page('<div lang="EN">Race Sunday</div><span hidden lang="pt-BR">oculto</span>')
  self.assertFalse(o['description_lang_conflict']);self.assertEqual(m.translation_status(self.page('Corrida domingo','pt-BR'),o,'en'),'pass')
class Logs(unittest.TestCase):
 def test_parses_claimed_bot_without_exporting_target_or_ip(self):
  raw='203.0.113.4 - - [03/Oct/2026:20:00:00 +0000] "GET /resultados/person-name/?token=secret HTTP/1.1" 403 12 "-" "Mozilla/5.0; OAI-SearchBot/1.4"'
  o=m.bot_observation(raw,{'OAI-SearchBot':['203.0.113.0/24']})
  self.assertEqual(o['agent'],'OAI-SearchBot');self.assertTrue(o['ip_matches']);self.assertEqual(o['status'],403)
  for secret in ['203.0.113.4','person-name','token','secret']:self.assertNotIn(secret,str(o))
 def test_ipv6_and_mismatched_identity(self):
  raw='2001:db8::1 - - [03/Oct/2026:20:00:00 +0000] "GET / HTTP/1.1" 200 12 "-" "PerplexityBot/1.0"'
  self.assertTrue(m.bot_observation(raw,{'PerplexityBot':['2001:db8::/32']})['ip_matches'])
  self.assertFalse(m.bot_observation(raw,{'PerplexityBot':['203.0.113.0/24']})['ip_matches'])
 def test_missing_ranges_is_unknown_and_nonbots_are_ignored(self):
  raw='203.0.113.4 - - [03/Oct/2026:20:00:00 +0000] "GET / HTTP/1.1" 200 12 "-" "ChatGPT-User/1.0"'
  self.assertIsNone(m.bot_observation(raw,{})['ip_matches']);self.assertIsNone(m.bot_observation(raw.replace('ChatGPT-User/1.0','RunnerHub-SEO/1.0'),{}))
if __name__=='__main__':unittest.main()
