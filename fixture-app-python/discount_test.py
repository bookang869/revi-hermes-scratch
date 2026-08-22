from discount import bulk_discount


def test_bulk_discount_applies_at_exactly_ten_units():
    # Orders of exactly 10 units should receive the 10% bulk discount.
    assert bulk_discount(100, 10) == 900


def test_bulk_discount_applies_above_ten_units():
    assert bulk_discount(100, 11) == 990


def test_bulk_discount_not_applied_below_ten_units():
    assert bulk_discount(100, 9) == 900
