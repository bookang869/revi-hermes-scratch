import http.server
import json
import sys

# Test double for the slice of the GitHub REST API promote-pr.sh calls
# (list PRs by head, create PR, comment on PR). Unlike mock_receiver.py this
# serves multiple requests per run (promote-pr.sh makes 2-3 calls), so it
# uses serve_forever() instead of handle_request().
PORT = int(sys.argv[1])
EXISTING_PR_URL = sys.argv[2] if len(sys.argv) > 2 else ""


class Handler(http.server.BaseHTTPRequestHandler):
    def _write_json(self, status, obj):
        body = json.dumps(obj).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if "/pulls" in self.path:
            print("GET_PULLS_CALLED path=" + self.path, flush=True)
            self._write_json(200, [{"html_url": EXISTING_PR_URL}] if EXISTING_PR_URL else [])
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body = json.loads(self.rfile.read(length) or b"{}")
        if self.path.endswith("/pulls"):
            print("CREATE_PR_PAYLOAD=" + json.dumps(body), flush=True)
            self._write_json(201, {"html_url": "http://127.0.0.1:9/pulls/1"})
        elif "/comments" in self.path:
            print("COMMENT_PAYLOAD=" + json.dumps(body), flush=True)
            self._write_json(201, {})
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, fmt, *args):
        pass


http.server.HTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
