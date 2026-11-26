from pathlib import Path
import json,re,sys,unittest
W=Path(__file__).resolve().parent;sys.path.insert(0,str(W));import derive

def code(sql):return ''.join(v if k=='code'else' 'for k,v in derive.b._tokens(sql))

class DerivedReferenceTests(unittest.TestCase):
    def test_2025_selection_reads_renewed_inventory_not_current_last_frozen_alias(self):
        s=code(derive.prepare(427).read_text());r=derive.runs()
        self.assertIn('r.id='+str(r[425]['id']),s)
        self.assertNotRegex(s,r'\br\.id\s*=\s*242\b')

    def test_2024_diagnostic_reads_new_inventory_and_selection(self):
        s=code(derive.prepare(445).read_text());r=derive.runs()
        for c in (444,427,425):self.assertIn(str(r[c]['id']),s)
        self.assertNotRegex(s,r'\br\.id\s*=\s*(258|244|242)\b')

    def test_brasil_gigante_uses_all_new_inputs_and_metadata(self):
        s=derive.prepare(453).read_text();r=derive.runs()
        for c in (425,426,427,428,429,436,437,452):self.assertIn(str(r[c]['id']),s)
        for kind,text in derive.b._tokens(s):
            if kind=='literal':
                try:v=json.loads(text[1:-1].replace("''", "'"))
                except ValueError:continue
                if isinstance(v,dict)and'source_runs'in v:
                    self.assertEqual(v['source_runs'],[210,*[r[c]['id']for c in (425,426,427,428,429,436,437,452)],r[251]['id']])
                    return
        self.fail('Source metadata not found')

if __name__=='__main__':unittest.main()
