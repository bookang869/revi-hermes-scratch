import urllib.error

import inventory


class _FakeHTTPResponse:
    def __init__(self, data):
        self._data = data

    def read(self):
        return self._data


def test_check_inventory_forwards_non_200_as_503(monkeypatch):
    def fake_urlopen(url, timeout=2):
        raise urllib.error.HTTPError(
            url, 500, "Internal Server Error", hdrs=None, fp=None
        )

    monkeypatch.setattr(inventory.urllib.request, "urlopen", fake_urlopen)

    status, body = inventory.check_inventory("widget")

    assert status == 503
    assert body == "inventory service unavailable"


def test_check_inventory_returns_200_on_success(monkeypatch):
    class _CM:
        def __enter__(self):
            return _FakeHTTPResponse(b"in stock")

        def __exit__(self, *exc):
            return False

    def fake_urlopen(url, timeout=2):
        return _CM()

    monkeypatch.setattr(inventory.urllib.request, "urlopen", fake_urlopen)

    status, body = inventory.check_inventory("widget")

    assert status == 200
    assert body == "in stock"
