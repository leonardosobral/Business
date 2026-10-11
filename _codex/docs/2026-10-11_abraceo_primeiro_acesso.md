# Primeiro acesso ABRACEO — publicado em 11/10/2026

Entrada: https://business.roadrunners.run/estudos/primeiro-acesso/
Gestão: https://business.roadrunners.run/estudos/primeiro-acesso/#gestao

## Regra aprovada

Qualquer usuário autenticado pelo Google pode localizar um dos pré-cadastros por CNPJ e declarar que representa a empresa para liberar a leitura pessoal da prévia. O CNPJ é público e a declaração não comprova representação legal. Nenhum vínculo em `tb_conta_usuarios`, titularidade, papel operacional ou status da conta empresarial é criado/alterado. As 36 contas novas continuam PENDENTE; as 5 existentes mantêm seu estado.

41 empresas habilitadas, a partir dos perfis ABRACEO importados: dados cadastrais e logos são reaproveitados. Casos duvidosos que não entraram no lote permanecem fora do fluxo. A concessão não inclui estudo anual nem desconto comercial. Campanhas comerciais anteriores permanecem intactas.

## Jornada

1. Login Google verificado. O retorno ao primeiro acesso funciona independentemente da seleção ou aprovação da conta empresarial.
2. CNPJ validado por dígitos ou voucher nominal. O cadastro exibe nome, razão social, CNPJ, contato público, endereço disponível e logotipo.
3. Abas separam dados da empresa e representante. Nome/e-mail do representante vêm da identidade autenticada. Função e autodeclaração são obrigatórias; correções são opcionais e registradas para revisão, sem sobrescrever os dados da empresa.
4. Confirmação concede leitura pessoal e oferece o leitor protegido da prévia janeiro–setembro/2026. Reenvios são idempotentes. Acesso revogado não é reativado por nova tentativa de CNPJ.

## Operação dos vouchers

Administradores usam a aba **Vouchers e representantes**: selecionam empresa, e-mail convidado e vencimento. Código exibido uma única vez e armazenado apenas como hash. Não há envio automático de mensagens. O convidado usa o mesmo e-mail no login. A biblioteca mantém a emissão/resgate e revogação pessoais existentes; vouchers emitidos nessa gestão específica também carregam o vínculo com a empresa para a jornada de primeiro acesso.

A lista administrativa mostra até 200 declarações recentes e suas correções. Revogações permanecem na gestão da biblioteca. Nenhum voucher para destinatário real foi emitido nesta implantação; os testes de concessão e resgate foram revertidos integralmente. O CNPJ já permite ingresso sem voucher.

## Implementação e dados

Runtime publicado: `estudos/includes/FirstAccess.cfc`, quatro arquivos em `estudos/primeiro-acesso/`, link em `estudos/index.cfm`, retorno Google em `includes/backend/business_google_callback.cfm`, allowlist pessoal em `services/accountDelegation/RequestBoundary.cfc`.

Migração aditiva: `_codex/sql/2026-10-11_estudo_primeiro_acesso.sql`.

- `estudo.primeiro_acesso_empresas`: lote elegível, com flag de suspensão individual.
- `estudo.primeiro_acesso_convites`: vínculo voucher–empresa.
- `estudo.primeiro_acesso_representantes`: declaração, identidade, função, correções, versão e acesso pessoal, única por usuário/empresa.
- Campanha `abraceo-primeiro-acesso`: prévia ativa, benefício comercial 0; usa os acessos pessoais e auditoria existentes.

API POST autenticada com CSRF, limite de 40 chamadas/minuto por sessão e allowlist estrita de campos. Dados retornados por lista explícita de campos, sem JSON bruto da pesquisa. Nenhum código de voucher é colocado em URL ou armazenamento persistente do navegador.

## Validação e recuperação

31 verificações ColdFusion transacionais passaram, incluindo CNPJ, voucher nominal, outro e-mail, expiração, revogação, reenvio, isolamento operacional e rejeição de parâmetros ambíguos. Todas as escritas de teste tiveram rollback. Compilação ColdFusion e sintaxe JavaScript passaram.

Na origem: página anônima 200; API sem autenticação 401; tentativa de ator arbitrário e parâmetro duplicado 403. O cliente Python pela borda recebeu bloqueio Cloudflare 1010; a validação pública autenticada foi realizada pelo navegador normal, sem alterar proteções.

Navegador real: consulta de 3LR Eventos com dados/logo, CNPJ inválido com mensagem visível, troca para voucher, 41 empresas na gestão, abas por teclado e layout mobile 390×844. Nenhuma declaração real foi enviada em nome do operador. O teste transacional validou concessão e leitura protegida.

Hashes de oito arquivos publicados conferidos. Baseline preservado para contas, membros, eventos, perfis e campanhas anteriores. 0 vouchers e 0 acessos persistidos ao fim da validação.

Backup inicial: `/var/backups/business-abraceo-first-access-20261011/baseline`.
Ajuste visual: `/var/backups/business-abraceo-first-access-20261011/ui-update/baseline`.
Evidências locais: `_codex/staging/abraceo-first-access-20261011/release-*.json`.

Rollback de runtime: `python3 _codex/scripts/deploy_abraceo_first_access.py rollback` (requer acesso SSH de operação). Verifica conflitos antes de restaurar e preserva tabelas/dados de primeiro acesso. Para suspender novas entradas sem perder histórico, pausar a campanha específica pelo fluxo administrativo existente; para revogar leituras já concedidas, usar revogação individual da biblioteca. Não remover tabelas com declarações reais.
