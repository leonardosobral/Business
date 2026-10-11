# Aquisição e retorno aos anunciantes

Atualização de 08/10/2026.

## Business

A aba `Retorno aos anunciantes` em `/portal/audiencia/#audience-advertisers`
cruza a campanha UTM da sessão com anúncios comerciais do sistema Ads por
`delivery_id` e `campaign_id`. Consulta somente leitura; não muda faturamento.

- Entregas renderizadas e vistas são deduplicadas por entrega.
- Exposição exige o evento existente de 50% visível por 1 segundo.
- Sessões com exposição são únicas por origem/meio/campanha/anúncio.
- Cliques exigem `ads.events.event_type='CLICK'`, `valid=true`, a mesma entrega
  e campanha e recebimento dentro do período selecionado.
- A última coluna mostra entregas vistas que também tiveram clique e sua taxa.
- Peças institucionais, entregas sem identificador e visitas sem campanha UTM
  ficam fora. Banners legados sem vínculo de entrega não estão cobertos.
- Não somar sessões entre anunciantes como pessoas distintas. Não interpretar
  cliques como inscrições, receita ou créditos faturáveis.

Os filtros gerais permanecem aplicáveis. Falha na consulta opcional apresenta
indisponibilidade sem impedir os demais relatórios. Acesso continua restrito a
administradores; a consulta SQL permanece protegida pelo diretório existente.

Arquivos: `portal/audiencia/queries/advertiser_acquisition.sql`,
`portal/audiencia/advertiser_acquisition.cfm`,
`portal/includes/audience_backend.cfm`, `portal/audiencia/home.cfm`.

## RoadRunners e Google

O rastreador existente de saída para inscrição LIVE! também envia
`rr_live_registration_outbound` ao GA4 `G-7MYGVTEDZV`, pela tag já instalada.
Somente produção, visitantes não internos, links LIVE! e IDs de prova válidos;
respeita opt-out e GPC. Não envia URL, identidade, valor ou receita. Não impede
a navegação. Há deduplicação por prova e sessão durante a vida da página.

GA4 RoadRunners (419141470): evento principal, uma vez por sessão, sem valor
padrão. Google Ads: `RR | Saída para inscrição LIVE!`, origem GA4, secundária,
contagem Uma, fora das metas da conta, sem valor monetário. Os lances seguem
por cliques. A recepção real pelo Google ainda depende do primeiro clique de
visitante e processamento; os testes não fabricaram conversões de produção.
A ação representa saída para inscrição, nunca compra confirmada na LIVE!.

Arquivos RoadRunners: `assets/js/rr-audience.js` e
`includes/analytics/bootstrap.cfm` (versão de cache).

## Operação e validação

Display C pausado; orçamentos A/SC, D/Maringá e E/interior SP preservados;
LIVE! preservada. B/resultados já estava pausada.

Publicados seis arquivos após comparação com produção, backup e compilação
CFML. Backup recuperável: `/var/backups/ads-followup-20261008` no servidor.
Dependências de outras frentes verificadas por hash e preservadas.

Evidências e scripts locais em `_codex/staging/ads-followup-20261008/`:
9 testes do rastreador, 7 verificações SQL com dados sintéticos em consulta
somente leitura, 10 verificações de renderização/dados/acesso, hashes dos seis
arquivos publicados e nove dependências preservadas. `release.py rollback`
restaura apenas os arquivos desta publicação, condicionado aos hashes esperados.

Verificação por navegador: homepage pública carregou a versão `6db9c5e7be65`
do rastreador, a tag GA4 correta e contexto prod/não interno. Preview local do
HTML renderizado em produção conferido em 1366 e 390 px, sem transbordamento
da página; a tabela tem rolagem própria. O painel autenticado completo não foi
inspecionado após publicação: o navegador isolado não compartilha essa sessão.
