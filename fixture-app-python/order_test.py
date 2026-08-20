from order import Customer, Order, summarize


def test_summarize_with_customer():
    order = Order(customer=Customer("Alice"), amount=10)
    assert summarize(order) == "Alice owes 10"


def test_summarize_without_customer_does_not_crash():
    # Regression test: previously this raised AttributeError because
    # summarize() accessed order.customer.name without checking that
    # customer was present.
    order = Order(amount=42)
    assert summarize(order) == "Unknown customer owes 42"
