from pathlib import Path
STAGE=Path(__file__).resolve().parent
for name in ['includes/head.cfm','robots.txt']:
 text=(STAGE/'baseline'/name).read_text()
 if name=='includes/head.cfm':
  marker='    <!--- META SEO --->'
  assert text.count(marker)==1
  text=text.replace(marker,'''    <!--- Athlete histories remain public in the site, without search indexing. --->
    <cfif structKeyExists(VARIABLES, "template") AND VARIABLES.template EQ "/resultados/">
        <meta name="robots" content="noindex, follow" />
    </cfif>

'''+marker)
 else:
  assert text.count('Disallow: /resultados\n')==2
  text=text.replace('Disallow: /resultados\n','')
 path=STAGE/'candidate'/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_text(text)
print('Noindex candidate for athlete histories; robots allows fetching the directive, perfil restriction preserved.')
