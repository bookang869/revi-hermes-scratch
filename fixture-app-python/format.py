import json

# format_order returns a JSON view of an order's amount, rejecting negative
# amounts with (400, ...) rather than echoing back a nonsensical order.
# Returns (status, body).


def format_order(amount):
    if amount < 0:
        body = {"error": "amount must be non-negative"}
        return 400, json.dumps(body, separators=(",", ":"))
    body = {"amount": amount, "currency": "USD"}
    return 200, json.dumps(body, separators=(",", ":"))
