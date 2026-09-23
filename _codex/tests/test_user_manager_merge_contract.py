from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[2]


class UserManagerMergeContract(unittest.TestCase):
    def setUp(self):
        self.schema = (ROOT / "administracao/usuarios/user_management_schema.sql").read_text(
            encoding="utf-8"
        )

    def test_source_identity_is_saved_before_unique_values_are_released(self):
        self.assertIn("v_source_user public.tb_usuarios%ROWTYPE", self.schema)
        self.assertRegex(
            self.schema,
            re.compile(
                r"SELECT usr\.\* INTO STRICT v_source_user.*?"
                r"UPDATE public\.tb_usuarios\s+SET username = NULL,\s+strava_id = NULL.*?"
                r"UPDATE public\.tb_usuarios keep",
                re.DOTALL,
            ),
        )

    def test_destination_uses_the_saved_source_record(self):
        self.assertIn(
            "username = coalesce(nullif(btrim(keep.username), ''), v_source_user.username)",
            self.schema,
        )
        self.assertNotIn("WITH source_values AS", self.schema)
        self.assertNotIn("FROM public.tb_usuarios source", self.schema)

    def test_merge_remains_transactional_and_audited(self):
        self.assertIn("DELETE FROM public.tb_usuarios WHERE id = p_source_user", self.schema)
        self.assertIn("'usuarios_mesclados'", self.schema)


if __name__ == "__main__":
    unittest.main()
