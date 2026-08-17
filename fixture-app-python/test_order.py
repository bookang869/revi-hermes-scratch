from order import Order, summarize


def test_summarize_nil_customer():
    got = summarize(Order(amount=42))
    assert got == "unknown customer owes 42"
