const http = require("http");
const { summarize } = require("./order");

/**
 * @param {any} req
 * @param {any} res
 */
function handle(req, res) {
  if (req.url === "/healthz") {
    res.writeHead(200);
    res.end("ok");
    return;
  }
  if (req.url === "/summarize") {
    res.writeHead(200);
    res.end(summarize({ amount: 42 }));
    return;
  }
  res.writeHead(404);
  res.end("not found");
}

const server = http.createServer(handle);
server.listen(8080);
