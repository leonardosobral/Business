import importlib.util, pathlib, tempfile, unittest
p=pathlib.Path(__file__).resolve().parents[1]/'scripts/deploy_error_triage.py'
spec=importlib.util.spec_from_file_location('release',p)
r=importlib.util.module_from_spec(spec);spec.loader.exec_module(r)
class ReleaseTests(unittest.TestCase):
 def test_conflict_before_any_write(self):
  with tempfile.TemporaryDirectory() as d:
   root=pathlib.Path(d)/'root';root.mkdir();(root/'old.cfm').write_text('unexpected');stage=pathlib.Path(d)/'stage'
   with self.assertRaises(RuntimeError):r.prepare(root,stage,{'old.cfm':'new'},{'old.cfm':r.digest(b'old')})
   self.assertEqual((root/'old.cfm').read_text(),'unexpected');self.assertFalse(stage.exists())
 def test_backup_publish_and_restore(self):
  with tempfile.TemporaryDirectory() as d:
   root=pathlib.Path(d)/'root';root.mkdir();(root/'old.cfm').write_text('old');stage=pathlib.Path(d)/'stage'
   r.prepare(root,stage,{'new.cfm':'dependency','old.cfm':'new'},{'old.cfm':r.digest(b'old')});r.publish(root,stage)
   self.assertEqual((root/'old.cfm').read_text(),'new');self.assertEqual((stage/'baseline/old.cfm').read_text(),'old')
   r.rollback(root,stage);self.assertEqual((root/'old.cfm').read_text(),'old');self.assertFalse((root/'new.cfm').exists())
 def test_new_target_conflict_and_candidate_tamper(self):
  with tempfile.TemporaryDirectory() as d:
   root=pathlib.Path(d)/'root';root.mkdir();(root/'old.cfm').write_text('old');(root/'new.cfm').write_text('other');stage=pathlib.Path(d)/'stage'
   with self.assertRaises(RuntimeError):r.prepare(root,stage,{'old.cfm':'new','new.cfm':'dep'},{'old.cfm':r.digest(b'old')})
   (root/'new.cfm').unlink();r.prepare(root,stage,{'old.cfm':'new','new.cfm':'dep'},{'old.cfm':r.digest(b'old')})
   (stage/'candidate/new.cfm').write_text('tampered')
   with self.assertRaises(RuntimeError):r.publish(root,stage)
   self.assertEqual((root/'old.cfm').read_text(),'old')
 def test_rollback_refuses_concurrent_change(self):
  with tempfile.TemporaryDirectory() as d:
   root=pathlib.Path(d)/'root';root.mkdir();(root/'old.cfm').write_text('old');stage=pathlib.Path(d)/'stage'
   r.prepare(root,stage,{'old.cfm':'new'},{'old.cfm':r.digest(b'old')});r.publish(root,stage);(root/'old.cfm').write_text('later')
   with self.assertRaises(RuntimeError):r.rollback(root,stage)
   self.assertEqual((root/'old.cfm').read_text(),'later')
if __name__=='__main__':unittest.main()
