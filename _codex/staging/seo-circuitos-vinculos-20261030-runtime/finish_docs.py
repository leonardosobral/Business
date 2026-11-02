from pathlib import Path
import json
S=Path(__file__).resolve().parent;D=S.parent/'seo-circuitos-vinculos-20261030'
d=json.loads((D/'decisions.json').read_text());inv={e['id_evento']:e for e in json.loads((D/'inventory.json').read_text())['events']}
text='''# Revisão dos vínculos das próximas etapas de LIVE! e Estações — 30/10/2026

## Resultado publicado

Revisadas 45 fichas futuras candidatas do catálogo (01/11–20/12/2026), comparando individualmente nome, cidade e data nas fontes oficiais. Não é uma revisão de todo o histórico ou do calendário de 2027. As listas públicas passaram de 3 para **24 próximas etapas no Estações** e de 11 para **12 na LIVE!**.

- 21 associações novas em `tb_agregadores_eventos` para `estacoes`; uma para `live-run-xp`. O campo `percursos` das associações ficou nulo, seguindo o contrato existente.
- Ribeirão Preto II (48557, 22/11): hotsite e inscrição corrigidos para a etapa real; inclusão dos 15 km e resumo factual PT/EN/ES com hashes de tradução atualizados. Os dois percursos anteriores mantiveram seus IDs e dados, exceto o bloqueio manual preventivo; o trigger de categorias criou somente o percurso faltante. Os três percursos ficaram bloqueados para proteger a curadoria. As datas de início/término do evento ficaram intactas.
- Fortaleza (45366 → 37570): duplicidade confirmada por cidade, data de 20/11 e URL oficial. Ficha duplicada inativada com `tag_301` para a válida, em PT/EN/ES. Nenhum registro foi apagado. Percursos, associações de fotos e dependências preservados; não houve migração de resultados/agenda/contas porque esses vínculos não existiam na duplicada.
- Imperatriz (37765): pendente, sem mudança. A [fonte O2 cadastrada](https://www.o2corre.com.br/calendario/circuito-das-estacoes-2026-ver-o-imperatriz/) não retornou dados da prova, e a cidade não consta no seletor atual do circuito. Isso não comprova cancelamento e não autoriza inferir nova data.
- Sete candidatas de outros organizadores ficaram fora dos dois circuitos: 46015, 47208, 48556, 50019, 48100, 50267 e 50485.

Os 11 vínculos LIVE! anteriores foram conferidos com o calendário oficial, junto da etapa de Ribeirão Preto. A fonte de Bonito usa um slug antigo com “jurer”, mas o conteúdo oficial confirma Bonito (MS), 01/11; o slug isoladamente não motivou mudança.

## Fontes dos 22 vínculos adicionados

As datas abaixo são as do cadastro, coincidentes com a evidência oficial capturada em 30/10. Não foram alteradas nesta rodada.

| ID | Circuito | Cidade | Data | Fonte oficial |
| --- | --- | --- | --- | --- |
'''
for x in sorted(d['addMemberships'],key=lambda x:(x['agregador_tag'],inv[x['id_evento']]['data_inicial'],inv[x['id_evento']]['cidade'])):
 e=inv[x['id_evento']];date='/'.join(reversed(e['data_inicial'].split('-')))
 text+=f"| {e['id_evento']} | {'Estações' if x['agregador_tag']=='estacoes' else 'LIVE!'} | {e['cidade']} | {date} | [Página da etapa]({x['source']}) |\n"
