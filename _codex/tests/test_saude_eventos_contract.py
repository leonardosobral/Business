from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[2]


class SaudeEventosBusinessContract(unittest.TestCase):
    def test_menu_exposes_health_operation_inside_event_management(self):
        menu = (ROOT / "includes/estrutura/sidenav.cfm").read_text(encoding="utf-8")
        self.assertIn('href="/saude-eventos/"', menu)
        self.assertIn("Operação de saúde", menu)
        self.assertGreaterEqual(menu.count('href="/saude-eventos/"'), 3)

    def test_management_write_is_csrf_and_account_scoped(self):
        backend = (ROOT / "saude-eventos/includes/backend.cfm").read_text(encoding="utf-8")
        self.assertIn("saudeEventosCsrf", backend)
        self.assertIn("saudeConfigWriteIds", backend)
        self.assertIn("qEventosContaOperacao", backend)
        self.assertIn("ON CONFLICT (id_evento) DO UPDATE", backend)
        self.assertIn('cfsqltype="cf_sql_bit"', backend)
        self.assertNotIn('cfsqltype="cf_sql_boolean"', backend)
        self.assertIn("diretor_medico", backend)
        self.assertIn("id_diretor_medico", backend)
        self.assertIn("qSaudeConfigMedicalDirectorCheck", backend)
        self.assertIn("cu.papel = 'MEDICO'::papel_usuario_conta", backend)
        self.assertIn("cu.status = 'ATIVO'::status_usuario_conta", backend)
        self.assertIn("whatsapp_equipe", backend)
        self.assertIn("saudeConfigWhatsapp", backend)

    def test_medical_director_is_selected_from_active_event_account_doctors(self):
        backend = (ROOT / "saude-eventos/includes/backend.cfm").read_text(encoding="utf-8")
        page = (ROOT / "saude-eventos/home.cfm").read_text(encoding="utf-8")
        migration = (ROOT / "_codex/sql/2026-09-22_evento_saude_diretor_medico.sql").read_text(encoding="utf-8")
        self.assertIn('name="id_diretor_medico"', page)
        self.assertNotIn('name="diretor_medico"', page)
        self.assertIn("qSaudeConfigDoctors", page)
        self.assertIn("tb_conta_eventos ce", backend)
        self.assertIn("ce.status = 'ATIVO'::status_conta_evento", backend)
        self.assertIn("Selecione um médico ativo da conta responsável pelo evento", backend)
        self.assertIn("Selecione um diretor médico válido", backend)
        self.assertIn("ADD COLUMN IF NOT EXISTS id_diretor_medico integer", migration)
        self.assertIn("ON UPDATE CASCADE ON DELETE SET NULL", migration)
        self.assertIn("diretor_candidatos", migration)

    def test_management_offers_whatsapp_invitation_for_an_active_health_central(self):
        page = (ROOT / "saude-eventos/home.cfm").read_text(encoding="utf-8")
        self.assertIn("https://business.roadrunners.run/saude-eventos/central/?id_evento=", page)
        self.assertIn('"https://wa.me/?text=" & urlEncodedFormat', page)
        self.assertIn("Convidar médico", page)
        self.assertIn("Se ainda não tiver permissão como Médico", page)
        self.assertIn(
            "qSaudeConfigSelected.ativo_painel AND VARIABLES.saudeConfigCanEditSelected",
            page,
        )

    def test_central_uses_business_identity_and_linked_event_scope(self):
        auth = (ROOT / "saude-eventos/central/includes/auth.cfm").read_text(encoding="utf-8")
        panel = (ROOT / "saude-eventos/central/index.cfm").read_text(encoding="utf-8")
        management = (ROOT / "saude-eventos/home.cfm").read_text(encoding="utf-8")
        self.assertIn('/includes/backend/backend_login.cfm', auth)
        self.assertIn("businessEffectiveIsAdmin", auth)
        self.assertIn("qEventosConta", auth)
        self.assertIn("saudeViewEventIds", auth)
        self.assertIn("saudeBusinessCsrfToken", auth)
        self.assertIn("VARIABLES.saudeViewEventIds", panel)
        self.assertIn("/saude-eventos/central/fetch/status.cfm", panel)
        self.assertNotIn("runnerhub.run/saude", management)

    def test_logged_out_central_preserves_destination_and_offers_medical_access_request(self):
        auth = (ROOT / "saude-eventos/central/includes/auth.cfm").read_text(encoding="utf-8")
        request_page = (ROOT / "saude-eventos/central/access-request.cfm").read_text(encoding="utf-8")
        callback = (ROOT / "includes/backend/business_google_callback.cfm").read_text(encoding="utf-8")
        login = (ROOT / "includes/backend/backend_login.cfm").read_text(encoding="utf-8")
        selector = (ROOT / "selecionar-conta/index.cfm").read_text(encoding="utf-8")
        modal = (ROOT / "includes/estrutura/account_context_modal.cfm").read_text(encoding="utf-8")
        self.assertIn("saudeReturnUrl", auth)
        self.assertIn("/?login=1&redirect=", auth)
        self.assertIn("qSaudeAlternateEventAccess", auth)
        self.assertIn("businessActiveAccountId", auth)
        self.assertIn("/saude-eventos/central/access-request.cfm", auth)
        self.assertIn("saudeAccessRequestAllowed", auth)
        self.assertIn("saudeAccessRequestAllowed", request_page)
        self.assertIn('CGI.request_method EQ "POST"', request_page)
        self.assertIn("saude_access_csrf", request_page)
        self.assertIn("papel_solicitado", request_page)
        self.assertIn("'MEDICO'::papel_usuario_conta", request_page)
        self.assertIn("tb_evento_saude_acesso_solicitacoes", request_page)
        self.assertIn("cu.papel = 'OWNER'::papel_usuario_conta", request_page)
        self.assertIn("coalesce(usr.is_admin, false) = true", request_page)
        self.assertIn('len("/saude-eventos/central/")', callback)
        self.assertIn('"?redirect=" & urlEncodedFormat', login)
        self.assertIn('compareNoCase(VARIABLES.template, "/saude-eventos/central/") NEQ 0', login)
        self.assertIn("businessAccountModalForcedRedirect", selector)
        self.assertIn("businessAccountModalForcedRedirect", modal)

    def test_medical_access_approval_is_owner_or_global_scoped_and_assigns_medical_role(self):
        backend = (ROOT / "administracao/contas/includes/backend.cfm").read_text(encoding="utf-8")
        page = (ROOT / "administracao/contas/home.cfm").read_text(encoding="utf-8")
        dashboard = (ROOT / "includes/estrutura/home_admin_dashboard.cfm").read_text(encoding="utf-8")
        migration = (ROOT / "_codex/sql/2026-09-22_evento_saude_acesso_solicitacoes.sql").read_text(encoding="utf-8")
        self.assertIn("medical_access_action", backend)
        self.assertIn("qBusinessMedicalAccessOwnerAuthorization", backend)
        self.assertIn("Apenas o Dono desta conta ou um Admin Global", backend)
        self.assertIn("ON CONFLICT (id_conta, id_usuario)", backend)
        self.assertIn("papel = 'MEDICO'::papel_usuario_conta", backend)
        self.assertIn("business_account_access_csrf", backend)
        self.assertIn('id="solicitacoes-saude"', page)
        self.assertIn("Aprovar como Médico", page)
        self.assertIn("businessAdminHomeMedicalAccessPendingTotal", dashboard)
        self.assertIn("Acesso médico", dashboard)
        self.assertIn("uq_evento_saude_acesso_pendente", migration)
        self.assertIn("WHERE status = 'PENDENTE'", migration)

    def test_every_central_endpoint_enforces_the_shared_business_authorization(self):
        for endpoint in ("startlist", "leaderboard", "athlete", "stats", "status", "bib", "note", "contact", "triage-clear"):
            source = (ROOT / f"saude-eventos/central/fetch/{endpoint}.cfm").read_text(encoding="utf-8")
            self.assertIn('/saude-eventos/central/includes/auth.cfm', source, endpoint)
        status = (ROOT / "saude-eventos/central/fetch/status.cfm").read_text(encoding="utf-8")
        self.assertIn("SESSION.saudeBusinessCsrfToken", status)
        self.assertIn("qPerfil.id", status)

    def test_central_resolves_blank_registration_names_without_blank_cards(self):
        for endpoint in ("startlist", "leaderboard", "athlete"):
            source = (ROOT / f"saude-eventos/central/fetch/{endpoint}.cfm").read_text(
                encoding="utf-8"
            )
            self.assertIn("nullif(trim(ins.nome), '')", source, endpoint)
            self.assertIn("Atleta · BIB", source, endpoint)
        startlist = (ROOT / "saude-eventos/central/fetch/startlist.cfm").read_text(
            encoding="utf-8"
        )
        self.assertIn("usr.name", startlist)
        self.assertIn("nome_exibicao", startlist)

    def test_status_update_normalizes_audit_fields_and_logs_the_failure_stage(self):
        status = (ROOT / "saude-eventos/central/fetch/status.cfm").read_text(
            encoding="utf-8"
        )
        self.assertIn("saudeStatusActorId", status)
        self.assertIn("saudeStatusIp", status)
        self.assertIn('file="business-saude-eventos"', status)
        self.assertIn('result="qSaudeStatusUpdateMeta"', status)

    def test_status_client_accepts_coldfusion_uppercase_json_keys(self):
        panel = (ROOT / "saude-eventos/central/index.cfm").read_text(encoding="utf-8")
        self.assertIn("key.toUpperCase()", panel)
        self.assertIn("responseValue(result, 'success')", panel)
        self.assertIn("responseValue(result, 'message')", panel)

    def test_bib_unlink_requires_confirmation_preserves_registration_and_audits(self):
        panel = (ROOT / "saude-eventos/central/index.cfm").read_text(encoding="utf-8")
        athlete = (ROOT / "saude-eventos/central/fetch/athlete.cfm").read_text(encoding="utf-8")
        endpoint = (ROOT / "saude-eventos/central/fetch/bib.cfm").read_text(encoding="utf-8")
        self.assertIn("prepararDesvinculoBib", panel)
        self.assertIn("bibUnlinkConfirmation", athlete)
        self.assertIn("Confirmar desvínculo", athlete)
        self.assertIn("SESSION.saudeBusinessCsrfToken", endpoint)
        self.assertIn("SET num_peito = NULL", endpoint)
        self.assertNotIn("DELETE FROM tb_inscricoes", endpoint)
        self.assertIn("bib_desvinculado", endpoint)
        self.assertIn("tb_evento_saude_historico", endpoint)

    def test_medical_permissions_are_enforced_in_ui_and_endpoints(self):
        auth = (ROOT / "saude-eventos/central/includes/auth.cfm").read_text(encoding="utf-8")
        athlete = (ROOT / "saude-eventos/central/fetch/athlete.cfm").read_text(encoding="utf-8")
        status = (ROOT / "saude-eventos/central/fetch/status.cfm").read_text(encoding="utf-8")
        bib = (ROOT / "saude-eventos/central/fetch/bib.cfm").read_text(encoding="utf-8")
        self.assertIn("saudeIsMedical", auth)
        self.assertIn("saudeCanOperate", auth)
        self.assertIn("saudeCanViewMedicalData", auth)
        self.assertIn("saudeCanUnlinkBib", auth)
        self.assertIn("Somente usuários com perfil Médico", athlete)
        self.assertIn("VARIABLES.saudeCanViewMedicalData", athlete)
        self.assertIn("VARIABLES.saudeCanUnlinkBib", athlete)
        self.assertIn("VARIABLES.saudeCanOperate", athlete)
        self.assertIn("NOT VARIABLES.saudeCanOperate", status)
        self.assertIn("NOT VARIABLES.saudeCanUnlinkBib", bib)

    def test_triage_can_be_cleared_in_bulk_only_by_health_operators(self):
        panel = (ROOT / "saude-eventos/central/index.cfm").read_text(encoding="utf-8")
        endpoint = (ROOT / "saude-eventos/central/fetch/triage-clear.cfm").read_text(encoding="utf-8")
        self.assertIn("prepararLimpezaTriagem", panel)
        self.assertIn("triageClearConfirmation", panel)
        self.assertIn("VARIABLES.saudeCanOperate", panel)
        self.assertIn("NOT VARIABLES.saudeCanOperate", endpoint)
        self.assertIn("ins.observacoes IN ('scan', 'acionado')", endpoint)
        self.assertIn("SET observacoes = NULL", endpoint)
        self.assertIn("data_scan = NULL", endpoint)
        self.assertIn("'triagem_limpa'", endpoint)
        self.assertIn("tb_evento_saude_historico", endpoint)

    def test_medical_profiles_without_bib_are_listed_in_the_health_operation(self):
        startlist = (ROOT / "saude-eventos/central/fetch/startlist.cfm").read_text(encoding="utf-8")
        stats = (ROOT / "saude-eventos/central/fetch/stats.cfm").read_text(encoding="utf-8")
        for source in (startlist, stats):
            self.assertIn("ins.num_peito IS NOT NULL", source)
            self.assertIn("usr.ficha_medica IS NOT NULL", source)
        self.assertIn("Sem BIB", startlist)

    def test_health_operation_uses_registration_id_when_bib_is_pending(self):
        panel = (ROOT / "saude-eventos/central/index.cfm").read_text(encoding="utf-8")
        athlete = (ROOT / "saude-eventos/central/fetch/athlete.cfm").read_text(encoding="utf-8")
        startlist = (ROOT / "saude-eventos/central/fetch/startlist.cfm").read_text(encoding="utf-8")
        migration = (ROOT / "_codex/sql/2026-09-22_evento_saude_atleta_sem_bib.sql").read_text(encoding="utf-8")
        self.assertIn("id_inscricao", panel)
        self.assertIn("URL.id_inscricao", athlete)
        self.assertIn("ins.num_pedido", startlist)
        self.assertIn("carregarAtleta(#qFMStartList.num_pedido#)", startlist)
        for endpoint in ("status", "note", "contact", "bib"):
            source = (ROOT / f"saude-eventos/central/fetch/{endpoint}.cfm").read_text(encoding="utf-8")
            self.assertIn("FORM.id_inscricao", source, endpoint)
            self.assertIn("num_pedido =", source, endpoint)
        self.assertIn("ALTER COLUMN num_peito DROP NOT NULL", migration)

    def test_medical_form_creates_an_idempotent_event_link_before_bib_assignment(self):
        profile_backend = (ROOT.parent / "RoadRunners/includes/backend/backend_perfil_edicao.cfm").read_text(
            encoding="utf-8"
        )
        self.assertIn("GARANTE O VINCULO PROVISORIO", profile_backend)
        self.assertIn("fichamedica_sem_bib", profile_backend)
        self.assertIn("tb_evento_saude_config cfg", profile_backend)
        self.assertIn("cfg.ativo = true", profile_backend)
        self.assertIn("NOT EXISTS", profile_backend)
        self.assertIn("existente.id_usuario = usr.id", profile_backend)
        self.assertIn("INSERT INTO tb_inscricoes", profile_backend)

    def test_health_queues_use_exclusive_scan_and_emergency_states(self):
        startlist = (ROOT / "saude-eventos/central/fetch/startlist.cfm").read_text(encoding="utf-8")
        leaderboard = (ROOT / "saude-eventos/central/fetch/leaderboard.cfm").read_text(encoding="utf-8")
        stats = (ROOT / "saude-eventos/central/fetch/stats.cfm").read_text(encoding="utf-8")
        styles = (ROOT / "saude-eventos/central/assets/saude-panel.css").read_text(encoding="utf-8")
        self.assertIn("NOT IN ('scan','acionado','diligencia','atendimento','atendido')", startlist)
        self.assertIn("IN ('scan','acionado')", leaderboard)
        self.assertIn('"acionado" ? "Acionado"', leaderboard)
        self.assertIn("IN ('scan','acionado')", stats)
        self.assertIn(".saude-status-badge.is-acionado,\n.saude-status-badge.is-diligencia", styles)

    def test_public_medical_profile_tracks_the_live_status_after_emergency_call(self):
        profile = (ROOT.parent / "Perfil/ficha.cfm").read_text(encoding="utf-8")
        self.assertIn('medicalStatusLabel = "Equipe acionada"', profile)
        self.assertIn('medicalStatusLabel = "Em diligência"', profile)
        self.assertIn('medicalStatusLabel = "Em atendimento"', profile)
        self.assertIn('medicalStatusLabel = "Atendimento concluído"', profile)
        self.assertIn('medicalPostCall = listFindNoCase("acionado,diligencia,atendimento,atendido", medicalStoredStatus)', profile)
        self.assertIn("<cfif medicalPostCall>", profile)
        self.assertIn('medicalEmergencyEnabled = medicalOperationActive AND medicalStoredStatus EQ "scan"', profile)
        self.assertIn("medicalStatusRefresh = true", profile)
        self.assertIn("Status do atendimento", profile)
        self.assertIn("Atualização automática a cada 15 segundos.", profile)
        self.assertIn('nextUrl.searchParams.set("sync", "1")', profile)
        self.assertIn("window.location.replace(nextUrl.toString())", profile)
        self.assertIn("'acesso_ficha'", profile)
        self.assertIn("'acionar_equipe'", profile)
        self.assertIn("'abrir_whatsapp'", profile)
        self.assertIn("identificador_sessao", profile)
        self.assertNotIn("Equipe médica acionada com sucesso.", profile)

    def test_athlete_record_has_permanent_cross_event_timeline_and_operator_notes(self):
        panel = (ROOT / "saude-eventos/central/index.cfm").read_text(encoding="utf-8")
        athlete = (ROOT / "saude-eventos/central/fetch/athlete.cfm").read_text(encoding="utf-8")
        note = (ROOT / "saude-eventos/central/fetch/note.cfm").read_text(encoding="utf-8")
        self.assertIn("qSaudeHistory", athlete)
        self.assertIn("hist.id_usuario_atleta", athlete)
        self.assertIn("Cronologia permanente", athlete)
        self.assertIn("em todos os eventos", athlete)
        self.assertIn("saudeFriendlyTimestamp", athlete)
        self.assertIn("autor_exibicao", athlete)
        self.assertIn("Adicionar anotação", athlete)
        self.assertIn("adicionarAnotacao", panel)
        self.assertIn("endpoints.note", panel)
        self.assertIn("SESSION.saudeBusinessCsrfToken", note)
        self.assertIn("'anotacao'", note)
        self.assertIn("saudeNoteActorName", note)

    def test_medical_contacts_have_small_actions_and_are_audited_before_opening(self):
        panel = (ROOT / "saude-eventos/central/index.cfm").read_text(encoding="utf-8")
        athlete = (ROOT / "saude-eventos/central/fetch/athlete.cfm").read_text(encoding="utf-8")
        contact = (ROOT / "saude-eventos/central/fetch/contact.cfm").read_text(encoding="utf-8")
        styles = (ROOT / "saude-eventos/central/assets/saude-panel.css").read_text(encoding="utf-8")
        self.assertIn("acionarContato", panel)
        self.assertIn("endpoints.contact", panel)
        self.assertIn("Chamar atleta pelo WhatsApp", athlete)
        self.assertIn("Ligar para o contato de emergência", athlete)
        self.assertIn("saude-contact-actions", styles)
        self.assertIn("SESSION.saudeBusinessCsrfToken", contact)
        self.assertIn("usr.ficha_medica", contact)
        self.assertIn("tb_evento_saude_historico", contact)
        self.assertIn('"contato_" & VARIABLES.saudeContactType', contact)
        self.assertIn("saudeContactActorName", contact)
        self.assertNotIn("FORM.telefone", contact)

    def test_health_central_defaults_to_a_fifteen_second_refresh(self):
        backend = (ROOT / "saude-eventos/includes/backend.cfm").read_text(encoding="utf-8")
        panel = (ROOT / "saude-eventos/central/index.cfm").read_text(encoding="utf-8")
        self.assertIn("coalesce(cfg.intervalo_atualizacao, 15)", backend)
        self.assertIn(": 15/>", panel)
        self.assertNotIn("coalesce(cfg.intervalo_atualizacao, 30)", backend)

    def test_schema_enforces_one_configuration_per_event_and_audit_history(self):
        migration = (ROOT / "_codex/sql/2026-09-21_evento_saude_operacao.sql").read_text(encoding="utf-8")
        self.assertIn("id_evento                integer PRIMARY KEY", migration)
        self.assertIn("tb_evento_saude_config_percurso_fk", migration)
        self.assertIn("tb_evento_saude_historico", migration)
        self.assertIn("CHECK (intervalo_atualizacao BETWEEN 10 AND 300)", migration)
        self.assertIn("ALTER COLUMN intervalo_atualizacao SET DEFAULT 15", migration)
        self.assertIn("WHERE intervalo_atualizacao = 30", migration)
        self.assertIn("diretor_medico", migration)
        self.assertIn("whatsapp_equipe", migration)
        self.assertIn("tipo_acao", migration)
        self.assertIn("autor_nome", migration)
        self.assertIn("identificador_sessao", migration)
        self.assertIn("ON UPDATE CASCADE ON DELETE RESTRICT", migration)
        self.assertIn("tb_evento_saude_historico_usuario_data_idx", migration)


if __name__ == "__main__":
    unittest.main()
