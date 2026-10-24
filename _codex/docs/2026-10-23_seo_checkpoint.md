# Checkpoint — SEO Road Runners

Salvo em **23/10/2026, 09:24, Brasília**, a pedido do usuário antes de ir ao escritório. Retomar deste ponto; não refazer publicações já verificadas.

## Estado da meta

Objetivo ainda aberto: **Site Health do Road Runners acima de 80%**, medido em auditoria Semrush concluída com 5.000 páginas, dispositivo móvel e JavaScript desativado. A nota de IA é outra métrica e não atende essa meta.

Último resultado concluído: **22/10/2026 às 16:38 de Brasília** (`2026-10-22T19:38:00Z`), campanha **26661911**:

| Métrica | Resultado |
|---|---:|
| Site Health | 75% (antes 71%) |
| Estado da pesquisa IA | 79% |
| Erros | 30 (antes 44) |
| Advertências | 10.333 |
| Observações | 5.892 |
| Páginas rastreadas | 5.000/5.000 |

Conteúdo duplicado passou de 6 para 0; títulos duplicados, de 14 para 4; descrições ausentes, de 2 para 0. Os 4 títulos e 6 descrições duplicados restantes eram da loja, que o usuário confirmou **desativada**. Não foram corrigidos metadados na plataforma externa.

## Auditoria que já está rodando

Uma nova execução foi iniciada em 23/10, aproximadamente às 09:05, depois da publicação da retirada do atalho da loja. Na última observação, **975/5.000 páginas**, status **“Rastreando páginas”**. O controle de interromper estava presente; não foi acionado.

**Não reexecutar nem interromper a campanha.** Primeiro verificar se essa execução terminou. A coleta continua no Semrush durante a pausa do trabalho. Não mudar limite, dispositivo, JS, exclusões ou verificações para elevar artificialmente a nota. Mesmo com as mesmas configurações, o conjunto de URLs pode variar entre coletas.

- Chrome: browser ID `1`; sessão `🔎 SEO Road Runners`.
- Aba da campanha em andamento: `283501509`, binding `semrush23`, preservada para retomada.
- URL observada: `https://pt.semrush.com/siteaudit/campaign/26661911/review/issue/detail/24`.
- Aba do painel: `283502437`, binding `seoPanel23`, preservada como resultado.
- Painel: `https://business.roadrunners.run/portal/seo/?aba=fila&site=roadrunners`.
- Ao retomar uso do navegador após resumo, executar primeiro `await cua.rewriteDocumentation()`; inventariar abas se os handles tiverem expirado.

## Publicado e verificado nesta rodada

### Business

1. **08:51:58** — painel Semrush com os dados reais acima, comparativo 22/10 12:32 → 16:38. Arquivos: `portal/includes/seo_semrush_data.cfm` e `portal/conteudo/seo_semrush.cfm`. A base orgânica de 04/10, com 51 pares palavra-chave/URL e 6 oportunidades, foi preservada. Não atribuir a ela a data da auditoria nova.
2. **09:19:33** — `portal/includes/seo_queue_data.cfm`: revisão da fila em 23/10 às 09:13, 4 frentes novas e 46 itens antigos preservados. RR-36 encerrada por desativação da loja; RR-40/41/42 registram entregas; RR-43 mantém aberta a lentidão da São Silvestre. O histórico medido e a pontuação Semrush não foram reescritos como se fossem correções externas.
3. Gerador local `_codex/scripts/seo_semrush_snapshot.py`: retirada de `cfheader.statustext`, incompatível com Adobe 2025; códigos 403/405 e `Allow: GET` mantidos.

Validações do painel: 6 testes Python, 19 cenários Adobe antes/depois, 8 controles de acesso, 2 templates compilados e 11 dependências preservadas. Fila: 164 verificações de integridade, 22 cenários Adobe antes/depois, 8 controles de acesso, 1 template compilado e 6 dependências preservadas. Fila real conferida no Chrome em desktop. A tentativa de screenshot móvel da fila manteve o tamanho de desktop; **não contar como validação móvel**. Não houve mudança de CSS nessa publicação.

### RoadRunners

**09:03:41** — somente `includes/estrutura/menu_apps_data.cfm`: retirada do item Loja do fallback estático. O catálogo Business já tinha o app 7 como “Oculto”; nenhum registro precisou mudar. Os demais itens, grupos, URLs por idioma/ambiente e assinatura foram preservados. O catálogo sob demanda mantém os 8 apps ativos.

36 verificações Adobe em 9 combinações de ambiente/idioma; 1 template compilado; 5 páginas reais com HTTP 200, links para loja de 5 para 0 e metadados intactos; 9 dependências preservadas. Menu conferido em desktop e celular de 390px; viewport restaurado.

## Backups e recibos

Staging completo no Business: `_codex/staging/seo-rr-80-20261023/`.

| Publicação | Backup no servidor | Recuperação com guardas, se necessária |
|---|---|---|
| Painel | `/var/backups/seo-rr-80-20261023-panel/baseline` | `python3 _codex/staging/seo-rr-80-20261023/panel/release.py rollback` |
| Menu RR | `/var/backups/seo-rr-80-20261023-fallback/baseline` | `python3 _codex/staging/seo-rr-80-20261023/release_fallback.py rollback` |
| Fila | `/var/backups/seo-rr-80-20261023-queue/baseline` | `python3 _codex/staging/seo-rr-80-20261023/queue/release.py rollback` |

