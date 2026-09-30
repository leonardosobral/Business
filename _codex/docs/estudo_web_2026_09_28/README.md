# Evidências e queries de publicação web

- `seed.sql`: carga inicial realmente aplicada; contém a primeira revisão da query 2025.
- `2025.sql`: revisão 2, executada e congelada em #32. A correção de alias está em `repair-cell.json`.
- `2026.sql`: revisão 1, executada e congelada em #33.
- `catalog-published.json`: destinos e publicações v1 ativas.
- `verification.json`: JSON público idêntico às projeções, integridade e acesso.
- `release-*`: publicação principal; `cache-release-*`: versão do JS Business; `label-release-*`: rótulo de resultados 2025.
- Backups recuperáveis: `/var/backups/business-estudo-web-20260928/` no servidor.

Fixtures agregadas e contratos estão em `../../tests/estudo_web_publication/`. Não há dados individuais de atletas.
