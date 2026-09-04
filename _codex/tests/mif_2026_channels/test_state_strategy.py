import json
from pathlib import Path
import unittest

from _codex.analyses.mif_2026_channels.state_strategy import (
    build_state_strategy,
    classify_reach,
)


def state_strategy_fixture():
    channel_index = [
        {
            "channel_name": "ÂNCORA",
            "channel_type": "influenciador",
            "slug": "ancora",
            "paid_registrations": 50,
            "gross_value": "15000.00",
            "registration_ticket": "300.00",
        },
        {
            "channel_name": "REFORÇO",
            "channel_type": "midia",
            "slug": "reforco",
            "paid_registrations": 30,
            "gross_value": "9300.00",
            "registration_ticket": "310.00",
        },
        {
            "channel_name": "BAIXO VALOR",
            "channel_type": "cortesia",
            "slug": "baixo-valor",
            "paid_registrations": 10,
            "gross_value": "50.00",
            "registration_ticket": "5.00",
        },
        {
            "channel_name": "Orgânico / sem cupom",
            "channel_type": "organico",
            "slug": "organico-sem-cupom",
            "paid_registrations": 20,
            "gross_value": "6000.00",
            "registration_ticket": "300.00",
        },
    ]
    observations = [
        {"state": "SP", "channel_name": "ÂNCORA", "modality": "21K", "phase": "Início", "paid_registrations": 20, "allocated_gross_value": "6000.00"},
        {"state": "SC", "channel_name": "ÂNCORA", "modality": "42K", "phase": "Meio", "paid_registrations": 10, "allocated_gross_value": "3000.00"},
        {"state": "PR", "channel_name": "ÂNCORA", "modality": "21K", "phase": "Meio", "paid_registrations": 5, "allocated_gross_value": "1500.00"},
        {"state": "MG", "channel_name": "ÂNCORA", "modality": "42K", "phase": "Reta final", "paid_registrations": 5, "allocated_gross_value": "1500.00"},
        {"state": "BA", "channel_name": "ÂNCORA", "modality": "5K", "phase": "Reta final", "paid_registrations": 5, "allocated_gross_value": "1500.00"},
        {"state": "DF", "channel_name": "ÂNCORA", "modality": "21K", "phase": "Encerramento", "paid_registrations": 5, "allocated_gross_value": "1500.00"},
        {"state": "SP", "channel_name": "REFORÇO", "modality": "21K", "phase": "Início", "paid_registrations": 15, "allocated_gross_value": "4650.00"},
        {"state": "MG", "channel_name": "REFORÇO", "modality": "42K", "phase": "Meio", "paid_registrations": 8, "allocated_gross_value": "2480.00"},
        {"state": "RJ", "channel_name": "REFORÇO", "modality": "21K", "phase": "Meio", "paid_registrations": 4, "allocated_gross_value": "1240.00"},
        {"state": "Não informado", "channel_name": "REFORÇO", "modality": "5K", "phase": "Meio", "paid_registrations": 3, "allocated_gross_value": "930.00"},
        {"state": "SC", "channel_name": "BAIXO VALOR", "modality": "5K", "phase": "Meio", "paid_registrations": 10, "allocated_gross_value": "50.00"},
        {"state": "SC", "channel_name": "Orgânico / sem cupom", "modality": "21K", "phase": "Meio", "paid_registrations": 20, "allocated_gross_value": "6000.00"},
    ]
    dossiers = [
        {
            "channel_name": "ÂNCORA",
            "similar_channels_by_dimension": [
                {
                    "dimension": "geography",
                    "other_channel": "REFORÇO",
                    "similarity_0_1": 0.81,
                    "channel_coverage": 100,
                    "other_coverage": 90,
                }
            ],
        },
        {
            "channel_name": "REFORÇO",
            "similar_channels_by_dimension": [
                {
                    "dimension": "geography",
                    "other_channel": "ÂNCORA",
                    "similarity_0_1": 0.81,
                    "channel_coverage": 90,
                    "other_coverage": 100,
                }
            ],
        },
    ]
    return {
        "overview": {"paid_registrations": 110, "gross_value": "30350.00"},
        "channel_index": channel_index,
        "dossiers": dossiers,
        "territory_observations": observations,
        "geography_benchmark": {"p90_similarity_0_1": 0.70},
        "generated_at": "2026-09-03T12:00:00-03:00",
    }


