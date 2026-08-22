import pytest

from divide import divide_share


def test_divide_share_normal():
    assert divide_share(100, 4) == 25


def test_divide_share_by_zero_raises():
    with pytest.raises(ValueError):
        divide_share(100, 0)
