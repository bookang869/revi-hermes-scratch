from order import Customer, Order, summarize


def test_summarize_with_customer():
    order = Order(customer=Customer("Alice"), amount=42)
    assert summarize(order) == "Alice owes 42"


def test_summarize_without_customer_does_not_crash():
    order = Order(amount=42)
    assert summarize(order) == "Unknown customer owes 42"
