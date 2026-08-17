# Stdlib-only HTTP server (mirrors server.js/main.rs/main.go's :8080
# /healthz + /summarize shape -- no Flask/etc, so nothing here needs to
# survive `git clean -fd` between repair-loop attempts via a requirements.txt
# install step that never runs).
from http.server import BaseHTTPRequestHandler, HTTPServer

from order import Order, summarize


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/healthz":
            self._respond(200, "ok")
        elif self.path == "/summarize":
            self._respond(200, summarize(Order(amount=42)))
        else:
            self._respond(404, "not found")

    def _respond(self, status, body):
        self.send_response(status)
        self.end_headers()
        self.wfile.write(body.encode())

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    HTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
