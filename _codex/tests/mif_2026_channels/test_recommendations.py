from copy import deepcopy
import unittest

from _codex.analyses.mif_2026_channels.recommendations import (
    STRATEGIC_CHANNELS,
    recommend_channel,
)


OVERVIEW = {
    "paid_registrations": 10_000,
    "gross_value": "3000000.00",
    "registration_ticket": "300.00",
}


def dossier(**overrides):
    value = {
        "channel_name": "Canal teste",
        "paid_registrations": 100,
        "gross_value": "30000.00",
        "registration_ticket": "300.00",
        "share_of_event_registrations": 1.0,
        "modality_delta_pp": [],
        "lot_delta_pp": [],
        "phase_delta_pp": [],
        "top_states": [],
        "product_mix": [],
        "distinctive_signals": [],
        "similar_channels_by_dimension": [],
    }
    value.update(overrides)
    return value


def delta(dimension, segment, value):
    return {
        "dimension": dimension,
        "segment": segment,
        "delta_pp": value,
        "channel_count": 40,
        "channel_denominator": 100,
        "event_count": 2_500,
        "event_denominator": 10_000,
    }


def organic_similarity(value):
    return [
        {
            "dimension": dimension,
            "other_channel": "Orgânico / sem cupom",
            "similarity_0_1": value,
        }
        for dimension in ("geography", "modality", "temporal", "product")
    ]


class RecommendationTests(unittest.TestCase):
    def test_prioritize_requires_scale_and_material_differentiation(self):
        channel = dossier(
            paid_registrations=800,
            gross_value="270000.00",
            share_of_event_registrations=8.0,
            modality_delta_pp=[delta("modalidade", "42K", 12.0)],
        )

        result = recommend_channel(channel, OVERVIEW)

        self.assertEqual(result["category"], "Priorizar")
        self.assertIn("42K", result["role"])
        self.assertIn("12,00%", result["role"])
        self.assertNotIn(" pp", result["role"])
        self.assertGreaterEqual(len(result["evidence"]), 2)

    def test_maintain_with_defined_role_for_specific_complement(self):
        channel = dossier(
            paid_registrations=90,
            gross_value="27000.00",
            share_of_event_registrations=0.9,
            phase_delta_pp=[delta("fase", "Lançamento", 15.0)],
        )

        result = recommend_channel(channel, OVERVIEW)

        self.assertEqual(result["category"], "Manter com função definida")
        self.assertIn("Lançamento", result["role"])

    def test_reduce_requires_low_scale_high_redundancy_and_no_material_role(self):
        channel = dossier(
            paid_registrations=40,
            gross_value="9000.00",
            share_of_event_registrations=0.4,
            similar_channels_by_dimension=organic_similarity(0.96),
        )

        result = recommend_channel(channel, OVERVIEW)

        self.assertEqual(result["category"], "Reduzir/descontinuar")
        self.assertTrue(any("orgânico" in item.casefold() for item in result["evidence"]))

    def test_small_sample_cannot_receive_a_strong_discontinuation(self):
        channel = dossier(
            paid_registrations=20,
            gross_value="2000.00",
            share_of_event_registrations=0.2,
            similar_channels_by_dimension=organic_similarity(0.99),
        )

        result = recommend_channel(channel, OVERVIEW)

        self.assertEqual(result["category"], "Testar/renegociar")
        self.assertEqual(result["sample_qualification"], "amostra reduzida")
        self.assertGreaterEqual(len(result["evidence"]), 2)

    def test_ambiguous_evidence_stays_in_test_and_renegotiate(self):
        result = recommend_channel(deepcopy(dossier()), OVERVIEW)

        self.assertEqual(result["category"], "Testar/renegociar")
        self.assertTrue(result["role"])

    def test_strategic_channels_are_explicit_and_normalized(self):
        self.assertEqual(
            STRATEGIC_CHANNELS,
            frozenset({"ROADRUNNERS", "SPORTS WEEK", "PCD"}),
        )


if __name__ == "__main__":
    unittest.main()
