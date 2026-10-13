# Primeiro acesso ABRACEO com CNPJ pendente

Publicação e emissão em 11/10/2026, autorizadas pelo usuário. O lote de 47 novos pré-cadastros teve 46 e-mails reconferidos nas páginas públicas da ABRACEO. Pace Eventos (#89) não tem e-mail publicado confirmado e permanece sem habilitação neste lote. Confirmação é de publicação do contato, não de entrega nem de representação legal.

## Resultado

- 46 novas empresas elegíveis no primeiro acesso; total 87 (41 anteriores + 46 novas).
- 46 novos vouchers nominais READY, vinculados por ID de conta e por e-mail do convidado.
- 40 vouchers anteriores preservados integralmente; total 86 códigos na planilha consolidada.
- Prazo de resgate: 10/11/2026, 23h59 de Brasília (expiração técnica 11/11/2026 00h00).
- 88 perfis ABRACEO e 47 contas com documento pendente preservados. Nenhum usuário operacional, declaração real ou acesso pessoal foi criado pela emissão. Não houve envio de mensagens.

A planilha `outputs/abraceo-convites-atualizados-20261011/vouchers_abraceo.xlsx` preserva as 40 linhas e estados de envio do arquivo anterior e adiciona as 46 novas. A aba Pendências mantém Morro MT (grafia do e-mail a confirmar) e adiciona Pace Eventos. O texto `convite_abraceo.txt` orienta voucher nominal, inclusive quando o CNPJ está pendente; eventual troca de destinatário exige revisão do convite.

## Alterações publicadas

- `estudos/includes/FirstAccess.cfc`: voucher resolve a conta pelo vínculo em `primeiro_acesso_convites`, independentemente do CNPJ. Busca pública por CNPJ continua validando documento confirmado. Admin pode emitir por ID, com validação de elegibilidade, identidade administrativa e rejeição de seleção ambígua.
- `estudos/primeiro-acesso/api.cfm`: encaminha companyId apenas à operação administrativa de emissão.
- `services/accountDelegation/RequestBoundary.cfc`: permite esse campo no endpoint pessoal exato; preserva bloqueio de ator arbitrário e parâmetros duplicados.
- `estudos/primeiro-acesso/index.cfm` e `primeiro-acesso.js`: seletor por ID; CNPJ pendente explícito; dados jurídicos pesquisados identificados como referências; cache do script atualizado.

Nenhuma migração de estrutura adicional foi necessária. Elegibilidade foi inserida somente para as 46 empresas com contato apto. O acesso continua restrito à leitura pessoal da prévia, mediante Google com o e-mail convidado, função e autodeclaração. CNPJ pesquisado não vira titularidade jurídica e nenhum vínculo operacional é criado.

## Validação e recuperação

47 verificações transacionais aprovadas, com rollback integral das gravações de teste, cobrindo fluxo anterior por CNPJ, voucher com documento NULL, e-mail incorreto, expiração, conta desabilitada, campanha pausada, revogação, repetição idempotente, declaração obrigatória, usuário sem privilégio, seleção ambígua e preservação do estado operacional. Compilação de 4 arquivos CFML no ColdFusion 2025 real e sintaxe JavaScript aprovadas. Hashes de 5 arquivos de produção conferidos. HTTP na origem: página anônima 200; consultas e parâmetros indevidos sem identidade retornam 401 (bloqueio inicial por autenticação); allowlist e duplicidades também foram testadas na suíte do RequestBoundary.

Navegador autenticado: 87 empresas no seletor, 46 identificadas como CNPJ pendente; consulta por CNPJ existente preservada, com nome, logo e dados; layout móvel de 390 px conferido. Nenhum voucher nominal real foi resgatado na conferência.

Operadores: `_codex/scripts/deploy_abraceo_pending_vouchers.py` e `outputs/abraceo-convites-atualizados-20261011/support/issue_vouchers.py`. O segundo bloqueia nova emissão se já houver tentativa registrada e permite conferir/recuperar os códigos existentes. Nunca imprimir códigos em logs. Arquivo final e relatórios com códigos têm modo 0600; o banco armazena apenas hashes.

Backups:
- `/var/backups/business-abraceo-voucher-pendente-20261011`: baseline dos cinco arquivos, candidato, testes e verificações.
- `/var/backups/business-abraceo-vouchers-pendentes-20261011`: baseline anterior à emissão, seleção nominal, códigos privados e conferência.

Não restaurar o runtime anterior deixando os novos vouchers ativos: a versão antiga depende de CNPJ para localizá-los. Em incidente, preferir correção do runtime ou suspender explicitamente as novas elegibilidades preservando convites e histórico. Revogação de vouchers/acessos deve seguir a gestão existente, sem exclusão de registros. Não executar novamente emissão nem habilitação; verificar os relatórios e a situação atual primeiro.
