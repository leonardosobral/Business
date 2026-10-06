# Runner Apps e recuperação da indisponibilidade — 04/10/2026

## Resultado verificado

Verificação pública às 02:34 UTC de 05/10 (23:34 de 04/10 em São Paulo): RoadRunners 200 em 0,106 s; Business 200 em 0,073 s; OpenResults busca 200 em 0,419 s; API catálogo 200 em 0,135 s. Apache: 2 workers ocupados, 73 livres, load1 0,43. O 503 temporário do OpenResults foi retirado. Home e estado tiveram HTTP 200 na origem; home pública 200 em 8,24 s, ainda lenta.

O processo ColdFusion PID 1756 continua iniciado em 14/09/2026. O Apache recebeu um reload graceful para aplicar limite de negociação TLS; seu processo pai PID 3808619 foi preservado. Não houve reinício do ColdFusion neste incidente. O limite de 150 workers não foi aumentado.

## Evidências e mudanças

Havia 147–149 workers ocupados e fila HTTPS cheia. A amostra inicial de conexões estava esperando negociação TLS com timeout de 300 segundos; aplicado RequestReadTimeout handshake=10, mantendo os limites existentes de cabeçalho e corpo. Só essa alteração não resolveu: a geração nova também ficou esperando AJP/ColdFusion.

As pilhas CFML apontaram cópia do catálogo de eventos e Query of Queries no backend compartilhado do OpenResults, inclusive em evento, resultados, busca e 404. Essas páginas não necessitam do catálogo completo. Banco predominantemente ocioso, sem evidência de bloqueio explicando a saturação. CPU estava praticamente toda ocupada. RSS Java alto não demonstrou heap esgotado; não foi diagnosticado OOM.

OpenResults: includes/backend.cfm agora carrega o catálogo somente para home e estado; .htaccess encaminha 404 para 404/index.html estático. A contenção 503 autorizada permitiu drenar o trabalho e foi removida depois da validação. O handler OnError legado ainda merece revisão; esta mudança não resolve todo seu envio repetido de e-mails.

Runner Apps: Business continua dono do cadastro e do componente Catalog.cfc. API pública serve /v1/discovery/runner-apps.cfm por mapeamento local do componente, sem HTTP ao Business. O legado Business responde 308 e não inicializa o portal. Catálogo público só contém ativos; incluir_ocultos retorna 400; linha=principal preservado. API de perfil sem credenciais retornou 401.

RoadRunners: cache com TTL 300 s, última resposta válida entregue imediatamente, uma atualização em background por aplicação e pausa de 60 s após falha; fallback estático no início. A factory junto aos CFCs corrige resolução quando o cabeçalho é incluído pelo OpenResults. Esse cenário de compartilhamento faltou nos primeiros testes e foi acrescentado à validação real antes de retirar a contenção.

GoRunners: URL alterada no código local backend/src/services/runnerAppsService.ts. NÃO publicado no servidor externo do jogo, cujo acesso/deployment não foi identificado. O endereço anterior mantém compatibilidade por 308; consumidor usa fetch com seguimento de redirecionamento.

## Validação e rastreabilidade

- Teste anterior reproduziu bloqueio de ~3 s e perda do cache antigo na falha.
- Testes CFML isolados: 12 verificações do cache, 8 do catálogo, 8 da API, 5 do legado e concorrência de quatro leitores com uma atualização. Sucesso registrado em staging/runner-apps-20261004/tests-green.json.
- Escopo do catálogo: baseline reproduziu quatro carregamentos indevidos; seis rotas passaram com a correção. CFML compilado antes de publicar.
- Factory testada em aplicação isolada fora do webroot do RoadRunners; componentes criados com sucesso; depois home, busca e estado OpenResults 200 reais.
- Hashes finais de 13 arquivos conferidos; verificações HTTP e estado em staging/runner-apps-20261004/final-recovery.json.

Backups recuperáveis no servidor:
- /var/backups/runner-apps-20261004-v2-provider/
- /var/backups/runner-apps-20261004-v2-rr/
- /var/backups/runner-apps-20261004-v2-legacy/
- /var/backups/runner-apps-shared-factory-20261004/
- /var/backups/openresults-static404-20261004/
- /var/backups/openresults-catalog-scope-20261004/
- /var/backups/apache-tls-timeout-20261004/

Rollback deve conferir hashes e restaurar em ordem inversa, preservando alterações posteriores. A factory é posterior ao release RR v2: restaurar primeiro sua alteração se reverter esse release. Nenhuma migração ou alteração de permissão do banco realizada.

## Pendências explícitas

A home do OpenResults ainda exige investigação de desempenho; a recuperação observada não garante ausência de futuras saturações. Outras chamadas HTTP síncronas de conteúdo do RoadRunners permanecem fora desta alteração. O deployment externo do GoRunners não foi executado.
