from discount import bulk_discount


def test_bulk_discount_applies_at_exactly_ten_units():
    # 10 units at 100 each should get the 10% bulk discount -> 900
    assert bulk_discount(100, 10) == 900


def test_bulk_discount_applies_above_ten_units():
    assert bulk_discount(100, 11) == 990


def test_bulk_discount_not_applied_below_ten_units():
    assert bulk_discount(100, 9) == 900
