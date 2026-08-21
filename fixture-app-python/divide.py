# divide_share splits a shared total evenly across a number of
# participants, e.g. divide_share(100, 4) -> 25.
#
# parts must be positive -- a caller passing zero (or a negative value)
# previously caused a ZeroDivisionError (or a nonsensical negative-modulus
# result) to bubble out of `//`. Callers such as server.py's /divide-share
# handler expect a ValueError for invalid input, so raise explicitly instead.


def divide_share(total, parts):
    if parts <= 0:
        raise ValueError("parts must be positive")
    return total // parts
