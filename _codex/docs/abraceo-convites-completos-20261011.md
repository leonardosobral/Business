# ABRACEO: conclusão dos contatos e convites

Em 11/10/2026, o usuário autorizou buscar o contato confirmado da Pace Eventos e revisar Morro MT para emitir os dois vouchers faltantes.

## Fontes e decisão

- Pace Eventos (#89): o site oficial https://paceeventos.com.br/ publica `contato@paceeventos.com.br`, identifica @paceeventos e provas de Vitória/ES. O regulamento da Maratona de Vitória 2027 identifica PACE Eventos Ltda como organizadora e também publica `maratona@paceeventos.com.br`. Foi escolhido o endereço geral de contato da empresa para o convite. Não foi utilizado o cadastro da empresa homônima de Natal/RN.
- Morro MT (#45): https://morro-mt.com.br/contato publica `morro@morro-mt.com.br`. O perfil da ABRACEO mantém `__morro@morro-mt.com.br`; a decisão foi baseada no endereço literalmente publicado no site oficial, e não em normalização presumida.

Fontes baixadas, hashes e evidências em `outputs/abraceo-convites-completos-20261011/support/`. A confirmação é de contato publicado; não houve envio ou teste de entrega.

## Atualização aplicada

E-mail principal e `dados.email_publico` corrigidos nas duas contas. O campo `dados.revisao_contato_convite` registra e-mail anterior, novo contato, fonte, data, evidência e ausência de teste de entrega. Nenhum CNPJ, status operacional, usuário, vínculo de evento ou logo foi alterado. Pace segue com documento pendente; seu primeiro acesso por voucher foi habilitado. A elegibilidade total passou de 87 para 88 contas.

Dois vouchers nominais emitidos pela API interna existente, um por conta e destinatário, com resgate até 10/11/2026 às 23h59 de Brasília. O banco mantém apenas o hash do código. Verificações confirmaram status READY, vínculo correto, destinatário, hash, produto de prévia, benefício comercial zero e prazo. Os 86 vouchers anteriores foram preservados integralmente, assim como acessos, declarações e permissões operacionais. Nenhum convite foi enviado.

Planilha final: `outputs/abraceo-convites-completos-20261011/vouchers_abraceo.xlsx`, com 88 códigos. As 86 linhas anteriores e seus estados de envio foram preservados. A aba Pendências registra as duas resoluções com as fontes. Oito empresas ainda sem pré-cadastro confirmado, de um inventário de 96 filiados, continuam fora deste lote.

## Operação e recuperação

Nenhum arquivo de runtime precisou ser alterado ou republicado; foi reutilizado o fluxo publicado de voucher por ID da conta.

Backups recuperáveis:
- `/var/backups/business-abraceo-contatos-finais-20261011`: duas contas e perfis anteriores, baseline de integridade, fontes selecionadas e registro da atualização.
- `/var/backups/business-abraceo-vouchers-finais-20261011`: baseline dos 86 vouchers, seleção dos dois destinatários, códigos privados e relatório de conferência.

Os operadores locais `support/contact_update.py` e `support/issue_vouchers.py` bloqueiam reaplicação ou reemissão quando há registro de execução. Em recuperação, inspecionar o estado e os backups, preservar uso posterior e não reemitir códigos automaticamente. Revogação deve usar a gestão existente, sem exclusão de histórico. Arquivo final e relatórios com códigos têm permissão 0600.
