# Aracaju / Sergipe / Maratona — SEO e navegação no fim de semana

Solicitação e publicação em 31/10/2026. Esta frente passa à frente das correções gerais da auditoria de 10.000 páginas, sem encerrar as pendências anteriores. Plano principal: `2026-10-25_plano_seo_regionais_pace.md`.

## Resultado publicado

**Ajuste de navegação solicitado em 31/10, publicado às 17:06:55 (Brasília):** o link do componente compartilhado para o OpenResults agora usa `target="_blank"` com `rel="noopener noreferrer"`. Um template compilado; conferidas as quatro páginas públicas consumidoras, todas com HTTP 200 e o atributo correto. Preferência para novos links registrada no `AGENTS.md` do RoadRunners. Backup `/var/backups/seo-openresults-target-20261031/baseline`; recibos em `../staging/seo-openresults-target-20261031/`. Outros links legados fora desta rodada não foram republicados.

Road Runners: destaque específico no calendário de Sergipe, no calendário de Aracaju, na ficha da edição 2026 e na página permanente da Maratona. O bloco reúne programação por dia, consulta de resultados no OpenResults, fotos e navegação entre cidade, estado e histórico. Os horários vêm do [regulamento da organização](https://cdn.ticketsports.com.br/ticketagora/arquivos/evento/74615/feb8f700da6241dc8080aa658a63261a638981859777687336.pdf), primeira página: sábado 31/10, 21 km às 04h30 e 10 km às 05h; domingo 01/11, 42,195 km às 04h e 5 km às 05h. A fonte e a data de conferência aparecem no conteúdo; horários sujeitos à organização.

Na fonte Foco Radical, a galeria de sábado foi confirmada por nome, data e cidade: [10 e 21 km, 31/10](https://www.focoradical.com.br/evento/20261031-maratona-de-aracaju-2026-1o-dia-aracaju-14873). Ela não constava no vínculo consultado no banco, que apontava para [42 e 5 km, 01/11](https://www.focoradical.com.br/prova/20261101-maratona-de-aracaju-2026-2o-dia-aracaju-14873). Incluído atalho editorial de sábado, preservando os vínculos existentes e identificando nome/data de cada galeria. Não há busca facial, compra, login ou envio de imagem pelo nosso bloco. O link não promete que todas as fotos já foram publicadas.

OpenResults: chamadas na página da edição, Sergipe e Aracaju, com histórico de 2025 claramente separado. Aracaju antes apontava canonical para `/estado/SE/` e compartilhava a descrição genérica de estado. Agora entrega `https://openresults.run/estado/se/?cidade=aracaju`, título/descrição/h1 próprios; Sergipe entrega `https://openresults.run/estado/se/`. Outros filtros canonicalizam à seleção base de cidade/estado; demais localidades preservam o comportamento anterior.

## Limites e estados

- Evento confirmado: ID 39399, tag `2026-maratona-de-aracaju-2026`, agregado 77, início 31/10, término 01/11. Nenhuma data ou outro campo foi alterado no banco.
- Leitura inicial: zero resultados públicos de 2026; 8.787 registros públicos de 2025. Os números não são exibidos como resultado de 2026.
- A disponibilidade usa a regra já existente no OpenResults: existência de registro não documental e `status_final < 3`, sem carregar nomes. Consulta com cache de um minuto; a renderização reconhece importações do processo operacional existente. Não é placar ao vivo nem importação nova.
- A chamada exige edição ativa, tag/datas exatas, ausência de cancelamento/adiamento e ausência de PNC. No Road Runners regional, somente SE/todas ou Aracaju, primeira página sem filtros; EN/ES ficam preservados. A programação é recolhida automaticamente depois de 01/11, mantendo o histórico datado.
- A alteração recente de produção do OpenResults, que usa `includes/aviso_resultados_pnc.cfm`, foi preservada. O candidato partiu da produção, não sobrescreveu esse trecho com o checkout anterior.
- Não foram alterados Cloudflare, autenticação, permissões, robots, sitemaps, dados pessoais ou a política noindex das páginas pessoais. Não houve commit, branch, push ou PR.

## Arquivos e recuperação

RoadRunners: `estado/index.cfm`, `evento/index.cfm`, `includes/permanent_race_editorial.cfm` e novo `includes/aracaju_2026.cfm`. OpenResults: `estado/index.cfm`, `evento/index.cfm` e novo `includes/aracaju_2026.cfm`. Os dois includes pertencem a seus projetos, com consulta e renderização locais; sem dependência de filesystem entre sites.

Publicação principal às **13:58:53**, complemento de fotos às **14:07:15**, em Brasília. Baselines e candidatos completos em `../staging/seo-aracaju-20261031/`. Backups Road Runners fora do webroot: `/var/backups/seo-aracaju-20261031-rr/baseline` e `/var/backups/seo-aracaju-photos-20261031/baseline`. No OpenResults, respeitada a preferência documentada de não manter backups avulsos no servidor: recuperação pela cópia exata do baseline preservada no workspace e guardas de hash; transporte temporário removido.

Os checkouts locais foram sincronizados por hashes, incluindo a diferença de produção do aviso PNC. A dependência `includes/aviso_resultados_pnc.cfm`, já existente em produção e ausente no checkout, foi copiada integralmente para o local, sem alteração ou publicação: recibo `dependency-pnc.json`. Outras mudanças locais foram preservadas. O painel Semrush do Business não foi republicado nesta frente; a auditoria de 10 mil está registrada no plano.

## Evidência de verificação

Sete templates compilados, **17 cenários Adobe ColdFusion**: cidade/estado, filtros, outras localidades, ficha 2026, histórico 2025, página permanente, controle EN/ES. Um H1 e canonical por página, IDs HTML únicos, JSON-LD válido, mensagens sem alegação falsa de resultados e escopo da chamada conferidos. O teste de canonical da cidade falhou no HTML anterior e passou no publicado.

Revisão Astra sem achados impeditivos no diff inicial; conferidos independentemente os 17 HTMLs e o regulamento. O complemento de fotos surgiu na QA pública e foi validado novamente nos 17 cenários, incluindo acesso à galeria de sábado. Verificação pública final: sete URLs HTTP 200, conteúdo novo, canonicals e dois links de fotos presentes; sete hashes publicados e 14 dependências preservadas. Chrome desktop e iPhone 16/393 px: textos, tabela, botões e listas sem recorte no conteúdo conferido.

Os dois includes novos retornaram **403** em acesso público direto; `git diff --check` passou no escopo de ambos os projetos. Recibos: `candidate-verified.json`, `candidate-results.json`, `release-publish.json`, `photos-publish.json`, `release-verify.json`, `public-after.json`, `protected-includes.json` e logs no staging. A revisão não afirma indexação, ganho de ranking ou pico de tráfego; leitura GA4 anteriormente negada continua pendente, sem alterar permissões. Importação dos resultados, atualização da disponibilidade externa e medição do fim de semana continuam como passos operacionais a confirmar.
