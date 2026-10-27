# Road Runners Teams — operação

Implementado e publicado em 26/10/2026. DDLs instalados manualmente pelo usuário no banco existente: produção em rr_teams e fixture em rr_teams_test. Não houve criação de outro banco, alteração de credenciais/grants, operação Git ou envio real de email nas validações.

## Acessos
- Cadastro: https://business.roadrunners.run/teams/cadastro/
- Painel e revisão global: https://business.roadrunners.run/teams/
- Diretório e adesão: https://roadrunners.run/teams/
- Meu Team: https://roadrunners.run/teams/meu-team/

O global vê todos os Teams; os demais recebem apenas seus acessos. Cadastro exige CREF e aprovação humana com evidência e conferência da versão examinada. O domínio não concede vínculo empresarial ou permissão de eventos. Campo legado assessoria e equipes históricas de resultados preservados.

## Regras
Um vínculo ativo por atleta, confirmação autenticada e CSRF. Próxima adesão/troca após 14 dias. Saída não elimina prazo. Remoção pelo Team bloqueia reentrada até liberação e mantém prazo. Suspensão/encerramento pelo RR encerra vínculos e permite nova escolha. Administração e filiação esportiva são independentes.

Acompanhamento: perfil esportivo e resultados oficiais existentes, sem saúde, contatos privados ou atividades privadas. Aquisição considera primeira adesão e origem rr_teams; retorno após 30 dias corresponde apenas a visitas autenticadas observadas em Teams. A tela explicita essa cobertura.

## Email
Job 27, endpoint /teams/mail-worker.cfm, intervalo de 5 minutos, referência existente business_ai_mails. Usuário autorizou explicitamente: “Autorizar a ativação dos convites por email”.

A revisão automática havia bloqueado a ativação por exigir autorização explícita para futuros envios externos. O comando só foi repetido após essa autorização.

Transporte em services/teams/EmailTransport.cfc: CFMAIL nativo, TLS e mesmas configurações Mandrill existentes. O sender legado foi preservado; o componente script mail não está disponível nesta instalação. Destino único validado, nome de destinatário fixo e subject sem CR/LF. Nenhuma credencial foi criada, alterada ou exibida.

Até 10 mensagens por lote, orçamento de 15 segundos para iniciar novos envios e timeout SMTP de 20 segundos. Mensagens não tentadas voltam à fila sem consumir tentativa. Falhas aguardam 15 minutos, até três tentativas. SENDING interrompido permanece ambíguo para inspeção, evitando reenvio automático de entrega cujo resultado externo é desconhecido. Corpo sensível é limpo após confirmação. WhatsApp abre mensagem para o próprio atleta revisar e enviar.

## Verificação
- 12 suítes: instalação, banco, CSRF, identidade, fronteira de conta, métricas, envelope, transporte, render, HTTP, concorrência e compilação dos candidatos exatos.
- Concorrência real: uma adesão e uma rejeição por atleta; um convite e uma rejeição por destino. Fixture limpa.
- 12 probes HTTP reais; hashes de 49 arquivos e 13 dependências preservadas.
- Painel global publicado renderizado contra produção e worker autenticado em dry-run com HTTP 200.
- Desktop e 390px inspecionados; QR Code local decodificado com payload correto.
- Nenhum SMTP real de teste. A entrega externa será exercida por convites reais solicitados pelos usuários.

## Recibos e recuperação
- Manifesto e candidatos: _codex/teams/release-manifest.json e release/.
- Suítes: _codex/teams/verification.json.
- Publicação: _codex/teams/publication.json.
- Estado operacional: operation-activate.json e operation-verify.json.
- Backup inicial: /var/backups/rr-teams-release-mlwyc97n.
- Atualização do transporte: /var/backups/rr-teams-release-g3kpw5z6.
- Tentativa revertida: /var/backups/rr-teams-release-yl0xb9vl; expectativa do probe anônimo corrigida, pois o formulário CREF exige login.

Antes de reverter runtime, desativar somente o job Teams. O segundo backup preserva o Mailer anterior; o primeiro preserva os seis pontos compartilhados anteriores. Reverter apenas arquivos correspondentes aos hashes do recibo, sem sobrescrever trabalho posterior. Manifestos distinguem arquivos novos para retirada e existentes para restauração. Dados reais de Teams não devem ser removidos ao reverter código.

As suítes source/native fazem a checagem inicial de job desativado antes de publicação. Após ativação, usar o verificador operacional para leitura de produção e adaptar essa pré-condição antes de um novo ciclo de implantação.


