# summarize used to be buggy: it accessed order.customer.name without
# checking whether customer is present, so an Order with no Customer
# attached raised AttributeError -- this was the seeded bug used to test
# the repair loop end-to-end (mirrors the Go/Rust/Node fixture apps'
# order.go/order.rs/order.js). Fixed by falling back to a placeholder name
# when no customer is attached instead of dereferencing None.


class Customer:
    def __init__(self, name):
        self.name = name


class Order:
    def __init__(self, customer=None, amount=0):
        self.customer = customer
        self.amount = amount


def summarize(order):
    name = order.customer.name if order.customer is not None else "Unknown customer"
    return f"{name} owes {order.amount}"
