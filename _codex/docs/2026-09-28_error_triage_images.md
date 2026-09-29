# Imagens ausentes — 28/09/2026

A aba Imagens ausentes em `/portal/erros/?aba=imagens` consulta os logs originais de 404 desde o início do recorte ativo (após a revisão do handler). Inclui ocorrências ainda não coletadas. Não altera logs, status, categorias ou arquivos do RoadRunners.

Agrupa por site e caminho exato, preservando maiúsculas, removendo host HTTP/HTTPS e parâmetros apenas para agrupamento. Inclui extensões png, jpg/jpeg, gif, webp, svg, ico, avif, bmp, tif/tiff e apng; ignora uma extensão presente apenas na query string ou seguida de outra extensão. Exibe totais, primeira/última ocorrência, contagem, log original e problema quando o exemplar já estiver coletado. URLs de origem completas continuam acessíveis no log.

A ordem padrão é última ocorrência decrescente; há opção por maior frequência, filtro por site e paginação de 25 caminhos. Trata-se de histórico de respostas 404, não de uma sondagem da disponibilidade atual. Não baixa nem executa arquivos dos caminhos listados. Criar um arquivo não remove automaticamente o histórico. Demais 404 continuam em Logs/Acompanhamento.

Reutiliza controles de abas, navegação por teclado e layout do Business. Conteúdo de log é escapado; apenas links administrativos são gerados. Consulta delimitada por log_item/data usa o índice existente; sem migração.

Validação: suíte CFML isolada com 66 asserções e 6 verificações HTTP de acesso/CSRF; testes JS existentes. Publicação limitada a ErrorTriage.cfc, home.cfm e includes/images.cfm. Backup recuperável em `/var/backups/business-error-triage-images-20260928/baseline`; publicador `_codex/scripts/deploy_error_triage_images.py` verifica baseline e hashes e suporta rollback sem alterar dados.

Verificação real após publicação: três hashes conferidos, compilação CFML 3/3, consulta RR com 56 caminhos e 607 ocorrências (71 ms nesta medição). UI autenticada validada em desktop e viewport 390×844, filtros, paginação e navegação por setas entre abas. Tabela móvel tem rolagem horizontal dentro do painel. Capturas em `_codex/staging/error-triage-images/desktop.png` e `mobile.png`.