Não executar rollback preventivo: tudo acima foi publicado e verificado. Os recibos estão em `panel/release-*.json`, `runtime/release-*.json` e `queue/release-*.json`. Fontes da coleta concluída: `panel/source-final.json`, `comparison-ui.parsed.json`, `comparison-ui.txt`. Capturas reais: `panel/published-desktop.png`, `queue/published-desktop.png`, `menu-published-desktop.png` e `menu-published-mobile.png`.

Uma primeira preparação da publicação da fila foi bloqueada por caminho incorreto do verificador. O helper foi corrigido para `/var/www/business.roadrunners.run`; **não houve conflito real nem alteração de dependência de produção**. Não repetir a hipótese inicial de mudança de outra frente.

## Investigações ainda abertas

- **São Silvestre:** 5 páginas lentas na coleta concluída. Consulta de edições com 1,3–2,6 s, aproximadamente 1,8 s no EXPLAIN ANALYZE. Três alternativas foram ensaiadas sem ganho; nenhuma foi publicada. O backend candidato foi restaurado ao baseline. O teste de equivalência de 34 casos sintéticos e 32 edições reais pertence apenas ao primeiro candidato, não aos demais. Não reutilizar seu recibo para uma nova consulta. Preservar empates, PCD, concluinte, homologação e perfil público/privado. Evitar benchmarks pesados enquanto o crawler estiver ativo.
- **Hreflang:** 1 achado em `2026-clandestina-ou-travessuras?/`. A URL com `%3F` tinha canonical e alternates corretos; variantes literais não existem. Investigar normalização do relatório antes de qualquer alteração de slug/dados. Não inventar redirecionamento só para suprimir o alerta.
- **Links internos quebrados/4xx:** parte dos 13 links e 1 resposta 4xx envolve `/cdn-cgi/l/email-protection` no rastreio sem JS. Não desativar proteção ou autenticação para elevar a nota.
- **Redirecionamentos temporários:** a lista de 4.799 ocorrências inclui links repetidos para `/estado/` (redirecionamento por preferência de estado) e caminhos com autenticação. São ocorrências de links, não 4.799 páginas quebradas; não converter redirecionamentos pessoais em 301 indiscriminadamente. Snapshot em `redirects-ui.txt`.
- **Minificação:** detalhe 135 foi aberto em aba de pesquisa `283502447`, mas ainda não foi extraído. URL observada: `https://pt.semrush.com/siteaudit/campaign/26661911/review/issue/detail/135`. Nenhuma alteração iniciada; essa aba não é necessária para continuar o crawler.

## Primeiro passo na retomada

1. Ler este checkpoint e `2026-10-23_seo_semrush_5000.md`; conferir estado Git e instruções dos projetos antes de novas alterações.
2. Observar a campanha existente. Se ainda rastreando, continuar acompanhando sem reiniciar. A nota do painel permanece 75% até haver nova coleta concluída.
3. Ao terminar, confirmar 5.000 páginas/móvel/JS desativado, horário real, Site Health, IA e totais. Extrair o comparativo completo contra **75/79/30/10.333/5.892** e reconciliar somas.
4. Importar em **staging e backup novos**, sem sobrescrever os baselines de publicações anteriores. Atualizar texto e métricas do painel com a nova fonte; preservar dados orgânicos, controles de acesso e trabalho alheio. Compilar, publicar só o escopo e verificar a tela real.
5. Se Site Health continuar em 80% ou menos, priorizar correções reais remanescentes. Só declarar a meta atingida quando o fornecedor mostrar **acima de 80%**, com o painel correspondente publicado e conferido.

## Preservação e autorização

Não houve escrita no banco, alteração de credenciais/permissões, DNS, Cloudflare, configuração da campanha ou ações na plataforma externa da loja nesta rodada. Não houve commit, branch, tag, push ou PR. “Checkpoint” aqui é documentação e cópia dos arquivos do escopo, **não um commit Git**.

Há muitas mudanças alheias no Business (audiência, navegação, comparador, estudos) e no RR (`circuitocatarinense/trailrun/index.cfm` e documentos relacionados). Preservar. Arquivos SEO de rodadas anteriores também estão modificados: nunca publicar um diretório inteiro. O footer de produção do RR tinha uma adição de Radar de outra frente; publicar o footer local inteiro pode apagá-la. O `head.cfm` do Business também tem diferenças alheias de versões de CSS.

Cada publicação futura deve comparar baseline de produção, manter backup recuperável, compilar/testar o escopo e verificar resultado real. Os roots são distintos: Business `/var/www/business.roadrunners.run`, RR `/var/www/roadrunners.com.br`. A preferência do usuário continua sendo publicar alterações autorizadas ao final sem nova confirmação; isso não autoriza operações Git nem mudanças alheias.

Manifesto e cópia dos quatro arquivos de runtime publicados e do gerador local: `_codex/staging/seo-rr-80-20261023/checkpoint/`. Não contêm arquivos centrais de credenciais ou uma cópia de todo o workspace.
