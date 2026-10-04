from pathlib import Path
import hashlib,json
STAGE=Path(__file__).resolve().parent
state=json.loads((STAGE/'state.json').read_text())
names=['descriptions.json','logs.json','ranges.json','state.json','cron-diagnosis.json','privacy-verification.json']
report={'schemaVersion':1,'descriptions':json.loads((STAGE/'descriptions.json').read_text()),'audience':state['audience'],'access':json.loads((STAGE/'logs.json').read_text()),
 'cron':state['state']['cron'],'queue':state['queue']['COUNTS'],'cron_diagnosis':json.loads((STAGE/'cron-diagnosis.json').read_text()),
 'sources':{n:hashlib.sha256((STAGE/n).read_bytes()).hexdigest() for n in names}}
(STAGE/'evidence.json').write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n')
print(json.dumps({'schemaVersion':1,'sources':len(report['sources']),'events':len(report['descriptions']['events'])}))
