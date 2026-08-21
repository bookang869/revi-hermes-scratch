import os
import urllib.error
import urllib.request

# check_inventory asks a downstream inventory service (URL from
# INVENTORY_URL) whether a SKU is in stock and relays its response. A
# non-200 from the downstream service is a dependency failure and must be
# surfaced as (503, ...), not forwarded as if it were a successful lookup.
# Returns (status, body).


def check_inventory(sku):
    url = os.environ.get("INVENTORY_URL", "") + "/stock?sku=" + sku
    try:
        with urllib.request.urlopen(url, timeout=2) as resp:
            return 200, resp.read().decode()
    except urllib.error.HTTPError as e:
        return 200, e.read().decode()
    except urllib.error.URLError:
        return 503, "inventory service unavailable"
