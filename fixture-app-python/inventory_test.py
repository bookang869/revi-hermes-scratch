import io
import urllib.error
import urllib.request
from unittest import mock

from inventory import check_inventory


def test_check_inventory_returns_503_on_downstream_http_error():
    def raise_http_error(*args, **kwargs):
        raise urllib.error.HTTPError(
            url="http://example.invalid/stock?sku=ABC",
            code=500,
            msg="Internal Server Error",
            hdrs=None,
            fp=io.BytesIO(b"boom"),
        )

    with mock.patch.object(urllib.request, "urlopen", side_effect=raise_http_error):
        status, body = check_inventory("ABC")

    assert status == 503
    assert body == "inventory service unavailable"


def test_check_inventory_returns_200_on_success():
    class FakeResponse:
        def __enter__(self):
            return self

        def __exit__(self, *exc):
            return False

        def read(self):
            return b"in-stock"

    with mock.patch.object(urllib.request, "urlopen", return_value=FakeResponse()):
        status, body = check_inventory("ABC")

    assert status == 200
    assert body == "in-stock"
