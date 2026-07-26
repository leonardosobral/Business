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

Campos deliberadamente ausentes da telemetria:

- header `Authorization`;
- cookies;
- query string;
- request e response bodies;
- e-mail, ID de usuário ou token hash;
- User-Agent e Referer.

O IP é usado somente para agrupamento de abuso e vira um prefixo de hash SHA-256
antes de ser armazenado no snapshot em memória ou exibido.

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
sudo install -o root -g rr-api-monitor -m 0640 /dev/null \
  /var/log/apache2/api.roadrunners.run-telemetry.log
sudo a2enmod remoteip
```

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