## Logotipo oficial — 26/10/2026

Aplicado o SVG fornecido pelo usuário, preservado byte a byte (SHA-256 `37bae9831ff48404d57ca074d5b21f4ed4419da7eb106d02820c074319c2e7ea`). Cabeçalhos compartilhados de Business e RR usam imagem com texto alternativo e dimensões intrínsecas, largura responsiva de 248px e fundo cinza escuro para contraste. CSS com versão 3.

Publicação limitada a seis arquivos: header.cfm, teams.css e rr_teams.svg em cada site. Backup recuperável: `/var/backups/rr-teams-logo-66i7opi2`. Recibo: `_codex/teams/logo-publish.json`; hashes cumulativos atualizados em `publication.json`. Validação visual em larguras de 390px e 1180px, conferência real das páginas publicadas e oito verificações HTTP (quatro páginas e quatro assets), incluindo igualdade do SVG publicado com o original. Nenhuma operação de banco ou email nesta alteração.

O script `_codex/scripts/deploy_teams_logo.py` registra baseline, faz troca atômica com comparação de hashes e restaura os seis arquivos se alguma verificação falhar. O empacotador principal também inclui `.svg` nos assets Business para preservar o logotipo em próximas publicações.


## Separação da gestão global — 26/10/2026

- Administração global: `https://business.roadrunners.run/administracao/teams/`, menu **Contas e parceiros → Gestão de Teams**, junto de Empresas. Shell compartilhado completo do Business, indicadores, tabela, busca por nome/cidade, filtros de situação/tipo/UF e paginação.
- Detalhes em abas GET: Cadastro, Responsável técnico, Revisão, Equipe administrativa, Atletas e Histórico. Filtros da lista preservados; busca/paginação de atletas usam `aq/apage`, independentes de `q/page` da lista global. Coluna de ações fica visível durante a rolagem da tabela.
- `/teams/` permanece o painel dos responsáveis, com lista limitada aos seus vínculos administrativos. Admin global em GET é encaminhado para a gestão, mantendo seleção e recorte de atletas quando houver. POST global na rota antiga é recusado; decisões de revisão estão somente na área administrativa.
- Autoridade global exige identidade do Business verificada e administrador ativo no banco; cookie, titular/consulta de Team, contexto delegado e simulação não concedem acesso. Revisões usam o serviço existente com CSRF, versão, evidência de CREF e justificativa. Suspensão/encerramento avisam sobre o fim dos vínculos e pedem confirmação.
- Formulários de cadastro preservam dados em erro e versão submetida. Corrigido o reconhecimento de campos opcionais website/description quando a enumeração CF retorna as chaves em maiúsculas (`listFindNoCase`).

Publicação limitada a nove arquivos Business. Backup recuperável: `/var/backups/rr-teams-global-release-96nables`. Manifesto e baseline em `_codex/teams/global/`; recibo `publication.json` na mesma pasta, com hashes cumulativos também atualizados em `_codex/teams/publication.json`. Doze dependências preservadas, incluindo transporte de email, job, configuração, logotipo, shell e gestão de Contas. A primeira tentativa foi automaticamente revertida por um probe que esperava formulário autenticado numa página anônima; o probe corrigido passou e a segunda publicação foi concluída.

Validação: 12 checks de consulta global em CF2025, 35 checks HTTP da separação, 27 checks de regressão do Teams público/responsáveis, oito CFML compilados, revisão independente (um ajuste de redirect corrigido e testado), prévia em 390px/1180px, hashes e seis probes de produção, incluindo shell global autenticado completo. Fixture vazia ao terminar; transações dos testes e efeitos legados de manutenção de notificações do probe foram revertidos. Nenhum email de teste, DDL, operação Git ou modificação de dados reais de Teams.

Ferramenta desta publicação: `_codex/scripts/deploy_teams_global.py` (`prepare`, `compile`, `publish`), com baseline comparado à publicação anterior, evidência HTTP dos mesmos hashes, troca atômica e rollback automático. Para próxima alteração, inspecionar baseline real novamente. A ferramenta operacional `_codex/scripts/operate_teams.py` passou a conferir o painel em `/administracao/teams/`, com rollback dos efeitos legados da leitura do shell.


## Cadastro manual de Team na gestão global — 26/10/2026

Adicionado o botão **Novo Team** na gestão global. Link direto: `https://business.roadrunners.run/administracao/teams/?novo=1`. O formulário usa os campos e validações existentes de cadastro. **Salvar e revisar** cria o Team em `PENDING` e encaminha à aba Revisão, mantendo os filtros da listagem. Cancelar retorna à lista. Erros de validação e CSRF conservam campos simples com saída HTML escapada.

