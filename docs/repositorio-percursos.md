# Repositório de Percursos

O módulo `/percursos/` mantém arquivos de percurso privados e versionados no Business. Aceita GPX, KML, KMZ, GeoJSON e FIT, normaliza a geometria e gera também um GPX otimizado. Os percursos podem ser vinculados à modalidade exata identificada por `tb_evento_corridas_percursos.id_evento_percurso`.

## Instalação

1. Aplique `percursos/percursos_schema.sql` no banco usado pelo Business.
2. Copie `config/percursos.local.example.cfm` para `config/percursos.local.cfm` e informe um diretório persistente, privado e gravável pelo ColdFusion.
3. Garanta backup do banco e do diretório de storage como uma unidade lógica.

O preview e a altimetria usam Mapbox. Configure:

- `mapboxPublicAccessToken` ou `BUSINESS_MAPBOX_PUBLIC_TOKEN` para os mapas de ruas e satélite no navegador;
- `mapboxServerAccessToken` ou `BUSINESS_MAPBOX_SERVER_TOKEN` para consultar Terrain-RGB no ColdFusion. Use um token secreto `sk.*` com o escopo `map:read`.

`MAPBOX_ACCESS_TOKEN` também é aceito como fallback somente para o preview. O token público pode ter restrição de URL. O token do servidor é obrigatório para a altimetria, deve começar com `sk.`, possuir apenas os escopos mínimos necessários — incluindo `map:read` — e não ter restrição de URL. O Business não reutiliza automaticamente o token público no servidor, evitando bloqueios `403` causados pela ausência do cabeçalho `Referer`.

Em instalações que já possuem o repositório, aplique também `_codex/sql/2026-07-21_strava_percursos_migration.sql`. O script adiciona o vínculo por modalidade e o controle da migração sem apagar ou modificar `tb_evento_corridas_percursos.mapa`.

O arquivo local é lido a cada requisição e não exige reinício do ColdFusion. A variável de ambiente `BUSINESS_PERCURSOS_STORAGE_PATH`, quando disponível, continua tendo prioridade. Sem nenhuma das duas configurações, o módulo usa uma pasta dentro de `getTempDirectory()`; esse fallback serve apenas para desenvolvimento.

## Segurança

- acesso somente após autenticação do Business;
- escrita limitada a administradores ou contas com papel de operador/gestor;
- migração das rotas Strava limitada a ADMINs reais do sistema;
- CSRF em todas as mutações;
- limite de upload de 20 MB;
- limite de 1 milhão de pontos por arquivo;
- extensões `.gpx`, `.kml`, `.kmz`, `.geojson` e `.fit`;
- rejeição de DTD e entidades XML;
- validação de coordenadas e quantidade mínima de pontos;
- arquivos originais, GPX otimizado e GeoJSON sem URL pública direta;
- autorização refeita no endpoint privado de geometria;
- auditoria das criações, versões e alterações.
- reserva atômica de cada modalidade no PostgreSQL para impedir processamento concorrente;
- download restrito ao endpoint numérico `https://www.strava.com/routes/{id}/export_gpx`.

## Modelo de arquivos

```text
{storage}/
  {id_percurso}/
    {versao}/
      original.{gpx|kml|kmz|geojson|fit}
      route.geojson
      optimized.gpx
```

O banco guarda apenas as chaves relativas. Isso permite substituir o filesystem por storage de objetos posteriormente.

## Altimetria

Arquivos enviados sem elevação são enriquecidos pelo Mapbox Terrain-RGB quando `BUSINESS_MAPBOX_SERVER_TOKEN` ou `mapboxServerAccessToken` estiver configurado. O limite de amostras pode ser ajustado por `elevationMaxSamples`; os valores intermediários são interpolados sobre todos os pontos da geometria.

O processamento usa zoom 15, converte cada coordenada para o pixel Web Mercator correspondente usando as dimensões reais do tile recebido e aplica uma suavização ponderada de cinco amostras antes de calcular ganho e perda. Isso reduz o ruído natural do modelo digital de elevação sem deslocar a geometria do percurso.

