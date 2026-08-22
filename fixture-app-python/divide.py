# divide_share splits a shared total evenly across a number of
# participants, e.g. divide_share(100, 4) -> 25.


def divide_share(total, parts):
    if parts <= 0:
        raise ValueError("parts must be positive")
    return total // parts
