from stats import average_order_value


def test_average_order_value_basic():
    assert average_order_value([10, 20, 30]) == 20


def test_average_order_value_empty():
    assert average_order_value([]) == 0


def test_average_order_value_non_integer_mean():
    assert average_order_value([10, 21]) == 15.5
