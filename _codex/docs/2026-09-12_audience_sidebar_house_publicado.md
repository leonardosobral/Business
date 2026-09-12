# Piloto institucional lateral — recibo de publicação

Publicado em **12/09/2026 às 11:48:22 BRT**. Verificação final às **11:50:40 BRT**.

## Lote

Somente dois arquivos no RoadRunners, nesta ordem:

1. `includes/ads_v1/sidebar_house_pilot.cfm` (novo).
2. `includes/ads_v1/banner_delivery.cfm`.

Pacote: `_codex/releases/2026-09-12_audience_sidebar_house_linux.tar.gz`.
SHA-256: `21e1ef89f8b4c08942b4b12a21329baa3ccc717d09969984580649daa7e66866`.
Hashes por arquivo e limites no [manifesto](2026-09-12_audience_sidebar_house_manifest.json).

Backup privado: `/var/backups/rr-sidebar-house.OYC1Vr`. Contém o original, registro
da ausência do include novo, metadados, pacote, candidatos e hashes de 39 arquivos
protegidos. Os dois hashes publicados e os 39 arquivos protegidos foram conferidos
antes e depois do teste em navegador. Proprietário/grupo/mode preservados
(`root:root`, 0644). Apache e ColdFusion continuaram ativos, sem restart.

Sem SQL, alterações de DSN/permissões, login, Ads config, cobrança, retenção ou
`tb_log`. Nenhum runtime do Business foi publicado. As demais alterações locais
de Ads não foram incluídas.

## Validação

- Pré-publicação independente: 25/25 cenários CFML, 17/17 com coletor real,
  87/87 regressões de audiência; `git diff --check` sem erros.
- Chrome autenticado: home `prod`, `pageFamily=home`, `isInternal=true`.
  Banner Avaí Run e três posições nativas carregadas. Banner lateral 318×318,
  preservando a proporção da campanha existente.
- Navegação normal pelo link 5K até a busca: banner lateral com campanha
  elegível, sem peça institucional simultânea. Sem erros de console.
- Busca em viewport 390×844: lateral desktop com área zero, banner mobile
  366×178,9375 com imagem carregada e sem overflow horizontal. Viewport restaurado.
- Não houve clique em anúncio, mudança de campanha/configuração, logout ou
  injeção de eventos. A coleta ocorreu pela navegação normal do teste.

### Business

Recorte em uma aba temporária própria: 7 dias, Home, Desktop, produção, contexto
comercial, todas as UFs, incluindo acessos internos. A aba original e seus filtros
não foram alterados.

Posição `rr-sidebar-banner-desktop`:

| Métrica | Antes | Depois |
| --- | ---: | ---: |
| Registradas | 204 | 205 |
| Institucionais | 179 | 180 |
| Pedidos | 179 | 180 |
| Entregas Ads | 179 | 180 |
| Montadas | 177 | 178 |
| Visíveis | 79 | 80 |

Última recepção passou de 11:32 para 11:50 BRT. Esses agregados confirmam
continuidade da coleta após a publicação, compatível com o teste interno; **não
são uma contagem da peça institucional nova**, pois o banner visto era a campanha
Avaí Run. Não extrapolar para potencial comercial nem inferir exclusividade por
usuário a partir desse incremento.

### Limite do smoke test

Havia campanha elegível nas páginas visitadas. O novo ramo `no_candidate` não foi
observado em produção e não foi forçado por desativação de campanhas, parâmetros
especiais ou alterações de configuração. A peça institucional foi renderizada e
validada em CFML/Chrome locais no passo anterior. A implantação está confirmada
por hashes; a observação natural desse ramo em Adobe ColdFusion continua sendo
uma verificação de campo possível quando surgir ausência de campanha.

O identificador `sidebar-marathons-300x250-v1` é somente DOM, não um filtro ou
grupo persistido. Valem as limitações de comparação antes/depois e de tamanho de
criativo descritas na [documentação do piloto](2026-09-12_audience_sidebar_house_pilot.md).

## Recuperação

Restaurar somente `before/includes/ads_v1/banner_delivery.cfm` do backup. O include
institucional novo pode permanecer inerte. Não executar rollback de outros lotes
nem alterar o banco. O backup do original corresponde ao hash
`60bc90d500652d3fe2f2604d135c500922c98911324d8f0293deb21e69667777`.
