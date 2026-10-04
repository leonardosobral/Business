# Revisão final SEO — Astra

Revisar somente o lote atual, sem editar ou publicar. Usuário autorizou continuar o plano e pede Astra. Business exige publicação scoped após baseline/backup e verificação; sem Git, credenciais, WAF, Apache, cron ou traduções pagas.

Plano/ledger: _codex/docs/2026-10-03_seo_evidencias_plano.md. Candidato runtime: três arquivos em candidate/, comparar baseline/ mesmos paths. As mudanças de runtime são dois snapshots e apenas o parágrafo introdutório de seo_ai.cfm.

Código desta etapa: _codex/scripts/seo_live_evidence.py (novo), seo_ai_evidence.mjs (novo); seo_scorecard.mjs alterações desta etapa = import withAiEvidence, generate optional aiEvidenceFile/default reportsRoot/evidence/latest.json, aplicação dos checks e argumento CLI. O restante inclui trabalho anterior, não reabrir sem impacto atual.

Tests: seo_live_evidence.test.py8; seo_ai_evidence.test.mjs11; seo_scorecard.test.mjs novo teste de persistência; suíteNode65 e CFML9 passam. Coletores stage collect_state.py/collect_logs.py/diagnose_cron.py/assemble_evidence.py, build_queue.py/release.py/verify_panel.py.

Evidências redigidas: evidence.json, descriptions.json, state.json, logs.json, ranges.json, cron-diagnosis.json, privacy-verification.json; snapshot.json. Esses arquivos não contêm nomes de participantes, IPs, caminho de requisição, prompt ou credenciais. logs.json é compartilhado e NÃO atribuível por domínio.

Focos de revisão: não dar pass em tradução pela interface/ausência de fonte/hash igual/PTfallback; fronteiras da extração HTML/lang, falsos casos de script/hidden; status/counts/datas/URLs robustos e nenhum dado pessoal público; refs=page_views/session distinct prod sem internos allowlistexata, sem herdar dados OR ou afirmar citações/conversões; logs sem hostname devem continuar unknown; não presumir saldo atual por erro histórico; não desfazer cron pausado/rejeitados; OR-02 só concluído na entrega com robots+noindex comprovados, sem afirmar desindexação efetiva; pesos/histórico iguais e futuras auditorias conservam data da medição; baseline/backup/publicação só3 e dependências5 preservadas.

Retornar somente findings Critical/Important/Minor com paths/linhas e consequência, ou revisão limpa com limites. Não criar nova revisão, não executar operações pagas, não modificar código. Artefato runtime candidato ainda não foi publicado; verificar entrega real é a etapa seguinte do executor.
