import urllib.error
from unittest.mock import patch

from inventory import check_inventory


def test_downstream_non_200_is_surfaced_as_503_not_forwarded_as_200():
    # Simulate the downstream inventory service returning a non-200
    # (e.g. 500) response. Before the fix, this was forwarded to the
    # caller as if it were a successful (200) lookup.
    http_error = urllib.error.HTTPError(
        url="http://inventory.example/stock?sku=abc",
        code=500,
        msg="Internal Server Error",
        hdrs=None,
        fp=None,
    )

    with patch("inventory.urllib.request.urlopen", side_effect=http_error):
        status, body = check_inventory("abc")

    assert status == 503
    assert status != 200


def test_downstream_200_is_forwarded_as_success():
    class FakeResp:
        def __enter__(self):
            return self

        def __exit__(self, *args):
            return False

        def read(self):
            return b"in-stock"

    with patch("inventory.urllib.request.urlopen", return_value=FakeResp()):
        status, body = check_inventory("abc")

    assert status == 200
    assert body == "in-stock"
