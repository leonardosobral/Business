from pathlib import Path
import json,base64,re,hashlib
P=Path(__file__).parent;ROOT=P.parents[2];OUT=P.parent
companies=json.loads((OUT/'revisao_empresas.json').read_text());events=json.loads((OUT/'revisao_eventos.json').read_text());before=json.loads((ROOT/'_codex/staging/abraceo-revisao55-20261011/baseline.json').read_text())
files={n:base64.b64encode((ROOT/n).read_bytes()).decode() for n in before};rows=[]
for r in companies:
 if r['status_organizacao']!='CONFIRMADO':continue
 logo=ROOT/'outputs/abraceo-20261010'/r['logo_arquivo'];suffix=logo.suffix.lower();suffix='.jpg' if suffix=='.jpeg' else suffix
 dest='assets/contas/abraceo/'+r['id_filiado']+suffix;assert logo.is_file();files[dest]=base64.b64encode(logo.read_bytes()).decode()
 email=r['email_publico'].strip();assert not email or re.fullmatch(r'[^\s|;,]+@[^\s|;,]+\.[^\s|;,]+',email)
 phone=r['telefone_publico'].strip(); phone=phone if len(phone)<=30 else ''
 selected=[e for e in events if e['id_filiado']==r['id_filiado'] and e['status_revisao']=='CONFIRMADO']
 r['eventos_confirmados']=[{k:e[k] for k in ['id_evento','nome_evento','data_inicial','fonte_confirmacao','motivo_revisao']} for e in selected]
 r['pendencias']='Confirmar CNPJ e razão social do titular atual e representante. Documento pesquisado não vinculado como titular.'
 rows.append(dict(id_filiado=r['id_filiado'],nome_empresa=r['nome_abraceo'],email=email,telefone=phone,logo_path='/'+dest,dados=r))
payload=dict(rows=rows,events=[e for e in events if e['status_revisao']=='CONFIRMADO'],files=files,before=before,migration=(ROOT/'_codex/sql/2026-10-11_contas_documento_pendente.sql').read_text())
(P/'payload.json').write_text(json.dumps(payload,ensure_ascii=False));print({'accounts':len(rows),'events':len(payload['events']),'files':len(files)})
