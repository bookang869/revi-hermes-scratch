import io
import urllib.error

import inventory


class _FakeHTTPError(urllib.error.HTTPError):
    def __init__(self, body):
        super().__init__(
            url="http://example.invalid/stock?sku=abc",
            code=500,
            msg="Internal Server Error",
            hdrs=None,
            fp=io.BytesIO(body.encode()),
        )
        self._body = body

    def read(self):
        return self._body.encode()


def test_non_200_downstream_response_is_surfaced_as_503(monkeypatch):
    def fake_urlopen(url, timeout=2):
        raise _FakeHTTPError("boom: out of stock service down")

    monkeypatch.setattr(inventory.urllib.request, "urlopen", fake_urlopen)

    status, body = inventory.check_inventory("abc")

    assert status == 503
    assert status != 200
    assert "boom: out of stock service down" in body


def test_successful_downstream_response_is_forwarded_as_200(monkeypatch):
    class _FakeResp:
        def __enter__(self):
            return self

        def __exit__(self, *exc):
            return False

        def read(self):
            return b"in_stock"

    def fake_urlopen(url, timeout=2):
        return _FakeResp()

    monkeypatch.setattr(inventory.urllib.request, "urlopen", fake_urlopen)

    status, body = inventory.check_inventory("abc")

    assert status == 200
    assert body == "in_stock"
