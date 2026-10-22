"""Public-source reader: no network in this suite; fixtures are literal."""
import importlib.util
import pathlib
import socket
import unittest
from unittest.mock import patch, MagicMock

ROOT = pathlib.Path(__file__).resolve().parents[3]
spec = importlib.util.spec_from_file_location('geo_source_fetcher', ROOT / 'services/geocoding/source_fetcher.py')
reader = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reader)


class SourceReaderTests(unittest.TestCase):
    def test_three_explicit_sources_include_regulation_and_keep_global_bounds(self):
        urls = ['https://race.com/official', 'https://race.com/entry', 'https://race.com/regulation']
        def transport(url, deadline, max_bytes=reader.PDF_LIMIT, authorize=None):
            return {'url': url, 'sha256': 'a'*64, 'content_type': 'text/html', 'body': b'<title>Race</title>'}
        with patch.object(reader, 'fetch_document', side_effect=transport):
            result = reader.collect({'urls': urls, 'robots': {'race.com': ''}})
        self.assertEqual([page['url'] for page in result['pages']], urls)
        self.assertLessEqual(result['documents'], 4)

    def test_urls_cannot_address_private_services_or_carry_credentials(self):
        for url in ['file:///etc/passwd', 'https://127.0.0.1/', 'https://[::1]/',
                    'https://169.254.169.254/', 'https://localhost/', 'https://a.internal/',
                    'https://user:pass@race.com/', 'https://race.com:8443/',
                    'https://race.com/?access_token=secret', 'https://race.com/\r\nHost:x']:
            with self.subTest(url=url), self.assertRaises(ValueError):
                reader.normalize_url(url)
        self.assertEqual(reader.normalize_url('http://race.com/evento?a=2#largada'), 'https://race.com/evento?a=2')
        self.assertEqual(reader.normalize_url('../regulamento.pdf', 'https://race.com/evento/2026/'), 'https://race.com/evento/regulamento.pdf')

    def test_mixed_public_private_dns_is_rejected_before_connect(self):
        rows = [(socket.AF_INET, socket.SOCK_STREAM, 6, '', ('8.8.8.8', 443)),
                (socket.AF_INET, socket.SOCK_STREAM, 6, '', ('10.0.0.1', 443))]
        with patch.object(reader.socket, 'getaddrinfo', return_value=rows), self.assertRaises(ValueError):
            reader.public_addresses('race.com')

    def test_tls_connect_uses_validated_ip_and_original_hostname(self):
        sock = MagicMock(); context = MagicMock()
        with patch.object(reader.socket, 'create_connection', return_value=sock) as connect:
            connection = reader.PinnedHTTPSConnection('race.com', '8.8.8.8', timeout=2, context=context)
            connection.connect()
            self.assertEqual(connect.call_args.args[0], ('8.8.8.8', 443))
            self.assertEqual(context.wrap_socket.call_args.kwargs['server_hostname'], 'race.com')

    def test_html_extracts_event_json_and_regulation_without_scripts_or_tracking(self):
        page = reader.parse_html('''<title>Corrida do Parque 2026</title><h1>Corrida do Parque</h1>
          <p>17/10/2026</p><p>Local da largada: Parque das Flores</p>
          <script type="application/ld+json">{"@type":"SportsEvent","name":"Corrida do Parque"}</script>
          <script>alert('private')</script><a href="/regulamento.pdf">Regulamento</a>
          <a href="https://organizador.com/prova">Site oficial</a><a href="/login">Minha conta</a>
          <iframe src="/regulamento/arquivo.pdf"></iframe>''', 'https://race.com/2026')
        self.assertIn('Local da largada: Parque das Flores', page['text'])
        self.assertNotIn('private', page['text'])
        self.assertEqual(page['jsonld'][0]['@type'], 'SportsEvent')
        self.assertEqual([r['url'] for r in page['links']], ['https://race.com/regulamento.pdf', 'https://organizador.com/prova', 'https://race.com/regulamento/arquivo.pdf'])
        self.assertEqual(page['title'], 'Corrida do Parque 2026')

    def test_robots_rules_are_respected_for_our_agent(self):
        self.assertFalse(reader.robots_allowed('User-agent: *\nDisallow: /privado', 'https://race.com/privado/evento'))
        self.assertTrue(reader.robots_allowed('User-agent: *\nDisallow: /privado', 'https://race.com/prova'))

    def test_response_limit_stops_chunked_oversized_content(self):
        response = MagicMock(); response.read.side_effect = [b'x' * 65536] * 20
        with self.assertRaises(ValueError):
            reader.read_limited(response, 100000)

    def test_private_redirect_is_never_followed(self):
        response = MagicMock(status=302)
        response.getheader.side_effect = lambda key, default='': {'Location':'https://127.0.0.1/admin'}.get(key, default)
        with patch.object(reader, 'public_addresses', return_value=['8.8.8.8']), \
             patch.object(reader, 'PinnedHTTPSConnection') as connection:
            connection.return_value.getresponse.return_value = response
            with self.assertRaises(ValueError):
                reader.fetch_document('https://race.com/prova', reader.time.monotonic()+5)
            self.assertEqual(connection.call_count, 1)

    def test_http_failure_does_not_return_error_page_as_event_evidence(self):
        response = MagicMock(status=403)
        with patch.object(reader, 'public_addresses', return_value=['8.8.8.8']), \
             patch.object(reader, 'PinnedHTTPSConnection') as connection:
            connection.return_value.getresponse.return_value = response
            with self.assertRaises(ValueError):
                reader.fetch_document('https://race.com/prova', reader.time.monotonic()+5)

    def test_temporary_robots_failure_is_not_an_authoritative_cached_prohibition(self):
        original = reader.fetch_document
        def transport(url, deadline, max_bytes=reader.PDF_LIMIT, authorize=None):
            if url.endswith('/robots.txt'):
                raise TimeoutError()
            return original(url, deadline, max_bytes, authorize)
        with patch.object(reader, 'fetch_document', side_effect=transport):
            result = reader.collect({'urls':['https://race.com/prova'], 'robots':{}})
        self.assertIn('source_unavailable', result['diagnostics'])
        self.assertNotIn('race.com', result['robots'])

    def test_redirect_respects_cached_destination_robots_before_request(self):
        redirect = MagicMock(status=302)
        redirect.getheader.side_effect = lambda key, default='': {'Location':'https://target.com/private'}.get(key, default)
        response = MagicMock(status=200)
        response.getheader.side_effect = lambda key, default='': {'Content-Type':'text/html'}.get(key, default)
        response.read.side_effect = [b'<title>Race</title>', b'']
        with patch.object(reader, 'public_addresses', return_value=['8.8.8.8']), \
             patch.object(reader, 'PinnedHTTPSConnection') as connection:
            connection.return_value.getresponse.side_effect = [redirect, response]
            result = reader.collect({'urls':['https://race.com/prova'], 'robots':{
                'race.com':'', 'target.com':'User-agent: *\nDisallow: /private'}})
            self.assertEqual(result['pages'], [])
            self.assertIn('robots_disallowed', result['diagnostics'])
            self.assertEqual(connection.call_count, 1)


if __name__ == '__main__':
    unittest.main()
