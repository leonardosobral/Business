import concurrent.futures,csv,hashlib,html,json,re,subprocess
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
OUT=Path(__file__).resolve().parent
source=ROOT/'abraceo-20261010'
accounts=json.loads((source/'importacao/resultado_business.json').read_text())['contas']
members={r['id_filiado']:r for r in csv.DictReader((source/'abraceo_filiados.csv').open(encoding='utf-8-sig'),delimiter=';')}

def one(c):
    r=members[c['id_origem']]
    result={'id_conta':c['id_conta'],'empresa':c['nome_conta'],'cnpj':c['documento'],'contato':r['contato_publico'],'fonte':r['fonte_abraceo'],'email_business':c['email_principal'],'status_conta':c['status']}
    p=subprocess.run(['curl','-fLsS','--max-time','25',r['fonte_abraceo']],capture_output=True,text=True,timeout=30)
    if p.returncode:
        result.update(status='PENDENTE',motivo='Não foi possível reconferir o contato na fonte',email=r['email_publico']);return result
    core=p.stdout[p.stdout.find('<h1'):].split('Associados ABRACEO')[0]
    vals=[html.unescape(re.sub('<[^>]+>',' ',v)).strip() for v in re.findall(r'<span class="elementor-icon-list-text">(.*?)</span>',core,re.S)]
    emails=sorted(set(re.findall(r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}', ' '.join(vals).lower())))
    old=re.findall(r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}',r['email_publico'].lower())
    email=c['email_principal'].lower() if c['email_principal'].lower() in emails else (old[0] if old and old[0] in emails else '')
    result.update(email=email,emails_fonte=emails,campos_fonte=vals,fonte_sha256=hashlib.sha256(p.stdout.encode()).hexdigest(),verificado_em='2026-10-11',vence_em='2026-11-10')
    if not email:result.update(status='PENDENTE',motivo='E-mail da base não confirmado na fonte atual')
    elif email.startswith('__'):result.update(status='PENDENTE',motivo='Endereço publicado começa com dois underscores; confirmar grafia com a ABRACEO antes de emitir')
    else:result.update(status='APTO',motivo='E-mail publicado no perfil da ABRACEO e reconferido na base')
    if c['id_conta']==39:result['motivo']+='; principal autorizado pelo usuário'
    if email!=c['email_principal'].lower():result['motivo']+='; usado contato ABRACEO, preservado e-mail da conta Business'
    return result

with concurrent.futures.ThreadPoolExecutor(max_workers=5) as pool:rows=list(pool.map(one,accounts))
assert len(rows)==41 and len({r['cnpj'] for r in rows})==41
(OUT/'contacts.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2))
print(json.dumps({'total':len(rows),'aptos':sum(r['status']=='APTO' for r in rows),'pendentes':[{'empresa':r['empresa'],'motivo':r['motivo']} for r in rows if r['status']!='APTO']},ensure_ascii=False))
