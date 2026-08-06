# Monitor administrativo da API

## Objetivo

O módulo `/administracao/api-monitor/` apresenta um monitor operacional inicial de
`api.roadrunners.run`. Ele é exclusivo para administradores e analisa o log de
telemetria dedicado do Apache sem consultar os tokens ou os payloads da API.

## Fonte

Arquivo padrão:

```text
/var/log/apache2/api.roadrunners.run-telemetry.log
```

O painel lê o arquivo atual e o `.1`, limita a leitura a 16 MB por padrão e mantém
o resultado em cache por 60 segundos. A interface aceita janelas de 1, 6, 24 e 72
horas.

O snapshot possui `schemaVersion` e o cache inclui uma versão própria. Em deploys,
subir juntos `includes/backend/api_monitor_service.cfm`,
`administracao/api-monitor/includes/backend.cfm` e
`administracao/api-monitor/home.cfm`. A view detecta arquivos incompatíveis e
mostra um aviso controlado em vez de tentar renderizar um snapshot antigo.

Campos deliberadamente ausentes da telemetria:

- header `Authorization`;
- cookies;
- query string;
- request e response bodies;
- e-mail, ID de usuário ou token hash;
- User-Agent e Referer.

O IP é usado somente para agrupamento de abuso e vira um prefixo de hash SHA-256
antes de ser armazenado no snapshot em memória ou exibido.

## Classificação do tráfego

O painel separa cada linha em uma única classe:

- `authenticated`: token válido identificado pelo header de resposta
  `X-Api-Client-Id`;
- `publicSurface`: landing, OpenAPI, health check e JavaScript do playground com
  resposta bem-sucedida;
- `rejected`: chamada a uma rota versionada da API, incluindo `result-imports`,
  sem credencial valida ou sem permissao;
- `probe`: rota fora do contrato, scanner ou requisição malformada.

A taxa de sucesso e a latência p95 principais usam somente `authenticated`. Isso
evita que crawlers, documentação pública e sondagens distorçam a saúde percebida
da API. O gráfico por hora continua mostrando todo o tráfego, mas com as quatro
classes empilhadas.

## Configuração opcional

Em `config/business.local.cfm`:

```cfml
"apiMonitorLogPath" = "/var/log/apache2/api.roadrunners.run-telemetry.log",
"apiMonitorMaxBytes" = 16777216,
"apiMonitorCacheSeconds" = 60,
```

As alternativas por ambiente são:

```text
RR_BUSINESS_API_MONITOR_LOG_PATH
RR_BUSINESS_API_MONITOR_MAX_BYTES
RR_BUSINESS_API_MONITOR_CACHE_SECONDS
```

## Permissões no servidor

O logrotate usa o grupo dedicado `rr-api-monitor`. Antes do primeiro deploy:

```bash
ps -eo user,group,args | grep -E '[c]fusion|[c]oldfusion|[t]omcat'
sudo groupadd --system rr-api-monitor
sudo usermod -aG rr-api-monitor USUARIO_DO_COLDFUSION
sudo touch /var/log/apache2/api.roadrunners.run-telemetry.log
sudo chown root:rr-api-monitor /var/log/apache2/api.roadrunners.run-telemetry.log
sudo chmod 0640 /var/log/apache2/api.roadrunners.run-telemetry.log
sudo apt-get install acl
sudo setfacl -m g:rr-api-monitor:--x /var/log/apache2
sudo a2enmod remoteip
```

Se o log ja tiver sido rotacionado antes dessa configuracao, ajuste uma vez o
arquivo ainda lido pelo monitor:

```bash
sudo chown root:rr-api-monitor /var/log/apache2/api.roadrunners.run-telemetry.log.1
sudo chmod 0640 /var/log/apache2/api.roadrunners.run-telemetry.log.1
sudo -u nobody test -r /var/log/apache2/api.roadrunners.run-telemetry.log.1
```

O monitor ignora individualmente um arquivo rotacionado inacessivel e sinaliza
que a leitura esta parcial, sem deixar de processar o log atual.

O ACL no diretório concede somente travessia para o nome conhecido do arquivo.
Ele não permite ao grupo listar ou ler os demais logs do Apache.

Depois, instalar:

```text
_codex/deploy/logrotate/roadrunners-api-telemetry
    -> /etc/logrotate.d/roadrunners-api-telemetry
```

A inclusão do usuário em um grupo Unix exige reiniciar apenas o serviço do
ColdFusion uma vez para renovar os grupos do processo. Alterações futuras de
token, janela ou cache não dependem desse restart.

Depois de instalar o VirtualHost atualizado:

```bash
sudo apachectl configtest
sudo systemctl reload apache2
```

O `mod_remoteip` aceita `CF-Connecting-IP` somente das faixas de proxy declaradas
no VirtualHost. Sem isso, uma chamada direta à origem poderia falsificar o header
e prejudicar tanto a análise por IP quanto o rate limit.

## Limites do MVP

- cobre somente tráfego que chega ao Apache de origem;
- bloqueios feitos no edge do Cloudflare não aparecem;
- usa arquivos locais e não consolida múltiplas instâncias;
- não mantém histórico além da rotação;
- os limiares de abuso são heurísticos, não bloqueiam tráfego.

Uma próxima fase pode ingerir agregados em PostgreSQL, combinar Cloudflare
Analytics e criar alertas automáticos.
