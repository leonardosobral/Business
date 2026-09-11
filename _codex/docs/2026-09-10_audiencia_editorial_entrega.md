# Audiência editorial — preparação de 10/09/2026

## Estado

Lote implementado, revisado, aplicado nos projetos locais e **publicado em produção em 10/09/2026 às 23:34:17 de Brasília**, após o usuário informar a execução do SQL. A validação ponta a ponta confirmou cartões expostos de notícias/vídeos, abertura de notícia e os quatro marcos de profundidade no Business. Os acessos de teste são internos, excluídos dos números comerciais padrão. Detalhes e backup: [recibo de publicação](2026-09-10_audience_editorial_publicado.md).

Manifesto dos arquivos e hashes: [manifesto editorial](2026-09-10_audience_editorial_manifest.json). Contagens não são retroativas; os novos campos estão ativos no Business de produção. As seções abaixo preservam o procedimento e as evidências da preparação local.

## O que muda

- Cards de notícias e vídeos: exposição qualificada com pelo menos 50% visível por um segundo contínuo. Conta uma vez por conteúdo/página, mesmo se o card reaparecer ou estiver também na lateral. Não é abertura, reprodução ou impressão de anúncio.
- Corpo da notícia: marcos de 25%, 50%, 75% e 100% alcançados na tela, com a notícia visível. Não equivale a leitura comprovada. Sidebar, título e rodapé não fazem parte da altura medida.
- Business → Conteúdo individual: cartões expostos, alcance exposto e profundidade, separados dos contadores existentes. Dados legados ou sem novo sinal ficam com `—`, sem inventar histórico ou CTR de abertura/exposição.

Renderizadores cobertos: home (notícias/vídeo destacado e vídeos recentes), listas de notícias e vídeos com suas partials infinitas, buscas editoriais, lateral compartilhada e relacionados da notícia. A profundidade usa somente `.news-content` no detalhe da notícia. Notícias mantêm a identidade já existente (ID quando fornecido, senão slug); vídeos mantêm o ID usado pelo player.

## Único passo de banco antes da ativação

Arquivo do RoadRunners: [SQL editorial](/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/sql/2026-09-10_audience_editorial.sql), SHA-256 `987ad749076e6535e58108c82cb9c47e83c2e00e409ee73b88d754377eff9ee9`.

O DBA deve executar **somente esse SQL**, no banco `runnerhub`, com a identidade que já pode alterar a tabela e a função existentes. Não reaplicar scripts antigos de criação de papéis ou retenção. A migração amplia os tipos aceitos e a validação da função `audience.ingest_events(jsonb,jsonb,jsonb)`; não cria colunas, não altera papéis, privilégios ou proprietários e não apaga eventos.

O script é transacional e reaplicável no contrato esperado. Se encontrar propriedades diferentes da função existente, interrompe a transação para revisão, sem sobrescrever a configuração. Não se deve contornar essa proteção executando partes isoladas. Ensaiado em PostgreSQL 16 local; o servidor informado pelo usuário é PostgreSQL 17.6. O usuário posteriormente confirmou sua execução, e a publicação validou a aceitação dos novos sinais por esse ambiente.

## Ordem de publicação e reversão

1. DBA conclui o SQL acima.
2. Publicar `services/AudienceMeasurementService.cfc` do RoadRunners.
3. Publicar tracker, os oito renderizadores e bootstrap com a versão do asset.
4. Publicar `portal/audiencia/queries/content.sql` e `portal/audiencia/home.cfm` do Business.
5. Validar um acesso interno real, exposição e marcos, depois conferir os novos valores no Business respeitando o cache de até um minuto. Não usar acesso de teste como audiência comercial.

Não sincronizar checkouts inteiros: existem mudanças preexistentes de outros assuntos. Antes de publicar, comparar hashes, guardar backups e publicar somente a lista deste lote. Caso seja preciso reverter, restaurar somente os arquivos de execução do lote. O SQL aditivo pode permanecer e os eventos aceitos não devem ser apagados. Um tracker novo **não pode** preceder o SQL, pois eventos desconhecidos podem fazer a base rejeitar o lote de coleta inteiro.

## Validação executada

- RoadRunners: 83/83 testes Node, incluindo 69 regressões anteriores e 14 verificações editoriais/template; contratos CFML legado e editorial aprovados. Os 83 testes e a checagem de sintaxe passaram novamente nos arquivos aplicados ao projeto local.
- Migração em PostgreSQL local descartável: atualização e reaplicação aprovadas, dados/owners/ACLs preservados; ingestão com `SET ROLE runner` aprovada. Não houve conexão ao banco de produção.
- Business: 51 verificações SQL legadas, 21 SQL editoriais, 11 asserções de renderização CFML e 5 testes JavaScript aprovados.
- Navegador Chrome em fixtures sintéticas locais: painel desktop 1360×900 e móvel 390×844 sem overflow da página; tabela rolável mostra a profundidade. Coletor: dois cards qualificados, sem eventos de Ads/slots, remontagem sem duplicação, quatro marcos de notícia e interrupção por recusa. Em viewport móvel, parte insuficiente da notícia não gera marco prematuro.

A correção final dirigida também passou pelo revisor independente e por teste RED/GREEN: ID vazio, tipo inválido ou retirada dos atributos fazem o card reiniciar o segundo contínuo. O navegador foi usado antes desse último ajuste; o ajuste foi validado por testes comportamentais do tracker, sem representar novo teste em produção. Aba temporária e servidor local foram encerrados, viewport restaurado e filtros do Business preservados.

Os testes CFML usam Lucee isolado, não o Adobe ColdFusion de produção. As consultas usam PostgreSQL descartável, não os números reais do site. Os runners locais precisam do runtime/cache indicado em suas opções. A confirmação posterior ponta a ponta em produção está no recibo de publicação, separada desses ensaios locais.

## Preservado e restante

Sem mudanças em `tb_log`, login, cobrança, DSN `runner`, permissões de `runner_dba`, escolha opt-out/GPC ou política de 90 dias. Retenção continua uma rotina independente; não é pré-requisito para esses contadores.

Ainda pertencem ao plano maior: promoções estáticas restantes, potencial visual de posições colapsadas, origem confiável da UF física (403 do provedor pendente), retenção operacional do DBA, projeção comercial com semanas completas e piloto de aquisição com verba aprovada. Aposentar somente o writer de view de evento em `tb_log` fica para o final, após comprovar a substituição.
