# Correção da classificação de inventário sem entrega

Continuação do contrato já aprovado: separar oportunidade, montagem, exposição,
inventário vazio, indisponibilidade e erro. Não é aprovação de novo layout.

## Global Constraints

- RoadRunners produz a classificação; Business consome os estados existentes.
- Apenas `no_candidate` é inventário `empty` quando a posição está habilitada.
- Posição desabilitada ou retorno `disabled`: `disabled`.
- Retorno `filtered_traffic`: `not_applicable`; não é falta de campanha.
- Falha, retorno inválido, desconhecido ou `served` que falhou na validação do
  criativo: `error`, nunca `empty`.
- Preservar `requested`, `served`, chaves, mídia responsiva, geometria e caminhos
  de anúncios válidos. Não alterar seleção, cobrança, configuração ou filtros.
- Sem SQL, autenticação, retenção, geolocalização ou `tb_log` neste lote.
- Sem branches, commits ou publicação. Preservar todas as mudanças existentes.
- Trabalhar primeiro na cópia isolada `/private/tmp/rr-audience-empty-state.nIlvuC`.

### Task 1: Corrigir os três emissores com classificação compartilhada e testes CFML

Repositório fonte: `/Users/Shared/Projects/RunnerHub/RoadRunners`.

Arquivos runtime autorizados:

1. `includes/ads_v1/banner_delivery.cfm`
2. `includes/estrutura/home_sidebar_promos.cfm`
3. `includes/eventos_ads.cfm`
4. `includes/analytics/slot_marker.cfm`

Os três caminhos sem entrega atualmente traduzem qualquer status diferente de
`error` em `empty`. Acrescentar `deliveryStatus` ao objeto destes caminhos e
centralizar a tradução opcional no marcador existente; chamadores que já fornecem
um estado sem `deliveryStatus` continuam intocados. Não duplicar a tabela/regra
nos três emissores. A classificação deve usar a habilitação representada por
`requested` sem alterar o valor desse campo: a requisição ao serviço foi tentada
mesmo quando a filtragem ocorre antes do leilão. `served` permanece falso.
Manter também `state` conservador no objeto (`disabled` se desabilitado, caso
contrário `error`) para compatibilidade com o marcador anterior na sobreposição
de publicação/reversão. Publicar o marcador antes dos três emissores.

TDD: executar fragmentos reais dos três emissores e o marcador real usando o
runtime CFML local já instalado, sem banco ou rede. Demonstrar que `fallback` e
`invalid_candidate` falham antes da correção, pois resultam em `empty`. Depois
cobrir todos os status retornados pelos três serviços, desconhecido/vazio, posição
desabilitada, `served` reprovado na validação e marcador sem `deliveryStatus`.
Verificar HTML final: estado, chave, placement, requested, served, atributo hidden
e mídia mobile preservados. Fixture não deve reimplementar o mapeamento.

Usar os padrões locais de `_codex/tests/` e `_codex/scripts/`. Não acrescentar
dependências nem exportações de produção somente para testes. Os testes e a
documentação são parte do lote, mas não entram no pacote runtime.

Criar `before/` com cópias exatas e `candidate/` com fontes modificadas; somente
editar a cópia isolada. Registrar hashes antes/depois e diff imutável para revisão.
Executar teste focado e suíte relevante uma vez após ficar verde. Revisão de
especificação/qualidade e revisão final antes de aplicar o lote local. Após aplicar,
verificação fresca e recibo distinguindo código local de produção.
