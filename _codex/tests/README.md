# Testes locais do Business

Esta suíte executa todos os arquivos `*.test.js`, `*.test.cjs` e `*.test.mjs`
nesta pasta e nas subpastas, com o runner nativo do Node 22 ou posterior.
Não executa os scripts de publicação ou os testes ColdFusion de produção.

## Preparação

```sh
npm --prefix _codex/tests ci --ignore-scripts
python3 -m venv _codex/tests/.venv
_codex/tests/.venv/bin/python3 -m pip install -r _codex/analyses/mif_2026_channels/requirements.txt
```

O verificador do relatório MIF usa `PYTHON`, quando definido; caso contrário,
usa o ambiente `.venv` acima ou `python3`. Um ambiente Python já preparado
também pode ser usado:

```sh
PYTHON=/caminho/python3 npm --prefix _codex/tests test
```

As versões de jsdom e PGlite estão fixadas no lockfile. Os testes de schema
executam PostgreSQL em memória com PGlite, sem acessar o banco de produção.
Os testes de DOM usam jsdom, sem navegador ou envio real de mensagens.

Os testes do Chat e da listagem de maratonas leem o checkout irmão
`../RoadRunners`. `RR_CHAT_RUNTIME` permite selecionar outro arquivo de Chat;
`RR_SEO_SOURCE` permite selecionar outro diretório raiz para a listagem.

## Execução completa

```sh
npm --prefix _codex/tests test
```

Para filtrar um cenário, o runner aceita as opções nativas do Node:

```sh
npm --prefix _codex/tests test -- --test-name-pattern='Plataforma'
```
