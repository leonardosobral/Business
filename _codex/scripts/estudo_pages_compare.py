from pathlib import Path
import re,json,hashlib,difflib
RR=Path(__file__).resolve().parents[3]/'RoadRunners'
D=RR/'_codex/docs/brasil_que_corre_provas'
# Lexical tokens preserve string/quoted-identifier content, while ignoring comments and formatting.
TOKEN=re.compile(r"--[^\n]*|/\*.*?\*/|'(?:''|[^'])*'|\"(?:\"\"|[^\"])*\"|[A-Za-z_][A-Za-z_0-9$]*|\d+(?:\.\d+)?|\S",re.S)
def toks(s):return [x if x[0] in "'\"" else x.lower() for x in TOKEN.findall(s) if not x.startswith(('--','/*')) and x!=';']
def sha(s):return hashlib.sha256(s.encode()).hexdigest()
def split(s,notebook=False):
 # Four recovered cells omitted delimiters between titled, top-level queries.
 if notebook:
  s=re.sub(r'\n(?=-- (?:Concentração|Conclusões|RAPIDAS))',';\n',s)
 out=[];start=0
 for m in TOKEN.finditer(s):
  if m.group()==';':
   if toks(s[start:m.end()]):out.append(s[start:m.end()].strip())
   start=m.end()
 if toks(s[start:]):out.append(s[start:].strip())
 return out

def load():
 out=[]
 for family,folder in [('editor','fontes_notebooks_2026_09_28'),('datagrip','fontes_sql'),('dba','fontes_dba_2026_09_27')]:
  for p in sorted((D/folder).glob('*.txt')):
   if 'insights_' in p.name:continue
   s=p.read_text()
   for i,b in enumerate(split(s,family=='editor'),1):
    ts=toks(b)
    first=next((x.strip('- ').strip() for x in b.splitlines() if x.strip().startswith('--')), 'Consulta sem título')
    out.append(dict(key=f'{family}:{p.name}:{i}',family=family,file=p.name,block=i,title=first,sql=b,tokens=ts,sha256=sha(b),operation=ts[0] if ts else '',tables=sorted(set(re.findall(r'\b(?:from|join)\s+((?:public\.)?(?:tb\w+|vw\w+))',b,re.I))),lines=len(b.splitlines())))
 return out
if __name__=='__main__':
 items=load();Path('/private/tmp/estudo-blocks.json').write_text(json.dumps(items,ensure_ascii=False,indent=2))
 for a in items:
  if a['family']=='dba' and a['file']!='INFOGRAFICO_DISTANCIAS.sql.txt':continue
  print(a['key'],a['title'][:60],a['operation'],','.join(a['tables']))
  if a['family']=='editor':
   choices=[b for b in items if b['family']=='datagrip']
   best=max(choices,key=lambda b:difflib.SequenceMatcher(None,a['tokens'],b['tokens'],autojunk=False).ratio())
   r=difflib.SequenceMatcher(None,a['tokens'],best['tokens'],autojunk=False).ratio()
   aa=['vw_resultados' if x=='tb_resultados' else x for x in a['tokens']]
   print('   ->',best['key'],round(r,3),'IGUAL' if a['tokens']==best['tokens'] else 'APENAS_FONTE' if aa==best['tokens'] else 'VARIANTE')
