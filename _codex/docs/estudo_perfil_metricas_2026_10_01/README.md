# Perfil Road Runners e publicação web — 01/10/2026

Dez métricas reconstruídas no [caderno único 6, Brasil que Corre Provas — Estudo e publicação](https://business.roadrunners.run/estudo/?caderno=6), seção 50/P15. O notebook é a fonte de autoria com o DBA; estes arquivos registram as consultas executadas e a entrega.

Publicadas 2025 web v12 / congelamento 108 / publicação 20 às 10h07 BRT e 2026 web v9 / congelamento 109 / publicação 21 às 10h11 BRT.

O responsável confirmou que “+” significa “mais de esse percentual” e que a população inclui todas as contas cadastradas até o corte. São 46.690 contas existentes até 31/12/2025 e 56.185 até 26/09/2026. Atributos atuais das contas não recuperam o perfil histórico nem medem crescimento entre edições. Médias e Premium têm suas bases conhecidas, diferentes do total; ausência não vira zero. Peso provisório 20–300 kg exclui um valor de 740 kg sem alterar o cadastro; alternativas congeladas. Regras completas em [notes.md](notes.md).

| Fonte | Célula/revisão | Execução congelada |
| --- | --- | --- |
| Query revisada dos dois anos | 305/4 | 104, 22 linhas com duas regras de peso |
| Mesma query com fixture sintética | 306/2 | 105, 22 resultados |
| Decisões e metodologia | 307/1 | markdown |
| Saída 2025 | 249/21 | 108 |
| Saída 2026 | 251/15 | 109 |

147 das 149 células originais intactas; apenas as saídas 249/251 editadas com revisão esperada. Todas as queries anteriores do DBA preservadas. Fontes relidas antes e depois da publicação. Valores históricos, demais indicadores e comparativos não mudaram.

Contratos aditivos 2025/6 e 2026/5, com novos campos opcionais para perfil. Baselines antigas e validador genérico preservados; validação oficial dos pacotes novos e anteriores passou antes do COMMIT. Banco anterior em `/var/backups/business-estudo-web-20260928/database/perfil-coortes-20261001-validado-before.json`. Reversão de dados pelo serviço oficial, republicando 100/2025 e 101/2026 com a publicação vigente como revisão esperada; não forçar revisões ou apagar histórico.

Não houve alteração de runtime Business, guarda SQL, autenticação ou tabelas operacionais. A web lê somente pacotes publicados congelados. Interface RoadRunners gerada de `previa/`, quatro assets publicados com backup e hashes conferidos. 78 testes Node, 22 saídas sintéticas SQL, JSON público, desktop/celular e alternância do PDF verificados. O evento de download no navegador integrado expirou; conteúdo CSV foi validado nos testes, salvamento pela UI não confirmado.

Registro completo e capturas: `/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/docs/brasil_que_corre_provas/perfil_2026_10_01/README.md`. Equivalência integral ainda aberta para cobertura 84,1%, corte nacional 14+, referências históricas ausentes e qualidade das maratonas/pódio 2026.