A criação manual exige administrador global ativo e identidade verificada, tanto na rota como em `Service.registerGlobal`. Ela registra a autoria (`requested_by` e evento `TEAM_REGISTER_MANUAL`), sem atribuir OWNER ao admin criador, vincular atletas ou enviar convites automaticamente. Os responsáveis recebem convites pela aba Equipe administrativa; a aprovação permanece na aba Revisão, com consulta de CREF e evidência. O auto cadastro preserva OWNER e limite diário; o cadastro manual não usa a quota pública de cinco solicitações. CPF/CNPJ, CREF, contato e duplicidade continuam validados pelo serviço.

Publicados somente quatro arquivos: `services/teams/Service.cfc`, `administracao/teams/home.cfm`, `administracao/teams/includes/backend.cfm`, `administracao/teams/includes/create.cfm`. Backup: `/var/backups/rr-teams-manual-release-179i6pt1`. Baseline, candidatos, compilação e recibo em `_codex/teams/manual/`; hashes cumulativos em `_codex/teams/publication.json`. Dezoito dependências preservadas. Ferramenta: `_codex/scripts/deploy_teams_manual.py` com prepare/compile/publish e proteção de baseline/CAS/rollback.

Verificação: 29 checks nativos de cadastro manual, 47 checks HTTP da gestão global incluindo criação, 27 regressões de Teams público/responsáveis; quatro CFML compilados. Revisão independente encontrou perda de campos com CSRF expirado, corrigida e testada RED/GREEN. Prévia desktop/celular e fluxo real em produção (lista → Novo Team → formulário) conferidos. Publicação validada com cinco probes, inclusive formulário autenticado completo; não foi criado Team real de teste nem enviado email de teste. Nenhum DDL ou operação Git.


## Adicionar usuário existente à gestão — 26/10/2026

Na gestão global, aba **Equipe administrativa**, a seção **Adicionar usuário existente** oferece busca por nome, email ou ID, limitada a 25 contas ativas sem acesso administrativo ao Team selecionado. Nome, email e ID identificam a conta antes da inclusão. Filtros e busca são preservados na URL (`user_busca`) e nos formulários. Após selecionar, o admin global escolhe Consulta (padrão), Administrador ou Titular e confirma a liberação imediata. Usuários de Team mantêm o fluxo de convites; a inclusão direta é exclusiva da administração global.

O serviço `adminCandidates` revalida o admin global e o Team; `addExistingAdmin` revalida também a conta destinatária, rejeita vínculos já existentes e papéis fora de OWNER/ADMIN/VIEWER e registra evento `ADMIN_ADD`. A inclusão altera apenas o acesso administrativo ao Team, sem filiar atleta, modificar perfil global/credenciais ou enviar email automaticamente. Convites pendentes para o mesmo email são revogados para impedir substituição posterior do papel escolhido.

A revisão independente encontrou inversão de bloqueios entre inclusão e aceite de convite. O caso foi reproduzido em teste concorrente (inclusão 500 / aceite 200) e corrigido: Team → convite → administrador em ambas as operações, com verificação do convite após o bloqueio. O teste passou com inclusão 200 e aceite antigo 409, preservando ADMIN. O aceite normal de convites também foi validado. O teste concorrente usa cópia privada instrumentada, cria somente uma fixture nomeada em rr_teams_test e a limpa no finally; a limpeza final foi confirmada. Demais cenários usam rollback.

Verificação final: 51 checks nativos de busca/inclusão/inatividade/convites, 62 checks HTTP da gestão global, caso concorrente RED/GREEN, quatro CFML compilados, prévia desktop/celular e interface real da aba Equipe administrativa em produção. Sem concessão de acesso a usuários reais de teste, email de teste, DDL ou operação Git.

Publicação limitada a `services/teams/Service.cfc`, `administracao/teams/home.cfm`, `administracao/teams/includes/backend.cfm` e `administracao/teams/includes/existing_user.cfm`. Backup recuperável: `/var/backups/rr-teams-existing-release-hj6en7a5`. Dezenove dependências preservadas e cinco probes de produção, incluindo leitura autenticada da nova seção. Manifesto, baseline, compilação e recibo: `_codex/teams/existing/`; hashes cumulativos atualizados em `_codex/teams/publication.json`. Ferramenta: `_codex/scripts/deploy_teams_existing.py` (prepare/compile/publish), com baseline/CAS e rollback automático.


