# Publicação — resumo de potencial e ocupação

> **Ressalva posterior:** a conferência abaixo comprovou publicação e aritmética, não adequação do denominador ao potencial comercial. O diagnóstico seguinte confirmou que slots vazios recolhidos eram excluídos por não terem `slot_viewable`; portanto o 100% registrado neste recibo não comprova ocupação total do inventário. A [correção aprovada](2026-09-12_audience_delivery_opportunities.md) substitui essa definição.

Autorização: usuário determinou “no final sempre publique”. Publicação concluída em **12/09/2026 às 22:36:23 BRT** (`2026-09-13T01:36:23Z`), exclusivamente no Business.

## Lote e recuperação

- Webroot: `/var/www/business.roadrunners.run`.
- Backup privado: `/var/backups/business-audience-occupancy.Ow8TA6`.
- Pacote SHA-256: `7233b8007da588aca5355197ba5dc602425ae4d56a5d1b15293c9ee8aab02f91`.
- Manifesto `runtime.tsv`, candidatos, publicador, `published.log`, metadados, três backups e 27 hashes de proteção preservados na pasta privada.
- Os dois novos arquivos entraram primeiro; os três substituídos tiveram baseline conferido antes de cada troca. Proprietário/grupo/modo preservados. Cinco hashes publicados e 27 arquivos protegidos conferidos após a publicação.

| Arquivo | SHA-256 publicado |
| --- | --- |
| `portal/audiencia/queries/occupancy.sql` | `3fb3b5ec74ace63817ebcef788e042187e17a7d2392c2abe25d4019915bfab8b` |
| `portal/audiencia/occupancy.cfm` | `e6462503952b7cd0c1234f3bc0e653b1c7b8e6b6beec789877ace17db8cdc0b1` |
| `assets/css/audience-dashboard.css` | `50b1804532c6c2c5e00ed8d23a4954e73ea08b5e30f6424451765aff8f4dd415` |
| `portal/includes/audience_backend.cfm` | `f16d527949e6b0232da261122413ba5a1cff3f7f95bd479db554c643b80a261b` |
| `portal/audiencia/home.cfm` | `ea2b2aff82ea38b8e12828703bbfa19344d121729db9080a073fc5d90abb099c` |

Recuperação, se necessária: conferir primeiro que os destinos ainda correspondem aos hashes publicados; restaurar os três arquivos substituídos a partir de `before/`, preservando metadados. Os dois arquivos novos podem permanecer inativos, sem apagar dados. Não sobrescrever mudanças posteriores de outra frente.

## Validação real

Painel autenticado já aberto pelo usuário recarregado em `https://business.roadrunners.run/portal/audiencia/#audience-overview`, sem novo login ou troca de conta. Captura visual conferida: cards, barras separadas Ads/banners, visitantes e sessões juntos, detalhes técnicos recolhidos e seis abas presentes.

Recorte observado às 22:37 BRT: 7 dias, contexto comercial, todas as UFs/páginas/dispositivos, produção e sem acessos internos.

| Indicador | Valor observado |
| --- | ---: |
| Potencial observado | 1.736 |
| Preenchidos, incluindo institucionais | 1.736 (100%) |
| Sem anúncio | 0 (0%) |
| Ads com visibilidade | 225, todos preenchidos |
| Banners com visibilidade | 1.511, todos preenchidos |
| Visitantes estimados | 1.117 |
| Sessões | 1.576 |
| Sessões qualificadas | 883 |
| Páginas com atividade | 5.409 |

Conciliação: `225 + 1.511 = 1.736`, preenchidos + vazios + sem classificação = potencial; sem classificação não apareceu por ser zero. São valores do recorte observado, não números fixos, vendas ou previsão de entrega. **100% preenchido inclui institucionais; não significa 100% vendido.** Não amplia a cobertura de coleta do produtor nem reconstrói posições sem sinal visível.

Verificações HTTP na origem com TLS validado: consulta SQL direta `403`, painel sem autenticação `302`, CSS versionado servido com hash igual ao publicado. `apache2` e `cf2023` ativos. Sem reinício, migração, execução manual de SQL, alteração de DSN, permissões de banco, login, coleta, créditos, cobrança ou `tb_log`.

Preflight local independente aprovado; seis testes Node e `git diff --check` passaram nesta continuação. PostgreSQL/CFML/browser sintéticos anteriores documentados no [relato de implementação](2026-09-12_audience_occupancy_business.md). A validação publicada executou o resumo pelo Adobe real; não mediu carga, tempo isolado do SQL nem todas as combinações de filtros.

## Preferência operacional

A instrução de publicar ao final ficou registrada no `AGENTS.md` local do Business. O arquivo de instruções e esta documentação não integram o runtime enviado. A preferência não autoriza publicar trabalho alheio, contornar bloqueios nem executar operações Git; nenhuma operação Git mutante foi realizada.
