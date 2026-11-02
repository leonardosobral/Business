# Prioridade das imagens de destaque da home — 30/10/2026

Publicado em **30/10 às 16:38:27 (Brasília)**, somente `index.cfm`. Primeiro destaque com `loading="eager" fetchpriority="high"`; demais com `loading="lazy" fetchpriority="low" decoding="async"`. Um único elemento de imagem do loop foi alterado; consulta de até 12 eventos, URLs, resolução, textos, carrossel, filtros e estilos preservados. Se o primeiro registro não tiver imagem, não se dá prioridade alta a uma imagem fora da primeira posição.

O diagnóstico anterior do PageSpeed apontava o destaque de Aracaju como LCP e ausência de prioridade alta. A alteração implementa essa recomendação, sem remover imagens do HTML nem mudar o destino dos links. Referência: [Fetch Priority, Google](https://web.dev/articles/fetch-priority).

## Validação

Um template compilado e seis cenários Adobe ColdFusion: homes PT/EN/ES, múltiplas imagens, primeiro registro sem imagem e lista vazia. As três páginas públicas responderam 200, com canonical próprio, 12 imagens, uma prioritária e 11 adiadas. Chrome desktop/celular de 390 px: avanço e retorno do carrossel, proporções mantidas e página sem overflow horizontal. Um hash publicado e seis dependências compartilhadas preservadas. Backup recuperável `/var/backups/seo-home-images-20261030/baseline` com manifest e guarda contra alterações concorrentes. Fonte local sincronizada após comparação do hash anterior. Sem alterações de banco, credenciais, permissões, Git ou configuração Cloudflare.

## Resultado e limites

Comparação pontual móvel/4G lento/Moto G Power/Lighthouse 13.6.0:

| Métrica | Antes, 16:14 | Depois, 16:39 |
| --- | --- | --- |
| Desempenho | 60 | 56 |
| LCP | 8,9 s | 10,8 s |
| TBT | 320 ms | 450 ms |
| Payload | 8.330 KiB | 6.324 KiB |
| CLS | 0,073 | 0,073 |

**O LCP não melhorou nessa observação; não declarar a home otimizada por completo nem atribuir ganho de campo/SEO à mudança.** O peso carregado foi menor e o achado de prioridade foi atendido, mas imagens ainda são excessivas em tamanho/formato. Medições isoladas variam e não provam que a marcação causou a diferença de LCP. O próximo trabalho deve reduzir o peso efetivo dos arquivos, com variantes responsivas e formatos modernos, preservando qualidade e fallback; não basta repetir dicas de prioridade.

O PSI mostrou 413,1 KiB no PNG de Aracaju, 726,9 KiB no de Curitiba e 824,4 KiB no JPG de 3840 px da Pampulha. Confirmar as representações já existentes antes de introduzir qualquer serviço novo. Não criar proxy aberto de imagens, buscar URLs arbitrárias do usuário ou mudar imagens/dados das provas no banco para silenciar auditorias.

[Antes](https://pagespeed.web.dev/analysis/https-roadrunners-run/kjlhssb5d7?form_factor=mobile) · [Depois](https://pagespeed.web.dev/analysis/https-roadrunners-run/15mutoos0l?form_factor=mobile). Evidências no Business: `_codex/staging/seo-home-images-20261030/`, incluindo fontes, testes, recibos e screenshots.

A auditoria Semrush 26661911 continua na mesma execução de 5.000 páginas, móvel/JS desativado, sem reinício. A última nota concluída é 73%; Lighthouse não é Site Health. Nada para executar no DataGrip.
