from datetime import date
from decimal import Decimal
import unittest

import pandas as pd

from _codex.analyses.mif_2026_channels.normalize import (
    age_on_event_date,
    coverage_status,
    normalize_city,
    normalize_country,
    normalize_gender,
    normalize_key,
    normalize_lot,
    normalize_modality,
    normalize_state,
    normalize_status,
    normalize_text,
    pace_to_seconds,
    parse_date,
    parse_decimal,
    parse_json_object,
)


class NormalizeTests(unittest.TestCase):
    def test_decimal_accepts_api_and_brazilian_formats(self):
        """A Brazilian decimal separator must not change commercial values."""
        self.assertEqual(parse_decimal("273.27"), Decimal("273.27"))
        self.assertEqual(parse_decimal("1.234,56"), Decimal("1234.56"))

    def test_decimal_rejects_non_finite_and_missing_values(self):
        """Non-finite or missing values must remain unusable instead of becoming amounts."""
        self.assertIsNone(parse_decimal("NaN"))
        self.assertIsNone(parse_decimal(float("inf")))
        self.assertIsNone(parse_decimal(pd.NA))

    def test_key_removes_accents_spacing_and_case(self):
        """Punctuation variants must use one stable mapping key."""
        self.assertEqual(normalize_key("  Corre  Criciúma_100 "), "CORRE CRICIUMA 100")

    def test_text_treats_missing_and_blank_values_as_absent(self):
        """Blank and dataframe-missing source cells must not look populated."""
        self.assertIsNone(normalize_text(None))
        self.assertIsNone(normalize_text(pd.NA))
        self.assertIsNone(normalize_text(" \t "))
        self.assertEqual(normalize_text("  São José  "), "São José")

    def test_json_object_accepts_objects_and_sanitizes_parse_errors(self):
        """Malformed payloads must identify only their export row, never their contents."""
        self.assertEqual(parse_json_object({"status": "pago"}), {"status": "pago"})
        self.assertEqual(parse_json_object('{"status": "pago"}'), {"status": "pago"})

        with self.assertRaisesRegex(ValueError, "export row 7") as error:
            parse_json_object('{"nome":"Pessoa Teste","numero_pedido":123', row_position=7)
        self.assertNotIn("Pessoa Teste", str(error.exception))
        self.assertNotIn("123", str(error.exception))

    def test_json_object_rejects_non_object_payloads(self):
        """JSON arrays cannot supply named TicketSports source fields."""
        with self.assertRaisesRegex(ValueError, "export row 0"):
            parse_json_object("[]", row_position=0)

    def test_status_and_modality_are_canonical(self):
        """Known status, modality, lot, and date formats must share canonical forms."""
        self.assertEqual(normalize_status(" PAGO "), "pago")
        self.assertEqual(normalize_modality("Maratona 42 km"), "42K")
        self.assertEqual(normalize_modality("Meia Maratona - 21KM"), "21K")
        self.assertEqual(normalize_lot("Lote 6"), "6")
        self.assertEqual(parse_date("30/08/2026"), date(2026, 8, 30))

    def test_modality_and_lot_preserve_unreviewed_nonblank_values(self):
        """Unexpected commercial labels must remain visible rather than be guessed."""
        self.assertEqual(normalize_modality("Trail 12 km"), "OUTRA: TRAIL 12 KM")
        self.assertEqual(normalize_lot("Lote VIP"), "OUTRO: LOTE VIP")
        self.assertEqual(normalize_lot("Lote 100"), "OUTRO: LOTE 100")
        self.assertEqual(normalize_lot(""), "Não informado")

    def test_missing_modality_uses_the_absence_marker(self):
        """Absent modality values must not become unexpected commercial categories."""
        self.assertEqual(normalize_modality(None), "Não informado")
        self.assertEqual(normalize_modality(""), "Não informado")
        self.assertEqual(normalize_modality(" \t "), "Não informado")

    def test_modality_maps_each_explicit_non_distance_category(self):
        """The three remaining reviewed modality categories must not fall into outra."""
        self.assertEqual(normalize_modality("5 km"), "5K")
        self.assertEqual(normalize_modality("Desafio 21K + 42K"), "DESAFIO")
        self.assertEqual(normalize_modality("Corrida Kids"), "KIDS")

    def test_date_accepts_iso_and_brazilian_values_only(self):
        """Ambiguous date text must not be converted into a participant birth date."""
        self.assertEqual(parse_date("2026-08-30"), date(2026, 8, 30))
        self.assertIsNone(parse_date("08/30/2026"))
        self.assertIsNone(parse_date("2026-02-30"))

    def test_geography_accepts_brazilian_ufs_only_for_brazil(self):
        """A UF code must not be attributed to a non-Brazilian country."""
        self.assertEqual(normalize_country("Brazil"), "BRASIL")
        self.assertEqual(normalize_country("Argentina"), "ARGENTINA")
        self.assertEqual(normalize_state("sc", "BR"), "SC")
        self.assertEqual(normalize_state("SC", None), "SC")
        self.assertIsNone(normalize_state("SC", "Argentina"))
        self.assertIsNone(normalize_state("Santa Catarina", "Brasil"))
        self.assertEqual(normalize_city("  São José/SC "), "SAO JOSE SC")

    def test_country_marks_unreviewed_values_as_other(self):
        """An unreviewed country label must not be treated as a valid country segment."""
        self.assertEqual(normalize_country("XPTO"), "OUTRO: XPTO")

    def test_gender_uses_explicit_aliases_and_marks_invalid_values(self):
        """Unrecognized gender labels must not be silently assigned to a category."""
        self.assertEqual(normalize_gender("F"), "Feminino")
        self.assertEqual(normalize_gender("masculino"), "Masculino")
        self.assertEqual(normalize_gender("não binário"), "Não binário/outro informado")
        self.assertEqual(normalize_gender(""), "Não informado")
        self.assertEqual(normalize_gender("xpto"), "Inválido")

    def test_age_and_pace_are_bounded(self):
        """Impossible age and pace values must not enter participant profiles."""
        self.assertEqual(age_on_event_date("1990-08-31"), 35)
        self.assertIsNone(age_on_event_date("2022-08-31"))
        self.assertEqual(pace_to_seconds("05:30"), 330)
        self.assertEqual(pace_to_seconds("00:05:30"), 330)
        self.assertIsNone(pace_to_seconds("99:99"))
        self.assertEqual(coverage_status("99:99", None), "invalido")
        self.assertEqual(coverage_status("", None), "nao_informado")
