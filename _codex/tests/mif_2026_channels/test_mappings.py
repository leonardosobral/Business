from dataclasses import replace
from decimal import Decimal
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest

import pandas as pd

from _codex.analyses.mif_2026_channels.facts import build_fact_bundle
from _codex.analyses.mif_2026_channels.mappings import (
    CHANNEL_MAPPING_COLUMNS,
    PRODUCT_MAPPING_COLUMNS,
    apply_reviewed_mappings,
    assign_channels,
    classify_products,
    emit_channel_mapping_draft,
    emit_product_mapping_draft,
    load_channel_mapping,
    load_product_mapping,
)
from _codex.tests.mif_2026_channels.fixtures import (
    mapping_product_fact,
    mapping_registration_fact,
    source_bundle,
)


DATA_DIR = Path("_codex/analyses/mif_2026_channels")


class MappingTests(unittest.TestCase):
    def test_two_correcriciuma_codes_consolidate_and_remain_auditable(self):
        """Matching only one code or replacing source aliases would lose auditability."""
        registrations = mapping_registration_fact().iloc[:2].copy()
        mapping = pd.DataFrame(
            [
                {
                    "coupon_title_key": "CORRECRICIUMA",
                    "coupon_code_key": code,
                    "channel_name": "Corre Criciúma",
                    "channel_type": "assessoria",
                    "alias_reason": reason,
                    "reviewed": True,
                }
                for code, reason in (
                    ("CORRECRICIUMA", "mesmo parceiro, código principal"),
                    ("CORRECRICIUMA_100", "mesmo parceiro, ação limitada"),
                )
            ]
        )

        assigned = assign_channels(registrations, mapping)

        self.assertEqual(set(assigned["channel_name"]), {"Corre Criciúma"})
        self.assertEqual(
            set(assigned["coupon_code"]),
            {"CORRECRICIUMA", "CORRECRICIUMA_100"},
        )
        self.assertEqual(
            set(assigned["alias_reason"]),
            {"mesmo parceiro, código principal", "mesmo parceiro, ação limitada"},
        )

    def test_final_correcriciuma_aliases_are_versioned_and_consolidated(self):
        """The reviewed final CSV must retain both observed exact aliases."""
        mapping = load_channel_mapping(DATA_DIR / "channel_mapping.csv")
        corre = mapping.loc[mapping["channel_name"] == "Corre Criciúma"]

        self.assertEqual(
            set(zip(corre["coupon_title_key"], corre["coupon_code_key"], strict=True)),
            {
                ("CORRECRICIUMA", "CORRECRICIUMA"),
                ("CORRECRICIUMA", "CORRECRICIUMA 100"),
            },
        )
        self.assertEqual(int(corre["paid_registrations"].sum()), 23)
        self.assertEqual(set(corre["channel_type"]), {"assessoria"})
        self.assertTrue(corre["reviewed"].all())

    def test_channel_assignment_is_exact_and_paid_pairs_fail_closed(self):
        """A fuzzy or partial join would silently classify an unreviewed coupon identity."""
        registrations = pd.DataFrame(
            [
                {
                    "numero_inscricao": 1,
                    "coupon_title": "Corre Criciuma",
                    "coupon_code": "CORRECRICIUMA-101",
                    "is_paid": True,
                }
            ]
        )
        mapping = load_channel_mapping(DATA_DIR / "channel_mapping.csv")

        with self.assertRaisesRegex(ValueError, "unmapped paid coupon pairs: 1"):
            assign_channels(registrations, mapping)

    def test_organic_sale_is_assigned_in_code_and_kept_separate(self):
        """Treating a blank coupon as a partner would contaminate channel totals."""
        registrations = mapping_registration_fact().iloc[[5]].copy()
        empty_mapping = load_channel_mapping(DATA_DIR / "channel_mapping.csv").iloc[0:0]

        assigned = assign_channels(registrations, empty_mapping)

        self.assertEqual(assigned.loc[0, "channel_name"], "Orgânico / sem cupom")
        self.assertEqual(assigned.loc[0, "channel_type"], "organico")
        self.assertIsNone(assigned.loc[0, "coupon_title"])
        self.assertIsNone(assigned.loc[0, "coupon_code"])

    def test_channel_mapping_requires_unique_complete_reviewed_rows(self):
        """Incomplete, duplicate, or unreviewed rows would bypass human review."""
        base = pd.DataFrame(
            [
                {
                    "coupon_title_key": "CANAL A",
                    "coupon_code_key": "CANAL A",
                    "coupon_title_example": "Canal A",
                    "coupon_code_example": "CANAL_A",
                    "paid_registrations": 1,
                    "channel_name": "Canal A",
                    "channel_type": "parceiro",
                    "alias_reason": "identidade exata",
                    "reviewed": True,
                }
            ]
        )
        with TemporaryDirectory() as directory:
            path = Path(directory) / "mapping.csv"
            cases = {
                "reviewed": base.assign(reviewed=False),
                "incomplete": base.assign(alias_reason=""),
                "duplicate": pd.concat([base, base], ignore_index=True),
                "channel_type": base.assign(channel_type="fuzzy"),
            }
            for message, frame in cases.items():
                with self.subTest(message=message):
                    frame.to_csv(path, index=False)
                    with self.assertRaisesRegex(ValueError, message):
                        load_channel_mapping(path)

    def test_channel_draft_contains_each_paid_nonorganic_pair_once(self):
        """Counting unpaid rows or collapsing exact pairs would produce a false review list."""
        registrations = mapping_registration_fact()
        with TemporaryDirectory() as directory:
            path = Path(directory) / "channel-draft.csv"
            emit_channel_mapping_draft(registrations, path)
            draft = pd.read_csv(path, keep_default_na=False)
            loaded_draft = load_channel_mapping(path, require_reviewed=False)

        self.assertEqual(list(draft.columns), CHANNEL_MAPPING_COLUMNS)
        self.assertEqual(len(draft), 5)
        self.assertEqual(len(loaded_draft), 5)
        sports_week = draft.loc[draft["coupon_code_key"] == "SPORTS WEEK"].iloc[0]
        self.assertEqual(sports_week["paid_registrations"], 1)
        self.assertEqual(sports_week["reviewed"], False)

    def test_final_channel_types_encode_reviewed_business_meanings(self):
        """Generic partner labels would erase reviewed meanings from final mappings."""
        mapping = load_channel_mapping(DATA_DIR / "channel_mapping.csv")
        observed = mapping.groupby("channel_name")["channel_type"].agg(set).to_dict()
        self.assertEqual(observed["Sports Week"], {"evento_acao"})
        self.assertEqual(observed["PCD"], {"politica"})
        self.assertEqual(observed["Benefício"], {"beneficio"})
        self.assertNotIn("Orgânico / sem cupom", observed)

    def test_product_draft_and_loader_require_exact_reviewed_identities(self):
        """A duplicate or unreviewed identity would make product classification ambiguous."""
        products = pd.concat(
            [
                mapping_product_fact(),
                pd.DataFrame(
                    [
                        {
                            "product_id": "ID-ONLY",
                            "product_name": None,
                            "product_quantity": 1,
                            "explicit_unit_value": None,
                            "explicit_total_value": None,
                        }
                    ]
                ),
            ],
            ignore_index=True,
        )
        with TemporaryDirectory() as directory:
            draft_path = Path(directory) / "product-draft.csv"
            emit_product_mapping_draft(products, draft_path)
            draft = pd.read_csv(draft_path, keep_default_na=False)
            loaded_draft = load_product_mapping(draft_path, require_reviewed=False)
            self.assertEqual(list(draft.columns), PRODUCT_MAPPING_COLUMNS)
            self.assertEqual(len(draft), 4)
            self.assertEqual(len(loaded_draft), 4)
            self.assertEqual(set(draft["observed_items"]), {1})

            draft.loc[:, "canonical_name"] = "Produto"
            draft.loc[:, "classification"] = "adicional"
            draft.loc[:, "classification_reason"] = "revisão sintética"
            draft.loc[:, "reviewed"] = True
            duplicate = pd.concat([draft, draft.iloc[[0]]], ignore_index=True)
            duplicate.to_csv(draft_path, index=False)
            with self.assertRaisesRegex(ValueError, "duplicate"):
                load_product_mapping(draft_path)

            draft.assign(reviewed=False).to_csv(draft_path, index=False)
            with self.assertRaisesRegex(ValueError, "reviewed"):
                load_product_mapping(draft_path)

    def test_product_classification_uses_only_explicit_values_for_revenue(self):
        """Inferring prices from names would fabricate revenue for included products."""
        products = mapping_product_fact()
        mapping = pd.DataFrame(
            [
                {
                    "product_id_key": product_id,
                    "product_name_key": product_name,
                    "canonical_name": canonical,
                    "classification": classification,
                    "classification_reason": "identidade sintética revisada",
                    "reviewed": True,
                }
                for product_id, product_name, canonical, classification in (
                    ("CAM-INCLUSA", "Camiseta inclusa", "Camiseta inclusa", "kit_incluso"),
                    ("CAM-EXTRA", "Camiseta extra", "Camiseta extra", "adicional"),
                    (None, "Item sem classificação comercial", "Item sem classificação comercial", "desconhecido"),
                )
            ]
        )

        classified = classify_products(products, mapping).set_index("product_id_key")

        self.assertEqual(classified.loc["CAM INCLUSA", "classification"], "kit_incluso")
        self.assertTrue(pd.isna(classified.loc["CAM INCLUSA", "product_revenue"]))
        self.assertEqual(classified.loc["CAM EXTRA", "classification"], "adicional")
        self.assertEqual(classified.loc["CAM EXTRA", "product_revenue"], Decimal("130.00"))
        self.assertEqual(
            classified.loc["", "product_revenue"],
            Decimal("12.50"),
        )

    def test_unclassified_product_identity_fails_closed_without_fuzzy_match(self):
        """Name similarity must never substitute for a reviewed product identity."""
        products = mapping_product_fact().iloc[[0]].copy()
        products.loc[:, "product_name"] = "Camiseta inclusa nova"
        mapping = pd.DataFrame(
            [
                {
                    "product_id_key": "CAM-INCLUSA",
                    "product_name_key": "Camiseta inclusa",
                    "canonical_name": "Camiseta inclusa",
                    "classification": "kit_incluso",
                    "classification_reason": "identidade sintética revisada",
                    "reviewed": True,
                }
            ]
        )

        with self.assertRaisesRegex(ValueError, "unclassified product identities: 1"):
            classify_products(products, mapping)

    def test_apply_reviewed_mappings_returns_new_fact_bundle_with_coverage(self):
        """Mutating facts or omitting coverage evidence would weaken downstream audits."""
        facts = build_fact_bundle(source_bundle())
        channel_mapping = pd.DataFrame(
            [
                {
                    "coupon_title_key": "PARCEIRO ALFA",
                    "coupon_code_key": code,
                    "channel_name": "Parceiro Alfa",
                    "channel_type": "parceiro",
                    "alias_reason": "código revisado",
                    "reviewed": True,
                }
                for code in ("PARCEIRO ALFA", "PARCEIRO ALFA 2")
            ]
        )
        product_mapping = pd.DataFrame(
            [
                {
                    "product_id_key": product_id,
                    "product_name_key": product_name,
                    "canonical_name": canonical,
                    "classification": classification,
                    "classification_reason": "identidade revisada",
                    "reviewed": True,
                }
                for product_id, product_name, canonical, classification in (
                    ("1", "KIT MIF 2026", "Kit MIF 2026", "kit_incluso"),
                    ("2", "CAMISETA EXTRA", "Camiseta Extra", "adicional"),
                    ("KIT 21", "KIT 21K", "Kit 21K", "desconhecido"),
                )
            ]
        )

        mapped = apply_reviewed_mappings(facts, channel_mapping, product_mapping)

        self.assertIsNot(mapped, facts)
        self.assertIs(mapped.orders, facts.orders)
        self.assertNotIn("channel_name", facts.registrations.columns)
        self.assertEqual(mapped.reconciliation["channel_mapping_coverage_pct"], 100.0)
        self.assertEqual(mapped.reconciliation["product_mapping_coverage_pct"], 100.0)


if __name__ == "__main__":
    unittest.main()
