# Situação no Google e nota técnica — 03/10/2026

Publicados quatro templates: portal/conteudo/seo.cfm, seo_report.cfm; portal/includes/seo_queue_data.cfm e novo seo_search_evidence.cfm.

A situação no Google precede a pontuação técnica, recolhida em details. Fonte/data/limite da evidência manual aparecem em cada site. Não há nota geral de SEO. RoadRunners: sitemap processado, 103.036 URLs descobertas na captura, indexação desconhecida. OpenResults: falha de busca do sitemap reportada mesmo após a nova URL XML, indexação desconhecida. O zero do relatório sitemap não é interpretado como zero indexadas.

Fila: 19 itens, 15 concluídos, quatro pendentes. SH-03 concluído; OR-04 novo incidente P1. OR-03 histórico JSON-LD preservado. Nota, fórmula, datas das auditorias e históricos não foram modificados. Novas evidências são curadas manualmente neste include, independentemente de auditorias do coletor; a tela explicita que não é consulta ao vivo.

Validação: teste contra produção anterior falhou por ausência do estado Google; candidato aprovado em Adobe. Revisão Astra identificou ID duplicado OR-03, corrigido para OR-04 e coberto por teste de unicidade. Quatro CFML compilados, 51 testes Node aprovados. Renderização publicada confirmou warning/error, duas notas recolhidas, 70/100 técnicos preservados, totais da fila corretos. Desktop1280 e celular390 sem transbordamento; Enter expande nota. Guardas administrativas preservadas; fixture temporária local com guarda real, sem representar login de usuário.

Baseline produção e fonte conferidos, backup recuperável em /var/backups/seo-search-status-20261003/baseline, quatro hashes finais e seis dependências intactos. Sem Git mutations, alterações Cloudflare ou execução de cron pago. Artefatos e recibos em _codex/staging/seo-search-status-20261003.

Leitura visual Cloudflare nesta sessão: regra geográfica OpenResults desativada, expressão excluindo BR/US/bots conhecidos. Nenhuma configuração alterada. O bloqueio 1010 ao cliente Python registrado no lote anterior não comprova bloqueio do Googlebot. Incidente segue aberto até confirmação do Search Console.

## Atualização posterior: indexação histórica conferida

Após a primeira entrega, foi possível consultar o Search Console autenticado. Substituída a ausência de medição por evidência datada de 20/09/2026: RR14,1milindexadas, ORzero e135.791bloqueadas403. A apresentação avisa que não mede a situação após as mudanças de03/10. Três CFML novamente compilados/publicados e renderização verificada; fórmula/históricos preservados. Backup do lote posterior: /var/backups/seo-google-index-20261003/baseline.
