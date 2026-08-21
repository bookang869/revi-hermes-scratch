from items import catalog_item, CATALOG_ITEMS


def test_catalog_item_valid_index_returns_item():
    assert catalog_item(0) == "widget"
    assert catalog_item(len(CATALOG_ITEMS) - 1) == "gizmo"


def test_catalog_item_out_of_range_returns_none_instead_of_raising():
    assert catalog_item(len(CATALOG_ITEMS)) is None


def test_catalog_item_negative_index_returns_none():
    assert catalog_item(-1) is None
