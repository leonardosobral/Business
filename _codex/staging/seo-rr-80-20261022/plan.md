# Road Runners — superar 80% no Semrush

## Contrato

Manter campanha 26661911, limite 5.000 páginas, rastreador móvel e JS desativado. Não excluir verificações/URLs nem enfraquecer privacidade, segurança ou indexação para alcançar a meta. Corrigir, publicar com baseline/recuperação, testar o site e medir novamente.

## Ordem

1. Remover a etapa de redirecionamento dos atalhos pessoais do rodapé para visitantes: entrada direta no login com retorno local equivalente; preservar links autenticados, perfis e destinos públicos.
2. Reauditar com a mesma configuração e usar o resultado para escolher o próximo lote. Se necessário, reduzir código estático repetido no HTML e resolver os erros restantes comprovados.
3. Encerrar somente com nota acima de 80% medida, ou relatar claramente os limites externos que impedirem o avanço.

## Baseline

- Auditoria disponível em 22/10: coleta 21/10, Site Health 71%, 63 erros, 33.179 advertências, incluindo 27.691 ocorrências de redirecionamento temporário e 3.836 páginas com baixa proporção texto/HTML. Antecede o lote publicado em 21/10.
- Quatro respostas reais medidas na origem: home 375.777 bytes, evento Together Run PE 337.671, estado BA 564.934 e ajuda 249.474. Código inline script/style/SVG ocupa grande parte; conteúdo público preservado.
- RoadRunners possui alterações preexistentes: trailrun e os dois includes publicados no dia anterior. Não sobrescrever nem publicar outros arquivos.
- Autenticação: usar o mesmo contrato existente `/login/?redirect=<destino local codificado>`; nenhum backend/controle de acesso será alterado.

## Publicações de 22/10

- Rodapé publicado às 14:29 UTC: seis atalhos pessoais de visitantes apontam diretamente ao login com retorno equivalente; 90 verificações CF, compilação e 36 links em seis páginas reais, sete respostas HTTP 200. Backup `/var/backups/seo-rr-80-20261022-nav/footer-before.cfm`. As adições Radar existentes somente em produção foram preservadas na publicação e não importadas ao checkout.
- Metadados publicados às 14:49 UTC: oito notícias sem resumo usam o título real como descrição; páginas de organizador e cronometragem ganham contexto no título. 23 verificações CF, três templates compilados, onze páginas reais HTTP 200 com canonical/robots/núcleo JSON-LD preservados. Backup `/var/backups/seo-rr-80-20261022-metadata/baseline`.
- Suite Node relacionada: 16/17 passaram; falha preexistente de contagem de marcadores em `api/home_news.cfm`, confirmado igual a HEAD e fora da publicação. Não alterada para satisfazer o teste. `git diff --check` passou.
- Semrush reexecutado após o lote de rodapé, com 5.000 páginas/móvel/JS desativado; às 14:51 UTC ainda rastreando 1.239/5.000. O segundo lote foi publicado durante o rastreamento; não afirmar cobertura integral dele nesta coleta. Última nota concluída permanece 71%.
- Nenhuma alteração de banco, autenticação, política de indexação ou Git.

## Conferências complementares

- Oito páginas lentas na coleta anterior: 16 requisições sequenciais na origem, todas 200, de 0,048 a 2,809 s. Não reproduziu >3 s nessa janela; não encerra o alerta sem nova medição do fornecedor. Recibo `slow-origin.json`.
- Hreflang remanescente é a URL legada não codificada `/evento/2026-clandestina-ou-travessuras?/`, agora 404/noindex. A URL válida `%3F/` responde 200 e emite canonical e quatro alternates coerentes em PT/EN/ES. A geração de links já foi corrigida em lote anterior; não alterar o cadastro ou substituir o `?` no identificador. A auditoria atual confirmará o que permanece no grafo. Recibo `legacy-url.json`.
- Panel: baseline de produção de snapshot/view igual ao local, candidato de view em `panel/candidate/`; nenhuma publicação do painel antes de nova coleta concluída.

## Continuação

Auditoria ainda em execução com 2.137/5.000 páginas. Chrome tab `283502210` marcado para continuar. `panel/build.py` recusa importar sem fonte concluída; `source-final.json` ainda não existe. Painel não foi publicado nesta etapa. Continuar até medição >80%; não concluir a meta pelo término do lote de código.

## Continuação verificada — painel preparado

