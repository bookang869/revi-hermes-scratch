# bulk_discount applies a 10% discount to orders of 10 or more units.
# bulk_discount(100, 10) -> 900 (10x100, 10% off).


def bulk_discount(unit_price, qty):
    total = unit_price * qty
    if qty > 10:
        total = total * 90 // 100
    return total
