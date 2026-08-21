from stats import average_order_value


def test_average_order_value_computes_mean():
    assert average_order_value([10, 20, 30]) == 20


def test_average_order_value_empty_list_returns_zero():
    assert average_order_value([]) == 0
