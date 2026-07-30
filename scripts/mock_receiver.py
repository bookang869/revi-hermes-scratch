import hashlib
import hmac
import http.server
import json
import sys

SECRET = sys.argv[1].encode()
PORT = int(sys.argv[2])


class Handler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length)
        sig_header = self.headers.get("X-Revi-Signature", "")
        expected = "sha256=" + hmac.new(SECRET, body, hashlib.sha256).hexdigest()
        ok = hmac.compare_digest(sig_header, expected)
        payload = json.loads(body)
        print("RECEIVED_PAYLOAD=" + json.dumps(payload), flush=True)
        print("SIGNATURE_VALID=" + str(ok), flush=True)
        self.send_response(202 if ok else 401)
        self.end_headers()

    def log_message(self, fmt, *args):
        pass


http.server.HTTPServer(("127.0.0.1", PORT), Handler).handle_request()
