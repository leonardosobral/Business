"""Immutable constants for the MIF 2026 channel sales study."""

from datetime import date


EVENT_CODE = 72611
EVENT_DATE = date(2026, 8, 30)
PAID_STATUS = "pago"
FULL_DOSSIER_MIN_REGISTRATIONS = 10
SMALL_CELL_MIN_REGISTRATIONS = 3
PIPELINE_VERSION = "1.0.0"
FORBIDDEN_OUTPUT_KEYS = frozenset({
    "nome", "email", "telefone", "celular", "cpf", "cnpj", "endereco",
    "logradouro", "numero_pedido", "numero_inscricao", "data_nascimento",
})
