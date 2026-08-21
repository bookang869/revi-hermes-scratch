# catalog_item returns the catalog item at the requested index, or None if
# the index is out of range -- rejecting out-of-range indices here instead
# of letting IndexError propagate out of the HTTP handler.

CATALOG_ITEMS = ["widget", "gadget", "gizmo"]


def catalog_item(index):
    return CATALOG_ITEMS[index]
