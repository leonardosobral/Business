# Workers Apache — diagnóstico 04/10/2026

Escopo desta rodada: diagnóstico e dimensionamento; não houve novo reinício nem mudança de configuração/runtime.

## Capacidade configurada

Servidor com 2 CPUs, aproximadamente 24 GiB de RAM; durante incidente anterior havia ~8,8 GiB disponíveis. Apache event: MaxRequestWorkers 150, ThreadsPerChild 25, MaxSpareThreads 75, ServerLimit padrão sem override identificado; Timeout 300 s e KeepAliveTimeout 5 s. ColdFusion neo-runtime: requestLimit 25 (páginas CFML), queueTimeout 60 s; AJP maxThreads 500. Estes são limites de camadas diferentes. O AJP aceitar 500 threads não aumenta o limite de execução de páginas CFML.

Conector /etc/apache2/workers.properties mantém connection_pool_timeout=60; connection_pool_size é descoberto pelo mod_jk pelo ThreadsPerChild. Não há timeout explícito de resposta AJP nessa configuração. Não reduzir limites globalmente sem inventariar endpoints longos legítimos.

## Evidências

Na indisponibilidade anterior: 148/150 workers ocupados, backlog HTTPS 512/511, arquivo estático HTTPS também falhava; ColdFusion direto retornava 200 em 3 ms. Snapshot Apache tinha 49 conexões associadas a GET /api/portal/runner-apps/; esse contador inclui estado do scoreboard e não prova 49 execuções CF simultâneas.

Cauda de 8 MB de access.log: 5.421 acessos à API com User-Agent ColdFusion, pico de 373/min, concentração de 21:27 a 21:45 (São Paulo; log do servidor em UTC 00:27–00:45 do dia 05). Respostas registradas 200; isso não prova que o chamador recebeu tudo antes de seu timeout.

Consumidor de produção encontrado: RoadRunners/includes/estrutura/menu_apps_data.cfm, SHA256 6b2f02b5bd0d0807e08baa01df2d7f15f02c627d16cb8dcd9849ec0b67d89d2c. Cache APPLICATION de 5 minutos, timeout cfhttp de 3 s. Só atualiza cache em resposta válida; não coordena concorrência na atualização, não mantém espera entre tentativas após falha e não usa cache antigo enquanto atualiza. Sob lentidão, visitas podem multiplicar chamadas internas e manter slots CF/Apache esperando a própria plataforma. Amplificação identificada; gatilho inicial da primeira lentidão ainda não demonstrado.

API atualmente saudável: success true, 2 grupos e 8 itens. Snapshot Java via Thread.getAllStackTraces: uma requisição esperando HTTP SSL no cfconteudo_lateral_api, cujo código chama https://conteudo.roadrunners.run/rest/cmscf_api/v1/content com timeout de 5 s; outra em query-of-query; maioria das threads de request ociosa. Banco na amostra: 49 conexões idle e uma ativa, sem evidência de bloqueio generalizado. Amostra é posterior à recuperação, não retrato retroativo da queda.

MXBean não utilizável pelo wrapper ColdFusion devido encapsulamento modular Java. API Thread pública funcionou ignorando subclasses internas inacessíveis; não houve alteração de flags/permissões Java. Ferramenta reutilizável: _codex/scripts/diagnose_apache_runtime.py. Fixture restrita a loopback e token temporário, removida ao final; saída não contém SQL, segredos ou corpos de requisições.

## Correções recomendadas para próxima implementação

1. Coordenar atualização do Runner Apps (uma tentativa por aplicação), usar último conteúdo válido e estabelecer intervalo entre novas tentativas em falha. Tratar conteúdo lateral com a mesma estratégia de não bloquear cada renderização por serviço secundário.
2. Telemetria Apache por host, rota, duração e status; snapshots por estado/idade do worker e stacks CF quando houver saturação. Logs atuais de acesso comuns não têm %D, impedindo reconstruir tempo exato de cada espera passada.
3. Testar aumento gradual a 200 e, se indicado pelas medições, 250 workers (múltiplos de 25), conferindo fila CF, memória, latência e throughput. Não aumentar CF requestLimit mecanicamente no servidor de 2 CPUs.

Fontes: https://httpd.apache.org/docs/2.4/mod/mpm_common.html#maxrequestworkers ; https://tomcat.apache.org/connectors-doc/reference/workers.html ; https://guides.adobe.com/coldfusion/en/docs/install-and-configure-coldfusion/using-the-coldfusion-administrator.html
