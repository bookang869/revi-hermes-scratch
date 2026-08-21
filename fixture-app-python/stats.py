# average_order_value returns the mean of a set of order amounts, or 0 for
# an empty list (avoids a divide-by-zero rather than raising on no data).
# Exposed over HTTP against a fixed sample so it's independently checkable,
# not just something Hermes could satisfy by deleting the broken function.


def average_order_value(orders):
    if not orders:
        return 0
    return sum(orders) / len(orders)
