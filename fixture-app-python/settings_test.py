import os

import pytest

import settings


@pytest.fixture(autouse=True)
def _clean_env():
    original = os.environ.pop("MAX_ORDER_AMOUNT", None)
    yield
    if original is None:
        os.environ.pop("MAX_ORDER_AMOUNT", None)
    else:
        os.environ["MAX_ORDER_AMOUNT"] = original


def test_max_order_amount_defaults_when_unset():
    assert settings.max_order_amount() == 100000


def test_max_order_amount_uses_valid_value():
    os.environ["MAX_ORDER_AMOUNT"] = "5000"
    assert settings.max_order_amount() == 5000


def test_max_order_amount_falls_back_to_default_when_invalid():
    os.environ["MAX_ORDER_AMOUNT"] = "not-a-number"
    assert settings.max_order_amount() == 100000


def test_validate_order_still_allows_orders_when_config_is_invalid():
    os.environ["MAX_ORDER_AMOUNT"] = "garbage"
    assert settings.validate_order(1) is True
    assert settings.validate_order(100000) is True
    assert settings.validate_order(100001) is False
