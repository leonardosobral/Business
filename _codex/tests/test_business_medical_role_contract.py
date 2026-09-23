from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[2]


class BusinessMedicalRoleContract(unittest.TestCase):
    def test_database_role_is_added_without_renaming_persisted_roles(self):
        migration = (ROOT / "_codex/sql/2026-09-22_business_medico_role.sql").read_text(encoding="utf-8")
        schema = (ROOT / "_codex/sql/ddl.sql").read_text(encoding="utf-8")
        self.assertIn("ADD VALUE IF NOT EXISTS 'MEDICO'", migration)
        self.assertIn("'OWNER', 'ADMIN', 'OPERADOR', 'MEDICO', 'VISUALIZADOR'", schema)

    def test_account_management_offers_the_medical_role_with_friendly_labels(self):
        backend = (ROOT / "administracao/contas/includes/backend.cfm").read_text(encoding="utf-8")
        page = (ROOT / "administracao/contas/home.cfm").read_text(encoding="utf-8")
        self.assertIn('"OWNER,ADMIN,OPERADOR,MEDICO,VISUALIZADOR"', backend)
        self.assertIn('MEDICO = "Médico"', backend)
        self.assertIn('VISUALIZADOR = "Auditor"', backend)
        self.assertIn('OWNER = "Dono"', backend)
        self.assertIn('option value="MEDICO"', page)
        self.assertIn("accountUserPapelLabels[accountPapelOption]", page)

    def test_medical_accounts_are_restricted_to_health_routes(self):
        context = (ROOT / "includes/backend/business_account_context.cfm").read_text(encoding="utf-8")
        login = (ROOT / "includes/backend/backend_login.cfm").read_text(encoding="utf-8")
        menu = (ROOT / "includes/estrutura/sidenav.cfm").read_text(encoding="utf-8")
        self.assertIn("businessCurrentAccountIsMedical", context)
        self.assertIn('compareNoCase(trim(VARIABLES.businessCurrentAccountRole & ""), "MEDICO")', context)
        self.assertIn('NOT findNoCase("/saude-eventos/", CGI.SCRIPT_NAME)', login)
        self.assertIn('url="/saude-eventos/"', login)
        self.assertIn("businessIsMedicalWorkspace", menu)
        self.assertIn("Central médica", menu)

    def test_medical_role_cannot_edit_operation_configuration(self):
        backend = (ROOT / "saude-eventos/includes/backend.cfm").read_text(encoding="utf-8")
        page = (ROOT / "saude-eventos/home.cfm").read_text(encoding="utf-8")
        self.assertIn("saudeConfigIsMedical", backend)
        self.assertIn("NOT VARIABLES.saudeConfigIsMedical", backend)
        self.assertIn("NOT VARIABLES.saudeConfigIsMedical", page)
        self.assertIn("não pode alterar sua configuração", page)


if __name__ == "__main__":
    unittest.main()
