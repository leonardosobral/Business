"""Release behavior tests against temporary directories; no SSH or production access."""
import base64,hashlib,importlib.util,pathlib,tempfile,unittest
from unittest.mock import patch
FILE=pathlib.Path(__file__).resolve().parents[2]/'scripts/deploy_comparador_admin.py'
release=None
if FILE.exists():
 spec=importlib.util.spec_from_file_location('release',FILE);release=importlib.util.module_from_spec(spec);spec.loader.exec_module(release)
class ReleaseTests(unittest.TestCase):
 def test_publisher_exists(self):self.assertIsNotNone(release,'Publisher behavior is not implemented')
 @unittest.skipIf(release is None,'Not implemented yet')
 def test_publish_verify_and_rollback(self):
  with tempfile.TemporaryDirectory() as folder:
   root,backup,payload=self.fixture(folder)
   receipt=release.deploy(root,backup,payload,'20261017T000000Z-12345678')
   self.assertEqual(receipt['status'],'published')
   self.assertEqual(len(receipt['changed']),5)
   for name,item in payload['files'].items():self.assertEqual(release.digest(root/name),item['after'])
   result=release.rollback(root,backup/'20261017T000000Z-12345678')
   self.assertEqual(result['status'],'rolled_back')
   self.assertEqual((root/'includes/estrutura/sidenav.cfm').read_bytes(),b'original menu')
   self.assertFalse((root/'services/ComparadorAdminService.cfc').exists())
 @unittest.skipIf(release is None,'Not implemented yet')
 def test_baseline_conflict_writes_nothing(self):
  with tempfile.TemporaryDirectory() as folder:
   root,backup,payload=self.fixture(folder)
   (root/'includes/estrutura/sidenav.cfm').write_text('concurrent change')
   with self.assertRaises(RuntimeError):release.deploy(root,backup,payload,'20261017T000000Z-12345678')
   self.assertEqual((root/'includes/estrutura/sidenav.cfm').read_text(),'concurrent change')
   self.assertFalse((root/'services/ComparadorAdminService.cfc').exists())
 @unittest.skipIf(release is None,'Not implemented yet')
 def test_rollback_does_not_overwrite_newer_work(self):
  with tempfile.TemporaryDirectory() as folder:
   root,backup,payload=self.fixture(folder)
   release.deploy(root,backup,payload,'20261017T000000Z-12345678')
   (root/'services/ComparadorAdminService.cfc').write_text('newer work')
   with self.assertRaises(RuntimeError):release.rollback(root,backup/'20261017T000000Z-12345678')
   self.assertEqual((root/'services/ComparadorAdminService.cfc').read_text(),'newer work')
   self.assertEqual(release.digest(root/'includes/estrutura/sidenav.cfm'),payload['files']['includes/estrutura/sidenav.cfm']['after'])
 @unittest.skipIf(release is None,'Not implemented yet')
 def test_partial_write_failure_auto_rolls_back(self):
  with tempfile.TemporaryDirectory() as folder:
   root,backup,payload=self.fixture(folder);real_atomic=release.atomic;calls=0
   def interrupted(*args,**kwargs):
    nonlocal calls
    calls+=1;real_atomic(*args,**kwargs)
    if calls==2:raise RuntimeError('Simulated interruption after replacement')
   with patch.object(release,'atomic',interrupted):
    with self.assertRaises(RuntimeError):release.deploy(root,backup,payload,'20261017T000000Z-12345678')
   for name,item in payload['files'].items():self.assertEqual(release.digest(root/name),item['before'])
 def fixture(self,folder):
  root=pathlib.Path(folder)/'web';backup=pathlib.Path(folder)/'backups';root.mkdir()
  (root/'includes/estrutura').mkdir(parents=True);(root/'services').mkdir();(root/'administracao').mkdir()
  (root/'includes/estrutura/sidenav.cfm').write_bytes(b'original menu')
  files={}
  for name in release.PATHS:
   data=('candidate '+name).encode();files[name]={'data':base64.b64encode(data).decode(),'before':release.digest(root/name),'after':hashlib.sha256(data).hexdigest()}
  return root,backup,{'files':files}
if __name__=='__main__':unittest.main()