class StateStrategyTests(unittest.TestCase):
    def test_reach_classification_uses_explicit_volume_coverage_and_breadth_gates(self):
        self.assertEqual(
            classify_reach(
                paid_registrations=100,
                valid_coverage_pct=95,
                active_ufs=10,
                active_regions=4,
                leading_state_share_pct=39.99,
            ),
            "Nacional",
        )
        self.assertEqual(
            classify_reach(
                paid_registrations=100,
                valid_coverage_pct=95,
                active_ufs=5,
                active_regions=3,
                leading_state_share_pct=60,
            ),
            "Multirregional",
        )
        self.assertEqual(
            classify_reach(
                paid_registrations=100,
                valid_coverage_pct=95,
                active_ufs=4,
                active_regions=2,
                leading_state_share_pct=61,
            ),
            "Regional",
        )
        self.assertEqual(
            classify_reach(
                paid_registrations=29,
                valid_coverage_pct=100,
                active_ufs=10,
                active_regions=5,
                leading_state_share_pct=20,
            ),
            "Evidência insuficiente",
        )
        self.assertEqual(
            classify_reach(
                paid_registrations=100,
                valid_coverage_pct=69.99,
                active_ufs=10,
                active_regions=5,
                leading_state_share_pct=20,
            ),
            "Evidência insuficiente",
        )

    def test_build_reconciles_valid_states_and_excludes_low_value_channel_from_commercial_views(self):
        result = build_state_strategy(**state_strategy_fixture())

        self.assertEqual(result["overview"]["event_paid_registrations"], 110)
        self.assertEqual(result["overview"]["valid_state_registrations"], 107)
        self.assertEqual(result["overview"]["state_coverage_pct"], "97.27")
        self.assertEqual(result["overview"]["commercial_paid_registrations"], 80)
        self.assertEqual(
            [row["channel_name"] for row in result["channels"]],
            ["ÂNCORA", "REFORÇO"],
        )
        self.assertNotIn(
            "BAIXO VALOR",
            {row["channel_name"] for row in result["state_channels"]},
        )

    def test_state_channel_detail_suppresses_small_cells_but_state_totals_remain_complete(self):
        result = build_state_strategy(**state_strategy_fixture())

        self.assertEqual(
            next(row for row in result["states"] if row["state"] == "RJ")["paid_registrations"],
            4,
        )
        self.assertNotIn(
            ("RJ", "REFORÇO"),
            {(row["state"], row["channel_name"]) for row in result["state_channels"]},
        )
        self.assertEqual(result["privacy"]["suppressed_state_channel_registrations"], 4)

    def test_featured_pair_exposes_strong_overlap_and_distinct_state_strengths(self):
        result = build_state_strategy(
            **state_strategy_fixture(),
            featured_channels=("ÂNCORA", "REFORÇO"),
        )
        pair = result["featured_pair"]

        self.assertEqual(pair["left_channel"], "ÂNCORA")
        self.assertEqual(pair["right_channel"], "REFORÇO")
        self.assertEqual(pair["geography_similarity_0_1"], 0.81)
        self.assertEqual(pair["geography_p90_similarity_0_1"], 0.70)
        self.assertEqual(pair["overlap_classification"], "Sobreposição forte")
        self.assertIn("SP", pair["shared_relevant_states"])
        self.assertIn("SC", pair["left_distinctive_states"])
        self.assertIn("MG", pair["right_distinctive_states"])
        serialized = json.dumps(pair, ensure_ascii=False)
        self.assertIn("não mede incrementalidade", serialized)
        self.assertNotRegex(serialized, r"canibalização comprovada|vendas seriam perdidas")

    def test_canonical_pair_preserves_national_reach_and_scale_difference(self):
        root = Path(__file__).resolve().parents[2] / "analyses" / "mif_2026_channels" / "modular_dist"
        channel_index = json.loads((root / "channels" / "index.json").read_text(encoding="utf-8"))["channels"]
        dossiers = [
            json.loads((root / "channels" / f"{slug}.json").read_text(encoding="utf-8"))["channel"]
            for slug in ("roadrunners", "maniadecorrida")
        ]
        general = json.loads((root / "general.json").read_text(encoding="utf-8"))
        territories = json.loads((root / "territories.json").read_text(encoding="utf-8"))
        portfolio = json.loads((root / "portfolio" / "summary.json").read_text(encoding="utf-8"))

        result = build_state_strategy(
            overview=general["overview"],
            channel_index=channel_index,
            dossiers=dossiers,
            territory_observations=territories["observations"],
            geography_benchmark=portfolio["dimension_benchmarks"]["geography"],
            generated_at=general["meta"]["generated_at"],
        )
        channels = {row["channel_name"]: row for row in result["channels"]}

        self.assertEqual(channels["ROADRUNNERS"]["reach_classification"], "Nacional")
        self.assertEqual(channels["ROADRUNNERS"]["active_ufs"], 22)
        self.assertEqual(channels["MANIADECORRIDA"]["reach_classification"], "Nacional")
        self.assertEqual(channels["MANIADECORRIDA"]["active_ufs"], 10)
        self.assertEqual(result["featured_pair"]["geography_similarity_0_1"], 0.8056)
        self.assertEqual(result["featured_pair"]["overlap_classification"], "Sobreposição forte")


if __name__ == "__main__":
    unittest.main()
