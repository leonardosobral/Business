# Recuperação Apache — 04/10/2026, 21h47 (São Paulo)

Incidente reportado: sites não carregavam. RoadRunners, Business e OpenResults excederam 12 s sem receber resposta. Apache ativo, Syntax OK, MPM event, MaxRequestWorkers=150: 148 ocupados e apenas 2 livres. Fila de entrada HTTPS cheia (512/511). CPU/carga e memória não indicavam esgotamento; ColdFusion direto em localhost:8500 respondeu 200 em 0,003 s; até arquivo estático por HTTPS excedia 4 s.

Snapshot de server-status mostrou 49 requisições em /api/portal/runner-apps/ do Business e outras requisições OpenResults. mod_jk registrava abortos de leitura/escrita do cliente. Isso evidencia saturação do atendimento Apache, mas não determina por si só o gatilho inicial. Não atribuir o incidente ao agrupamento de erros ou a uma rota isolada sem investigação adicional.

Recuperação: systemctl restart apache2 após validar configuração. ColdFusion preservado. Nenhum arquivo de runtime/configuração, credencial, permissão, limite ou dado foi alterado. Após reinício, workers ocupados caíram de 148 para 4 e depois 1; 49 livres, fila HTTPS 0/511.

Conferência externa 21:47:25: RoadRunners 200/0,172 s, Business 200/0,117 s, OpenResults 200/0,904 s. API Runner Apps 200/0,069 s. Recibo em _codex/staging/apache-recovery-20261004/public-final.json.

Observação para investigação posterior: consumidor RR includes/estrutura/menu_apps_data.cfm usa cache de 5 minutos e timeout HTTP de 3 s, sem coordenação de atualização nem espera entre novas tentativas após falha. Pode amplificar concorrência durante falha/expiração; não foi alterado nem confirmado como causa inicial nesta recuperação. Configuração Apache permaneceu intacta.
