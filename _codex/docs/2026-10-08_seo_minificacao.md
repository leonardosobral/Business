# SEO — recursos compartilhados do Road Runners, 08/10/2026

Publicado o lote RR-33 no Road Runners e registrado no painel Business.

A consulta ao Chrome autenticado confirmou que a última auditoria Semrush continua
sendo a de 06/10/2026: 5.000 páginas, Site Health 75%, pesquisa IA 78%, 27 erros e
45.495 advertências. O relatório de minificação tem 11.995 ocorrências, não esse
número de arquivos distintos. A busca pelo domínio principal mostrou 11.959
ocorrências; foram inspecionadas amostras da primeira página e da página 60.

As amostras apontaram o menu de aplicativos em home e eventos, scripts de busca
e filtros, CSS institucional e CSS/JS de localização dos eventos. O lote inclui
também os recursos correspondentes dos percursos e seu embed, usando o mesmo
gerador e mantendo as fontes legíveis.

## Road Runners

- Gerador `_codex/scripts/minify_seo_assets.mjs` ampliado de cinco para treze fontes.
  esbuild 0.28.2; minifyWhitespace, sem minifyIdentifiers/minifySyntax; JS es2017.
- Oito arquivos novos `.min.js`/`.min.css`, no mesmo diretório de suas fontes.
- Onze templates trocam apenas caminho e versão de cache; atributos de scripts,
  ordem e condições de carregamento preservados.
- Soma desses oito recursos: 192.028 para 126.605 bytes, redução de 65.423 bytes
  (34,1%) antes da compressão HTTP. Cada página carrega apenas seu subconjunto.
- Nenhum cadastro de evento, API, autenticação, acesso privado ou WAF alterado.

## Validação e publicação

- Baseline local/produção conferido em 11 templates e 13 fontes de assets.
- Oito verificações de representação normalizada e roundtrip do compilador.
- Onze templates compilados pelo Adobe ColdFusion.
- Quinze rotas públicas antes/depois, com 31 referências de recursos. Quatorze
  respostas 200 e o redirecionamento 302 de atendimento para login preservados.
- Títulos, H1, descrição, canonical, hreflang e JSON-LD preservados.
- Oito recursos publicados em HTTP 200 com MIME e hashes esperados.
- Menu confirmou carregamento pelo endpoint (`runnerAppsLoaded=true`); filtro
  de cupom atualizou URL, três eventos e contagens/links de cidades; busca comum
  por Night Run Vitória retornou quatro eventos.
- Ajuda conferida visualmente em 1280 e 390 pixels; largura do documento igual
  à viewport, sem overflow horizontal. Override de viewport restaurado.
- Road Runners: 19 arquivos publicados, 23 dependências preservadas, backup
  `/var/backups/seo-assets-20261008/baseline`.
- Business: dois templates compilados e publicados; 19 cenários de renderização
  e acesso, incluindo oito controles de acesso, antes e depois da publicação.
  Dez dependências preservadas; backup
  `/var/backups/seo-assets-panel-20261008/baseline`.

Scripts e recibos: `_codex/staging/seo-assets-20261008/`. O script de release
confere baseline, hashes do candidato/validações, compilação e dependências;
rollback recusa conteúdo modificado por outra frente.

## Próxima medição

O painel conserva as notas, totais e datas da auditoria de 06/10 e a coleta
orgânica de 04/10. Nenhuma queda foi calculada manualmente. Uma nova rodada de
5.000 páginas deve medir o efeito sobre minificação e o lote RR-32. Títulos e
descrições da loja, links de proteção de e-mail e o perfil protegido continuam
separados; não ocultar problemas nem remover proteção para melhorar a nota.

Minificação trata advertências técnicas. Indexação e ranking precisam de
medições próprias no Search Console.

Revisão posterior de 08/10: a classificação do 403 como perfil protegido foi
corrigida. O erro era de codificação no Apache; a correção RR-34 conserva a
exigência de login. Ver [evidências e validações](2026-10-08_seo_rota_atleta.md).
