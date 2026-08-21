# Stdlib-only HTTP server (mirrors server.js/main.rs/main.go's :8080
# shape -- no Flask/etc, so nothing here needs to survive `git clean -fd`
# between repair-loop attempts via a requirements.txt install step that
# never runs).
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs

from discount import bulk_discount
from divide import divide_share
from format import format_order
from inventory import check_inventory
from items import catalog_item
from order import Order, summarize
from settings import validate_order
from stats import average_order_value


def _int_param(query, name):
    try:
        return int(query.get(name, ["0"])[0])
    except ValueError:
        return 0


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path
        query = parse_qs(parsed.query)

        if path == "/healthz":
            self._respond(200, "ok")
        elif path == "/summarize":
            self._respond(200, summarize(Order(amount=42)))
        elif path == "/divide-share":
            total = _int_param(query, "total")
            parts = _int_param(query, "parts")
            try:
                self._respond(200, str(divide_share(total, parts)))
            except ValueError:
                self._respond(400, "parts must be positive")
        elif path == "/discount":
            unit_price = _int_param(query, "unit_price")
            qty = _int_param(query, "qty")
            self._respond(200, str(bulk_discount(unit_price, qty)))
        elif path == "/validate-order":
            amount = _int_param(query, "amount")
            self._respond(200, "accepted" if validate_order(amount) else "rejected")
        elif path == "/inventory":
            sku = query.get("sku", [""])[0]
            status, body = check_inventory(sku)
            self._respond(status, body)
        elif path == "/average":
            self._respond(200, str(average_order_value([10, 20, 30])))
        elif path == "/format-order":
            amount = _int_param(query, "amount")
            status, body = format_order(amount)
            self._respond(status, body, content_type="application/json")
        elif path == "/items":
            index = _int_param(query, "index")
            item = catalog_item(index)
            if item is None:
                self._respond(400, "index out of range")
            else:
                self._respond(200, item)
        else:
            self._respond(404, "not found")

    def _respond(self, status, body, content_type="text/plain"):
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.end_headers()
        self.wfile.write(body.encode())

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    HTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
