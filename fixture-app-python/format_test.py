import json

from format import format_order


def test_format_order_rejects_negative_amount():
    status, body = format_order(-5)
    assert status == 400
    parsed = json.loads(body)
    assert "error" in parsed


def test_format_order_accepts_positive_amount():
    status, body = format_order(42)
    assert status == 200
    parsed = json.loads(body)
    assert parsed == {"amount": 42, "currency": "USD"}


def test_format_order_accepts_zero_amount():
    status, body = format_order(0)
    assert status == 200
    parsed = json.loads(body)
    assert parsed == {"amount": 0, "currency": "USD"}
