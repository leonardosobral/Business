# Medição das regionais e da calculadora — 25/10/2026

Lote publicado às 18:48 (Brasília). Responsabilidades: RoadRunners encaminha as duas ações da calculadora pela tag Google existente; Business exibe o snapshot histórico do Search Console dentro da aba Audiência Google.

## Entregue

- `assets/js/runnerhub-pace.js` e minificado: `rr_pace_calculate` depois de cálculo válido e `rr_pace_calendar_click` ao seguir para o calendário. Encaminhamento explícito para G-7MYGVTEDZV com apenas `calculator_mode` (pace/time/distance) e transporte beacon. Nenhum valor livre de ritmo, tempo, distância ou perfil é acrescentado ao evento.
- Elegibilidade reutiliza `RoadRunnersAudienceConfig.context`: produção e visitante não interno, host HTTPS RR, tag disponível, sem GPC/opt-out em storage/cookie. Ausência do contexto ou erro de armazenamento/tag falha sem interromper cálculo ou navegação. A tag existente continua responsável pelo consentimento e transporte. Nenhuma alteração de GTM, OAuth ou permissões.
- Versão do script na calculadora atualizada. Não mantém o antigo push de objeto no dataLayer, evitando duplicação caso o contêiner evolua. A inspeção do GTM público encontrou zero referências às ações de pace; o comando gtag é o caminho utilizado por esta entrega.
- Business: `portal/conteudo/seo_growth_baseline.cfm`, incluído por `seo_ga4.cfm`, exibe período, resumo, três páginas e dez consultas em detalhes recolhíveis. Não aparece no filtro OpenResults. Acesso direto 403, painel anônimo redireciona para login; proteção administrativa preservada.

## Baseline e limites

Search Console, Web, todos os países/dispositivos, 26/09–23/10: piloto PR/Curitiba e DF/Brasília com 316 cliques, 10,7 mil impressões (arredondado), CTR 2,9%, posição 7,4. PR: 197 cliques/4.888 impressões; DF: 119/5.826; Curitiba: 0/5. Brasília cidade não teve linha retornada, o que não prova ausência de indexação. Dez consultas capturadas dentre 241 exibidas. Regex e valores em `gsc-baseline.json`, tabelas originais em `gsc-pages.txt` e `gsc-queries-top10.txt` no stage Business.

Este período é anterior às mudanças de 25/10. Comparar com janelas completas de 28 dias posteriores; não atribuir a alta já existente à nova entrega. O snapshot é manual, não uma nova integração contínua.

O painel Business informou falta de autorização `analytics.readonly` da conexão existente. Não foram concedidas permissões. O navegador Analytics estava em uma propriedade OpenResults; seus dados não foram usados como RR. **Recebimento real dos eventos no GA4 ainda não comprovado.** Próxima ação do usuário: Autorizar Google Analytics na aba de audiência com a conta da integração. Depois validar propriedade com fluxo G-7MYGVTEDZV e consultar Realtime/DebugView. Emissão validada em testes não equivale a recebimento.

## Triagem editorial, ainda não correção factual

Inventário dos cards públicos de Curitiba/Brasília salvo em `pilot-inventory.json`. Seleção inicial:

| Ficha | Observação no card | Próxima conferência |
| --- | --- | --- |
| `/evento/2026-maratona-de-curitiba-santander-2026/` | 15/11; distâncias 5/10/21, sem 42 | Conferir distâncias e modalidades no regulamento da edição; o nome não autoriza acrescentar 42 automaticamente. |
| `/evento/2026-maratona-monumental-de-brasilia-2026/` | 22/11; distância vazia, aparecendo apenas “km” | Conferir modalidades, local, horários e fonte oficial. |
| `/evento/2026-live-run-xp-brasilia-2026-iii/` | 13/12; 5/10/15 e anúncio de cupom | Conferir condições comerciais e inscrição na origem antes de afirmar validade. |
| Night Run Curitiba, slugs com e sem Santander | Cards em 31/10 e 07/11 | Verificar se são provas/edições distintas antes de tratar como duplicidade ou corrigir datas. |

Não houve alteração de data, distância, oferta ou banco nesta rodada. A revisão editorial aprofundada continua pendente; esta triagem não conta como ficha corrigida.

## Verificações e recuperação

20 testes Node (10 regressão matemática/navegação e 10 medição fonte/minificado), 3 templates compilados no Adobe ColdFusion, 6 cenários de render/acesso. Cinco verificações HTTP públicas: página, dois assets com hash idêntico, include direto e painel anônimo. Navegador autenticado: painel desktop/mobile 390 px, detalhes/tabelas e pendência OAuth; calculadora funcional no mobile, 5 km em 30 minutos = 6:00. Largura da página 390 px, tabelas rolam internamente. Contexto anônimo elegível confirmado por HTTP com user-agent de navegador; curl padrão é excluído pelo controle de audiência existente.

Backup de cada projeto: `/var/backups/seo-measurement-editorial-20261025/{RoadRunners,Business}/baseline`. Cinco hashes de runtime e oito dependências preservadas conferidos; stage e scripts de verificação em `Business/_codex/staging/seo-measurement-editorial-20261025/`. Não houve migração, DataGrip, commit ou push.
