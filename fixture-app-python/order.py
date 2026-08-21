# summarize is deliberately buggy: it accesses order.customer.name without
# checking whether customer is present, so an Order with no Customer
# attached raises AttributeError -- this is the seeded bug used to test
# the repair loop end-to-end (mirrors the Go/Rust/Node fixture apps'
# order.go/order.rs/order.js).


class Customer:
    def __init__(self, name):
        self.name = name


class Order:
    def __init__(self, customer=None, amount=0):
        self.customer = customer
        self.amount = amount


def summarize(order):
    if order.customer is None:
        return f"Unknown customer owes {order.amount}"
    return f"{order.customer.name} owes {order.amount}"
