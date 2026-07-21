# Repositório de Percursos

O módulo `/percursos/` mantém percursos GPX privados e versionados no Business. Nesta etapa ele não altera os embeds do Road Runners nem cria vínculos com modalidades de eventos.

## Instalação

1. Aplique `percursos/percursos_schema.sql` no banco usado pelo Business.
2. Copie `config/percursos.local.example.cfm` para `config/percursos.local.cfm` e informe um diretório persistente, privado e gravável pelo ColdFusion.
3. Garanta backup do banco e do diretório de storage como uma unidade lógica.

O arquivo local é lido a cada requisição e não exige reinício do ColdFusion. A variável de ambiente `BUSINESS_PERCURSOS_STORAGE_PATH`, quando disponível, continua tendo prioridade. Sem nenhuma das duas configurações, o módulo usa uma pasta dentro de `getTempDirectory()`; esse fallback serve apenas para desenvolvimento.

## Segurança

- acesso somente após autenticação do Business;
- escrita limitada a administradores ou contas com papel de operador/gestor;
- CSRF em todas as mutações;
- limite de upload de 20 MB;
- limite de 250 mil pontos por arquivo;
- somente extensão `.gpx`;
- rejeição de DTD e entidades XML;
- validação de coordenadas e quantidade mínima de pontos;
- arquivos GPX e GeoJSON sem URL pública direta;
- autorização refeita no endpoint privado de geometria;
- auditoria das criações, versões e alterações.

## Modelo de arquivos

```text
{storage}/
  {id_percurso}/
    {versao}/
      original.gpx
      route.geojson
```

O banco guarda apenas as chaves relativas. Isso permite substituir o filesystem por storage de objetos posteriormente.

## Preview administrativo

O preview autenticado oferece mapa de ruas e satélite, tela cheia, recentralização, escala métrica, largada e chegada, setas de direção, marcadores configuráveis a cada 1 ou 5 km, resumo de distância e elevação e perfil de elevação sincronizado com um marcador no mapa. O download do GPX e o card de auditoria são exclusivos do usuário criador do percurso, inclusive diante de compartilhamento ou acesso administrativo.

## Próxima etapa

Criar `tb_evento_percurso_vinculos` e integrar o seletor à modalidade identificada por `tb_evento_corridas_percursos.id_evento_percurso`. O código público do Road Runners permanece fora do escopo atual.
