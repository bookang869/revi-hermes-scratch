# Tests for stats.average_order_value.
# Before the fix, importing stats.py raised SyntaxError: '(' was never
# closed, so this whole module would fail to collect. After the fix,
# average_order_value should correctly compute the mean and handle the
# empty-list case without raising.

from stats import average_order_value


def test_average_order_value_computes_mean():
    assert average_order_value([10, 20, 30]) == 20


def test_average_order_value_empty_list_returns_zero():
    assert average_order_value([]) == 0
