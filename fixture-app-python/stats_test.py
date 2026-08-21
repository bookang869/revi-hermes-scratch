from stats import average_order_value


def test_average_order_value_empty():
    assert average_order_value([]) == 0


def test_average_order_value_computes_mean():
    assert average_order_value([10, 20, 30]) == 20


def test_average_order_value_non_integer_mean():
    assert average_order_value([10, 15]) == 12.5
