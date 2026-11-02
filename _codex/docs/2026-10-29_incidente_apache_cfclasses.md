# Indisponibilidade e recuperação — 29/10/2026

## Evidências

Às 11:06 BRT, RoadRunners, Business e OpenResults não responderam aos probes públicos de 12 segundos. Apache e ColdFusion estavam ativos. Apache: 148 workers ocupados de 150; memória disponível superior a 13 GB, swap sem uso, load aproximadamente 2. A página padrão estática do ColdFusion em 8500 respondeu em 9 ms.

Thread dump: 123–124 threads aguardando o semáforo do ColdFusion e várias aguardando cache/carregamento de templates, além de chamadas HTTP. Evidência privada completa: `/var/backups/incident-20261029-threads/threads.txt`. Não foi concluída atribuição de um único endpoint como causador.

Logs recentes continham repetidas `FileNotFoundException` de classes em `/opt/coldfusion2025/cfusion/wwwroot/WEB-INF/cfclasses/`. A pasta inteira estava ausente. O pai WEB-INF tinha mtime 29/10 14:02:16 UTC. Isso não identifica quem ou qual operação removeu o diretório.

## Intervenções e resultados

1. Após ordem explícita do usuário, executado `systemctl restart apache2`; serviço confirmado ativo às 11:10:18 BRT. Business e OpenResults retornaram HTTP 200; RoadRunners retornou 200 em 24,25 s no probe posterior. Workers caíram inicialmente para 55, mas chegaram novamente a 96 durante a drenagem.
2. Confirmada a ausência de `cfclasses`, recriada somente essa pasta como usuário `coldfusion`, modo 0755, sem sobrescrever arquivos ou alterar permissões existentes. O ColdFusion voltou a gerar classes: 1.398 arquivos na primeira amostra.
3. Probes públicos imediatamente posteriores: RoadRunners HTTP 200 em 0,282 s; Business HTTP 200 em 0,198 s; OpenResults HTTP 200 em 0,296 s. Apache: 5 workers ocupados e 70 livres.

Nenhum arquivo de código de runtime foi alterado/publicado. Não houve reinício do ColdFusion. A origem da remoção da pasta de cache compilado permanece não identificada; qualquer rotina de limpeza deve preservar o diretório ou ser coordenada com o ciclo de vida do runtime.

## Causa identificada após informação do usuário

O usuário informou que havia tentado instalar o pacote `ai` pelo Administrator e a tela permanecera anunciando reinício. A inspeção subsequente dos logs confirmou:

- `cfpm-audit.log`, 29/10 11:01:15 BRT: solicitação de `ai:2025.0.14.332029`; o gerenciador registrou que essa versão exige Update 14 e iniciou atualização do core, então no Update 13.
- Dois logs do instalador em `cfusion/hf-updates/hf-2025-00014-332029/` (nomes com 14:02:07 e 14:02:59 UTC) registram explicitamente `Delete:/opt/coldfusion2025/cfusion/wwwroot/WEB-INF/cfclasses`. A origem da remoção deixou de ser desconhecida: foi o instalador da atualização.
- Às 11:03:35–11:03:41, o gerenciador registrou tentativas de downgrade do core para 13 e `uninstaller.jar is corrupted`. Às 11:05:30 há mensagem genérica de sucesso da atualização, insuficiente para afirmar que toda a operação terminou corretamente.
- O processo Java de produção continuou PID 711240, iniciado em 27/10, e o serviço registra início em 27/10 15:40:13 UTC. O reinício anunciado não ocorreu até a amostra desta investigação.
- `cfpm.sh list`, executado somente para consulta como `coldfusion`, confirmou que **ai não está instalado**. Adminapi/administrator/chart aparecem na versão 13; document/feed/htmltopdf/image/mail/pdf/scheduler aparecem na versão 14; outros pacotes permanecem em versões anteriores. Versões diferentes por si só podem ser normais para pacotes sem atualização, mas o pacote solicitado ausente, as tentativas de rollback e o reinício não ocorrido comprovam que não se pode tratar a instalação de AI como concluída.

Nenhuma nova instalação, atualização, rollback ou reinício foi executado nessa etapa de diagnóstico. Próxima intervenção: reconciliar o core e os pacotes em uma versão compatível e concluir instalação de AI com um reinício controlado, validando os três sites depois. A documentação Adobe do Update 14 exige reinício do ColdFusion para ativação: https://guides.adobe.com/coldfusion/en/docs/install-and-configure-coldfusion/coldfusion-2025-release-update-14.html.
