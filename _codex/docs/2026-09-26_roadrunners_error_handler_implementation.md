# Tratamento de erros do RoadRunners — 26/09/2026

## Comportamento

O OnError do portal e do microsite responde 500 na mesma requisição, com página genérica responsiva ou JSON para consumidores JSON. Não há redirecionamento para 404 nem exposição de dumps por `?debug`. Rotas inexistentes retornam 404. A apresentação usa HTML/CSS independente, em português, inglês e espanhol; o diretório 404 tem Application.cfc mínimo e não carrega bootstrap, sessão, login ou layout comuns. O Apache possui fallback estático para 500/503.

O handler registra `erro` na tb_log antes de tentar notificar. Inclui HTTP_STATUS, REQUEST_ID, ambiente, assinatura e decisão do limitador em HTML compatível com o coletor do Business. Dados brutos de formulário, URL e exceção não são despejados. O detalhe técnico entra como hash normalizado: valores SQL variáveis são agrupados e identificadores estruturais distinguem falhas. Falha no banco tenta log local; falha no logger ou SMTP não impede a resposta. Guarda por requisição evita reentrada.

A primeira ocorrência elegível reserva um alerta; repetições da mesma assinatura ficam silenciosas por 15 minutos. O teto global é de 15 alertas por hora móvel (até 30 submissões a destinatários, considerando To e CC existentes). Tentativas malsucedidas consomem a reserva. A próxima ocorrência permitida informa o acumulado desde o alerta anterior. Não há resumo periódico nem garantia de entrega: cfmail enfileira, e entrega/quotas dependem do Mandrill. E-mails transacionais não foram alterados.

O limitador vive em SERVER sob lock, limitado a 1.000 assinaturas; resiste à reinicialização da aplicação, mas reiniciar o JVM zera as reservas. Não é um limitador distribuído entre servidores. Dev e hosts desconhecidos não notificam. O microsite mantém o envio desativado, como antes. Falhas de infraestrutura anteriores ao ColdFusion dependem do fallback do servidor. Se o banco falhar, os registros no arquivo local não são importados automaticamente pelo Business.

## Business e histórico

O Business continua consumindo tb_log pela coleta manual já publicada. As novas falhas internas não geram um segundo 404 artificial. Logs históricos foram preservados; o destino /404/ sozinho não prova que um registro antigo era falso. A classificação de entrada inválida ou tentativa maliciosa segue sujeita à triagem: o erro HTTP, por si só, não prova ataque. Acompanhamento e histórico de tratamento permanecem no painel em abas.

## Validação

- 18 verificações CFML do agrupamento, privacidade e limitador, incluindo regressão demonstrada antes/depois para colunas SQL distintas.
- 21 verificações HTTP no Adobe ColdFusion, herdando handlers reais em aplicação temporária isolada e protegida por loopback/token. Banco sintético e SMTP substituído; limpeza ao final.
- Rajada de 12 requisições: 12 logs e apenas uma notificação reservada. Falhas de bootstrap, banco, SMTP, logger e reentrada verificadas. 404 independente, tradução, JSON 500 e microsite verificados.
- 4 testes do publicador seletivo. Interface 500 em desktop/celular e 404 em celular conferida visualmente.
- Recibos de compilação e publicação em Business/_codex/staging/error-handler/release-*.json.

## Operação e rollback

Publicação seletiva de 15 arquivos de runtime. Backup privado confirmado: `/var/backups/roadrunners-error-handler-20260926-v2/baseline`, com manifesto de hashes no diretório pai. O script Business/_codex/scripts/deploy_rr_error_handler.py verifica conflitos antes de publicar, instala dependências antes dos pontos de entrada e preserva modificações concorrentes no rollback. `python3 _codex/scripts/deploy_rr_error_handler.py rollback` restaura os quatro arquivos originais e remove somente os novos arquivos correspondentes ao manifesto, recusando sobrescrever mudanças posteriores. Sem migração de banco nesta etapa; sem alteração da API pública isolada.

## Publicação confirmada

Os 15 arquivos foram publicados em 26/09/2026 e seus hashes conferidos no runtime. Compilação Adobe: 8/8 templates, exit 0. Verificação HTTP pública: home 200; /404/, /en/404/, /es/404/ e arquivo .txt inexistente retornaram 404 com o conteúdo esperado, sem redirecionamento para outra URL; /errors/500.html serviu a página estática. A resposta 500 foi comprovada nos 21 testes isolados dos handlers reais, sem provocar falha interna ou enviar e-mail real em produção.
