"""Privacy and neutral-narrative contracts for the MIF 2026 analysis."""

from copy import deepcopy
from dataclasses import replace
import unittest

from _codex.analyses.mif_2026_channels.metrics import build_analysis
from _codex.analyses.mif_2026_channels.narrative import (
    build_decision_questions,
    describe_channel,
    describe_event,
)
from _codex.analyses.mif_2026_channels.privacy import (
    assert_anonymous,
    protect_analysis,
    suppress_small_cells,
)
from _codex.tests.mif_2026_channels.fixtures import channel_metric_facts


FORBIDDEN_ADVICE = (
    "manter",
    "cortar",
    "eliminar",
    "priorizar",
    "nota",
    "ranking",
    "score",
    "recomendar",
    "recomendação",
)
MECHANISM_POLICY = (
    "mecanismo/política no cadastro, não presumido como parceiro comercial"
)


def analysis_result():
    """Return a complete real analysis result for public-contract tests."""
    return build_analysis(channel_metric_facts())


class PrivacyNarrativeTests(unittest.TestCase):
    def test_forbidden_keys_and_pii_values_report_every_json_path(self):
        """Skipping recursion or returning early would conceal additional PII findings."""
        payload = {
            "Email": "pessoa@example.com",
            "nested": [
                {"Data Nascimento": "1990-01-01"},
                {"description": "CPF 123.456.789-00"},
                {"note": "ligue para (48) 99999-1234"},
            ],
        }

        with self.assertRaises(ValueError) as raised:
            assert_anonymous(payload)

        message = str(raised.exception)
        for expected in (
            "$.Email: forbidden key",
            "$.Email: email-like value",
            "$.nested[0].Data Nascimento: forbidden key",
            "$.nested[1].description: document-like value",
            "$.nested[2].note: phone-like value",
        ):
            self.assertIn(expected, message)

    def test_anonymous_metrics_weeks_coupon_codes_and_money_are_allowed(self):
        """Overbroad number matching would reject legitimate aggregate evidence."""
        assert_anonymous(
            {
                "paid_registrations": 42,
                "week_start": "2026-06-01",
                "coupon_code": "11987654321",
                "registration_ticket": "120.00",
                "summary": "42K; cobertura de 100%; R$ 120,00",
            }
        )

    def test_small_cross_tab_cells_are_aggregated_with_suppressed_total(self):
        """Dropping small rows instead of aggregating them would break reconciliation."""
        rows = [
            {"state": "SC", "count": 2},
            {"state": "PR", "count": 3},
        ]

        self.assertEqual(
            suppress_small_cells(rows, "count"),
            [
                {"state": "Outros / suprimido", "count": 2, "suppressed": True},
                {"state": "PR", "count": 3, "suppressed": False},
            ],
        )
        self.assertEqual(sum(row["count"] for row in rows), 5)

    def test_protection_suppresses_only_defined_channel_cross_tabs(self):
        """Suppressing channel totals, long tail, or state mix would hide business totals."""
        original = analysis_result()
        dossiers = deepcopy(original.full_dossiers)
        dossier = dossiers[0]
        dossier["top_cities"] = [
            {"city": "Cidade A", "paid_registrations": 1},
            {"city": "Cidade B", "paid_registrations": 2},
            {"city": "Cidade C", "paid_registrations": 3},
        ]
        dossier["age_bands"] = [
            {"age_band": "18–24", "paid_registrations": 2},
            {"age_band": "25–34", "paid_registrations": 10},
        ]
        dossier["gender_mix"] = [
            {"gender": "Outro", "paid_registrations": 1},
            {"gender": "Feminino", "paid_registrations": 11},
        ]
        dossier["pace_bands"] = [
            {"pace_band": "4:30–4:59", "paid_registrations": 2},
            {"pace_band": "5:00–5:29", "paid_registrations": 10},
        ]
        dossier["club_presence"] = [
            {"club": "Clube A", "paid_registrations": 1},
            {"club": "Clube B", "paid_registrations": 11},
        ]
        dossier["top_states"] = [{"state": "SC", "paid_registrations": 1}]
        candidate = replace(original, full_dossiers=dossiers)

        protected = protect_analysis(candidate)

        protected_dossier = protected.full_dossiers[0]
        expected_suppressed_totals = {
            "top_cities": 3,
            "age_bands": 2,
            "gender_mix": 1,
            "pace_bands": 2,
            "club_presence": 1,
        }
        for field, expected_total in expected_suppressed_totals.items():
            self.assertTrue(protected_dossier[field][0]["suppressed"], field)
            self.assertEqual(
                protected_dossier[field][0]["paid_registrations"], expected_total
            )
        self.assertEqual(protected_dossier["top_states"], dossier["top_states"])
        self.assertEqual(
            protected.datasets["channel_index"], original.datasets["channel_index"]
        )
        self.assertEqual(protected.long_tail, original.long_tail)
        self.assertNotIn("suppressed", candidate.full_dossiers[0]["top_cities"][0])

    def test_channel_text_is_evidence_not_keep_cut_advice(self):
        """An action label or missing evidence base would turn a dossier into a score."""
        dossier = deepcopy(analysis_result().full_dossiers[0])
        dossier["modality_mix"] = [
            {
                "modality": "42K",
                "paid_registrations": 7,
                "denominator": 12,
                "share_pct": 58.33,
            },
            *dossier["modality_mix"],
        ]

        text = describe_channel(dossier, analysis_result().overview)
        lowered = text.lower()

        for forbidden in FORBIDDEN_ADVICE:
            self.assertNotIn(forbidden, lowered)
        for expected in (
            "42K",
            "12 inscrições pagas",
            "12 pedidos tocados",
            "46.15%",
            "ticket médio ponderado por inscrição",
            "abrangência",
            "concentração",
            "lote",
            "adicional",
            "Cobertura de perfil",
            "Aliases de origem",
            "Limitações de leitura:",
        ):
            self.assertIn(expected, text)
        self.assertTrue(text.endswith(dossier["data_limitations"][-1] + "."))

    def test_event_text_declares_grains_weighted_tickets_bases_and_limitations(self):
        """Blending order and registration grains would overstate channel evidence."""
        text = describe_event(analysis_result())
        lowered = text.lower()

        for forbidden in FORBIDDEN_ADVICE:
            self.assertNotIn(forbidden, lowered)
        for expected in (
            "Grãos",
            "pedidos pagos únicos",
            "inscrições pagas",
            "pedidos tocados não são aditivos entre canais",
            "ticket médio ponderado",
            "base de 26 pedidos",
            "base de 26 inscrições",
            "Coberturas de fonte",
            "Limitações de leitura:",
        ):
            self.assertIn(expected, text)

    def test_mechanism_channels_are_not_presumed_commercial_partners(self):
        """Treating policy or benefit coupons as partners would invent a commercial tie."""
        base = analysis_result().full_dossiers[0]
        overview = analysis_result().overview

        for channel_name, channel_type in (
            ("PCD", "politica"),
            ("Benefício", "beneficio"),
        ):
            dossier = {
                **deepcopy(base),
                "channel_name": channel_name,
                "channel_type": channel_type,
            }
            self.assertIn(MECHANISM_POLICY, describe_channel(dossier, overview))

        reviewed_partner = {
            **deepcopy(base),
            "channel_name": "PCD",
            "channel_type": "parceiro",
        }
        self.assertNotIn(MECHANISM_POLICY, describe_channel(reviewed_partner, overview))

    def test_sports_week_receives_the_complete_channel_evidence_treatment(self):
        """A special-case short summary would give Sports Week inferior treatment."""
        dossier = {
            **deepcopy(analysis_result().full_dossiers[0]),
            "channel_name": "Sports Week",
            "channel_type": "evento_acao",
        }

        text = describe_channel(dossier, analysis_result().overview)

        for expected in (
            "inscrições pagas",
            "pedidos tocados",
            "ticket médio ponderado por inscrição",
            "Cobertura de perfil",
            "Aliases de origem",
            "Limitações de leitura:",
        ):
            self.assertIn(expected, text)

    def test_decision_questions_have_no_yes_no_answer_score_or_action_label(self):
        """Attaching answers or actions would automate a human commercial decision."""
        questions = build_decision_questions(analysis_result())

        self.assertEqual(len(questions), 4)
        self.assertTrue(
            all(
                isinstance(question, str) and question.endswith("?")
                for question in questions
            )
        )
        self.assertTrue(any("pares" in question.lower() for question in questions))
        self.assertTrue(any("cobertura" in question.lower() for question in questions))
        for question in questions:
            lowered = question.lower()
            self.assertFalse(lowered.startswith(("sim", "não")))
            for forbidden in (*FORBIDDEN_ADVICE, "ação:", "resposta:"):
                self.assertNotIn(forbidden, lowered)


if __name__ == "__main__":
    unittest.main()