Para percursos antigos cuja versão atual não possui elevação, usuários com permissão de edição veem a ação **Gerar altimetria** na página do percurso. A operação:

- consulta somente a geometria da versão atual;
- cria um novo GPX com `<ele>` em todos os pontos;
- regenera o GeoJSON e o GPX otimizado;
- cria uma nova versão, sem sobrescrever o arquivo anterior;
- recalcula ganho, altitude mínima e máxima;
- registra a origem e a quantidade de pontos consultados na auditoria.

Quando a versão atual já possui elevação, a ação passa a se chamar **Regerar altimetria**. Ela ignora os valores anteriores, consulta novamente o Mapbox Terrain-RGB e cria outra versão preservando todas as anteriores.

## Gestão de versões

Usuários com permissão de edição podem:

- **Voltar** para uma versão anterior: os arquivos escolhidos são copiados para uma nova versão, que passa a ser a atual. A versão original e toda a sequência histórica permanecem intactas;
- **Excluir** uma versão: o registro é desativado logicamente e deixa de participar do preview, dos downloads e da API pública. Os arquivos privados não são apagados, permitindo rastreabilidade pela auditoria.

A única versão ativa de um percurso não pode ser excluída.

## Preview administrativo

O preview autenticado usa Mapbox GL JS com os estilos Mapbox Streets e Satellite Streets. Ele oferece tela cheia, recentralização, navegação, escala métrica, largada e chegada, linha com contorno, setas de direção, marcadores configuráveis a cada 1 ou 5 km, resumo de distância e elevação e perfil de elevação sincronizado com um marcador no mapa. A autorização considera propriedade, administração, conta responsável e contas ativas ligadas aos eventos vinculados.

## Migração dos mapas Strava

O painel está disponível em `/percursos/migracao-strava.cfm` para ADMINs do sistema.

1. Faça backup do banco e do storage.
2. Aplique `_codex/sql/2026-07-21_strava_percursos_migration.sql`.
3. Abra o painel e execute primeiro um lote pequeno em **Simular**.
4. Confira distância, quantidade de pontos, status HTTP e mensagens.
5. Execute o mesmo recorte em **Migrar de verdade**.
6. Amplie gradualmente o lote, com limite de dez rotas por requisição.

O inventário é sincronizado a partir dos registros que possuem `mapa`. A simulação baixa e valida o GPX, mas não cria arquivos nem vínculos. A migração efetiva:

- processa o GPX com `PercursoGpxService`;
- gera o GeoJSON privado;
- reutiliza um percurso quando o SHA-256 já existe;
- cria um percurso em rascunho quando o arquivo é novo;
- vincula pelo `id_evento_percurso` original;
- registra origem, hash, distância, resultado e usuário responsável;
- mantém o campo `mapa` original inalterado.

Os estados possíveis são `pendente`, `processando`, `validado`, `migrado`, `reutilizado`, `revisao`, `erro` e `ignorado`. Uma execução interrompida em `processando` volta a ser elegível depois de quinze minutos. Registros concluídos não são processados novamente pelo painel.

Se a modalidade já estiver associada a outro GPX, o item vai para `revisao` e nenhum vínculo é sobrescrito. Erros de uma rota não revertem as demais rotas do lote.

## Ativação no Road Runners

Durante a transição, o consumidor deve procurar primeiro `tb_evento_percursos_gpx.id_evento_percurso` e usar `tb_evento_corridas_percursos.mapa` apenas como fallback. Depois da conferência integral, o fallback pode ser desativado sem limpar o campo antigo.

Para rollback, basta o Road Runners voltar a usar `mapa`. Os IDs originais do Strava permanecem tanto na tabela histórica quanto em `tb_percurso_migracoes_strava`.

A arquitetura pública, o contrato da API, a geometria derivada para web, a integração Mapbox e o plano de rollout estão definidos em [Percursos de eventos no Road Runners com Mapbox](/Users/geraldoprotta/IdeaProjects/Business/docs/road-runners-percursos-mapbox.md).
