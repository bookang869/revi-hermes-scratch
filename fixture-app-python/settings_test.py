import os

import pytest

import settings


@pytest.fixture(autouse=True)
def _clear_env():
    os.environ.pop("MAX_ORDER_AMOUNT", None)
    yield
    os.environ.pop("MAX_ORDER_AMOUNT", None)


def test_max_order_amount_defaults_when_unset():
    assert settings.max_order_amount() == 100000


def test_max_order_amount_defaults_when_invalid():
    os.environ["MAX_ORDER_AMOUNT"] = "not-a-number"
    assert settings.max_order_amount() == 100000


def test_max_order_amount_parses_valid_value():
    os.environ["MAX_ORDER_AMOUNT"] = "5000"
    assert settings.max_order_amount() == 5000


def test_validate_order_uses_default_when_config_invalid():
    os.environ["MAX_ORDER_AMOUNT"] = "not-a-number"
    assert settings.validate_order(50000) is True
    assert settings.validate_order(150000) is False
