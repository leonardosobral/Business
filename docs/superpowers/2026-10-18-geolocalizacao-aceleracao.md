# Geolocalização: aceleração segura

Solicitação aprovada em 18/10/2026: cron a cada minuto, corrigir 502 e otimizar cache, preservando teto compartilhado de 2.000 consultas/dia UTC, no máximo uma por segundo, sem sobreposição e sem relaxar confiança. Alteração delimitada ao fluxo existente; nenhuma nova migração, credencial ou compra. O usuário dispensou novas pausas de aprovação de planejamento.

## Diagnóstico

- Baseline remoto dos 15 arquivos conferido; serviço de cron coincide com HEAD (`2cdbbdcb…7270`).
- Logs CFHTTP: 11 consultas Geoapify sem conclusão precederam 11 respostas 502 do endpoint. 173 consultas concluídas retornaram 200. Falhas não expõem exceções/URL/chave.
- Cliente tinha timeout de 8s; endpoint convertia qualquer erro de consulta em 502, cuja resposta era substituída no caminho público por erro genérico. O cron agendava `fim + intervalo`, resultando em ~6 minutos para intervalo de 5.
- Cache existente já reaproveita consultas, mas o bloqueio antecipado por cooldown impedia seu uso; a normalização antiga apagava pontuação de endereços.

## Implementação e aceitação

1. Regressões RED→GREEN: distinção de endereço, exclusão/recuperação de lote por token no banco, rejeição do cache legado sem proveniência, cache durante cooldown, HTTP de tentativas preservadas, cadência alinhada exclusiva deste endpoint e prioridade do worker já devido.
2. Timeout limitado de 15s e orçamento antes de consultas de 17s dentro do lote de 45s. Pausa de fornecedor de 60s para timeout/indisponibilidade; 429 respeita Retry-After. Três tentativas continuam limitadas, com erros terminais visíveis.
3. Lease de lote de 120s na tabela já existente, maior que timeout de requisição de 60s, com conferência antes de novas ações e liberação tokenizada em finally. Lease por item e reserva serial/quota por fornecedor mantidas.
4. Cache v2 preserva pontuação. Revisão independente identificou que o upsert legado pode associar texto de consulta antigo à resposta de endereço colidente; por isso nenhum resultado v1 será reutilizado. Permanecem armazenados, sem exclusão. Cache de fontes/robots permanece. Resultados v2 continuam passando por todas as verificações de fonte/região/confiança/CAS.
5. Retorno 202 informa processamento adiado/aceito na fila, sem declarar coordenadas encontradas; `success=false/errors` permanecem em falhas reais. Erros internos/terminais 500 e configuração 503.
6. Publicar somente sete arquivos de runtime após revisão independente, backup recuperável e baseline CAS. Atualizar apenas job 25 para intervalo 1. No aceite, a fila compartilhada demonstrou espera atrás de outros jobs: seleção agora prioriza somente a geolocalização já devida; mantém oldest-first entre os demais e o limite global 5 (quatro slots restantes). Tolerância de 2s evita perder o tick pela diferença de relógio entre web e banco. Nenhuma alteração de relógio ou crontab.

## Registro

- Suíte nativa completa de 12 modos e testes Python do pesquisador executados antes da revisão.
- Nenhuma alteração de Policy/Sources/limiares de autoaprovação. Cidade permanece sugestão privada; coordenadas existentes não são substituídas.
- Sem commit/push. Recibos de publicação e validação em `_codex/deploy/geocoding-aceleracao-20261018*.json`.
- Publicação inicial com backup `/var/backups/business-geocoding-sources-h1mduxgj`; follow-ups recuperáveis `8h1wzug7` e `gd2j4u09` no mesmo prefixo. Configuração anterior preservada em `/var/backups/geocoding-tests-71yhc2_c` e ativação em `cqmk3cmd`.
- Concorrência HTTP real: enquanto um lease estava ativo, outra requisição assinada retornou 202 `worker_busy`, 0 itens e 0 chamadas (`/var/backups/geocoding-tests-_0_sx5gy`).
- Recuperados 17 itens v2 esgotados por falha antiga de fornecedor, via enqueue normal com autor `maintenance:timeout-fix`, sem consulta/API ou aplicação de coordenadas; auditoria permanente preservada (`/var/backups/geocoding-tests-duibvdex`).
- Um timeout externo voltou a ocorrer com 15s: retorno 202 explícito, `success=false`, erro persistido e próxima tentativa limitada. Uma execução de cooldown consumiu zero chamadas. Não se afirma disponibilidade contínua do fornecedor nem ausência garantida de timeouts.
