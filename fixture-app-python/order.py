class Customer:
    def __init__(self, name):
        self.name = name


class Order:
    def __init__(self, customer=None, amount=0):
        self.customer = customer
        self.amount = amount


def summarize(order):
    if order.customer is None:
        return f"unknown customer owes {order.amount}"
    return f"{order.customer.name} owes {order.amount}"
