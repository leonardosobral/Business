# Vinculador Foco Radical

Implementacao automatizada hospedada no Business. O endpoint original no
RunnerHub permanece disponível para compatibilidade, mas o cron principal deve
usar este endpoint.

## Preparacao

1. Aplicar `foco_match_schema.sql` no banco usado pelo Business.
2. Configurar `focoApiToken` em `config/business.local.cfm`.
3. Configurar o token Bearer em `cronSecrets.business_foco_eventos`.
4. Aplicar `administracao/cron-jobs/foco_event_match_job.sql`.

O arquivo local e lido em toda requisicao e nao exige reinicio do ColdFusion.
Durante a migracao, se `business_foco_eventos` estiver ausente, o endpoint e o
executor do cron reutilizam automaticamente `runnerhub_foco_eventos`.

## Requisicao

```http
POST https://business.roadrunners.run/api/foco/jobs/match-events.cfm
Authorization: Bearer {jobToken}
Content-Type: application/json
```

```json
{
  "limit": 20,
  "pageSize": 20,
  "fromDate": "2023-01-01",
  "minReviewScore": 60,
  "autoLinkScore": 85,
  "autoLink": true,
  "dryRun": false
}
```

- `limit`: eventos processados por chamada, entre 1 e 20.
- `pageSize`: itens por pagina da Foco, entre 1 e 100.
- `eventId`: opcional; restringe o teste a um evento da base.
- `fromDate`: data final minima quando `eventId` nao for informado.
- `minReviewScore`: score minimo para armazenar candidato para revisao; por padrao 60.
- `autoLinkScore`: score minimo para auto-vinculo quando `autoLink=true`; por padrao 85.
- `autoLink`: permite gravar candidato(s) acima de `autoLinkScore`, com data e UF compativeis.
- `dryRun`: nao grava estado, candidatos ou badges.

## Regras de seguranca

- Eventos com galeria Foco existente podem receber galerias adicionais; o
  badge legado permanece como espelho principal de compatibilidade.
- Candidatos de cidade diferente da cidade do evento Road Runners nao sao
  armazenados para revisao.
- Candidatos abaixo de 60 pontos sao ignorados por padrao.
- Candidatos de 60 ate 84,99 pontos ficam para revisao manual no Business.
- Candidatos negados manualmente no Business ficam com `status='ignored'` e nao
  voltam para a fila em reprocessamentos futuros.
- Um ou mais candidatos com 85 pontos ou mais, data compativel e UF compativel
  podem ser vinculados automaticamente quando `autoLink=true`.
- A mesma competicao Foco nao pode estar ativa em dois eventos Road Runners.
- Um evento Road Runners pode ter mais de uma galeria Foco ativa.
- O processo nao usa `tb_evento_corridas.data_processamento`.

## Modelo de vinculo

A relacao principal fica em `tb_evento_foco_vinculos`, permitindo multiplas
galerias Foco para o mesmo `id_evento`. O `tb_badges` continua recebendo uma
galeria principal para compatibilidade com telas antigas que esperam apenas um
badge `foco`.

## Revisao no Business

Casos ambiguos ficam disponiveis em `/administracao/foco-revisao/`. O administrador
pode vincular uma galeria adicional, ignorar um candidato incorreto, desvincular
uma galeria ativa ou descartar o caso. O Business bloqueia vinculo manual abaixo
de 60 pontos para evitar candidatos fracos. Reaplique `foco_match_schema.sql` ao
instalar essa tela para adicionar a tabela de vinculos multiplos, status de
candidato e campos de auditoria.
