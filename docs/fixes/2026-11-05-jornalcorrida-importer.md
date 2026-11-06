# Jornal da Corrida — falha de extração no job 13

O job 13 recebia HTTP 500 com 20 erros por execução. O retorno completo mostrou que todos eram “Item ignorado por não ter título ou corpo útil”. A notícia oficial continha o corpo; o mecanismo de regex do ColdFusion não localizava a seção `post-description` no HTML Wix de 982.787 caracteres, embora `find()` e o parser HTML a localizassem.

O extrator compartilhado usa agora o Jsoup já disponível no runtime, limitado à seção de conteúdo. Mantém a limpeza existente, preserva seções aninhadas e a imagem original `data-pin-media`. Sem a seção, continua retornando vazio; não importa a página completa como substituto. As regras editoriais, deduplicação, autenticação e agendamento permanecem no código existente.

A compactação do histórico Business preserva até três amostras de erros com mensagens limitadas, dentro do limite existente de 4.000 caracteres.

Verificação: regressão reproduzida antes da correção; 11 verificações nativas aprovadas. Importação real após publicação: HTTP 200, 20 processados, 3 criados, 17 atualizados, zero erros. Nenhuma alteração de DDL, credenciais, agenda ou operações Git.

Evidência: `_codex/deploy/jornalcorrida-extraction-20261105.json`. Backup recuperável: `/var/backups/business-jornalcorrida-k6s9qul0`. Publicação restrita a `conteudo.roadrunners.run/admin/importer_contrarelogio.cfm` e `business.roadrunners.run/includes/backend/cron_jobs_service.cfm`; baseline e hashes dos arquivos preservados conferidos.
