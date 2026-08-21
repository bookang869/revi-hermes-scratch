from order import Order, summarize


def test_summarize_with_no_customer_does_not_crash():
    order = Order(amount=42)
    result = summarize(order)
    assert result == "Unknown owes 42"


def test_summarize_with_customer_uses_customer_name():
    from order import Customer

    order = Order(customer=Customer("Alice"), amount=10)
    result = summarize(order)
    assert result == "Alice owes 10"
