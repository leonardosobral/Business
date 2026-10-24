# Classificação das campanhas Awin — 22/10/2026

Publicado no Business em **PLATAFORMA → Comparador → Integração Awin → Vinculação e publicação**. A página abre em **Precisam de revisão** e oferece as listas **Fora do catálogo**, **Vinculadas**, **Bloqueadas** e **Todas**, com contadores, busca por campanha/motivo e filtro de programa.

As 40 campanhas da revisão de hoje receberam a classificação **Fora do catálogo**, com os motivos já conferidos. Resultado em produção: **40 fora do catálogo, zero precisando de revisão**, sem novos vínculos de campanha. As **95 ofertas de preço**, bloqueios do feed e regras editoriais anteriores foram preservados.

## Comportamento

A classificação usa `rules.mode=fora_catalogo`, com motivo, data, identidade da campanha e candidatos já conferidos. Ela persiste no mesmo estado privado e no histórico existente. Uma campanha desconhecida ou ambígua continua em revisão: falta de correspondência não a classifica automaticamente fora do catálogo.

O administrador pode salvar o motivo, mover explicitamente para revisão (`mode=revisar`), restaurar a identificação automática, bloquear ou confirmar produtos. Ações mantêm administrador global sem delegação, POST, CSRF e token otimista. Mudanças de título, descrição, condições, cupom, destino ou validade invalidam a classificação. Uma correspondência automática que não existia na revisão anterior também reabre a fila; nenhuma dessas reaberturas publica um vínculo automaticamente. Coleções genéricas continuam exigindo conferência humana da seleção da loja.

O contrato continua na versão 1. Decisões passam a incluir `classification`; histórico, resultado do serviço e API acrescentam `outsideCatalog`. O campo `pending` passa a contar somente a fila de revisão. O Comparador continua consumindo apenas as ofertas elegíveis; nenhum arquivo de runtime do consumidor foi alterado.

## Verificação

- **46 testes CFML**, incluindo persistência, mudança de campanha, novo modelo, reabertura, restauração automática, motivo obrigatório, CSRF, concorrência e regressões de vínculo/bloqueio.
- Renderização dos templates no ColdFusion de produção em fixture privada: revisão vazia, 40 campanhas fora do catálogo, editor e filtros por busca/programa.
- Prévia dos mesmos templates e estilos conferida em **1280 × 960** e **390 × 844**, sem transbordamento horizontal. As capturas são de fixture isolada; não simulam uma sessão administrativa de produção.
- API pública: GET 405 e POST sem autenticação 401, usando agente de validação identificado.
- Job 24 executado pelo mecanismo existente, com lock, autenticação e histórico: **run 236138**, **200 OK**, `success=true`, `pending=0`, `outsideCatalog=40`, sete feeds sem erros e 95 ofertas de preço. Os leitores reais aceitaram 66 produtos e 1.881 variantes. Próxima execução: **12h25 de Brasília**, intervalo de 30 minutos preservado.

## Publicação e recuperação

Release **20261022T145246Z-cicd0nxl**. Cinco arquivos de runtime no Business: `services/ComparadorAwinPublicationService.cfc`, `administracao/comparador/awin/{backend,home,publication}.cfm` e `api/comparador/awin-sync.cfm`. O teste foi atualizado no workspace. Baselines e hashes conferidos antes/depois, sem sobrescrever mudanças de outras frentes.

A classificação inicial foi uma operação autorizada por SSH, sob o mesmo lock da publicação. Conferiu identidade e condições das 40 campanhas, recusou sobrescrever regras existentes, preservou as anteriores e registrou `classificacao_catalogo_operacional` com ator de operação do servidor. Não foi criada nem simulada sessão administrativa. O job normal confirmou a persistência em seguida.

Backup privado de runtime e estado anterior em `/var/backups/awin-triagem-20261022/20261022T145246Z-cicd0nxl`. Para recuperar uma versão, comparar os hashes com o recibo e considerar alterações posteriores; não restaurar o estado inteiro sobre novas decisões editoriais. O código anterior trata essas regras sem produtos como pendências, sem gerar vínculos, caso seja necessário reverter somente o runtime. Preservar configuração, preços, histórico e fontes atuais.

Sem migração de banco, mudanças em `tb_cupom`, novos produtos ou alterações de mídia/World Athletics. Nenhum cron adicional, commit ou branch foi criado.

[Recibo sanitizado](../../../Comparador/codex/docs/evidencias/awin-triagem-2026-10-22.json) · [Revisão das campanhas](../../../Comparador/codex/docs/2026-10-22_awin-revisao-campanhas.md) · [Gestão no Business](https://business.roadrunners.run/administracao/comparador/awin/?aba=publicacao).