- Turno anterior classificado como progresso: quatro arquivos de runtime publicados e conferidos. Nesta continuação, rastreamento confirmado ao vivo de 2.251 para 2.682/5.000, sem reiniciar. Espera verificada, não bloqueio.
- Business acessível no Chrome autenticado, tab `283502236`, binding `seoPanel22`; exibe o snapshot de 08/10 (75%). Ainda não publicado.
- `panel/build.py`, `verify_panel.py` e `release.py` preparados. Importação preserva todos os dados orgânicos; verificação reutiliza o fixture Adobe de 19 cenários com oito controles de acesso; release compila dois templates e confere onze dependências com baseline/backup e rollback guardado. Executar somente depois de criar `source-final.json` com a coleta final real. Não inventar hora/minuto de conclusão: obter na UI. O histórico 08/10 agora fica em detalhes e não deve ser confundido com os números atuais.
- Seis testes existentes do importador passaram; sintaxe dos três scripts válida; `git diff --check` sem problemas. Os 19 cenários Adobe ainda não foram executados para o novo snapshot, pois a coleta não acabou.

## Investigação de duplicidade — evidência nova

- Campanha continua ativa; 4.172/5.000 na última leitura. A demora de navegação ocorreu só na observação do Chrome; mesma tab recuperada, sem reexecutar a campanha.
- Os seis endereços PT/EN/ES da Amazônia representam os cadastros 44162 (slug 2026) e 46375 (slug 2027), ambos com data atual 28/03/2027, mesmo local e mesma inscrição externa TicketSports 87544. Página oficial conferida com JS no Chrome confirma nome, cidade e data. Não inferir outra edição pelo ano da URL, nem alterar datas que já estão corretas.
- Consulta em transação READ ONLY: 40 referências permitidas contadas, com apenas dois percursos e um estado de matching Foco por cadastro. Algumas tabelas não são legíveis à conexão; privilégios não foram ampliados e nenhum dado pessoal foi retornado. Nenhuma escrita no banco. Campo tag_301 possui permissão de UPDATE já existente, mas isso não constitui publicação/alteração.
- Caso o alerta permaneça e a meta exija outro lote, considerar alias com o serviço existente, usando prova da mesma inscrição e mantendo o ID/URL original como canônico. Não fazer exclusão ou fusão física sem avaliar vínculos.
- Corre Brasil: org/timer já possuem SSR; consultas repetem o filtro de fornecedor sem separar função. Antes de alterar listagens, confirmar os tipos reais dos vínculos. Títulos por função já foram publicados; não declarar o conteúdo duplicado resolvido por isso.

## Auditoria concluída e painel publicado

- 22/10, 12:32 Brasília, 5.000 páginas, móvel/JS desativado: Site Health 71%, IA 81%, erros 44, advertências 10.306, observações 2.685. Meta de Site Health >80 NÃO alcançada. Sem novo rastreamento iniciado desde esta coleta.
- Comparativo 21→22/10: erros 63−27+8=44; advertências 33.179−25.191+2.318=10.306; observações 5.865−4.293+1.113=2.685. Tabela completa reconciliada (38 checks de erro, 34 warning, 25 notice). Parser corrigido para o formato YAML com aspas simples em nomes com dois-pontos; nenhum contador foi ajustado.
- Business publicou dois templates às 13:15 Brasília. 19 cenários Adobe antes/depois (oito de acesso), dois compilados, onze dependências preservadas; seis testes do gerador e git diff --check passaram. Conferência no Chrome autenticado em desktop e 390 px, viewport restaurado. Screenshot `panel/published-desktop.png`. Backup `/var/backups/seo-rr-80-20261022-panel/baseline`.
- Gerador-fonte `_codex/scripts/seo_semrush_snapshot.py` corrigido para remover statustext de cfheader (incompatível no CF2025), sem alterar os status/guardas. Falha detectada em fixture antes da publicação.
- Metodologia oficial Semrush consultada: tipos/quantidades de checks influenciam a nota; erros têm peso maior e encerrar um tipo completo é mais efetivo que resolver ocorrências isoladas. Fonte https://www.semrush.com/kb/114-total-score . Repriorizar grupos completos, começando pela duplicidade comprovada da Amazônia. HTML/performance permanece candidato real, sem prometer que externalização parcial encerrará o alerta.
- Loja pública responde no Chrome; assets de `gcp-heroku.majestic.ink.rsvcloud.com` apontam a hospedagem externa, mas nenhuma autenticação/admin/API foi tentada. Não alterar compras/preços/pedidos. Acessos/edição de SEO da plataforma ainda não confirmados.


Rodada 15:15 BRT: alias Amazônia e correções de títulos/descrições publicados e verificados. Usuário fará a próxima atualização Semrush; nenhuma nova auditoria iniciada. Resultado medido continua71/IA81. Ver documentação Business 2026-10-22_seo_semrush_5000.md e recibos titles/, heads/, amazonia-*.json.
