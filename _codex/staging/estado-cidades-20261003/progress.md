# Ledger — plan: estado-cidades-20261003/plan.md

Spec: desenho aprovado na conversa pelo usuário em 03/10/2026.
Pre-flight: include produz qEstadoCidades e estadoCitiesData; página e API consomem o mesmo contrato; JS não altera RunnerHubEventFilters compartilhado.
Decisão: isolamento em cópia staging, sem worktree nem commits, conforme proibição expressa de operações Git nas instruções do workspace. Baselines e hashes protegem mudanças alheias; custo se inadequado: instalação deve abortar diante de divergência.

Task 1: RED observado (5 navegação e contagens ausentes); GREEN 5 Node, 8 asserts Adobe real; 3 templates compilados. Runtime local antigo indisponível; teste CFML executado no Adobe real com fixtures sintéticas, sem acesso a dados pessoais nem mutações no banco.
Final review Astra: 1 Important (payload de contagens antigo) corrigido com assinatura semântica; testes RED→GREEN 8/8 incluindo distância inicial ativa. Reclassificado o Minor da lateral zerada como regressão funcional: teste de renderização Adobe RED, contêiner agora persistente para restaurar a lateral.
Verificação móvel: preview 390px produziu overflow 403px; correção scoped box-sizing preparada.

Task 2: GREEN: Adobe renderizou 230 cidades da Bahia, total 184 provas e 65 em 30 dias. Lateral vazia preservada e restaurada no browser; payload atrasado simulado não alterou as 65 provas. 390px sem overflow (scrollWidth=390); Escape fecha e retorna foco ao summary; desktop 1280px conferido.
Revisão encerrada: todos os achados resolvidos com testes, sem itens adiados. Sem mudanças no controlador compartilhado, anúncios ou banco.

Task 3: complete. Publicados 5 arquivos, hashes 5/5 e 7 arquivos alheios preservados. HTTP 200 em 5 alvos; canonical regional sem filtros. Verificação real Alagoinhas → Todas as cidades → SC manteve cupom=true; AJAX atualizado: estado=1 prova, Alagoinhas=0. Testes finais Node 31/31 e Adobe 8/8. Documentação instalada no RoadRunners.
