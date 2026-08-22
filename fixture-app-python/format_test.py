import json

from format import format_order


def test_format_order_rejects_negative_amount():
    status, body = format_order(-5)
    assert status == 400
    payload = json.loads(body)
    assert "error" in payload


def test_format_order_accepts_positive_amount():
    status, body = format_order(42)
    assert status == 200
    payload = json.loads(body)
    assert payload == {"amount": 42, "currency": "USD"}


def test_format_order_accepts_zero_amount():
    status, body = format_order(0)
    assert status == 200
    payload = json.loads(body)
    assert payload == {"amount": 0, "currency": "USD"}
