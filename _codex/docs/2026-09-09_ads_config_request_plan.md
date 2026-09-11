# Ads request configuration Implementation Plan

**Concluído e publicado em 09/09/2026 11:11:33 Brasília.** [Registro, validação Adobe desktop/mobile e backup](2026-09-09_ads_config_publicado.md). O bloqueio SSH descrito abaixo é histórico; usar o pacote `_linux.tar.gz`, não o pacote macOS anterior.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Restaurar a leitura da configuração Ads do site atual sem depender de APPLICATION compartilhada.

**Architecture:** Carregar `config/ads.local.cfm` em escopo local de um serviço sem estado, uma vez por REQUEST. Os três renderizadores e o SHADOW recebem a mesma estrutura. A inicialização legada em settings permanece por compatibilidade, mas deixa de ser fonte dos consumidores públicos.

**Tech Stack:** CFML; testes offline no CommandBox/Lucee existente; validação de produção no navegador CUA.

**Spec:** `2026-09-09_banners_desativados_diagnostico.md` e aprovação do usuário em 09/09: corrigir Ads sem restart, login ou billing.

## Global Constraints

- Não mudar Application.cfc, nome da aplicação, settings globais, ads.local, DSN runnerhub, permissões, SQL, sessão, billing, viewability ou geolocalização.
- Não criar commits/branches. Preparar candidato em diretório temporário, preservando checkout sujo.
- Manter allowlists HOUSE/CPC/SHADOW e UUIDs com a mesma validação existente; arquivo ausente implica listas vazias, sem herança de outro ambiente.
- Publicar somente cinco arquivos de runtime com backup e hashes; testes/documentação não são endpoints públicos novos.

### Task 1: Carregamento isolado e consumidores

**Files:** criar `services/AdsV1ConfigService.cfc`, `includes/ads_v1/runtime_config.cfm`; modificar `includes/ads_v1/banner_delivery.cfm`, `includes/eventos_ads.cfm`, `includes/estrutura/home_sidebar_promos.cfm`; criar `_codex/tests/ads-request-config-contract.cfm` e fixtures privados de teste.

**Interfaces:** `AdsV1ConfigService.load(configTemplate='../config/ads.local.cfm', host='')` retorna struct com datasource, environment e quatro allowlists. Include preenche `REQUEST.adsV1` uma vez e passa apenas host. O template relativo ao componente preserva o suporte do Adobe CF.

- [x] Escrever contrato: config prod habilita banner, config ausente em beta não herda prod, dev não altera prod, listas inválidas não habilitam slots, UUIDs válidos normalizados; sentinela APPLICATION não muda.
- [x] Executar teste antes do serviço e observar falha por componente inexistente.
- [x] Implementar loader com variáveis locais, sanitização equivalente e falha fechada para arquivo inválido. Include relativo ao componente, sem input do usuário nem mapping global de configuração.
- [x] Substituir as quatro leituras globais (banner, native, sidebar e SHADOW) por `REQUEST.adsV1` após include idempotente.
- [x] Executar contrato CFML offline e contratos estáticos existentes de banner/native/serviços; revisão independente do diff. O script de bot depende de HTTP público e não completou (DNS na execução); não apresentado como aprovado.

### Task 2: Publicação e evidência

- [x] Preflight remoto read-only, comparar hash de cada consumidor com origem local pré-patch.
- [x] Backup explícito dos três arquivos existentes e registrar inexistência dos dois novos; publicar dependências antes de consumidores, preservando owner/mode dos existentes.
- [x] Verificar hashes remotos e intocados: ads.local, Application.cfc, settings, viewability e endpoints financeiros.
- [x] Abrir home e estado/SC por CUA, conferir slot requested/served e imagem efetivamente carregada; não clicar anúncio nem emitir beacon manual.
- [x] Documentar resultado, rollback e limite: não identificado qual request sobrescreveu APPLICATION anteriormente.

## Resultado local e bloqueio de publicação

- Teste reproduzível: `bash _codex/scripts/test_ads_request_config_local.sh` no Business. O runner monta temporariamente serviços, fixtures, dois sites com raízes físicas distintas e mappings exclusivos de teste; não executa Application.cfc do portal, não acessa banco nem rede.
- Suíte CFML: 16 verificações aprovadas no Lucee 5.3.10.120, incluindo duas raízes físicas na mesma APPLICATION; código precisa ainda de confirmação no Adobe de produção.
- Três contratos estáticos aprovados no RoadRunners: `test_ads_v1_banner_render_contract.sh`, `test_ads_v1_native_render_contract.sh`, `test_ads_v1_native_service_contract.sh`. `git diff --check` limpo.
- Revisão independente corrigiu uso inicial de include físico absoluto. A [documentação Adobe](https://helpx.adobe.com/coldfusion/cfml-reference/coldfusion-tags/tags-i/cfinclude.html) exige caminho relativo/lógico; candidato final usa `../config/ads.local.cfm` relativo ao CFC. Não restou P1/P2 na revisão local.
- Primeiro preflight remoto foi somente leitura; tentativas posteriores expiraram na conexão da porta 22, incluindo IPv4. Nenhum arquivo enviado, nenhum restart/reload/SQL/beacon manual.
- Pacote Business: `_codex/releases/2026-09-09_ads_request_config.tar.gz`; somente os cinco arquivos de runtime, sem config privada, credenciais, testes ou outros arquivos do checkout.

### Arquivos do candidato (SHA-256)

| Arquivo | SHA-256 |
| --- | --- |
| services/AdsV1ConfigService.cfc | 965876abb5c229ec9770b748ccc7e33dd5da9dcb39cd1529952c6405d9f8cf6c |
| includes/ads_v1/runtime_config.cfm | 13cfa9ea48730bfd0a715b20c66dbfc84eb85454b27828409b7e82f4da9570bc |
| includes/ads_v1/banner_delivery.cfm | e28141ec19c01a160c772db29fdc3c97f5681040caddd39cef18f5bb33446077 |
| includes/eventos_ads.cfm | fd2f5d8b08cc89531d095f28fdddb00d70532a1c95baa18122c1afcddbbe7e38 |
| includes/estrutura/home_sidebar_promos.cfm | 307d992b76917868e60640ec6a513a5e7088737c92632cfcfc28f84fbcffb86f |

### Retomada segura

1. Revalidar ausência dos dois arquivos novos e SHA dos consumidores: banner `e6a9e8f68027952e780f44c61192466d493957bef51095e3c648d864917f9150`; eventos `79e160b06f320d41b9ffa068aef70cf6a3e87f9d87db5e9d31c1332b56222c83`; sidebar `0a1ee3ceacf2a91c57800bf3765d62ab252e0a81fefb9dda98e39a8ec83ea7d7`.
2. Conferir caminhos sem symlinks; backup privado dos três consumidores; extrair candidato fora do docroot e conferir hashes antes de substituir.
3. Publicar serviço e runtime primeiro, depois consumidores, cada arquivo com substituição atômica no mesmo filesystem. Não extrair pacote direto sobre docroot nem sincronizar pastas inteiras.
4. Em caso de erro Adobe/renderer, restaurar os três consumidores do backup antes de retirar os novos arquivos; não restaurar configurações globais.
5. Validar home/estado/SC desktop/mobile no CUA: marcador solicitado e imagem efetivamente carregada. Não clicar anúncios ou emitir eventos manuais. Confirmar arquivos intocados e registrar a observação.
