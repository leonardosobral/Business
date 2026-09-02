import unittest

from _codex.analyses.mif_2026_channels.portfolio import (
    build_portfolio_artifacts,
    classify_exposure,
    commercial_channels,
    nearest_peer_profiles,
    redundancy_candidates,
)


def channel_index_fixture():
    return [
        {"channel_name": "ALFA", "channel_type": "parceiro", "gross_value": "400.00", "paid_registrations": 20, "registration_ticket": "20.00"},
        {"channel_name": "BETA", "channel_type": "parceiro", "gross_value": "300.00", "paid_registrations": 20, "registration_ticket": "15.00"},
        {"channel_name": "GAMA", "channel_type": "parceiro", "gross_value": "200.00", "paid_registrations": 20, "registration_ticket": "12.00"},
    ]


def similarity_fixture():
    fixture = {dimension: [] for dimension in ("geography", "modality", "temporal", "lot", "product")}
    for dimension in ("geography", "modality", "temporal", "lot"):
        fixture[dimension].append(
            {"channel_a": "ALFA", "channel_b": "BETA", "similarity_0_1": 0.95, "coverage_a": 90, "coverage_b": 90}
        )
    fixture["geography"].append(
        {"channel_a": "BETA", "channel_b": "ALFA", "similarity_0_1": 0.95, "coverage_a": 90, "coverage_b": 90}
    )
    fixture["temporal"].append(
        {"channel_a": "ALFA", "channel_b": "GAMA", "similarity_0_1": 0.97, "coverage_a": 90, "coverage_b": 90}
    )
    fixture["product"].append(
        {"channel_a": "ALFA", "channel_b": "BETA", "similarity_0_1": 0.99, "coverage_a": 60, "coverage_b": 90}
    )
    for dimension in ("geography", "modality", "temporal", "lot"):
        fixture[dimension].extend(
            {
                "channel_a": f"LOW-{number:02d}",
                "channel_b": f"LOW-{number:02d}-PEER",
                "similarity_0_1": 0.10,
                "coverage_a": 90,
                "coverage_b": 90,
            }
            for number in range(20)
        )
    return fixture


def portfolio_fixture():
    channels = channel_index_fixture()
    channels.append(
        {"channel_name": "Orgânico / sem cupom", "channel_type": "organico", "gross_value": "500.00", "paid_registrations": 40, "registration_ticket": "12.50"}
    )
    return {
        "overview": {"paid_registrations": 100, "gross_value": "1500.00"},
        "channel_index": channels,
        "dossiers": {"similarities": similarity_fixture()},
        "registration_cube": [
            {"phase": "Início", "modality": "21K", "state": "SC", "city": "Florianópolis", "week_start": "2026-01-05", "channel_name": "ALFA", "paid_registrations": 12, "allocated_gross_value": "240.00"},
            {"phase": "Início", "modality": "21K", "state": "SC", "city": "Florianópolis", "week_start": "2026-01-12", "channel_name": "BETA", "paid_registrations": 8, "allocated_gross_value": "120.00"},
            {"phase": "Início", "modality": "21K", "state": "SC", "city": "Florianópolis", "week_start": "2026-01-12", "channel_name": "Orgânico / sem cupom", "paid_registrations": 10, "allocated_gross_value": "125.00"},
        ],
        "generated_at": "2026-09-02T12:00:00-03:00",
    }


class PortfolioContractTests(unittest.TestCase):
    def test_commercial_universe_excludes_organic_and_ticket_boundary(self):
        rows = [
            {"channel_name": "Orgânico / sem cupom", "channel_type": "organico", "gross_value": "100.00", "paid_registrations": 20, "registration_ticket": "200.00"},
            {"channel_name": "Cortesia", "channel_type": "cortesia", "gross_value": "100.00", "paid_registrations": 20, "registration_ticket": "10.00"},
            {"channel_name": "Sports Week", "channel_type": "parceiro", "gross_value": "100.00", "paid_registrations": 20, "registration_ticket": "10.01"},
        ]

        self.assertEqual(
            [row["channel_name"] for row in commercial_channels(rows, selectable=True)],
            ["Sports Week"],
        )

    def test_exposure_uses_event_and_partner_denominators(self):
        self.assertEqual(
            classify_exposure(selected=40, event_total=100, commercial_total=50),
            "alta",
        )
        self.assertEqual(
            classify_exposure(selected=20, event_total=100, commercial_total=50),
            "média",
        )
        self.assertEqual(
            classify_exposure(selected=12, event_total=100, commercial_total=20),
            "dependência entre parceiros",
        )
        self.assertIsNone(
            classify_exposure(selected=4, event_total=5, commercial_total=4)
        )

    def test_nearest_peer_is_dimension_specific_and_requires_coverage(self):
        result = nearest_peer_profiles(similarity_fixture(), channel_index_fixture())

        self.assertEqual(result["ALFA"]["geography"]["nearest_channel"], "BETA")
        self.assertEqual(result["ALFA"]["temporal"]["nearest_channel"], "GAMA")
        self.assertEqual(result["ALFA"]["product"]["status"], "evidência insuficiente")

    def test_redundancy_requires_four_dimensions_including_geography_or_temporal(self):
        rows = redundancy_candidates(similarity_fixture(), channel_index_fixture())

        self.assertEqual(
            [(row["left_channel"], row["right_channel"]) for row in rows],
            [("ALFA", "BETA")],
        )

    def test_static_summary_never_contains_simulator_cube(self):
        artifacts = build_portfolio_artifacts(**portfolio_fixture())

        self.assertNotIn("coverage_cube", artifacts["portfolio/summary.json"])
        self.assertEqual(
            artifacts["portfolio/simulator.json"]["dimensions"],
            ["phase", "modality", "state", "channel_name"],
        )


if __name__ == "__main__":
    unittest.main()
