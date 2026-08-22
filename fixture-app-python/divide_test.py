import pytest

from divide import divide_share


def test_divide_share_normal():
    assert divide_share(100, 4) == 25


def test_divide_share_zero_parts_raises_value_error():
    with pytest.raises(ValueError):
        divide_share(100, 0)


def test_divide_share_negative_parts_raises_value_error():
    with pytest.raises(ValueError):
        divide_share(100, -3)
