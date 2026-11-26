# Categoria Atleta de elite e revisão dos desafios

Solicitação de 24/11/2026: criar a categoria, classificar Guilherme Neto e investigar os vínculos em desafios dos 107 permanentes ainda sem motivo.

## Runtime publicado

- `services/VerifiedAdmin.cfc`: rótulo `elite = Atleta de elite`; opções de edição liberam a categoria somente quando a restrição do banco já a aceita. Demais categorias continuam disponíveis durante a transição.
- `portal/verificados/home.cfm`: categoria no filtro e, após a migração, nos editores individual, rápido e em lote.
- Backup recuperável: `/var/backups/business-verified-elite-lia1aqgw`.
- Recibos e baseline em `_codex/staging/verified-elite-20261124/`.

Validação: 27 verificações nativas CFML e proteções de administrador/CSRF/ações antigas; migração em PostgreSQL temporário com reexecução idempotente, revisão concorrente, preservação dos demais históricos e concessões e rejeição de não administrador/perfil sem permanência. Compilação CF2025, hashes e gates HTTP conferidos. Tela publicada e detalhe do Guilherme renderizados HTTP 200 em fixture privada somente de leitura. Todos os recursos temporários foram encerrados/removidos e a remoção conferida.

## Migração solicitada ao proprietário

`_codex/sql/2026-11-24_verified_elite.sql` acrescenta `elite` à restrição e à função auditada. Classifica exclusivamente o perfil 28882 (usuário 49983, `gneto25`), por autorização de Leonardo Sobral (administrador 139), com referência ao resultado 1831949 e à ficha CBAt 24936. Selos, vencimentos e pagamentos não são modificados. Guardas impedem sobrescrever classificação concorrente ou função/restrição diferentes do baseline; repetir o SQL não duplica o histórico.

Mantida a preferência anterior do proprietário por executar migrações no DataGrip. SQL integral solicitado, banco `runnerhub`, role `runner_dba`. Na última consulta desta entrega ainda estava pendente: `elite_ready = 0`, Guilherme `nao_informado`, concessão permanente preservada. A classificação não deve ser declarada concluída até conferir o recibo e a tela após a execução.

## Cruzamento dos 107 perfis

Auditoria somente de leitura, em transação consistente, por identidade da conta (IDs maiores que zero), com consulta a `desafios`, `desafio_cna`, `tb_desafios_rr`, `tb_desafios_rr_provas`, `desafio_leads` e GoRunners via `gorunners.users.rr_user_id`. Catálogos de desafios/produtos fornecem os nomes. Observações administrativas consultadas para indicar cancelamentos, upgrades e entregas; não foram transformadas em motivos automaticamente.

- 105 possuem registros em `desafios`; 73 têm alguma inscrição com status C e 32 apenas registros sem confirmação.
- 103 constam em Todo Santo Dia, 43 em Desafio 365, 14 em Desafio 366, 15 em Brasil Gigante; há sobreposição e outros registros menores nos circuitos catarinenses, Foco e Supra.
- 46 têm VIP/upgrade Todo Santo Dia com status C: 37 sem referência de pedido e 9 com referência. Status C não comprova pagamento ou origem exclusiva do selo.
- O legado CNA contém 43 dos mesmos perfis, sem acrescentar novas pessoas à cobertura. Leads históricos aparecem em 14 perfis, sem acrescentar pessoas.
- Não foram encontrados registros nos circuitos antigos `tb_desafios_rr`/`tb_desafios_rr_provas` ou progresso GoRunners via vínculo de conta para essa coorte.
- Débora Aparecida Simas (27813) e Karla Silva (13937) não apareceram nas tabelas consultadas. Ausência não prova inexistência em outras fontes.
- O ledger consultado por usuário/produto e `rr_verified.challenge_orders` não retornaram fontes financeiras para esta coorte; não foi feita nova consulta à Pagar.me. Não concluir que ninguém pagou com base nesse resultado.

Relação privada pesquisável: `_codex/analyses/verified-challenges-20261124/revisao-desafios.html`, com cada perfil, desafios/produtos, status, presença de referência de pedido e link para revisão no Business. O retrato contém Guilherme, pois foi extraído antes da classificação autorizada. JSONs privados na mesma pasta; geradores em `_codex/scripts/audit_verified_challenges.py` e `render_verified_challenge_review.py`.

Nenhum motivo dos demais perfis, selo, prazo ou configuração de pagamento foi alterado. Sem commit ou push.
