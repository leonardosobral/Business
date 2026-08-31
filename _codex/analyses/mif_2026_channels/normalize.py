"""Deterministic normalizers for fields supplied by TicketSports exports."""

from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal, InvalidOperation
import json
import re
from typing import Any
import unicodedata

import pandas as pd

from .config import EVENT_DATE


BRAZIL_ALIASES = frozenset({"BR", "BRASIL", "BRAZIL"})
REVIEWED_COUNTRIES = frozenset({"ARGENTINA"})
VALID_UFS = frozenset(
    "AC AL AP AM BA CE DF ES GO MA MT MS MG PA PB PR PE PI RJ RN RS RO RR SC SP SE TO".split()
)

_FEMININE_ALIASES = frozenset({"F", "FEM", "FEMININO", "FEMININA", "FEMALE"})
_MASCULINE_ALIASES = frozenset({"M", "MASC", "MASCULINO", "MASCULINA", "MALE"})
_OTHER_GENDER_ALIASES = frozenset(
    {"NB", "NAO BINARIO", "NAO BINARIA", "NAO BINARIE", "OUTRO", "OUTRA", "OUTRE"}
)


def _is_missing(value: object) -> bool:
    if value is None:
        return True
    try:
        return bool(pd.isna(value))
    except (TypeError, ValueError):
        return False


def normalize_text(value: object) -> str | None:
    """Return stripped source text, treating dataframe missing values as absent."""
    if _is_missing(value):
        return None
    text = str(value).strip()
    return text or None


def normalize_key(value: object) -> str:
    """Return an accent-free uppercase key suitable for deterministic matching."""
    text = normalize_text(value) or ""
    ascii_text = "".join(
        char for char in unicodedata.normalize("NFKD", text)
        if not unicodedata.combining(char)
    )
    return re.sub(r"[^A-Za-z0-9]+", " ", ascii_text).strip().upper()


def _json_error(row_position: int | None) -> ValueError:
    location = f" at export row {row_position}" if row_position is not None else ""
    return ValueError(f"invalid JSON object{location}")


def parse_json_object(value: object, row_position: int | None = None) -> dict[str, Any]:
    """Parse a JSON object without echoing source contents in error messages."""
    if isinstance(value, dict):
        return dict(value)
    if not isinstance(value, str):
        raise _json_error(row_position)
    try:
        parsed = json.loads(value)
    except (TypeError, json.JSONDecodeError) as error:
        raise _json_error(row_position) from error
    if not isinstance(parsed, dict):
        raise _json_error(row_position)
    return parsed


def parse_decimal(value: object) -> Decimal | None:
    """Parse API and Brazilian decimal formats while rejecting non-finite values."""
    if _is_missing(value):
        return None
    if isinstance(value, str):
        text = value.strip()
        if "," in text and "." in text:
            if text.rfind(",") > text.rfind("."):
                text = text.replace(".", "").replace(",", ".")
            else:
                text = text.replace(",", "")
        elif "," in text:
            text = text.replace(",", ".")
        value = text
    try:
        parsed = Decimal(str(value))
    except (InvalidOperation, ValueError):
        return None
    return parsed if parsed.is_finite() else None


def parse_date(value: object) -> date | None:
    """Parse the ISO and Brazilian date formats accepted by the export contract."""
    if _is_missing(value):
        return None
    if isinstance(value, datetime):
        return value.date()
    if isinstance(value, date):
        return value
    text = normalize_text(value)
    if text is None:
        return None
    for pattern in ("%Y-%m-%d", "%d/%m/%Y"):
        try:
            return datetime.strptime(text, pattern).date()
        except ValueError:
            continue
    return None


def coverage_status(raw_value: object, parsed_value: object) -> str:
    """Distinguish source absence from a present but invalid parsed value."""
    if normalize_text(raw_value) is None:
        return "nao_informado"
    return "valido" if parsed_value is not None else "invalido"


def normalize_status(value: object) -> str:
    """Return the stable lowercase status key used by paid-sale filtering."""
    return normalize_key(value).lower()


def normalize_modality(value: object) -> str:
    """Map only explicit race-distance and category patterns to canonical modalities."""
    key = normalize_key(value)
    if not key:
        return "Não informado"
    if re.search(r"\bDESAFIO\b", key):
        return "DESAFIO"
    if re.search(r"\bKIDS?\b", key):
        return "KIDS"
    if re.search(r"\b(?:21\s*K?M?|MEIA MARATONA)\b", key):
        return "21K"
    if re.search(r"\b(?:42\s*K?M?|MARATONA)\b", key):
        return "42K"
    if re.search(r"\b5\s*K?M?\b", key):
        return "5K"
    return f"OUTRA: {key}"


def normalize_lot(value: object) -> str:
    """Normalize numbered lots without relabeling unexpected commercial values."""
    key = normalize_key(value)
    if not key:
        return "Não informado"
    matched = re.fullmatch(r"(?:LOTE\s*)?0*(\d{1,2})", key)
    if matched is not None and 1 <= int(matched.group(1)) <= 99:
        return str(int(matched.group(1)))
    return f"OUTRO: {key}"


def normalize_country(value: object) -> str | None:
    """Return Brazil under one label and otherwise preserve reviewed country keys."""
    key = normalize_key(value)
    if not key:
        return None
    if key in BRAZIL_ALIASES:
        return "BRASIL"
    return key if key in REVIEWED_COUNTRIES else f"OUTRO: {key}"


def normalize_state(value: object, country: object = None) -> str | None:
    """Accept a Brazilian UF only when the country is Brazil or absent."""
    key = normalize_key(value)
    normalized_country = normalize_country(country)
    if key not in VALID_UFS or normalized_country not in (None, "BRASIL"):
        return None
    return key


def normalize_city(value: object) -> str | None:
    """Return a normalized city key while retaining absent values as null."""
    key = normalize_key(value)
    return key or None


def normalize_gender(value: object) -> str:
    """Assign gender only from explicit source aliases."""
    key = normalize_key(value)
    if not key:
        return "Não informado"
    if key in _FEMININE_ALIASES:
        return "Feminino"
    if key in _MASCULINE_ALIASES:
        return "Masculino"
    if key in _OTHER_GENDER_ALIASES:
        return "Não binário/outro informado"
    return "Inválido"


def age_on_event_date(value: object) -> int | None:
    """Calculate a bounded age as of the fixed event date."""
    born = parse_date(value)
    if born is None:
        return None
    age = EVENT_DATE.year - born.year - (
        (EVENT_DATE.month, EVENT_DATE.day) < (born.month, born.day)
    )
    return age if 5 <= age <= 100 else None


def pace_to_seconds(value: object) -> int | None:
    """Parse a bounded pace in MM:SS or HH:MM:SS format."""
    text = normalize_text(value)
    if text is None:
        return None
    matched = re.fullmatch(r"(\d{1,2}):(\d{2})(?::(\d{2}))?", text)
    if matched is None:
        return None
    first, second, third = (
        int(part) if part is not None else None for part in matched.groups()
    )
    if second >= 60 or (third is not None and third >= 60):
        return None
    seconds = first * 60 + second if third is None else first * 3600 + second * 60 + third
    return seconds if 120 <= seconds <= 1200 else None
