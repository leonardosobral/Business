from html.parser import HTMLParser
from pathlib import Path
import sys
class Canonical(HTMLParser):
 def __init__(self):super().__init__();self.values=[]
 def handle_starttag(self,t,a):
  a=dict(a)
  if t=='link' and a.get('rel')=='canonical':self.values.append(a.get('href'))
p=Canonical();p.feed(Path(sys.argv[1]).read_text())
assert p.values==['https://openresults.run/estado/se/?cidade=aracaju'],p.values
print('Aracaju retains its city-specific canonical: PASS')