## Edição de papéis e inclusão agrupada — 26/10/2026

Na gestão global, aba Equipe administrativa, cada pessoa tem seleção de papel e **Salvar papel**, sem remover e recriar o vínculo. Papéis: Titular, Administrador e Consulta. O serviço `changeAdminRole` exige admin global ativo e CSRF na rota, trava o Team, compara o papel esperado, protege o último OWNER, revoga convites pendentes do destinatário e faz UPDATE na mesma linha. O aceite original permanece preservado. Mudanças reais geram `ADMIN_ROLE_CHANGE` com papéis anterior/novo; salvar o mesmo papel não gera alteração artificial. Edições obsoletas pedem recarregar a página, preservando o papel submetido no formulário.

As duas formas de inclusão agora ficam juntas em uma única seção **Adicionar usuário**, seguindo Empresas: **Adicionar usuário existente** e **Convidar por email**, como opções expansíveis operáveis por teclado. Busca ou erro abre a opção correspondente; email, papel, busca e filtros são preservados. O convite mantém a liberação após aceite e seus papéis atuais; a inclusão de conta existente continua imediata, apenas na gestão global. O painel dos responsáveis não foi modificado.

Validação: 27 checks nativos da edição de papéis, 76 checks HTTP da gestão global, cinco CFML compilados, revisão independente sem achados bloqueantes e prévia desktop/celular. Verificação real autenticada confirmou Salvar papel e as duas opções juntas em produção. Nenhum papel de usuário real foi alterado como teste; fixture final vazia, nenhum envio de email de teste, DDL ou operação Git.

Publicação de cinco arquivos: `services/teams/Service.cfc`, `administracao/teams/home.cfm`, `administracao/teams/includes/backend.cfm`, `administracao/teams/includes/existing_user.cfm` e novo `administracao/teams/includes/admins.cfm`. Backup recuperável: `/var/backups/rr-teams-roles-release-4zg6_gwu`. Dezenove dependências preservadas; cinco probes de produção, incluindo shell autenticado. Baseline, manifesto, compilação e recibo em `_codex/teams/roles/`; hashes cumulativos em `_codex/teams/publication.json`. Ferramenta `_codex/scripts/deploy_teams_roles.py` com prepare/compile/publish, CAS e rollback automático. Nenhum CSS ou dependência nova de runtime.

## Inclusão e edição de papéis no painel dos responsáveis — 26/10/2026

O painel `/teams/`, aba Equipe administrativa, compartilha agora a view da gestão global. Adicionar usuário reúne conta existente (acesso imediato) e convite por email (após aceite). Busca, filtros e valores de erro são preservados. Edição de papel mantém o vínculo original. CSS portátil escopado em `teams/assets/admins.css`.

Matriz: GLOBAL gerencia OWNER/ADMIN/VIEWER; OWNER adiciona e altera ADMIN/VIEWER, sem editar/remover titulares; ADMIN adiciona/convida somente VIEWER, sem editar/remover membros nem substituir/revogar convite ADMIN; VIEWER consulta. Titularidade continua global. Serviço revalida autoridade sob lock, papel esperado, hierarquia, escopo e convites superiores. Proteção ao último titular mantida. Convite para membro já vinculado é recusado e orienta editar o papel. Acesso administrativo continua independente da filiação de atleta.

Verificação: 55 checks nativos de permissões, 27 de papéis, 51 de usuários existentes, 10 de fronteira, render e compilação dos cinco CFML (seis candidatos contando CSS); 93 checks HTTP e 27 regressões público/responsáveis. Revisão independente sem bloqueios; visual Titular/Administrador/Consulta e 390px. Fixture vazia, rollback e nenhum email de teste ou concessão de acesso real.

Publicação de seis arquivos Business: Service.cfc, RequestBoundary.cfc, teams/index.cfm, teams/includes/admins.cfm, teams/assets/admins.css e administracao/teams/includes/admins.cfm. Baseline/CAS, troca atômica e backup `/var/backups/rr-teams-tenant-admins-release-9xuvpjki`; 20 dependências preservadas. Recibo `_codex/teams/tenant-admins/publication.json` e hashes cumulativos atualizados. Quatro probes HTTP e shell global autenticado passaram; CSS por HTTPS idêntico ao candidato e interface publicada conferida no navegador. Não havia membro administrativo não global ativo para validar identidade real de responsável; matriz exercida em fixture com rollback, sem criar acessos reais. Nenhum DDL ou operação Git.