text+='''
Inscrição correta de Ribeirão: [LIVE! Experience](https://www.appliveexperience.com.br/evento/live-run-ribeirao-preto-ii-2026), observada no botão da página oficial, sem adivinhar a rota. Evidências textuais completas em `Business/_codex/staging/seo-circuitos-vinculos-20261030/official-*.txt`, `live-calendar-official.txt` e `official-checks.json`.

## Navegação entre ficha e circuito

A conferência pública revelou que `qAgrega` depende do tema visual e não exibia o retorno ao circuito para várias associações válidas. Para preservar o agrupamento de edições e os cabeçalhos existentes, foi adicionado um include separado:

- `evento/index.cfm`: inclui `parts/circuit_links.cfm` após o breadcrumb.
- `evento/parts/circuit_links.cfm`: consulta parametrizada, somente leitura, para os dois circuitos; cache de um minuto, timeout de cinco segundos, nomes/atributos escapados e rota validada. Suprime o link quando o cabeçalho temático já o oferece. Rótulo PT/EN/ES; destino do circuito em português com `hreflang="pt-BR"`. Acesso direto retorna 403.

Não houve alteração de tema, regras de edições, cupons, autenticação, inscrições/pagamento, APIs, JS ou CSS.

## Validação e publicação

- Dados: baseline exato de 24 eventos, ensaio transacional e teste da inversão antes da aplicação. 50 percursos anteriores preservados por ID/conteúdo, com somente os dois bloqueios manuais de Ribeirão; 51 após criar o de 15 km. 22 associações novas e uma associação anterior intacta no snapshot do lote. 46 grupos de dependências com contagens e hashes preservados.
- ColdFusion: dois templates compilados e cinco cenários reais (Estações sem tema, Ribeirão sem tema, LIVE! Brasília e Fortaleza com tema, maratona de Curitiba sem circuito). Sem duplicação de navegação nos cenários temáticos.
- Público: 29 verificações passaram — duas listas com contagens 24/12, 22 fichas com canonical e retorno ao circuito, três 301 localizados de Fortaleza e Ribeirão EN/ES com 15 km. Verificação adicional: include direto 403.
- Navegador: Chrome desktop, Ribeirão e Estações no celular de 390 px; novos vínculos, 15 km e contagem visíveis, sem overflow horizontal. Screenshots e recibo no staging de dados.
- Runtime publicado às **14:54:20 (Brasília)** em 30/10/2026, dois hashes finais e cinco dependências compartilhadas preservadas. Baseline local e de produção eram iguais; sincronização local também protegida por hashes.

Os dados foram efetivamente aplicados no banco. **Nada para executar no DataGrip.** Não houve alteração de datas dos eventos, commit, push, branch ou PR. Não foi executada nova auditoria Semrush; esta entrega não comprova ganho de Site Health, tráfego ou ranking.

## Evidências e restauração

- Dados e evidências: `Business/_codex/staging/seo-circuitos-vinculos-20261030/` — `decisions.json`, `before.json`, `release-rehearse.json`, `release-publish.json`, `release-verify.json`, `public-verified.json`, fontes e screenshots.
- Runtime: `Business/_codex/staging/seo-circuitos-vinculos-20261030-runtime/` — baseline, candidato, recibos de compilação/publicação, `public-include-verified.json` e sincronização local.
- Backup de dados no servidor: `/var/backups/seo-circuitos-vinculos-20261030/`, com snapshot, ensaio, `inverse.sql` e estado publicado.
- Backup de runtime: `/var/backups/seo-circuitos-vinculos-20261030-runtime/baseline`.

Rollback exige correspondência exata com o estado publicado; não executar SQL inverso às cegas após novas edições. O `release.py rollback` do staging de dados confere o estado, remove somente as 22 associações inseridas e o novo percurso de 15 km e restaura os dois eventos/flags anteriores. O `release.py rollback` do staging de runtime confere hashes antes de restaurar o arquivo anterior e remover apenas o include novo.

## Continuidade

Rever Imperatriz quando houver fonte oficial verificável; depois, ampliar conteúdo útil pós-prova e detalhes de kits anunciados. A revisão dos vínculos futuros encontrados neste lote está concluída, exceto Imperatriz; a cobertura histórica/outros circuitos e a comprovação de impacto permanecem abertas. Andamento central no plano `Business/_codex/docs/2026-10-25_plano_seo_regionais_pace.md`.
'''
(S/'technical.md').write_text(text)
receipt={'method':'Chrome via CUA; páginas reais após publicação','date':'2026-10-30','desktop':{'path':'/circuito/estacoes/','upcoming':24,'screenshot':'estacoes-published-desktop.png'},'mobile':{'width':390,'cases':[{'path':'/circuito/estacoes/','upcoming':24,'scrollWidth':390,'innerWidth':390,'screenshot':'estacoes-published-mobile.png'},{'eventId':48557,'circuitLinkVisible':True,'distance15kmVisible':True,'scrollWidth':390,'innerWidth':390,'screenshot':'ribeirao-published-mobile.png'}]},'viewportReset':True}
for name in [receipt['desktop']['screenshot']]+[x['screenshot'] for x in receipt['mobile']['cases']]:assert (D/name).stat().st_size>1000
(D/'browser-verified.json').write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'technicalDocBytes':(S/'technical.md').stat().st_size,'officialSources':len(d['addMemberships']),'browserReceipt':True}))
