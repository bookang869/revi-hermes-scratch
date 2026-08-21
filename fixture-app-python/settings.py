import os

# max_order_amount rejects orders over a configurable maximum, read from
# MAX_ORDER_AMOUNT (defaults to 100000 if unset or unparsable -- an invalid
# config value must fall back to the default, not silently disable
# ordering entirely).


def max_order_amount():
    raw = os.environ.get("MAX_ORDER_AMOUNT")
    if raw:
        try:
            return int(raw)
        except ValueError:
            return 0
    return 100000


def validate_order(amount):
    return amount <= max_order_amount()
