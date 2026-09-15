# Central de atendimento — publicação de 14/09/2026

## Escopo

Interface administrativa de `/helpdesk/`, restrita ao administrador global já autorizado pelo Business. A área `/suporte/` mantém a interface anterior e a consulta por usuário proprietário. Sem migração, alteração de credenciais, reinício de serviço ou publicação de outras frentes.

## Recursos

- Fila paginada (20 chamados), conversa e editor no mesmo ambiente.
- Busca literal por protocolo, assunto, nome ou e-mail; filtros combinados de status e setor.
- Visões de pendências, setores sob responsabilidade do atendente e chamados não concluídos sem atualização há mais de 48 horas.
- Ordenação por atenção necessária, atualização recente ou abertura mais antiga.
- Histórico com identificação de solicitante/equipe e iniciais; setores e responsáveis em painel recolhível.
- IA existente preservada; três respostas rápidas inseridas ao final do rascunho para revisão humana.
- Atualização de status e setor independente de mensagem ao usuário.
- Proteção de rascunho ao sair, limite de texto, prevenção de clique duplicado, POST/CSRF, transação e revisão do chamado para conflitos concorrentes.
- Arquivos internos recusam acesso direto sem contexto administrativo; mensagens internas são excluídas da consulta pública.

## Definições dos indicadores

Fonte: `tb_helpdesk_chamados`, com setores/usuários e mensagens nas consultas da fila. Os indicadores são globais e não respondem aos filtros da fila; isso é informado na tela.

| Indicador | Critério |
| --- | --- |
| A responder | `aberto` + `cliente_respondeu` |
| Em atendimento | `em_atendimento` |
| Aguardando usuário | `aguardando_cliente` |
| Concluídos | `resolvido` + `fechado` |
| Sem atualização · 48 h | Não concluído e `updated_at` anterior a agora menos 48 horas; não é SLA |

“Meus setores” usa o responsável padrão do setor, não atribuição individual por chamado. A ordenação de atenção coloca retornos do usuário antes de abertos, em atendimento, aguardando usuário e concluídos, com atualização mais antiga primeiro em cada grupo.

## Validação executada

- 21 testes Node aprovados (workspace e editor de IA).
- Renderização CFML local com dados sintéticos: filtros, parametrização/escape literal, ordenação, renderização e escape de HTML aprovados.
- Compilação Adobe ColdFusion no servidor: todos os templates candidatos aprovados.
- Produção autenticada: 86 chamados, 24 a responder, 38 em atendimento, 3 aguardando, 21 concluídos e 62 não concluídos sem atualização há 48 h. Os quatro grupos de status somam 86; o indicador de 48 h é sobreposto.
- Busca “Teste notificação” + status “Usuário respondeu”: um resultado; texto e filtros preservados ao abrir a conversa.
- Fila de pendentes: 24 resultados, duas páginas; segunda página com quatro resultados.
- Filtro combinado de setor Suporte ao atleta e status Aberto renderizado corretamente.
- Editor/IA/histórico e gestão de setores renderizados; tentativa de resposta vazia impedida no navegador.
- `/suporte/`: interface anterior, quatro chamados próprios da sessão usada para conferência.
- Nenhuma mensagem, alteração de status ou notificação de teste enviada a usuários reais. A gravação transacional foi revisada/testada estruturalmente, não exercitada com escrita em chamados reais.
- Acessos HTTP diretos a `workspace-init.cfm` e `workspace-actions.cfm`: 403.
- Conferência visual desktop aprovada e sem erros de console. CSS possui breakpoints responsivos; tentativa de override para 390 px não foi aplicada pelo navegador de validação, portanto a inspeção visual mobile permanece não confirmada.

## Publicação e recuperação

Publicados apenas dez arquivos: `helpdesk/index.cfm`, `home.cfm`, `includes/backend.cfm`, cinco novos includes (serviço e workspace), `assets/workspace.css` e `assets/workspace.js`.

Baseline de produção conferido por SHA-256; candidatos conferidos contra arquivos locais. Backup original recuperável: `/var/backups/business-helpdesk-workspace.PC9h1k/baseline`. Refinamento dos guards possui cópia intermediária em `before-hardening`. Manifesto de hashes no mesmo diretório.

Procedimento da tarefa: `_codex/scripts/deploy_helpdesk_workspace_20260914.py`; modo `rollback` verifica conflitos e restaura os três arquivos originais, mantendo dependências novas sem uso para recuperação. O procedimento é específico desta publicação, não um deploy genérico.
